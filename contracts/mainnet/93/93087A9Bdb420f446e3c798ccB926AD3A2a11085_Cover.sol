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

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import {ISecurityMatrix} from "../secmatrix/ISecurityMatrix.sol";
import {Math} from "../common/Math.sol";
import {Constant} from "../common/Constant.sol";
import {ICoverConfig} from "./ICoverConfig.sol";
import {ICoverData} from "./ICoverData.sol";
import {ICoverQuotation} from "./ICoverQuotation.sol";
import {ICapitalPool} from "../pool/ICapitalPool.sol";
import {IPremiumPool} from "../pool/IPremiumPool.sol";
import {IExchangeRate} from "../exchange/IExchangeRate.sol";
import {IReferralProgram} from "../referral/IReferralProgram.sol";
import {ICover} from "./ICover.sol";

contract Cover is ICover, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // the security matrix address
    address public smx;
    // the cover data address
    address public data;
    // the cover config address
    address public cfg;
    // the cover quotation address
    address public quotation;
    // the capital pool address
    address public capitalPool;
    // the premium pool address
    address public premiumPool;
    // the insur token address
    address public insur;

    // buy cover maxmimum block number latency
    uint256 public buyCoverMaxBlkNumLatency;
    // buy cover signer flag map (signer -> true/false)
    mapping(address => bool) public buyCoverSignerFlagMap;
    // buy cover owner nonce flag map (owner -> nonce -> true/false)
    mapping(address => mapping(uint256 => bool)) public buyCoverNonceFlagMap;

    // the exchange rate address
    address public exchangeRate;

    // the referral program address
    address public referralProgram;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setup(
        address securityMatrixAddress,
        address insurTokenAddress,
        address _coverDataAddress,
        address _coverCfgAddress,
        address _coverQuotationAddress,
        address _capitalPool,
        address _premiumPool,
        address _exchangeRate,
        address _referralProgram
    ) external onlyOwner {
        require(securityMatrixAddress != address(0), "S:1");
        require(insurTokenAddress != address(0), "S:2");
        require(_coverDataAddress != address(0), "S:3");
        require(_coverCfgAddress != address(0), "S:4");
        require(_coverQuotationAddress != address(0), "S:5");
        require(_capitalPool != address(0), "S:6");
        require(_premiumPool != address(0), "S:7");
        require(_exchangeRate != address(0), "S:8");
        require(_referralProgram != address(0), "S:9");
        smx = securityMatrixAddress;
        insur = insurTokenAddress;
        data = _coverDataAddress;
        cfg = _coverCfgAddress;
        quotation = _coverQuotationAddress;
        capitalPool = _capitalPool;
        premiumPool = _premiumPool;
        exchangeRate = _exchangeRate;
        referralProgram = _referralProgram;
    }

    function pauseAll() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPauseAll() external onlyOwner whenPaused {
        _unpause();
    }

    modifier allowedCaller() {
        require((ISecurityMatrix(smx).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    function getPremium(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256[] memory rewardPercentages
    )
        external
        view
        override
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256[] memory
        )
    {
        require(products.length == durationInDays.length, "GPCHK: 1");
        require(products.length == amounts.length, "GPCHK: 2");

        // check if the currency is a valid premium currency
        require(ICoverConfig(cfg).isValidCurrency(currency), "GPCHK: 3");

        // check the owner and referrer addresses
        require(owner != address(0), "GPCHK: 4");
        require(address(uint160(referralCode)) != address(0), "GPCHK: 5");

        // check if each amount is within the individual capacity
        uint256[] memory helperParameters = new uint256[](2);
        helperParameters[0] = 0;
        helperParameters[1] = 0;
        for (uint256 i = 0; i < products.length; i++) {
            helperParameters[0] = helperParameters[0].add(amounts[i]);
            helperParameters[1] = helperParameters[1].add(amounts[i].mul(durationInDays[i]));
            require(ICapitalPool(capitalPool).canBuyCoverPerProduct(products[i], amounts[i], currency), "GPCHK: 6");
        }

        // check if the total amount is within the overall capacity (ETH/DAI, from Capital Pool)
        require(ICapitalPool(capitalPool).canBuyCover(helperParameters[0], currency), "GPCHK: 7");

        // check and calculate the cover premium amount
        uint256 premiumAmount = 0;
        uint256 discountPercent = 0;
        (premiumAmount, discountPercent) = ICoverQuotation(quotation).getPremium(products, durationInDays, amounts, currency);
        require(premiumAmount > 0, "GPCHK: 8");

        // check the Cover Owner and Referral Reward Percentages (its length is 2)
        require(rewardPercentages.length == 2, "GPCHK: 9");
        uint256[] memory insurRewardAmounts = new uint256[](2);

        // calculate the Cover Owner and Referral Reward amounts
        uint256 premiumAmount2Insur = IExchangeRate(exchangeRate).getTokenToTokenAmount(currency, insur, premiumAmount);
        if (premiumAmount2Insur > 0 && owner != address(uint160(referralCode))) {
            // estimate the Cover Owner INSUR Reward Amount
            uint256 coverOwnerRewardPctg = _getRewardPctg(rewardPercentages[0]);
            insurRewardAmounts[0] = _getRewardAmount(premiumAmount2Insur, coverOwnerRewardPctg);
            // estimate the Referral INSUR Reward Amount
            uint256 referralRewardPctg = rewardPercentages[1];
            (, insurRewardAmounts[1]) = IReferralProgram(referralProgram).getReferralRewardAmount(Constant.REFERRALREWARD_COVER, premiumAmount2Insur, referralRewardPctg);
        } else {
            // there is no INSUR reward amounts if no valid premium value or referrer
            insurRewardAmounts[0] = 0;
            insurRewardAmounts[1] = 0;
        }

        return (premiumAmount, helperParameters, discountPercent, insurRewardAmounts);
    }

    event BuyCoverEvent(address indexed currency, address indexed owner, uint256 coverId, uint256 productId, uint256 durationInDays, uint256 extendedClaimDays, uint256 coverAmount, uint256 estimatedPremium, uint256 coverStatus);

    event BuyCoverOwnerRewardEvent(address indexed owner, uint256 rewardPctg, uint256 insurRewardAmt);

    function buyCover(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override whenNotPaused nonReentrant {
        // check the number of cover details
        require(products.length == durationInDays.length, "BC: 1");
        require(products.length == amounts.length, "BC: 2");

        // check if the currency is a valid premium currency
        require(ICoverConfig(cfg).isValidCurrency(currency), "BC: 3");

        // check the beneficiary address list (its length is 2)
        require(owner != address(0), "BC: 4");
        require(address(uint160(referralCode)) != address(0), "BC: 5");

        // check the helper parameters (its length is 4)
        // helperParameters[0] -> totalAmounts (the sum of cover amounts)
        // helperParameters[1] -> totalWeight (the sum of cover amounts multipled by cover durations)
        // helperParameters[2] -> coverOwnerRewardPctg (the cover owner reward perentageX10000 of premium, 0 if not set)
        // helperParameters[3] -> referralRewardPctg (the referral reward perentageX10000 of premium, 0 if not set)
        require(helperParameters.length == 4, "BC: 6");

        // check the security parameters (its length is 2)
        // securityParameters[0] -> blockNumber (the block number when the signature is generated off-chain)
        // securityParameters[1] -> nonce (the nonce of the cover owner, can be timestamp in seconds)
        require(securityParameters.length == 2, "BC: 7");

        // check the block number latency
        require((block.number >= securityParameters[0]) && (block.number - securityParameters[0] <= buyCoverMaxBlkNumLatency), "BC: 8");

        // check the signature
        require(_checkSignature(address(this), products, durationInDays, amounts, currency, owner, referralCode, premiumAmount, helperParameters, securityParameters, v, r, s), "BC: 9");

        // check the cover owner nonce flag
        require(!buyCoverNonceFlagMap[owner][securityParameters[1]], "BC: 10");
        buyCoverNonceFlagMap[owner][securityParameters[1]] = true;

        // check and receive the premium from this transaction
        if (currency == Constant.BCNATIVETOKENADDRESS) {
            require(premiumAmount <= msg.value, "BC: 11");
            IPremiumPool(premiumPool).addPremiumAmount{value: premiumAmount}(currency, premiumAmount);
        } else {
            require(IERC20Upgradeable(currency).balanceOf(_msgSender()) >= premiumAmount, "BC: 12");
            require(IERC20Upgradeable(currency).allowance(_msgSender(), address(this)) >= premiumAmount, "BC: 13");
            IERC20Upgradeable(currency).safeTransferFrom(_msgSender(), address(this), premiumAmount);
            IERC20Upgradeable(currency).safeTransfer(premiumPool, premiumAmount);
            IPremiumPool(premiumPool).addPremiumAmount(currency, premiumAmount);
        }

        // process the cover creation and reward distribution
        _processCovers(products, durationInDays, amounts, currency, owner, referralCode, premiumAmount, helperParameters);
    }

    function _checkSignature(
        address scAddress,
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 msgHash = "msgHash";
        {
            bytes memory msg1 = abi.encodePacked(scAddress, products, durationInDays, amounts, currency);
            bytes memory msg2 = abi.encodePacked(owner, referralCode, premiumAmount, helperParameters, securityParameters);
            msgHash = keccak256(abi.encodePacked(msg1, msg2));
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgHash));
        address signer = ecrecover(prefixedHash, v, r, s);
        return buyCoverSignerFlagMap[signer];
    }

    function _processCovers(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256 premiumAmount,
        uint256[] memory helperParameters
    ) internal {
        uint256 coverOwnerRewardPctg = 0;

        // check and give out the insur token reward if there is any referrer
        if (owner != address(uint160(referralCode))) {
            uint256 premiumAmount2Insur = IExchangeRate(exchangeRate).getTokenToTokenAmount(currency, insur, premiumAmount);
            // distribute the cover owner reward
            coverOwnerRewardPctg = _getRewardPctg(helperParameters[2]);
            _processCoverOwnerReward(owner, premiumAmount2Insur, coverOwnerRewardPctg);
            // distribute the referral reward if the referrer address is not the owner address
            IReferralProgram(referralProgram).processReferralReward(address(uint160(referralCode)), owner, Constant.REFERRALREWARD_COVER, premiumAmount2Insur, helperParameters[3]);
        }

        // create the expanded cover records (one per each cover item)
        uint256[] memory capacities = new uint256[](2);
        (capacities[0], capacities[1]) = ICapitalPool(capitalPool).getCapacityInfo();
        _createCovers(owner, currency, premiumAmount, products, durationInDays, amounts, capacities, helperParameters, coverOwnerRewardPctg);
    }

    function _createCovers(
        address owner,
        address currency,
        uint256 premiumAmount,
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        uint256[] memory capacities,
        uint256[] memory helperParameters,
        uint256 rewardPctg
    ) internal {
        require(IExchangeRate(exchangeRate).getTokenToTokenAmount(currency, ICapitalPool(capitalPool).getBaseToken(), helperParameters[0]) <= capacities[0], "BCC: 1");
        uint256 cumPremiumAmount = 0;
        for (uint256 index = 0; index < products.length; ++index) {
            require(IExchangeRate(exchangeRate).getTokenToTokenAmount(currency, ICapitalPool(capitalPool).getBaseToken(), amounts[index]).add(ICapitalPool(capitalPool).getCoverAmtPPInBaseToken(products[index])) <= capacities[1].mul(ICapitalPool(capitalPool).getCoverAmtPPMaxRatio()).div(10000), "BCC: 2");
            ICapitalPool(capitalPool).buyCoverPerProduct(products[index], amounts[index], currency);

            uint256 estimatedPremium = 0;
            if (index == products.length.sub(1)) {
                estimatedPremium = premiumAmount.sub(cumPremiumAmount);
            } else {
                uint256 currentWeight = amounts[index].mul(durationInDays[index]);
                estimatedPremium = currentWeight.mul(10000).div(helperParameters[1]).mul(premiumAmount).div(10000);
                cumPremiumAmount = cumPremiumAmount.add(estimatedPremium);
            }

            _createOneCover(owner, currency, products[index], durationInDays[index], amounts[index], estimatedPremium, rewardPctg);
        }
    }

    function _createOneCover(
        address owner,
        address currency,
        uint256 productId,
        uint256 durationInDays,
        uint256 amount,
        uint256 estimatedPremium,
        uint256 rewardPctg
    ) internal {
        uint256 nextCoverId = ICoverData(data).increaseCoverCount(owner);
        ICoverData(data).setNewCoverDetails(
            owner,
            nextCoverId,
            productId,
            amount,
            currency,
            block.timestamp, // solhint-disable-line not-rely-on-time
            block.timestamp + durationInDays * 1 days, // solhint-disable-line not-rely-on-time
            block.timestamp + (durationInDays + ICoverConfig(cfg).getMaxClaimDurationInDaysAfterExpired()) * 1 days, // solhint-disable-line not-rely-on-time
            estimatedPremium
        );

        if (rewardPctg > 0) {
            ICoverData(data).setCoverRewardPctg(owner, nextCoverId, rewardPctg);
        }

        emit BuyCoverEvent(currency, owner, nextCoverId, productId, durationInDays, ICoverConfig(cfg).getMaxClaimDurationInDaysAfterExpired(), amount, estimatedPremium, Constant.COVERSTATUS_ACTIVE);
    }

    event UnlockCoverRewardEvent(address indexed owner, uint256 amount);

    function unlockRewardByController(address _owner, address _to) external override allowedCaller whenNotPaused nonReentrant returns (uint256) {
        return _unlockReward(_owner, _to);
    }

    function _unlockReward(address owner, address to) internal returns (uint256) {
        uint256 toBeunlockedAmt = ICoverData(data).getBuyCoverInsurTokenEarned(owner);
        if (toBeunlockedAmt > 0) {
            ICoverData(data).decreaseTotalInsurTokenRewardAmount(toBeunlockedAmt);
            ICoverData(data).decreaseBuyCoverInsurTokenEarned(owner, toBeunlockedAmt);
            IERC20Upgradeable(insur).safeTransfer(to, toBeunlockedAmt);
            emit UnlockCoverRewardEvent(owner, toBeunlockedAmt);
        }
        return toBeunlockedAmt;
    }

    function getRewardAmount() external view override returns (uint256) {
        return ICoverData(data).getBuyCoverInsurTokenEarned(_msgSender());
    }

    function getCoverOwnerRewardAmount(uint256 premiumAmount2Insur, uint256 overwrittenRewardPctg) external view override returns (uint256, uint256) {
        uint256 rewardPctg = _getRewardPctg(overwrittenRewardPctg);
        uint256 rewardAmount = _getRewardAmount(premiumAmount2Insur, rewardPctg);
        return (rewardPctg, rewardAmount);
    }

    function _getRewardPctg(uint256 overwrittenRewardPctg) internal view returns (uint256) {
        return overwrittenRewardPctg > 0 ? overwrittenRewardPctg : ICoverConfig(cfg).getInsurTokenRewardPercentX10000();
    }

    function _getRewardAmount(uint256 premiumAmount2Insur, uint256 rewardPctg) internal pure returns (uint256) {
        return rewardPctg <= 10000 ? premiumAmount2Insur.mul(rewardPctg).div(10**4) : 0;
    }

    function _processCoverOwnerReward(
        address owner,
        uint256 premiumAmount2Insur,
        uint256 rewardPctg
    ) internal {
        require(rewardPctg <= 10000, "PCORWD: 1");
        uint256 rewardAmount = _getRewardAmount(premiumAmount2Insur, rewardPctg);
        if (rewardAmount > 0) {
            ICoverData(data).increaseTotalInsurTokenRewardAmount(rewardAmount);
            ICoverData(data).increaseBuyCoverInsurTokenEarned(owner, rewardAmount);
            emit BuyCoverOwnerRewardEvent(owner, rewardPctg, rewardAmount);
        }
    }

    function getINSURRewardBalanceDetails() external view override returns (uint256, uint256) {
        uint256 insurRewardBalance = IERC20Upgradeable(insur).balanceOf(address(this));
        uint256 totalRewardRequired = ICoverData(data).getTotalInsurTokenRewardAmount();
        return (insurRewardBalance, totalRewardRequired);
    }

    function removeINSURRewardBalance(address toAddress, uint256 amount) external override onlyOwner {
        IERC20Upgradeable(insur).safeTransfer(toAddress, amount);
    }

    event SetBuyCoverMaxBlkNumLatencyEvent(uint256 numOfBlocks);

    function setBuyCoverMaxBlkNumLatency(uint256 numOfBlocks) external override onlyOwner {
        require(numOfBlocks > 0, "SBCMBNL: 1");
        buyCoverMaxBlkNumLatency = numOfBlocks;
        emit SetBuyCoverMaxBlkNumLatencyEvent(numOfBlocks);
    }

    event SetBuyCoverSignerEvent(address indexed signer, bool enabled);

    function setBuyCoverSigner(address signer, bool enabled) external override onlyOwner {
        require(signer != address(0), "SBCS: 1");
        buyCoverSignerFlagMap[signer] = enabled;
        emit SetBuyCoverSignerEvent(signer, enabled);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

interface ICoverConfig {
    function getAllValidCurrencyArray() external view returns (address[] memory);

    function isValidCurrency(address currency) external view returns (bool);

    function getMinDurationInDays() external view returns (uint256);

    function getMaxDurationInDays() external view returns (uint256);

    function getMinAmountOfCurrency(address currency) external view returns (uint256);

    function getMaxAmountOfCurrency(address currency) external view returns (uint256);

    function getMaxClaimDurationInDaysAfterExpired() external view returns (uint256);

    function getInsurTokenRewardPercentX10000() external view returns (uint256);
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

interface ICoverData {
    function hasCoverOwner(address owner) external view returns (bool);

    function addCoverOwner(address owner) external;

    function getAllCoverOwnerList() external view returns (address[] memory);

    function getAllCoverCount() external view returns (uint256);

    function getCoverCount(address owner) external view returns (uint256);

    function increaseCoverCount(address owner) external returns (uint256);

    function setNewCoverDetails(
        address owner,
        uint256 coverId,
        uint256 productId,
        uint256 amount,
        address currency,
        uint256 beginTimestamp,
        uint256 endTimestamp,
        uint256 maxClaimableTimestamp,
        uint256 estimatedPremium
    ) external;

    function getCoverBeginTimestamp(address owner, uint256 coverId) external view returns (uint256);

    function setCoverBeginTimestamp(
        address owner,
        uint256 coverId,
        uint256 timestamp
    ) external;

    function getCoverEndTimestamp(address owner, uint256 coverId) external view returns (uint256);

    function setCoverEndTimestamp(
        address owner,
        uint256 coverId,
        uint256 timestamp
    ) external;

    function getCoverMaxClaimableTimestamp(address owner, uint256 coverId) external view returns (uint256);

    function setCoverMaxClaimableTimestamp(
        address owner,
        uint256 coverId,
        uint256 timestamp
    ) external;

    function getCoverProductId(address owner, uint256 coverId) external view returns (uint256);

    function setCoverProductId(
        address owner,
        uint256 coverId,
        uint256 productId
    ) external;

    function getCoverCurrency(address owner, uint256 coverId) external view returns (address);

    function setCoverCurrency(
        address owner,
        uint256 coverId,
        address currency
    ) external;

    function getCoverAmount(address owner, uint256 coverId) external view returns (uint256);

    function setCoverAmount(
        address owner,
        uint256 coverId,
        uint256 amount
    ) external;

    function getAdjustedCoverStatus(address owner, uint256 coverId) external view returns (uint256);

    function setCoverStatus(
        address owner,
        uint256 coverId,
        uint256 coverStatus
    ) external;

    function isCoverClaimable(address owner, uint256 coverId) external view returns (bool);

    function getCoverEstimatedPremiumAmount(address owner, uint256 coverId) external view returns (uint256);

    function setCoverEstimatedPremiumAmount(
        address owner,
        uint256 coverId,
        uint256 amount
    ) external;

    function getBuyCoverInsurTokenEarned(address owner) external view returns (uint256);

    function increaseBuyCoverInsurTokenEarned(address owner, uint256 amount) external;

    function decreaseBuyCoverInsurTokenEarned(address owner, uint256 amount) external;

    function getTotalInsurTokenRewardAmount() external view returns (uint256);

    function increaseTotalInsurTokenRewardAmount(uint256 amount) external;

    function decreaseTotalInsurTokenRewardAmount(uint256 amount) external;

    function getCoverRewardPctg(address owner, uint256 coverId) external view returns (uint256);

    function setCoverRewardPctg(
        address owner,
        uint256 coverId,
        uint256 rewardPctg
    ) external;

    function getCoverClaimedAmount(address owner, uint256 coverId) external view returns (uint256);

    function increaseCoverClaimedAmount(
        address owner,
        uint256 coverId,
        uint256 amount
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

interface ICoverQuotation {
    function getPremium(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        address currency
    ) external view returns (uint256, uint256);
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

interface IReferralProgram {
    function getReferralINSURRewardPctg(uint256 rewardType) external view returns (uint256);

    function setReferralINSURRewardPctg(uint256 rewardType, uint256 percent) external;

    function getReferralINSURRewardAmount() external view returns (uint256);

    function getTotalReferralINSURRewardAmount() external view returns (uint256);

    function getReferralRewardAmount(
        uint256 rewardType,
        uint256 baseAmount,
        uint256 overwrittenRewardPctg
    ) external view returns (uint256, uint256);

    function processReferralReward(
        address referrer,
        address referee,
        uint256 rewardType,
        uint256 baseAmount,
        uint256 overwrittenRewardPctg
    ) external;

    function unlockRewardByController(address referrer, address to) external returns (uint256);

    function getINSURRewardBalanceDetails() external view returns (uint256, uint256);

    function removeINSURRewardBalance(address toAddress, uint256 amount) external;
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

interface ICover {
    function getPremium(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256[] memory rewardPercentages
    )
        external
        view
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256[] memory
        );

    function buyCover(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function unlockRewardByController(address owner, address to) external returns (uint256);

    function getRewardAmount() external view returns (uint256);

    function getCoverOwnerRewardAmount(uint256 premiumAmount2Insur, uint256 overwrittenRewardPctg) external view returns (uint256, uint256);

    function getINSURRewardBalanceDetails() external view returns (uint256, uint256);

    function removeINSURRewardBalance(address toAddress, uint256 amount) external;

    function setBuyCoverMaxBlkNumLatency(uint256 numOfBlocks) external;

    function setBuyCoverSigner(address signer, bool enabled) external;
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

