/**
 *Submitted for verification at polygonscan.com on 2021-08-10
*/

pragma solidity ^0.8.4;

/*
 * SPDX-License-Identifier: MIT
*/

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time.
 */
contract TokenTimelock {


    IERC20Token  public _lockedToken;
    address public _beneficiary;
    address public _manager ;
    uint256 public _releaseTime ;
    
    constructor () {
        //_lockedToken = '0x58d872Aa4F9A0a4FEB41E02660b91dd08fCCC23D';
        //_lockedToken = 0x2708865F899fFfFE896817D79FC3C7aF9C669bD2;
        _beneficiary =  msg.sender;
        _manager =  msg.sender;
        _releaseTime = block.timestamp;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20Token) {
        return _lockedToken;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _lockedToken.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _lockedToken.transfer(_beneficiary, amount);
    }


    /*
    * enable changing the beneficiary (eg. for changing to a multi-sig contract instead of address)
    */
    function updateBeneficiary(address _newBeneficiary) public {
        require(_manager == msg.sender,"only the _manager can change this");
        _beneficiary = _newBeneficiary;
    }

    function updateManager(address _newManager) public {
        require(_manager == msg.sender,"only the _manager can change this");
        _manager = _newManager;
    }

    /*  
    * enable extending the lock period
    */
    function updateLockDuration(uint256 _newTime) public {
        require(_manager == msg.sender,"only the _manager can change this");
        require(_newTime > _releaseTime, "new time must be greater than current time");
        _releaseTime = _newTime;
    }
    
    function timelockSetup(IERC20Token _setLockedToken) public {
       require(msg.sender == _manager, "You do not have the required permission.");  
        //owner = msg.sender;
        _lockedToken = _setLockedToken; //set the contract address of default token
    }



}