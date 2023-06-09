// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../../src/tokens/ERC1155/ERC1155.sol";

error accountsAndIdsLengthMissmatch();
error amountsAndIdsLengthMissmatch();
error callFail();
error transferToNonERC1155Receiver();
error transferToZeroAddress();
error transferFromZeroAddress();
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
  constructor() ERC1155("testERC1155", "TST", "baseUri") {}

  function mint(address to, uint256 id, uint256 amount, bytes calldata data) external {
    _mint(to, id, amount, data);
  }

  function mintBatch(address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  )
    external
  {
    _mintBatch(to, ids, amounts, data);
  }

  function burn(address from, uint256 id, uint256 amount) external {
    _burn(from, id, amount);
  }

  function burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts) external {
    _burnBatch(from, ids, amounts);
  }

  function setURI(string calldata newuri) external {
    _setURI(newuri);
  }
}

contract ERC1155Test is Test {
  ERC1155 public erc1155;
  ERC1155Receiver public erc1155Receiver;
  MyERC1155 public testERC1155;

  string name = "nameTestAAAAAAAAAAAAAAAAAAnameTestAAAAAAAAAAAAAAAAAA";
  string symbol = "NTST";
  string uri = "baseUri";
  uint256 maxSupply = 1000000 ether;

  uint256 internal ownerPrivateKey;
  address internal owner;
  uint256 internal user1PrivateKey;
  address internal user1;
  uint256 internal user2PrivateKey;
  address internal user2;
  int256 internal user3PrivateKey;
  address internal user3;

  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  function setUp() public {
    ownerPrivateKey = 0xA11CE;
    owner = vm.addr(ownerPrivateKey);
    user1PrivateKey = 0xB0B;
    user1 = vm.addr(user1PrivateKey);
    user2PrivateKey = 0xFE55E;
    user2 = vm.addr(user2PrivateKey);
    user3PrivateKey = 0xD1C;
    user3 = vm.addr(user2PrivateKey);
    vm.startPrank(owner);
    erc1155Receiver = new ERC1155Receiver();
    testERC1155 = new MyERC1155();
  }

  function testLog() public view {
    console.logBytes4(bytes4(keccak256("accountsAndIdsLengthMissmatch()")));
    console.logBytes4(bytes4(keccak256("amountsAndIdsLengthMissmatch()")));
    console.logBytes32(keccak256("ApprovalForAll(address,address,bool)"));
    console.logBytes4(bytes4(keccak256("callFail()")));
    console.logBytes4(bytes4(keccak256("transferToNonERC1155Receiver()")));
    console.logBytes4(bytes4(keccak256("transferToZeroAddress()")));
    console.logBytes4(bytes4(keccak256("insufficientBalance()")));
    console.logBytes4(bytes4(keccak256("overflow()")));
    console.logBytes32(keccak256("TransferSingle(address,address,address,uint256,uint256)"));
    console.logBytes4(bytes4(keccak256("operatorNotApproved()")));
    console.logBytes32(keccak256("TransferBatch(address,address,address,uint256[],uint256[])"));
    console.logBytes4(bytes4(keccak256("transferFromZeroAddress()")));
  }

  function testUri() public view {
    string memory uri_ = testERC1155.uri(1);
    require(keccak256(abi.encode(uri)) == keccak256(abi.encode(uri_)), "Uri missmatch");
  }

  function testSetUri() public {
    string memory newUri = "baseUriABCDEFGHIJKLMNOPKRSTUVWXY";
    testERC1155.setURI(newUri);
    string memory uri_ = testERC1155.uri(1);
    require(keccak256(abi.encode(newUri)) == keccak256(abi.encode(uri_)), "fail set new uri");
  }

  function testApprovalForAll() public {
    testERC1155.setApprovalForAll(user1, true);
    bool approved = testERC1155.isApprovedForAll(owner, user1);
    require(approved == true, "fail set approval for all");
  }

  function testMint() public {
    testERC1155.mint(user1, 1, 100, "");
    uint256 balance = testERC1155.balanceOf(user1, 1);
    require(balance == 100, "fail mint");
  }

  function testMintToERC1155ReceiverContract() public {
    testERC1155.mint(address(erc1155Receiver), 1, 100, "");
    uint256 balance = testERC1155.balanceOf(address(erc1155Receiver), 1);
    require(balance == 100, "fail mint");
  }

  function testMintEmitTransferSingle() public {
    vm.stopPrank();
    vm.startPrank(user1);
    vm.expectEmit(true, true, true, true);
    emit TransferSingle(user1, address(0), user1, 1, 100);
    testERC1155.mint(user1, 1, 100, "");
  }

  function testMintFailToAddressZero() public {
    vm.expectRevert(transferToZeroAddress.selector);
    testERC1155.mint(address(0), 1, 100, "");
  }

  function testMintBatch() public {
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 100;
    amounts[1] = 200;
    testERC1155.mintBatch(user1, ids, amounts, "");
    uint256 balanceId1 = testERC1155.balanceOf(user1, 1);
    uint256 balanceId2 = testERC1155.balanceOf(user1, 2);
    require(balanceId1 == 100, "fail mint id 1");
    require(balanceId2 == 200, "fail mint id 2");
  }

  function testMintBatchToERC1155ReceiverContract() public {
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 100;
    amounts[1] = 200;
    testERC1155.mintBatch(address(erc1155Receiver), ids, amounts, "");
    uint256 balanceId1 = testERC1155.balanceOf(address(erc1155Receiver), 1);
    uint256 balanceId2 = testERC1155.balanceOf(address(erc1155Receiver), 2);
    require(balanceId1 == 100, "fail mint id 1");
    require(balanceId2 == 200, "fail mint id 2");
  }

  function testMintBatchEmitTransferBatchEvent() public {
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 100;
    amounts[1] = 200;
    vm.expectEmit(true, true, true, false);
    emit TransferBatch(owner, address(0), user1, ids, amounts);
    testERC1155.mintBatch(user1, ids, amounts, "");
  }

  function testMintBatchFailToAddressZero() public {
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 100;
    amounts[1] = 200;
    vm.expectRevert(transferToZeroAddress.selector);
    testERC1155.mintBatch(address(0), ids, amounts, "");
  }

  function testMintBatchFailIdsAndAmountsLengthMissmatch() public {
    uint256[] memory ids = new uint256[](2);
    uint256[] memory amounts = new uint256[](3);
    vm.expectRevert(amountsAndIdsLengthMissmatch.selector);
    testERC1155.mintBatch(user1, ids, amounts, "");
  }

  function testBurn() public {
    testERC1155.mint(user1, 1, 100, "");
    uint256 balanceBefore = testERC1155.balanceOf(user1, 1);
    require(balanceBefore == 100, "fail mint");
    testERC1155.burn(user1, 1, 50);
    uint256 balanceAfter = testERC1155.balanceOf(user1, 1);
    require(balanceAfter == 50, "fail burn");
  }

  function testBurnEmitTransferSingleEvent() public {
    testERC1155.mint(user1, 1, 100, "");
    vm.expectEmit(true, true, true, true);
    emit TransferSingle(owner, user1, address(0), 1, 50);
    testERC1155.burn(user1, 1, 50);
  }

  function testBurnFailFromAddressZero() public {
    vm.expectRevert(transferFromZeroAddress.selector);
    testERC1155.burn(address(0), 1, 50);
  }

  function testBurnFailInsufficientBalance() public {
    testERC1155.mint(user1, 1, 100, "");
    vm.expectRevert(insufficientBalance.selector);
    testERC1155.burn(user1, 1, 101);
  }

  function testBurnBatch() public {
    testERC1155.mint(user1, 1, 100, "");
    testERC1155.mint(user1, 2, 100, "");
    uint256 balanceBeforeId1 = testERC1155.balanceOf(user1, 1);
    uint256 balanceBeforeId2 = testERC1155.balanceOf(user1, 2);
    require(balanceBeforeId1 == 100, "fail mint id 1");
    require(balanceBeforeId2 == 100, "fail mint id 2");
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 50;
    amounts[1] = 100;
    testERC1155.burnBatch(user1, ids, amounts);
    uint256 balanceAfterId1 = testERC1155.balanceOf(user1, 1);
    uint256 balanceAfterId2 = testERC1155.balanceOf(user1, 2);
    require(balanceAfterId1 == 50, "fail burn id 1");
    require(balanceAfterId2 == 0, "fail burn id 2");
  }

  function testBurnBatchEmitTransferBatchEvent() public {
    testERC1155.mint(user1, 1, 100, "");
    testERC1155.mint(user1, 2, 100, "");
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 50;
    amounts[1] = 100;
    vm.expectEmit(true, true, true, false);
    emit TransferBatch(owner, user1, address(0), ids, amounts);
    testERC1155.burnBatch(user1, ids, amounts);
  }

  function testBalanceOf() public {
    uint256 balance = testERC1155.balanceOf(user1, 1);
    require(balance == 0);
    testERC1155.mint(user1, 1, 100, "");
    balance = testERC1155.balanceOf(user1, 1);
    require(balance == 100, "fail to get balance");
  }

  function testBalanceOfBatch() public {
    address[] memory accounts = new address[](2);
    accounts[0] = user1;
    accounts[1] = user2;
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 1;
    testERC1155.mint(user1, 1, 100, "");
    testERC1155.mint(user2, 1, 25, "");
    uint256[] memory balances = testERC1155.balanceOfBatch(accounts, ids);
    require(balances[0] == 100, "fail get balance batch 1");
    require(balances[1] == 25, "fail get balance batch 2");
  }

  function testBalanceOfBatchFailIdsAndAccountsLengthMissmatch() public {
    address[] memory accounts = new address[](2);
    uint256[] memory ids = new uint256[](3);
    vm.expectRevert(accountsAndIdsLengthMissmatch.selector);
    testERC1155.balanceOfBatch(accounts, ids);
  }

  function testERC1155SafeTransferFrom() public {
    testERC1155.mint(user1, 1, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    testERC1155.safeTransferFrom(user1, user2, 1, 10, "");
    uint256 balance = testERC1155.balanceOf(user2, 1);
    require(balance == 10, "fail transfer single");
  }

  function testERC1155SafeTransferFromMultipleTransfer() public {
    testERC1155.mint(user1, 1, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    testERC1155.safeTransferFrom(user1, user2, 1, 10, "");
    uint256 balance = testERC1155.balanceOf(user2, 1);
    require(balance == 10, "fail transfer single");
    testERC1155.safeTransferFrom(user1, user2, 1, 10, "");
    balance = testERC1155.balanceOf(user2, 1);
    require(balance == 20, "fail transfer single multiple time");
  }

  function testERC1155SafeTransferFromAnotherUserWithApprovalSet() public {
    testERC1155.mint(user1, 1, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    testERC1155.setApprovalForAll(user2, true);
    testERC1155.safeTransferFrom(user1, user3, 1, 10, "");
    uint256 balance = testERC1155.balanceOf(user3, 1);
    require(balance == 10, "fail transfer single");
  }

  function testERC1155SafeTransferFromAnotherUserFailNotApproved() public {
    testERC1155.mint(user1, 1, 100, "");
    vm.stopPrank();
    vm.startPrank(user2);
    vm.expectRevert(operatorNotApproved.selector);
    testERC1155.safeTransferFrom(user1, user2, 1, 10, "");
  }

  function testERC1155SafeTransferFromFailToAddressZero() public {
    testERC1155.mint(user1, 1, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    vm.expectRevert(transferToZeroAddress.selector);
    testERC1155.safeTransferFrom(user1, address(0), 1, 10, "");
  }

  function testERC1155SafeTransferFromFailInsuficientBalance() public {
    vm.stopPrank();
    vm.startPrank(user1);
    vm.expectRevert(insufficientBalance.selector);
    testERC1155.safeTransferFrom(user1, user2, 1, 10, "");
  }

  function testERC1155SafeTransferFromToERC1155ReceiverContract() public {
    testERC1155.mint(user1, 1, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    testERC1155.safeTransferFrom(user1, address(erc1155Receiver), 1, 10, "");
    uint256 balance = testERC1155.balanceOf(address(erc1155Receiver), 1);
    require(balance == 10, "fail transfer single to erc1155 receiver contract");
  }

  function testERC1155SafeTransferFromEmitTransferSingleEvent() public {
    testERC1155.mint(user1, 1, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    vm.expectEmit(true, true, true, true);
    emit TransferSingle(user1, user1, user2, 1, 10);
    testERC1155.safeTransferFrom(user1, user2, 1, 10, "");
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

  function testERC1155SafeBatchTransferFromMultipleTransfer() public {
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
    testERC1155.safeBatchTransferFrom(user1, user2, ids, amounts, "");
    balanceId1 = testERC1155.balanceOf(user2, 1);
    balanceId2 = testERC1155.balanceOf(user2, 2);
    require(balanceId1 == 40, "fail batch transfer");
    require(balanceId2 == 100, "fail batch transfer");
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

  function testERC1155SafeBatchTransferFromAnotherUserWithApprovalSet() public {
    testERC1155.mint(user1, 1, 100, "");
    testERC1155.mint(user1, 2, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    testERC1155.setApprovalForAll(user2, true);
    vm.stopPrank();
    vm.startPrank(user2);
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

  function testERC1155SafeBatchTransferFromEmitTransferBatchEvent() public {
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
    vm.expectEmit(true, true, true, false);
    emit TransferBatch(user1, user1, user2, ids, amounts);
    testERC1155.safeBatchTransferFrom(user1, user2, ids, amounts, "");
  }

  function testERC1155SafeBatchTransferFromAnotherUserFailNotApprove() public {
    testERC1155.mint(user1, 1, 100, "");
    testERC1155.mint(user1, 2, 100, "");
    vm.stopPrank();
    vm.startPrank(user2);
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 20;
    amounts[1] = 50;
    vm.expectRevert(operatorNotApproved.selector);
    testERC1155.safeBatchTransferFrom(user1, user2, ids, amounts, "");
  }

  function testERC1155SafeBatchTransferFromFailToAddressZero() public {
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
    vm.expectRevert(transferToZeroAddress.selector);
    testERC1155.safeBatchTransferFrom(user1, address(0), ids, amounts, "");
  }

  function testERC1155SafeBatchTransferFromFailIdsAndAmountsLengthMissmatch() public {
    testERC1155.mint(user1, 1, 100, "");
    testERC1155.mint(user1, 2, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    uint256[] memory ids = new uint256[](2);
    uint256[] memory amounts = new uint256[](3);
    vm.expectRevert(amountsAndIdsLengthMissmatch.selector);
    testERC1155.safeBatchTransferFrom(user1, user2, ids, amounts, "");
  }

  function testERC1155SafeBatchTransferFromFailInsuficientBalance() public {
    testERC1155.mint(user1, 1, 100, "");
    testERC1155.mint(user1, 2, 100, "");
    vm.stopPrank();
    vm.startPrank(user1);
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 20;
    amounts[1] = 150;
    vm.expectRevert(insufficientBalance.selector);
    testERC1155.safeBatchTransferFrom(user1, user2, ids, amounts, "");
  }
}