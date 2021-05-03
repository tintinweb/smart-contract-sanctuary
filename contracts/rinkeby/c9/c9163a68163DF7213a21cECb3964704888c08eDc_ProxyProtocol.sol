pragma solidity ^0.7.6;

import "../PErc20.sol";
import "../PEther.sol";
import "../Maximillion.sol";
import "../PTokenFactory.sol";
import "../PriceOracle.sol";
import "../SafeMath.sol";
import "../EIP20Interface.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

contract ProxyProtocol {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public admin;
    address public pendingAdmin;

    address public feeToken;
    address public feeRecipient;
    uint public feeAmountCreatePool;
    uint public feePercentMint;
    uint public feePercentRepayBorrow;

    address public pTokenFactory;
    UniswapPriceOracle public oracle;
    address payable public pETH;
    address payable public maximillion;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewFee(uint newFee);

    constructor(
        address pTokenFactory_,
        address payable pETH_,
        address payable maximillion_,
        address admin_,
        address feeToken_,
        address feeRecipient_,
        uint feeAmountCreatePool_,
        uint feePercentMint_,
        uint feePercentRepayBorrow_
    ) {
        pTokenFactory = pTokenFactory_;
        pETH = pETH_;
        maximillion = maximillion_;

        admin = admin_;
        feeToken = feeToken_;
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
        uint err = PTokenFactory(pTokenFactory).createPToken(underlying_);

        if (err == 0) {
            doTransferIn(msg.sender, feeRecipient, feeToken, feeAmountCreatePool);
        }

        return err;
    }

    /**
     * @notice Sender supplies assets into the market and receives pTokens in exchange
     * @param pToken The address of pToken
     * @param initMintAmount The amount of the underlying asset to supply
     */
    function mint(address pToken, uint initMintAmount) external returns (bool) {
        oracle.update(feeToken);
        uint fee = calcFee(feePercentMint, pToken, initMintAmount);
        doTransferIn(msg.sender, feeRecipient, feeToken, fee);

        address underlying = PErc20Interface(pToken).underlying();
        doTransferIn(msg.sender, address(this), underlying, initMintAmount);

        uint pTokenAmountBefore = EIP20Interface(pToken).balanceOf(address(this));

        uint mintAmount = EIP20Interface(underlying).balanceOf(address(this));
        mintAmount = mintAmount < initMintAmount ? mintAmount : initMintAmount;

        IERC20(underlying).approve(pToken, mintAmount);
        PErc20Interface(pToken).mint(mintAmount);

        uint pTokenAmountAfter = EIP20Interface(pToken).balanceOf(address(this));
        uint amount = pTokenAmountAfter.sub(pTokenAmountBefore);
        doTransferOut(pToken, msg.sender, amount);

        return true;
    }

    /**
     * @notice Sender repays their own borrow
     * @param pToken The address of pToken
     * @param repayAmount The amount to repay
     */
    function repayBorrow(address pToken, uint repayAmount) public returns (bool) {
        return repayBorrowBehalf(pToken, msg.sender, repayAmount);
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param pToken The address of pToken
     * @param borrower the account with the debt being payed off
     * @param initRepayAmount The amount to repay
     */
    function repayBorrowBehalf(address pToken, address borrower, uint initRepayAmount) public returns (bool) {
        uint feeAmount = initRepayAmount;

        address underlying = PErc20Interface(pToken).underlying();
        uint underlyingAmountBefore = IERC20(underlying).balanceOf(address(this));

        doTransferIn(msg.sender, address(this), underlying, initRepayAmount);

        uint repayAmount = EIP20Interface(underlying).balanceOf(address(this));
        repayAmount = repayAmount < initRepayAmount ? repayAmount : initRepayAmount;

        IERC20(underlying).approve(pToken, repayAmount);
        PErc20Interface(pToken).repayBorrowBehalf(borrower, repayAmount);

        uint underlyingAmountAfter = IERC20(underlying).balanceOf(address(this));

        if (underlyingAmountAfter > underlyingAmountBefore) {
            uint delta = underlyingAmountAfter.sub(underlyingAmountBefore);
            doTransferOut(underlying, msg.sender, delta);
            feeAmount = repayAmount.sub(delta);
        }

        oracle.update(feeToken);
        uint fee = calcFee(feePercentRepayBorrow, pToken, feeAmount);
        doTransferIn(msg.sender, feeRecipient, feeToken, fee);

        return true;
    }

    /*** ETH functions ***/

    /**
     * @notice Sender supplies assets into the market and receives pTokens in exchange
     * @dev Reverts upon any failure
     */
    function mint() external payable {
        oracle.update(feeToken);
        uint fee = calcFee(feePercentMint, pETH, msg.value);
        doTransferIn(msg.sender, feeRecipient, feeToken, fee);

        uint beforeBalance = EIP20Interface(pETH).balanceOf(address(this));

        PEther(pETH).mint{value: msg.value}();

        uint afterBalance = EIP20Interface(pETH).balanceOf(address(this));
        uint amount = afterBalance.sub(beforeBalance);
        doTransferOut(pETH, msg.sender, amount);
    }

    /**
     * @notice Sender repays their own borrow
     * @dev Reverts upon any failure
     */
    function repayBorrow() public payable {
        repayBorrowBehalf(msg.sender);
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @dev Reverts upon any failure
     * @param borrower the account with the debt being payed off
     */
    function repayBorrowBehalf(address borrower) public payable {
        uint fee;
        uint received = msg.value;

        uint borrows = getETHBorrows(borrower);

        oracle.update(feeToken);

        if (received > borrows) {
            fee = calcFee(feePercentRepayBorrow, pETH, borrows);

            msg.sender.transfer(received - borrows);
            Maximillion(maximillion).repayBehalf{value: borrows}(borrower);
        } else {
            fee = calcFee(feePercentRepayBorrow, pETH, received);

            Maximillion(maximillion).repayBehalf{value: received}(borrower);
        }

        doTransferIn(msg.sender, feeRecipient, feeToken, fee);
    }

    function getETHBorrows(address borrower) public returns (uint) {
        uint borrows = PEther(pETH).borrowBalanceCurrent(borrower);
        uint totalBorrows = PEther(pETH).totalBorrows();

        if (borrows > totalBorrows) {
            borrows = totalBorrows;
        }

        return borrows;
    }

    function calcFee(uint feePercent, address pToken, uint amount) public view returns (uint) {
        uint feeInUSD = oracle.getUnderlyingPrice(pToken).mul(amount).mul(feePercent).div(1e18);
        uint feeTokenPriceInUSD = oracle.getPriceInUSD(feeToken);
        uint power = EIP20Interface(feeToken).decimals();

        return calcFeeAmount(power, feeInUSD.div(feeTokenPriceInUSD));
    }

    function calcFeeAmount(uint power, uint amount) internal view returns (uint) {
        uint factor;

        if (18 >= power) {
            factor = 10**(18 - power);
            return amount.div(factor);
        } else {
            factor = 10**(power - 18);
            return amount.mul(factor);
        }
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

    function _setFeeToken(address newFeeToken) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'ProxyProtocol: Only admin can set fee token');

        // Store feeToken with value newFeeToken
        feeToken = newFeeToken;

        return true;
    }

    function _setFactory(address newFactory) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'ProxyProtocol: Only admin can set factory');

        // Store factory with value newFactory
        pTokenFactory = newFactory;

        return true;
    }

    function _setOracle(address newOracle) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'ProxyProtocol: Only admin can set oracle');

        // Store oracle with value newOracle
        oracle = UniswapPriceOracle(newOracle);

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
    function doTransferIn(address from, address to, address token, uint amount) internal {
        if (amount == 0) {
            return;
        }

        IERC20 ERC20Interface = IERC20(token);
        ERC20Interface.safeTransferFrom(from, to, amount);
    }

    function doTransferOut(address token, address to, uint amount) internal {
        if (amount == 0) {
            return;
        }

        IERC20 ERC20Interface = IERC20(token);
        ERC20Interface.safeTransfer(to, amount);
    }

    function withdraw(address token, address to) external {
        require(msg.sender == admin, "ProxyProtocol: Only admin can withdraw tokens from contract");

        IERC20 ERC20Interface = IERC20(token);
        uint amount = ERC20Interface.balanceOf(address(this));
        ERC20Interface.safeTransfer(to, amount);
    }

    function withdraw(address payable to) external {
        require(msg.sender == admin, "ProxyProtocol: Only admin can withdraw ether from contract");

        uint amount = address(this).balance;
        to.transfer(amount);
    }
}