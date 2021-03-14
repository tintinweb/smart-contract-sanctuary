pragma solidity ^0.5.16;

import "./CErc20Delegator.sol";
import "./InterestRateModel.sol";
import "./ComptrollerInterface.sol";
import "./CWCErc20Interface.sol";

/**
 * @title CloudWalk's CErc20Delegator Contract
 * @notice CTokens which wrap an EIP-20 underlying and delegate to an implementation
 * @author CloudWalk
 */
contract CWCErc20Delegator is CErc20Delegator, CWCErc20Interface {
    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     * @param implementation_ The address of the implementation the contract delegates to
     * @param becomeImplementationData The encoded args for becomeImplementation
     */
    constructor(address underlying_,
                address comptroller_,
                address interestRateModel_,
                uint initialExchangeRateMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_,
                address payable admin_,
                address implementation_,
                bytes memory becomeImplementationData) CErc20Delegator(
                    underlying_,
                    ComptrollerInterface(comptroller_),
                    InterestRateModel(interestRateModel_),
                    initialExchangeRateMantissa_,
                    name_,
                    symbol_,
                    decimals_,
                    admin_,
                    implementation_,
                    becomeImplementationData) public { } 

    /**
      * @notice Trusted sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function trustedBorrow(uint borrowAmount) external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("trustedBorrow(uint256)", borrowAmount));
        return abi.decode(data, (uint));
    }    

    /**
     * @notice Trusted sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function trustedRepayBorrow(uint repayAmount) external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("trustedRepayBorrow(uint256)", repayAmount));
        return abi.decode(data, (uint));
    }                    
}