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

abstract contract RateSetterLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract MinimalRateSetterOverlay is GebAuth {
    address        public pCalculator;
    address        public piCalculator;

    RateSetterLike public rateSetter;

    constructor(address rateSetter_, address pCalculator_, address piCalculator_) public {
        require(rateSetter_ != address(0), "MinimalRateSetterOverlay/null-address");
        require(both(pCalculator_ != address(0), piCalculator_ != address(0)), "MinimalRateSetterOverlay/null-calculators");

        rateSetter   = RateSetterLike(rateSetter_);
        pCalculator  = pCalculator_;
        piCalculator = piCalculator_;
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /*
    * @notify Change address params
    * @param parameter The name of the parameter to change
    * @param data The new address for the orcl
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "orcl") {
          rateSetter.modifyParameters(parameter, data);
        } else if (parameter == "pidCalculator") {
          require(either(data == pCalculator, data == piCalculator), "MinimalRateSetterOverlay/invalid-calculator-address");
          rateSetter.modifyParameters(parameter, data);
        } else revert("MinimalRateSetterOverlay/modify-forbidden-param");
    }
}