// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../ERC1155.sol";

import "forge-std/Test.sol";

// bytes4(keccak256("overflow()"))
// bytes32 constant OVERFLOW = 0x004264c300000000000000000000000000000000000000000000000000000000;

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
  function totalSupply(uint256 id) public view virtual returns (uint256) {
    assembly {
      mstore(0x00, id)
      mstore(0x20, _totalSupply.slot)
      mstore(0x00, sload(keccak256(0x00, 0x40)))
      return(0x00, 0x20)
    }
  }

  /**
   * @dev Indicates whether any token exist with a given id, or not.
   */
  function exists(uint256 id) public view virtual returns (bool) {
    // return ERC1155Supply.totalSupply(id) > 0;
    assembly {
      mstore(0x00, id)
      mstore(0x20, _totalSupply.slot)
      let supply := sload(keccak256(0x00, 0x40))
      if iszero(supply) {
        mstore(0x00, 0)
        return(0x00, 0x20)
      }
      mstore(0x00, 1)
      return(0x00, 0x20)
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

    bytes32 log;

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
    }

    console.logBytes32(log);

    // if (to == address(0)) {
    //   for (uint256 i = 0; i < ids.length; ++i) {
    //     uint256 id = ids[i];
    //     uint256 amount = amounts[i];
    //     uint256 supply = _totalSupply[id];
    //     require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
    //     unchecked {
    //       _totalSupply[id] = supply - amount;
    //     }
    //   }
    // }
  }
}