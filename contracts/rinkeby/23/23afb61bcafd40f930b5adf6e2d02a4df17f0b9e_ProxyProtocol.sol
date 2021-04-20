pragma solidity ^0.7.6;

import "./PErc20.sol";
import "./PEther.sol";
import "./PTokenFactory.sol";
import "./PriceOracle.sol";
import "./SafeMath.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

contract ProxyProtocol {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public admin;
    address public pendingAdmin;

    address public proxyToken;
    address public feeRecipient;
    uint public feeAmountCreatePool;
    uint public feePercentMint;
    uint public feePercentRepayBorrow;

    address public pTokenFactory;
    UniswapPriceOracle public oracle;
    address payable public pETH;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewFee(uint newFee);

    constructor(
        address pTokenFactory_,
        address payable pETH_,
        address admin_,
        address proxyToken_,
        address feeRecipient_,
        uint feeAmountCreatePool_,
        uint feePercentMint_,
        uint feePercentRepayBorrow_
    ) {
        pTokenFactory = pTokenFactory_;
        pETH = pETH_;
        admin = admin_;
        proxyToken = proxyToken_;
        oracle = PTokenFactory(pTokenFactory).oracle();

        feeRecipient = feeRecipient_;
        feeAmountCreatePool = feeAmountCreatePool_; // value
        feePercentMint = feePercentMint_; // For example: 100% = 1e18, 1% = 1e16, 0.01% = 1e14
        feePercentRepayBorrow = feePercentRepayBorrow_; //
    }

    /*** User Interface ***/

    /**
     * Creates new pToken with proxy contract
     * @param underlying_ The address of the underlying asset
     */
    function createPToken(address underlying_) external returns (uint) {
        doTransferFee(msg.sender, proxyToken, feeAmountCreatePool);

        return delegateTo(pTokenFactory, abi.encodeWithSignature("createPToken(address)", underlying_));
    }

    /**
     * @notice Sender supplies assets into the market and receives pTokens in exchange
     * @param pToken The address of pToken
     * @param mintAmount The amount of the underlying asset to supply
     */
    function mint(address pToken, uint mintAmount) external returns (uint) {
        uint fee = calcFee(feePercentMint, pToken, mintAmount);
        doTransferFee(msg.sender, proxyToken, fee);

        return delegateTo(pToken, abi.encodeWithSignature("mint(uint256)", mintAmount));
    }

    /**
     * @notice Sender redeems pTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param pToken The address of pToken
     * @param redeemTokens The number of pTokens to redeem into underlying
     */
    function redeem(address pToken, uint redeemTokens) external returns (uint) {
        return delegateTo(pToken, abi.encodeWithSignature("redeem(uint256)", redeemTokens));
    }

    /**
     * @notice Sender redeems pTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param pToken The address of pToken
     * @param redeemAmount The amount of underlying to redeem
     */
    function redeemUnderlying(address pToken, uint redeemAmount) external returns (uint) {
        return delegateTo(pToken, abi.encodeWithSignature("redeemUnderlying(uint256)", redeemAmount));
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @param pToken The address of pToken
      */
    function borrow(address pToken, uint borrowAmount) external returns (uint) {
        return delegateTo(pToken, abi.encodeWithSignature("borrow(uint256)", borrowAmount));
    }

    /**
     * @notice Sender repays their own borrow
     * @param pToken The address of pToken
     * @param repayAmount The amount to repay
     */
    function repayBorrow(address pToken, uint repayAmount) external returns (uint) {
        uint fee = calcFee(feePercentRepayBorrow, pToken, repayAmount);
        doTransferFee(msg.sender, proxyToken, fee);

        return delegateTo(pToken, abi.encodeWithSignature("repayBorrow(uint256)", repayAmount));
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param pToken The address of pToken
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     */
    function repayBorrowBehalf(address pToken, address borrower, uint repayAmount) external returns (uint) {
        uint fee = calcFee(feePercentRepayBorrow, pToken, repayAmount);
        doTransferFee(msg.sender, proxyToken, fee);

        return delegateTo(pToken, abi.encodeWithSignature("repayBorrowBehalf(address,uint256)", borrower, repayAmount));
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     * The collateral seized is transferred to the liquidator.
     * @param pToken The address of pToken
     * @param borrower The borrower of this pToken to be liquidated
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param pTokenCollateral The market in which to seize collateral from the borrower
     */
    function liquidateBorrow(address pToken, address borrower, uint repayAmount, PTokenInterface pTokenCollateral) external returns (uint) {
        return delegateTo(pToken, abi.encodeWithSignature("liquidateBorrow(address,uint256,address)", borrower, repayAmount, pTokenCollateral));
    }

    /*** ETH functions ***/

    /**
     * @notice Sender supplies assets into the market and receives pTokens in exchange
     * @dev Reverts upon any failure
     */
    function mint() external payable {
        uint fee = calcFee(feePercentMint, pETH, msg.value);

        doTransferFee(msg.sender, proxyToken, fee);
        delegateTo(pETH, abi.encodeWithSignature("mint()"));
    }

    /**
     * @notice Sender redeems pTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of pTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external returns (uint) {
        return delegateTo(pETH, abi.encodeWithSignature("redeem(uint256)", redeemTokens));
    }

    /**
     * @notice Sender redeems pTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return delegateTo(pETH, abi.encodeWithSignature("redeemUnderlying(uint256)", redeemAmount));
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) external returns (uint) {
        return delegateTo(pETH, abi.encodeWithSignature("borrow(uint256)", borrowAmount));
    }

    /**
     * @notice Sender repays their own borrow
     * @dev Reverts upon any failure
     */
    function repayBorrow() external payable {
        uint fee = calcFee(feePercentRepayBorrow, pETH, msg.value);
        doTransferFee(msg.sender, proxyToken, fee);

        delegateTo(pETH, abi.encodeWithSignature("repayBorrow()"));
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @dev Reverts upon any failure
     * @param borrower the account with the debt being payed off
     */
    function repayBorrowBehalf(address borrower) external payable {
        uint fee = calcFee(feePercentRepayBorrow, pETH, msg.value);
        doTransferFee(msg.sender, proxyToken, fee);

        delegateTo(pETH, abi.encodeWithSignature("repayBorrowBehalf(address)", borrower));
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     * The collateral seized is transferred to the liquidator.
     * @dev Reverts upon any failure
     * @param borrower The borrower of this pToken to be liquidated
     * @param pTokenCollateral The market in which to seize collateral from the borrower
     */
    function liquidateBorrow(address borrower, PToken pTokenCollateral) external payable {
        delegateTo(pETH, abi.encodeWithSignature("liquidateBorrow(address,address)", borrower, pTokenCollateral));
    }

    function calcFee(uint feePercent, address pToken, uint amount) public view returns (uint) {
        return oracle.getUnderlyingPrice(pToken).mul(amount).mul(feePercent).div(1e18);
    }

    /*** Admin functions ***/

    function _setFee(uint feeAmountCreatePool_, uint feePercentMint_, uint feePercentRepayBorrow_) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'ProxyProtocol: Only admin can set fee');

        // Store fee with new values
        feeAmountCreatePool = feeAmountCreatePool_;
        feePercentMint = feePercentMint_;
        feePercentRepayBorrow = feePercentRepayBorrow_;

        return true;
    }

    function _setRecipient(address newFeeRecipient) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'ProxyProtocol: Only admin can set fee recipient');

        // Store feeRecipient with value newFeeRecipient
        feeRecipient = newFeeRecipient;

        return true;
    }

    function _setPendingAdmin(address newPendingAdmin) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'ProxyProtocol: Only admin can set pending admin');

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        return true;
    }

    function _acceptAdmin() public returns (bool) {
        // Check caller is pendingAdmin
        require(msg.sender == pendingAdmin, 'ProxyProxyProtocol: Only pendingAdmin can accept admin');

        address oldAdmin = admin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);

        return true;
    }

    /*** Safe Token ***/
    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferFee(address from, address token, uint amount) internal {
        if (amount == 0) {
            return;
        }

        IERC20 ERC20Interface = IERC20(token);
        ERC20Interface.safeTransferFrom(from, feeRecipient, amount);
    }

    function delegateTo(address callee, bytes memory data) internal returns (uint) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return toUint(returnData);
    }

    function toUint(bytes memory _bytes) internal pure returns (uint) {
        require(_bytes.length >= 32);
        uint tempUint;

        assembly {
            tempUint := mload(add(_bytes, 0x20))
        }

        return tempUint;
    }
}