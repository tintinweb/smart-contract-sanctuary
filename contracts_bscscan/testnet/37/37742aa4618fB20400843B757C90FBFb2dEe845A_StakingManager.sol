//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./IERC721Enumerable.sol";
import "./ILockStakingRewards.sol";

interface IShop {
}

contract StakingManager is Ownable {
    IERC721Enumerable public snakeNFT;
    address public snakeShop;

    uint256 public NFTCount;

    mapping(address => ILockStakingRewards) public stakingPools;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public stakingNonceNFT; //user => stakingPool => nonce => tokenId

    event ProcessStake(address indexed stakingToken, address indexed receiver, uint256 amount, uint256 stakingNonce, uint256 indexed tokenId);
    event ProcessTransfer(address indexed sender, address indexed recepient, uint256 indexed tokenId);
    event ProcessWithdrawal(address indexed stakingToken, uint256 indexed tokenId);
    event ProcessClaimReward(address indexed stakingToken, uint256 indexed tokenId);

    constructor(address snakeNFT_) {
        require(Address.isContract(snakeNFT_), "snakeNFT_ is not a contract");

        snakeNFT = IERC721Enumerable(snakeNFT_);
    }

    modifier onlyShopContract() {
        require(msg.sender == snakeShop, "StakeManager: Caller is not a shop contract");
        _;
    }
    
    modifier onlyTokenOwner(uint256 tokenId) {
        require(snakeNFT.ownerOf(tokenId) == _msgSender(), "StakingManager: Caller is not an owner of a token");
        _;
    }

    function updateStakingPool(address stakingToken, address stakingPool) external onlyOwner {
        require(Address.isContract(stakingToken) && Address.isContract(stakingPool), "StakingManager: Staking pool or staking token is not a contract");
        stakingPools[stakingToken] = ILockStakingRewards(stakingPool);
    }

    function updateSnakeShop(address snakeShop_) external onlyOwner {
        require(Address.isContract(snakeShop_), "StakingManager: snakeShop_ is not a contract");
        snakeShop = snakeShop_;
    }

    function updareNFTConract(address snakeNFT_) external onlyOwner {
        require(Address.isContract(snakeNFT_), "StakingManager: snakeNFT_ is not a contract");
        snakeNFT = IERC721Enumerable(snakeNFT_);
    }

    function processStake(address stakingToken, uint256 amount, address user) external onlyShopContract {
        ILockStakingRewards stakingPool = stakingPools[stakingToken];
        require(address(stakingPool) != address(0), "StakingManager: No staking pool for token");
        uint tokenId = ++NFTCount;
        snakeNFT.safeMint(user, tokenId);
        uint256 nonce = stakingPool.stakeFor(amount, tokenId, user);
        stakingNonceNFT[address(stakingPool)][user][nonce] = tokenId;

        emit ProcessStake(stakingToken, user, amount, nonce, tokenId);
    }  

    function processTransfer(uint256 tokenId, address receiver) external onlyTokenOwner(tokenId) {
        address owner = snakeNFT.ownerOf(tokenId);
        snakeNFT.safeTransferFrom(owner, receiver, tokenId);

        emit ProcessTransfer(owner, receiver, tokenId);
    }

    function processWithdrawal(address stakingToken, uint256 tokenId) external onlyTokenOwner(tokenId) {
        ILockStakingRewards stakingPool = stakingPools[stakingToken];
        require(address(stakingPool) != address(0), "StakingManager: No staking pool for token");

        stakingPool.withdraw(tokenId, 1);

        emit ProcessWithdrawal(stakingToken, tokenId);
    }

    function processClaimReward(address stakingToken, uint256 tokenId) external onlyTokenOwner(tokenId) {
        ILockStakingRewards stakingPool = stakingPools[stakingToken];
        require(address(stakingPool) != address(0), "StakingManager: No staking pool for token");

        stakingPool.getReward(tokenId);

        emit ProcessClaimReward(stakingToken, tokenId);
    }
}