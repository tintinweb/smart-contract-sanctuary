/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

pragma solidity ^0.5.16;

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
    address internal comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    address public interestRateModel;

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
}