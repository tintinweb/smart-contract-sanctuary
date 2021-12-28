/*

 /$$$$$$$$ /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$   /$$ /$$$$$$$  /$$       /$$$$$$$$  /$$$$$$   /$$$$$$ 
|__  $$__/| $$  | $$| $$_____/      | $$_____/| $$$ | $$| $$__  $$| $$      | $$_____/ /$$__  $$ /$$__  $$
   | $$   | $$  | $$| $$            | $$      | $$$$| $$| $$  \ $$| $$      | $$      | $$  \__/| $$  \__/
   | $$   | $$$$$$$$| $$$$$         | $$$$$   | $$ $$ $$| $$  | $$| $$      | $$$$$   |  $$$$$$ |  $$$$$$ 
   | $$   | $$__  $$| $$__/         | $$__/   | $$  $$$$| $$  | $$| $$      | $$__/    \____  $$ \____  $$
   | $$   | $$  | $$| $$            | $$      | $$\  $$$| $$  | $$| $$      | $$       /$$  \ $$ /$$  \ $$
   | $$   | $$  | $$| $$$$$$$$      | $$$$$$$$| $$ \  $$| $$$$$$$/| $$$$$$$$| $$$$$$$$|  $$$$$$/|  $$$$$$/
   |__/   |__/  |__/|________/      |________/|__/  \__/|_______/ |________/|________/ \______/  \______/ 
                                                                                                          
*/
// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.6;

import "./libs/ItheEndlessFactory.sol";
import "./libs/Gamificable.sol";
import "./libs/ImergeAPI.sol";

/*
ERROR TABLE
===========

ERR1: contract not allowed
ERR2: Can only run genesisStartRound once
ERR3: Invalid Harvest interval
*/

contract KingDomNFT is Ownable, ReentrancyGuard, Gamificable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;
    
    // The address of the dream kingdom factory
    ItheEndlessFactory public theEndlessFactoryNFT;

    ImergeAPI public iMergeAPI;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // The block number when dream mining ends.
    uint256 public endBlock;

    // The block number when dream mining starts.
    uint256 public startBlock;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // tokens created per block.
    uint256 public rewardPerBlock;

    // experience created per block.
    uint256 public experiencePerBlock;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The reward token
    IERC20Metadata public rewardToken;

    // The staked token
    IERC20Metadata public stakedToken;

    // The transfer fee (in basis points) of staked token
    uint16 public stakedTokenTransferFee;

    // The harvest interval
    uint256 public harvestInterval;

    // Max Harvest interval: 30 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 1 days;

    mapping(uint256 => bool) nftIDs;

    uint256 public userNftLength;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 nextHarvestUntil;
        uint256 nftID;
        bool hasNFT;
        uint256 powerStaking;
        uint256 powerAmount;
        uint256 experience;
        uint256 experienceDebt;
        uint256 currentExperience;
        uint256 amountWithNFT;
    }

    // Info of each pool.
    PoolInfo public poolInfo;
    
    struct PoolInfo {
        IERC20 token;           // Address of token contract.
        uint256 lastRewardBlock;  // Last block number that Rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e18. See below.
        uint256 totalPower;
        uint256 accExperiencePerShare;
        uint256 supplyWithNFT;
        uint256 lastExperienceBlock;
    }

    /*
     * @notice Deploy the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _endBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _stakedTokenTransferFee: the transfer fee of stakedToken (if any, else 0)
     * @param _harvestInterval: the Harvest interval for stakedToken (if any, else 0)
     */
    
    constructor(
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _experiencePerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _poolLimitPerUser,
        uint16 _stakedTokenTransferFee,
        uint256 _harvestInterval,
        ItheEndlessFactory _theEndlessFactoryNFT,
        ImergeAPI _iMergeAPI
    ) {
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL);

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        experiencePerBlock = _experiencePerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        stakedTokenTransferFee = _stakedTokenTransferFee;
        harvestInterval = _harvestInterval;
        theEndlessFactoryNFT = _theEndlessFactoryNFT;
        iMergeAPI = _iMergeAPI;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30);

        PRECISION_FACTOR = uint256(10 ** (uint256(30).sub(decimalsRewardToken))); 

        // staking pool
        poolInfo = PoolInfo({
            token: _stakedToken,
            lastRewardBlock: startBlock,
            accRewardPerShare: 0,
            totalPower: 0,
            accExperiencePerShare: 0,
            supplyWithNFT: 0,
            lastExperienceBlock: startBlock
        });

        updateOperator(msg.sender, true);

    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount, uint256 _nftID) external nonReentrant {
        require(block.number <= endBlock);

        UserInfo storage user = userInfo[msg.sender];

        bool prevHasNFT = user.hasNFT;

        if (_amount == 0)
            require (user.nextHarvestUntil <= block.timestamp);

        if (hasUserLimit)
            require(_amount.add(user.amount) <= poolLimitPerUser);

        if (theEndlessFactoryNFT.balanceOf(msg.sender) > 0) {
            if(!user.hasNFT)
                _initializeNFT(_nftID, msg.sender);
        }

        _updatePool();
        if (user.hasNFT)
            _updateExperiencePool();

        if (user.amount > 0) {
            _userHarvest(msg.sender);
            if (prevHasNFT)
                _userHarvestExperience(msg.sender);
        }

        if (_amount > 0) {
            uint256 balanceBefore = stakedToken.balanceOf(address(this));
            stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 balanceAfter = stakedToken.balanceOf(address(this));
            _amount = balanceAfter.sub(balanceBefore);

            if (stakedTokenTransferFee > 0) {
                uint256 transferFee = _amount.mul(stakedTokenTransferFee).div(10000);
                _amount = _amount.sub(transferFee);
            }

            user.amount = user.amount.add(_amount);

            if (user.nextHarvestUntil == 0)
                _updateHarvestLookup(msg.sender);
            if (user.hasNFT)
                _updatePower(msg.sender, _amount);
        }

        user.rewardDebt = _calculatedUserAmount(msg.sender).mul(poolInfo.accRewardPerShare).div(PRECISION_FACTOR);
        if (user.hasNFT)
            user.experienceDebt = user.amountWithNFT.mul(poolInfo.accExperiencePerShare).div(PRECISION_FACTOR);

    }

    /*
     * @notice Withdraw all staked tokens and collect reward tokens
     */
    function withdraw() external nonReentrant {
        require(block.number > endBlock);

        UserInfo storage user = userInfo[msg.sender];
        user.nextHarvestUntil = 0;

        uint256 _amount = user.amount;

        _updatePool();
        if (user.hasNFT)
            _updateExperiencePool();

        if (_amount > 0) {
            // Harvest
            _userHarvest(msg.sender);
            if (user.hasNFT)
                _userHarvestExperience(msg.sender);

            if (user.hasNFT) {
                poolInfo.supplyWithNFT = poolInfo.supplyWithNFT.sub(user.amountWithNFT);
                uint256 _newExperience = user.currentExperience.add(user.experience);
                theEndlessFactoryNFT.setExperience(user.nftID, _newExperience);

                poolInfo.totalPower = poolInfo.totalPower.sub(user.powerAmount);
                user.powerAmount = 0;
                user.amountWithNFT = 0;
            }

            user.amount = 0;

            stakedToken.safeTransfer(address(msg.sender), _amount);
        }

        user.rewardDebt = 0; // _calculatedUserAmount(msg.sender).mul(poolInfo.accRewardPerShare).div(PRECISION_FACTOR);
        user.experienceDebt = 0;

    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        require(block.number > endBlock);

        UserInfo storage user = userInfo[msg.sender];

        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.nextHarvestUntil = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
        }

    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken));
        require(_tokenAddress != address(rewardToken));

        IERC20Metadata(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        endBlock = block.number;
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(startBlock > block.number);

        rewardPerBlock = _rewardPerBlock;
    }

    function updateExperienceRewardPerBlock(uint256 _experiencePerBlock) external onlyOwner {
        require(startBlock > block.number);

        experiencePerBlock = _experiencePerBlock;
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateBlocks(uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        require(startBlock > block.number);
        require(_startBlock < _endBlock);

        startBlock = _startBlock;
        endBlock = _endBlock;

        poolInfo.lastRewardBlock = startBlock;
        poolInfo.lastExperienceBlock = startBlock;

    }

    // /*
    //  * @notice Update the Harvest interval
    //  * @dev Only callable by owner.
    //  * @param _interval: the Harvest interval for staked token in seconds
    //  */
    function updateHarvestInterval(uint256 _interval) external onlyOwner {
        require(_interval <= MAXIMUM_HARVEST_INTERVAL, "ERR3");
        harvestInterval = _interval;
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        uint256 calculatedAmount = _calculatedUserAmount(_userAddress);
        uint256 accRewardPerShare = poolInfo.accRewardPerShare;

        if (block.number > poolInfo.lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(poolInfo.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare = accRewardPerShare.add(tokenReward.mul(PRECISION_FACTOR).div(stakedTokenSupply.add(poolInfo.totalPower)));
            return calculatedAmount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        } else {
            return calculatedAmount.mul(accRewardPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        }
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingExperience(address _userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress];
        if (!user.hasNFT)
            return 0;

        uint256 supplyWithNFT = poolInfo.supplyWithNFT;
        uint256 calculatedAmount = user.amountWithNFT;
        uint256 accExperiencePerShare = poolInfo.accExperiencePerShare;

        if (block.number > poolInfo.lastExperienceBlock && supplyWithNFT != 0) {
            uint256 multiplier = _getMultiplier(poolInfo.lastExperienceBlock, block.number);
            uint256 experienceReward = multiplier.mul(experiencePerBlock);
            uint256 adjustedTokenPerShare = accExperiencePerShare.add(experienceReward.mul(PRECISION_FACTOR).div(supplyWithNFT));
            return calculatedAmount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.experienceDebt);
        } else {
            return calculatedAmount.mul(accExperiencePerShare).div(PRECISION_FACTOR).sub(user.experienceDebt);
        }
    }

    // View function to see if user can withdraw staked token.
    function canWithdraw() external view returns (bool) {
        return block.number > endBlock;
    }

    // View function to see if user can harvest reward token.
    function canHarvest(address _userAddress) external view returns (bool) {
        return block.timestamp >= userInfo[_userAddress].nextHarvestUntil;
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= poolInfo.lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            poolInfo.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(poolInfo.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardPerBlock);
        poolInfo.accRewardPerShare = poolInfo.accRewardPerShare.add(tokenReward.mul(PRECISION_FACTOR).div(stakedTokenSupply.add(poolInfo.totalPower)));
        poolInfo.lastRewardBlock = block.number;
    }

    function _updateExperiencePool() internal {
        if (block.number <= poolInfo.lastExperienceBlock) {
            return;
        }

        uint256 supplyWithNFT = poolInfo.supplyWithNFT;

        if (supplyWithNFT == 0) {
            poolInfo.lastExperienceBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(poolInfo.lastExperienceBlock, block.number);
        uint256 experienceReward = multiplier.mul(experiencePerBlock);
        poolInfo.accExperiencePerShare = poolInfo.accExperiencePerShare.add(experienceReward.mul(PRECISION_FACTOR).div(supplyWithNFT));

        poolInfo.lastExperienceBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }

    function _initializeNFT(uint256 _nftID, address _userAddress) internal  {
        UserInfo storage user = userInfo[_userAddress];

        if (!nftIDs[_nftID]) {
            if (theEndlessFactoryNFT.ownerOf(_nftID) == _userAddress) {
                user.hasNFT = true;
                user.nftID = _nftID;
                user.powerStaking = _getNFTPowerStaking(user.nftID);
                nftIDs[_nftID] = true;
                userNftLength = userNftLength.add(1);
                uint256 _currentExperience = _getNFTExperience(user.nftID);
                if (_currentExperience > 0 && _currentExperience < 1e5)
                    _currentExperience = _currentExperience.mul(1e18);

                user.currentExperience = _currentExperience;
        
            }
        }
    }

    function _updatePower(address _user, uint256 _amount) internal {
        UserInfo storage user = userInfo[_user];

        uint256 factor = 10000;
        uint256 _powerStaking = user.powerStaking;
        uint256 _currentExperience = user.currentExperience.div(1e18);
        if (_currentExperience > 0) {
            if (_currentExperience < 1000) {
                _powerStaking = _powerStaking.add(50);
            } else if (_currentExperience < 2000) {
                _powerStaking = _powerStaking.add(100);
            } else if (_currentExperience < 3000) {
                _powerStaking = _powerStaking.add(150);
            } else if (_currentExperience < 4000) {
                _powerStaking = _powerStaking.add(200);
            } else if (_currentExperience < 5000) {
                _powerStaking = _powerStaking.add(250);
            } else if (_currentExperience < 6000) {
                _powerStaking = _powerStaking.add(300);
            } else if (_currentExperience < 7000) {
                _powerStaking = _powerStaking.add(350);
            } else {
                _powerStaking = _powerStaking.add(400);
            }
        }

        uint256 boostedAmount = (_amount * _powerStaking).div(factor);

        user.powerAmount = user.powerAmount.add(boostedAmount);

        poolInfo.totalPower = poolInfo.totalPower.add(boostedAmount);

        user.amountWithNFT = user.amountWithNFT.add(_amount.add(boostedAmount));

        poolInfo.supplyWithNFT = poolInfo.supplyWithNFT.add(_amount.add(boostedAmount));
    }

    function _userHarvest(address _userAddress) internal {
        UserInfo storage user = userInfo[_userAddress];

        uint256 newUserAmount = _calculatedUserAmount(_userAddress);
        uint256 pending = newUserAmount.mul(poolInfo.accRewardPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        if (pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
            _updateHarvestLookup(_userAddress);
        }
    }

    function _userHarvestExperience(address _userAddress) internal {
        UserInfo storage user = userInfo[_userAddress];

        uint256 pending = user.amountWithNFT.mul(poolInfo.accExperiencePerShare).div(PRECISION_FACTOR).sub(user.experienceDebt);
        if (pending > 0)
            user.experience = user.experience.add(pending);
    }

    function _calculatedUserAmount(address _user) internal view returns (uint256) {
        UserInfo storage user = userInfo[_user];

        uint256 newAmount = user.amount;

        if (user.hasNFT)
            newAmount = newAmount.add(user.powerAmount);

        return newAmount;
    }

    function _updateHarvestLookup(address _userAddress) internal {
        UserInfo storage user = userInfo[_userAddress];
        uint256 newHarvestInverval = harvestInterval;
        if (user.hasNFT) {
            newHarvestInverval = newHarvestInverval.div(2);
            if (user.currentExperience > 0) {
                uint256 _calculatedExperience = user.currentExperience.div(1e18).add(120);
                if (_calculatedExperience < newHarvestInverval)
                    newHarvestInverval = newHarvestInverval.sub(_calculatedExperience);
            }
        }

        user.nextHarvestUntil = block.timestamp.add(newHarvestInverval);
    }

    function _getNFTPowerStaking(uint256 _nftID) internal view returns (uint256) {
        uint256 strength;
        uint256 agility;
        uint256 endurance;
        uint256 intelligence;
        uint256 wisdom;
        uint256 magic;

        (
            strength,
            agility,
            endurance,
            intelligence,
            magic,
            wisdom
        ) = iMergeAPI.getSkillCard(_nftID);

        if (strength == 0 && agility == 0 ) {
            (
                strength,
                agility,
                endurance,
                intelligence,
                wisdom,
                magic
            ) = theEndlessFactoryNFT.getCharacterStats(_nftID);
        }

        return (strength + agility + endurance + intelligence + magic + wisdom);
    }

    function _getNFTExperience(uint256 _nftID) internal returns (uint256) {
        (,uint256 experience,) = theEndlessFactoryNFT.getCharacterOverView(_nftID);

        return experience;
    }

    // View function to see if user can harvest reward token.
    function claimHarvest() external {
        address _userAddress = msg.sender;
        if (canClaimHarvest(_userAddress)) {
            userInfo[_userAddress].nextHarvestUntil = block.timestamp;
            ledger[_userAddress].lastRoundHarvest   = ledger[_userAddress].roundNumber;
        }
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) public onlyOwner {
        operators[_operator] = _status;
    }

}

/*

 /$$$$$$$$ /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$   /$$ /$$$$$$$  /$$       /$$$$$$$$  /$$$$$$   /$$$$$$ 
|__  $$__/| $$  | $$| $$_____/      | $$_____/| $$$ | $$| $$__  $$| $$      | $$_____/ /$$__  $$ /$$__  $$
   | $$   | $$  | $$| $$            | $$      | $$$$| $$| $$  \ $$| $$      | $$      | $$  \__/| $$  \__/
   | $$   | $$$$$$$$| $$$$$         | $$$$$   | $$ $$ $$| $$  | $$| $$      | $$$$$   |  $$$$$$ |  $$$$$$ 
   | $$   | $$__  $$| $$__/         | $$__/   | $$  $$$$| $$  | $$| $$      | $$__/    \____  $$ \____  $$
   | $$   | $$  | $$| $$            | $$      | $$\  $$$| $$  | $$| $$      | $$       /$$  \ $$ /$$  \ $$
   | $$   | $$  | $$| $$$$$$$$      | $$$$$$$$| $$ \  $$| $$$$$$$/| $$$$$$$$| $$$$$$$$|  $$$$$$/|  $$$$$$/
   |__/   |__/  |__/|________/      |________/|__/  \__/|_______/ |________/|________/ \______/  \______/ 
                                                                                                          
*/
// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.6;

interface  ItheEndlessFactory {
    function setExperience(uint256 tokenId, uint256 _newExperience) external;
    function getCharacterStats(uint256 tokenId) external view returns (uint256,uint256,uint256,uint256,uint256,uint256);
    function getCharacterOverView(uint256 tokenId) external returns (string memory,uint256,uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/*_________   _____    _______  ________      _____      _____    _______   
 /   _____/  /  _  \   \      \ \______ \    /     \    /  _  \   \      \  
 \_____  \  /  /_\  \  /   |   \ |    |  \  /  \ /  \  /  /_\  \  /   |   \ 
 /        \/    |    \/    |    \|    `   \/    Y    \/    |    \/    |    \
/_______  /\____|__  /\____|__  /_______  /\____|__  /\____|__  /\____|__  /
One Thing I've Learned. You Can Know Anything. It's All There. You Just Have To Find It.
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
ERROR TABLE
===========

ERR1: contract not allowed
ERR2: Can only run genesisStartRound once
ERR3: OnlyOwner
*/


abstract contract Gamificable is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;
    using Counters for Counters.Counter;
    
    // GAMING
    struct Round {
      uint256 roundNumber;
      int256 lockPrice;
      int256 closePrice;
      bool oracleCalled;
      uint256 roundStart;
      uint256 roundEnd;
      Position positionWinner;
    }

    enum Position {Neutral, Bull, Bear}

    struct BetInfo {
      uint256 roundNumber;
      uint256 lastRoundHarvest;
      Position position;
    }

    //arrays
    mapping(uint256 => Round) public rounds;
    mapping(address => BetInfo) public ledger;
    mapping(address => bool) public operators;

    //counters
    Counters.Counter public roundCounter;

    //booleans
    bool public genesisStartOnce;
    bool public genesisLockOnce;

    //ChainLink Oracules
    AggregatorV3Interface internal oracle = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); //matic usd
    

    //events
    // event StartRound(uint256 indexed roundNumber, int256 lockPrice);
    // event EndRound(uint256 indexed roundNumber, int256 lockPrice, int256 closePrice);
    // event BetBull(address indexed sender, uint256 indexed currentRound);
    // event BetBear(address indexed sender, uint256 indexed currentRound);


    // MODIFIERS
    modifier avoidBotCall() {
        require(!Address.isContract(msg.sender), "ERR1");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "ERR3");
        _;
    }


    /**
     * @dev Bet bear position
     */
    function betBear() external avoidBotCall {
        require(ledger[msg.sender].roundNumber != _currentRound());

        ledger[msg.sender].roundNumber = _currentRound();
        ledger[msg.sender].position = Position.Bear;

        // emit BetBear(msg.sender, _currentRound());
    }

    /**
     * @dev Bet bull position
     */
    function betBull() external avoidBotCall {
        require(ledger[msg.sender].roundNumber != _currentRound());

        ledger[msg.sender].roundNumber = _currentRound();
        ledger[msg.sender].position = Position.Bull;

        // emit BetBull(msg.sender, _currentRound());
    }

    /* 
     * @dev Start genesis round
     */
    function genesisStartRound() external onlyOwner {
        require(!genesisStartOnce, "ERR2");

        int256 currentPrice = _getPriceFromOracle();
        _startRound(_currentRound(), currentPrice);
        _endRound(_currentRound(), currentPrice);
        
        Counters.increment(roundCounter);
        _startRound(_currentRound(), currentPrice);

        genesisStartOnce = true;        
    }

    /**
     * @dev Start round
     */
    function executeRound() external onlyOperator {
        require(genesisStartOnce);

        int256 currentPrice = _getPriceFromOracle();

        // close current round
        _endRound(_currentRound(), currentPrice);

        // open nexrt round
        Counters.increment(roundCounter);
        _startRound(_currentRound(), currentPrice);
    }

    /**
     * @dev Get the claimable
     */
    function canClaimHarvest(address _user) public view returns (bool) {
        BetInfo memory betInfo = ledger[_user];
        Round memory round = rounds[betInfo.roundNumber];

        // return false if price not change or not has bid
        if (round.lockPrice == round.closePrice || betInfo.lastRoundHarvest == betInfo.roundNumber) {
            return false;
        }
        return round.oracleCalled && (round.positionWinner == betInfo.position);
    }


    function userIsPlayingNow(address _user) external view returns (bool) {
        bool _status = false;
        if (ledger[_user].roundNumber > 0)
            if ((_currentRound().sub(ledger[_user].roundNumber) ) == 0 )
                _status = true;
        return _status;
    }

    function userHasBid(address _user) external view returns (bool) {
        bool _status = false;
        if (ledger[_user].roundNumber > 0)
            if ((ledger[_user].roundNumber.sub(ledger[_user].lastRoundHarvest) ) > 0 )
                _status = true;
        return _status;
    }

    /**
     * INTERNALS METHODS
     */

    /**
     * @dev Start round
     */
    function _startRound(uint256 roundNumber, int256 price) internal {
        Round storage round = rounds[roundNumber];
        round.roundNumber = roundNumber;
        round.lockPrice = price;
        round.roundStart = block.timestamp;

        // emit StartRound(roundNumber, round.lockPrice);
    }

    /**
     * @dev End round
     */

    function _endRound(uint256 roundNumber, int256 price) internal {
        Round storage round = rounds[roundNumber];
        round.closePrice = price;
        round.oracleCalled = true;
        round.roundEnd = block.timestamp;
        if (round.closePrice > round.lockPrice)
            round.positionWinner = Position.Bull;
        else if (round.closePrice < round.lockPrice)
            round.positionWinner = Position.Bear;
        else round.positionWinner = Position.Neutral;

        // emit EndRound(roundNumber, round.lockPrice, round.closePrice);
    }

    function _getPriceFromOracle() internal view returns (int256) {
        (, int256 price, ,, ) = oracle.latestRoundData();
        return price;
    }

    function _currentRound() internal view returns (uint256) {
        return Counters.current(roundCounter);
    }

}

/*_________   _____    _______  ________      _____      _____    _______   
 /   _____/  /  _  \   \      \ \______ \    /     \    /  _  \   \      \  
 \_____  \  /  /_\  \  /   |   \ |    |  \  /  \ /  \  /  /_\  \  /   |   \ 
 /        \/    |    \/    |    \|    `   \/    Y    \/    |    \/    |    \
/_______  /\____|__  /\____|__  /_______  /\____|__  /\____|__  /\____|__  /
One Thing I've Learned. You Can Know Anything. It's All There. You Just Have To Find It.
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.6;

interface  ImergeAPI {
    function getSkillCard(uint256 _nftID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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