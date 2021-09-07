// SPDX-License-Identifier: UNLICENSE

/**
Apes Together Strong!

About BigShortBets DeFi project:

We are creating a social&trading p2p platform that guarantees encrypted interaction between investors.
Logging in is possible via a cryptocurrency wallet (e.g. Metamask).
The security level is one comparable to the Tor network.

https://bigsb.io/ - Our Tool
https://bigshortbets.com - Project&Team info

Video explainer:
https://youtu.be/wbhUo5IvKdk

Zaorski, You Son of a bitch I’m in …
*/

pragma solidity 0.8.7;

import "./owned.sol";
import "./interfaces.sol";
import "./reentryGuard.sol";

contract TeamStake is Owned, Guarded {
    address immutable token;

    constructor(address _token) {
        token = _token;
    }

    /// Claim fees, keep contract balance at 10% of total supply
    function claim() external onlyOwner guarded {
        uint256 amt = claimable();
        require(amt > 0, "Nothing to claim");
        bool success = IERC20(token).transfer(msg.sender, amt);
        require(success, "Transer failed");
    }

    /// We can only claim fees and we keep contract balance at 10% of supply
    function claimable() public view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 supply = IERC20(token).totalSupply();
        if (balance > supply / 10) {
            return (balance - (supply / 10));
        } else return 0;
    }

    /**
    @dev Function to recover accidentally send ERC20 tokens
    @param erc20 ERC20 token address
    */
    function rescueERC20(address erc20) external onlyOwner {
        require(erc20 != token, "Lol, nope!");
        uint256 amt = IERC20(erc20).balanceOf(address(this));
        require(amt > 0, "Nothing to rescue");
        IUsdt(erc20).transfer(owner, amt);
    }

    /**
    @dev Function to recover any ETH send to contract
    */
    function rescueETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}

//This is fine!