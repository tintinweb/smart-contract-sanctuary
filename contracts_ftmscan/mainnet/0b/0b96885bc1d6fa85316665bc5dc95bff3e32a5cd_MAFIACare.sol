/**
 *Submitted for verification at FtmScan.com on 2021-12-31
*/

/**

Making FANTOM safer! Community & Peer review & KYC services & tools for FTM Chain!

Website: https://defymafia.com
Telegram: https://t.me/defymafia

A contract that holds funds for taking care of $MAFIA holders in the event they get rugged in any FTM tokens.

*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MAFIACare {
    IERC20 constant WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    address constant defyape = 0xE1f7effBF0c2F68582310D17ce8eEd6b972422a2;
    
    function compensateVictim(address account) external {
        require(msg.sender == defyape, "Only DefyApe can compensate a victim!");
        require(WFTM.balanceOf(address(this)) >= 10 ether, "At least 10 FTM needed!");
        WFTM.transfer(account, 10);
    }
}