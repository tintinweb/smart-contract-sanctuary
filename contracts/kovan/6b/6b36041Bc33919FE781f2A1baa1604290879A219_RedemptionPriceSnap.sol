/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

pragma solidity 0.6.7;

abstract contract OracleRelayerLike {
    function redemptionPrice() virtual public returns (uint256);
}

contract RedemptionPriceSnap {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
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
        require(authorizedAccounts[msg.sender] == 1, "RedemptionPriceSnap/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Latest recorded redemption price
    uint256           public snappedRedemptionPrice;

    OracleRelayerLike public oracleRelayer;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, address data);
    event FailUpdateSnappedPrice(bytes revertReason);

    constructor(
      address oracleRelayer_
    ) public {
        require(oracleRelayer_ != address(0), "RedemptionPriceSnap/null-oracle-relayer");

        authorizedAccounts[msg.sender] = 1;

        oracleRelayer = OracleRelayerLike(oracleRelayer_);
        oracleRelayer.redemptionPrice();

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    uint256 public TEN_THOUSAND = 10000 * 10 ** 27;
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "RedemptionPriceSnap/sub-uint-uint-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "RedemptionPriceSnap/multiply-uint-uint-overflow");
    }
    function delta(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x >= y) ? subtract(x, y) : subtract(y, x);
    }

    // --- Administration ---
    /**
     * @notice Modify general address params
     * @param parameter The name of the contract address being modified
     * @param data New address for the contract
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "RedemptionPriceSnap/null-address");

        if (parameter == "oracleRelayer") {
          oracleRelayer = OracleRelayerLike(data);
          require(oracleRelayer.redemptionPrice() > 0, "RedemptionPriceSnap/null-redemption-price");
        }
        else revert("RedemptionPriceSnap/modify-unrecognized-param");

        emit ModifyParameters(parameter, data);
    }

    // --- Core Logic ---
    /**
    * @notice Update and read the latest redemption price
    **/
    function updateSnappedPrice() public {
        try oracleRelayer.redemptionPrice() returns (uint256 price) {
          if (price == 0) return;
          snappedRedemptionPrice = price;
        } catch(bytes memory revertReason) {
          emit FailUpdateSnappedPrice(revertReason);
        }
    }
    /**
    * @notice Read the latest redemption price and return it
    **/
    function updateAndGetSnappedPrice() external returns (uint256) {
        updateSnappedPrice();
        return snappedRedemptionPrice;
    }
}