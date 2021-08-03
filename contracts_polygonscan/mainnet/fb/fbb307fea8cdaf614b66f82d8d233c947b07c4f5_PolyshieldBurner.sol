/**
 *Submitted for verification at polygonscan.com on 2021-08-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

interface IPolyshield {
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 _amount) external;
}

contract PolyshieldBurner {
    
    address public polyshield;
    mapping(address => uint256) public burnTotals; 
    
    constructor(address _polyshield){
        polyshield = _polyshield;
    }
    
    function burn() public {
        uint256 tokenBalance = IPolyshield(polyshield).balanceOf(address(this));
        IPolyshield(polyshield).burn(tokenBalance);
        burnTotals[msg.sender]+=tokenBalance;
    }
}