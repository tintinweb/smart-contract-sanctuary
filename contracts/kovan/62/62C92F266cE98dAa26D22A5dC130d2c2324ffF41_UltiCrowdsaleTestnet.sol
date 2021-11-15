// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.0;

import '../crowdsale/extension/Crowdsale.sol';
import '../crowdsale/extension/TimedCrowdsale.sol';
import '../crowdsale/extension/PostVestingCrowdsale.sol';
import '../crowdsale/extension/WhitelistAccess.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract UltiCrowdsaleTestnet is Crowdsale, TimedCrowdsale, PostVestingCrowdsale, WhitelistAccess {
    enum CrowdsaleStage {Inactive, GuaranteedSpot, PrivateSale, Presale1, Presale2, Presale3, Presale4, Presale5}

    struct CrowdsaleStageData {
        uint256 closingTime;
        uint256 rate;
        uint256 bonus;
        uint256 cap;
        uint256 startCap;
        uint256 weiRaised;
    }

    mapping(CrowdsaleStage => CrowdsaleStageData) private _stages;

    mapping(address => uint256) private _weiContributed;

    uint256 public constant OPENING_TIME = 1622559600;
    uint256 public constant CLOSING_TIME = 1622862000;

    bytes32 public constant GUARANTEED_SPOT_WHITELIST = keccak256('GUARANTEED_SPOT_WHITELIST');
    bytes32 public constant CROWDSALE_WHITELIST = keccak256('CROWDSALE_WHITELIST');

    uint256 public constant MIN_PRIVATE_SALE_CONTRIBUTION = 5 * 1e13; // 0.00005 BNB
    uint256 public constant MAX_PRIVATE_SALE_CONTRIBUTION = 5 * 1e16; // 0.05 BNB

    uint256 public constant HARD_CAP = 5 * 1e17; // 0.5 BNB

    uint256 public constant VESTING_START_OFFSET = 300; // 5 min
    uint256 public constant VESTING_CLIFF_DURATION = 300; // 5 min
    uint256 public constant VESTING_DURATION = 1800; // 30 minutes
    uint256 public constant VESTING_INITIAL_PERCENT = 10; // 10 %

    constructor(address payable wallet_, IERC20Burnable token_)
        Crowdsale(1, wallet_, token_)
        TimedCrowdsale(OPENING_TIME, CLOSING_TIME)
        PostVestingCrowdsale(VESTING_START_OFFSET, VESTING_CLIFF_DURATION, VESTING_DURATION, VESTING_INITIAL_PERCENT)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        uint256 stageDuration = 43200;
        _setupCrowdsaleStage(CrowdsaleStage.Inactive, 0, 0, 0, 0, 0);
        _setupCrowdsaleStage(
            CrowdsaleStage.GuaranteedSpot,
            OPENING_TIME + (1 * stageDuration),
            5263157,
            30,
            1 * 1e17,
            0
        );
        _setupCrowdsaleStage(CrowdsaleStage.PrivateSale, OPENING_TIME + (2 * stageDuration), 5263157, 30, 1 * 1e17, 0);
        _setupCrowdsaleStage(
            CrowdsaleStage.Presale1,
            OPENING_TIME + (3 * stageDuration),
            2222222,
            10,
            1 * 1e17,
            1 * 1e17
        );
        _setupCrowdsaleStage(
            CrowdsaleStage.Presale2,
            OPENING_TIME + (4 * stageDuration),
            1408450,
            5,
            1 * 1e17,
            2 * 1e17
        );
        _setupCrowdsaleStage(
            CrowdsaleStage.Presale3,
            OPENING_TIME + (5 * stageDuration),
            1030927,
            3,
            1 * 1e17,
            3 * 1e17
        );
        _setupCrowdsaleStage(
            CrowdsaleStage.Presale4,
            OPENING_TIME + (6 * stageDuration),
            800000,
            0,
            1 * 1e17,
            4 * 1e17
        );
        _setupCrowdsaleStage(
            CrowdsaleStage.Presale5,
            OPENING_TIME + (7 * stageDuration),
            666666,
            0,
            1 * 1e17,
            5 * 1e17
        );
    }

    modifier onlyWhileHardcapNotReached() {
        require(!hardcapReached(), 'UltiCrowdsale: Hardcap is reached');
        _;
    }

    modifier onlyNotExceedsStageCap(uint256 weiAmount) {
        require(
            _stages[_currentStage()].startCap + _stages[_currentStage()].weiRaised + weiAmount <= cap(),
            'UltiCrowdsale: value sent exceeds maximal cap of stage'
        );
        _;
    }

    function rate() public view override(Crowdsale) returns (uint256) {
        return _stages[_currentStage()].rate;
    }

    function bonus() public view returns (uint256) {
        return _stages[_currentStage()].bonus;
    }

    function stage() public view returns (CrowdsaleStage) {
        return _currentStage();
    }

    function cap() public view returns (uint256) {
        return _stages[_currentStage()].startCap + _stages[_currentStage()].cap;
    }

    function hardcapReached() public view returns (bool) {
        return weiRaised() >= HARD_CAP;
    }

    function weiContributed(address account) public view returns (uint256) {
        return _weiContributed[account];
    }

    function weiRaisedInStage(CrowdsaleStage stage_) public view returns (uint256) {
        return _stages[stage_].weiRaised;
    }

    function releaseTokens(address beneficiary) public {
        require(beneficiary != address(0), 'UltiCrowdsale: beneficiary is the zero address');
        require(
            _isWhitelisted(GUARANTEED_SPOT_WHITELIST, beneficiary) || _isWhitelisted(CROWDSALE_WHITELIST, beneficiary),
            'UltiCrowdsale: beneficiary is not on whitelist'
        );
        return _releaseTokens(beneficiary);
    }

    function burn(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasClosed(), 'UltiCrowdsale: crowdsale not closed');
        uint256 crowdsaleBalance = token().balanceOf(address(this));
        uint256 tokensToBeReleased = tokensSold() - tokensReleased();
        require(crowdsaleBalance - amount >= tokensToBeReleased, 'UltiCrowdsale: unreleased tokens can not be burned');
        token().burn(amount);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
        override(Crowdsale, TimedCrowdsale)
        onlyWhileOpen
        onlyWhileHardcapNotReached
        onlyNotExceedsStageCap(weiAmount)
    {
        Crowdsale._preValidatePurchase(beneficiary, weiAmount);

        bool isGuaranteedSpotWhitelisted = _isWhitelisted(GUARANTEED_SPOT_WHITELIST, beneficiary);
        bool isCrowdsaleWhitelisted = _isWhitelisted(CROWDSALE_WHITELIST, beneficiary);
        CrowdsaleStage stage_ = _currentStage();
        // Check if beneficiary is whitelisted
        if (stage_ == CrowdsaleStage.GuaranteedSpot) {
            require(isGuaranteedSpotWhitelisted, 'UltiCrowdsale: beneficiary is not on whitelist');
        } else {
            require(
                isGuaranteedSpotWhitelisted || isCrowdsaleWhitelisted,
                'UltiCrowdsale: beneficiary is not on whitelist'
            );
        }
        // Check beneficiary contribution
        if (stage_ == CrowdsaleStage.GuaranteedSpot || stage_ == CrowdsaleStage.PrivateSale) {
            require(
                weiAmount >= MIN_PRIVATE_SALE_CONTRIBUTION,
                'UltiCrowdsale: value sent is lower than minimal contribution'
            );
            require(
                _weiContributed[beneficiary] + weiAmount <= MAX_PRIVATE_SALE_CONTRIBUTION,
                'UltiCrowdsale: value sent exceeds beneficiary private sale contribution limit'
            );
        }
    }

    function _getTokenAmount(uint256 weiAmount) internal view override(Crowdsale) returns (uint256) {
        uint256 amount = weiAmount * rate();
        uint256 _bonus = (amount * bonus()) / 100;
        return amount + _bonus;
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount)
        internal
        override(Crowdsale, PostVestingCrowdsale)
    {
        PostVestingCrowdsale._processPurchase(beneficiary, tokenAmount);
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal override(Crowdsale) {
        _stages[_currentStage()].weiRaised = _stages[_currentStage()].weiRaised + weiAmount;
        _weiContributed[beneficiary] = _weiContributed[beneficiary] + weiAmount;
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

    function _setupCrowdsaleStage(
        CrowdsaleStage stage_,
        uint256 closingTime_,
        uint256 rate_,
        uint256 bonus_,
        uint256 cap_,
        uint256 startingCap_
    ) private {
        _stages[stage_] = CrowdsaleStageData(closingTime_, rate_, bonus_, cap_, startingCap_, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './IERC20Burnable.sol';

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, ReentrancyGuard {
    using SafeERC20 for IERC20Burnable;

    // The token being sold
    IERC20Burnable private _token;

    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param rate_ Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet_ Address where collected funds will be forwarded to
     * @param token_ Address of the token being sold
     */
    constructor(
        uint256 rate_,
        address payable wallet_,
        IERC20Burnable token_
    ) {
        require(rate_ > 0, 'Crowdsale: rate is 0');
        require(wallet_ != address(0), 'Crowdsale: wallet is the zero address');
        require(address(token_) != address(0), 'Crowdsale: token is the zero address');

        _rate = rate_;
        _wallet = wallet_;
        _token = token_;
    }

    /**
     * @dev Contract might receive/hold ETH.
     */
    receive() external payable {
        buyTokens(_msgSender());
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20Burnable) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view virtual returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public payable nonReentrant {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised + weiAmount;

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised() + weiAmount <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view virtual {
        require(beneficiary != address(0), 'Crowdsale: beneficiary is the zero address');
        require(weiAmount != 0, 'Crowdsale: weiAmount is 0');
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal virtual {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view virtual returns (uint256) {
        return weiAmount * _rate;
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Crowdsale.sol';

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCrowdsale is Crowdsale {
    uint256 private _openingTime;
    uint256 private _closingTime;

    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), 'TimedCrowdsale: not open');
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param openingTime_ Crowdsale opening time
     * @param closingTime_ Crowdsale closing time
     */
    constructor(uint256 openingTime_, uint256 closingTime_) {
        // solhint-disable-next-line not-rely-on-time
        require(openingTime_ >= block.timestamp, 'TimedCrowdsale: opening time is before current time');
        // solhint-disable-next-line max-line-length
        require(closingTime_ > openingTime_, 'TimedCrowdsale: opening time is not before closing time');

        _openingTime = openingTime_;
        _closingTime = closingTime_;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view virtual override onlyWhileOpen {
        super._preValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), 'TimedCrowdsale: already closed');
        // solhint-disable-next-line max-line-length
        require(newClosingTime > _closingTime, 'TimedCrowdsale: new closing time is before current closing time');

        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './TimedCrowdsale.sol';

/**
 * @title PostVestingCrowdsale
 * @dev Crowdsale that start tokens vesting after the sale.
 */
abstract contract PostVestingCrowdsale is TimedCrowdsale {
    // Token amount bought by each beneficiary
    mapping(address => uint256) private _balances;
    // Token amount released by each beneficiary
    mapping(address => uint256) private _released;

    // Number of tokens sold
    uint256 private _tokensSold;
    // Number of tokens released
    uint256 private _tokensReleased;

    // Cliff timestamp
    uint256 private _cliff;
    // Vesting start timestamp
    uint256 private _start;
    // Vesting duration in seconds
    uint256 private _duration;
    // Percent of releasable tokens at the vesting start
    uint256 private _initialPercent;

    /**
     * Event for token release logging
     * @param beneficiary who got the tokens
     * @param amount amount of tokens released
     */
    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(
        uint256 startOffset_,
        uint256 cliffDuration_,
        uint256 duration_,
        uint256 initialPercent_
    ) {
        require(cliffDuration_ <= duration_, 'PostVestingCrowdsale: Cliff has to be lower or equal to duration');
        require(initialPercent_ <= 100, 'PostVestingCrowdsale: Initial percent has to be lower than 100%');
        _start = closingTime() + startOffset_;
        _cliff = _start + cliffDuration_;
        _duration = duration_;
        _initialPercent = initialPercent_;
    }

    /**
     * @return timestamp of the start of the vesting process
     */
    function vestingStart() public view returns (uint256) {
        return _start;
    }

    /**
     * @return timestamp of the vesting process cliff
     */
    function vestingCliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @return timestamp of the end of the vesting process
     */
    function vestingEnd() public view returns (uint256) {
        return _start + _duration;
    }

    /**
     * @return true if the process of vesting is ended
     */
    function isVestingEnded() public view returns (bool) {
        return block.timestamp >= vestingEnd();
    }

    /**
     * @param beneficiary Tokens beneficiary.
     * @return the number of tokens bought by beneficiary.
     */
    function tokensBought(address beneficiary) public view returns (uint256) {
        return _balances[beneficiary];
    }

    /**
     * @return the number of tokens sold.
     */
    function tokensSold() public view returns (uint256) {
        return _tokensSold;
    }

    /**
     * @return the number of tokens released.
     */
    function tokensReleased() public view returns (uint256) {
        return _tokensReleased;
    }

    /**
     * @param beneficiary Tokens beneficiary.
     * @return the number of tokens that is possible to release by beneficiary.
     */
    function releasableAmount(address beneficiary) public view returns (uint256) {
        return _vestedAmount(beneficiary) - _released[beneficiary];
    }

    /**
     * @dev Releases the token in an amount that is left to withdraw up to the current time.
     * @param beneficiary Tokens beneficiary.
     */
    function _releaseTokens(address beneficiary) internal {
        require(hasClosed(), 'PostVestingCrowdsale: not closed');
        require(
            _balances[beneficiary] - _released[beneficiary] > 0,
            'PostVestingCrowdsale: beneficiary is not due any tokens'
        );
        uint256 amount = releasableAmount(beneficiary);
        require(amount > 0, 'PostVestingCrowdsale: beneficiary tokens are vested');
        _released[beneficiary] = _released[beneficiary] + amount;
        _tokensReleased += amount;
        _deliverTokens(beneficiary, amount);
        emit TokensReleased(beneficiary, amount);
    }

    /**
     * @dev Calculates the vested amount of the token which is the total number of tokens
     * that can be released up to the current time.
     * @param beneficiary Tokens beneficiary.
     * @return the number of vested tokens.
     */
    function _vestedAmount(address beneficiary) internal view returns (uint256) {
        uint256 lastBlockTimestamp = block.timestamp;
        if (block.timestamp < _cliff) {
            return (_balances[beneficiary] * _initialPercent) / 100;
        } else if (lastBlockTimestamp >= vestingEnd()) {
            return _balances[beneficiary];
        } else {
            return (_balances[beneficiary] * (lastBlockTimestamp - _start)) / _duration;
        }
    }

    /**
     * @dev Overrides parent by storing due balances and updating total number of sold tokens.
     * @param beneficiary Token beneficiary
     * @param tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal virtual override {
        _balances[beneficiary] = _balances[beneficiary] + tokenAmount;
        _tokensSold = _tokensSold += tokenAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract WhitelistAccess is Context, AccessControl {
    /**
     * @dev Emitted when `account` is added to `whitelist`.
     */
    event WhitelistAdded(bytes32 indexed whitelist, address indexed account);

    /**
     * @dev Emitted when `account` is removed from `whitelist`.
     */
    event WhitelistRemoved(bytes32 indexed whitelist, address indexed account);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Modifier that checks that an account is present on `whitelist`.
     */
    modifier onlyWhitelisted(bytes32 whitelist) {
        require(_isWhitelisted(whitelist, _msgSender()), 'WhitelistAccess: caller is not whitelisted');
        _;
    }

    /**
     * @dev Returns `true` if `account` is present on `whitelist`.
     */
    function isWhitelisted(string memory whitelist, address account) public view returns (bool) {
        return _isWhitelisted(keccak256(abi.encodePacked(whitelist)), account);
    }

    /**
     * @dev Adds `account` to `whitelist`.
     *
     * If `account` had been added, emits a {WhitelistAdded} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function addToWhitelist(string memory whitelist, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _addWhitelisted(keccak256(abi.encodePacked(whitelist)), account);
    }

    /**
     * @dev Removes `account` from `whitelist`.
     *
     * If `account` had been removed, emits a {WhitelistRemoved} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function removeFromWhitelist(string memory whitelist, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeWhitelisted(keccak256(abi.encodePacked(whitelist)), account);
    }

    /**
     * @dev Adds multiple `accounts` to `whitelist`.
     *
     * For each of `accounts` if was added, emits a {WhitelistAdded} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function bulkAddToWhitelist(string memory whitelist, address[] memory accounts)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bytes32 _whitelist = keccak256(abi.encodePacked(whitelist));
        for (uint256 i = 0; i < accounts.length; i++) {
            _addWhitelisted(_whitelist, accounts[i]);
        }
    }

    /**
     * @dev Returns `true` if `account` is present on `whitelist`.
     */
    function _isWhitelisted(bytes32 whitelist, address account) internal view returns (bool) {
        return hasRole(whitelist, account);
    }

    /**
     * @dev Adds `account` to `whitelist`.
     */
    function _addWhitelisted(bytes32 whitelist, address account) internal {
        _setupRole(whitelist, account);
        emit WhitelistAdded(whitelist, account);
    }

    /**
     * @dev Removes `account` from `whitelist`.
     */
    function _removeWhitelisted(bytes32 whitelist, address account) internal {
        revokeRole(whitelist, account);
        emit WhitelistRemoved(whitelist, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

    constructor () {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

