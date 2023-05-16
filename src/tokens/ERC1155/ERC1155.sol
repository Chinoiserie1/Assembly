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

// bytes4(keccak256("transferToNonERC1155Receiver()"))
bytes32 constant TRANSFER_TO_NON_ERC1155_RECEIVER = 
  0x7a40500d00000000000000000000000000000000000000000000000000000000;

bytes32 constant APPROVAL_FOR_ALL_HASH = 
  0x625ed98187814316ab2cce6290cc517e4fa7fa0b604af464c9424177ee1a0ea2;

bytes32 constant ON_ERC1155_RECEIVED =
  0xf23a6e6100000000000000000000000000000000000000000000000000000000;

contract ERC1155 {
  // Mapping from token ID to account balances slot 0x00
  mapping(uint256 => mapping(address => uint256)) public _balances;

  // Mapping from account to operator approvals slot 0x01
  mapping(address => mapping(address => bool)) public _operatorApprovals;

  // slot 0x02
  string private _name;
  // slot 0x03
  string private _symbol;

  /**
   * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
   */
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    }

    _afterTokenTransfer(operator, from, to, ids, amounts, data);
    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  // for testgi
  function mint(address user) external {
    _balances[1][user] += 1 ether;
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
    bytes memory data
  ) private {
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
        // store the size of data
        let size := mload(data)
        mstore(add(ptr, 0x84), size)
        let startSlot := add(ptr, 0xa4)
        let totalSlot := shr(5, add(size, 0x1F))
        // store all the data
        for { let i := 0 } lt(i, totalSlot) { i := add(i, 1) } {
          mstore(add(startSlot, mul(i, 0x20)), mload(add(add(data, 0x20), mul(i, 0x20))))
        }
        let totalSize := add(0xa4, mul(totalSlot, 0x20))
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

  // need to convert to assembly
  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}