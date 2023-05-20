// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/IERC165.sol";
import "./IERC1155.sol";

import "forge-std/Test.sol";

// bytes4(keccak256("accountsAndIdsLengthMissmatch()"))
bytes32 constant ACCOUNTS_AND_IDS_LENGTH_MISSMATCH = 
  0x06894ca700000000000000000000000000000000000000000000000000000000;

// bytes4(keccak256("callFail()"))
bytes32 constant CALL_FAIL = 0x076e644b00000000000000000000000000000000000000000000000000000000;

// bytes4(keccak256("transferToZeroAddress()"))
bytes32 constant TRANSFER_TO_ZERO_ADDRESS = 
  0xec87facc00000000000000000000000000000000000000000000000000000000;

// bytes4(keccak256("insufficientBalance()"))
bytes32 constant INSUFFICIENT_BALANCE = 
  0x47108e3e00000000000000000000000000000000000000000000000000000000;

// bytes4(keccak256("overflow()"))
bytes32 constant OVERFLOW = 0x004264c300000000000000000000000000000000000000000000000000000000;

// bytes4(keccak256("transferToNonERC1155Receiver()"))
bytes32 constant TRANSFER_TO_NON_ERC1155_RECEIVER = 
  0x7a40500d00000000000000000000000000000000000000000000000000000000;

// bytes4(keccak256("operatorNotApproved()"))
bytes32 constant OPERATOR_NOT_APPROVED = 
 0xa207e75400000000000000000000000000000000000000000000000000000000;

// keccak256("ApprovalForAll(address,address,bool)")
bytes32 constant APPROVAL_FOR_ALL_HASH = 
  0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;

// keccak256("TransferSingle(address,address,address,uint256,uint256)")
bytes32 constant TRANSFER_SINGLE_HASH = 
 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62;

// keccak256("TransferBatch(address,address,address,uint256[],uint256[])")
bytes32 constant TRANSFER_BATCH_HASH =
  0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb;

// bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
bytes32 constant ON_ERC1155_RECEIVED =
  0xf23a6e6100000000000000000000000000000000000000000000000000000000;

// bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
bytes32 constant ON_ERC1155_BATCH_RECEIVED = 
  0xbc197c8100000000000000000000000000000000000000000000000000000000;

contract ERC1155 {
  // Mapping from token ID to account balances slot 0x00
  mapping(uint256 => mapping(address => uint256)) public _balances;

  // Mapping from account to operator approvals slot 0x01
  mapping(address => mapping(address => bool)) public _operatorApprovals;

  // slot 0x02
  string private _name;
  // slot 0x03
  string private _symbol;
  // slot 0x04
  string private _uri;

  /**
   * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
   */
  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  /**
   * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
   * transfers.
   */
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  /**
   * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
   * `approved`.
   */
  event ApprovalForAll(address indexed account, address indexed operator, bool approved);

  /**
   * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
   *
   * If an {URI} event was emitted for `id`, the standard
   * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
   * returned by {IERC1155MetadataURI-uri}.
   */
  event URI(string value, uint256 indexed id);

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
        // store the new memory ptr
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

  // need to change with offset and length
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external view returns (uint256[] memory balances)
  {
    assembly {
      balances := mload(0x40)
      let accountSize := calldataload(0x44)
      let idZise := calldataload(add(0x04, calldataload(0x24)))
      if iszero(eq(accountSize, idZise)) {
        // revert code
        mstore(0x00, ACCOUNTS_AND_IDS_LENGTH_MISSMATCH)
        revert(0x00,0x04)
      }
      // store the size in the first slot
      mstore(balances, idZise)

      for { let i := 0} lt(i, idZise) { i := add(i, 1) } {
        let account := calldataload(add(0x64, mul(i, 0x20)))
        let id := calldataload(add(add(0x24, calldataload(0x24)), mul(i, 0x20)))
        mstore(0x00, id)
        mstore(0x20, 0x00)
        mstore(0x20, keccak256(0x00, 0x40))
        mstore(0x00, account)
        mstore(add(add(balances, 0x20), mul(0x20, i)), sload(keccak256(0x00, 0x40)))
      }
      // store the new memory ptr
      mstore(0x40, add(add(balances, 0x20), mul(idZise, 0x20)))
    }
  }

  function setApprovalForAll(address operator, bool approved) external {
    assembly {
      mstore(0x00, caller())
      mstore(0x20, 0x01)
      mstore(0x20, keccak256(0x00, 0x40))
      mstore(0x00, operator)
      sstore(keccak256(0x00, 0x40), approved)
      mstore(0x00, approved)
      log3(0x00, 0x20, APPROVAL_FOR_ALL_HASH, caller(), operator)
    }
  }

  function isApprovedForAll(address account, address operator) external view returns (bool) {
    assembly {
      mstore(0x00, account)
      mstore(0x20, 0x01)
      mstore(0x20, keccak256(0x00, 0x40))
      mstore(0x00, operator)
      mstore(0x00, sload(keccak256(0x00, 0x40)))
      return(0x00, 0x20)
    }

  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data) 
    external
  {
    address operator = msg.sender;
    uint256[] memory ids = _asSingletonArray(id);
    uint256[] memory amounts = _asSingletonArray(amount);
    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    assembly {
      if iszero(to) {
        mstore(0x00, TRANSFER_TO_ZERO_ADDRESS)
        revert(0x00, 0x04)
      }
      // check if approved
      if iszero(eq(operator, from)) {
        mstore(0x00, from)
        mstore(0x20, 0x01)
        mstore(0x20, keccak256(0x00, 0x40))
        mstore(0x00, operator)
        if iszero(sload(keccak256(0x00, 0x40))) {
          mstore(0x00, OPERATOR_NOT_APPROVED)
          revert(0x00, 0x04)
        }
      }
      // from balance
      mstore(0x00, id)
      mstore(0x20, 0x00) // store _balances.slot
      mstore(0x20, keccak256(0x00, 0x40)) // hash id + slot
      mstore(0x00, from)
      let ptrFrom := keccak256(0x00, 0x40)
      let fromBalance := sload(ptrFrom)
      if lt(fromBalance, amount) {
        mstore(0x00, INSUFFICIENT_BALANCE)
        revert(0x00, 0x04)
      }
      sstore(ptrFrom, sub(fromBalance, amount))
      mstore(0x00, to)
      let ptrTo := keccak256(0x00, 0x40)
      let toBalance := sload(ptrTo)
      sstore(ptrTo, add(toBalance, amount))
      if lt(add(toBalance, amount), toBalance) {
        mstore(0x00, OVERFLOW)
        revert(0x00, 0x04)
      }
      // emit event
      mstore(0x00, id)
      mstore(0x20, amount)
      log4(0x00, 0x40, TRANSFER_SINGLE_HASH, operator, from, to)
    }

    _afterTokenTransfer(operator, from, to, ids, amounts, data);
    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  )
    external
  {
    address operator = msg.sender;
    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    assembly {
      let ptr := mload(0x40)
      // check size ids & amounts
      if iszero(eq(ids.length, amounts.length)) {
        mstore(0x00, ACCOUNTS_AND_IDS_LENGTH_MISSMATCH)
        revert(0x00,0x04)
      }
      // check if approved
      if iszero(eq(operator, from)) {
        mstore(0x00, from)
        mstore(0x20, 0x01)
        mstore(0x20, keccak256(0x00, 0x40))
        mstore(0x00, operator)
        if iszero(sload(keccak256(0x00, 0x40))) {
          mstore(0x00, OPERATOR_NOT_APPROVED)
          revert(0x00, 0x04)
        }
      }
      // store ids and amounts length for emit event
      mstore(ptr, ids.length)
      let ptrStartAmountEvent := add(add(ptr, 0x20), mul(ids.length, 0x20))
      mstore(ptrStartAmountEvent, amounts.length)

      for { let i := 0 } lt(i, ids.length) { i := add(i, 1) } {
        let id := calldataload(add(ids.offset, mul(i, 0x20)))
        let amount := calldataload(add(amounts.offset, mul(i, 0x20)))
        // check balance
        mstore(0x00, id)
        mstore(0x20, 0x00) // store _balances.slot
        mstore(0x20, keccak256(0x00, 0x40)) // hash id + slot
        mstore(0x00, from)
        let ptrFrom := keccak256(0x00, 0x40)
        let fromBalance := sload(ptrFrom)
        if lt(fromBalance, amount) {
          mstore(0x00, INSUFFICIENT_BALANCE)
          revert(0x00, 0x04)
        }
        // store the new balance
        sstore(ptrFrom, sub(fromBalance, amount))
        // compute balance to
        mstore(0x00, to)
        let ptrTo := keccak256(0x00, 0x40)
        let toBalance := sload(ptrTo)
        // store the new balance to
        sstore(ptrTo, add(toBalance, amount))
        // check overflow
        if lt(add(toBalance, amount), toBalance) {
          mstore(0x00, OVERFLOW)
          revert(0x00, 0x04)
        }
        // store id for emit event
        mstore(add(add(ptr, 0x20), mul(i, 0x20)), id)
        // store amount for emit event
        mstore(add(add(ptrStartAmountEvent, 0x20), mul(i, 0x20)), amount)
      }
      mstore(0x00, ptr)
      mstore(0x20, ptrStartAmountEvent)
      log4(
        0x00,
        add(add(ptrStartAmountEvent, 0x20), mul(amounts.length, 0x20)),
        TRANSFER_BATCH_HASH,
        operator,
        from,
        to
      )
      // store the new memory ptr
      mstore(0x40, add(add(ptrStartAmountEvent, 0x20), mul(amounts.length, 0x20)))
    }

    _afterTokenTransfer(operator, from, to, ids, amounts, data);
    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  // for test purpose
  function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
    _balances[id][to] += amount;
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal {}

  function _afterTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) 
    private
  {
    assembly {
      // check if address to is a contract
      if gt(extcodesize(to), 0) {
        let ptr := mload(0x40)
        // store call info
        mstore(ptr, ON_ERC1155_RECEIVED)
        mstore(add(ptr, 0x04), operator)
        mstore(add(ptr, 0x24), from)
        mstore(add(ptr, 0x44), id)
        mstore(add(ptr, 0x64), amount)
        mstore(add(ptr, 0x84), 0xa0)
        // store the size of data
        mstore(add(ptr, 0xa4), data.length)
        let startSlot := add(ptr, 0xc4)
        let totalSlot := shr(5, add(data.length, 0x1F))
        // store all the data
        for { let i := 0 } lt(i, totalSlot) { i := add(i, 1) } {
          mstore(add(startSlot, mul(i, 0x20)), calldataload(add(data.offset, mul(i, 0x20))))
        }
        let totalSize := add(0xe4, mul(totalSlot, 0x20))
        // perform call
        let callstatus := call(gas(), to, 0, ptr, totalSize, 0x00, 0x20)
        if iszero(callstatus) {
          mstore(0x00, CALL_FAIL)
          revert(0x00, 0x04)
        }
        if iszero(and(mload(0x00),  ON_ERC1155_RECEIVED)) {
          mstore(0x00, TRANSFER_TO_NON_ERC1155_RECEIVER)
          revert(0x00, 0x04)
        }
        // store the new memory ptr
        mstore(0x40, add(ptr, totalSize))
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  )
    private
  {
    assembly {
      let ptr := mload(0x40)
      // check if address to is a contract
      if gt(extcodesize(to), 0) {
        // get start pointer of ids & amounts
        let startIdsPtr := add(ptr, 0xa4)
        let startAmountsPtr := add(add(startIdsPtr, 0x20), mul(ids.length, 0x20))
        let startDataPtr := add(add(startAmountsPtr, 0x20), mul(amounts.length, 0x20))
        // store call info
        mstore(ptr, ON_ERC1155_BATCH_RECEIVED)
        mstore(add(ptr, 0x04), operator)
        mstore(add(ptr, 0x24), from)
        mstore(add(ptr, 0x44), 0xa0)
        mstore(add(ptr, 0x64), add(0xc0, mul(ids.length, 0x20)))
        mstore(add(ptr, 0x84), add(add(0xe0, mul(ids.length, 0x20)), mul(amounts.length, 0x20)))
        // store size ids, amounts & data
        mstore(startIdsPtr, ids.length)
        mstore(startAmountsPtr, amounts.length)
        mstore(startDataPtr, data.length)
        // store ids & amounts datas
        for { let i := 0 } lt(i, ids.length) { i := add(i, 1) } {
          mstore(add(add(startIdsPtr, 0x20), mul(i, 0x20)), calldataload(add(ids.offset, mul(i, 0x20))))
          mstore(add(add(startAmountsPtr, 0x20), mul(i, 0x20)), calldataload(add(amounts.offset, mul(i, 0x20))))
        }
        // get total slot of data
        let totalSlotData := shr(5, add(data.length, 0x1F))
        // store data datas
        for { let i := 0} lt(i, totalSlotData) { i := add(i, 1) } {
          mstore(add(add(startDataPtr, 0x20), mul(i, 0x20)), calldataload(add(data.offset, mul(i, 0x20))))
        }
        // [0xa4 + 0x60 = call info + size * (ids, amounts, data)] + length ids, amounts, data
        let totalSize := add(0x104, add(mul(2, mul(ids.length, 0x20)), mul(totalSlotData, 0x20)))

        // perform call
        let callstatus := call(gas(), to, 0, ptr, totalSize, 0x00, 0x20)
        if iszero(callstatus) {
          mstore(0x00, CALL_FAIL)
          revert(0x00, 0x04)
        }
        if iszero(and(mload(0x00),  ON_ERC1155_BATCH_RECEIVED)) {
          mstore(0x00, TRANSFER_TO_NON_ERC1155_RECEIVER)
          revert(0x00, 0x04)
        }
        // store the new memory ptr
        mstore(0x40, add(ptr, totalSize))
      }
    }
  }

  // need to convert to assembly
  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}