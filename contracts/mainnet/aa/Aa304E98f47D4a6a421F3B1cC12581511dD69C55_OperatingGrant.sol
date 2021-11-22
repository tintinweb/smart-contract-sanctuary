// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "../interfaces/ITellor.sol";

/**
 @author Tellor Inc.
 @title OperatingGrant
 @dev This contract allows the Tellor team to receive a grant to fund operations.
*/
contract OperatingGrant {
    //Storage
    uint256 public lastReleaseTime;
    uint256 public maxAmount;
    address public beneficiary = 0x39E419bA25196794B595B2a595Ea8E527ddC9856;
    address public constant tellorAddress = 0x88dF592F8eb5D7Bd38bFeF7dEb0fBc02cf3778a0;

    //Events
    event TokenWithdrawal (uint256 _amount);


    constructor () {
        lastReleaseTime = block.timestamp;
    }

    /**
     * @dev Use this function to update the beneficiary address
     *
     */
    function updateBeneficiary (address _newBeneficiary) external {
        require(msg.sender == beneficiary, "must be the beneficiary");
        beneficiary = _newBeneficiary;
    } 
    
    /**
     * @dev Use this function to withdraw released tokens
     *
     */
    function withdrawTrb() external {
        uint256 _availableBalance = ITellor(tellorAddress).balanceOf(address(this));
        if(_availableBalance > maxAmount){
            maxAmount = _availableBalance;
        }
        uint256 _releasedAmount = maxAmount * (block.timestamp - lastReleaseTime)/(86400* 365 * 2); //2 year payout 
        if(_releasedAmount > _availableBalance){
            _releasedAmount = _availableBalance;
        }
        lastReleaseTime = block.timestamp;
        ITellor(tellorAddress).transfer(beneficiary, _releasedAmount);
        emit TokenWithdrawal(_releasedAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title ITellor
 */
interface ITellor {
    function balanceOf(address _user) external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
}