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

abstract contract StabilityFeeTreasuryLike {
    function takeFunds(address, uint256) virtual external;
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalStabilityFeeTreasuryOverlay is GebAuth {
    StabilityFeeTreasuryLike public treasury;

    constructor(address treasury_) public GebAuth() {
        require(treasury_ != address(0), "MinimalStabilityFeeTreasuryOverlay/null-address");
        treasury = StabilityFeeTreasuryLike(treasury_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /*
    * @notify Call the treasury so it can take funds from another address
    * @param account The address that the treasury should take funds from
    * @amount The amount of funds the treasury should take from the account
    */
    function takeFunds(address account, uint256 amount) external isAuthorized {
        treasury.takeFunds(account, amount);
    }
    /*
    * @notify Modify an uint256 param
    * @param parameter Must be "lastUpdateTime"
    * @param data The new value for lastUpdateTime
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (either(either(parameter == "treasuryCapacity", parameter == "minimumFundsRequired"), parameter == "pullFundsMinThreshold")) {
          treasury.modifyParameters(parameter, data);
        } else revert("MinimalStabilityFeeTreasuryOverlay/modify-forbidden-param");
    }
}