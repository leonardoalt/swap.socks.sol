// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import "./Socks.sol";

/// @title Swap contract for Solidity socks.
/// @dev One invariant of this contract is that users can, after a deposit, always either swap or withdraw, therefore their deposited tokens never get stuck.
/// A few ways to represent that:
/// - After a successful call to `deposit(from)` from user U, the next call from U to either `swapAfterDeposit(from, to)` or `withdraw()` cannot revert.
/// - balanceOf[msg.sender][id] > 0 => socks.balanceOf[address(this)][Sock.Left] > 0 || socks.balanceOf[address(this)][Sock.Left]
/// The property above must be true for the swap market itself, regardless of calls to `inflate`.
contract SocksSwap is ERC1155TokenReceiver {
    Socks constant socks = Socks(0xdfcCFA821F0bFD9d90746021094FAf6C0f10AB63);
    uint256 constant BOOTSTRAP = 10;

    mapping(address => mapping(Sock => uint256)) balanceOf;

    /// @notice Bootstraps the pool.
    constructor() {
        // Let's fill up with whatever at first.
        inflate(Sock(block.difficulty % 2));
    }

    /// @notice Mint more socks for the pool contract. Will fail from 9.11.2022.
    function inflate(Sock expected) public {
        // Make sure we fill up with a specific needed side.
        require(block.difficulty % 2 == uint256(expected));

        for (uint256 i = 0; i < BOOTSTRAP;) {
            socks.mint();
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Optimized swap path if the pool has enough tokens.
    function swap(Sock from, Sock to) external {
        socks.safeTransferFrom(msg.sender, address(this), uint256(from), 1, "");
        socks.safeTransferFrom(address(this), msg.sender, uint256(to), 1, "");
    }

    /// @notice If there is nothing on the other side of the swap users might need to deposit and swap at different times.
    function deposit(Sock id) external {
        socks.safeTransferFrom(msg.sender, address(this), uint256(id), 1, "");
        unchecked {
            ++balanceOf[msg.sender][id];
        }
    }

    /// @notice If there is nothing on the other side of the swap users might need to deposit and swap at different times.
    function swapAfterDeposit(Sock from, Sock to) external {
        require(from != to);
        require(socks.balanceOf(address(this), uint256(to)) > 0);

        --balanceOf[msg.sender][from];
        socks.safeTransferFrom(address(this), msg.sender, uint256(to), 1, "");
    }

    /// @notice Users can always withdraw their tokens if a swap was not available for a while.
    function withdraw() external {
        (uint256 balLeft, uint256 balRight) = (balanceOf[msg.sender][Sock.Left], balanceOf[msg.sender][Sock.Right]);
        balanceOf[msg.sender][Sock.Left] = 0;
        balanceOf[msg.sender][Sock.Right] = 0;
        if (balLeft > 0) {
            socks.safeTransferFrom(address(this), msg.sender, uint256(Sock.Left), balLeft, "");
        }
        if (balRight > 0) {
            socks.safeTransferFrom(address(this), msg.sender, uint256(Sock.Right), balRight, "");
        }
    }
}
