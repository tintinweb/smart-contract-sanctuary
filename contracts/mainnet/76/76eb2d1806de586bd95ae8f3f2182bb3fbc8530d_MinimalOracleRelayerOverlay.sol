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

abstract contract OracleRelayerLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function redemptionPrice() virtual public returns (uint256);
}
contract MinimalOracleRelayerOverlay is GebAuth {
    OracleRelayerLike public oracleRelayer;
    uint256           public constant RAY = 10 ** 27;

    constructor(address oracleRelayer_) public GebAuth() {
        require(oracleRelayer_ != address(0), "MinimalOracleRelayerOverlay/null-address");
        oracleRelayer = OracleRelayerLike(oracleRelayer_);
    }

    /*
    * @notice Reset the redemption rate to 0%
    */
    function restartRedemptionRate() external isAuthorized {
        oracleRelayer.redemptionPrice();
        oracleRelayer.modifyParameters("redemptionRate", RAY);
    }
}