// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/Swap.sol";
import "../src/Socks.sol";

contract SocksSwapTest is Test, ERC1155TokenReceiver {
    SocksSwap public sockSwap;
    Socks immutable socks = Socks(0xdfcCFA821F0bFD9d90746021094FAf6C0f10AB63);
    address immutable other = address(0xcafe);

    function setUp() public {
        sockSwap = new SocksSwap();
    }

    function testSwap() public {
        // Mint a Left for ourselves.
        vm.difficulty(0);
        socks.mint();

        // Mint a Right for other.
        vm.difficulty(1);
        vm.startPrank(other);
        socks.mint();
        vm.stopPrank();

        // Check the statements above
        assertEq(socks.balanceOf(address(this), 0), 1);
        assertEq(socks.balanceOf(other, 1), 1);

        // Swap
        socks.setApprovalForAll(address(sockSwap), true);
        sockSwap.deposit(Sock.Left);
        vm.startPrank(other);
        socks.setApprovalForAll(address(sockSwap), true);
        sockSwap.depositAndSwap({from: Sock.Right, to: Sock.Left});
        vm.stopPrank();
        sockSwap.swap({from: Sock.Left, to: Sock.Right});

        // Check the swap happened
        assertEq(socks.balanceOf(address(this), 1), 1);
        assertEq(socks.balanceOf(address(this), 0), 0);
        assertEq(socks.balanceOf(other, 0), 1);
        assertEq(socks.balanceOf(other, 1), 0);
    }
}
