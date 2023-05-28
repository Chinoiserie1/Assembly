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
  
}