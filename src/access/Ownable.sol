// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// first 4 bit keccak256("callerNotOwner()")
bytes32 constant CALLER_NOT_OWNER = 0xbbe424b900000000000000000000000000000000000000000000000000000000;
// bytes4(keccak256("OwnerSetToAddressZero()"))
bytes32 constant OWNER_SET_TO_ADDRESS_ZERO = 
  0x059a159a00000000000000000000000000000000000000000000000000000000;
// keccak256("OwnershipTransferred(address,address)")
bytes32 constant TRANSFER_OWNERSHIP_HASH = 
  0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;


contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    assembly {
      sstore(_owner.slot, caller())
    }
  }

  modifier onlyOwner() {
    assembly {
      if iszero(eq(caller(), sload(_owner.slot))) {
        mstore(0x00, CALLER_NOT_OWNER)
        revert(0x00, 0x04)
      }
    }
    _;
  }

  /**
   * @notice get the owner f the contract
   */
  function owner() public view returns (address) {
    assembly {
      mstore(0x00, sload(_owner.slot))
      return(0x00, 0x20)
    }
  }

  function transferOwnership(address newOwner) public onlyOwner {
    assembly {
      if eq(newOwner, 0x00) {
        mstore(0x00, OWNER_SET_TO_ADDRESS_ZERO)
        revert(0x00, 0x04)
      }
    }
    _transferOwnership(newOwner);
  }

  function renounceOwnership() public onlyOwner {
    _transferOwnership(address(0));
  }

  function _transferOwnership(address newOwner) internal {
    assembly {
      let previousOwner := sload(_owner.slot)
      sstore(_owner.slot, newOwner)
      log3(0x00, 0x00, TRANSFER_OWNERSHIP_HASH, previousOwner, newOwner)
    }
  }
}