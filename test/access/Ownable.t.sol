// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../src/access/Ownable.sol";

error ownerSetToAddressZero();
error callerNotOwner();

contract OwnableTest is Test {
  Ownable public ownable;

  uint256 internal ownerPrivateKey;
  address internal owner;
  uint256 internal user1PrivateKey;
  address internal user1;
  uint256 internal user2PrivateKey;
  address internal user2;

  function setUp() public {
    ownerPrivateKey = 0xA11CE;
    owner = vm.addr(ownerPrivateKey);
    user1PrivateKey = 0xB0B;
    user1 = vm.addr(user1PrivateKey);
    user2PrivateKey = 0xFE55E;
    user2 = vm.addr(user2PrivateKey);

    vm.startPrank(owner);

    ownable = new Ownable();
  }

  function testGetOwner() public view {
    address _owner = ownable.owner();
    require(_owner == owner, "fail get owner");
  }

  function testTransferOwnership() public {
    ownable.transferOwnership(user1);
    address _owner = ownable.owner();
    require(_owner == user1, "fail transfer ownership");
  }

  function testTransferOwnershipFailCallerNotOwner() public {
    vm.stopPrank();
    vm.startPrank(user1);
    vm.expectRevert(callerNotOwner.selector);
    ownable.transferOwnership(user1);
  }

  function testTransferOwnershipFailToAddressZero() public {
    vm.expectRevert(ownerSetToAddressZero.selector);
    ownable.transferOwnership(address(0));
  }

  function testRenonceOwnership() public {
    ownable.renounceOwnership();
    address _owner = ownable.owner();
    require(_owner == address(0), "fail renonce ownership");
  }

  function testRenonceOwnershipFailCallerNotOwner() public {
    vm.stopPrank();
    vm.startPrank(user1);
    vm.expectRevert(callerNotOwner.selector);
    ownable.renounceOwnership();
  }
}