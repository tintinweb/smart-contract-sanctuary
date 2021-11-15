// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '../interfaces/ICrowdsale.sol';
import '../interfaces/IStagedCrowdsale.sol';
import '../interfaces/ITimedCrowdsale.sol';
import '../interfaces/IUltiCrowdsale.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

contract UltiCrowdsaleWrappedV03 is
    ICrowdsale,
    IStagedCrowdsale,
    ITimedCrowdsale,
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    mapping(CrowdsaleStage => CrowdsaleStageData) private _stages;

    IUltiCrowdsale private baseCrowdsale;
    IUltiCrowdsale private wrappedV01Crowdsale;

    // Token amount bought by each beneficiary
    mapping(address => uint256) private _balances;

    // Number of tokens sold
    uint256 private _tokensSold;

    // Amount of wei raised
    uint256 private _weiRaised;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier onlyWhileOpen() {
        require(isOpen(), 'TimedCrowdsale: not open');
        _;
    }

    modifier onlyInContributionLimits(address beneficiary, uint256 weiAmount) {
        require(weiAmount > 0, 'UltiCrowdsale: the value sent is zero');
        require(
            weiContributedInStage(stage(), beneficiary) + weiAmount >= minContribution(),
            'UltiCrowdsale: the value sent is insufficient for the minimal contribution'
        );
        require(
            weiAmount <= _weiToContributionLimit(beneficiary),
            'UltiCrowdsale: the value sent exceeds the maximum contribution'
        );
        _;
    }

    receive() external payable {
        buyTokens(_msgSender());
    }

    function token() public view override returns (IERC20Burnable) {
        return baseCrowdsale.token();
    }

    function wallet() public view override returns (address payable) {
        return baseCrowdsale.wallet();
    }

    function rate() public view override returns (uint256) {
        return baseCrowdsale.rate();
    }

    function weiRaised() public view override returns (uint256) {
        return wrappedV01Crowdsale.weiRaised() + _weiRaised;
    }

    function buyTokens(address beneficiary) public payable override nonReentrant {
        uint256 weiAmount = msg.value;

        if (
            weiAmount >= baseCrowdsale.minContribution() ||
            baseCrowdsale.weiContributedInStage(stage(), beneficiary) >= baseCrowdsale.minContribution()
        ) {
            baseCrowdsale.buyTokens{value: weiAmount}(beneficiary);
            return;
        }

        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised + weiAmount;

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
    }

    function openingTime() public view override returns (uint256) {
        return baseCrowdsale.openingTime();
    }

    function closingTime() public view override returns (uint256) {
        return baseCrowdsale.closingTime();
    }

    function isOpen() public view override returns (bool) {
        return baseCrowdsale.isOpen() && block.timestamp < _stages[CrowdsaleStage.Presale5].closingTime;
    }

    function hasClosed() public view override returns (bool) {
        return baseCrowdsale.hasClosed();
    }

    function bonus() public view override returns (uint256) {
        return baseCrowdsale.bonus();
    }

    function minContribution() public view override returns (uint256) {
        return _stages[stage()].minContribution;
    }

    function maxContribution() public view override returns (uint256) {
        return _stages[stage()].maxContribution;
    }

    function cap() external view override returns (uint256) {
        return baseCrowdsale.cap();
    }

    function stage() public view override returns (CrowdsaleStage) {
        return _currentStage();
    }

    function weiContributed(address account) external view override returns (uint256) {
        uint256 _weiContributed = 0;
        for (uint256 i = uint256(CrowdsaleStage.GuaranteedSpot); i <= uint256(CrowdsaleStage.Presale5); i++) {
            _weiContributed = _weiContributed + weiContributedInStage(CrowdsaleStage(i), account);
        }
        return _weiContributed;
    }

    function weiContributedInStage(CrowdsaleStage stage_, address account) public view override returns (uint256) {
        return wrappedV01Crowdsale.weiContributedInStage(stage_, account) + _stages[stage_].contributions[account];
    }

    function weiRaisedInStage(CrowdsaleStage stage_) public view override returns (uint256) {
        return wrappedV01Crowdsale.weiRaisedInStage(stage_) + _stages[stage_].weiRaised;
    }

    function weiToStageCap() external view override returns (uint256) {
        return _weiToStageCap();
    }

    function tokensBought(address beneficiary) public view returns (uint256) {
        return wrappedV01Crowdsale.tokensBought(beneficiary) + _balances[beneficiary];
    }

    function tokensSold() public view returns (uint256) {
        return wrappedV01Crowdsale.tokensSold() + _tokensSold;
    }

    function isWhitelisted(bytes32 whitelist, address account) public view returns (bool) {
        return baseCrowdsale.isWhitelisted(whitelist, account);
    }

    function isWhitelistedForCurrentStage(address account) public view returns (bool) {
        return baseCrowdsale.isWhitelistedForCurrentStage(account);
    }

    function GUARANTEED_SPOT_WHITELIST() public view returns (bytes32) {
        return baseCrowdsale.GUARANTEED_SPOT_WHITELIST();
    }

    function PRIVATE_SALE_WHITELIST() public view returns (bytes32) {
        return baseCrowdsale.PRIVATE_SALE_WHITELIST();
    }

    function KYCED_WHITELIST() public view returns (bytes32) {
        return baseCrowdsale.KYCED_WHITELIST();
    }

    function updateStage(
        CrowdsaleStage stage_,
        uint256 closingTime_,
        uint256 minContribution_,
        uint256 maxContribution_
    ) public onlyOwner {
        require(
            stage_ > CrowdsaleStage.Inactive && stage_ <= CrowdsaleStage.Presale5,
            'UltiCrowdsale: stage int out of range'
        );

        if (closingTime_ > 0) {
            uint256 stageInt = uint256(stage_);
            require(
                closingTime_ > _stages[CrowdsaleStage(stageInt - 1)].closingTime,
                'UltiCrowdsale: closing time must be higher than in previous stage'
            );
            if (stage_ < CrowdsaleStage.Presale5) {
                require(
                    closingTime_ < _stages[CrowdsaleStage(stageInt + 1)].closingTime,
                    'UltiCrowdsale: closing time must be lower than in next stage'
                );
            }
            _stages[stage_].closingTime = closingTime_;
        }

        if (minContribution_ > 0) {
            require(
                minContribution_ <= _stages[stage_].maxContribution,
                'UltiCrowdsale: minimal contribution must be lower than maximal'
            );
            _stages[stage_].minContribution = minContribution_;
        }
        if (maxContribution_ > 0) {
            require(
                maxContribution_ >= _stages[stage_].minContribution,
                'UltiCrowdsale: maximal contribution must be higher than minimal'
            );
            _stages[stage_].maxContribution = maxContribution_;
        }
    }

    function withdrawAnyToken(
        IERC20 token_,
        address recipient_,
        uint256 amount_
    ) public onlyOwner {
        require(amount_ <= token_.balanceOf(address(this)), 'UltiCrowdsale: Requested amount exceeds balance');
        token_.transfer(recipient_, amount_);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
        onlyWhileOpen
        onlyInContributionLimits(beneficiary, weiAmount)
    {
        require(beneficiary != address(0), 'Crowdsale: beneficiary is the zero address');
        require(weiAmount != 0, 'Crowdsale: weiAmount is 0');
        require(weiAmount <= _weiToStageCap(), 'UltiCrowdsale: value sent exceeds cap of stage');
        require(
            baseCrowdsale.isWhitelistedForCurrentStage(beneficiary),
            'UltiCrowdsale: beneficiary is not on whitelist'
        );
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 amount = weiAmount * rate();
        uint256 _bonus = (amount * bonus()) / 100;
        return amount + _bonus;
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _balances[beneficiary] = _balances[beneficiary] + tokenAmount;
        _tokensSold = _tokensSold + tokenAmount;
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        CrowdsaleStage stage_ = stage();
        _stages[stage_].weiRaised = _stages[stage_].weiRaised + weiAmount;
        _stages[stage_].contributions[beneficiary] = _stages[stage_].contributions[beneficiary] + weiAmount;
    }

    function _forwardFunds() internal {
        baseCrowdsale.wallet().transfer(msg.value);
    }

    function _weiToStageCap() private view returns (uint256) {
        CrowdsaleStage stage_ = stage();
        uint256 extraAmount = 0;
        // In order to sum up raised amounts in GuaranteedSpot and PrivateSale stages
        if (stage_ == CrowdsaleStage.PrivateSale) {
            extraAmount = _stages[CrowdsaleStage.GuaranteedSpot].weiRaised;
        }
        uint256 baseWeiToStageCap = wrappedV01Crowdsale.weiToStageCap();
        if (_stages[stage_].weiRaised + extraAmount > baseWeiToStageCap) {
            return 0;
        }
        return baseWeiToStageCap - _stages[stage_].weiRaised - extraAmount;
    }

    function _weiToContributionLimit(address account) private view returns (uint256) {
        CrowdsaleStage stage_ = stage();
        uint256 extraAmount = 0;
        // In order to sum up raised amounts in GuaranteedSpot and PrivateSale stages
        if (stage_ == CrowdsaleStage.PrivateSale) {
            extraAmount = weiContributedInStage(CrowdsaleStage.GuaranteedSpot, account);
        }
        uint256 weiContributedInStage_ = weiContributedInStage(stage_, account);
        if (weiContributedInStage_ + extraAmount > maxContribution()) {
            return 0;
        }
        return maxContribution() - weiContributedInStage_ - extraAmount;
    }

    function _currentStage() private view returns (CrowdsaleStage) {
        if (!isOpen()) {
            return CrowdsaleStage.Inactive;
        }

        uint256 lastBlockTimestamp = block.timestamp;

        if (lastBlockTimestamp > _stages[CrowdsaleStage.Presale4].closingTime) {
            return CrowdsaleStage.Presale5;
        } else if (lastBlockTimestamp > _stages[CrowdsaleStage.Presale3].closingTime) {
            return CrowdsaleStage.Presale4;
        } else if (lastBlockTimestamp > _stages[CrowdsaleStage.Presale2].closingTime) {
            return CrowdsaleStage.Presale3;
        } else if (lastBlockTimestamp > _stages[CrowdsaleStage.Presale1].closingTime) {
            return CrowdsaleStage.Presale2;
        } else if (lastBlockTimestamp > _stages[CrowdsaleStage.PrivateSale].closingTime) {
            return CrowdsaleStage.Presale1;
        } else if (lastBlockTimestamp > _stages[CrowdsaleStage.GuaranteedSpot].closingTime) {
            return CrowdsaleStage.PrivateSale;
        } else {
            return CrowdsaleStage.GuaranteedSpot;
        }
    }

    function _setupStage(
        CrowdsaleStage stage_,
        uint256 closingTime_,
        uint256 rate_,
        uint256 bonus_,
        uint256 cap_,
        uint256 minContribution_,
        uint256 maxContribution_
    ) private {
        _stages[stage_].closingTime = closingTime_;
        _stages[stage_].rate = rate_;
        _stages[stage_].bonus = bonus_;
        _stages[stage_].cap = cap_;
        _stages[stage_].minContribution = minContribution_;
        _stages[stage_].maxContribution = maxContribution_;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './IERC20Burnable.sol';

interface ICrowdsale {
    function token() external view returns (IERC20Burnable);

    function wallet() external view returns (address payable);

    function rate() external view returns (uint256);

    function weiRaised() external view returns (uint256);

    function buyTokens(address beneficiary) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IStagedCrowdsale {
    enum CrowdsaleStage {
        Inactive,
        GuaranteedSpot,
        PrivateSale,
        Presale1,
        Presale2,
        Presale3,
        Presale4,
        Presale5
    }

    struct CrowdsaleStageData {
        uint256 closingTime;
        uint256 rate;
        uint256 bonus;
        uint256 cap;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 weiRaised;
        mapping(address => uint256) contributions;
    }

    function bonus() external view returns (uint256);

    function minContribution() external view returns (uint256);

    function maxContribution() external view returns (uint256);

    function cap() external view returns (uint256);

    function stage() external view returns (CrowdsaleStage);

    function weiContributed(address account) external view returns (uint256);

    function weiContributedInStage(CrowdsaleStage stage_, address account) external view returns (uint256);

    function weiRaisedInStage(CrowdsaleStage stage_) external view returns (uint256);

    function weiToStageCap() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ITimedCrowdsale {
    function openingTime() external view returns (uint256);

    function closingTime() external view returns (uint256);

    function isOpen() external view returns (bool);

    function hasClosed() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './ICrowdsale.sol';
import './IPostVestingCrowdsale.sol';
import './IStagedCrowdsale.sol';
import './ITimedCrowdsale.sol';

interface IUltiCrowdsale is IStagedCrowdsale, IPostVestingCrowdsale, ITimedCrowdsale, ICrowdsale {
    function GUARANTEED_SPOT_WHITELIST() external view returns (bytes32);

    function PRIVATE_SALE_WHITELIST() external view returns (bytes32);

    function KYCED_WHITELIST() external view returns (bytes32);

    function isWhitelisted(bytes32 whitelist, address account) external view returns (bool);

    function isWhitelistedForCurrentStage(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Interface of the ERC20Burnable standard.
 */
interface IERC20Burnable is IERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     */
    function burnFrom(address account, uint256 amount) external;
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

pragma solidity ^0.8.6;

interface IPostVestingCrowdsale {
    function vestingStart() external view returns (uint256);

    function vestingCliff() external view returns (uint256);

    function vestingEnd() external view returns (uint256);

    function isVestingEnded() external view returns (bool);

    function tokensBought(address beneficiary) external view returns (uint256);

    function tokensSold() external view returns (uint256);

    function tokensReleased() external view returns (uint256);

    function releasableAmount(address beneficiary) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

