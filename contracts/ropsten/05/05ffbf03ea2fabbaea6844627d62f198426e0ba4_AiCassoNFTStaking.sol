// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Ownable.sol';
import './Strings.sol';
import './IERC721Enumerable.sol';
import './IAiCassoNFTStaking.sol';

contract AiCassoNFTStaking is Ownable {
    using Strings for uint256;

    struct Staker {
        uint256[] tokenIds;
        mapping (uint256 => uint256) tokenIndex;
        uint256 stakerIndex;
        uint256 balance;
        uint256 lastRewardCalculate;
        uint256 rewardCalculated;
        uint256 rewardWithdrawed;
    }

    struct Reward {
        uint256 start;
        uint256 end;
        uint256 amount;
        uint256 perMinute;
    }

    struct Withdraw {
        uint256 date;
        uint256 amount;
    }

    mapping (address => Staker) public stakers;
    mapping (uint256 => address) public tokenOwner;
    mapping (uint256 => Reward) public rewards;
    mapping (uint256 => Withdraw) public withdraws;
    address[] public stakersList;

    uint256 public stakedCount;
    uint256 public rewardsCount;
    uint256 public withdrawsCount;

    event Staked(address owner, uint256 tokenId);
    event UnStaked(address owner, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 reward);

    IERC721Enumerable public AiCassoNFT;


    modifier onlyParent() {
        require(address(AiCassoNFT) == msg.sender);
        _;
    }

    constructor(address _AiCassoNFT) {
        AiCassoNFT = IERC721Enumerable(_AiCassoNFT);
    }

    function deposit() public onlyOwner payable {
        addReward(msg.value);
    }

    function withdrawForOwner(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, 'Insufficient funds');
        payable(msg.sender).transfer(amount);
    }

    function withdraw() public {
        updateReward(msg.sender);

        Staker storage staker = stakers[msg.sender];
        uint256 toWithdraw = staker.rewardCalculated - staker.rewardWithdrawed;
        uint256 balance = address(this).balance;

        require(balance >= toWithdraw, 'The function is not available at the moment, try again later');
        staker.rewardWithdrawed += toWithdraw;

        Withdraw storage _withdraw = withdraws[withdrawsCount];
        withdrawsCount += 1;
        _withdraw.date = block.timestamp;
        _withdraw.amount = toWithdraw;

        payable(msg.sender).transfer(toWithdraw);

        emit RewardPaid(msg.sender, toWithdraw);
    }

    function stake(uint256 _tokenId, address _owner) public onlyParent {
        _stake(_owner, _tokenId);
    }

    function unstake(uint256 numberOfTokens) public {
        Staker storage staker = stakers[msg.sender];
        require(staker.balance >= numberOfTokens);
        updateReward(msg.sender);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _unstake(msg.sender, staker.tokenIds[i]);
        }
    }

    function addReward(uint256 amount) internal {
        Reward storage reward = rewards[rewardsCount];
        rewardsCount += 1;

        reward.start = block.timestamp;
        reward.end = block.timestamp + 30 days;
        reward.amount = amount;
        reward.perMinute = amount / 30 days * 60;
    }

    function updateRewardAll() internal {
        for (uint256 i = 0; i < stakersList.length; i++) {
            updateReward(stakersList[i]);
        }
    }

    function updateReward(address _user) internal {
        Staker storage staker = stakers[_user];
        staker.lastRewardCalculate = block.timestamp;
        staker.rewardCalculated += getReward(_user);
    }

    function getReward(address _user) public view returns (uint256) {
        Staker storage staker = stakers[_user];
        if (staker.balance > 0) {
            uint256 rewardCalculated;

            for (uint256 i = 0; i < rewardsCount; i++) {
                Reward storage reward = rewards[i];
                if (reward.end > staker.lastRewardCalculate) {
                    uint256 startCalculate = staker.lastRewardCalculate;
                    if (reward.start > staker.lastRewardCalculate) {
                        startCalculate = reward.start;
                    }

                    uint256 minutesReward = (block.timestamp - startCalculate) / 60;
                    uint256 totalReward = minutesReward * reward.perMinute;
                    uint256 userReward = staker.balance / stakedCount * totalReward;

                    rewardCalculated += userReward;
                }
            }

            return rewardCalculated;
        }

        return 0;
    }

    function totalStaked() public view returns (uint256) {
        return stakedCount;
    }


    function totalLastWeekWithdraws() public view returns (uint256) {
        uint256 weekStart = block.timestamp - 7 days;
        uint256 total = 0;

        for (uint256 i = 0; i < withdrawsCount; i++) {
            Withdraw storage _withdraw = withdraws[i];
            if (_withdraw.date >= weekStart) {
                total += _withdraw.amount;
            }
        }
        return total;
    }

    function totalRewardOf(address _user) public view returns (uint256) {
        Staker storage staker = stakers[_user];
        uint256 reward = getReward(_user);
        return reward + staker.rewardCalculated;
    }

    function percentOf(address _user) public view returns (uint256) {
        Staker storage staker = stakers[_user];
        return staker.balance / stakedCount * 100;
    }

    function balanceOf(address _user) public view returns (uint256) {
        Staker storage staker = stakers[_user];
        return staker.balance;
    }

    function rewardOf(address _user) public view returns (uint256) {
        Staker storage staker = stakers[_user];
        return getReward(_user) + staker.rewardCalculated - staker.rewardWithdrawed;
    }


    function _stake(address _user, uint256 _tokenId) internal {
        Staker storage staker = stakers[_user];

        updateRewardAll();

        if (staker.balance == 0 && staker.lastRewardCalculate == 0) {
            staker.lastRewardCalculate = block.timestamp;
            staker.stakerIndex = stakersList.length;
            stakersList[stakersList.length] = _user;
        }

        staker.balance += 1;
        staker.tokenIds.push(_tokenId);
        staker.tokenIndex[staker.tokenIds.length - 1];
        tokenOwner[_tokenId] = _user;

        stakedCount += 1;

        emit Staked(_user, _tokenId);
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        Staker storage staker = stakers[_user];

        staker.balance -= 1;

        uint256 lastIndex = staker.tokenIds.length - 1;
        uint256 lastIndexKey = staker.tokenIds[lastIndex];
        uint256 tokenIdIndex = staker.tokenIndex[_tokenId];

        staker.tokenIds[tokenIdIndex] = lastIndexKey;
        staker.tokenIndex[lastIndexKey] = tokenIdIndex;
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
            delete staker.tokenIndex[_tokenId];
        }

        if (staker.balance == 0) {
            lastIndex = stakersList.length - 1;
            address lastStakerIndexKey = stakersList[lastIndex];
            tokenIdIndex = staker.stakerIndex;

            stakersList[tokenIdIndex] = lastStakerIndexKey;
            if (stakersList.length > 0) {
                stakersList.pop();
            }

            staker.lastRewardCalculate = 0;
        }
        delete tokenOwner[_tokenId];

        stakedCount -= 1;

        AiCassoNFT.safeTransferFrom(
            address(this),
            _user,
            _tokenId
        );

        emit UnStaked(_user, _tokenId);
    }
}