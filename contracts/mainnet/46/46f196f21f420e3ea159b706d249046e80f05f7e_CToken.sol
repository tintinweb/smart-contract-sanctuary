/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

pragma solidity ^0.5.16;

interface ComptrollerInterface {
    function admin() external view returns (address);
    function adminHasRights() external view returns (bool);
    function fuseAdminHasRights() external view returns (bool);
}

interface IFuseFeeDistributor {
    function minBorrowEth() external view returns (uint256);
    function maxSupplyEth() external view returns (uint256);
    function maxUtilizationRate() external view returns (uint256);
    function interestFeeRate() external view returns (uint256);
    function comptrollerImplementationWhitelist(address oldImplementation, address newImplementation) external view returns (bool);
    function cErc20DelegateWhitelist(address oldImplementation, address newImplementation, bool allowResign) external view returns (bool);
    function cEtherDelegateWhitelist(address oldImplementation, address newImplementation, bool allowResign) external view returns (bool);
    function latestComptrollerImplementation(address oldImplementation) external view returns (address);
    function latestCErc20Delegate(address oldImplementation) external view returns (address cErc20Delegate, bool allowResign, bytes memory becomeImplementationData);
    function latestCEtherDelegate(address oldImplementation) external view returns (address cEtherDelegate, bool allowResign, bytes memory becomeImplementationData);
    function deployCEther(bytes calldata constructorData) external returns (address);
    function deployCErc20(bytes calldata constructorData) external returns (address);
    function () external payable;
}

/**
 * @title CToken
 * @notice Built solely to change a faulty IRM.
 */
contract CToken {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;

    /**
     * @notice Administrator for Fuse
     */
    IFuseFeeDistributor internal constant fuseAdmin = IFuseFeeDistributor(0xa731585ab05fC9f83555cf9Bff8F58ee94e18F85);

    /**
     * @dev LEGACY USE ONLY: Administrator for this contract
     */
    address payable internal __admin;

    /**
     * @dev LEGACY USE ONLY: Whether or not the Fuse admin has admin rights
     */
    bool internal __fuseAdminHasRights;

    /**
     * @dev LEGACY USE ONLY: Whether or not the admin has admin rights
     */
    bool internal __adminHasRights;
    
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string internal name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string internal symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 internal decimals;

    /**
     * @notice LEGACY USE ONLY: Pending administrator for this contract
     */
    address payable private __pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface internal comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    address public interestRateModel;
    
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(address oldInterestRateModel, address newInterestRateModel);

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public {
        // Shh -- currently unused
        data;
        
        address newInterestRateModel = 0x5FDCb640b181E19Ef7f77491d8D26E5fF6B7A4DF;
        
        // Used to store old model for use in the event that is emitted on success
        address oldInterestRateModel;

        // Track the market's current interest rate model
        oldInterestRateModel = interestRateModel;

        // Set the interest rate model to newInterestRateModel
        interestRateModel = newInterestRateModel;

        // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
    }

    /**
     * @dev Internal function to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementationInternal(address implementation_, bool allowResign, bytes memory becomeImplementationData) internal {
        // Check whitelist
        require(fuseAdmin.cErc20DelegateWhitelist(implementation, implementation_, allowResign), "!impl");

        // Get old implementation
        address oldImplementation = implementation;

        // Store new implementation
        implementation = implementation_;

        // Call _becomeImplementation externally (delegating to new delegate's code)
        _functionCall(address(this), abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData), "!become");

        // Emit event
        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementationSafe(address implementation_, bool allowResign, bytes calldata becomeImplementationData) external {
        // Check admin rights
        require(hasAdminRights(), "!admin");

        // Set implementation
        _setImplementationInternal(implementation_, allowResign, becomeImplementationData);
    }

    /**
     * @notice Function called before all delegator functions
     * @dev Checks comptroller.autoImplementation and upgrades the implementation if necessary
     */
    function _prepare() external payable {}

    /**
     * @notice Returns a boolean indicating if the sender has admin rights
     */
    function hasAdminRights() internal view returns (bool) {
        return (msg.sender == comptroller.admin() && comptroller.adminHasRights()) || (msg.sender == address(fuseAdmin) && comptroller.fuseAdminHasRights());
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     * @param data The call data (encoded using abi.encode or one of its variants).
     * @param errorMessage The revert string to return on failure.
     */
    function _functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.call(data);

        if (!success) {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }

        return returndata;
    }
}