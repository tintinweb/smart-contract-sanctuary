//SPDX-License-Identifier: None

pragma solidity ^0.8.0;

/**
 * Multi-sig treasury for CryptoCartel
 */

import "./IERC20.sol";

contract CryptoCartelTreasury {
    
    address public Travis;

    address public Daniel;

    uint256 claimedFTMO; // FTMO claimed from contract so far

    uint256 startTime; // Vestimg period start

    constructor() {
        Travis = 0x40A432E2d0e27Bd7cC49B1ab76A03F1c633211CB;
        Daniel = 0x78c92232e72bAdE97669FF403c2dd5aA36dC755e;
        claimedFTMO = 0;
        startTime = block.timestamp; // Epoch seconds
    }

    function sendToken(address token, address to, uint256 amount)
        external
        onlyCoreTeam
    {
        if (token == 0x0000000000000000000000000000000000000000) { // zero address means FTM
            require(
                amount <= address(this).balance,
                "CryptoCartelTreasury: amount exceeds FTM balance"
            );
            payable(to).transfer(amount);           
        } else {
            IERC20 TokenToSend = IERC20(token);
            require(
                amount <= TokenToSend.balanceOf(address(this)),
                "CryptoCartelTreasury: amount exceeds token balance"
            );
            TokenToSend.transfer(to, amount);
        }
    }

    fallback() external payable {}
    receive() external payable {}

    // Withdraw function sends FTMO to the caller
    // Only the core team can use this function
    function withdrawFTMO()
        external
        onlyCoreTeam
    {
        IERC20 FTMO = IERC20(0x9bD0611610A0f5133e4dd1bFdd71C5479Ee77f37);
        uint256 available = 30000000000000000000000 // Initially unlocked FTMO
                            + ((block.timestamp - startTime) // Seconds since vesting period start
                            *(470000000000000000000000)) // Remaining FTMO in agreement
                            /(30*24*3600) // Total seconds in vesting period
                            - claimedFTMO; // FTMO claimed by beneficiary already
        FTMO.transfer(msg.sender, available);
        claimedFTMO += available;
    }

    // Only core team has certain privileges
    modifier onlyCoreTeam() {
        require(
            msg.sender == Travis || msg.sender == Daniel,
            "CryptoCartelTreasury: only core team allowed"
        );
        _;
    }
}