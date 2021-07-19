/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity 0.6.7;

contract GebAuth {
    // --- Authorization ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "GebAuth/account-not-authorized");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);

    constructor () public {
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }
}

abstract contract AccountingEngineLike {
    function modifyParameters(bytes32, address) virtual external;
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalAccountingEngineOverlay is GebAuth {
    AccountingEngineLike public accountingEngine;

    constructor(address accountingEngine_) public GebAuth() {
        require(accountingEngine_ != address(0), "MinimalAccountingEngineOverlay/null-address");
        accountingEngine = AccountingEngineLike(accountingEngine_);
    }

    /*
    * @notice Modify the systemStakingPool address inside the AccountingEngine
    * @param parameter Must be "systemStakingPool"
    * @param data The new address for the systemStakingPool
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "systemStakingPool") {
          accountingEngine.modifyParameters(parameter, data);
        }
        else revert("MinimalAccountingEngineOverlay/modify-forbidden-param");
    }
    /*
    * @notice Modify extraSurplusIsTransferred
    * @param parameter Must be "extraSurplusIsTransferred"
    * @param data The new value for extraSurplusIsTransferred
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "extraSurplusIsTransferred") {
          accountingEngine.modifyParameters(parameter, data);
        }
        else revert("MinimalAccountingEngineOverlay/modify-forbidden-param");
    }
}