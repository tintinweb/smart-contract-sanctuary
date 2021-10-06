//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./SafeBEP20.sol";
import "./ReentrancyGuard.sol";
import "./IBEP20.sol";
import "./IRouter.sol";
import "./ILockStakingRewards.sol";
import "./IERC721.sol";

contract LockStakingRewardFixedAPY is ILockStakingRewards, ReentrancyGuard, Ownable {
    using SafeBEP20 for IBEP20;

    struct StakeInfo {
        uint256 tokenId;
        uint256 rewardRate;
        uint256 stakeAmount;
        uint256 stakeAmountRewardEquivalent;
        uint256 stakeLock;
    }

    struct TokenStakeInfo {
        uint256 weightedStakeDate;
        uint256 balance;
        uint256 balanceRewardEquivalent;
    }

    IBEP20 public immutable rewardsToken;
    IBEP20 public immutable stakingToken;
    IRouter public swapRouter;
    IERC721 public snakeNFT;

    address public stakingManager;

    uint256 public rewardRate;
    uint256 public immutable lockDuration; 
    uint256 public constant rewardDuration = 365 days;

    mapping(uint256 => uint256) public stakeNonces;

    mapping(uint256 => mapping(uint256 => StakeInfo)) public stakeInfo;
    mapping(uint256 => TokenStakeInfo) public tokenStakeInfo;

    uint256 private _totalSupply;
    uint256 private _totalSupplyRewardEquivalent;

    event Staked(uint256 indexed tokenId, uint256 amount);
    event Withdrawn(uint256 indexed tokenId, uint256 amount, address indexed to);
    event RewardPaid(uint256 indexed tokenId, uint256 reward, address indexed to);
    event Rescue(address indexed to, uint amount);
    event RescueToken(address indexed to, address indexed token, uint amount);
    event RewardRateUpdated(uint256 rate);

    modifier onlyStakingManager {
        require(_msgSender() == stakingManager, "LockStakingRewardFixedAPY: caller is not a staking manager contract");
        _;
    }

    constructor(
        address _rewardsToken,
        address _stakingToken,
        address _swapRouter,
        address _stakingManager,
        address _snakeNFT,
        uint _rewardRate,
        uint _lockDuration
    ) {
        require(Address.isContract(_rewardsToken), "_rewardsToken is not a contract");
        require(Address.isContract(_stakingToken), "_stakingToken is not a contract");
        require(Address.isContract(_swapRouter), "_swapRouter is not a contract");
        require(Address.isContract(_snakeNFT), "_snakeNFT is not a contract");
        require(_rewardRate > 0, "_rewardRate is equal to zero");
        require(_lockDuration > 0, "_lockDuration is equal to zero");

        rewardsToken = IBEP20(_rewardsToken);
        stakingToken = IBEP20(_stakingToken);
        swapRouter = IRouter(_swapRouter);
        snakeNFT = IERC721(_snakeNFT);
        stakingManager = _stakingManager;
        rewardRate = _rewardRate;
        lockDuration = _lockDuration;
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function totalSupplyRewardEquivalent() external view returns (uint256) {
        return _totalSupplyRewardEquivalent;
    }

    function balanceOf(uint256 tokenId) public override view returns (uint256) {
        return tokenStakeInfo[tokenId].balance;
    }

    function balanceOfRewardEquivalent(uint256 tokenId) external view returns (uint256) {
        return tokenStakeInfo[tokenId].balanceRewardEquivalent;
    }

    function getRate(uint256 tokenId) public view returns(uint totalRate) {
        uint totalAmountStaked = balanceOf(tokenId);

        for(uint i = 0; i < stakeNonces[tokenId]; i++) {
            StakeInfo memory stakeInfoLocal = stakeInfo[tokenId][i];

            if(stakeInfoLocal.stakeAmount != 0) {
                totalRate += stakeInfoLocal.rewardRate * stakeInfoLocal.stakeAmount / totalAmountStaked;
            }
        }
    }

    function stakeFor(uint256 amount, uint256 tokenId, address user) external override nonReentrant onlyStakingManager returns(uint256 nonce) {
        require(amount > 0, "LockStakingRewardFixedAPY: Cannot stake 0");

        nonce = _stake(amount, tokenId, user);
    }

    function withdrawAndGetReward(uint256 tokenId, uint256 nonce) external override onlyStakingManager {
        getReward(tokenId);
        withdraw(tokenId, nonce);
    }

    function earned(uint256 tokenId) public override view returns (uint256) {
        return (tokenStakeInfo[tokenId].balanceRewardEquivalent * (block.timestamp - tokenStakeInfo[tokenId].weightedStakeDate) * getRate(tokenId)) / (100 * rewardDuration);
    }

    function withdraw(uint256 tokenId, uint256 nonce) public override nonReentrant onlyStakingManager {
        require(stakeInfo[tokenId][nonce].stakeAmount > 0, "LockStakingRewardFixedAPY: This stake nonce was withdrawn");
        require(stakeInfo[tokenId][nonce].stakeLock < block.timestamp, "LockStakingRewardFixedAPY: Locked");

        address tokenOwner = IERC721(snakeNFT).ownerOf(tokenId);
        uint256 amount = stakeInfo[tokenId][nonce].stakeAmount;
        uint256 amountRewardEquivalent = stakeInfo[tokenId][nonce].stakeAmountRewardEquivalent;

        _totalSupply -= amount;
        _totalSupplyRewardEquivalent -= amountRewardEquivalent;
        tokenStakeInfo[tokenId].balance -= amount;
        tokenStakeInfo[tokenId].balanceRewardEquivalent -= amountRewardEquivalent;

        stakingToken.safeTransfer(tokenOwner, amount);

        stakeInfo[tokenId][nonce].stakeAmount = 0;
        stakeInfo[tokenId][nonce].stakeAmountRewardEquivalent = 0;

        emit Withdrawn(tokenId, amount, tokenOwner);
    }

    function getReward(uint256 tokenId) public override nonReentrant onlyStakingManager {
        uint256 reward = earned(tokenId);

        if (reward > 0) {
            tokenStakeInfo[tokenId].weightedStakeDate = block.timestamp;

            address tokenOwner = IERC721(snakeNFT).ownerOf(tokenId);
            rewardsToken.safeTransfer(tokenOwner, reward);

            emit RewardPaid(tokenId, reward, tokenOwner);
        }
    }

    function getEquivalentAmount(uint amount) public view returns (uint) {
        address[] memory path = new address[](2);

        uint equivalent;
        if (stakingToken != rewardsToken) {
            path[0] = address(stakingToken);            
            path[1] = address(rewardsToken);
            equivalent = swapRouter.getAmountsOut(amount, path)[1];
        } else {
            equivalent = amount;   
        }
        
        return equivalent;
    }

    function updateRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
        emit RewardRateUpdated(rewardRate);
    }
    
    function updateSwapRouter(address _swapRouter) external onlyOwner {
        require(Address.isContract(_swapRouter), "LockStakingRewardFixedAPY: _swapRouter is not a contract");
        swapRouter = IRouter(_swapRouter);
    }

    function updateStakingManager(address _stakingManager) external onlyOwner {
        require(Address.isContract(_stakingManager), "LockStakingRewardFixedAPY: _stakingManager is not a contract");
        stakingManager = _stakingManager;
    }

    function updateSnakeNFT(address _snakeNFT) external onlyOwner {
        require(Address.isContract(_snakeNFT), "LockStakingRewardFixedAPY: _snakeNFT is not a contract");
        snakeNFT = IERC721(_snakeNFT);
    }

    function rescue(address to, address token, uint256 amount) external onlyOwner {
        require(to != address(0), "LockStakingRewardFixedAPY: Cannot rescue to the zero address");
        require(amount > 0, "LockStakingRewardFixedAPY: Cannot rescue 0");
        require(token != address(stakingToken), "LockStakingRewardFixedAPY: Cannot rescue staking token");
        //owner can rescue rewardsToken if there is spare unused tokens on staking contract balance

        IBEP20(token).safeTransfer(to, amount);
        emit RescueToken(to, address(token), amount);
    }

    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "LockStakingRewardFixedAPY: Cannot rescue to the zero address");
        require(amount > 0, "LockStakingRewardFixedAPY: Cannot rescue 0");

        to.transfer(amount);
        emit Rescue(to, amount);
    }

    function _stake(uint256 amount, uint256 tokenId, address user) private returns(uint256 stakeNonce) {
        stakingToken.safeTransferFrom(user, address(this), amount);

        uint stakeLock = block.timestamp + lockDuration;
        uint amountRewardEquivalent = getEquivalentAmount(amount);      
        _totalSupply += amount;
        _totalSupplyRewardEquivalent += amountRewardEquivalent;

        TokenStakeInfo memory tokenStakeInfoLocal = tokenStakeInfo[tokenId];

        uint previousAmount = tokenStakeInfoLocal.balance;
        uint newAmount = previousAmount + amount;
        tokenStakeInfo[tokenId].weightedStakeDate = tokenStakeInfoLocal.weightedStakeDate * previousAmount / newAmount + block.timestamp * amount / newAmount;
        tokenStakeInfo[tokenId].balance = newAmount;

        stakeNonce = stakeNonces[tokenId]++;
        stakeInfo[tokenId][stakeNonce].tokenId = tokenId;
        stakeInfo[tokenId][stakeNonce].rewardRate = getRate(tokenId);
        stakeInfo[tokenId][stakeNonce].stakeAmount = amount;
        stakeInfo[tokenId][stakeNonce].stakeLock = stakeLock;
        
        stakeInfo[tokenId][stakeNonce].stakeAmountRewardEquivalent = amountRewardEquivalent;
        tokenStakeInfo[tokenId].balanceRewardEquivalent += amountRewardEquivalent;
        
        emit Staked(tokenId, amount);
    }
}