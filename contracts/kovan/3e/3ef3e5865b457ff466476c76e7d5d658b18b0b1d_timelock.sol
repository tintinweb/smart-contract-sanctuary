/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

contract timelock {
    
    // beneficiary of tokens after they are released
    address payable _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;    

    // Provider address
    address private _provider;
    
    uint256 private _amount;

constructor (address payable beneficiary_, uint256 releaseTime_, uint256 amount_) payable {
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        require(msg.value == amount_, "Not sending the amount specified");
        _provider = msg.sender;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

  
    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");
        uint256 amount = address(this).balance;
        require(amount > 0, "TokenTimelock: no tokens to release");
        _beneficiary.transfer(amount);
    }    
    
    
}