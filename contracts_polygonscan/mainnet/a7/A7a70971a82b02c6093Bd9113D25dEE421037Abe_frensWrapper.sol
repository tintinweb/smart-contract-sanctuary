/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;

interface Staker{
    function frens(address _account) external view returns (uint256 frens_);
}

contract frensWrapper{
    Staker ghstStaking = Staker(0xA02d547512Bb90002807499F05495Fe9C4C3943f);
    
    constructor() {
        
    }
    
    function frens(address _wallet) public view returns(uint256){
        return ghstStaking.frens(_wallet);
    }
}