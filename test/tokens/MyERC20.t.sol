// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/tokens/MyERC20.sol";

contract MyERC20Test is Test {
  MyERC20 public myERC20;
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
    myERC20 = new MyERC20(name, symbol, maxSupply);
  }

  function testNameAndSymbol() public view {
    // see trace to verify name and symbol (forge test -vvvvv)
    myERC20.name();
    myERC20.symbol();
  }

  function test() public view {
    console.logBytes32(keccak256("addressZero()"));
    console.logBytes32(keccak256("quantityZero()"));
    console.logBytes32(keccak256("maxSupplyReach()"));
    console.logBytes32(keccak256("callerNotOwner()"));
    console.logBytes32(keccak256("overflow()"));
    console.logBytes32(keccak256("insufficientBalance()"));
    console.logBytes32(keccak256("OwnershipTransferred(address,address)"));
    console.logBytes4(bytes4(keccak256("ownerSetToAddressZero()")));
  }

  function testMint() public {
    myERC20.mint(user1, 1 ether);
    uint256 supply = myERC20.totalSupply();
    require(supply == 1 ether, "fail update supply");
  }

  function testFailMintNotOwner() public {
    vm.stopPrank();
    vm.startPrank(user1);
    myERC20.mint(user1, 1 ether);
  }

  function testTotalSupply() public {
    uint256 totalSupply = myERC20.totalSupply();
    require(totalSupply == 0, "fail get total supply");
    myERC20.mint(user1, 1 ether);
    totalSupply = myERC20.totalSupply();
    require(totalSupply == 1 ether, "fail get total supply after mint");
  }

  function testBalanceOf() public {
    uint256 balanceUser1 = myERC20.balanceOf(user1);
    require(balanceUser1 == 0, "fail get balance user1");
    myERC20.mint(user1, 1 ether);
    balanceUser1 = myERC20.balanceOf(user1);
    require(balanceUser1 == 1 ether, "fail get balance user1 after mint");
  }

  function testTransfer() public {
    myERC20.mint(user1, 1 ether);
    uint256 balanceUser2 = myERC20.balanceOf(user2);
    require(balanceUser2 == 0, "fail user should have zero balance");
    vm.stopPrank();
    vm.startPrank(user1);
    myERC20.transfer(user2, 0.5 ether);
    balanceUser2 = myERC20.balanceOf(user2);
    require(balanceUser2 == 0.5 ether, "fail transfer");
  }

  function testFailTransferInsufficientBalance() public {
    myERC20.transfer(user2, 0.5 ether);
  }

  function testApprove() public {
    bool success = myERC20.approve(user1, 1 ether);
    require(success, "fail approve user1");
  }

  function testAllowance() public {
    bool success = myERC20.approve(user1, 1 ether);
    require(success, "fail approve user1");
    uint256 allowance = myERC20.allowance(owner, user1);
    require(allowance == 1 ether, "fail get allowance");
  }

  function testBurn() public {
    myERC20.mint(user1, 1 ether);
    uint256 balanceUser1 = myERC20.balanceOf(user1);
    require(balanceUser1 == 1 ether, "fail mint token user1");
    vm.stopPrank();
    vm.startPrank(user1);
    myERC20.burn(0.5 ether);
    balanceUser1 = myERC20.balanceOf(user1);
    require(balanceUser1 == 0.5 ether, "fail burn token user1");
    uint256 currentSupply = myERC20.totalSupply();
    require(currentSupply == 0.5 ether, "fail update current supply");
  }

  function testFailBurnInsufficientBalance() public {
    myERC20.burn(1 ether);
  }

  function testMaxSupply() public view {
    uint256 maxSupply_ = myERC20.maxSupply();
    require(maxSupply_ == maxSupply, "fail get maxSupply");
  }

  function testGetOwner() public view {
    address _owner = myERC20.owner();
    require(_owner == owner, "fail get owner");
  }

  function testTransferOwnership() public {
    myERC20.transferOwnership(user1);
  }
}
