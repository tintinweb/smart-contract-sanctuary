/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity 0.6.7;

abstract contract ESMLike {
    function settled() virtual public view returns (uint256);
    function modifyParameters(bytes32, uint256) virtual external;
}
abstract contract ProtocolTokenLike {
    function balanceOf(address) virtual public view returns (uint256);
    function totalSupply() virtual public view returns (uint256);
}

contract ESMThresholdSetter {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) public isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) public isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "ESMThresholdSetter/account-not-authorized");
        _;
    }

    // --- Variables ---
    // The minimum amount of protocol tokens that must be burned to trigger settlement using the ESM
    uint256           public minAmountToBurn;         // [wad]
    // The percentage of outstanding protocol tokens to burn in order to trigger settlement using the ESM
    uint256           public supplyPercentageToBurn;  // [thousand]

    // The address of the protocol token
    ProtocolTokenLike public protocolToken;
    // The address of the ESM contract
    ESMLike           public esm;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, address account);

    constructor(
      address protocolToken_,
      uint256 minAmountToBurn_,
      uint256 supplyPercentageToBurn_
    ) public {
        require(protocolToken_ != address(0), "ESMThresholdSetter/");
        require(both(supplyPercentageToBurn_ > 0, supplyPercentageToBurn_ < THOUSAND), "ESMThresholdSetter/invalid-percentage-to-burn");
        require(minAmountToBurn_ > 0, "ESMThresholdSetter/null-min-amount-to-burn");

        authorizedAccounts[msg.sender] = 1;

        minAmountToBurn        = minAmountToBurn_;
        supplyPercentageToBurn = supplyPercentageToBurn_;
        protocolToken          = ProtocolTokenLike(protocolToken_);

        require(protocolToken.totalSupply() > 0, "ESMThresholdSetter/null-token-supply");
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Math ---
    uint256 constant THOUSAND = 10 ** 3;
    function maximum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x >= y) ? x : y;
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ESMThresholdSetter/sub-uint-uint-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ESMThresholdSetter/multiply-uint-uint-overflow");
    }

    // --- Administration ---
    /*
    * @notify Change the ESM address
    * @parameter Name of the parameter (should only be "esm")
    * @param New ESM address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "ESMThresholdSetter/null-addr");
        if (parameter == "esm") {
          require(address(esm) == address(0), "ESMThresholdSetter/esm-already-set");
          esm = ESMLike(addr);
          require(esm.settled() == 0, "ESMThresholdSetter/esm-disabled");
        } else revert("ESMThresholdSetter/modify-unrecognized-param");
        emit ModifyParameters("esm", addr);
    }
    /*
    * @notify Calculate and set a new protocol token threshold in the ESM
    */
    function recomputeThreshold() public {
        // The ESM must still be functional
        require(esm.settled() == 0, "ESMThresholdSetter/esm-disabled");

        uint256 currentTokenSupply = protocolToken.totalSupply();
        if (currentTokenSupply == 0) { // If the current supply is zero, set the min amount to burn
          esm.modifyParameters("triggerThreshold", minAmountToBurn);
        } else { // Otherwise compute a new threshold taking into account supplyPercentageToBurn
          uint256 newThreshold = multiply(subtract(currentTokenSupply, protocolToken.balanceOf(address(0))), supplyPercentageToBurn) / THOUSAND;
          esm.modifyParameters("triggerThreshold", maximum(minAmountToBurn, newThreshold));
        }
    }
}