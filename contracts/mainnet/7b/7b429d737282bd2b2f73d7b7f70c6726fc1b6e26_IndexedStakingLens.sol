/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;


contract IndexedStakingLens {
  struct StakingPool {
    uint256 pid;
    address stakingToken;
    bool isPairToken;
    address token0;
    address token1;
    uint256 amountStaked;
    uint256 ndxPerDay;
    string symbol;
  }

  // Assume 13.5 sec per block
  uint256 internal constant BLOCKS_PER_DAY = 864000 / 135;
  IMultiTokenStaking public constant stakingContract = IMultiTokenStaking(0xC46E0E7eCb3EfCC417f6F89b940FFAFf72556382);

  function getPool(
    uint256 i,
    uint256 totalAllocPoint,
    uint256 totalNdxPerDay
  ) internal view returns (StakingPool memory pool) {
    pool.pid = i;
    pool.stakingToken = stakingContract.lpToken(i);
    IUniswapV2Pair poolAsPair = IUniswapV2Pair(pool.stakingToken);
    try poolAsPair.getReserves() returns (uint112, uint112, uint32) {
      pool.isPairToken = true;
      pool.token0 = poolAsPair.token0();
      pool.token1 = poolAsPair.token1();
      pool.symbol = string(abi.encodePacked(
        SymbolHelper.getSymbol(pool.token0),
        "/",
        SymbolHelper.getSymbol(pool.token1)
      ));
    } catch {
      pool.symbol = SymbolHelper.getSymbol(pool.stakingToken);
    }
    pool.amountStaked = IERC20(pool.stakingToken).balanceOf(address(stakingContract));
    pool.ndxPerDay = (stakingContract.poolInfo(i).allocPoint * totalNdxPerDay) / totalAllocPoint;
  }

  function getPools() external view returns (StakingPool[] memory arr) {
    uint256 len = stakingContract.poolLength();
    arr = new StakingPool[](len);
    uint256 totalAllocPoint = stakingContract.totalAllocPoint();
    uint256 totalNdxPerDay = stakingContract.rewardsSchedule().getRewardsForBlockRange(block.number, block.number + BLOCKS_PER_DAY);
    for (uint256 i; i < len; i++) {
      arr[i] = getPool(i, totalAllocPoint, totalNdxPerDay);
    }
  }
}


library SymbolHelper {

  /**
   * @dev Returns the index of the lowest bit set in `self`.
   * Note: Requires that `self != 0`
   */
  function lowestBitSet(uint256 self) internal pure returns (uint256 _z) {
    require (self > 0, "Bits::lowestBitSet: Value 0 has no bits set");
    uint256 _magic = 0x00818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    uint256 val = (self & -self) * _magic >> 248;
    uint256 _y = val >> 5;
    _z = (
      _y < 4
        ? _y < 2
          ? _y == 0
            ? 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            : 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
          : _y == 2
            ? 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            : 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
        : _y < 6
          ? _y == 4
            ? 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            : 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
          : _y == 6
            ? 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            : 0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
    );
    _z >>= (val & 0x1f) << 3;
    return _z & 0xff;
  }

  function getSymbol(address token) internal view returns (string memory) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("symbol()"));
    if (!success) return "UNKNOWN";
    if (data.length != 32) return abi.decode(data, (string));
    uint256 symbol = abi.decode(data, (uint256));
    if (symbol == 0) return "UNKNOWN";
    uint256 emptyBits = 255 - lowestBitSet(symbol);
    uint256 size = (emptyBits / 8) + (emptyBits % 8 > 0 ? 1 : 0);
    assembly { mstore(data, size) }
    return string(data);
  }
}


interface IMultiTokenStaking {
  struct PoolInfo {
    uint128 accRewardsPerShare;
    uint64 lastRewardBlock;
    uint64 allocPoint;
  }

  function poolLength() external view returns (uint256);

  function lpToken(uint256) external view returns (address);

  function poolInfo(uint256) external view returns (PoolInfo memory);

  function totalAllocPoint() external view returns (uint256);

  function rewardsSchedule() external view returns (IRewardsSchedule);
}

interface IRewardsSchedule {
  function getRewardsForBlockRange(uint256 from, uint256 to) external view returns (uint256);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
}

interface IERC20 {
  function balanceOf(address) external view returns (uint256);
}