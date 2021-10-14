/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity ^0.5.0;

interface ICourtStake{
    function blockWithdraw(address account,uint256 time) external;
    function getUserPower(address account) external view returns(uint256);
}

contract CourtStakeDummy is ICourtStake{
    mapping(address =>uint256) public powerDB;
    function blockWithdraw(address account,uint256 time) external{
        
    }
    function getUserPower(address account) external view returns(uint256){
        return powerDB[account];
    }
    function setUserPower(address account, uint256 power) external returns(uint256){
        powerDB[account] = power;
    }
}