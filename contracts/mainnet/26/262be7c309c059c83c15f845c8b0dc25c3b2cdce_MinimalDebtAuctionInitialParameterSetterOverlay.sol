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

abstract contract DebtAuctionInitialParameterSetterLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract MinimalDebtAuctionInitialParameterSetterOverlay is GebAuth {
    DebtAuctionInitialParameterSetterLike public debtAuctionParamSetter;

    constructor(address debtAuctionParamSetter_) public GebAuth() {
        require(debtAuctionParamSetter_ != address(0), "MinimalDebtAuctionInitialParameterSetterOverlay/null-address");
        debtAuctionParamSetter = DebtAuctionInitialParameterSetterLike(debtAuctionParamSetter_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /*
    * @notify Change the address of the protocolTokenOrcl or systemCoinOrcl inside the debtAuctionParamSetter
    * @param parameter Must be "protocolTokenOrcl" or "systemCoinOrcl"
    * @param data The new address for the protocolTokenOrcl or the systemCoinOrcl
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (either(parameter == "protocolTokenOrcl", parameter == "systemCoinOrcl")) {
            debtAuctionParamSetter.modifyParameters(parameter, data);
        }
        else revert("MinimalDebtAuctionInitialParameterSetterOverlay/modify-forbidden-param");
    }
}