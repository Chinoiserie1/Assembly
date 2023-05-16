// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../../src/tokens/ERC1155/ERC1155.sol";

contract ERC1155Test is Test {
  ERC1155 public erc1155;
  string name = "nameTestAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
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
  }

  function testLog() public view {
    console.logBytes4(bytes4(keccak256("accountsAndIdsLengthMissmatch()")));
    console.logBytes32(keccak256("ApprovalForAll(address,address,bool"));
  }

  function testERC1155() public {
    erc1155.name();
    erc1155.mint(user1);
    erc1155.mint(user2);
    erc1155.mint(user2);
    uint256 balanceuser1 = erc1155.balanceOf(user1, 1);
    console.log(balanceuser1);

    address[] memory ad = new address[](1);
    ad[0] = user1;
    // ad[1] = user2;
    // ad[2] = user1;
    uint256[] memory id = new uint256[](1);
    id[0] = 1;
    // id[1] = 1;
    // id[2] = 1;
    uint256[] memory balance = new uint256[](1);
    balance = erc1155.balanceOfBatch(ad, id);
    // console.log(balance[0]);
    // console.log(balance[1]);
  }

  function testApprovalForAll() public {
    erc1155.setApprovalForAll(user1, true);
    bool approved = erc1155.isApprovedForAll(owner, user1);
    require(approved == true, "fail set approval for all");
  }
}