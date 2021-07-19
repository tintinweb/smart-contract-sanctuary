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

abstract contract TaxCollectorLike {
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) virtual external;
    function taxSingle(bytes32) virtual public returns (uint256);
}
contract MinimalTaxCollectorOverlay is GebAuth {
    // --- Variables ---
    // Stability fee bounds for every collateral type
    mapping(bytes32 => Bounds) public stabilityFeeBounds;
    TaxCollectorLike           public taxCollector;

    // --- Structs ---
    struct Bounds {
        // Maximum per second stability fee that can be charged for a collateral type
        uint256 upperBound;  // [ray]
        // Minimum per second stability fee that can be charged for a collateral type
        uint256 lowerBound;  // [ray]
    }

    constructor(
      address taxCollector_,
      bytes32[] memory collateralTypes,
      uint256[] memory lowerBounds,
      uint256[] memory upperBounds
    ) public {
        require(taxCollector_ != address(0), "MinimalTaxCollectorOverlay/null-address");
        require(both(collateralTypes.length == lowerBounds.length, lowerBounds.length == upperBounds.length), "MinimalTaxCollectorOverlay/invalid-array-lengths");
        require(collateralTypes.length > 0, "MinimalTaxCollectorOverlay/null-array-lengths");

        taxCollector = TaxCollectorLike(taxCollector_);

        // Loop through the bounds array and set them for each collateral type
        for (uint i = 0; i < collateralTypes.length; i++) {
            // Make sure we don't set bounds for the same collateral type twice
            require(
              both(stabilityFeeBounds[collateralTypes[i]].upperBound == 0, stabilityFeeBounds[collateralTypes[i]].lowerBound == 0),
              "MinimalTaxCollectorOverlay/bounds/already-set"
            );
            // Make sure the upper bound is >= the lower bound
            require(upperBounds[i] >= lowerBounds[i], "MinimalTaxCollectorOverlay/invalid-bounds");
            stabilityFeeBounds[collateralTypes[i]] = Bounds(upperBounds[i], lowerBounds[i]);
        }
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Math ---
    uint256 public constant RAY = 10 ** 27;

    /*
    * @notice Modify the stability fee for a collateral type; revert if the new fee is not within bounds
    * @param collateralType The collateral type to change the fee for
    * @param parameter Must be "stabilityFee"
    * @param data The new fee
    */
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) external isAuthorized {
        // Fetch the bounds
        uint256 lowerBound = stabilityFeeBounds[collateralType].lowerBound;
        uint256 upperBound = stabilityFeeBounds[collateralType].upperBound;
        // Check that the collateral type has bounds
        require(
          upperBound >= lowerBound,
          "MinimalTaxCollectorOverlay/bounds-improperly-set"
        );
        // Check that the new fee is within bounds
        require(both(data <= upperBound, data >= lowerBound), "MinimalTaxCollectorOverlay/fee-exceeds-bounds");
        // Check that the parameter name is correct
        require(parameter == "stabilityFee", "MinimalTaxCollectorOverlay/invalid-parameter");
        // Collect the fee up until now
        taxCollector.taxSingle(collateralType);
        // Finally set the new fee
        taxCollector.modifyParameters(collateralType, parameter, data);
    }
}