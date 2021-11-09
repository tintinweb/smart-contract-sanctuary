/**
 *Submitted for verification at Etherscan.io on 2021-11-08
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

abstract contract GebLenderFirstResortRewardsLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalLenderFirstResortOverlay is GebAuth {
    GebLenderFirstResortRewardsLike public staking;

    // Max amount of staked tokens to keep
    uint256                         public maxStakedTokensToKeep;

    constructor(address staking_, uint256 maxStakedTokensToKeep_) public GebAuth() {
        require(staking_ != address(0), "MinimalLenderFirstResortOverlay/null-address");
        require(maxStakedTokensToKeep_ > 0, "MinimalLenderFirstResortOverlay/null-maxStakedTokensToKeep");
        staking               = GebLenderFirstResortRewardsLike(staking_);
        maxStakedTokensToKeep = maxStakedTokensToKeep_;
    }

    /*
    * @notify Modify escrowPaused
    * @param parameter Must be "escrowPaused"
    * @param data The new value for escrowPaused
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "escrowPaused") {
            staking.modifyParameters(parameter, data);
        } else if (parameter == "minStakedTokensToKeep") {
            require(data <= maxStakedTokensToKeep, "MinimalLenderFirstResortOverlay/minStakedTokensToKeep-over-limit");
            staking.modifyParameters(parameter, data);
        }
        else revert("MinimalLenderFirstResortOverlay/modify-forbidden-param");
    }
}