// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OTCEngine.sol";


// Have fun reading it. Hopefully it's bug-free. God bless.
contract OTCEngineEventsWrapper is OTCEngine {

    event DealCreated(
        uint256 dealId,
        address sellerAccount,
        address indexed saleTokenAddress,
        address indexed wantedTokenAddress,
        uint256 saleBalance,
        uint256 wantedBalance,
        uint256 indexed lastUpdatedPriceE35,
        uint256 saleMinPercentage,
        uint256 saleMaxPercentage,
        uint256 saleMinAbsolute,
        uint256 saleMaxAbsolute
    );

    event DealPriceUpdated(
        uint256 indexed dealId,
        uint256 indexed wantedBalance,
        uint256 indexed lastUpdatedPriceE35
    );

    event DealConfigUpdated(
        uint256 indexed dealId,
        uint256 saleMinPercentage,
        uint256 saleMaxPercentage,
        uint256 indexed saleMinAbsolute,
        uint256 indexed saleMaxAbsolute
    );

    constructor(
        OTCHelper _otcHelper,
        PlushToolBox _plushToolBox
    ) public OTCEngine(
            _otcHelper,
            _plushToolBox
        ) {
    }

    function addDeal(address _saleTokenAddress, address _wantedTokenAddress, uint256 _saleBalance, uint256 _wantedBalance,
            uint256 _saleMinPercentage, uint256 saleMaxPercentage, uint256 _saleMinAbsolute, uint256 _saleMaxAbsolute) public override payable returns (uint256) {
        uint256 dealId = super.addDeal(_saleTokenAddress, _wantedTokenAddress, _saleBalance, _wantedBalance,
            _saleMinPercentage, saleMaxPercentage, _saleMinAbsolute, _saleMaxAbsolute);

        emit DealCreated(
            dealId,
            msg.sender,
            _saleTokenAddress,
            _wantedTokenAddress,
            globalDealInfos[dealId].saleBalance,
            _wantedBalance,
            globalDealInfos[dealId].lastUpdatedPriceE35,
            _saleMinPercentage,
            saleMaxPercentage,
            _saleMinAbsolute,
            _saleMaxAbsolute
        );

        return dealId;
    }

    function topUpDeal(uint256 dealId, uint256 _topUpAmout) public override payable {
        super.topUpDeal(dealId, _topUpAmout);

        emit DealBalancesChanged(
            dealId,
            globalDealInfos[dealId].saleBalance,
            globalDealInfos[dealId].wantedBalance
        );
    }

    function updateDealPrice(uint256 dealId, uint256 _newBuyPriceE35) public override {
        super.updateDealPrice(dealId, _newBuyPriceE35);

        emit DealPriceUpdated(dealId, globalDealInfos[dealId].wantedBalance, _newBuyPriceE35);
    }

    function updateDealConfig(uint256 dealId, uint256 _saleMinPercentage, uint256 saleMaxPercentage, uint256 _saleMinAbsolute, uint256 _saleMaxAbsolute) public override {
        super.updateDealConfig(dealId, _saleMinPercentage, saleMaxPercentage, _saleMinAbsolute, _saleMaxAbsolute);

        emit DealConfigUpdated(
            dealId,
            _saleMinPercentage,
            saleMaxPercentage,
            _saleMinAbsolute,
            _saleMaxAbsolute
        );
    }

    function removeDeal(uint256 dealId) public override {
        super.removeDeal(dealId);

        emit DealBalancesChanged(dealId, 0, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/IERC20.sol";
import "../libs/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./OTCHelper.sol";


// Have fun reading it. Hopefully it's bug-free. God bless.
contract OTCEngine is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // OTCs helpful assistant.
    OTCHelper public immutable otcHelper;

    // Plush's trusty utility belt.
    PlushToolBox public immutable plushToolBox;

    // BUSD Polygon (BNB) address
    address public constant busdCurrencyAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // default % fee is 0.24% = 24/10,000
    uint256 public depostFeeBP = 24;
    uint256 public bnbDealCreationFee = 0.001 ether;

    mapping(address => bool) public percFeeExemptMap;

    // All deals
    OTCHelper.DealInfo[] public globalDealInfos;

    event DealBalancesChanged(
        uint256 indexed dealId,
        uint256 indexed saleBalance,
        uint256 indexed wantedBalance
    );

    event DealExecuted(
        uint256 dealId,
        address indexed buyerAccount,
        uint256 indexed saleAmount,
        uint256 indexed buyingAmount
    );

    event SetPercFeeExemptMap(
        address indexed exemptAddress,
        bool isExempt
    );

    event SetDepositFeeBP(
        uint256 newDepositFeeBP
    );

    event SetBnbDealCreationFee(
        uint256 newBnbDealCreationFee
    );

    constructor(
        OTCHelper _otcHelper,
        PlushToolBox _plushToolBox
    ) public {
        otcHelper = _otcHelper;
        plushToolBox = _plushToolBox;
    }

    function getDealParams(uint256 dealId) external view returns (address, address, address, uint256, uint256, uint256) {
        return (
                globalDealInfos[dealId].sellerAccount,
                globalDealInfos[dealId].saleTokenAddress,
                globalDealInfos[dealId].wantedTokenAddress,
                globalDealInfos[dealId].saleBalance,
                globalDealInfos[dealId].wantedBalance,
                globalDealInfos[dealId].lastUpdatedPriceE35
            );
        }

    function getDealDelimiters(uint256 dealId) external view returns (uint256, uint256, uint256, uint256) {
        return (
                globalDealInfos[dealId].saleMinPercentage,
                globalDealInfos[dealId].saleMaxPercentage,
                globalDealInfos[dealId].saleMinAbsolute,
                globalDealInfos[dealId].saleMaxAbsolute
            );
    }

    function getGlobalDealsLength() external view returns (uint256) {
        return globalDealInfos.length;
    }

    function addDeal(address _saleTokenAddress, address _wantedTokenAddress, uint256 _saleBalance, uint256 _wantedBalance,
            uint256 _saleMinPercentage, uint256 _saleMaxPercentage, uint256 _saleMinAbsolute, uint256 _saleMaxAbsolute) public virtual payable nonReentrant returns (uint256) {
        // Make sure the provided tokens are somewhat compliant
        IERC20(_saleTokenAddress).balanceOf(address(this));
        IERC20(_wantedTokenAddress).balanceOf(address(this));
        // Deal validity checks
        require(_saleTokenAddress != _wantedTokenAddress, "invalid address");
        require(_saleBalance > 0 && _wantedBalance > 0 && _saleBalance <= 5e33 && _wantedBalance <= 5e33, "sale/wanted balance out of range");
        require(_saleMinPercentage <= 1e12 && _saleMaxPercentage <= 1e12 &&
                    _saleMinPercentage <= _saleMaxPercentage && _saleMinAbsolute <= _saleMaxAbsolute, "min/max out of range");

        IERC20 saleToken = IERC20(_saleTokenAddress);

        uint256 prevContractBalance = saleToken.balanceOf(address(this));

        saleToken.safeTransferFrom(msg.sender, address(this), _saleBalance);

        uint256 depositedAmount = (saleToken.balanceOf(address(this)) - prevContractBalance);

        //require(depositedAmount > 0 &&
        //            plushToolBox.getTokenBUSDValue(depositedAmount, _saleTokenAddress, 0, true, busdCurrencyAddress) >= 1 * 1e18 /* 1 busd minimum */,
        //                "deal too small");

        otcHelper.updateTokenBalances(_saleTokenAddress, true, depositedAmount);

        {
            require(msg.value >= bnbDealCreationFee, "not enough bnb provided");

            // we don't need to fail if this doesn't succeed, will be sent next time.
            payable(address(otcHelper)).call{value: address(this).balance}("");
        }

        globalDealInfos.push(OTCHelper.DealInfo({
            dealId: globalDealInfos.length,
            sellerAccount: msg.sender,
            saleTokenAddress: _saleTokenAddress,
            wantedTokenAddress: _wantedTokenAddress,
            saleBalance: depositedAmount,
            wantedBalance: _wantedBalance,
            lastUpdatedPriceE35: ((_wantedBalance * 1e35) / depositedAmount),
            saleMinPercentage: _saleMinPercentage,
            saleMaxPercentage: _saleMaxPercentage,
            saleMinAbsolute: _saleMinAbsolute,
            saleMaxAbsolute: _saleMaxAbsolute
        }));

        return globalDealInfos.length - 1;
    }

    function topUpDeal(uint256 dealId, uint256 _topUpAmout) public virtual payable nonReentrant {
        require(msg.sender == globalDealInfos[dealId].sellerAccount, "incorrect caller");
        require(msg.value >= bnbDealCreationFee, "not enough bnb provided");
        require(_topUpAmout > 0 && (globalDealInfos[dealId].saleBalance + _topUpAmout) <= 5e33, "topup out of range");

        IERC20 saleToken = IERC20(globalDealInfos[dealId].saleTokenAddress);

        uint256 prevContractBalance = saleToken.balanceOf(address(this));

        saleToken.safeTransferFrom(globalDealInfos[dealId].sellerAccount, address(this), _topUpAmout);

        uint256 depositedAmount = saleToken.balanceOf(address(this)) - prevContractBalance;

        otcHelper.updateTokenBalances(globalDealInfos[dealId].saleTokenAddress, true, depositedAmount);

        // Overflows are protected against by SafeMath
        // 35 decimal errors we are willing to accept.
        // max deal size is 5*10^33 so no loss in division
        uint256 wantedBalanceDelta = (depositedAmount * globalDealInfos[dealId].lastUpdatedPriceE35) / 1e35;

        require(wantedBalanceDelta > 0 &&
                    globalDealInfos[dealId].wantedBalance + wantedBalanceDelta <= 5e33,
                        "wanted balance out of range");

        globalDealInfos[dealId].saleBalance = (globalDealInfos[dealId].saleBalance + depositedAmount);
        globalDealInfos[dealId].wantedBalance = (globalDealInfos[dealId].wantedBalance + wantedBalanceDelta);
    }

    function updateDealPrice(uint256 dealId, uint256 _newBuyPriceE35) public virtual nonReentrant {
        require(msg.sender == globalDealInfos[dealId].sellerAccount, "incorrect caller");

        require(_newBuyPriceE35 < globalDealInfos[dealId].lastUpdatedPriceE35, "new buy price out of range");

        uint256 newWantedBalance = ((globalDealInfos[dealId].saleBalance * _newBuyPriceE35) / 1e35);
        require(newWantedBalance > 0 && newWantedBalance < globalDealInfos[dealId].wantedBalance, "new wanted balance out of range");

        globalDealInfos[dealId].wantedBalance = newWantedBalance;
        globalDealInfos[dealId].lastUpdatedPriceE35 = _newBuyPriceE35;
    }

    function updateDealConfig(uint256 dealId, uint256 _saleMinPercentage, uint256 saleMaxPercentage, uint256 _saleMinAbsolute, uint256 _saleMaxAbsolute) public virtual nonReentrant {
        require(msg.sender == globalDealInfos[dealId].sellerAccount, "incorrect caller");
        require(_saleMinPercentage <= 1e12 && _saleMinPercentage <= 1e12 &&
                    _saleMinPercentage <= saleMaxPercentage && _saleMinAbsolute <= _saleMaxAbsolute, "min/max out of range");

        globalDealInfos[dealId].saleMinPercentage = _saleMinPercentage;
        globalDealInfos[dealId].saleMaxPercentage = saleMaxPercentage;
        globalDealInfos[dealId].saleMinAbsolute = _saleMinAbsolute;
        globalDealInfos[dealId].saleMaxAbsolute = _saleMaxAbsolute;
    }

    function executeDealExactSaleAmount(uint256 dealId, uint256 saleAmount) public payable nonReentrant {
        require(msg.value >= (bnbDealCreationFee / 10), "not enough bnb provided");

        uint256 buyingAmount = otcHelper.getBuyingAmountFromSaleAmount(dealId, saleAmount);

        executeDeal(dealId, saleAmount, buyingAmount);
    }

    function executeDealExactBuyingAmount(uint256 dealId, uint256 buyingAmount) public payable nonReentrant {
        require(msg.value >= (bnbDealCreationFee / 10), "not enough bnb provided");
        require(buyingAmount <= globalDealInfos[dealId].wantedBalance, "not enough funds left in deal");

        uint256 saleAmount = otcHelper.getSaleAmountFromBuyingAmount(dealId, buyingAmount);

        executeDeal(dealId, saleAmount, buyingAmount);
    }

    function executeDeal(uint256 dealId, uint256 saleAmount, uint256 buyingAmount) internal virtual {
        address buyerAddress = msg.sender == address(otcHelper) ? otcHelper.multiBuyerCustomerAddress() : msg.sender;
        require(buyerAddress != globalDealInfos[dealId].sellerAccount, "can't buy your own deal");
        // Aready asserted saleBalance and wanted Balance and > 0 in OTCHelper.sol

        IERC20 saleToken = IERC20(globalDealInfos[dealId].saleTokenAddress);
        IERC20 wantedToken = IERC20(globalDealInfos[dealId].wantedTokenAddress);

        uint256 prevBuyerSaleTokenBalance = saleToken.balanceOf(buyerAddress);

        saleToken.safeTransfer(buyerAddress, saleAmount);

        require(saleToken.balanceOf(buyerAddress) > prevBuyerSaleTokenBalance, "no tokens to buyer");

        otcHelper.updateTokenBalances(globalDealInfos[dealId].saleTokenAddress, false, saleAmount);

        uint256 skim = saleToken.balanceOf(address(this)) - otcHelper.tokenBalances(globalDealInfos[dealId].saleTokenAddress);

        if (skim > 0)
            saleToken.safeTransfer(address(otcHelper), skim);

        uint256 buyerOTCFee = 0;
        // don't take a fee out of trades involving any exempt tokens.
        // fees are only ever taken out of the wanted tokens.
        if (depostFeeBP > 0 && !percFeeExemptMap[address(saleToken)] && !percFeeExemptMap[address(wantedToken)]) {
            buyerOTCFee = (buyingAmount * depostFeeBP) / 10000;

            // OTC fee comes out of the buyers payment/sellers revenue
            wantedToken.safeTransferFrom(buyerAddress, address(otcHelper), buyerOTCFee);

            otcHelper.swapToWETHAndDistribute(address(wantedToken));
        }

        uint256 prevSellerBalance = wantedToken.balanceOf(globalDealInfos[dealId].sellerAccount);

        // pay the seller minus our fee
        wantedToken.safeTransferFrom(buyerAddress, globalDealInfos[dealId].sellerAccount, buyingAmount - buyerOTCFee);

        require(wantedToken.balanceOf(globalDealInfos[dealId].sellerAccount) > prevSellerBalance, "no tokens sent to seller");

        otcHelper.updateUsernameIdMappings(dealId, buyerAddress, buyingAmount);

        globalDealInfos[dealId].wantedBalance = globalDealInfos[dealId].wantedBalance - buyingAmount;
        globalDealInfos[dealId].saleBalance = globalDealInfos[dealId].saleBalance - saleAmount;

        emit DealExecuted(dealId, buyerAddress, saleAmount, buyingAmount);
        emit DealBalancesChanged(
            dealId,
            globalDealInfos[dealId].saleBalance,
            globalDealInfos[dealId].wantedBalance
        );
    }

    function removeDeal(uint256 dealId) public virtual nonReentrant {
        require(msg.sender == globalDealInfos[dealId].sellerAccount, "incorrect caller");
        require(globalDealInfos[dealId].saleBalance > 0,"can't remove an empty deal");

        IERC20 saleToken = IERC20(globalDealInfos[dealId].saleTokenAddress);

        uint256 prevSaleBalance = saleToken.balanceOf(msg.sender);

        // Refunding seller.
        saleToken.safeTransfer(msg.sender, globalDealInfos[dealId].saleBalance);

        require((saleToken.balanceOf(msg.sender) - prevSaleBalance) > 0, "no tokens sent");

        // We do want to subtract by the recorded amount, not recieved.
        otcHelper.updateTokenBalances(globalDealInfos[dealId].saleTokenAddress, false, globalDealInfos[dealId].saleBalance);

        globalDealInfos[dealId].saleBalance = 0;
        globalDealInfos[dealId].wantedBalance = 0;
    }

    // To receive BNB from user for deal creation, top ups, and executions.
    receive() external payable {}

    // set a token to be fee free in OTC
    function setPercFeeExemptMap(address tokenAddress, bool isExempt) external nonReentrant onlyOwner {
        require(tokenAddress != address(0), "token address can't be 0!");
        percFeeExemptMap[tokenAddress] = isExempt;

        emit SetPercFeeExemptMap(tokenAddress, isExempt);
    }

    // Update the system deposit fee
    function setDepositfeeBP(uint256 _depostFeeBP) external nonReentrant onlyOwner {
        require(_depostFeeBP <= 40, "deposit fee can't be more than 0.4%");
        depostFeeBP = _depostFeeBP;

        emit SetDepositFeeBP(depostFeeBP);
    }

    // Update the bnb deal creation fee
    function setBnbDealCreationFee(uint256 _bnbDealCreationFee) external nonReentrant onlyOwner {
        require(_bnbDealCreationFee <= 0.02 ether, "bnb fee is max 0.02");
        bnbDealCreationFee = _bnbDealCreationFee;

        emit SetBnbDealCreationFee(bnbDealCreationFee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/IWETH.sol";
import "../libs/IERC20.sol";
import "../libs/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "../libs/PlushToolBox.sol";
import "./OTCEngine.sol";



// Have fun reading it. Hopefully it's bug-free. God bless.
contract OTCHelper is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // The OG OTC Mothership.
    OTCEngine public otcEngine;

    // The STB TOKEN!
    address public immutable STB;
    // The PLUSH TOKEN!
    address public immutable plush;
    // Plushs trusty toolbelt.
    PlushToolBox public immutable plushToolBox;

    // The swap router.
    IUniswapV2Router02 public immutable plushSwapRouter;

    // BUSD Polygon (BNB) address
    address public constant busdCurrencyAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // WBNB Polygon (BNB) address
    address public constant wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    // WBNB Polygon (BNB) IERC20 Token
    IERC20 public immutable wbnbToken;

    mapping(address => uint256) public tokenBalances;

    mapping(address => uint256) public userVolumeMap;

    // user gets a usernameId once they move 10busd.
    uint256 public constant usernameBUSDThreshold = 10 * (1e18);

    uint256 public usernameIdMapLength = 0;
    // IDs start at 1
    // 0 means no ID assigned yet, [NOVICE] status
    mapping(address => uint256) public usernameIdMap;

    event FeeSwappedToBnb(address indexed tokenFeeAddress, uint256 tokenQuantity, uint256 bnbRecieved);
    event UserTradingVolumeUpdated(address indexed userAddress, uint256 newTotalVolume);
    event UserNameGiven(address indexed userAddress, uint256 indexed usernameId);
    event FeeTokensRescued(address indexed tokenFeeAddress, address destinationAddress, uint256 tokenQuantity);
    event OTCEngineSet(address otcEngineAddress);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    struct DealInfo {
        uint256 dealId;
        address sellerAccount;
        address saleTokenAddress;
        address wantedTokenAddress;
        uint256 saleBalance;
        uint256 wantedBalance;
        uint256 lastUpdatedPriceE35;
        // 1 sale{Min,Max}Percentage is E10, E12 = 100%
        uint256 saleMinPercentage;
        uint256 saleMaxPercentage;
        uint256 saleMinAbsolute;
        uint256 saleMaxAbsolute;
    }

    // The operator can only update the transfer tax rate
    address public _operator;

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    constructor(
        address _STB,
        address _plush,
        PlushToolBox _plushToolBox,
        IUniswapV2Router02 _plushSwapRouter
    ) public {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        wbnbToken = IERC20(wbnbAddress);

        STB = _STB;
        plush = _plush;
        plushToolBox = _plushToolBox;
        plushSwapRouter = _plushSwapRouter;
    }

    function updateTokenBalances(address tokenAddress, bool isIncrement, uint256 delta) external onlyOwner {
        if (isIncrement)
            tokenBalances[tokenAddress] = tokenBalances[tokenAddress] + delta;
        else
            tokenBalances[tokenAddress] = tokenBalances[tokenAddress] - delta;
    }

    function swapToWETHAndDistribute(address token) external onlyOwner {
        uint256 bnbBalance = address(this).balance;
        // Wrapping native bnb for wbnb.
        if (bnbBalance > 0)
            IWETH(wbnbAddress).deposit{value:bnbBalance}();

        if (token != wbnbAddress) {
            uint256 amountToSwap = IERC20(token).balanceOf(address(this));

            if (amountToSwap > 0) {
                uint256 wbnbBeforeBalance = wbnbToken.balanceOf(address(this));

                // generate the plushSwap pair path of token -> busd.
                address[] memory path = new address[](2);
                path[0] = token;
                path[1] = wbnbAddress;

                IERC20(token).approve(address(plushSwapRouter), amountToSwap);

                // put in a try catch in case a bnb pair doesn't exist for the token yet.
                try
                    // make the swap
                    plushSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        amountToSwap,
                        0, // accept any amount of wbnb
                        path,
                        address(this),
                        block.timestamp
                    )
                {
                    /* suceeded */
                    emit FeeSwappedToBnb(token, amountToSwap, wbnbToken.balanceOf(address(this)) - wbnbBeforeBalance);
                } catch { /* failed, but we avoided reverting */ }
            }
        }

        uint256 wbnbProfit = wbnbToken.balanceOf(address(this));

        if (wbnbProfit >= 10 ** 14) {
            uint256 STBFee = wbnbProfit / 2;
            wbnbToken.transfer(address(STB), STBFee);
            wbnbToken.transfer(address(plush), wbnbProfit - STBFee);
        }
    }

    function verifyDealDelimiters(uint256 dealId, uint256 saleAmount) internal view {
        (, , ,
            uint256 saleBalance, , ) = otcEngine.getDealParams(dealId);
        (uint256 saleMinPercentage, uint256 saleMaxPercentage,
            uint256 saleMinAbsolute, uint256 saleMaxAbsolute) = otcEngine.getDealDelimiters(dealId);
        require(saleAmount > 0 && saleAmount <= saleBalance &&
            saleAmount >= ((saleBalance * saleMinPercentage) / 1e12) &&
                saleAmount <= ((saleBalance * saleMaxPercentage) / 1e12) &&
                    saleAmount >= saleMinAbsolute &&
                        saleAmount <= saleMaxAbsolute,
                            "calculated sale amount outside allowed range");
    }

    function getSaleAmountFromBuyingAmount(uint256 dealId, uint256 buyingAmount) external view returns (uint256) {
        (, , ,
            uint256 saleBalance, uint256 wantedBalance, uint256 lastUpdatedPriceE35 ) = otcEngine.getDealParams(dealId);

        require(buyingAmount <= wantedBalance, "buying amount greater than wanted balance");
        require(buyingAmount > 0 && saleBalance > 0 && wantedBalance > 0,
                    "buying amount/sale/wanted balance is 0");

        // Overflows are protected against by SafeMath
        // 35 decimal errors we are willing to accept.
        // max deal size is 5*10^33 so minimal loss on division
        uint256 saleAmount;

        // If the full wanted amount is offered, the sale amount is given.
        if (wantedBalance == buyingAmount)
            saleAmount = saleBalance;
        else {
            uint256 wantedBalanceByPrice = (saleBalance * lastUpdatedPriceE35) / 1e35;
            require(wantedBalanceByPrice > 0, "intermediate balance too low");
            saleAmount = (buyingAmount * 1e35) / lastUpdatedPriceE35;
        }

        verifyDealDelimiters(dealId, saleAmount);

        return saleAmount;
    }

    function getBuyingAmountFromSaleAmount(uint256 dealId, uint256 saleAmount) external view returns (uint256) {
        verifyDealDelimiters(dealId, saleAmount);
        (, , , uint256 saleBalance, uint256 wantedBalance, uint256 lastUpdatedPriceE35 ) = otcEngine.getDealParams(dealId);

        require(saleBalance > 0 && wantedBalance > 0, "sale/wanted balance is 0");

        // Overflows are protected against by SafeMath
        // 35 decimal errors we are willing to accept.
        // max deal size is 5*10^33 so minimal loss on division
        uint256 buyingAmount;

        // If the full sale amount requested, the full wanted amount is necessary.
        if (saleBalance == saleAmount)
            buyingAmount = wantedBalance;
        else
            buyingAmount = (saleAmount * lastUpdatedPriceE35) / 1e35;

        require(buyingAmount > 0, "calculated buying amount is 0, perhaps you are buying too little");

        require(buyingAmount <= wantedBalance, "insufficient funds left in deal");

        return buyingAmount;
    }

    function updateUsernameIdMappings(uint256 dealId, address buyerAccount, uint256 buyingAmount) external onlyOwner {
        (address sellerAccount, , address wantedTokenAddress, , ,) = otcEngine.getDealParams(dealId);

        uint256 busdTradeValue = plushToolBox.getTokenBUSDValue(buyingAmount, wantedTokenAddress, 0, true, busdCurrencyAddress);

        userVolumeMap[sellerAccount] = userVolumeMap[sellerAccount] + busdTradeValue;
        userVolumeMap[buyerAccount] = userVolumeMap[buyerAccount] + busdTradeValue;

        emit UserTradingVolumeUpdated(sellerAccount, userVolumeMap[sellerAccount]);
        emit UserTradingVolumeUpdated(buyerAccount, userVolumeMap[buyerAccount]);

        if (usernameIdMap[sellerAccount] == 0 && userVolumeMap[sellerAccount] > usernameBUSDThreshold) {
            usernameIdMapLength = usernameIdMapLength + 1;
            usernameIdMap[sellerAccount] = usernameIdMapLength;

            emit UserNameGiven(sellerAccount, usernameIdMap[sellerAccount]);
        }

        if (usernameIdMap[buyerAccount] == 0 && userVolumeMap[buyerAccount] > usernameBUSDThreshold) {
            usernameIdMapLength = usernameIdMapLength + 1;
            usernameIdMap[buyerAccount] = usernameIdMapLength;

            emit UserNameGiven(buyerAccount, usernameIdMap[buyerAccount]);
        }
    }

    /// MULTI-BUY HELPER CODE

    event PartialMultiBuyByWantedToken(uint256 indexed dealId, uint256 indexed multiBuyIndex, address indexed buyerAccount, uint256 wantedAmount);
    event PartialMultiBuyBySaleToken(uint256 indexed dealId, uint256 indexed multiBuyIndex, address indexed buyerAccount, uint256 saleAmount);
    event MultiBuyComplete(uint256 numberOfDealsRequested, uint256 numberOfDealsCompleted);

    address public multiBuyerCustomerAddress;

    modifier buyerAddressProvider(address _buyerAddress) {
        multiBuyerCustomerAddress = _buyerAddress;
        _;
        multiBuyerCustomerAddress = address(0);
    }

    function multiBuy(uint256[] calldata dealIds, uint256[] calldata amounts, bool isByWantedTokenAmounts, bool persistOnFail) external payable nonReentrant buyerAddressProvider(msg.sender) {
        uint256 bnbExecutionPrice = otcEngine.bnbDealCreationFee()/10;
        // We only require enough bnb for 1 deal excution, as a buyer may want to try more deals than they have gas for.
        require(msg.value >= bnbExecutionPrice, "not enough bnb for even 1 deal execution!");
        require(dealIds.length > 0, "no deals requests");
        require(dealIds.length == amounts.length, "unequal array lengths");

        uint256 initialBnbBeforeUser = address(this).balance - msg.value;

        uint256 numberOfSucceededBuys = 0;

        for (uint256 i = 0;i<dealIds.length;i++) {
            uint256 dealId = dealIds[i];

            if (isByWantedTokenAmounts) {
                uint256 buyingAmount = amounts[i];

                try
                    otcEngine.executeDealExactBuyingAmount{value: bnbExecutionPrice}(dealId, buyingAmount)
                {
                    numberOfSucceededBuys = numberOfSucceededBuys + 1;
                    emit PartialMultiBuyByWantedToken(dealId, i, msg.sender, buyingAmount);
                } catch {
                    require(persistOnFail, "multi-buy failed!");
                }
            } else {
                uint256 saleAmount = amounts[i];
                try
                    otcEngine.executeDealExactSaleAmount{value: bnbExecutionPrice}(dealId, saleAmount)
                {
                    numberOfSucceededBuys = numberOfSucceededBuys + 1;
                    emit PartialMultiBuyBySaleToken(dealId, i, msg.sender, saleAmount);
                } catch {
                    require(persistOnFail, "multi-buy failed!");
                }
            }

            if (address(this).balance < initialBnbBeforeUser + bnbExecutionPrice)
                break;
        }

        require(numberOfSucceededBuys > 0, "no buys completed!");

        emit MultiBuyComplete(dealIds.length, numberOfSucceededBuys);

        // Refunding any unused gas. No need to check the return status of the bnb refund at the cost of the whole multi-buy.
        if (address(this).balance > initialBnbBeforeUser)
            payable(msg.sender).call{value: address(this).balance - initialBnbBeforeUser}("");
    }

    // Fetch tokens we can't take fees from automatically, no bnb pair, is an LP token etc...
    function fetchFeeTokens(address feeTokenAddress, address destinationAddress, uint256 quantity) external nonReentrant onlyOperator {
        require(address(feeTokenAddress) != address(0), "bad token address");
        IERC20(feeTokenAddress).safeTransfer(destinationAddress, quantity);

        emit FeeTokensRescued(feeTokenAddress, destinationAddress, quantity);
    }

    // To receive BNB from plushSwapRouter when swapping
    receive() external payable {}

    // Update the otc engine contract address by the owner
    function setOTCEngine(address _otcEngine) external nonReentrant onlyOwner {
        require(address(otcEngine) == address(0), "can only assign OTC engine once");
        otcEngine = OTCEngine(payable(_otcEngine));

        emit OTCEngineSet(_otcEngine);
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) external nonReentrant onlyOperator {
        require(newOperator != address(0), "transferOperator: new operator is the zero address");

        emit OperatorTransferred(_operator, newOperator);

        _operator = newOperator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


contract PlushToolBox {

    IUniswapV2Router02 public immutable plushSwapRouter;

    uint256 public immutable startBlock;

    /**
     * @notice Constructs the PlushToken contract.
     */
    constructor(uint256 _startBlock, IUniswapV2Router02 _plushSwapRouter) public {
        startBlock = _startBlock;
        plushSwapRouter = _plushSwapRouter;
    }

    function convertToTargetValueFromPair(IUniswapV2Pair pair, uint256 sourceTokenAmount, address targetAddress) public view returns (uint256) {
        require(pair.token0() == targetAddress || pair.token1() == targetAddress, "one of the pairs must be the targetAddress");
        if (sourceTokenAmount == 0)
            return 0;

        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (res0 == 0 || res1 == 0)
            return 0;

        if (pair.token0() == targetAddress)
            return (res0 * sourceTokenAmount) / res1;
        else
            return (res1 * sourceTokenAmount) / res0;
    }

    function getTokenBUSDValue(uint256 tokenBalance, address token, uint256 tokenType, bool viaBnbBUSD, address busdAddress) external view returns (uint256) {
        require(tokenType == 0 || tokenType == 1, "invalid token type provided");
        if (token == address(busdAddress))
            return tokenBalance;

        // lp type
        if (tokenType == 1) {
            IUniswapV2Pair lpToken = IUniswapV2Pair(token);
            if (lpToken.totalSupply() == 0)
                return 0;
            // If lp contains busd, we can take a short-cut
            if (lpToken.token0() == address(busdAddress)) {
                return (IERC20(lpToken.token0()).balanceOf(address(lpToken)) * tokenBalance * 2) / lpToken.totalSupply();
            } else if (lpToken.token1() == address(busdAddress)){
                return (IERC20(lpToken.token1()).balanceOf(address(lpToken)) * tokenBalance * 2) / lpToken.totalSupply();
            }
        }

        // Only used for lp type tokens.
        address lpTokenAddress = token;
        // If token0 or token1 is bnb, use that, else use token0.
        if (tokenType == 1) {
            token = IUniswapV2Pair(token).token0() == plushSwapRouter.WETH() ? plushSwapRouter.WETH() :
                        (IUniswapV2Pair(token).token1() == plushSwapRouter.WETH() ? plushSwapRouter.WETH() : IUniswapV2Pair(token).token0());
        }

        // if it is an LP token we work with all of the reserve in the LP address to scale down later.
        uint256 tokenAmount = (tokenType == 1) ? IERC20(token).balanceOf(lpTokenAddress) : tokenBalance;

        uint256 busdEquivalentAmount = 0;

        if (viaBnbBUSD) {
            uint256 bnbAmount = 0;

            if (token == plushSwapRouter.WETH()) {
                bnbAmount = tokenAmount;
            } else {

                // As we arent working with busd at this point (early return), this is okay.
                IUniswapV2Pair bnbPair = IUniswapV2Pair(IUniswapV2Factory(plushSwapRouter.factory()).getPair(plushSwapRouter.WETH(), token));

                if (address(bnbPair) == address(0))
                    return 0;

                bnbAmount = convertToTargetValueFromPair(bnbPair, tokenAmount, plushSwapRouter.WETH());
            }

            // As we arent working with busd at this point (early return), this is okay.
            IUniswapV2Pair busdbnbPair = IUniswapV2Pair(IUniswapV2Factory(plushSwapRouter.factory()).getPair(plushSwapRouter.WETH(), address(busdAddress)));

            if (address(busdbnbPair) == address(0))
                return 0;

            busdEquivalentAmount = convertToTargetValueFromPair(busdbnbPair, bnbAmount, busdAddress);
        } else {
            // As we arent working with busd at this point (early return), this is okay.
            IUniswapV2Pair busdPair = IUniswapV2Pair(IUniswapV2Factory(plushSwapRouter.factory()).getPair(address(busdAddress), token));

            if (address(busdPair) == address(0))
                return 0;

            busdEquivalentAmount = convertToTargetValueFromPair(busdPair, tokenAmount, busdAddress);
        }

        // for the tokenType == 1 path busdEquivalentAmount is the BUSD value of all the tokens in the parent LP contract.

        if (tokenType == 1)
            return (busdEquivalentAmount * tokenBalance * 2) / IUniswapV2Pair(lpTokenAddress).totalSupply();
        else
            return busdEquivalentAmount;
    }

    function getNumberOfHalvingsSinceStart(uint256 STBReleaseHalfLife, uint256 _to) public view returns (uint256) {
        if (_to <= startBlock)
            return 0;

        return (_to - startBlock) / STBReleaseHalfLife;
    }

    function getPreviousSTBHalvingBlock(uint256 STBReleaseHalfLife, uint256 _block) public view  returns (uint256) {
        // won't revert from getSTBRelease due to bounds check
        require(_block >= startBlock, "can't get previous STB halving before startBlock");

        uint256 numberOfHalvings = getNumberOfHalvingsSinceStart(STBReleaseHalfLife, _block);
        return numberOfHalvings * STBReleaseHalfLife + startBlock;
    }

    function getNextSTBHalvingBlock(uint256 STBReleaseHalfLife, uint256 _block) public view  returns (uint256) {
        // won't revert from getSTBRelease due to bounds check
        require(_block >= startBlock, "can't get previous STB halving before startBlock");

        uint256 numberOfHalvings = getNumberOfHalvingsSinceStart(STBReleaseHalfLife, _block);

        if ((_block - startBlock) % STBReleaseHalfLife == 0)
            return numberOfHalvings * STBReleaseHalfLife + startBlock;
        else
            return (numberOfHalvings + 1) * STBReleaseHalfLife + startBlock;
    }

    function getSTBReleaseForBlockE24(uint256 initialSTBReleaseRate, uint256 STBReleaseHalfLife, uint256 _block) public view  returns (uint256) {
        if (_block < startBlock)
            return 0;

        uint256 numberOfHalvings = getNumberOfHalvingsSinceStart(STBReleaseHalfLife, _block);
        return (initialSTBReleaseRate * 1e24) / (2 ** numberOfHalvings);
    }

    // Return STB reward release over the given _from to _to block.
    function getSTBRelease(uint256 initialSTBReleaseRate, uint256 STBReleaseHalfLife, uint256 _from, uint256 _to) external view returns (uint256) {
        if (_from < startBlock || _to <= _from)
            return 0;

        uint256 releaseDuration = _to - _from;

        uint256 startReleaseE24 = getSTBReleaseForBlockE24(initialSTBReleaseRate, STBReleaseHalfLife, _from);
        uint256 endReleaseE24 = getSTBReleaseForBlockE24(initialSTBReleaseRate, STBReleaseHalfLife, _to);

        // If we are all in the same era its a rectangle problem
        if (startReleaseE24 == endReleaseE24)
            return (endReleaseE24 * releaseDuration) / 1e24;

        // The idea here is that if we span multiple halving eras, we can use triangle geometry to take an average.
        uint256 startSkipBlock = getNextSTBHalvingBlock(STBReleaseHalfLife, _from);
        uint256 endSkipBlock = getPreviousSTBHalvingBlock(STBReleaseHalfLife, _to);

        // In this case we do span multiple eras (at least 1 complete half-life era)
        if (startSkipBlock != endSkipBlock) {
            uint256 numberOfCompleteHalfLifes = getNumberOfHalvingsSinceStart(STBReleaseHalfLife, endSkipBlock) - getNumberOfHalvingsSinceStart(STBReleaseHalfLife, startSkipBlock);
            uint256 partialEndsRelease = startReleaseE24 * (startSkipBlock - _from) + (endReleaseE24 * (_to - endSkipBlock));
            uint256 wholeMiddleRelease = (endReleaseE24 * 2 * STBReleaseHalfLife) * ((2 ** numberOfCompleteHalfLifes) - 1);
            return (partialEndsRelease + wholeMiddleRelease) / 1e24;
        }

        // In this case we just span across 2 adjacent eras
        return ((endReleaseE24 * releaseDuration) + (startReleaseE24 - endReleaseE24) * (startSkipBlock - _from)) / 1e24;
    }

    function getPlushEmissionForBlock(uint256 _block, bool isIncreasingGradient, uint256 releaseGradient, uint256 gradientEndBlock, uint256 endEmission) public pure returns (uint256) {
        if (_block >= gradientEndBlock)
            return endEmission;

        if (releaseGradient == 0)
            return endEmission;
        uint256 currentPlushEmission = endEmission;
        uint256 deltaHeight = (releaseGradient * (gradientEndBlock - _block)) / 1e24;

        if (isIncreasingGradient) {
            // if there is a logical error, we return 0
            if (endEmission >= deltaHeight)
                currentPlushEmission = endEmission - deltaHeight;
            else
                currentPlushEmission = 0;
        } else
            currentPlushEmission = endEmission + deltaHeight;

        return currentPlushEmission;
    }

    function calcEmissionGradient(uint256 _block, uint256 currentEmission, uint256 gradientEndBlock, uint256 endEmission) external pure returns (uint256) {
        uint256 plushReleaseGradient;

        // if the gradient is 0 we interpret that as an unchanging 0 gradient.
        if (currentEmission != endEmission && _block < gradientEndBlock) {
            bool isIncreasingGradient = endEmission > currentEmission;
            if (isIncreasingGradient)
                plushReleaseGradient = ((endEmission - currentEmission) * 1e24) / (gradientEndBlock - _block);
            else
                plushReleaseGradient = ((currentEmission - endEmission) * 1e24) / (gradientEndBlock - _block);
        } else
            plushReleaseGradient = 0;

        return plushReleaseGradient;
    }

    // Return if we are in the normal operation era, no promo
    function isFlatEmission(uint256 _gradientEndBlock, uint256 _blocknum) internal pure returns (bool) {
        return _blocknum >= _gradientEndBlock;
    }

    // Return PLUSH reward release over the given _from to _to block.
    function getPlushRelease(bool isIncreasingGradient, uint256 releaseGradient, uint256 gradientEndBlock, uint256 endEmission, uint256 _from, uint256 _to) external view returns (uint256) {
        if (_to <= _from || _to <= startBlock)
            return 0;
        uint256 clippedFrom = _from < startBlock ? startBlock : _from;
        uint256 totalWidth = _to - clippedFrom;

        if (releaseGradient == 0 || isFlatEmission(gradientEndBlock, clippedFrom))
            return totalWidth * endEmission;

        if (!isFlatEmission(gradientEndBlock, _to)) {
            uint256 heightDelta = releaseGradient * totalWidth;

            uint256 baseEmission;
            if (isIncreasingGradient)
                baseEmission = getPlushEmissionForBlock(clippedFrom, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);
            else
                baseEmission = getPlushEmissionForBlock(_to, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);
            return totalWidth * baseEmission + (((totalWidth * heightDelta) / 2) / 1e24);
        }

        // Special case when we are transitioning between promo and normal era.
        if (!isFlatEmission(gradientEndBlock, clippedFrom) && isFlatEmission(gradientEndBlock, _to)) {
            uint256 blocksUntilGradientEnd = gradientEndBlock - clippedFrom;
            uint256 heightDelta = releaseGradient * blocksUntilGradientEnd;

            uint256 baseEmission;
            if (isIncreasingGradient)
                baseEmission = getPlushEmissionForBlock(_to, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);
            else
                baseEmission = getPlushEmissionForBlock(clippedFrom, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);

            return totalWidth * baseEmission - (((blocksUntilGradientEnd * heightDelta) / 2) / 1e24);
        }

        // huh?
        // shouldnt happen, but also don't want to assert false here either.
        return 0;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

