// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./Initializable.sol";

contract Rewards is Initializable, PausableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}    

    // shard price
    uint256 private _shardPrice;

    // used for what token should be used for purchasing a sealed nft
    address private _tokenAddress;

    // used for receiving the token (REWARDS AND POOL CONTRA)
    address private _rewardPoolAddress;

    event ShardSold(
        address indexed buyer,
        uint256 indexed shardPrice,
        uint256 indexed shardQty
    );

    struct ShardsPool {
        uint256 total;
        uint256 totalRemaining;
        uint256 totalMinted;
    }

    // total circulating shards on item shop
    mapping (uint256=>ShardsPool) private _shardsPool;

    // current shard index;
    uint256 private _currentShardsPoolIndex;

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();

        _shardPrice = 1 * 10 ** 18; // set shard price to 1 token

        _rewardPoolAddress = address(this);

        _currentShardsPoolIndex = 0;

        _createNewShardsPool(56868750); // 30% of initial supply of timeshards
    }

    function _createNewShardsPool(uint256 _shardsSupply) public onlyOwner {
        require(_shardsPool[_currentShardsPoolIndex].totalRemaining == 0,"Total Remaining shards should be zero");

        _currentShardsPoolIndex = _currentShardsPoolIndex.add(1);

        _shardsPool[_currentShardsPoolIndex] = ShardsPool(_shardsSupply, _shardsSupply, 0); 
    }

    // token address
    function tokenAddress() external view returns (address) {
        return _tokenAddress;
    }

    function setTokenAddress(address _token) external onlyOwner {
        _tokenAddress = _token;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function buyShards(uint256 shardQty) external whenNotPaused {
        require(shardQty > 0 ,"Shard Quantity should be greater than zero");
        require(_rewardPoolAddress != address(0),"Reward pool address not set");
        require(_tokenAddress != address(0),"Token address not set");
        require(_shardsPool[_currentShardsPoolIndex].total >= _shardsPool[_currentShardsPoolIndex].totalMinted.add(shardQty),"Total shards minted reached");
        uint256 totalShardPrice = _shardPrice.mul(shardQty);
        
        _shardsPool[_currentShardsPoolIndex].totalMinted = _shardsPool[_currentShardsPoolIndex].totalMinted.add(shardQty);

        _shardsPool[_currentShardsPoolIndex].totalRemaining = _shardsPool[_currentShardsPoolIndex].totalRemaining.sub(shardQty);
        
        require(IERC20Upgradeable(_tokenAddress).allowance(_msgSender() , address(this))>=totalShardPrice,"Token amount allowance is not enough to buy shards");

        // transfer the token amount to the reward pool address
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(_msgSender(), _rewardPoolAddress, totalShardPrice);

        // emit an event that a shard sold
        emit ShardSold(_msgSender(),_shardPrice, shardQty);
    }

    function shardPrice() external view returns (uint256) {
        return _shardPrice;
    }
    function setShardPrice(uint256 shardPrice_) external onlyOwner {
        _shardPrice = shardPrice_;
    }
}