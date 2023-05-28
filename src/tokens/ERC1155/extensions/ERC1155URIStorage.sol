// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../ERC1155.sol";

import "forge-std/Test.sol";

abstract contract ERC1155URIStorage is ERC1155 {
  // Optional base URI
  string private _baseURI = "";

  // Optional mapping for token URIs
  mapping(uint256 => string) public _tokenURIs;

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * This implementation returns the concatenation of the `_baseURI`
   * and the token-specific uri if the latter is set
   *
   * This enables the following behaviors:
   *
   * - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
   *   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
   *   is empty per default);
   *
   * - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
   *   which in most cases will contain `ERC1155._uri`;
   *
   * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
   *   uri value set, then the result is empty.
   */
  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    string memory baseURI = _getBaseURI();
    string memory tokenURI = _getTokenURIs(tokenId);

    assembly {
      let sizeBaseURI := mload(baseURI)
      let sizeTokenURI := mload(tokenURI)
      let totalSize := add(sizeBaseURI, sizeTokenURI)
      if gt(sizeTokenURI, 0) {
        if iszero(sizeBaseURI) {
          mstore(0x00, tokenURI)
          return(0x00, mload(0x40))
        }
        let ptr := mload(0x40)
        mstore(ptr, totalSize)
        let totalSlotBaseUri := shr(5, add(sizeBaseURI, 0x1F))
        for { let i := 0 } lt(i, totalSlotBaseUri) { i := add(i, 1) } {
          mstore(add(add(ptr, 0x20), mul(i, 0x20)), mload(add(add(baseURI, 0x20), mul(i, 0x20))))
        }
        let subSize := sub(32, mod(sizeBaseURI, 32))
        let totalSLotTokenURI := shr(5, add(sizeTokenURI, 0x1F))
        let startSlotTokenURI := sub(add(add(ptr, 0x20), mul(totalSlotBaseUri, 0x20)), subSize)
        for { let i := 0 } lt(i, totalSLotTokenURI) { i := add(i, 1) } {
          mstore(add(startSlotTokenURI, mul(i, 0x20)), mload(add(add(tokenURI, 0x20), mul(i, 0x20))))
        }
        mstore(0x40, add(add(ptr, 0x20), totalSize))
        mstore(0x00, ptr)
        return(0x00, mload(0x40))
      }
    }
    return super.uri(tokenId);
  }

  /**
   * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
   */
  function _setURI(uint256 tokenId, string calldata tokenURI) internal virtual {
    assembly {
      mstore(0x00, tokenId)
      mstore(0x20, _tokenURIs.slot)
      let slot := keccak256(0x00, 0x40)
      switch lt(tokenURI.length, 32)
      case 1 {
         // string store in the same slot
        mstore(0x00, calldataload(tokenURI.offset))
        mstore(0x1f, shl(248, mul(tokenURI.length, 2)))
        sstore(slot, mload(0x00))
      }
      case 0 {
        // string store in multiple slot
        mstore(0x00, slot)
        let startSlot := keccak256(0x00, 0x20)
        let totalSlot := shr(5, add(tokenURI.length, 0x1F))
        sstore(slot, add(shl(1, tokenURI.length), 1))
        for { let i := 0 } lt(i, totalSlot) { i := add(i, 1) } {
          sstore(add(startSlot, i), calldataload(add(tokenURI.offset, mul(i, 0x20))))
        }
      }
    }
  }

  /**
   * @dev Sets `baseURI` as the `_baseURI` for all tokens
   */
  function _setBaseURI(string calldata baseURI) internal {
    assembly {
      switch lt(baseURI.length, 32)
      case 1 {
        // string store in the same slot
        mstore(0x00, calldataload(baseURI.offset))
        mstore(0x1f, shl(248, mul(baseURI.length, 2)))
        sstore(_baseURI.slot, mload(0x00))
      }
      case 0 {
        // string store in multiple slot
        mstore(0x00, _baseURI.slot)
        let startSlot := keccak256(0x00, 0x20)
        let totalSlot := shr(5, add(baseURI.length, 0x1F))
        sstore(_baseURI.slot, add(shl(1, baseURI.length), 1))
        for { let i := 0 } lt(i, totalSlot) { i := add(i, 1) } {
          sstore(add(startSlot, i), calldataload(add(baseURI.offset, mul(i, 0x20))))
        }
      }
    }
  }

  function _getTokenURIs(uint256 tokenId) private view returns(string memory) {
    string memory ptr;
    assembly {
      ptr := mload(0x40)
      mstore(0x00, tokenId)
      mstore(0x20, _tokenURIs.slot)
      let slotPtr := keccak256(0x00, 0x40)
      let slot := sload(slotPtr)
      switch and(slot, 1)
      case 0 {
        let size := shr(1, and(slot, 255))
        mstore(ptr, size)
        mstore(add(ptr, 0x20), and(slot, not(255)))
        mstore(0x40, add(add(ptr, 0x20), size))
      }
      case 1 {
        mstore(0x00, slotPtr)
        let startSlot := keccak256(0x00, 0x20)
        let size := shr(1, and(slot, 255))
        mstore(ptr, size)
        let totalSlot := shr(5, add(size, 0x1F))
        for { let i := 0 } lt(i, totalSlot) { i := add(i, 1) } {
          mstore(add(add(ptr, 0x20), mul(0x20, i)), sload(add(startSlot, i)))
        }
        mstore(0x40, add(add(ptr, 0x20), size))
      }
    }
    return ptr;
  }

  function _getBaseURI() private view returns(string memory) {
    string memory ptr;
    assembly {
      ptr := mload(0x40)
      let slot := sload(_baseURI.slot)
      switch and(slot, 1)
      case 0 {
        let size := shr(1, and(slot, 255))
        mstore(ptr, size)
        mstore(add(ptr, 0x20), and(slot, not(255)))
        mstore(0x40, add(add(ptr, 0x20), size))
      }
      case 1 {
        mstore(0x00, _baseURI.slot)
        let startSlot := keccak256(0x00, 0x20)
        let size := shr(1, and(slot, 255))
        mstore(ptr, size)
        let totalSlot := shr(5, add(size, 0x1F))
        for { let i := 0 } lt(i, totalSlot) { i := add(i, 1) } {
          mstore(add(add(ptr, 0x20), mul(0x20, i)), sload(add(startSlot, i)))
        }
        mstore(0x40, add(add(ptr, 0x20), size))
      }
    }
    return ptr;
  }
}