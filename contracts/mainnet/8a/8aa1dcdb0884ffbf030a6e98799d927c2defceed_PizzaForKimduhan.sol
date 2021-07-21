/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function decimals() external view returns (uint8);
}

contract PizzaForKimduhan {
    address private constant kimduhan =
        0x2542642c045cA7f26725089dD90d5EaF1c53Fd91;
    address private constant vbtc = 0x84e7AE4897B3847B67f212Aff78BFbC5f700aa40;
    address private constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public committer;
    uint256 public deadline;

    uint256 immutable VBTC; // unit 10**8
    uint256 immutable DAI; // unit 10**18

    constructor() {
        VBTC = (10**IERC20(vbtc).decimals());
        DAI = (10**IERC20(dai).decimals());
    }

    function commit() public {
        require(
            IERC20(dai).balanceOf(address(this)) >= 4 * DAI,
            "kimduhan should deposit 4 dollars first"
        );
        require(
            deadline <= block.timestamp || committer == address(0),
            "Someone already committed"
        );
        if (committer != address(0)) {
            // refund
            IERC20(vbtc).transfer(
                committer,
                IERC20(vbtc).balanceOf(address(this))
            );
        }
        // set committer & deadline
        committer = msg.sender;
        deadline = block.timestamp + 1 hours;
    }

    function pizzaAtFourDollars() public {
        uint256 vbtcBal = IERC20(vbtc).balanceOf(address(this));
        uint256 daiBal = IERC20(dai).balanceOf(address(this));
        require(vbtcBal >= 10000 * VBTC, "not enough vbtc");
        require(daiBal >= 4 * DAI, "not enough dai");

        // transfer dai to committer
        IERC20(dai).transfer(committer, daiBal);
        // transfer vbtc to kimduhan
        IERC20(vbtc).transfer(kimduhan, vbtcBal);
        delete committer;
        delete deadline;
    }
}