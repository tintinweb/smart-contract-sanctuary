/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}


contract TokenReceiver {
    IERC20 private _token;
    //event DoneStuff(address from);

    /**
     * @dev Constructor sets token that can be received
     */
    constructor (IERC20 token) public {
        _token = token;
    }

    /**
     * @dev Do stuff, requires tokens
     */
    function transfer(address _address) public {
        _token.transferFrom(msg.sender, _address, 10000);
        
        //emit DoneStuff(from);
    }
}