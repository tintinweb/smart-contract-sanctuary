// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';
import './IERC20.sol';
import './sbTokensInterface.sol';
import './sbCommunityInterface.sol';
import './sbStrongPoolInterface.sol';
import './sbVotesInterface.sol';

contract sbControllerV2 {
  event CommunityAdded(address indexed community);
  event RewardsReleased(address indexed receiver, uint256 amount, uint256 indexed day);

  using SafeMath for uint256;

  bool internal initDone;

  address internal sbTimelock;
  IERC20 internal strongToken;
  sbTokensInterface internal sbTokens;
  sbStrongPoolInterface internal sbStrongPool;
  sbVotesInterface internal sbVotes;
  uint256 internal startDay;

  mapping(uint256 => uint256) internal COMMUNITY_DAILY_REWARDS_BY_YEAR;
  mapping(uint256 => uint256) internal STRONGPOOL_DAILY_REWARDS_BY_YEAR;
  mapping(uint256 => uint256) internal VOTER_DAILY_REWARDS_BY_YEAR;
  uint256 internal MAX_YEARS;

  address[] internal communities;

  mapping(uint256 => uint256) internal dayMineSecondsUSDTotal;
  mapping(address => mapping(uint256 => uint256)) internal communityDayMineSecondsUSD;
  mapping(address => mapping(uint256 => uint256)) internal communityDayRewards;
  mapping(address => uint256) internal communityDayStart;
  uint256 internal dayLastReleasedRewardsFor;

  address internal superAdmin;
  address internal pendingSuperAdmin;

  function setSuperAdmin() public {
    require(superAdmin == address(0), 'superAdmin already set');
    superAdmin = address(0x4B5057B2c87Ec9e7C047fb00c0E406dfF2FDaCad);
  }

  function setPendingSuperAdmin(address newPendingSuperAdmin) public {
    require(msg.sender == superAdmin && msg.sender != address(0), 'not superAdmin');
    pendingSuperAdmin = newPendingSuperAdmin;
  }

  function acceptSuperAdmin() public {
    require(msg.sender == pendingSuperAdmin && msg.sender != address(0), 'not pendingSuperAdmin');
    superAdmin = pendingSuperAdmin;
    pendingSuperAdmin = address(0);
  }

  function getSuperAdminAddressUsed() public view returns (address) {
    return superAdmin;
  }

  function getPendingSuperAdminAddressUsed() public view returns (address) {
    return pendingSuperAdmin;
  }

  function updateCommunityDailyRewardsByYear(uint256 amount) public {
    require(msg.sender == superAdmin && msg.sender != address(0), 'not superAdmin');
    uint256 year = _getYearDayIsIn(_getCurrentDay());
    require(year <= MAX_YEARS, 'invalid year');
    COMMUNITY_DAILY_REWARDS_BY_YEAR[year] = amount;
  }

  function updateStrongPoolDailyRewardsByYear(uint256 amount) public {
    require(msg.sender == superAdmin && msg.sender != address(0), 'not superAdmin');
    uint256 year = _getYearDayIsIn(_getCurrentDay());
    require(year <= MAX_YEARS, 'invalid year');
    STRONGPOOL_DAILY_REWARDS_BY_YEAR[year] = amount;
  }

  // TODO: Double check me
  function updateVoterDailyRewardsByYear(uint256 amount) public {
    require(msg.sender == superAdmin && msg.sender != address(0), 'not superAdmin');
    uint256 year = _getYearDayIsIn(_getCurrentDay());
    require(year <= MAX_YEARS, 'invalid year');
    VOTER_DAILY_REWARDS_BY_YEAR[year] = amount;
  }

  function upToDate() external view returns (bool) {
    return dayLastReleasedRewardsFor == _getCurrentDay().sub(1);
  }

  function addCommunity(address community) external {
    require(msg.sender == sbTimelock, 'not sbTimelock');
    require(community != address(0), 'community not zero address');
    require(!_communityExists(community), 'community exists');
    communities.push(community);
    communityDayStart[community] = _getCurrentDay();
    emit CommunityAdded(community);
  }

  function getCommunities() external view returns (address[] memory) {
    return communities;
  }

  function getDayMineSecondsUSDTotal(uint256 day) external view returns (uint256) {
    require(day >= startDay, '1: invalid day');
    require(day <= dayLastReleasedRewardsFor, '2: invalid day');
    return dayMineSecondsUSDTotal[day];
  }

  function getCommunityDayMineSecondsUSD(address community, uint256 day) external view returns (uint256) {
    require(_communityExists(community), 'invalid community');
    require(day >= communityDayStart[community], '1: invalid day');
    require(day <= dayLastReleasedRewardsFor, '2: invalid day');
    return communityDayMineSecondsUSD[community][day];
  }

  function getCommunityDayRewards(address community, uint256 day) external view returns (uint256) {
    require(_communityExists(community), 'invalid community');
    require(day >= communityDayStart[community], '1: invalid day');
    require(day <= dayLastReleasedRewardsFor, '2: invalid day');
    return communityDayRewards[community][day];
  }

  function getCommunityDailyRewards(uint256 day) external view returns (uint256) {
    require(day >= startDay, 'invalid day');
    uint256 year = _getYearDayIsIn(day);
    require(year <= MAX_YEARS, 'invalid year');
    return COMMUNITY_DAILY_REWARDS_BY_YEAR[year];
  }

  function getStrongPoolDailyRewards(uint256 day) external view returns (uint256) {
    require(day >= startDay, 'invalid day');
    uint256 year = _getYearDayIsIn(day);
    require(year <= MAX_YEARS, 'invalid year');
    return STRONGPOOL_DAILY_REWARDS_BY_YEAR[year];
  }

  function getVoterDailyRewards(uint256 day) external view returns (uint256) {
    require(day >= startDay, 'invalid day');
    uint256 year = _getYearDayIsIn(day);
    require(year <= MAX_YEARS, 'invalid year');
    return VOTER_DAILY_REWARDS_BY_YEAR[year];
  }

  function getStartDay() external view returns (uint256) {
    return startDay;
  }

  function communityAccepted(address community) external view returns (bool) {
    return _communityExists(community);
  }

  function getMaxYears() public view returns (uint256) {
    return MAX_YEARS;
  }

  function getCommunityDayStart(address community) public view returns (uint256) {
    require(_communityExists(community), 'invalid community');
    return communityDayStart[community];
  }

  function getSbTimelockAddressUsed() public view returns (address) {
    return sbTimelock;
  }

  function getStrongAddressUsed() public view returns (address) {
    return address(strongToken);
  }

  function getSbTokensAddressUsed() public view returns (address) {
    return address(sbTokens);
  }

  function getSbStrongPoolAddressUsed() public view returns (address) {
    return address(sbStrongPool);
  }

  function getSbVotesAddressUsed() public view returns (address) {
    return address(sbVotes);
  }

  function getCurrentYear() public view returns (uint256) {
    uint256 day = _getCurrentDay().sub(startDay);
    return _getYearDayIsIn(day == 0 ? startDay : day);
  }

  function getYearDayIsIn(uint256 day) public view returns (uint256) {
    require(day >= startDay, 'invalid day');
    return _getYearDayIsIn(day);
  }

  function getCurrentDay() public view returns (uint256) {
    return _getCurrentDay();
  }

  function getDayLastReleasedRewardsFor() public view returns (uint256) {
    return dayLastReleasedRewardsFor;
  }

  function releaseRewards() public {
    uint256 currentDay = _getCurrentDay();
    require(currentDay > dayLastReleasedRewardsFor.add(1), 'already released');
    require(sbTokens.upToDate(), 'need token prices');
    dayLastReleasedRewardsFor = dayLastReleasedRewardsFor.add(1);
    uint256 year = _getYearDayIsIn(dayLastReleasedRewardsFor);
    require(year <= MAX_YEARS, 'invalid year');
    address[] memory tokenAddresses = sbTokens.getTokens();
    uint256[] memory tokenPrices = sbTokens.getTokenPrices(dayLastReleasedRewardsFor);
    for (uint256 i = 0; i < communities.length; i++) {
      address community = communities[i];
      uint256 sum = 0;
      for (uint256 j = 0; j < tokenAddresses.length; j++) {
        address token = tokenAddresses[j];
        (, , uint256 minedSeconds) = sbCommunityInterface(community).getTokenData(token, dayLastReleasedRewardsFor);
        uint256 tokenPrice = tokenPrices[j];
        uint256 minedSecondsUSD = tokenPrice.mul(minedSeconds).div(1e18);
        sum = sum.add(minedSecondsUSD);
      }
      communityDayMineSecondsUSD[community][dayLastReleasedRewardsFor] = sum;
      dayMineSecondsUSDTotal[dayLastReleasedRewardsFor] = dayMineSecondsUSDTotal[dayLastReleasedRewardsFor].add(sum);
    }
    for (uint256 i = 0; i < communities.length; i++) {
      address community = communities[i];
      if (communityDayMineSecondsUSD[community][dayLastReleasedRewardsFor] == 0) {
        continue;
      }
      communityDayRewards[community][dayLastReleasedRewardsFor] = communityDayMineSecondsUSD[community][dayLastReleasedRewardsFor]
        .mul(COMMUNITY_DAILY_REWARDS_BY_YEAR[year])
        .div(dayMineSecondsUSDTotal[dayLastReleasedRewardsFor]);

      uint256 amount = communityDayRewards[community][dayLastReleasedRewardsFor];
      strongToken.approve(community, amount);
      sbCommunityInterface(community).receiveRewards(dayLastReleasedRewardsFor, amount);
      emit RewardsReleased(community, amount, currentDay);
    }
    (, , uint256 strongPoolMineSeconds) = sbStrongPool.getMineData(dayLastReleasedRewardsFor);
    if (strongPoolMineSeconds != 0) {
      strongToken.approve(address(sbStrongPool), STRONGPOOL_DAILY_REWARDS_BY_YEAR[year]);
      sbStrongPool.receiveRewards(dayLastReleasedRewardsFor, STRONGPOOL_DAILY_REWARDS_BY_YEAR[year]);
      emit RewardsReleased(address(sbStrongPool), STRONGPOOL_DAILY_REWARDS_BY_YEAR[year], currentDay);
    }
    bool hasVoteSeconds = false;
    for (uint256 i = 0; i < communities.length; i++) {
      address community = communities[i];
      (, , uint256 voteSeconds) = sbVotes.getCommunityData(community, dayLastReleasedRewardsFor);
      if (voteSeconds > 0) {
        hasVoteSeconds = true;
        break;
      }
    }
    if (hasVoteSeconds) {
      strongToken.approve(address(sbVotes), VOTER_DAILY_REWARDS_BY_YEAR[year]);
      sbVotes.receiveVoterRewards(dayLastReleasedRewardsFor, VOTER_DAILY_REWARDS_BY_YEAR[year]);
      emit RewardsReleased(address(sbVotes), VOTER_DAILY_REWARDS_BY_YEAR[year], currentDay);
    }
  }

  function _getCurrentDay() internal view returns (uint256) {
    return block.timestamp.div(1 days).add(1);
  }

  function _communityExists(address community) internal view returns (bool) {
    for (uint256 i = 0; i < communities.length; i++) {
      if (communities[i] == community) {
        return true;
      }
    }
    return false;
  }

  function _getYearDayIsIn(uint256 day) internal view returns (uint256) {
    return day.sub(startDay).div(366).add(1); // dividing by 366 makes day 1 and 365 be in year 1
  }
}
