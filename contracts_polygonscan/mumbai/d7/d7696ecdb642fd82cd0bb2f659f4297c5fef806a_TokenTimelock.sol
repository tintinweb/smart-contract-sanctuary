/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

pragma solidity ^0.8.4;

/*
 * SPDX-License-Identifier: MIT
*/

/*
* CREATED BY ME - Version 1
* receive any token, lock for a period of time, before allowing withdraw.
* works with liquidity tokens also
* Version 2
* auto extending timelock (eg. 30 day rolling timelock, that requires a pause request)
* this let's users have an eternal timelock, with the ability to pause if needed and gives the community time to react
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
 * 
 * add function check_release_time
 * add function extend release_time
 * 
 */
contract TokenTimelock {


    IERC20Token  public _lockedToken;
    address public _beneficiary;
    address public _manager ;
    //uint256 public _releaseTime ;
    uint256 public _pauseTime ;
    uint256 public _rollingTime ;
    
    constructor () {
        //_lockedToken = '0x58d872Aa4F9A0a4FEB41E02660b91dd08fCCC23D';
        //_lockedToken = 0x2708865F899fFfFE896817D79FC3C7aF9C669bD2;
        _beneficiary =  msg.sender;
        _manager =  msg.sender;
        //_releaseTime = block.timestamp;
        _pauseTime = 0;
        _rollingTime = 60 * 60 * 24 * 30; // 30 days
    }
    
    event lockUpdate (uint256 pauseUpdate, string themessage);

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20Token) {
        return _lockedToken;
    }

   
    
    

    /**
     * @return the time when the tokens are released.
     */
    function getReleaseTime() public view returns (uint256) {
        if(_pauseTime > 0){
            //_releaseTime = _pauseTime + _rollingTime;
            return _pauseTime + _rollingTime;
        }
        else{
            //_releaseTime = block.timestamp + _rollingTime;
            return block.timestamp + _rollingTime;
        }
        //return _releaseTime;
    }
    
     /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release_rolling() public {
        require(_manager == msg.sender,"only the _manager can change this");
        // ensure we are using the correct release time
        require(_pauseTime >0, "Lock must be paused");
        require(block.timestamp >= (_pauseTime + _rollingTime), "Rolling Time must be > current time");
        //require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _lockedToken.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _lockedToken.transfer(_beneficiary, amount);
    }
    
    
    
     function pauseTimelock() public {
        require(_manager == msg.sender,"only the _manager can change this");
        require(_pauseTime == 0, "The token must be locked before pausing");
        
        _pauseTime = block.timestamp;
        emit lockUpdate(_pauseTime, 'A pause request was made');
    }
    
    function unpauseTimelock() public {
        require(_manager == msg.sender,"only the _manager can change this");
        require(_pauseTime > 0, "The token must be locked before pausing");
        
        _pauseTime = 0;
        emit lockUpdate(_pauseTime, 'The contract has been locked');
    }
    
    
    
    
    
    
    
    

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     
    function release() public {
        
        // ensure we are using the correct release time
        _releaseTime = releaseTime();
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _lockedToken.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _lockedToken.transfer(_beneficiary, amount);
    }
    */


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
    
    function updateLockDuration(uint256 _newTime) public {
        require(_manager == msg.sender,"only the _manager can change this");
        require(_newTime > _releaseTime, "new time must be greater than current time");
        _releaseTime = _newTime;
    }
    */
    
    function timelockSetup(IERC20Token _setLockedToken) public {
       require(msg.sender == _manager, "You do not have the required permission.");  
        //owner = msg.sender;
        _lockedToken = _setLockedToken; //set the contract address of default token
    }



}