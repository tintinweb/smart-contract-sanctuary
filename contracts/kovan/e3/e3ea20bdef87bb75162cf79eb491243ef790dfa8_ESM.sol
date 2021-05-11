/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

abstract contract TokenLike {
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address) virtual public view returns (uint256);
    function transfer(address, uint256) virtual public returns (bool);
    function transferFrom(address, address, uint256) virtual public returns (bool);
}

abstract contract GlobalSettlementLike {
    function shutdownSystem() virtual public;
}

contract ESM {
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
        require(authorizedAccounts[msg.sender] == 1, "esm/account-not-authorized");
        _;
    }

    TokenLike            public protocolToken;      // collateral
    GlobalSettlementLike public globalSettlement;   // shutdown module
    ESMThresholdSetter   public thresholdSetter;    // threshold setter

    address              public tokenBurner;        // burner
    uint256              public triggerThreshold;   // threshold
    uint256              public settled;            // flag that indicates whether the shutdown module has been called/triggered

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 wad);
    event ModifyParameters(bytes32 parameter, address account);
    event Shutdown();
    event FailRecomputeThreshold(bytes revertReason);

    constructor(
      address protocolToken_,
      address globalSettlement_,
      address tokenBurner_,
      address thresholdSetter_,
      uint256 triggerThreshold_
    ) public {
        require(both(triggerThreshold_ > 0, triggerThreshold_ < TokenLike(protocolToken_).totalSupply()), "esm/threshold-not-within-bounds");

        authorizedAccounts[msg.sender] = 1;

        protocolToken    = TokenLike(protocolToken_);
        globalSettlement = GlobalSettlementLike(globalSettlement_);
        thresholdSetter  = ESMThresholdSetter(thresholdSetter_);
        tokenBurner      = tokenBurner_;
        triggerThreshold = triggerThreshold_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters(bytes32("triggerThreshold"), triggerThreshold_);
        emit ModifyParameters(bytes32("thresholdSetter"), thresholdSetter_);
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    // --- Utils ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Administration ---
    /*
    * @notice Modify a uint256 parameter
    * @param parameter The name of the parameter to change the value for
    * @param wad The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 wad) external {
        require(settled == 0, "esm/already-settled");
        require(either(address(thresholdSetter) == msg.sender, authorizedAccounts[msg.sender] == 1), "esm/account-not-authorized");
        if (parameter == "triggerThreshold") {
          require(both(wad > 0, wad < protocolToken.totalSupply()), "esm/threshold-not-within-bounds");
          triggerThreshold = wad;
        }
        else revert("esm/modify-unrecognized-param");
        emit ModifyParameters(parameter, wad);
    }
    /*
    * @notice Modify an address parameter
    * @param parameter The parameter name whose value will be changed
    * @param account The new address for the parameter
    */
    function modifyParameters(bytes32 parameter, address account) external isAuthorized {
        require(settled == 0, "esm/already-settled");
        if (parameter == "thresholdSetter") {
          thresholdSetter = ESMThresholdSetter(account);
          // Make sure the update works
          thresholdSetter.recomputeThreshold();
        }
        else revert("esm/modify-unrecognized-param");
        emit ModifyParameters(parameter, account);
    }

    /*
    * @notify Recompute the triggerThreshold using the thresholdSetter
    */
    function recomputeThreshold() internal {
        if (address(thresholdSetter) != address(0)) {
          try thresholdSetter.recomputeThreshold() {}
          catch(bytes memory revertReason) {
            emit FailRecomputeThreshold(revertReason);
          }
        }
    }
    /*
    * @notice Sacrifice tokens and trigger settlement
    * @dev This can only be done once
    */
    function shutdown() external {
        require(settled == 0, "esm/already-settled");
        recomputeThreshold();
        settled = 1;
        require(protocolToken.transferFrom(msg.sender, tokenBurner, triggerThreshold), "esm/transfer-failed");
        emit Shutdown();
        globalSettlement.shutdownSystem();
    }
}


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