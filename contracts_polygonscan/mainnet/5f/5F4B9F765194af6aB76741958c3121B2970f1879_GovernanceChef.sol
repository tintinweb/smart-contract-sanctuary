/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// File: .deps/github/Loesil/VaultChef/contracts/interfaces/IGovernanceDB.sol

interface IGovernanceDB
{
    //-------------------------------------------------------------------------
    // ATTRIBUTES
    //-------------------------------------------------------------------------

    function userIndexLength() external returns(uint256);
    
    //-------------------------------------------------------------------------
    // USER FUNCTIONS
    //-------------------------------------------------------------------------

    function getUserValue(address _user, uint256 _category) external view returns(uint256);
    
    function setUserValue(address _user, uint256 _category, uint256 _value) external;
    
    function setUserValueIfZero(address _user, uint256 _category, uint256 _value) external;
    
    function modifyUserValue(address _user, uint256 _category, uint256 _value, bool _add) external;
}

// File: .deps/github/Loesil/VaultChef/contracts/GovernanceChef.sol

contract GovernanceChef
{
    //-------------------------------------------------------------------------
    // CONSTANTS
    //-------------------------------------------------------------------------
	
	string public constant VERSION = "0.1.0";
	
	uint256 public constant DECIMALS = 6;
	
	//-------------------------------------------------------------------------
    // ATTRIBUTES
    //-------------------------------------------------------------------------
    
    address public govData;
    
    uint256[] public steps_compound;
    
    //-------------------------------------------------------------------------
    // CREATE
    //-------------------------------------------------------------------------
    
    constructor(address _govData)
    {
        govData = _govData;
        steps_compound = [10, 25, 50, 100, 200];
    }
    
    //-------------------------------------------------------------------------
    // VOTING FUNCTIONS
    //-------------------------------------------------------------------------
    
    function getVotingPower(address _user) external view returns(uint256)
    {
        uint256 vp = 0;
        
        //base
        vp += shiftValue(getVotingPower_time(IGovernanceDB(govData).getUserValue(_user, 1)), DECIMALS); //1
        vp += shiftValue(getVotingPower_step(IGovernanceDB(govData).getUserValue(_user, 2), steps_compound) * 5, DECIMALS - 1); //0.5
        
        //check BETA + Test (1000, 1001)
        vp += shiftValue(IGovernanceDB(govData).getUserValue(_user, 1000) * 5, DECIMALS); //5
        vp += shiftValue(IGovernanceDB(govData).getUserValue(_user, 1001), DECIMALS);
        
        //check Team (10000)
        vp += shiftValue(IGovernanceDB(govData).getUserValue(_user, 10000), DECIMALS);
        
        return vp;
    }
    
    //-------------------------------------------------------------------------
    // HELPER FUNCTIONS
    //-------------------------------------------------------------------------
    
    function shiftValue(uint256 _value, uint256 _shift) internal pure returns (uint256)
    {
        return (_value * (10 ** _shift));
    }
    
    function getVotingPower_step(uint256 _value, uint256[] memory _steps) internal pure returns(uint256)
    {
        uint256 val = 0;
        for (uint256 n = 0; n < _steps.length; n++)
        {
            if (_steps[n] > _value)
            {
                break;
            }
            val = _steps[n];
        }
        
        return val;
    }

    function getVotingPower_time(uint256 _time) internal view returns(uint256)
    {
        if (_time == 0)
        {
            return 0;
        }
        
        uint256 dif = block.timestamp - _time;
        uint256 val = 0;
        if (dif >= 365 days) //1 year
        {
            val = (dif / 365 days) + 7;
        }
        else if (dif >= 24 weeks) //6 month
        {
            val = 6;
        }
        else if (dif >= 12 weeks) //3 month
        {
            val = 5;
        }
        else if (dif >= 4 weeks) //1 month
        {
            val = 4;
        }
        else if (dif >= 2 weeks)
        {
            val = 3;
        }
        else if (dif >= 1 weeks)
        {
            val = 2;
        }
        else if (dif >= 1 days)
        {
            val = 1;
        }
        
        if (val > 10)
        {
            val = 10;
        }
        return val;
    }
}