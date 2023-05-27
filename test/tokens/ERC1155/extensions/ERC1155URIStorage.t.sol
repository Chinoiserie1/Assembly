// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../../../src/tokens/ERC1155/extensions/ERC1155URIStorage.sol";
// import "../../../../src/tokens/ERC1155/ERC1155.sol";

contract MyERC1155URIStorage is ERC1155URIStorage {
  constructor() ERC1155("name", "symbol", "baseURI") {}

  function setURI(uint256 tokenId, string calldata tokenURI) external {
    _setURI(tokenId, tokenURI);
  }

  function setBaseURI(string calldata baseURI) external {
    _setBaseURI(baseURI);
  }
}

contract TestERC1155URIStorage is Test {
  MyERC1155URIStorage public testERC1155URIStorage;

  uint256 internal ownerPrivateKey;
  address internal owner;
  uint256 internal user1PrivateKey;
  address internal user1;
  uint256 internal user2PrivateKey;
  address internal user2;
  int256 internal user3PrivateKey;
  address internal user3;

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
    testERC1155URIStorage = new MyERC1155URIStorage();
  }

  function testURI() public {
    testERC1155URIStorage.setBaseURI("ThisIsBase1ThisIsBase2ThisIsBase3ThisIsBase4321");
    // testERC1155URIStorage.getBaseURI2();
    // testERC1155URIStorage.setBaseURI2("ThisIsBase1ThisIsBase2ThisIsBase3ThisIsBase456");
    // string memory res = testERC1155URIStorage._tokenURIs[1];
    testERC1155URIStorage.setURI(1, "ThisIsBase1ThisIsBase2ThisIsBase3ThisIsBase4567");
    testERC1155URIStorage.getURI(1);
    testERC1155URIStorage.uri(1);
  }
}