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

abstract contract FixedTreasuryReimbursementLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalFixedTreasuryReimbursementOverlay is GebAuth {
    FixedTreasuryReimbursementLike public reimburser;

    constructor(address reimburser_) public GebAuth() {
        require(reimburser_ != address(0), "MinimalFixedTreasuryReimbursementOverlay/null-address");
        reimburser = FixedTreasuryReimbursementLike(reimburser_);
    }

    /*
    * @notify Modify "fixedReward"
    * @param parameter Must be "fixedReward"
    * @param data The new value for the fixedReward
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "fixedReward") {
          reimburser.modifyParameters(parameter, data);
        } else revert("MinimalFixedTreasuryReimbursementOverlay/modify-forbidden-param");
    }
}