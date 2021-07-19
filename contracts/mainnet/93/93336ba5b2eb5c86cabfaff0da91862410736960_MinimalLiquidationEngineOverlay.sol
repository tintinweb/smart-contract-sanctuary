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

abstract contract LiquidationEngineLike {
    function connectSAFESaviour(address) virtual external;
    function disconnectSAFESaviour(address) virtual external;
}
contract MinimalLiquidationEngineOverlay is GebAuth {
    LiquidationEngineLike public liquidationEngine;

    constructor(address liquidationEngine_) public GebAuth() {
        require(liquidationEngine_ != address(0), "MinimalLiquidationEngineOverlay/null-address");
        liquidationEngine = LiquidationEngineLike(liquidationEngine_);
    }

    /*
    * @notify Connect a new safe saviour to the LiquidationEngine
    * @param saviour The new saviour address
    */
    function connectSAFESaviour(address saviour) external isAuthorized {
        liquidationEngine.connectSAFESaviour(saviour);
    }
    /*
    * @notify Disconnect an existing safe saviour from the LiquidationEngine
    * @param saviour The saviour address to disconnect
    */
    function disconnectSAFESaviour(address saviour) external isAuthorized {
        liquidationEngine.disconnectSAFESaviour(saviour);
    }
}