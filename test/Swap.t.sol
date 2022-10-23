// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/Swap.sol";
import "../src/Socks.sol";

contract SocksSwapTest is Test, ERC1155TokenReceiver {
    SocksSwap sockSwap;
    Socks constant socks = Socks(0xdfcCFA821F0bFD9d90746021094FAf6C0f10AB63);
    address constant other = address(0xcafe);

    function setUp() public {
        sockSwap = new SocksSwap();
    }

    /****** PASS CASES *********/

    function testSimpleSwap() public {
        // Inflate the pool.
        vm.difficulty(left());
        sockSwap.inflate(Sock.Left);
        vm.difficulty(right());
        sockSwap.inflate(Sock.Right);

        // Check we have no socks.
        assertEq(socks.balanceOf(address(this), left()), 0);
        assertEq(socks.balanceOf(address(this), right()), 0);

        // Mint a Left for ourselves.
        vm.difficulty(left());
        socks.mint();

        // Check we have a left and no right.
        assertEq(socks.balanceOf(address(this), left()), 1);
        assertEq(socks.balanceOf(address(this), right()), 0);

        // Perform simple swap.
        socks.setApprovalForAll(address(sockSwap), true);
        sockSwap.swap({from: Sock.Left, to: Sock.Right});

        // Check we have a right and no left.
        assertEq(socks.balanceOf(address(this), left()), 0);
        assertEq(socks.balanceOf(address(this), right()), 1);
    }

    function testDepositAndSwap() public {
        // Mint a Left for ourselves.
        vm.difficulty(left());
        socks.mint();

        // Mint a Right for other.
        vm.difficulty(right());
        vm.startPrank(other);
        socks.mint();
        vm.stopPrank();

        // Check the statements above
        assertEq(socks.balanceOf(address(this), left()), 1);
        assertEq(socks.balanceOf(other, right()), 1);

        // Swap
        socks.setApprovalForAll(address(sockSwap), true);
        sockSwap.deposit(Sock.Left);
        vm.startPrank(other);
        socks.setApprovalForAll(address(sockSwap), true);
        sockSwap.swap({from: Sock.Right, to: Sock.Left});
        vm.stopPrank();
        sockSwap.swapAfterDeposit({from: Sock.Left, to: Sock.Right});

        // Check the swap happened
        assertEq(socks.balanceOf(address(this), right()), 1);
        assertEq(socks.balanceOf(address(this), left()), 0);
        assertEq(socks.balanceOf(other, left()), 1);
        assertEq(socks.balanceOf(other, right()), 0);
    }

    function testWithdraw() public {
        // Mint a Left for ourselves.
        vm.difficulty(left());
        socks.mint();

        // Mint a Right for ourselves.
        vm.difficulty(right());
        socks.mint();

        // Deposit both.
        socks.setApprovalForAll(address(sockSwap), true);
        sockSwap.deposit(Sock.Left);
        sockSwap.deposit(Sock.Right);

        // Make sure we don't have socks.
        assertEq(socks.balanceOf(address(this), left()), 0);
        assertEq(socks.balanceOf(address(this), right()), 0);

        // Don't wanna swap anymore, just withdraw.
        sockSwap.withdraw();

        // Make sure we got our socks back.
        assertEq(socks.balanceOf(address(this), left()), 1);
        assertEq(socks.balanceOf(address(this), right()), 1);
    }

    /********** FAIL CASES **********/

    function testSwapWithoutApproval() public {
        vm.expectRevert("NOT_AUTHORIZED");
        sockSwap.swap({from: Sock.Left, to: Sock.Right});
    }

    function testSwapWithoutFunds() public {
        socks.setApprovalForAll(address(sockSwap), true);
        vm.expectRevert(stdError.arithmeticError);
        sockSwap.swap({from: Sock.Left, to: Sock.Right});
    }

    function testDepositWithoutApproval() public {
        vm.expectRevert("NOT_AUTHORIZED");
        sockSwap.deposit(Sock.Left);
    }

    function testDepositWithoutFunds() public {
        socks.setApprovalForAll(address(sockSwap), true);
        vm.expectRevert(stdError.arithmeticError);
        sockSwap.deposit(Sock.Left);
    }

    function testSwapAfterDepositWithoutSocks() public {
        vm.expectRevert();
        sockSwap.swapAfterDeposit({from: Sock.Left, to: Sock.Right});
    }

    function testSwapAfterDepositWithoutDeposit() public {
        // Inflate the pool.
        vm.difficulty(left());
        sockSwap.inflate(Sock.Left);
        vm.difficulty(right());
        sockSwap.inflate(Sock.Right);

        vm.expectRevert(stdError.arithmeticError);
        sockSwap.swapAfterDeposit({from: Sock.Left, to: Sock.Right});
    }

    /********** HELPERS ***********/

    function left() internal pure returns (uint) {
        return uint(Sock.Left);
    }

    function right() internal pure returns (uint) {
        return uint(Sock.Right);
    }
}
