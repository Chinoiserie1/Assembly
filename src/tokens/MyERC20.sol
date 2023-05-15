// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "./Interfaces/IERC20.sol";

// first 4 bit keccak256("addressZero()") 
bytes32 constant ADDRESS_ZERO = 0x7299a72900000000000000000000000000000000000000000000000000000000;
// first 4 bit keccak256("quantityZero()")
bytes32 constant QUANTITY_ZERO = 0xb031b0f000000000000000000000000000000000000000000000000000000000;
// first 4 bit keccak256("maxSupplyReach()")
bytes32 constant MAX_SUPPLY_REACH = 0xc8f37d3300000000000000000000000000000000000000000000000000000000;
// first 4 bit keccak256("callerNotOwner()")
bytes32 constant CALLER_NOT_OWNER = 0xbbe424b900000000000000000000000000000000000000000000000000000000;
// first 4 bit keccak256("insufficientBalance()")
bytes32 constant INSUFFICIENT_BALANCE = 0x47108e3e00000000000000000000000000000000000000000000000000000000;
// first 4 bit keccak256("overflow()")
bytes32 constant OVERFLOW = 0x004264c300000000000000000000000000000000000000000000000000000000;
// keccak256("Transfer(address,address,uint256)")
bytes32 constant TRANSFER_HASH = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
// keccak256("Approval(address,address,uint256)")
bytes32 constant APPROVAL_HASH = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;
// keccak256("TransferOwnership(address,address)")
bytes32 constant TRANSFER_OWNERSHIP_HASH = 0x5c486528ec3e3f0ea91181cff8116f02bfa350e03b8b6f12e00765adbb5af85c;

/**
 * @title MyERC20
 * @author chixx.eth
 * @notice YUL ERC20 with ownable, mint, burn & a max supply
 */
contract MyERC20 {
  // slot 0x00
  mapping(address => uint256) private balances;
  // slot 0x01
  mapping(address => mapping (address => uint256)) private allowances;
  // slot 0x02
  uint256 private _currentSupply;
  // slot 0x03
  uint256 private _maxSupply;
  // slot 0x04
  string private _name;
  // slot 0x05
  string private _symbol;
  // slot 0x06
  address private _owner;

  // https://docs.soliditylang.org/en/v0.8.19/abi-spec.html#events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event TransferOwnership(address indexed previousOwner, address indexed newOwner);

  constructor(string memory name_, string memory symbol_, uint256 maxSupply_) {
    _owner = msg.sender;
    _name = name_;
    _symbol = symbol_;
    _maxSupply = maxSupply_;
    emit TransferOwnership(address(0), msg.sender);
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
   * @notice transfer the ownership to another address
   * @param newOwner address of the new owner of the contract
   */
  function transferOwnership(address newOwner) public onlyOwner {
    assembly {
      let previousOwner := sload(_owner.slot)
      sstore(_owner.slot, newOwner)
      log3(0x00, 0x00, TRANSFER_OWNERSHIP_HASH, previousOwner, newOwner)
    }
  }

  /**
   * @notice get the owner f the contract
   */
  function owner() public view returns (address) {
    assembly {
      mstore(0x00, sload(0x06))
      return(0x00, 0x20)
    }
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
      let slot := sload(0x04)
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
        mstore(0x00, 0x04)
        let startSlot := keccak256(0x00, 0x20)
        let size := shr(1, and(slot, 255))
        mstore(ptr, size)
        // compute total memeory slot (size + 31) / 32
        let totalSlot := shr(5, add(size, 0x1F))

        // retrieve name
        for { let i := 0 } lt(i, totalSlot) { i := add(i, 1) } {
          mstore(add(add(ptr, 0x20), mul(0x20, i)), sload(add(startSlot, i)))
        }
        // store the new memory ptrg
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
      let slot := sload(0x05)
      switch and(slot, 1)
      case 0 {
        let size := shr(1, and(slot, 255))
        mstore(ptr, size)
        mstore(add(ptr, 0x20), and(slot, not(255)))
        mstore(0x40, add(add(ptr, 0x20), size))
      }
      case 1 {
        mstore(0x00, 0x05)
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

  function mint(address _to, uint256 _quantity) external onlyOwner {
    _mint(_to, _quantity);
  }

  /**
   * @notice mint (create new token) for a given address
   * @dev _currentSupply.slot = 0x02
   *      _maxSupply.slot = 0x03
   * @param _to address that will be credited the token
   * @param _quantity amount tha will be minted to the address _to
   */
  function _mint(address _to, uint256 _quantity) internal {
    assembly {
      // if address zero revert with error addressZero();
      if iszero(_to) {
        mstore(0x00, ADDRESS_ZERO)
        revert(0x00, 0x04)
      }
      // if quantity zero revert with error quantityZero();
      if iszero(_quantity) {
        mstore(0x00, QUANTITY_ZERO)
        revert(0x00, 0x04)
      }
      let newSupply := add(_quantity, sload(0x02))
      // check if overflow
      if lt(newSupply, _quantity) {
        mstore(0x00, OVERFLOW)
        revert(0x00, 0x04)
      }
      // check supply dont reach max supply
      if gt(newSupply, sload(0x03)) {
        mstore(0x00, MAX_SUPPLY_REACH)
        revert(0x00, 0x04)
      }
      // store new currentSupply
      sstore(0x02, newSupply)
      // populate mapping
      mstore(0x00, _to)
      mstore(0x20, 0x00) // use 0x00 because first storage slot or balances.slot
      let slot := keccak256(0x00, 0x40)
      sstore(slot, add(sload(slot), _quantity))
      // emit event Transfer(address(0), _to, _quantity);
      mstore(0x00, _quantity)
      log3(0x00, 0x20, TRANSFER_HASH, 0x00, _to)
    }
  }

  /**
   * @notice transfer token from caller to receiver
   * @param to address that receive the token
   * @param amount amount token transfer to receiver
   */
  function transfer(address to, uint256 amount) external returns (bool) {
    assembly {
      mstore(0x00, caller())
      mstore(0x20, 0x00)
      let slotCaller := keccak256(0x00, 0x40)
      let amountCaller := sload(slotCaller)
      // check amount
      if lt(amountCaller, amount) {
        mstore(0x00, INSUFFICIENT_BALANCE)
        revert(0x00, 0x04)
      }
      mstore(0x00, to)
      let slotTo := keccak256(0x00, 0x40)
      let amountTo := sload(slotTo)
      // update new caller balance
      sstore(slotCaller, sub(amountCaller, amount))
      amountTo := add(amountTo, amount)
      // check overflow
      if lt(amountTo, amount) {
        mstore(0x00, OVERFLOW)
        revert(0x00, 0x04)
      }
      // update new to balance
      sstore(slotTo, amountTo)
      // emit Transfer event
      mstore(0x00, amount)
      log3(0x00, 0x20, TRANSFER_HASH, caller(), to)
      mstore(0x00, 0x01)
      return(0x00, 0x20)
    }
  }

  /**
   * @notice approve a user to spend tokens
   *         if a user already have amount approved it will override
   * @param spender address who can spend the allowance
   * @param amount amount the spender can spend
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    assembly {
      mstore(0x00, caller())
      mstore(0x20, 0x01)
      mstore(0x20, keccak256(0x00, 0x40))
      mstore(0x00, spender)
      sstore(keccak256(0x00, 0x40), amount)
      mstore(0x00, amount)
      log3(0x00, 0x20, APPROVAL_HASH, caller(), spender)
      mstore(0x00, 0x01)
      return(0x00, 0x20)
    }
  }

  function burn(uint256 _quantity) external {
    _burn(_quantity);
  }

  /**
   * @notice burn an amount of tokens
   * @dev _currentSupply = 0x02
   * @param _quantity amount token to burn
   */
  function _burn(uint256 _quantity) internal {
    assembly {
      mstore(0x00, caller())
      mstore(0x20, 0x00)
      let slot := keccak256(0x00, 0x40)
      let currentAmountCaller := sload(slot)
      if lt(currentAmountCaller, _quantity) {
        mstore(0x00, INSUFFICIENT_BALANCE)
        revert(0x00, 0x04)
      }
      sstore(0x02, sub(sload(0x02), _quantity))
      sstore(slot, sub(currentAmountCaller, _quantity))
      mstore(0x00, _quantity)
      log3(0x00, 0x20, TRANSFER_HASH, caller(), 0x00)
    }
  }

  /**
   * @notice get the approved value
   * @param owner address that approve tokens
   * @param spender address that can spend tokens
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    assembly {
      mstore(0x00, owner)
      mstore(0x20, 0x01)
      mstore(0x20, keccak256(0x00, 0x40))
      mstore(0x00, spender)
      mstore(0x00, sload(keccak256(0x00, 0x40)))
      return(0x00, 0x20)
    }
  }

  /**
   * @notice get the total circulating supply
   */
  function totalSupply() external view returns (uint256) {
    assembly {
      mstore(0x00, sload(0x02))
      return(0x00, 0x20)
    }
  }

  /**
   * @notice get the balance of a given address
   * @param account address to get the balance
   */
  function balanceOf(address account) external view returns (uint256) {
    assembly {
      mstore(0x00, account)
      mstore(0x20, 0x00)
      let slot := keccak256(0x00, 0x40)
      mstore(0x00, sload(slot))
      return(0x00, 0x20)
    }
  }

  /**
   * @notice get the max supply that can be minted
   * @dev _maxSupply.slot = 0x03
   */
  function maxSupply() external view returns (uint256) {
    assembly {
      mstore(0x00, sload(0x03))
      return(0x00, 0x20)
    }
  }
}
