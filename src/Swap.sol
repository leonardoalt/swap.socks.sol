// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import "./Socks.sol";

/// @title Swap contract for Solidity socks.
/// @dev One invariant of this contract is that users can always either swap or withdraw, therefore their deposited tokens never get stuck.
contract SocksSwap is ERC1155TokenReceiver {
    Socks constant socks = Socks(0xdfcCFA821F0bFD9d90746021094FAf6C0f10AB63);
    uint256 constant BOOTSTRAP = 10;

    mapping (address => uint[2]) balanceOf;

    /// @notice Bootstraps the pool.
    constructor() {
        for (uint i = 0; i < BOOTSTRAP; ++i) {
            socks.mint();
        }
    }

    /// @notice Atomic deposit & swap.
    function depositAndSwap(Sock from, Sock to) external {
        deposit(from);
        swap(from, to);
    }

    /// @notice If there is nothing on the other side of the swap users might need to deposit and swap at different times.
    function deposit(Sock id) public {
        socks.safeTransferFrom(msg.sender, address(this), uint(id), 1, "");
        ++balanceOf[msg.sender][uint(id)];
    }

    /// @notice If there is nothing on the other side of the swap users might need to deposit and swap at different times.
    function swap(Sock from, Sock to) public {
        require(from != to);
        require(socks.balanceOf(address(this), uint(to)) > 0);

        --balanceOf[msg.sender][uint(from)];
        socks.safeTransferFrom(address(this), msg.sender, uint(to), 1, "");
    }

    /// @notice Users can always withdraw their tokens if a swap was not available for a while.
    function withdraw() public {
        uint[2] memory balance = balanceOf[msg.sender];
        balanceOf[msg.sender] = [0, 0];
        if (balance[0] > 0) {
            socks.safeTransferFrom(address(this), msg.sender, 0, balance[0], "");
        }
        if (balance[1] > 0) {
            socks.safeTransferFrom(address(this), msg.sender, 1, balance[1], "");
        }
    }
}
