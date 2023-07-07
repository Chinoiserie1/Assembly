// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Code from openzepplin

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
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    assembly {
      let c := add(a, b)
      if iszero(lt(c, a)) {
        mstore(0x00, 0)
        mstore(0x20, c)
        return(0x00, 0x40)
      }
      mstore(0x00, 1)
      mstore(0x20, c)
      return(0x00, 0x40)
    }
  }
}