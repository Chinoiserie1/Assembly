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
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    bool success = true;
    uint256 result;
    assembly {
gi      result := sub(a, b)
      if gt(b, a) {
        success := 0
        result := 0
      }
    }
    return (success, result);
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    assembly {
      if iszero(a) {
        mstore(0x00, 1)
        mstore(0x20, 0)
        return(0x00, 0x40)
      }
      let c := mul(a, b)
      if iszero(eq(div(c, a), b)) {
        mstore(0x00, 0)
        mstore(0x20, 0)
        return(0x00, 0x40)
      }
      mstore(0x00, 1)
      mstore(0x20, c)
      return(0x00, 0x40)
    }
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    assembly {
      if iszero(b) {
        mstore(0x00, 0)
        mstore(0x20, 0)
        return(0x00, 0x40)
      }
      mstore(0x00, 1)
      mstore(0x20, div(a, b))
      return(0x00, 0x40)
    }
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    assembly {
      if iszero(b) {
        mstore(0x00, 0)
        mstore(0x20, 0)
        return(0x00, 0x40)
      }
      mstore(0x00, 0)
      mstore(0x20, mod(a, b))
      return(0x00, 0x40)
    }
  }

  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    assembly {
      if gt(a, b) {
        mstore(0x00, a)
        return(0x00, 0x20)
      }
      mstore(0x00, b)
      return(0x00, 0x20)
    }
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    assembly {
      if lt(a, b) {
        mstore(0x00, a)
        return(0x00, 0x20)
      }
      mstore(0x00, b)
      return(0x00, 0x20)
    }
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
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