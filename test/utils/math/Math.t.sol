// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { Math } from "../../../src/utils/math/Math.sol";

contract TestMath is Test {
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
  }

  function testConsoleLog() public {
    console.log("hey");
  }

  function testFuzz_TryAdd(uint128 a, uint128 b) public view {
    (bool success, uint256 result) = Math.tryAdd(a, b);
    require(success, "fail tryAdd");
  }
}