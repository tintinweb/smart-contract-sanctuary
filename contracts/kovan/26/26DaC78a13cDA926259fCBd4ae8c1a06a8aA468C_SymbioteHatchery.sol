pragma solidity 0.5.15;
pragma experimental ABIEncoderV2;

import "./ISymbioteShareToken.sol";
import "../libraries/SafeMathUint256.sol";
import "../libraries/IERC20.sol";
import "../augur-para/IFeePot.sol";
import "../augur-para/IParaOICash.sol";
import "./ISymbioteShareTokenFactory.sol";
import "./IArbiter.sol";
import "./ISymbioteHatchery.sol";

contract SymbioteHatchery is ISymbioteHatchery {
    using SafeMathUint256 for uint256;

    uint256 private constant MIN_OUTCOMES = 2; // Does not Include Invalid
    uint256 private constant MAX_OUTCOMES = 7; // Does not Include Invalid
    uint256 private constant MAX_FEE = 2 * 10**16; // 2%
    address private constant NULL_ADDRESS = address(0);
    uint256 private constant MAX_UINT = 2**256 - 1;

    constructor(ISymbioteShareTokenFactory _tokenFactory, IFeePot _feePot) public {
        tokenFactory = _tokenFactory;
        feePot = _feePot;
        collateral = _feePot.collateral();
        collateral.approve(address(_feePot), MAX_UINT);
    }

    function createSymbiote(uint256 _creatorFee, string[] memory _outcomeSymbols, bytes32[] memory _outcomeNames, uint256 _numTicks, IArbiter _arbiter, bytes memory _arbiterConfiguration) public returns (uint256) {
        require(_numTicks.isMultipleOf(2), "SymbioteHatchery.createSymbiote: numTicks must be multiple of 2");
        require(_numTicks >= _outcomeSymbols.length, "SymbioteHatchery.createSymbiote: numTicks lower than numOutcomes");
        require(MIN_OUTCOMES <= _outcomeSymbols.length && _outcomeSymbols.length <= MAX_OUTCOMES, "SymbioteHatchery.createSymbiote: Number of outcomes is not acceptable");
        require(_outcomeSymbols.length == _outcomeNames.length, "SymbioteHatchery.createSymbiote: outcome names and outcome symbols differ in length");
        require(_creatorFee <= MAX_FEE, "SymbioteHatchery.createSymbiote: market creator fee too high");
        uint256 _id = symbiotes.length;
        {
            symbiotes.push(Symbiote(
                msg.sender,
                _creatorFee,
                _numTicks,
                _arbiter,
                tokenFactory.createShareTokens(_outcomeNames, _outcomeSymbols),
                0
            ));
        }
        _arbiter.onSymbioteCreated(_id, _outcomeSymbols, _outcomeNames, _numTicks, _arbiterConfiguration);
        emit SymbioteCreated(_id, _creatorFee, _outcomeSymbols, _outcomeNames, _numTicks, _arbiter, _arbiterConfiguration);
        return _id;
    }

    function getShareTokens(uint256 _id) external view returns (ISymbioteShareToken[] memory) {
        return symbiotes[_id].shareTokens;
    }

    function mintCompleteSets(uint256 _id, uint256 _amount, address _receiver) public returns (bool) {
        uint256 _numTicks = symbiotes[_id].numTicks;
        uint256 _cost = _amount.mul(_numTicks);
        collateral.transferFrom(msg.sender, address(this), _cost);
        for (uint256 _i = 0; _i < symbiotes[_id].shareTokens.length; _i++) {
            symbiotes[_id].shareTokens[_i].trustedMint(_receiver, _amount);
        }
        emit CompleteSetsMinted(_id, _amount, _receiver);
        return true;
    }

    function burnCompleteSets(uint256 _id, uint256 _amount, address _receiver) public returns (bool) {
        for (uint256 _i = 0; _i < symbiotes[_id].shareTokens.length; _i++) {
            symbiotes[_id].shareTokens[_i].trustedBurn(msg.sender, _amount);
        }
        uint256 _numTicks = symbiotes[_id].numTicks;
        payout(_id, _receiver, _amount.mul(_numTicks), false, false);
        emit CompleteSetsBurned(_id, _amount, msg.sender);
        return true;
    }

    function claimWinnings(uint256 _id) public returns (bool) {
        // We expect this to revert or return an empty array if the symbiote is not resolved
        uint256[] memory _winningPayout = symbiotes[_id].arbiter.getSymbioteResolution(_id);
        require(_winningPayout.length > 0, "market not resolved");
        uint256 _winningBalance = 0;
        for (uint256 _i = 0; _i < symbiotes[_id].shareTokens.length; _i++) {
            _winningBalance = _winningBalance.add(symbiotes[_id].shareTokens[_i].trustedBurnAll(msg.sender) * _winningPayout[_i]);
        }
        payout(_id, msg.sender, _winningBalance, true, _winningPayout[0] != 0);
        emit Claim(_id);
        return true;
    }

    function payout(uint256 _id, address _payee, uint256 _payout, bool _finalized, bool _invalid) private {
        uint256 _creatorFee = symbiotes[_id].creatorFee.mul(_payout) / 10**18;

        if (_finalized) {
            if (_invalid) {
                feePot.depositFees(_creatorFee + symbiotes[_id].creatorFees);
                symbiotes[_id].creatorFees = 0;
            } else {
                collateral.transfer(symbiotes[_id].creator, _creatorFee);
            }
        } else {
            symbiotes[_id].creatorFees = symbiotes[_id].creatorFees.add(_creatorFee);
        }

        collateral.transfer(_payee, _payout.sub(_creatorFee));
    }

    function withdrawCreatorFees(uint256 _id) external returns (bool) {
        // We expect this to revert if the symbiote is not resolved
        uint256[] memory _winningPayout = symbiotes[_id].arbiter.getSymbioteResolution(_id);
        require(_winningPayout.length > 0, "market not resolved");
        require(_winningPayout[0] == 0, "Can only withdraw creator fees from a valid market");

        collateral.transfer(symbiotes[_id].creator, symbiotes[_id].creatorFees);

        return true;
    }
}

pragma solidity 0.5.15;


interface ISymbioteShareToken {
    function trustedTransfer(address _from, address _to, uint256 _amount) external;
    function trustedMint(address _target, uint256 _amount) external;
    function trustedBurn(address _target, uint256 _amount) external;
    function trustedBurnAll(address _target) external returns (uint256);
}

pragma solidity 0.5.15;


/**
 * @title SafeMathUint256
 * @dev Uint256 math operations with safety checks that throw on error
 */
library SafeMathUint256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function subS(uint256 a, uint256 b, string memory message) internal pure returns (uint256) {
        require(b <= a, message);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            uint256 x = (y + 1) / 2;
            z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getUint256Min() internal pure returns (uint256) {
        return 0;
    }

    function getUint256Max() internal pure returns (uint256) {
        // 2 ** 256 - 1
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function isMultipleOf(uint256 a, uint256 b) internal pure returns (bool) {
        return a % b == 0;
    }

    // Float [fixed point] Operations
    function fxpMul(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, base), b);
    }
}

pragma solidity 0.5.15;


contract IERC20 {
    uint8 public decimals = 18;
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.5.15;

import "../libraries/IERC20.sol";
import "../libraries/IERC20DynamicSymbol.sol";


contract IFeePot is IERC20 {
    function depositFees(uint256 _amount) external returns (bool);
    function withdrawableFeesOf(address _owner) external view returns(uint256);
    function redeem() external returns (bool);
    function collateral() external view returns (IERC20);
    function reputationToken() external view returns (IERC20DynamicSymbol);
}

pragma solidity 0.5.15;

import "../libraries/IERC20.sol";
import "./IParaUniverse.sol";
import "./IParaAugur.sol";


contract IParaOICash is IERC20 {
    function deposit(uint256 _amount) external returns (bool);
    function withdraw(uint256 _amount) external returns (bool _alwaysTrue, uint256 _payout);
    function initialize(IParaAugur _augur, IParaUniverse _universe) external;
    function approveFeePot() external;
}

pragma solidity 0.5.15;
pragma experimental ABIEncoderV2;

import "./ISymbioteShareToken.sol";


interface ISymbioteShareTokenFactory {
    function createShareTokens(bytes32[] calldata _names, string[] calldata _symbols) external returns (ISymbioteShareToken[] memory tokens);
}

pragma solidity 0.5.15;
pragma experimental ABIEncoderV2;


contract IArbiter {
    function onSymbioteCreated(uint256 _id, string[] memory _outcomeSymbols, bytes32[] memory _outcomeNames, uint256 _numTicks, bytes memory _arbiterConfiguration) public;
    function getSymbioteResolution(uint256 _id) public returns (uint256[] memory);
}

pragma solidity 0.5.15;
pragma experimental ABIEncoderV2;

import "./ISymbioteShareToken.sol";
import "../libraries/Initializable.sol";
import "../libraries/SafeMathUint256.sol";
import "../libraries/IERC20.sol";
import "../augur-para/IFeePot.sol";
import "../augur-para/IParaOICash.sol";
import "./ISymbioteShareTokenFactory.sol";
import "./IArbiter.sol";

contract ISymbioteHatchery {
    struct Symbiote {
        address creator;
        uint256 creatorFee;
        uint256 numTicks;
        IArbiter arbiter;
        ISymbioteShareToken[] shareTokens;
        uint256 creatorFees;
    }

    Symbiote[] public symbiotes;
    ISymbioteShareTokenFactory public tokenFactory;
    IFeePot public feePot;
    IERC20 public collateral;

    event SymbioteCreated(uint256 id, uint256 creatorFee, string[] outcomeSymbols, bytes32[] outcomeNames, uint256 numTicks, IArbiter arbiter, bytes arbiterConfiguration);
    event CompleteSetsMinted(uint256 symbioteId, uint256 amount, address target);
    event CompleteSetsBurned(uint256 symbioteId, uint256 amount, address target);
    event Claim(uint256 symbioteId);

    function createSymbiote(uint256 _creatorFee, string[] memory _outcomeSymbols, bytes32[] memory _outcomeNames, uint256 _numTicks, IArbiter _arbiter, bytes memory _arbiterConfiguration) public returns (uint256);
    function getShareTokens(uint256 _id) external view returns (ISymbioteShareToken[] memory);
    function mintCompleteSets(uint256 _id, uint256 _amount, address _receiver) public returns (bool);
    function burnCompleteSets(uint256 _id, uint256 _amount, address _receiver) public returns (bool);
    function claimWinnings(uint256 _id) public returns (bool);
    function withdrawCreatorFees(uint256 _id) external returns (bool);
}

pragma solidity 0.5.15;

import "./IERC20.sol";


contract IERC20DynamicSymbol is IERC20 {
    function symbol() public view returns (string memory);
}

pragma solidity 0.5.15;

import "../augur-core/reporting/IV2ReputationToken.sol";
import "../augur-core/reporting/IMarket.sol";
import "../augur-core/reporting/IUniverse.sol";
import "./IFeePot.sol";


interface IParaUniverse {
    function augur() external view returns (address);
    function cash() external view returns (address);
    function openInterestCash() external view returns (address);
    function getFeePot() external view returns (IFeePot);
    function getReputationToken() external view returns (IV2ReputationToken);
    function originUniverse() external view returns (IUniverse);
    function setMarketFinalized(IMarket _market, uint256 _totalSupply) external returns (bool);
    function withdraw(address _recipient, uint256 _amount, address _market) external returns (bool);
    function deposit(address _sender, uint256 _amount, address _market) external returns (bool);
    function decrementOpenInterest(uint256 _amount) external returns (bool);
    function incrementOpenInterest(uint256 _amount) external returns (bool);
    function recordMarketCreatorFees(IMarket _market, uint256 _marketCreatorFees, address _sourceAccount) external returns (bool);
    function getMarketOpenInterest(IMarket _market) external view returns (uint256);
    function getOrCacheReportingFeeDivisor() external returns (uint256);
    function getReportingFeeDivisor() external view returns (uint256);
    function setOrigin(IUniverse _originUniverse) external;
}

pragma solidity 0.5.15;

import "../augur-core/reporting/IUniverse.sol";
import "../augur-core/ICash.sol";
import "../augur-core/reporting/IMarket.sol";
import "./IParaUniverse.sol";
import "./IOINexus.sol";
import "./IParaShareToken.sol";


contract IParaAugur {
    mapping(address => address) public getParaUniverse;

    ICash public cash;
    IParaShareToken public shareToken;
    IOINexus public OINexus;

    function generateParaUniverse(IUniverse _universe) external returns (IParaUniverse);
    function registerContract(bytes32 _key, address _address) external returns (bool);
    function lookup(bytes32 _key) external view returns (address);
    function isKnownUniverse(IUniverse _universe) external view returns (bool);
    function trustedCashTransfer(address _from, address _to, uint256 _amount) public returns (bool);
    function isKnownMarket(IMarket _market) public view returns (bool);
    function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) external returns (bool);
    function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets, uint256 _fees) external returns (bool);
    function logMarketOIChanged(IUniverse _universe, IMarket _market) external returns (bool);
    function logTradingProceedsClaimed(IUniverse _universe, address _sender, address _market, uint256 _outcome, uint256 _numShares, uint256 _numPayoutTokens, uint256 _fees) external returns (bool);
    function logShareTokensBalanceChanged(address _account, IMarket _market, uint256 _outcome, uint256 _balance) external returns (bool);
    function logReportingFeeChanged(uint256 _reportingFee) external returns (bool);
    function getTimestamp() public view returns (uint256);
}

pragma solidity 0.5.15;

import "./IReputationToken.sol";


contract IV2ReputationToken is IReputationToken {
    function parentUniverse() external returns (IUniverse);
    function burnForMarket(uint256 _amountToBurn) public returns (bool);
    function mintForWarpSync(uint256 _amountToMint, address _target) public returns (bool);
    function getLegacyRepToken() public view returns (IERC20);
}

pragma solidity 0.5.15;

import "../../libraries/IOwnable.sol";
import "../IAugur.sol";
import "./IInitialReporter.sol";
import "./IUniverse.sol";
import "./IDisputeWindow.sol";
import "./IV2ReputationToken.sol";
import "./IAffiliateValidator.sol";


contract IMarket is IOwnable {
    enum MarketType {
        YES_NO,
        CATEGORICAL,
        SCALAR
    }

    function initialize(IAugur _augur, IUniverse _universe, uint256 _endTime, uint256 _feePerCashInAttoCash, IAffiliateValidator _affiliateValidator, uint256 _affiliateFeeDivisor, address _designatedReporterAddress, address _creator, uint256 _numOutcomes, uint256 _numTicks) public;
    function derivePayoutDistributionHash(uint256[] memory _payoutNumerators) public view returns (bytes32);
    function doInitialReport(uint256[] memory _payoutNumerators, string memory _description, uint256 _additionalStake) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getDisputeWindow() public view returns (IDisputeWindow);
    function getNumberOfOutcomes() public view returns (uint256);
    function getNumTicks() public view returns (uint256);
    function getMarketCreatorSettlementFeeDivisor() public view returns (uint256);
    function getForkingMarket() public view returns (IMarket _market);
    function getEndTime() public view returns (uint256);
    function getWinningPayoutDistributionHash() public view returns (bytes32);
    function getWinningPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getWinningReportingParticipant() public view returns (IReportingParticipant);
    function getReputationToken() public view returns (IV2ReputationToken);
    function getFinalizationTime() public view returns (uint256);
    function getInitialReporter() public view returns (IInitialReporter);
    function getDesignatedReportingEndTime() public view returns (uint256);
    function getValidityBondAttoCash() public view returns (uint256);
    function affiliateFeeDivisor() external view returns (uint256);
    function getNumParticipants() public view returns (uint256);
    function getDisputePacingOn() public view returns (bool);
    function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256);
    function recordMarketCreatorFees(uint256 _marketCreatorFees, address _sourceAccount, bytes32 _fingerprint) public returns (bool);
    function isContainerForReportingParticipant(IReportingParticipant _reportingParticipant) public view returns (bool);
    function isFinalizedAsInvalid() public view returns (bool);
    function finalize() public returns (bool);
    function isFinalized() public view returns (bool);
    function isForkingMarket() public view returns (bool);
    function getOpenInterest() public view returns (uint256);
}

pragma solidity 0.5.15;

import "./IMarket.sol";
import "./IDisputeWindow.sol";
import "./IV2ReputationToken.sol";
import "./IReportingParticipant.sol";
import "./IAffiliateValidator.sol";

contract IUniverse {
    function creationTime() external view returns (uint256);
    function marketBalance(address) external view returns (uint256);

    function fork() public returns (bool);
    function updateForkValues() public returns (bool);
    function getParentUniverse() public view returns (IUniverse);
    function createChildUniverse(uint256[] memory _parentPayoutNumerators) public returns (IUniverse);
    function getChildUniverse(bytes32 _parentPayoutDistributionHash) public view returns (IUniverse);
    function getReputationToken() public view returns (IV2ReputationToken);
    function getForkingMarket() public view returns (IMarket);
    function getForkEndTime() public view returns (uint256);
    function getForkReputationGoal() public view returns (uint256);
    function getParentPayoutDistributionHash() public view returns (bytes32);
    function getDisputeRoundDurationInSeconds(bool _initial) public view returns (uint256);
    function getOrCreateDisputeWindowByTimestamp(uint256 _timestamp, bool _initial) public returns (IDisputeWindow);
    function getOrCreateCurrentDisputeWindow(bool _initial) public returns (IDisputeWindow);
    function getOrCreateNextDisputeWindow(bool _initial) public returns (IDisputeWindow);
    function getOrCreatePreviousDisputeWindow(bool _initial) public returns (IDisputeWindow);
    function getOpenInterestInAttoCash() public view returns (uint256);
    function getTargetRepMarketCapInAttoCash() public view returns (uint256);
    function getOrCacheValidityBond() public returns (uint256);
    function getOrCacheDesignatedReportStake() public returns (uint256);
    function getOrCacheDesignatedReportNoShowBond() public returns (uint256);
    function getOrCacheMarketRepBond() public returns (uint256);
    function getOrCacheReportingFeeDivisor() public returns (uint256);
    function getDisputeThresholdForFork() public view returns (uint256);
    function getDisputeThresholdForDisputePacing() public view returns (uint256);
    function getInitialReportMinValue() public view returns (uint256);
    function getPayoutNumerators() public view returns (uint256[] memory);
    function getReportingFeeDivisor() public view returns (uint256);
    function getPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getWinningChildPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function isOpenInterestCash(address) public view returns (bool);
    function isForkingMarket() public view returns (bool);
    function getCurrentDisputeWindow(bool _initial) public view returns (IDisputeWindow);
    function getDisputeWindowStartTimeAndDuration(uint256 _timestamp, bool _initial) public view returns (uint256, uint256);
    function isParentOf(IUniverse _shadyChild) public view returns (bool);
    function updateTentativeWinningChildUniverse(bytes32 _parentPayoutDistributionHash) public returns (bool);
    function isContainerForDisputeWindow(IDisputeWindow _shadyTarget) public view returns (bool);
    function isContainerForMarket(IMarket _shadyTarget) public view returns (bool);
    function isContainerForReportingParticipant(IReportingParticipant _reportingParticipant) public view returns (bool);
    function migrateMarketOut(IUniverse _destinationUniverse) public returns (bool);
    function migrateMarketIn(IMarket _market, uint256 _cashBalance, uint256 _marketOI) public returns (bool);
    function decrementOpenInterest(uint256 _amount) public returns (bool);
    function decrementOpenInterestFromMarket(IMarket _market) public returns (bool);
    function incrementOpenInterest(uint256 _amount) public returns (bool);
    function getWinningChildUniverse() public view returns (IUniverse);
    function isForking() public view returns (bool);
    function deposit(address _sender, uint256 _amount, address _market) public returns (bool);
    function withdraw(address _recipient, uint256 _amount, address _market) public returns (bool);
    function pokeRepMarketCapInAttoCash() public returns (uint256);
    function createScalarMarket(uint256 _endTime, uint256 _feePerCashInAttoCash, IAffiliateValidator _affiliateValidator, uint256 _affiliateFeeDivisor, address _designatedReporterAddress, int256[] memory _prices, uint256 _numTicks, string memory _extraInfo) public returns (IMarket _newMarket);
    function createYesNoMarket(uint256 _endTime, uint256 _feePerCashInAttoCash, IAffiliateValidator _affiliateValidator, uint256 _affiliateFeeDivisor, address _designatedReporterAddress, string memory _extraInfo) public returns (IMarket _newMarket);
    function createCategoricalMarket(uint256 _endTime, uint256 _feePerCashInAttoCash, IAffiliateValidator _affiliateValidator, uint256 _affiliateFeeDivisor, address _designatedReporterAddress, bytes32[] memory _outcomes, string memory _extraInfo) public returns (IMarket _newMarket);
    function runPeriodicals() external returns (bool);
}

pragma solidity 0.5.15;

import "../../libraries/IERC20.sol";
import "./IUniverse.sol";


contract IReputationToken is IERC20 {
    function migrateOutByPayout(uint256[] memory _payoutNumerators, uint256 _attotokens) public returns (bool);
    function migrateIn(address _reporter, uint256 _attotokens) public returns (bool);
    function trustedReportingParticipantTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedMarketTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedUniverseTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedDisputeWindowTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getTotalMigrated() public view returns (uint256);
    function getTotalTheoreticalSupply() public view returns (uint256);
    function mintForReportingParticipant(uint256 _amountMigrated) public returns (bool);
}

pragma solidity 0.5.15;

import "../../libraries/IERC20.sol";
import "../../libraries/ITyped.sol";
import "./IUniverse.sol";
import "../IAugur.sol";
import "./IReputationToken.sol";


contract IDisputeWindow is ITyped, IERC20 {
    function invalidMarketsTotal() external view returns (uint256);
    function validityBondTotal() external view returns (uint256);

    function incorrectDesignatedReportTotal() external view returns (uint256);
    function initialReportBondTotal() external view returns (uint256);

    function designatedReportNoShowsTotal() external view returns (uint256);
    function designatedReporterNoShowBondTotal() external view returns (uint256);

    function initialize(IAugur _augur, IUniverse _universe, uint256 _disputeWindowId, bool _participationTokensEnabled, uint256 _duration, uint256 _startTime) public;
    function trustedBuy(address _buyer, uint256 _attotokens) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getReputationToken() public view returns (IReputationToken);
    function getStartTime() public view returns (uint256);
    function getEndTime() public view returns (uint256);
    function getWindowId() public view returns (uint256);
    function isActive() public view returns (bool);
    function isOver() public view returns (bool);
    function onMarketFinalized() public;
    function redeem(address _account) public returns (bool);
}

pragma solidity 0.5.15;

import "./IMarket.sol";


contract IReportingParticipant {
    function getStake() public view returns (uint256);
    function getPayoutDistributionHash() public view returns (bytes32);
    function liquidateLosing() public;
    function redeem(address _redeemer) public returns (bool);
    function isDisavowed() public view returns (bool);
    function getPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getPayoutNumerators() public view returns (uint256[] memory);
    function getMarket() public view returns (IMarket);
    function getSize() public view returns (uint256);
}

pragma solidity 0.5.15;


contract IAffiliateValidator {
    function validateReference(address _account, address _referrer) external view returns (bool);
}

pragma solidity 0.5.15;


contract IOwnable {
    function getOwner() public view returns (address);
    function transferOwnership(address _newOwner) public returns (bool);
}

pragma solidity 0.5.15;

import "./reporting/IUniverse.sol";
import "./reporting/IMarket.sol";
import "./reporting/IDisputeWindow.sol";
import "./ICash.sol";

contract IAugur {
    IUniverse public genesisUniverse;
    function createChildUniverse(bytes32 _parentPayoutDistributionHash, uint256[] memory _parentPayoutNumerators) public returns (IUniverse);
    function isKnownUniverse(IUniverse _universe) public view returns (bool);
    function trustedCashTransfer(address _from, address _to, uint256 _amount) public returns (bool);
    function isTrustedSender(address _address) public returns (bool);
    function onCategoricalMarketCreated(uint256 _endTime, string memory _extraInfo, IMarket _market, address _marketCreator, address _designatedReporter, uint256 _feePerCashInAttoCash, bytes32[] memory _outcomes) public returns (bool);
    function onYesNoMarketCreated(uint256 _endTime, string memory _extraInfo, IMarket _market, address _marketCreator, address _designatedReporter, uint256 _feePerCashInAttoCash) public returns (bool);
    function onScalarMarketCreated(uint256 _endTime, string memory _extraInfo, IMarket _market, address _marketCreator, address _designatedReporter, uint256 _feePerCashInAttoCash, int256[] memory _prices, uint256 _numTicks)  public returns (bool);
    function logInitialReportSubmitted(IUniverse _universe, address _reporter, address _market, address _initialReporter, uint256 _amountStaked, bool _isDesignatedReporter, uint256[] memory _payoutNumerators, string memory _description, uint256 _nextWindowStartTime, uint256 _nextWindowEndTime) public returns (bool);
    function disputeCrowdsourcerCreated(IUniverse _universe, address _market, address _disputeCrowdsourcer, uint256[] memory _payoutNumerators, uint256 _size, uint256 _disputeRound) public returns (bool);
    function logDisputeCrowdsourcerContribution(IUniverse _universe, address _reporter, address _market, address _disputeCrowdsourcer, uint256 _amountStaked, string memory description, uint256[] memory _payoutNumerators, uint256 _currentStake, uint256 _stakeRemaining, uint256 _disputeRound) public returns (bool);
    function logDisputeCrowdsourcerCompleted(IUniverse _universe, address _market, address _disputeCrowdsourcer, uint256[] memory _payoutNumerators, uint256 _nextWindowStartTime, uint256 _nextWindowEndTime, bool _pacingOn, uint256 _totalRepStakedInPayout, uint256 _totalRepStakedInMarket, uint256 _disputeRound) public returns (bool);
    function logInitialReporterRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256[] memory _payoutNumerators) public returns (bool);
    function logDisputeCrowdsourcerRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256[] memory _payoutNumerators) public returns (bool);
    function logMarketFinalized(IUniverse _universe, uint256[] memory _winningPayoutNumerators) public returns (bool);
    function logMarketMigrated(IMarket _market, IUniverse _originalUniverse) public returns (bool);
    function logReportingParticipantDisavowed(IUniverse _universe, IMarket _market) public returns (bool);
    function logMarketParticipantsDisavowed(IUniverse _universe) public returns (bool);
    function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public returns (bool);
    function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets, uint256 _fees) public returns (bool);
    function logMarketOIChanged(IUniverse _universe, IMarket _market) public returns (bool);
    function logTradingProceedsClaimed(IUniverse _universe, address _sender, address _market, uint256 _outcome, uint256 _numShares, uint256 _numPayoutTokens, uint256 _fees) public returns (bool);
    function logUniverseForked(IMarket _forkingMarket) public returns (bool);
    function logReputationTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value, uint256 _fromBalance, uint256 _toBalance) public returns (bool);
    function logReputationTokensBurned(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logReputationTokensMinted(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logShareTokensBalanceChanged(address _account, IMarket _market, uint256 _outcome, uint256 _balance) public returns (bool);
    function logDisputeCrowdsourcerTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value, uint256 _fromBalance, uint256 _toBalance) public returns (bool);
    function logDisputeCrowdsourcerTokensBurned(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logDisputeCrowdsourcerTokensMinted(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logDisputeWindowCreated(IDisputeWindow _disputeWindow, uint256 _id, bool _initial) public returns (bool);
    function logParticipationTokensRedeemed(IUniverse universe, address _sender, uint256 _attoParticipationTokens, uint256 _feePayoutShare) public returns (bool);
    function logTimestampSet(uint256 _newTimestamp) public returns (bool);
    function logInitialReporterTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool);
    function logMarketTransferred(IUniverse _universe, address _from, address _to) public returns (bool);
    function logParticipationTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value, uint256 _fromBalance, uint256 _toBalance) public returns (bool);
    function logParticipationTokensBurned(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logParticipationTokensMinted(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logMarketRepBondTransferred(address _universe, address _from, address _to) public returns (bool);
    function logWarpSyncDataUpdated(address _universe, uint256 _warpSyncHash, uint256 _marketEndTime) public returns (bool);
    function isKnownFeeSender(address _feeSender) public view returns (bool);
    function lookup(bytes32 _key) public view returns (address);
    function getTimestamp() public view returns (uint256);
    function getMaximumMarketEndDate() public returns (uint256);
    function isKnownMarket(IMarket _market) public view returns (bool);
    function derivePayoutDistributionHash(uint256[] memory _payoutNumerators, uint256 _numTicks, uint256 numOutcomes) public view returns (bytes32);
    function logValidityBondChanged(uint256 _validityBond) public returns (bool);
    function logDesignatedReportStakeChanged(uint256 _designatedReportStake) public returns (bool);
    function logNoShowBondChanged(uint256 _noShowBond) public returns (bool);
    function logReportingFeeChanged(uint256 _reportingFee) public returns (bool);
    function getUniverseForkIndex(IUniverse _universe) public view returns (uint256);
    function getMarketType(IMarket _market) public view returns (IMarket.MarketType);
    function getMarketOutcomes(IMarket _market) public view returns (bytes32[] memory _outcomes);
    ICash public cash;
}

pragma solidity 0.5.15;

import "../IAugur.sol";
import "./IReportingParticipant.sol";
import "../../libraries/IOwnable.sol";

contract IInitialReporter is IReportingParticipant, IOwnable {
    function initialize(IAugur _augur, IMarket _market, address _designatedReporter) public;
    function report(address _reporter, bytes32 _payoutDistributionHash, uint256[] memory _payoutNumerators, uint256 _initialReportStake) public;
    function designatedReporterShowed() public view returns (bool);
    function initialReporterWasCorrect() public view returns (bool);
    function getDesignatedReporter() public view returns (address);
    function getReportTimestamp() public view returns (uint256);
    function migrateToNewUniverse(address _designatedReporter) public;
    function returnRepFromDisavow() public;
}

pragma solidity 0.5.15;

import "../libraries/IERC20.sol";


contract ICash is IERC20 {
    function faucet(uint256 _amount) public returns (bool);
}

pragma solidity 0.5.15;


contract ITyped {
    function getTypeName() public view returns (bytes32);
}

pragma solidity 0.5.15;

import "../augur-core/reporting/IUniverse.sol";
import "./IParaUniverse.sol";


contract IOINexus {
    function getAttoCashPerRep(address _cash, address _reputationToken) public returns (uint256);
    function universeReportingFeeDivisor(address _universe) external returns (uint256);
    function addParaAugur(address _paraAugur) external returns (bool);
    function registerParaUniverse(IUniverse _universe, IParaUniverse _paraUniverse) external;
    function recordParaUniverseValuesAndUpdateReportingFee(IUniverse _universe, uint256 _targetRepMarketCapInAttoCash, uint256 _repMarketCapInAttoCash) external returns (uint256);
}

pragma solidity 0.5.15;

import "../augur-core/ICash.sol";
import "../augur-core/reporting/IMarket.sol";
import "./IParaUniverse.sol";

interface IParaShareToken {
    function cash() external view returns (ICash);
    function augur() external view returns (address);
    function initialize(address _augur, address _originalShareToken) external;
    function approveUniverse(IParaUniverse _paraUniverse) external;
    function buyCompleteSets(IMarket _market, address _account, uint256 _amount) external returns (bool);
    function claimTradingProceeds(IMarket _market, address _shareHolder, bytes32 _fingerprint) external returns (uint256[] memory _outcomeFees);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function setApprovalForAll(address operator, bool approved) external;
    function publicSellCompleteSets(IMarket _market, uint256 _amount) external returns (uint256 _creatorFee, uint256 _reportingFee);
    function sellCompleteSets(IMarket _market, address _holder, address _recipient, uint256 _amount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee);
    function publicBuyCompleteSets(IMarket _market, uint256 _amount) external returns (bool);
    function getTokenId(IMarket _market, uint256 _outcome) external pure returns (uint256 _tokenId);
    function unsafeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) external;
    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory balances_);
    function unsafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external;
    function getMarket(uint256 _tokenId) external pure returns(IMarket);
    function isMarketInitialized(IMarket _market) external view returns (bool);
    function initializeMarket(IMarket _market) external;
}

pragma solidity 0.5.15;


contract Initializable {
    bool private initialized = false;

    modifier beforeInitialized {
        require(!initialized);
        _;
    }

    function endInitialization() internal beforeInitialized {
        initialized = true;
    }

    function getInitialized() public view returns (bool) {
        return initialized;
    }
}