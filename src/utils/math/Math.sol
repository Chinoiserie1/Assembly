// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Code from openzepplin in YUL

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Muldiv operation overflow.
   */
  error MathOverflowedMulDiv();

  enum Rounding {
    Down, // Toward negative infinity
    Up, // Toward infinity
    Zero // Toward zero
  }

  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
    assembly {
      let c := add(a, b)
      success := 1
      result := c
      if lt(c, a) {
        success := 0
        result := 0
      }
    }
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
    assembly {
      success := 1
      result := sub(a, b)
      if gt(b, a) {
        success := 0
        result := 0
      }
    }
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
    assembly {
      success := 1
      result := mul(a, b)
      if iszero(eq(div(result, a), b)) {
        success := 0
        result := 0
      }
      if or(iszero(a), iszero(b)) {
        success := 1
        result := 0
      }
    }
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
    assembly {
      success := 1
      result := div(a, b)
      if iszero(b) {
        success := 0
        result := 0
      }
    }
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
    assembly {
      success := 1
      result := mod(a, b)
      if or(iszero(a), iszero(b)) {
        result := 0
      }
    }
  }

  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256 result) {
    assembly {
      result := b
      if gt(a, b) {
        result := a
      }
    }
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256 result) {
    assembly {
      result := b
      if lt(a, b) {
        result := a
      }
    }
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256 result) {
    // (a + b) / 2 can overflow.
    assembly {
      result := add(and(a, b), div(xor(a, b), 2))
    }
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b == 0) {
      // Guarantee the same behavior as in a regular Solidity division.
      return a / b;
    }

    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a == 0 ? 0 : (a - 1) / b + 1;
  }
}