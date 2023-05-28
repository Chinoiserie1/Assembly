// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../../../src/tokens/ERC1155/extensions/ERC1155Supply.sol";

contract MyERC1155Supply is ERC1155Supply {
  constructor() ERC1155("name", "symbol", "baseURI") {}

  function mint(address to, uint256 id, uint256 amount, bytes calldata data) external {
    _mint(to, id, amount, data);
  }
}

contract TestERC1155Supply is Test {
  MyERC1155Supply public testERC1155Supply;

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
    testERC1155Supply = new MyERC1155Supply();
  }

  function testERC1155SupplyMintTokenId1ShouldUpdateSupply() public {
    testERC1155Supply.mint(user1, 1, 100, "");
    uint256 totalSupply = testERC1155Supply.totalSupply(1);
    require(totalSupply == 100, "fail update total supply");
  }
}