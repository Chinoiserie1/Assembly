// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { Math } from "../../../src/utils/math/Math.sol";

uint256 constant MAX_VALUE_UINT256 = (
  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
);
uint256 constant HALF_MAX_VALUE_UINT256 = (
  0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
);
uint256 constant MAX_VALUE_UINT128 = (
  0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
);

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

  // TEST TRY ADD

  function testTryAdd() public pure {
    (bool success, uint256 result) = Math.tryAdd(0, 0);
    require(success, "fail try add");
    require(result == 0, "fail get result");
  }

  function testFuzz_TryAdd(uint128 a, uint128 b) public pure {
    (bool success, uint256 result) = Math.tryAdd(a, b);
    require(success, "fail tryAdd");
    if (a != 0 && b != 0) {
      require(result > a, "fail get correct result");
      require(result > b, "fail get correct result");
    }
  }

  function testFuzz_TryAddWithParamsOverflowShouldReturnFalse(uint256 a, uint256 b) public pure {
    vm.assume(a > HALF_MAX_VALUE_UINT256);
    vm.assume(b > HALF_MAX_VALUE_UINT256);
    (bool success, ) = Math.tryAdd(a, b);
    require(!success, "fail should be false");
  }

  // TEST TRY SUB

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

  // TEST TRY MUL

  function testFuzz_TryMul(uint256 a, uint256 b) public view {
    a = bound(a, 0, MAX_VALUE_UINT128);
    b = bound(b, 0, 4294967295);
    (bool success, uint256 result) = Math.tryMul(a, b);
    require(success, "fail get mul result");
    require(result == a * b, "fail get exact result");
  }

  function testFuzz_TryMulShouldOverflow(uint256 a, uint256 b) public pure {
    vm.assume(a > MAX_VALUE_UINT128);
    vm.assume(b > MAX_VALUE_UINT128);
    (bool success, ) = Math.tryMul(a, b);
    require(!success, "Fail should overflow");
  }

  // TEST TRY DIV

  function testFuzz_TryDiv(uint256 a, uint256 b) public pure {
    (bool success, uint256 result) = Math.tryDiv(a, b);
    if (b == 0) {
      require(!success, "Should fail get div");
      require(result == 0, "fail with zero");
    } else {
      require(success, "fail get div");
      require(result == a / b, "fail get exact result");
    }
  }

  // TEST TRY MOD

  function testFuzz_TryMod(uint256 a, uint256 b) public pure {
    (bool success, uint256 result) = Math.tryMod(a, b);
    require(success, "fail get div");
    if (a == 0 || b == 0) {
      require(result == 0, "fail with zero");
    } else {
      require(result == a % b, "fail get exact result");
    }
  }

  // TEST MAX

  function testFuzz_Max(uint256 a, uint256 b) public pure {
    uint256 result = Math.max(a, b);
    if (a > b) {
      require(result == a, "fail get correct result");
    } else {
      require(result == b, "fail get correct result");
    }
  }

  // TEST MIN

  function testFuzz_Min(uint256 a, uint256 b) public pure {
    uint256 result = Math.min(a, b);
    if (a > b) {
      require(result == b, "fail get correct result");
    } else {
      require(result == a, "fail get correct result");
    }
  }

  // TEST AVERAGE

  function testFuzz_Average(uint256 a, uint256 b) public pure {
    uint256 result = Math.average(a, b);
    uint256 computeRes = (a & b) + (a ^ b) / 2;
    require(result == computeRes, "fail get correct result");
  }

  // TEST CEILDIV

  function testFuzz_CeilDiv(uint256 a, uint256 b) public view {
    vm.assume(b != 0);
    uint256 result = Math.ceilDiv(a, b);
    uint256 computeRes = a == 0 ? 0 : (a - 1) / b + 1;
    console.log(result);
    console.log(computeRes);
    require(result == computeRes, "fail get correct result");
  }
}