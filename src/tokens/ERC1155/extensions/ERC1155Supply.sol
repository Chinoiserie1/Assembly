// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../ERC1155.sol";

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
}