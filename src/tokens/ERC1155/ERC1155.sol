// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/IERC165.sol";
import "./IERC1155.sol";

import "forge-std/Test.sol";

contract ERC1155 {
  // Mapping from token ID to account balances slot 0x00
  mapping(uint256 => mapping(address => uint256)) private _balances;

  // Mapping from account to operator approvals slot 0x01
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // slot 0x02
  string private _name;
  // slot 0x03
  string private _symbol;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  /**
   * @notice return the name of the contract
   * @dev string are not fixed to 32 bytes, if name > 32
   *      need to compute each slot and get the value
   */
  function name() external view returns (string memory) {
    string memory ptr;
    assembly {
      // load free memory ptr
      ptr := mload(0x40)
      let slot := sload(0x02)
      switch and(slot, 1)
      // the name are in the same slot
      case 0 {
        // shr for gas efficiency can also use div
        let size := shr(1, and(slot, 255))
        mstore(ptr, size)
        mstore(add(ptr, 0x20), and(slot, not(255)))
        mstore(0x40, add(add(ptr, 0x20), size))
      }
      // the name is not on the same slot
      case 1 {
        mstore(0x00, 0x02)
        let startSlot := keccak256(0x00, 0x20)
        let size := shr(1, and(slot, 255))
        mstore(ptr, size)
        // compute total memeory slot (size + 31) / 32
        let totalSlot := shr(5, add(size, 0x1F))

        // retrieve name
        for { let i := 0 } lt(i, totalSlot) { i := add(i, 1) } {
          mstore(add(add(ptr, 0x20), mul(0x20, i)), sload(add(startSlot, i)))
        }
        // store the new memory ptrgi
        mstore(0x40, add(add(ptr, 0x20), size))
      }
    }
    // return the ptr of the name in memory
    return ptr;
  }

  /**
   * @notice return the symbol of the contract
   * @dev see name() for more detail
   */
  function symbol() external view returns (string memory) {
    string memory ptr;
    assembly {
      ptr := mload(0x40)
      let slot := sload(0x03)
      switch and(slot, 1)
      case 0 {
        let size := shr(1, and(slot, 255))
        mstore(ptr, size)
        mstore(add(ptr, 0x20), and(slot, not(255)))
        mstore(0x40, add(add(ptr, 0x20), size))
      }
      case 1 {
        mstore(0x00, 0x03)
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

  function balanceOf(address account, uint256 id) external view returns (uint256) {
    assembly {
      mstore(0x00, id)
      mstore(0x20, 0x00) // store _balances.slot
      mstore(0x20, keccak256(0x00, 0x40)) // hash id + slot
      mstore(0x00, account)
      mstore(0x00, sload(keccak256(0x00, 0x40))) // hash account + precedent hash
      return(0x00, 0x20)
    }
  }

  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external view returns (uint256[] memory)
  {
    uint256[] memory ptr;
    assembly {
      ptr := mload(0x40)
      let accountSize := calldataload(0x44)
      let idZise := calldataload(add(0x04, calldataload(0x24)))
      if iszero(eq(accountSize, idZise)) {
        // revert code
        revert(0,0)
      }
      mstore(ptr, idZise)

      for { let i := 0} lt(i, idZise) { i := add(i, 1) } {
        let account := calldataload(add(0x64, mul(i, 0x20)))
        let id := calldataload(add(add(0x24, calldataload(0x24)), mul(i, 0x20)))
        mstore(0x00, id)
        mstore(0x20, 0x00)
        mstore(0x20, keccak256(0x00, 0x40))
        mstore(0x00, account)
        // mstore(add(add(ptr, 0x20), mul(i, 0x20)), sload(keccak256(0x00, 0x40)))
        mstore(add(add(ptr, 0x20), mul(0x20, i)), sload(keccak256(0x00, 0x40)))
      }
      // store the new memory ptr
      mstore(0x40, add(add(ptr, 0x20), mul(idZise, 0x20)))
    }
    return ptr;
  }

  function mint(address user) external {
    _balances[1][user] = 1 ether;
  }
}