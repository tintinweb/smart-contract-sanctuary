/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ICapitalPool} from "./ICapitalPool.sol";
import {IPremiumPool} from "./IPremiumPool.sol";
import {IStakersPoolV2} from "../pool/IStakersPoolV2.sol";
import {SecurityMatrix} from "../secmatrix/SecurityMatrix.sol";
import {Constant} from "../common/Constant.sol";
import {Math} from "../common/Math.sol";
import {IExchangeRate} from "../exchange/IExchangeRate.sol";

contract CapitalPool is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, ICapitalPool {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function initializeCapitalPool() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    address public securityMatrix;

    // stakers V2 _token and misc
    address[] public stakersTokenData;
    mapping(address => uint256) public stakersTokenDataMap;
    address public stakersPoolV2;

    // fee pool
    address public feePoolAddress;

    // premium pool
    address public premiumPoolAddress;
    uint256 public premiumPayoutRatioX10000;

    // claim payout address
    address public claimToSettlementPool;

    // product cover pool tokens
    address[] public productCoverTokens;
    mapping(address => uint256) public productCoverTokensMap;
    uint256[] public productList;
    mapping(uint256 => uint256) public productListMap;
    // product id -> token -> cover amount
    mapping(uint256 => mapping(address => uint256)) public coverAmtPPPT;

    uint256 public coverAmtPPMaxRatio;
    uint256 public constant COVERAMT_PPMAX_RATIOBASE = 10000;

    // capital wise
    uint256 public scr;
    address public scrToken;
    mapping(address => uint256) public deltaCoverAmt; // should be reset when updating scr value
    uint256 public cap2CapacityRatio;
    uint256 public constant CAP2CAPACITY_RATIOBASE = 10000;
    address public baseToken;
    uint256 public mt;

    // token -> last expired amount update timestamp
    mapping(address => uint256) public tokenExpCvAmtUpdTimestampMap;

    // exchange rate
    address public exchangeRate;

    modifier allowedCaller() {
        require((SecurityMatrix(securityMatrix).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    function setup(
        address _securityMatrix,
        address _feePoolAddress,
        address _premiumPoolAddress,
        address _claimToSettlementPool,
        address _stakersPoolV2,
        address _exchangeRate
    ) external onlyOwner {
        require(_securityMatrix != address(0), "S:1");
        require(_feePoolAddress != address(0), "S:2");
        require(_premiumPoolAddress != address(0), "S:3");
        require(_claimToSettlementPool != address(0), "S:4");
        require(_stakersPoolV2 != address(0), "S:5");
        require(_exchangeRate != address(0), "S:6");
        securityMatrix = _securityMatrix;
        baseToken = Constant.BCNATIVETOKENADDRESS;
        scrToken = Constant.BCNATIVETOKENADDRESS;
        feePoolAddress = _feePoolAddress;
        premiumPoolAddress = _premiumPoolAddress;
        claimToSettlementPool = _claimToSettlementPool;
        stakersPoolV2 = _stakersPoolV2;
        exchangeRate = _exchangeRate;
    }

    function setData(uint256 _coverAmtPPMaxRatio, uint256 _premiumPayoutRatioX10000) external allowedCaller {
        coverAmtPPMaxRatio = _coverAmtPPMaxRatio;
        premiumPayoutRatioX10000 = _premiumPayoutRatioX10000;
    }

    event UpdateCap2CapacityRatioEvent(uint256 _cap2CapacityRatio);

    function updateCap2CapacityRatio(uint256 _cap2CapacityRatio) external allowedCaller {
        require(_cap2CapacityRatio > 0, "UPDC2CR:1");
        cap2CapacityRatio = _cap2CapacityRatio;

        emit UpdateCap2CapacityRatioEvent(_cap2CapacityRatio);
    }

    event UpdateMTEvent(address indexed _mtToken, uint256 _mtAmount);

    function updateMT(address _mtToken, uint256 _mtAmount) external allowedCaller {
        require(_mtToken == baseToken, "UPDMT:1");
        require(_mtAmount > 0, "UPDMT:2");
        mt = _mtAmount;

        emit UpdateMTEvent(_mtToken, _mtAmount);
    }

    event UpdateSCREvent(address indexed _scrToken, uint256 _scrAmount);

    function updateSCR(
        address _scrToken,
        uint256 _scrAmount,
        address[] memory _tokens,
        uint256[] memory _offsetAmounts
    ) external allowedCaller {
        require(_scrToken != address(0), "UPDSCR:1");
        require(_scrAmount > 0, "UPDSCR:2");
        require(_tokens.length == _offsetAmounts.length, "UPDSCR:3");

        scrToken = _scrToken;
        scr = _scrAmount;

        for (uint256 index = 0; index < _tokens.length; index++) {
            deltaCoverAmt[_tokens[index]] = deltaCoverAmt[_tokens[index]].sub(_offsetAmounts[index]);
        }

        emit UpdateSCREvent(_scrToken, _scrAmount);
    }

    event UpdateExpiredCoverAmountEvent(address indexed _token, uint256 _updateTimestamp, uint256 _productId, uint256 _amount);

    function updateExpiredCoverAmount(
        address _token,
        uint256 _updateTimestamp,
        uint256[] memory _products,
        uint256[] memory _amounts
    ) external allowedCaller {
        require(_token != address(0), "UPDECAMT:1");
        require(_products.length > 0, "UPDECAMT:2");
        require(_products.length == _amounts.length, "UPDECAMT:3");
        require(_updateTimestamp > tokenExpCvAmtUpdTimestampMap[_token], "UPDECAMT:4");

        tokenExpCvAmtUpdTimestampMap[_token] = _updateTimestamp;

        for (uint256 index = 0; index < _products.length; index++) {
            uint256 productId = _products[index];
            uint256 expiredAmount = _amounts[index];
            coverAmtPPPT[productId][_token] = coverAmtPPPT[productId][_token].sub(expiredAmount);

            emit UpdateExpiredCoverAmountEvent(_token, _updateTimestamp, productId, expiredAmount);
        }
    }

    function hasTokenInStakersPool(address _token) external view override returns (bool) {
        return stakersTokenDataMap[_token] == 1;
    }

    function addStakersPoolData(address _token) external onlyOwner {
        require(_token != address(0), "ASPD:1");
        require(stakersTokenDataMap[_token] != 1, "ASPD:2");
        stakersTokenDataMap[_token] = 1;
        stakersTokenData.push(_token);
    }

    function removeStakersPoolDataByIndex(uint256 _index) external onlyOwner {
        require(stakersTokenData.length > _index, "RSPDBI:1");
        address token = stakersTokenData[_index];
        delete stakersTokenDataMap[token];
        if (_index != stakersTokenData.length - 1) {
            stakersTokenData[_index] = stakersTokenData[stakersTokenData.length - 1];
        }
        stakersTokenData.pop();
    }

    function _getTokenToBase(address _tokenFrom, uint256 _amount) private view returns (uint256) {
        if (_tokenFrom == baseToken || _amount == 0) {
            return _amount;
        }
        return IExchangeRate(exchangeRate).getTokenToTokenAmount(_tokenFrom, baseToken, _amount);
    }

    function getStakingPercentageX10000() external view override returns (uint256) {
        uint256 nst = _getCapInBaseToken();
        return nst.mul(10**4).div(mt);
    }

    function getTVLinBaseToken() external view override returns (uint256) {
        return _getCapInBaseToken();
    }

    function _getCapInBaseToken() private view returns (uint256) {
        uint256 retVinBase = 0;

        uint256 poolLength = stakersTokenData.length;
        for (uint256 poolLengthIndex = 0; poolLengthIndex < poolLength; poolLengthIndex++) {
            address token = stakersTokenData[poolLengthIndex];
            retVinBase = retVinBase.add(_getTokenToBase(token, IStakersPoolV2(stakersPoolV2).getStakedAmountPT(token)));
        }

        return retVinBase;
    }

    function _getDeltaCoverAmtInBaseToken() private view returns (uint256) {
        uint256 retVinBase = 0;
        for (uint256 tokenIndex = 0; tokenIndex < productCoverTokens.length; tokenIndex++) {
            address token = productCoverTokens[tokenIndex];
            uint256 temp = _getTokenToBase(token, deltaCoverAmt[token]);
            retVinBase = retVinBase.add(temp);
        }
        return retVinBase;
    }

    function getCapacityInfo() external view override returns (uint256, uint256) {
        return _getFreeCapacity();
    }

    function getProductCapacityInfo(uint256[] memory _products) external view returns (uint256, uint256[] memory) {
        (uint256 freeCapacity, uint256 totalCapacity) = _getFreeCapacity();
        uint256 maxCapacityOfOneProduct = Math.min(totalCapacity.mul(coverAmtPPMaxRatio).div(COVERAMT_PPMAX_RATIOBASE), freeCapacity);

        uint256[] memory usedCapacityOfProducts = new uint256[](_products.length);
        for (uint256 index = 0; index < _products.length; ++index) {
            usedCapacityOfProducts[index] = _getCoverAmtPPInBaseToken(_products[index]);
        }

        return (maxCapacityOfOneProduct, usedCapacityOfProducts);
    }

    function _getFreeCapacity() private view returns (uint256, uint256) {
        // capital
        uint256 capitalInBaseToken = _getCapInBaseToken();
        // - scr
        uint256 srcInBT = _getTokenToBase(scrToken, scr);
        uint256 deltaCoverAmtT = _getDeltaCoverAmtInBaseToken();
        if (capitalInBaseToken <= srcInBT.add(deltaCoverAmtT)) {
            return (0, srcInBT.add(deltaCoverAmtT));
        }
        uint256 capInBaseTokenAftSCR = capitalInBaseToken.sub(srcInBT);
        uint256 baseTokenFreeCapacityAftSCR = capInBaseTokenAftSCR.mul(cap2CapacityRatio).div(CAP2CAPACITY_RATIOBASE);
        return (baseTokenFreeCapacityAftSCR.sub(deltaCoverAmtT), baseTokenFreeCapacityAftSCR.add(srcInBT));
    }

    function getBaseToken() external view override returns (address) {
        return baseToken;
    }

    function getCoverAmtPPMaxRatio() external view override returns (uint256) {
        return coverAmtPPMaxRatio;
    }

    function getCoverAmtPPInBaseToken(uint256 _productId) external view override returns (uint256) {
        return _getCoverAmtPPInBaseToken(_productId);
    }

    function _getCoverAmtPPInBaseToken(uint256 _productId) private view returns (uint256) {
        uint256 retVinBase = 0;
        for (uint256 tokenIndex = 0; tokenIndex < productCoverTokens.length; tokenIndex++) {
            address token = productCoverTokens[tokenIndex];
            uint256 temp = _getTokenToBase(token, coverAmtPPPT[_productId][token]);
            retVinBase = retVinBase.add(temp);
        }
        return retVinBase;
    }

    function canBuyCoverPerProduct(
        uint256 _productId,
        uint256 _amount,
        address _token
    ) external view override returns (bool) {
        uint256 coverAmtPPinBaseToken = _getCoverAmtPPInBaseToken(_productId);

        uint256 buyCurrencyAmtinBaseToken = _getTokenToBase(_token, _amount);

        (uint256 btFreeCapacity, uint256 btTotalCapacity) = _getFreeCapacity();
        if (buyCurrencyAmtinBaseToken.add(coverAmtPPinBaseToken) > btTotalCapacity.mul(coverAmtPPMaxRatio).div(COVERAMT_PPMAX_RATIOBASE)) {
            return false;
        }
        if (buyCurrencyAmtinBaseToken > btFreeCapacity) {
            return false;
        }
        return true;
    }

    function canBuyCover(uint256 _amount, address _token) external view override returns (bool) {
        uint256 buyCurrencyAmtinBaseToken = _getTokenToBase(_token, _amount);
        (uint256 btFreeCapacity, ) = _getFreeCapacity();

        if (buyCurrencyAmtinBaseToken > btFreeCapacity) {
            return false;
        }
        return true;
    }

    function buyCoverPerProduct(
        uint256 _productId,
        uint256 _amount,
        address _token
    ) external override allowedCaller {
        if (productListMap[_productId] == 0) {
            productList.push(_productId);
            productListMap[_productId] = 1;
        }
        if (productCoverTokensMap[_token] == 0) {
            productCoverTokens.push(_token);
            productCoverTokensMap[_token] = 1;
        }
        coverAmtPPPT[_productId][_token] = coverAmtPPPT[_productId][_token].add(_amount);
        deltaCoverAmt[_token] = deltaCoverAmt[_token].add(_amount);
    }

    function _getExactToken2PaymentToken(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amount
    ) private view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        if (_tokenFrom == _tokenTo) {
            return _amount;
        }
        uint256 ret = IExchangeRate(exchangeRate).getTokenToTokenAmount(_tokenFrom, _tokenTo, _amount);
        require(ret != 0, "_GET2PT:1");
        return ret;
    }

    function _settleExactPayoutFromStakers(
        address _paymentToken,
        uint256 _settleAmt,
        address _claimTo,
        uint256 _claimId
    ) private {
        uint256 settleAmount = _settleAmt;
        uint256 amountInPaymentToken = 0;
        uint256[] memory tempPaymentTokenPerPool = new uint256[](stakersTokenData.length);
        uint256 poolLength = stakersTokenData.length;

        for (uint256 poolLengthIndex = 0; poolLengthIndex < poolLength; poolLengthIndex++) {
            address token = stakersTokenData[poolLengthIndex];
            uint256 temp = _getExactToken2PaymentToken(token, _paymentToken, IStakersPoolV2(stakersPoolV2).getStakedAmountPT(token));
            tempPaymentTokenPerPool[poolLengthIndex] = temp;
            amountInPaymentToken = amountInPaymentToken.add(temp);
        }

        // weight calc
        uint256[] memory settlePaymentPerPool = new uint256[](stakersTokenData.length);
        for (uint256 poolLengthIndex = 0; poolLengthIndex < poolLength; poolLengthIndex++) {
            if (poolLengthIndex == poolLength.sub(1)) {
                settlePaymentPerPool[poolLengthIndex] = settleAmount;
                break;
            }
            uint256 tempSettlePerPool = _settleAmt.mul(tempPaymentTokenPerPool[poolLengthIndex]).mul(10**10);
            tempSettlePerPool = tempSettlePerPool.div(amountInPaymentToken).div(10**10);
            settlePaymentPerPool[poolLengthIndex] = tempSettlePerPool;
            require(settleAmount >= tempSettlePerPool, "_SEPFS:1");
            settleAmount = settleAmount.sub(tempSettlePerPool);
        }

        // calc back to in amount and currency
        for (uint256 poolLengthIndex = 0; poolLengthIndex < poolLength; poolLengthIndex++) {
            address token = stakersTokenData[poolLengthIndex];
            if (settlePaymentPerPool[poolLengthIndex] == 0) {
                continue;
            }
            uint256 fromRate = IStakersPoolV2(stakersPoolV2).getStakedAmountPT(token);
            uint256 toRate = tempPaymentTokenPerPool[poolLengthIndex];
            if (toRate == 0) {
                continue;
            }
            IStakersPoolV2(stakersPoolV2).claimPayout(token, _paymentToken, settlePaymentPerPool[poolLengthIndex], _claimTo, _claimId, fromRate, toRate);
        }
    }

    function settlePaymentForClaim(
        address _token,
        uint256 _amount,
        uint256 _claimId
    ) external override allowedCaller {
        require(_amount > 0, "PPFC:1");

        uint256 premiumPayoutRatioAmt = IPremiumPool(premiumPoolAddress).getPremiumPoolAmtInPaymentToken(_token);

        premiumPayoutRatioAmt = premiumPayoutRatioAmt.mul(premiumPayoutRatioX10000).div(10**4);

        uint256 paymentToSettle = _amount;
        if (premiumPayoutRatioAmt != 0) {
            uint256 settleAmt = Math.min(premiumPayoutRatioAmt, _amount);

            uint256 remainAmt = IPremiumPool(premiumPoolAddress).settlePayoutFromPremium(_token, settleAmt, claimToSettlementPool);
            require(settleAmt >= remainAmt, "PPFC:2");
            require(paymentToSettle >= settleAmt.sub(remainAmt), "PPFC:3");
            paymentToSettle = paymentToSettle.sub(settleAmt.sub(remainAmt));
        }
        if (paymentToSettle == 0) {
            return;
        }
        // settle from stakers pools

        _settleExactPayoutFromStakers(_token, paymentToSettle, claimToSettlementPool, _claimId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
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
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ICapitalPool {
    function canBuyCoverPerProduct(
        uint256 _productId,
        uint256 _amount,
        address _token
    ) external view returns (bool);

    function canBuyCover(uint256 _amount, address _token) external view returns (bool);

    function buyCoverPerProduct(
        uint256 _productId,
        uint256 _amount,
        address _token
    ) external;

    function hasTokenInStakersPool(address _token) external view returns (bool);

    function getCapacityInfo() external view returns (uint256, uint256);

    function getBaseToken() external view returns (address);

    function getCoverAmtPPMaxRatio() external view returns (uint256);

    function getCoverAmtPPInBaseToken(uint256 _productId) external view returns (uint256);

    function settlePaymentForClaim(
        address _token,
        uint256 _amount,
        uint256 _claimId
    ) external;

    function getStakingPercentageX10000() external view returns (uint256);

    function getTVLinBaseToken() external view returns (uint256);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IPremiumPool {
    function addPremiumAmount(address _token, uint256 _amount) external payable;

    function getPremiumPoolAmtInPaymentToken(address _paymentToken) external view returns (uint256);

    function settlePayoutFromPremium(
        address _paymentToken,
        uint256 _settleAmt,
        address _claimToSettlementPool
    ) external returns (uint256);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IStakersPoolV2 {
    function addStkAmount(address _token, uint256 _amount) external payable;

    function withdrawTokens(
        address payable _to,
        uint256 _amount,
        address _token,
        address _feePool,
        uint256 _fee
    ) external;

    function reCalcPoolPT(address _lpToken) external;

    function settlePendingRewards(address _account, address _lpToken) external;

    function harvestRewards(
        address _account,
        address _lpToken,
        address _to
    ) external returns (uint256);

    function getPoolRewardPerLPToken(address _lpToken) external view returns (uint256);

    function getStakedAmountPT(address _token) external view returns (uint256);

    function showPendingRewards(address _account, address _lpToken) external view returns (uint256);

    function showHarvestRewards(address _account, address _lpToken) external view returns (uint256);

    function claimPayout(
        address _fromToken,
        address _paymentToken,
        uint256 _settleAmtPT,
        address _claimToSettlementPool,
        uint256 _claimId,
        uint256 _fromRate,
        uint256 _toRate
    ) external;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {ISecurityMatrix} from "./ISecurityMatrix.sol";

contract SecurityMatrix is ISecurityMatrix, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function initializeSecurityMatrix() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    // callee -> caller
    mapping(address => mapping(address => uint256)) public allowedCallersMap;
    mapping(address => address[]) public allowedCallersArray;
    address[] public allowedCallees;

    function pauseAll() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPauseAll() external onlyOwner whenPaused {
        _unpause();
    }

    function addAllowdCallersPerCallee(address _callee, address[] memory _callers) external onlyOwner {
        require(_callers.length != 0, "AACPC:1");
        require(allowedCallersArray[_callee].length != 0, "AACPC:2");

        for (uint256 index = 0; index < _callers.length; index++) {
            allowedCallersArray[_callee].push(_callers[index]);
            allowedCallersMap[_callee][_callers[index]] = 1;
        }
    }

    function setAllowdCallersPerCallee(address _callee, address[] memory _callers) external onlyOwner {
        require(_callers.length != 0, "SACPC:1");
        // check if callee exist
        if (allowedCallersArray[_callee].length == 0) {
            // not exist, so add callee
            allowedCallees.push(_callee);
        } else {
            // if callee exist, then purge data
            for (uint256 i = 0; i < allowedCallersArray[_callee].length; i++) {
                delete allowedCallersMap[_callee][allowedCallersArray[_callee][i]];
            }
            delete allowedCallersArray[_callee];
        }
        // and overwrite
        for (uint256 index = 0; index < _callers.length; index++) {
            allowedCallersArray[_callee].push(_callers[index]);
            allowedCallersMap[_callee][_callers[index]] = 1;
        }
    }

    function isAllowdCaller(address _callee, address _caller) external view override whenNotPaused returns (bool) {
        return allowedCallersMap[_callee][_caller] == 1 ? true : false;
    }

    function getAllowedCallees() external view returns (address[] memory) {
        return allowedCallees;
    }

    function getAllowedCallersPerCallee(address _callee) external view returns (address[] memory) {
        return allowedCallersArray[_callee];
    }
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

library Constant {
    // the standard 10**18 Amount Multiplier
    uint256 public constant MULTIPLIERX10E18 = 10**18;

    // the valid ETH and DAI addresses (Rinkeby, TBD: Mainnet)
    address public constant BCNATIVETOKENADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // product status enumerations
    uint256 public constant PRODUCTSTATUS_ENABLED = 1;
    uint256 public constant PRODUCTSTATUS_DISABLED = 2;

    // the cover status enumerations
    uint256 public constant COVERSTATUS_ACTIVE = 0;
    uint256 public constant COVERSTATUS_EXPIRED = 1;
    uint256 public constant COVERSTATUS_CLAIMINPROGRESS = 2;
    uint256 public constant COVERSTATUS_CLAIMDONE = 3;
    uint256 public constant COVERSTATUS_CANCELLED = 4;

    // the claim status enumerations
    uint256 public constant CLAIMSTATUS_SUBMITTED = 0;
    uint256 public constant CLAIMSTATUS_INVESTIGATING = 1;
    uint256 public constant CLAIMSTATUS_PREPAREFORVOTING = 2;
    uint256 public constant CLAIMSTATUS_VOTING = 3;
    uint256 public constant CLAIMSTATUS_VOTINGCOMPLETED = 4;
    uint256 public constant CLAIMSTATUS_ABDISCRETION = 5;
    uint256 public constant CLAIMSTATUS_COMPLAINING = 6;
    uint256 public constant CLAIMSTATUS_COMPLAININGCOMPLETED = 7;
    uint256 public constant CLAIMSTATUS_ACCEPTED = 8;
    uint256 public constant CLAIMSTATUS_REJECTED = 9;
    uint256 public constant CLAIMSTATUS_PAYOUTREADY = 10;
    uint256 public constant CLAIMSTATUS_PAID = 11;

    // the voting outcome status enumerations
    uint256 public constant OUTCOMESTATUS_NONE = 0;
    uint256 public constant OUTCOMESTATUS_ACCEPTED = 1;
    uint256 public constant OUTCOMESTATUS_REJECTED = 2;

    // the referral reward type
    uint256 public constant REFERRALREWARD_NONE = 0;
    uint256 public constant REFERRALREWARD_COVER = 1;
    uint256 public constant REFERRALREWARD_STAKING = 2;
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// a library for performing various math operations
library Math {
    using SafeMathUpgradeable for uint256;

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? y : x;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y.div(2).add(1);
            while (x < z) {
                z = x;
                x = (y.div(x).add(x)).div(2);
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // power private function
    function pow(uint256 _base, uint256 _exponent) internal pure returns (uint256) {
        if (_exponent == 0) {
            return 1;
        } else if (_exponent == 1) {
            return _base;
        } else if (_base == 0 && _exponent != 0) {
            return 0;
        } else {
            uint256 z = _base;
            for (uint256 i = 1; i < _exponent; i++) {
                z = z.mul(_base);
            }
            return z;
        }
    }
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IExchangeRate {
    function getBaseCurrency() external view returns (address);

    function setBaseCurrency(address _currency) external;

    function getAllCurrencyArray() external view returns (address[] memory);

    function addCurrencies(
        address[] memory _currencies,
        uint128[] memory _multipliers,
        uint128[] memory _rates
    ) external;

    function removeCurrency(address _currency) external;

    function getAllCurrencyRates() external view returns (uint256[] memory);

    function updateAllCurrencies(uint128[] memory _rates) external;

    function updateCurrency(address _currency, uint128 _rate) external;

    function getTokenToTokenAmount(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ISecurityMatrix {
    function isAllowdCaller(address _callee, address _caller) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}