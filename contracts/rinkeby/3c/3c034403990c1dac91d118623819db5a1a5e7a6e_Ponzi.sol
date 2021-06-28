// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPonzi.sol";

/**
 * @dev Implementation of the {IPonzi} interface.
 *
 */
contract Ponzi is IPonzi {
    
    mapping(address => ACC) ACCs;

    uint256 private _dailyPR;
    
    struct ACC {
        address payable receiver;
        uint depositTime;
        uint amount;
        bool destroyAll;
    }
    
    modifier fundsSent() {
        require(msg.value > 0, "Deposit value must be > 0");
        _;
    }
    
    modifier accExists(address _owner) {
        require(haveACC(_owner), "ACC does not exist");
        _;
    }
    
    modifier withdrawable(address _owner) {
        require(ACCs[_owner].receiver == payable(msg.sender), "Withdrawable: Not Invalidation receiver address");
        _;
    }
    
    /**
     * @dev Sets the values for {dailyInterestRate_}.
     *
     */
    constructor(uint256 dailyPR_) {
        _dailyPR = dailyPR_;
    }

    function dailyPR() external view returns (uint256) {
        return _dailyPR;
    }

    /**
     * @dev See {IPonzi-withdrew}.
     */
    function balanceOf(address _owner) 
        external 
        view 
        override 
        accExists(_owner)
        returns (uint256) 
    {
        return ACCs[_owner].amount;
    }

    /**
     * @dev See {IPonzi-deposit}.
     */
    function deposit(address _owner, bool destroyAll) 
        external 
        payable
        override 
        fundsSent
        returns (bool) 
    {
        if (!haveACC(_owner)){
        ACCs[_owner] = ACC(
            payable(_owner),
            block.timestamp,
            msg.value,
            destroyAll
        );
        }
        else{
            ACC storage c = ACCs[_owner];
            c.depositTime = block.timestamp;
            c.amount += msg.value;
            c.destroyAll = destroyAll;
        }
        emit Deposit(_owner);
        if(destroyAll == true){
            emit DestroyAll(
                _owner
                );
        }
        return true;
    }

    /**
     * @dev See {IPonzi-withdrew}.
     */
    function withdrew(address _owner)
        external 
        override
        returns (bool) 
    {
        ACC storage c = ACCs[_owner];
        uint i = ( (block.timestamp - c.depositTime) * 10 * (c.amount) ) / 86400;
        c.amount = c.amount + i;
        if(c.destroyAll == true){
            c.amount = 0;
            c.depositTime = 0;
            emit DestroyAll(_owner);
            collectAllandDestroy(c.receiver);
        }
        else{
            c.receiver.transfer(c.amount);
            c.amount = 0;
            c.depositTime = 0;
            emit Withdrew(_owner);
        }
        return true;
    }
    
    /**
     * @dev Is there a ACC with address _owner.
     */
    function haveACC(address _owner)
        internal
        view
        returns (bool exists)
    {
        exists = (ACCs[_owner].receiver != address(0));
    }
    
    /**
     * @dev Called by the receiver if the ACC.destroyAll is true
     * This will selfdestruct the contract and sned the rest of the funds to the receiver.
     *
     * @param _address Address of the receiver.
     */
    function collectAllandDestroy(address _address) 
        internal
    {
        selfdestruct(payable(_address));
    }

}