// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPonzi.sol";

/**
 * @dev Implementation of the {IPonzi} interface.
 *
 */
contract Ponzi is IPonzi {
    
    mapping(address => ACC) ACCs;

    uint256 private _totalfunds;

    uint256 private _dailyInterestRate;
    
    struct ACC {
        address payable receiver;
        uint depositTime;
        uint amount;
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
     * The default value of {_totalfunds} is 0. 
     *
     */
    constructor(uint256 dailyInterestRate_) {
        _dailyInterestRate = dailyInterestRate_;
        _totalfunds = 0;
    }

    function dailyInterestRate() external view returns (uint256) {
        return _dailyInterestRate;
    }

    function totalFunds() external view returns (uint256) {
        return _totalfunds;
    }

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
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function deposit(address _owner) 
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
            msg.value
        );
        }
        else{
            ACC storage c = ACCs[_owner];
            c.amount += msg.value;
        }
        emit Deposit(_owner);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function withdrew(address _owner)
        external 
        override
        payable
        returns (bool) 
    {
        emit Withdrew(_owner);
        return true;
    }
    
    /**
     * @dev Is there a ACCContract with address _owner.
     */
    function haveACC(address _owner)
        internal
        view
        returns (bool exists)
    {
        exists = (ACCs[_owner].receiver != address(0));
    }
    
    /**
     * @dev Called by the receiver if the LockContract.destroyAll is true
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