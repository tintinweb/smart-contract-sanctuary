/**
 *Submitted for verification at snowtrace.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

/**
 * XXX
 * 𝗖𝗼𝗻𝘁𝗿𝗮𝗰𝘁 𝗼𝗿𝗶𝗴𝗶𝗻𝗮𝗹𝗹𝘆 𝗰𝗿𝗲𝗮𝘁𝗲𝗱 𝗯𝘆 𝗥𝘂𝗴𝗗𝗼𝗰
 * 𝗔𝗻𝗱 𝗳𝗼𝗿𝗸𝗲𝗱 𝗯𝘆 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆 𝗗𝗲𝘃
 * 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆: 𝗮𝗻 𝗶𝗻𝗻𝗼𝘃𝗮𝘁𝗶𝘃𝗲 𝗗𝗲𝗙𝗶 𝗽𝗿𝗼𝘁𝗼𝗰𝗼𝗹 𝗳𝗼𝗿 𝗬𝗶𝗲𝗹𝗱 𝗙𝗮𝗿𝗺𝗶𝗻𝗴 𝗼𝗻 𝗔𝘃𝗮𝗹𝗮𝗻𝗰𝗵𝗲
 * 
 * 𝗟𝗶𝗻𝗸𝘀:
 * 𝗵𝘁𝘁𝗽𝘀://𝗳𝗮𝗿𝗺𝗲𝗿𝘀𝗼𝗻𝗹𝘆.𝗳𝗮𝗿𝗺
 * 𝗵𝘁𝘁𝗽𝘀://𝘁.𝗺𝗲/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝟮
 * 𝗵𝘁𝘁𝗽𝘀://𝘁𝘄𝗶𝘁𝘁𝗲𝗿.𝗰𝗼𝗺/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝗗𝗲𝗙𝗶
 * XXX
 */

pragma solidity ^0.8.10;

// File [email protected]
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// File [email protected]
/**
 * XXX
 * 𝗖𝗼𝗻𝘁𝗿𝗮𝗰𝘁 𝗼𝗿𝗶𝗴𝗶𝗻𝗮𝗹𝗹𝘆 𝗰𝗿𝗲𝗮𝘁𝗲𝗱 𝗯𝘆 𝗥𝘂𝗴𝗗𝗼𝗰
 * 𝗔𝗻𝗱 𝗳𝗼𝗿𝗸𝗲𝗱 𝗯𝘆 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆 𝗗𝗲𝘃
 * 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆: 𝗮𝗻 𝗶𝗻𝗻𝗼𝘃𝗮𝘁𝗶𝘃𝗲 𝗗𝗲𝗙𝗶 𝗽𝗿𝗼𝘁𝗼𝗰𝗼𝗹 𝗳𝗼𝗿 𝗬𝗶𝗲𝗹𝗱 𝗙𝗮𝗿𝗺𝗶𝗻𝗴 𝗼𝗻 𝗔𝘃𝗮𝗹𝗮𝗻𝗰𝗵𝗲
 * 
 * 𝗟𝗶𝗻𝗸𝘀:
 * 𝗵𝘁𝘁𝗽𝘀://𝗳𝗮𝗿𝗺𝗲𝗿𝘀𝗼𝗻𝗹𝘆.𝗳𝗮𝗿𝗺
 * 𝗵𝘁𝘁𝗽𝘀://𝘁.𝗺𝗲/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝟮
 * 𝗵𝘁𝘁𝗽𝘀://𝘁𝘄𝗶𝘁𝘁𝗲𝗿.𝗰𝗼𝗺/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝗗𝗲𝗙𝗶
 * XXX
 */
contract FarmersOnlyLiqLocker {
    address public FarmersOnlyDev = 0xeE68753bD98d29D20C8768b05f90c95D66AEf1a8;
    uint256 public unlockTimestamp;
    
    constructor() {
        unlockTimestamp = block.timestamp + 60 * 60 * 24 * 90; // 90 days lock
    }
    
    function withdraw(IERC20 token) external {
        require(msg.sender == FarmersOnlyDev, "withdraw: message sender is not FarmersOnlyDev");
        require(block.timestamp > unlockTimestamp, "withdraw: the token is still locked");
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
}