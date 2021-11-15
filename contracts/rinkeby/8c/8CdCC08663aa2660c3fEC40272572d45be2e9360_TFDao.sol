// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;

import '../utils/SafeMath.sol';
import '../utils/SafeMath64.sol';
import '../utils/TCPSafeMath.sol';
import '../utils/TCPSafeCast.sol';
import '../utils/Time.sol';
import './interfaces/ITFDao.sol';
import '../interfaces/IPositionNFT.sol';
import '../governance/GovernorAlpha.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';


contract TFDao is ITFDao, PeriodTime(24 hours), ReentrancyGuard {
    using SafeMath64 for uint64;
    using SafeMath for uint256;
    using TCPSafeMath for uint64;
    using TCPSafeMath for uint256;
    using TCPSafeCast for uint64;
    using TCPSafeCast for uint256;

    
    
    
    
    
    address public incentiveContract;

    
    address public immutable timelock;

    
    GovernorAlpha public tfGovernorAlpha;

    
    IProtocolToken public tfToken;

    
    IPositionNFT public tfPositionNFT;


    
    
    uint internal constant TOKENS_PER_DAY = 1e23; 
    
    uint internal constant INCENTIVE_TOKENS_PER_DAY = 1e22; 
    
    uint64 internal constant MIN_MONTHS = 6;
    
    uint64 internal constant MAX_MONTHS = 48;
    
    uint64 internal constant MONTH_INCREMENTS = 6;


    
    
    uint64 public lastPeriodGlobalInflationUpdated = 1;
    
    mapping(uint16 => TokenRewardsStatusStorage) public rewardsStatus;
    
    
    
    
    mapping(uint16 => uint) public virtualCount;

    
    uint16 internal countUnderlyingProtocolTokens;
    
    mapping(IProtocolToken => uint16) public tokenToID;
    
    mapping(uint16 => IProtocolToken) public idToToken;
    
    mapping(uint64 => TokenPositionStorage) public positions;
    
    mapping(bytes4 => bool) public blacklistedAction;


    
    
    
    address public deployer;
    
    
    address public multisig;
    
    uint64 public startPeriod;
    
    
    uint64 public incentivesStartPeriod;
    
    uint public totalIncentivesMinted;

    constructor(address _timelock, address _multisig, IProtocolToken _initialToken) {
        deployer = msg.sender;

        timelock = _timelock;
        multisig = _multisig;

        _addToken(_initialToken);
    }

    
    function init(IPositionNFT _tfPositionNFT, IProtocolToken _tfToken, GovernorAlpha _tfGovernorAlpha) external {
        _requireAuthorized(msg.sender == deployer);
        delete deployer;

        tfPositionNFT = _tfPositionNFT;
        tfToken = _tfToken;
        tfGovernorAlpha = _tfGovernorAlpha;

        
        _blacklistAction(IERC20.transfer.selector);
        _blacklistAction(IERC20.transferFrom.selector);
        _blacklistAction(IERC20.approve.selector);

        
        _blacklistAction(IProtocolToken.mintTo.selector);
        _blacklistAction(IProtocolToken.burnFrom.selector);
        _blacklistAction(IProtocolToken.burn.selector);
        _blacklistAction(IProtocolToken.increaseAllowance.selector);
        _blacklistAction(IProtocolToken.decreaseAllowance.selector);
        _blacklistAction(IProtocolToken.addGovernor.selector);
        _blacklistAction(IProtocolToken.delegate.selector);
    }

    function _blacklistAction(bytes4 action) internal {
        blacklistedAction[action] = true;
    }

    
    
    
    function dailyProtocolTFIncentiveCount() public view returns (uint) {
        if (startPeriod == 0) return 0;
        if (incentiveContract != address(0)) return TOKENS_PER_DAY - INCENTIVE_TOKENS_PER_DAY;
        return TOKENS_PER_DAY;
    }

    
    
    function setIncentiveContract(address _contract) external onlyThis {
        require(incentiveContract == address(0), 'Contract already set');
        require(Address.isContract(_contract), 'Not a contract');

        incentiveContract = _contract;
        incentivesStartPeriod = _currentPeriod();

        emit LiquidationIncentiveContractSet(_contract);
    }

    
    function addToken(IProtocolToken token) external onlyThis {
        _addToken(token);
    }

    
    function mintIncentive(address dest, uint count) external onlyThis {
        require(count <= tfToken.totalSupply() / 50, 'More than 2% of supply');
        require(Address.isContract(dest), 'Not a contract');

        tfToken.mintTo(dest, count);

        emit IncentiveMinted(dest, count);
    }

    
    function start() external {
        _requireAuthorized(msg.sender == multisig);
        delete multisig;

        _accrueInflation();
        startPeriod = _currentPeriod();

        emit TFDaoStarted();
    }

    
    
    function execute(
        address target,
        string memory signature,
        bytes memory data
    ) external nonReentrant returns (bool success, bytes memory returnData) {
        
        _requireAuthorized(msg.sender == timelock);

        bytes4 action = _sig4(signature);

        require(!blacklistedAction[action], 'Action blacklisted');

        
        (success, returnData) = target.call(abi.encodePacked(action, data));

        require(success, string(returnData));
    }

    function voteInUnderlyingProtocol(GovernorAlpha, uint) public pure override {}

    function executeMetaProposalVote(uint metaProposalID) external {
        
        (uint128 forVotes, uint128 againstVotes, uint128 availableVotingTokens, bytes memory callData) =
            _validateMetaProposal(metaProposalID);

        
        bool moreForThanAgainst = forVotes > againstVotes;
        uint quorumVotesThreshold = uint(availableVotingTokens)._mul(tfGovernorAlpha.QUORUM_VOTES_PERCENTAGE());

        moreForThanAgainst
            ? require(forVotes > quorumVotesThreshold, 'Insufficient for votes')
            : require(againstVotes > quorumVotesThreshold, 'Insufficient against votes');

        
        (address ga, uint proposalID) = abi.decode(callData, (address, uint));

        IGovernorAlpha(ga).castVote(proposalID, moreForThanAgainst);

        emit MetaGovernanceDecisionExecuted(address(ga), proposalID, moreForThanAgainst);
    }

    function _validateMetaProposal(
        uint metaProposalID
    ) internal view returns (uint128, uint128, uint128, bytes memory) {
        require(metaProposalID > 0, 'Noop');

        (   ,,,
            uint48 id,
            uint128 forVotes,
            ,,,,
            uint128 againstVotes,
            uint128 availableVotingTokens
        ) = tfGovernorAlpha.proposals(metaProposalID);

        require(id > 0, 'Meta proposal DNE');

        GovernorAlpha.ProposalState state = tfGovernorAlpha.state(metaProposalID);

        require(
            state == GovernorAlpha.ProposalState.Succeeded
            || state == GovernorAlpha.ProposalState.Defeated
            || state == GovernorAlpha.ProposalState.Queued
            || state == GovernorAlpha.ProposalState.Executed,
            'Invalid proposal state');

        (address[] memory targets, string[] memory signatures, bytes[] memory calldatas) =
            tfGovernorAlpha.getActions(metaProposalID);

        require(targets.length == 1, 'Too many actions');
        require(targets[0] == address(this), 'Incorrect target');
        require(_sig4(signatures[0]) == ITFDao.voteInUnderlyingProtocol.selector, 'Invalid sig');

        return (forVotes, againstVotes, availableVotingTokens, calldatas[0]);
    }

    
    function _sig4(string memory signature) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(signature)));
    }

    
    function _addToken(IProtocolToken token) internal {
        require(countUnderlyingProtocolTokens < type(uint16).max);

        countUnderlyingProtocolTokens++;

        idToToken[countUnderlyingProtocolTokens] = token;
        tokenToID[token] = countUnderlyingProtocolTokens;

        token.delegate(address(this));

        emit TokenAdded(address(token));
    }

    
    modifier onlyThis() {
        _requireAuthorized(msg.sender == address(this));
        _;
    }

    
    function _requireAuthorized(bool authorized) internal pure {
        require(authorized, 'Not Authorized');
    }

    
    
    function availableSupply() external view override returns (uint) {
        uint64 _startPeriod = startPeriod;
        if (_startPeriod == 0) return 0;
        return uint((_currentPeriod() + 1).sub(_startPeriod)).mul(TOKENS_PER_DAY);
    }

    
    function incentiveContractMint(address dest, uint count) external override nonReentrant {
        _requireAuthorized(msg.sender == incentiveContract);

        uint newTotalIncentivesMinted = totalIncentivesMinted.add(count);

        uint maxTotalIncentives =
            uint((_currentPeriod() + 1).sub(incentivesStartPeriod)).mul(INCENTIVE_TOKENS_PER_DAY);
        require(newTotalIncentivesMinted <= maxTotalIncentives, 'Allotment exceeded');

        totalIncentivesMinted = newTotalIncentivesMinted;

        tfToken.mintTo(dest, count);
    }

    
    
    function lockTokens(
        IProtocolToken token,
        uint count,
        uint8 lockDurationMonths,
        address to
    ) external nonReentrant returns(uint64 positionNFTTokenID) {
        
        uint16 _tokenID = tokenToID[token];
        require(_tokenID > 0, 'Unsupported token');
        require(count > 0, 'Noop');
        require(
            MIN_MONTHS <= lockDurationMonths &&
            lockDurationMonths <= MAX_MONTHS &&
            lockDurationMonths % MONTH_INCREMENTS == 0, 'Invalid lock duration');

        
        _accrueInflation();

        
        TokenRewardsStatus memory rs = _getRewardsStatus(_tokenID);

        
        virtualCount[_tokenID] = virtualCount[_tokenID].add(_virtualCount(count, lockDurationMonths));

        positionNFTTokenID = tfPositionNFT.mintTo(to);

        uint64 currentPeriod = _currentPeriod();

        
        _storePosition(positionNFTTokenID, TokenPosition({
            count: count,
            startTotalRewards: rs.totalRewards,
            startCumulativeVirtualCount: rs.cumulativeVirtualCount,
            lastPeriodUpdated: currentPeriod,
            endPeriod: currentPeriod.add(_monthsToDays(lockDurationMonths)),
            durationMonths: lockDurationMonths,
            tokenID: _tokenID
        }));

        
        TransferHelper.safeTransferFrom(address(token), msg.sender, address(this), count);

        emit TokensLocked(_tokenID, to, lockDurationMonths, count);

        return positionNFTTokenID;
    }

    
    function getRewards(uint64 positionNFTTokenID) external nonReentrant {
        _requireAuthorized(tfPositionNFT.isApprovedOrOwner(msg.sender, positionNFTTokenID));

        TokenPosition memory position = _distributeRewardsAndGetUpdatedPosition(positionNFTTokenID);

        _storePosition(positionNFTTokenID, position);

        emit RewardsClaimed(positionNFTTokenID, msg.sender);
    }

    
    function unlockTokens(uint64 positionNFTTokenID) external nonReentrant {
        address msgSender = msg.sender;
        _requireAuthorized(tfPositionNFT.isApprovedOrOwner(msgSender, positionNFTTokenID));

        TokenPosition memory position = _distributeRewardsAndGetUpdatedPosition(positionNFTTokenID);
        require(position.endPeriod <= _currentPeriod(), 'Still locked');

        virtualCount[position.tokenID] =
            virtualCount[position.tokenID].sub(_virtualCount(position.count, position.durationMonths));

        delete positions[positionNFTTokenID];

        address dest = tfPositionNFT.ownerOf(positionNFTTokenID);

        tfPositionNFT.burn(positionNFTTokenID);

        emit TokensUnlocked(position.tokenID, msgSender, position.count);

        
        TransferHelper.safeTransfer(address(idToToken[position.tokenID]), dest, position.count);
    }

    
    function accrueInflation() external nonReentrant {
        _accrueInflation();
    }

    
    
    
    function _distributeRewardsAndGetUpdatedPosition(
        uint64 positionNFTTokenID
    ) internal returns (TokenPosition memory position) {
        position = _getPosition(positionNFTTokenID);
        
        require(position.count > 0, 'Position DNE');

        
        _accrueInflation();

        
        if (position.lastPeriodUpdated >= lastPeriodGlobalInflationUpdated) return position;

        TokenRewardsStatus memory rs = _getRewardsStatus(position.tokenID);

        
        
        
        uint avgVirtualCountPerPeriod =
            rs.cumulativeVirtualCount.sub(position.startCumulativeVirtualCount)
                / (lastPeriodGlobalInflationUpdated - position.lastPeriodUpdated);

        
        
        uint rewards = _virtualCount(position.count, position.durationMonths).mulDiv(
            rs.totalRewards.sub(position.startTotalRewards),
            avgVirtualCountPerPeriod);

        
        if (rewards > 0) tfToken.mintTo(tfPositionNFT.ownerOf(positionNFTTokenID), rewards);

        
        position.startTotalRewards = rs.totalRewards;
        position.startCumulativeVirtualCount = rs.cumulativeVirtualCount;
        position.lastPeriodUpdated = _currentPeriod();

        
        
        return position;
    }

    
    
    function _accrueInflation() internal {
        uint64 currentPeriod = _currentPeriod();
        if (currentPeriod <= lastPeriodGlobalInflationUpdated) return;

        uint64 periods = currentPeriod - lastPeriodGlobalInflationUpdated;

        uint _countTokens = countUnderlyingProtocolTokens;
        
        uint rewardsPerToken = dailyProtocolTFIncentiveCount().mul(periods) / _countTokens;

        TokenRewardsStatus memory rs;

        for(uint16 _tokenID = 1; _tokenID <= _countTokens; _tokenID++) {
            rs = _getRewardsStatus(_tokenID);
            
            rewardsStatus[_tokenID] = TokenRewardsStatusStorage({
                cumulativeVirtualCount: rs.cumulativeVirtualCount.add(virtualCount[_tokenID].mul(periods)).toUint128(),
                totalRewards: rs.totalRewards.add(rewardsPerToken).toUint128()
            });
        }

        
        lastPeriodGlobalInflationUpdated = currentPeriod;

        emit InflationAccrued(currentPeriod, periods);
    }

    
    function _virtualCount(uint count, uint64 durationMonths) internal pure returns (uint) {
        return count.mulDiv(durationMonths, 12);
    }

    
    function _monthsToDays(uint64 months) internal pure returns (uint64) {
        return months.mul(365) / 12;
    }

    
    function _getRewardsStatus(uint16 _tokenID) internal view returns (TokenRewardsStatus memory) {
        TokenRewardsStatusStorage memory statusStorage = rewardsStatus[_tokenID];
        return TokenRewardsStatus({
            cumulativeVirtualCount: statusStorage.cumulativeVirtualCount,
            totalRewards: statusStorage.totalRewards
        });
    }

    
    function _getPosition(uint64 positionNFTTokenID) internal view returns (TokenPosition memory) {
        TokenPositionStorage memory tpStorage = positions[positionNFTTokenID];
        return TokenPosition({
            count: tpStorage.count,
            startTotalRewards:  tpStorage.startTotalRewards,
            startCumulativeVirtualCount:  tpStorage.startCumulativeVirtualCount,
            lastPeriodUpdated:  tpStorage.lastPeriodUpdated,
            endPeriod:  tpStorage.endPeriod,
            durationMonths:  tpStorage.durationMonths,
            tokenID:  tpStorage.tokenID
        });
    }

    
    function _storePosition(uint64 positionNFTTokenID, TokenPosition memory _position) internal {
        positions[positionNFTTokenID] = TokenPositionStorage({
            count: _position.count.toUint128(),
            startTotalRewards: _position.startTotalRewards.toUint128(),
            startCumulativeVirtualCount: _position.startCumulativeVirtualCount.toUint184(),
            lastPeriodUpdated: _position.lastPeriodUpdated.toUint16(),
            endPeriod: _position.endPeriod.toUint16(),
            durationMonths: _position.durationMonths.toUint8(),
            tokenID: _position.tokenID
        });
    }

}

interface IGovernorAlpha {
     function castVote(uint proposalId, bool support) external;
}

interface IProtocolToken is IERC20 {
    function delegate(address delegatee) external;
    function mintTo(address dest, uint count) external;
    function burnFrom(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function addGovernor(address newGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'mul-overflow');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



library SafeMath64 {
    function add(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require((z = x + y) >= x, 'add-overflow');
    }

    function sub(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require((z = x - y) <= x, 'sub-underflow');
    }

    function mul(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require(y == 0 || (z = x * y) / y == x, 'mul-overflow');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



library TCPSafeMath {
    
    
    
    
    
    
    
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        
        
        
        
        
        uint256 prod0; 
        uint256 prod1; 
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        
        
        require(denominator > prod1);

        
        
        

        
        
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        
        
        
        uint256 twos = -denominator & denominator;
        
        assembly {
            denominator := div(denominator, twos)
        }

        
        assembly {
            prod0 := div(prod0, twos)
        }
        
        
        
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        
        
        
        
        
        uint256 inv = (3 * denominator) ^ 2;
        
        
        
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 

        
        
        
        
        
        
        result = prod0 * inv;
        return result;
    }


    
    
    uint256 public constant ONE = 1e18;

    
    function _div(uint256 a, uint256 b) internal pure returns (uint256 r) {
        r = mulDiv(a, ONE, b);
    }

    
    function _mul(uint256 a, uint256 b) internal pure returns (uint256 r) {
        r = mulDiv(a, b, ONE);
    }
}

// SPDX-License-Identifier: MIT
// NOTE: modified compiler version to 0.7.4 and added toUint192, toUint160, and toUint96

pragma solidity =0.7.6;



library TCPSafeCast {
    
    
    

    
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value < 2**192, "more than 192 bits");
        return uint192(value);
    }

    
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value < 2**184, "more than 184 bits");
        return uint184(value);
    }

    
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value < 2**176, "more than 176 bits");
        return uint176(value);
    }

    
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value < 2**160, "more than 160 bits");
        return uint160(value);
    }

    
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "more than 128 bits");
        return uint128(value);
    }

    
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value < 2**96, "more than 96 bits");
        return uint96(value);
    }

    
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "more than 64 bits");
        return uint64(value);
    }

    
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value < 2**48, "more than 48 bits");
        return uint48(value);
    }

    
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "more than 40 bits");
        return uint40(value);
    }

    
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "more than 32 bits");
        return uint32(value);
    }

    
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "more than 16 bits");
        return uint16(value);
    }

    
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "more than 8 bits");
        return uint8(value);
    }

    
    
    
    
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "more than 128 bits");
        return int128(value);
    }

    
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "more than 64 bits");
        return int64(value);
    }

    
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "more than 32 bits");
        return int32(value);
    }

    
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= -2**23 && value < 2**23, "more than 24 bits");
        return int24(value);
    }

    
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "more than 16 bits");
        return int16(value);
    }

    
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "more than 8 bits");
        return int8(value);
    }

    
    
    
    
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "value not positive");
        return uint256(value);
    }


    
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "too big for int256");
        return int256(value);
    }
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import './TCPSafeCast.sol';
import './SafeMath64.sol';



abstract contract Time {
    using SafeMath64 for uint64;
    using TCPSafeCast for uint256;

    
    function _currentTime() internal view returns (uint64 time) {
        time = block.timestamp.toUint64();
    }

    
    function _futureTime(uint64 addition) internal view returns (uint64 time) {
        time = _currentTime().add(addition);
    }
}


abstract contract PeriodTime is Time {
    using SafeMath64 for uint64;

    
    uint64 public immutable periodLength;
    
    uint64 public immutable firstPeriod;

    
    constructor (uint64 _periodLength) {
        firstPeriod = (_currentTime() / _periodLength) - 1;
        periodLength = _periodLength;
    }

    
    function currentPeriod() external view returns (uint64 period) {
        period = _currentPeriod();
    }

    
    function _currentPeriod() internal view returns (uint64 period) {
        period = (_currentTime() / periodLength) - firstPeriod;
    }

    
    function _periodToTime(uint64 period) internal view returns (uint64 time) {
        time = periodLength.mul(firstPeriod.add(period));
    }

    
    function _timeToPeriod(uint64 time) internal view returns (uint64 period) {
        period = (time / periodLength).sub(firstPeriod);
    }
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '../../governance/GovernorAlpha.sol';


interface ITFDao {
    
    function availableSupply() external view returns (uint);
    function incentiveContractMint(address dest, uint count) external;
    function voteInUnderlyingProtocol(GovernorAlpha, uint) external pure;

    
    struct TokenRewardsStatus {
        uint cumulativeVirtualCount;
        uint totalRewards;
    }

    struct TokenRewardsStatusStorage {
        uint128 cumulativeVirtualCount;
        uint128 totalRewards;
    }

    struct TokenPosition {
        uint count;
        uint startTotalRewards;
        uint startCumulativeVirtualCount;
        uint64 lastPeriodUpdated;
        uint64 endPeriod;
        uint64 durationMonths;
        uint16 tokenID;
    }

    struct TokenPositionStorage {
        uint128 count;
        uint128 startTotalRewards;
        uint184 startCumulativeVirtualCount;
        uint16 lastPeriodUpdated;
        uint16 endPeriod;
        uint16 tokenID;
        uint8 durationMonths;
    }

    
    
    event LiquidationIncentiveContractSet(address indexed _contract);
    event TokenAdded(address indexed token);
    event IncentiveMinted(address indexed token, uint count);
    event TFDaoStarted();
    event MetaGovernanceDecisionExecuted(address indexed governorAlpha, uint indexed proposalID, bool indexed decision);

    
    event TokensLocked(
        uint16 indexed tokenID,
        address indexed initialOwner,
        uint8 indexed lockDurationMonths,
        uint count);
    event RewardsClaimed(uint64 indexed positionNFTTokenID, address indexed owner);
    event TokensUnlocked(uint16 indexed tokenID, address indexed owner, uint count);

    
    event InflationAccrued(uint64 indexed currentPeriod, uint64 periods);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';



interface IPositionNFT is IERC721, IERC721Metadata {
    
    function mintTo(address to) external returns (uint64 id);
    function burn(uint64 tokenID) external;

    
    function isApprovedOrOwner(address account, uint tokenId) external view returns (bool r);
    function positionIDs(address account) external view returns (uint64[] memory IDs);
    function nextPositionID() external view returns (uint64 ID);
}

// SPDX-License-Identifier: BSD-3-Clause












pragma solidity =0.7.6;
pragma abicoder v2;


abstract contract GovernorAlpha {
    
    
    string public name;

    
    
    uint128 public constant QUORUM_VOTES_PERCENTAGE = 0.03e18; 

    
    
    uint128 public constant PROPOSAL_THRESHOLD_PERCENTAGE = 0.005e18; 

    
    
    function proposalThreshold(uint availableVotingTokens) public pure returns (uint) {
        return mul256(availableVotingTokens, PROPOSAL_THRESHOLD_PERCENTAGE) / 1e18;
    }

    
    function proposalMaxOperations() public pure returns (uint) { return 10; } 

    
    function votingDelay() public pure returns (uint) { return 1; } 

    
    function votingPeriod() public view returns (uint) { return votingPeriodBlocks; }

    
    TimelockInterface public timelock;

    
    uint48 public proposalCount;

    
    
    uint48 public immutable votingPeriodBlocks; 

    
    VotingTokenInterface public votingToken;

    
    address public guardian;

    
    struct Proposal {
        address[] targets;
        string[] signatures;
        bytes[] calldatas;
        string ipfsHash;
        address proposer;
        uint48 eta;
        uint48 id;
        uint128 forVotes;
        uint48 startBlock;
        uint48 endBlock;
        bool canceled;
        bool executed;
        uint128 againstVotes;
        uint128 availableVotingTokens;
    }

    
    
    struct Receipt {
        bool hasVoted;
        bool support;
        uint192 votes;
    }

    
    
    mapping(uint48 => mapping (address => Receipt)) internal receipts;

    
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    
    mapping (uint => Proposal) public proposals;

    
    mapping (address => uint) public latestProposalIds;

    
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    
    
    event ProposalCreated(uint indexed id, address indexed proposer);

    
    event VoteCast(address indexed voter, uint indexed proposalId, bool indexed support, uint votes);

    
    event ProposalCanceled(uint indexed id);

    
    event ProposalQueued(uint indexed id, uint eta);

    
    event ProposalExecuted(uint indexed id);

    constructor(string memory name_, address timelock_, address votingToken_, address guardian_, uint48 votingPeriodBlocks_) {
        
        name = name_;

        require(timelock_ != address(0) && votingToken_ != address(0) && guardian_ != address(0));
        timelock = TimelockInterface(timelock_);
        votingToken = VotingTokenInterface(votingToken_);
        guardian = guardian_;

        
        require(votingPeriodBlocks_ > 0);
        votingPeriodBlocks = votingPeriodBlocks_;
    }

    function propose(address[] memory targets, string[] memory signatures, bytes[] memory calldatas, string memory ipfsHash) public returns (uint) {
        
        uint availableVotingTokens = _availableVotingTokens();
        require(votingToken.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(availableVotingTokens), "GovernorAlpha::propose: proposer votes below proposal threshold");
        require(targets.length == signatures.length && targets.length == calldatas.length, "GovernorAlpha::propose: proposal function information arity mismatch");
        require(targets.length > 0, "GovernorAlpha::propose: must provide actions");
        require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId > 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal");
        }

        
        for (uint i = 0; i < signatures.length; i++) {
            _requireValidAction(targets[i], signatures[i]);
        }

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());

        proposalCount++;
        require(proposalCount < 2**48);
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            ipfsHash: ipfsHash, 
            proposer: msg.sender,
            eta: 0,
            targets: targets,
            signatures: signatures,
            calldatas: calldatas,
            startBlock: _to48(startBlock),
            endBlock: _to48(endBlock),
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false,
            availableVotingTokens: _to128(availableVotingTokens) 
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        
        emit ProposalCreated(newProposal.id, msg.sender);
        return newProposal.id;
    }

    function queue(uint proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = _to48(eta);
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(address target, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, signature, data, eta))), "GovernorAlpha::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target, signature, data, eta);
    }

    
    function execute(uint proposalId) public {
        require(state(proposalId) == ProposalState.Queued, "GovernorAlpha::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction(proposal.targets[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        
        
        
        require(state(proposalId) != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        
        require(msg.sender == guardian || votingToken.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(proposal.availableVotingTokens), "GovernorAlpha::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(uint proposalId) public view returns (address[] memory targets, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.signatures, p.calldatas);
    }

    function getReceipt(uint48 proposalId, address voter) public view returns (Receipt memory) {
        
        return receipts[proposalId][voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < mul256(proposal.availableVotingTokens, QUORUM_VOTES_PERCENTAGE) / 1e18) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorAlpha::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = receipts[_to48(proposalId)][voter];
        require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
        uint votes = votingToken.getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = _to128(add256(proposal.forVotes, votes));
        } else {
            proposal.againstVotes = _to128(add256(proposal.againstVotes, votes));
        }

        receipt.hasVoted = true;
        receipt.support = support;
        
        receipt.votes = _to192(votes);

        emit VoteCast(voter, proposalId, support, votes);
    }

    function __abdicate() public {
        require(_canAbdicate(msg.sender), 'Not Authorized');
        guardian = address(0);
    }

    
    function _canAbdicate(address) internal view virtual returns (bool);
    function _requireValidAction(address, string memory) internal view virtual;
    function _availableVotingTokens() internal view virtual returns (uint);

    

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    
    function mul256(uint256 a, uint256 b) internal pure returns (uint r) {
        if (a == 0) return 0;
        r = a * b;
        require(r / a == b, "multiplication overflow");
    }


    
    function _to192(uint256 val) internal pure returns (uint192) {
        require(val < 2**192, 'Exceeds 192 bits');
        return uint192(val);
    }

    function _to128(uint256 val) internal pure returns (uint128) {
        require(val < 2**128, 'Exceeds 128 bits');
        return uint128(val);
    }

    function _to48(uint256 val) internal pure returns (uint48) {
        require(val < 2**48, 'Exceeds 48 bits');
        return uint48(val);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    
    function getAllProposals(address voter) external view returns (
        Proposal[] memory _proposals,
        ProposalState[] memory _proposalStates,
        Receipt[] memory _receipts
    ) {
        uint _proposalCount = proposalCount;
        _proposals = new Proposal[](_proposalCount);
        _proposalStates = new ProposalState[](_proposalCount);
        _receipts = new Receipt[](_proposalCount);

        for(uint48 i = 1; i <= _proposalCount; i++) {
            _proposals[i - 1] = proposals[i];
            _proposalStates[i - 1] = state(i);
            _receipts[i - 1] = getReceipt(i, voter);
        }
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

interface VotingTokenInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

