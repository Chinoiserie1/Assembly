// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../ERC1155.sol";

// bytes4(keccak256("burnAmountExceedsTotalSupply()"))
bytes32 constant BURN_AMOUNT_EXCEEDS_TOTAL_SUPPLY = 
  0x9fe38c4f00000000000000000000000000000000000000000000000000000000;

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 * 
 * @author chixx.eth
 */
abstract contract ERC1155Supply is ERC1155 {
  mapping(uint256 => uint256) private _totalSupply;

  /**
   * @dev Total amount of tokens in with a given id.
   */
  function totalSupply(uint256 id) public view virtual returns (uint256 supply) {
    assembly {
      mstore(0x00, id)
      mstore(0x20, _totalSupply.slot)
      supply := sload(keccak256(0x00, 0x40))
    }
  }

  /**
   * @dev Indicates whether any token exist with a given id, or not.
   */
  function exists(uint256 id) public view virtual returns (bool exist) {
    // return ERC1155Supply.totalSupply(id) > 0;
    assembly {
      mstore(0x00, id)
      mstore(0x20, _totalSupply.slot)
      if iszero(sload(keccak256(0x00, 0x40))) {
        exist := 0
      }
      exist := 1
    }
  }

  /**
   * @dev See {ERC1155-_beforeTokenTransfer}.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    assembly {
      if iszero(from) {
        let size := mload(ids)
        let startIds := add(ids, 0x20)
        let startAmounts := add(amounts, 0x20)
        // store slot _totalSupply for keccak256 for retrieve totalSupply
        mstore(0x20, _totalSupply.slot)
        for { let i := 0 } lt(i, size) { i := add(i, 1) } {
          mstore(0x00, mload(add(startIds, mul(i, 0x20))))
          let slot := keccak256(0x00, 0x40)
          let currentSupply := sload(slot)
          let updatedSupply := add(currentSupply, mload(add(startAmounts, mul(i, 0x20))))
          if lt(updatedSupply, currentSupply) {
            mstore(0x00, OVERFLOW)
            revert(0x00, 0x04)
          }
          sstore(slot, updatedSupply)
        }
      }
      if iszero(to) {
        let size := mload(ids)
        let startIds := add(ids, 0x20)
        let startAmounts := add(amounts, 0x20)
        // store slot _totalSupply for keccak256 for retrieve totalSupply
        mstore(0x20, _totalSupply.slot)
        for { let i := 0 } lt(i, size) { i := add(i, 1) } {
          mstore(0x00, mload(add(startIds, mul(i, 0x20))))
          let slot := keccak256(0x00, 0x40)
          let currentSupply := sload(slot)
          let amountBurn := mload(add(startAmounts, mul(i, 0x20)))
          if lt(currentSupply, amountBurn) {
            mstore(0x00, BURN_AMOUNT_EXCEEDS_TOTAL_SUPPLY)
            revert(0x00, 0x04)
          }
          let updatedSupply := sub(currentSupply, amountBurn)
          sstore(slot, updatedSupply)
        }
      }
    }
  }
}