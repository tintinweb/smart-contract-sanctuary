/**
 *Submitted for verification at FtmScan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IERC20 {
    function balanceOf(address addr) external view returns (uint256);
    function transfer(address dst, uint wad) external returns (bool);

}

contract SpookyEscrow {
    IERC20 constant BOO = IERC20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE);
    IERC20 constant WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    address constant exploiter = 0xDefC385D7038f391Eb0063C2f7C238cFb55b206C;
    address constant spookyswap = 0x95478C4F7D22D1048F46100001c2C69D2BA57380;
    
    /// @notice Either party can accept the deal once the contract has at least 136,650 BOO and $300k USDC.
    /// @notice This transfers the BOO to spookyswap and the USDC to the exploiter.
    function accept() external {
        require(msg.sender == exploiter || msg.sender == spookyswap, "exploiter or spookyswap must accept the trade");
        require(BOO.balanceOf(address(this)) >= 136650 ether, "At least 136,650 BOO");
        require(WFTM.balanceOf(address(this)) >= 300000 ether, "At least 300,000 FTM");
        BOO.transfer(spookyswap, BOO.balanceOf(address(this)));
        WFTM.transfer(exploiter, WFTM.balanceOf(address(this)));
    }

    /// @notice Either party can cancel the deal in a couple of days.
    /// @notice This transfers any BOO back to the exploiter and any USDC back to spookyswap.
    function cancel() external {
        require(msg.sender == exploiter || msg.sender == spookyswap, "exploiter or spookyswap only");
        require(block.timestamp >= 1640972394, "too soon");

        BOO.transfer(exploiter, BOO.balanceOf(address(this)));
        WFTM.transfer(spookyswap, WFTM.balanceOf(address(this)));
    }
}