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

abstract contract RrfmCalculatorLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, int256) virtual external;
}
contract MinimalRrfmCalculatorOverlay is GebAuth {
    // --- Vars ---
    mapping(bytes32 => UnsignedBounds) public unsignedBounds;
    mapping(bytes32 => SignedBounds)   public signedBounds;

    RrfmCalculatorLike public calculator;

    // --- Structs ---
    struct UnsignedBounds {
        uint256 upperBound;
        uint256 lowerBound;
    }
    struct SignedBounds {
        int256 upperBound;
        int256 lowerBound;
    }

    constructor(
        address calculator_,
        bytes32[] memory unsignedParams,
        bytes32[] memory signedParams,
        uint256[] memory unsignedUpperBounds,
        uint256[] memory unsignedLowerBounds,
        int256[] memory signedUpperBounds,
        int256[] memory signedLowerBounds
    ) public {
        require(
          both(unsignedParams.length == unsignedUpperBounds.length, unsignedParams.length == unsignedLowerBounds.length),
          "MinimalRrfmCalculatorOverlay/invalid-unsigned-lengths"
        );
        require(
          both(signedParams.length == signedUpperBounds.length, signedParams.length == signedLowerBounds.length),
          "MinimalRrfmCalculatorOverlay/invalid-signed-lengths"
        );
        require(calculator_ != address(0), "MinimalRrfmCalculatorOverlay/null-calculator");

        uint256 i;
        for (i = 0; i < unsignedParams.length; i++) {
            require(either(unsignedUpperBounds[i] != 0, unsignedLowerBounds[i] != 0), "MinimalRrfmCalculatorOverlay/invalid-uint-bounds");
            require(unsignedUpperBounds[i] >= unsignedLowerBounds[i], "MinimalRrfmCalculatorOverlay/incorrect-uint-bounds");
            unsignedBounds[unsignedParams[i]] = UnsignedBounds(unsignedUpperBounds[i], unsignedLowerBounds[i]);
        }
        for (i = 0; i < signedParams.length; i++) {
            require(either(signedUpperBounds[i] != 0, signedLowerBounds[i] != 0), "MinimalRrfmCalculatorOverlay/invalid-int-bounds");
            require(signedUpperBounds[i] >= signedLowerBounds[i], "MinimalRrfmCalculatorOverlay/incorrect-int-bounds");
            signedBounds[signedParams[i]] = SignedBounds(signedUpperBounds[i], signedLowerBounds[i]);
        }

        calculator = RrfmCalculatorLike(calculator_);
    }
    
    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /*
    * @notify Modify a uint256 param inside the calculator
    * @param parameter The parameter's name
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        UnsignedBounds memory bounds = unsignedBounds[parameter];

        if (parameter == "allReaderToggle") {
            calculator.modifyParameters(parameter, uint(1));
        }
        else if (either(bounds.upperBound != 0, bounds.lowerBound != 0)) {
            require(both(val >= bounds.lowerBound, val <= bounds.upperBound), "MinimalRrfmCalculatorOverlay/invalid-value");
            calculator.modifyParameters(parameter, val);
        }
        else revert("MinimalRrfmCalculatorOverlay/modify-forbidden-param");
    }

    /*
    * @notify Modify a int256 param inside the calculator
    * @param parameter The parameter's name
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, int256 val) external isAuthorized {
        SignedBounds memory bounds = signedBounds[parameter];

        if (parameter == "pdc") {
            calculator.modifyParameters(parameter, int(0));
        }
        else if (either(bounds.upperBound != 0, bounds.lowerBound != 0)) {
            require(both(val >= bounds.lowerBound, val <= bounds.upperBound), "MinimalRrfmCalculatorOverlay/invalid-value");
            calculator.modifyParameters(parameter, val);
        }
        else revert("MinimalRrfmCalculatorOverlay/modify-forbidden-param");
    }
}