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

  function testFuzz_TryAdd(uint128 a, uint128 b) public pure {
    (bool success, uint256 result) = Math.tryAdd(a, b);
    require(success, "fail tryAdd");
    if (a != 0 && b != 0) {
      require(result > a, "fail get correct result");
      require(result > b, "fail get correct result");
    }
  }

  function testTrySubWithTwoValueEqualZero() public pure {
    (bool success, uint256 result) = Math.trySub(0, 0);
    require(success, "fail try sub with params (0, 0)");
    require(result == 0, "fail get result");
  }

  function testFuzz_TrySub(uint256 a, uint256 b) public pure {
    vm.assume(a > 0);
    vm.assume(b > 0);
    (bool success, uint256 result) = Math.trySub(a, b);
    if (a < b) {
      require(!success, "fail get underflow error");
    } else {
      require(success, "fail trySub");
      require(result < a, "fail try sub result");
    }
  }

  function testFuzz_trySubWithFirstValueEqualZero(uint256 b) public pure {
    vm.assume(b > 0);
    (bool success, ) = Math.trySub(0, b);
    require(!success, "need to fail but dont fail");
  }
}