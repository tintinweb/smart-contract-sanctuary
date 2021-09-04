/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        ));
    }
}

interface erc20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface PositionManagerV3 {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    function safeTransferFrom(address from, address to, uint tokenId) external;

    function ownerOf(uint tokenId) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;
     function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

interface UniV3 {
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
    function liquidity() external view returns (uint128);
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
}

contract StakingRewardsV3 {

    address immutable public reward;
    address immutable public pool;

    address constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    PositionManagerV3 constant nftManager = PositionManagerV3(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    uint constant DURATION = 7 days;
    uint constant PRECISION = 10 ** 18;

    uint rewardRate;
    uint periodFinish;
    uint lastUpdateTime;
    uint rewardPerLiquidityStored;
    uint public forfeit;

    mapping(uint => uint) public tokenRewardPerLiquidityPaid;
    mapping(uint => uint) public rewards;
    
    address immutable owner;

    struct time {
        uint32 timestamp;
        uint32 secondsInside;
    }

    mapping(uint => time) public elapsed;
    mapping(uint => address) public owners;
    mapping(address => uint[]) public tokenIds;
    mapping(uint => uint) public liquidityOf;
    uint public totalLiquidity;
    
    uint public earned0;
    uint public earned1;

    event RewardPaid(address indexed sender, uint tokenId, uint reward);
    event RewardAdded(address indexed sender, uint reward);
    event Deposit(address indexed sender, uint tokenId, uint liquidity);
    event Withdraw(address indexed sender, uint tokenId, uint liquidity);
    event Collect(address indexed sender, uint tokenId, uint amount0, uint amount1);

    constructor(address _reward, address _pool) {
        reward = _reward;
        pool = _pool;
        owner = msg.sender;
    }

    function getTokenIds(address _owner) external view returns (uint[] memory) {
        return tokenIds[_owner];
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerLiquidity() public view returns (uint) {
        if (totalLiquidity == 0) {
            return rewardPerLiquidityStored;
        }
        return rewardPerLiquidityStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * PRECISION / totalLiquidity);
    }
    
    function collect(uint tokenId) external {
        _collect(tokenId);
    }
    
    function _collect(uint tokenId) internal {
        if (owners[tokenId] != address(0)) {
            PositionManagerV3.CollectParams memory _claim = PositionManagerV3.CollectParams(tokenId, owner, type(uint128).max, type(uint128).max);
            (uint amount0, uint amount1) = nftManager.collect(_claim);
            earned0 += amount0;
            earned1 += amount1;
            emit Collect(msg.sender, tokenId, amount0, amount1);
        }
    }

    function earned(uint tokenId) public view returns (uint claimable, uint32 secondsInside, uint128 liquidity, uint forfeited) {
        (int24 _tickLower, int24 _tickUpper) = (0,0);
        (,,,,,_tickLower,_tickUpper,liquidity,,,,) = nftManager.positions(tokenId);
        (,,secondsInside) = UniV3(pool).snapshotCumulativesInside(_tickLower, _tickUpper);
        (,int24 _tick,,,,,) = UniV3(pool).slot0();
        
        claimable = rewards[tokenId];
        uint _liquidity = liquidityOf[tokenId];
        if (_liquidity > 0) {
            time memory _elapsed = elapsed[tokenId];
        
            uint _maxSecondsElapsed = lastTimeRewardApplicable() - Math.min(_elapsed.timestamp, periodFinish);
            uint _secondsInside = Math.min(_maxSecondsElapsed, (secondsInside - _elapsed.secondsInside));
            
            uint _reward = (_liquidity * (rewardPerLiquidity() - tokenRewardPerLiquidityPaid[tokenId]) / PRECISION);
            uint _earned = _reward * _secondsInside / _maxSecondsElapsed;
            forfeited = _reward - _earned;
            claimable += _earned;
            
            if (_tickLower > _tick || _tick > _tickUpper) {
                forfeited = claimable;
                claimable = 0;
                liquidity = 0;
            }
        }
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate * DURATION;
    }

    function deposit(uint tokenId) external update(tokenId) {
        (,,address token0,address token1,uint24 fee,int24 tickLower,int24 tickUpper,uint128 _liquidity,,,,) = nftManager.positions(tokenId);
        address _pool = PoolAddress.computeAddress(factory,PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee}));

        require(pool == _pool);
        require(_liquidity > 0);
        
        (,int24 _tick,,,,,) = UniV3(_pool).slot0();
        require(tickLower < _tick && _tick < tickUpper);
        
        owners[tokenId] = msg.sender;
        tokenIds[msg.sender].push(tokenId);

        nftManager.transferFrom(msg.sender, address(this), tokenId);

        emit Deposit(msg.sender, tokenId, _liquidity);
    }

    function _findIndex(uint[] memory array, uint element) internal pure returns (uint i) {
        for (i = 0; i < array.length; i++) {
            if (array[i] == element) {
                break;
            }
        }
    }

    function _remove(uint[] storage array, uint element) internal {
        uint _index = _findIndex(array, element);
        uint _length = array.length;
        if (_index >= _length) return;
        if (_index < _length-1) {
            array[_index] = array[_length-1];
        }

        array.pop();
    }

    function withdraw(uint tokenId) public update(tokenId) {
        _collect(tokenId);
        _withdraw(tokenId);
    }
    
    function _withdraw(uint tokenId) internal {
        require(owners[tokenId] == msg.sender);
        uint _liquidity = liquidityOf[tokenId];
        liquidityOf[tokenId] = 0;
        totalLiquidity -= _liquidity;
        owners[tokenId] = address(0);
        _remove(tokenIds[msg.sender], tokenId);
        nftManager.safeTransferFrom(address(this), msg.sender, tokenId);

        emit Withdraw(msg.sender, tokenId, _liquidity);
    }

    function getRewards() external {
        uint[] memory _tokens = tokenIds[msg.sender];
        for (uint i = 0; i < _tokens.length; i++) {
            getReward(_tokens[i]);
        }
    }

    function getReward(uint tokenId) public update(tokenId) {
        _collect(tokenId);
        uint _reward = rewards[tokenId];
        if (_reward > 0) {
            rewards[tokenId] = 0;
            _safeTransfer(reward, _getRecipient(tokenId), _reward);

            emit RewardPaid(msg.sender, tokenId, _reward);
        }
    }

    function _getRecipient(uint tokenId) internal view returns (address) {
        if (owners[tokenId] != address(0)) {
            return owners[tokenId];
        } else {
            return nftManager.ownerOf(tokenId);
        }
    }

    function withdraw() external {
        uint[] memory _tokens = tokenIds[msg.sender];
        for (uint i = 0; i < _tokens.length; i++) {
            withdraw(_tokens[i]);
        }
    }

    function notify(uint amount) external update(0) {
        require(msg.sender == owner);
        if (block.timestamp >= periodFinish) {
            rewardRate = amount / DURATION;
        } else {
            uint _remaining = periodFinish - block.timestamp;
            uint _leftover = _remaining * rewardRate;
            
            rewardRate = (amount + _leftover) / DURATION;
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
        
        _safeTransferFrom(reward, msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }
    
    function refund() external {
        require(msg.sender == owner);
        uint _forfeit = forfeit;
        forfeit = 0;
        
        _safeTransfer(reward, owner, _forfeit);
    }

    modifier update(uint tokenId) {
        uint _rewardPerLiquidityStored = rewardPerLiquidity();
        uint _lastUpdateTime = lastTimeRewardApplicable();
        rewardPerLiquidityStored = _rewardPerLiquidityStored;
        lastUpdateTime = _lastUpdateTime;
        if (tokenId != 0) {
            (uint _reward, uint32 _secondsInside, uint _liquidity, uint _forfeited) = earned(tokenId);
            tokenRewardPerLiquidityPaid[tokenId] = _rewardPerLiquidityStored;
            rewards[tokenId] = _reward;
            forfeit += _forfeited;

            if (elapsed[tokenId].timestamp < _lastUpdateTime) {
                elapsed[tokenId] = time(uint32(_lastUpdateTime), _secondsInside);
            }
            
            uint _currentLiquidityOf = liquidityOf[tokenId];
            if (_currentLiquidityOf != _liquidity) {
                totalLiquidity -= _currentLiquidityOf;
                liquidityOf[tokenId] = _liquidity;
                totalLiquidity += _liquidity;
            }
        }
        _;
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}