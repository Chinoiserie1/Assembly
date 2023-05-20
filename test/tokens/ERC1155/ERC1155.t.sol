// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../../src/tokens/ERC1155/ERC1155.sol";

error accountsAndIdsLengthMissmatch();
error callFail();
error transferToNonERC1155Receiver();
error transferToZeroAddress();
error insufficientBalance();
error overflow();
error operatorNotApproved();

contract ERC1155Receiver {
   function onERC1155Received(
    address _operator,
    address _from,
    uint256 _id,
    uint256 _value,
    bytes calldata _data)
    external returns(bytes4)
  {
    return 0xf23a6e61;
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4) {
    return 0xbc197c81;
  }
}

contract MyERC1155 is ERC1155 {
  constructor() ERC1155("testERC1155", "TST") {}

  function mint(address to, uint256 id, uint256 amount, bytes calldata data) external {
    _mint(to, id, amount, data);
  }
}

contract ERC1155Test is Test {
  ERC1155 public erc1155;
  ERC1155Receiver public erc1155Receiver;
  MyERC1155 public testERC1155;

  string name = "nameTestAAAAAAAAAAAAAAAAAAnameTestAAAAAAAAAAAAAAAAAA";
  string symbol = "NTST";
  uint256 maxSupply = 1000000 ether;

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
    erc1155 = new ERC1155(name, symbol);
    erc1155Receiver = new ERC1155Receiver();
    testERC1155 = new MyERC1155();
  }

  // function testLog() public view {
  //   console.logBytes4(bytes4(keccak256("accountsAndIdsLengthMissmatch()")));
  //   console.logBytes32(keccak256("ApprovalForAll(address,address,bool)"));
  //   console.logBytes4(bytes4(keccak256("callFail()")));
  //   console.logBytes4(bytes4(keccak256("transferToNonERC1155Receiver()")));
  //   console.logBytes4(bytes4(keccak256("transferToZeroAddress()")));
  //   console.logBytes4(bytes4(keccak256("insufficientBalance()")));
  //   console.logBytes4(bytes4(keccak256("overflow()")));
  //   console.logBytes32(keccak256("TransferSingle(address,address,address,uint256,uint256)"));
  //   console.logBytes4(bytes4(keccak256("operatorNotApproved()")));
  //   console.logBytes32(keccak256("TransferBatch(address,address,address,uint256[],uint256[])"));
  // }

  function testERC1155SafeTransferFrom() public {
    testERC1155.mint(user1, 1, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    testERC1155.safeTransferFrom(user1, address(erc1155Receiver), 1, 10, "");
  }

  function testERC1155SafeBatchTransferFrom() public {
    testERC1155.mint(user1, 1, 100, "");
    testERC1155.mint(user1, 2, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 20;
    amounts[1] = 50;
    testERC1155.safeBatchTransferFrom(user1, user2, ids, amounts, "");
    uint256 balanceId1 = testERC1155.balanceOf(user2, 1);
    uint256 balanceId2 = testERC1155.balanceOf(user2, 2);
    require(balanceId1 == 20, "fail batch transfer");
    require(balanceId2 == 50, "fail batch transfer");
  }

  function testERC1155SafeBatchTransferFromToERC1155ReceiverContract() public {
    testERC1155.mint(user1, 1, 100, "");
    testERC1155.mint(user1, 2, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 20;
    amounts[1] = 50;
    testERC1155.safeBatchTransferFrom(user1, address(erc1155Receiver), ids, amounts, "");
    uint256 balanceId1 = testERC1155.balanceOf(address(erc1155Receiver), 1);
    uint256 balanceId2 = testERC1155.balanceOf(address(erc1155Receiver), 2);
    require(balanceId1 == 20, "fail batch transfer");
    require(balanceId2 == 50, "fail batch transfer");
  }

  function testApprovalForAll() public {
    erc1155.setApprovalForAll(user1, true);
    bool approved = erc1155.isApprovedForAll(owner, user1);
    require(approved == true, "fail set approval for all");
  }
}