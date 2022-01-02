// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/chainlink/KeeperCompatible.sol";
import "../interfaces/strategyv2.sol";
import "./interfaces/univ3/pool/IUniswapV3PoolState.sol";

contract PickleRebalancingKeeper is KeeperCompatibleInterface {
    address[] public strategyArray;
    int24 public threshold = 10;

    address public governance;

    constructor(address _governance) public {
        governance = _governance;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setThreshold(int24 _threshold) external {
        require(msg.sender == governance, "!governance");
        threshold = _threshold;
    }

    function addStrategy(address _address) external {
        require(msg.sender == governance, "!governance");
        require(!_search(_address), "Address Already Watched");
        strategyArray.push(_address);
    }

    function removeStrategy(address _address) external {
        require(msg.sender == governance, "!governance");
        require(_search(_address), "Address Not Watched");

        for (uint256 i = 0; i < strategyArray.length; i++) {
            if (strategyArray[i] == _address) {
                strategyArray[i] = strategyArray[strategyArray.length - 1];
                strategyArray.pop();
                break;
            }
        }
    }

    function checkUpkeep(bytes calldata)
        external
        override
        returns (
            bool,
            bytes memory _memory
        )
    {
        for (uint256 i = 0; i < strategyArray.length; i++) {
            int24 _lowerTick = IStrategyV2(strategyArray[i]).tick_lower();
            int24 _upperTick = IStrategyV2(strategyArray[i]).tick_upper();
            int24 _range = _upperTick - _lowerTick;
            int24 _limitVar = _range / threshold;
            int24 _lowerLimit = _lowerTick + _limitVar;
            int24 _upperLimit = _upperTick - _limitVar;

            (, int24 _currentTick, , , , , ) = IUniswapV3PoolState(
                IStrategyV2(strategyArray[i]).pool()
            ).slot0();
            if (_currentTick < _lowerLimit || _currentTick > _upperLimit) {
                return (true, abi.encode(strategyArray[i]));
            }
        }
        return (false, _memory);
    }

    function performUpkeep(bytes memory _calldata) external override {
        address _strategy = abi.decode(_calldata, (address));
        IStrategyV2(_strategy).rebalance();
    }

    function _search(address _address) internal view returns (bool) {
        for (uint256 i = 0; i < strategyArray.length; i++) {
            if (strategyArray[i] == _address) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./KeeperBase.sol";
import "./KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IStrategyV2 {

    function tick_lower() external view returns (int24);

    function tick_upper() external view returns (int24);

    function balanceProportion(int24, int24) external;

    function pool() external view returns (address);

    function timelock() external view returns (address);

    function deposit() external;

    function withdraw(address) external;

    function withdraw(uint256) external returns (uint256, uint256);

    function withdrawAll() external returns (uint256, uint256);

    function liquidityOf() external view returns (uint256);

    function harvest() external;

    function rebalance() external;

    function setTimelock(address) external;

    function setController(address _controller) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract KeeperBase {
  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    require(tx.origin == address(0), "only for simulated backend");
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface KeeperCompatibleInterface {

  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}