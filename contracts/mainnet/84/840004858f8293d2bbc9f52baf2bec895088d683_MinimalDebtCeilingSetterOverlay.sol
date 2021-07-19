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

abstract contract DebtCeilingSetterLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalDebtCeilingSetterOverlay is GebAuth {
    DebtCeilingSetterLike public ceilingSetter;

    constructor(address ceilingSetter_) public GebAuth() {
        require(ceilingSetter_ != address(0), "MinimalDebtCeilingSetterOverlay/null-address");
        ceilingSetter = DebtCeilingSetterLike(ceilingSetter_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /*
    * @notify Modify the blockIncreaseWhenRevalue or blockDecreaseWhenDevalue value inside the ceiling setter
    * @param parameter Must be "blockIncreaseWhenRevalue" or "blockDecreaseWhenDevalue"
    * @param data The new value for blockIncreaseWhenRevalue or blockDecreaseWhenDevalue
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (either(parameter == "blockIncreaseWhenRevalue", parameter == "blockDecreaseWhenDevalue")) {
          ceilingSetter.modifyParameters(parameter, data);
        } else revert("MinimalDebtCeilingSetterOverlay/modify-forbidden-param");
    }
}