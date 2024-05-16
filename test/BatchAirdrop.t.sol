// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {BatchAirdrop} from "../src/BatchAirdrop.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    constructor() ERC20("ERC20Token", "ERC20") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract BatchAirdropTest is Test {
    BatchAirdrop public airdrop;
    ERC20Token public token;

    function setUp() public {
        airdrop = new BatchAirdrop(address(this));
        airdrop.setFee(100);

        token = new ERC20Token();
    }

    function test_AirdropCoin() public {
        // allocate 400 wei to this contract
        vm.prank(address(this));
        vm.deal(address(this), 400);

        // console.log(address(this).balance);

        address[] memory to = new address[](2);
        uint256[] memory amount = new uint256[](2);

        to[0] = address(1);
        to[1] = address(2);

        amount[0] = 100;
        amount[1] = 200;

        uint256 _amount = amount[0] + amount[1] + airdrop.fee();
        // try airdrop.airdropCoin{value: _amount}(to, amount) {
        //     console.log("success");
        // } catch Error(string memory reason) {
        //     console.log("fail");
        //     console.log(reason);
        // }
        bytes memory data = abi.encodeWithSignature(
            "airdropCoin(address[],uint256[])",
            to,
            amount
        );
        (bool success, ) = address(airdrop).call{value: _amount}(data);
        assertEq(success, true);
        // fee 100
        assertEq(address(this).balance, 100);
        assertEq(address(1).balance, 100);
        assertEq(address(2).balance, 200);
        assertEq(address(airdrop).balance, 0);
    }

    function testFail_AirdropCoinLengthNotMatch() public {
        vm.prank(address(this));
        vm.deal(address(this), 400);

        // to and amount length not match
        address[] memory to = new address[](2);
        uint256[] memory amount = new uint256[](1);

        to[0] = address(1);
        to[1] = address(2);

        amount[0] = 100;

        uint256 _amount = amount[0] + airdrop.fee();
        airdrop.airdropCoin{value: _amount}(to, amount);
        vm.expectRevert("BatchAirdrop: length not match");
    }

    function testFail_AirdropCoinValueNotEnough() public {
        vm.prank(address(this));
        vm.deal(address(this), 400);

        address[] memory to = new address[](2);
        uint256[] memory amount = new uint256[](2);

        to[0] = address(1);
        to[1] = address(2);

        amount[0] = 100;
        amount[1] = 200;

        uint256 _amount = amount[0] + amount[1] + airdrop.fee() - 1;
        airdrop.airdropCoin{value: _amount}(to, amount);
        vm.expectRevert("BatchAirdrop: value not enough");
    }


    // test airdrop token
    function test_AirdropToken() public {
        
        vm.prank(address(this));
        // for fee
        vm.deal(address(this), 100);

        token.mint(address(this), 300);
        // approve to airdrop
        token.approve(address(airdrop), 300);

        address[] memory to = new address[](2);
        uint256[] memory amount = new uint256[](2);

        to[0] = address(1);
        to[1] = address(2);

        amount[0] = 100;
        amount[1] = 200;

        uint256 _amount = airdrop.fee();
     
        bytes memory data = abi.encodeWithSignature(
            "airdropToken(address,address[],uint256[])",
            address(token),
            to,
            amount
        );
        (bool success, ) = address(airdrop).call{value: _amount}(data);
        assertEq(success, true);
        // fee 100
        assertEq(address(this).balance, 100);
        // assertEq(address(airdrop).balance, 0);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(1)), 100);
        assertEq(token.balanceOf(address(2)), 200);
    }

    // testfail airdrop token length not match
    function testFail_AirdropTokenLengthNotMatch() public {
        vm.prank(address(this));
        vm.deal(address(this), 100);

        token.mint(address(this), 300);
        token.approve(address(airdrop), 300);

        address[] memory to = new address[](2);
        uint256[] memory amount = new uint256[](1);

        to[0] = address(1);
        to[1] = address(2);

        amount[0] = 100;

        uint256 _amount = airdrop.fee();
        airdrop.airdropToken{value: _amount}(address(token), to, amount);
        vm.expectRevert("BatchAirdrop: length not match");
    }

    // testfail airdrop token value not enough
    function testFail_AirdropTokenValueNotEnough() public {
        vm.prank(address(this));
        vm.deal(address(this), 100);

        token.mint(address(this), 300);
        token.approve(address(airdrop), 300);

        address[] memory to = new address[](2);
        uint256[] memory amount = new uint256[](2);

        to[0] = address(1);
        to[1] = address(2);

        amount[0] = 100;
        amount[1] = 200;

        uint256 _amount = airdrop.fee() - 1;
        airdrop.airdropToken{value: _amount}(address(token), to, amount);
        vm.expectRevert("BatchAirdrop: value not enough");
    }

    // token not enough
    function testFail_AirdropTokenTokenNotEnough() public {
        vm.prank(address(this));
        vm.deal(address(this), 100);

        token.mint(address(this), 200);
        token.approve(address(airdrop), 200);

        address[] memory to = new address[](2);
        uint256[] memory amount = new uint256[](2);

        to[0] = address(1);
        to[1] = address(2);

        amount[0] = 100;
        amount[1] = 200;

        uint256 _amount = airdrop.fee();
        airdrop.airdropToken{value: _amount}(address(token), to, amount);
        vm.expectRevert("SafeERC20: transfer amount exceeds balance");
    }

    // testfail set owner
    function testFail_SetOwner() public {
        // assume msg.sender is zero
        vm.prank(address(0));
        airdrop.setOwner(address(0));
    }

    // test set owner
    function test_SetOwner() public {
        vm.prank(address(this));
        airdrop.setOwner(address(1));
        assertEq(airdrop.owner(), address(1));
    }

    //testfail set fee
    function testFail_SetFee() public {
        // assume msg.sender is zero
        vm.prank(address(0));
        airdrop.setFee(0);
    }

    // test set fee
    function test_SetFee() public {
        vm.prank(address(this));
        airdrop.setFee(200);
        assertEq(airdrop.fee(), 200);
        airdrop.setFee(100);
    }

    // payable
    receive() external payable {}
}
