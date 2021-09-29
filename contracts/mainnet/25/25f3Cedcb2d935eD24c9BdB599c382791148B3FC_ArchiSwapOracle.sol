// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

interface IArchiSwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract ArchiSwapOracle {
    address updater;
    bool isEveryoneUpdate = false;
    address immutable public pair;
    Observation[65535] public observations;
    uint16 public length;
    uint constant periodSize = 1800;
    uint Q112 = 2**112;
    uint e10 = 10**18;

    constructor(address _pair) {
        pair = _pair;
        updater = msg.sender;
        (,,uint32 timestamp) = IArchiSwapPair(_pair).getReserves();
        uint112 _price0CumulativeLast = uint112(IArchiSwapPair(_pair).price0CumulativeLast() * e10 / Q112);
        uint112 _price1CumulativeLast = uint112(IArchiSwapPair(_pair).price1CumulativeLast() * e10 / Q112);
        observations[length++] = Observation(timestamp, _price0CumulativeLast, _price1CumulativeLast);
    }

    struct Observation {
        uint32 timestamp;
        uint112 price0Cumulative;
        uint112 price1Cumulative;
    }

    function cache(uint size) external {
        uint _length = length+size;
        for (uint i = length; i < _length; i++) observations[i].timestamp = 1;
    }

    function update() external onlyUpdater returns (bool) {
        return _update();
    }

    function updateable() external view returns (bool) {
        Observation memory _point = observations[length-1];
        (,, uint timestamp) = IArchiSwapPair(pair).getReserves();
        uint timeElapsed = timestamp - _point.timestamp;
        return timeElapsed > periodSize;
    }

    function _update() internal returns (bool) {
        Observation memory _point = observations[length-1];
        (,, uint32 timestamp) = IArchiSwapPair(pair).getReserves();
        uint32 timeElapsed = timestamp - _point.timestamp;
        if (timeElapsed > periodSize) {
            uint112 _price0CumulativeLast = uint112(IArchiSwapPair(pair).price0CumulativeLast() * e10 / Q112);
            uint112 _price1CumulativeLast = uint112(IArchiSwapPair(pair).price1CumulativeLast() * e10 / Q112);
            observations[length++] = Observation(timestamp, _price0CumulativeLast, _price1CumulativeLast);
            return true;
        }
        return false;
    }

    function _computeAmountOut(uint start, uint end, uint elapsed, uint amountIn) internal view returns (uint amountOut) {
        amountOut = amountIn * (end - start) / e10 / elapsed;
    }

    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut, uint lastUpdatedAgo) {
        (address token0,) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);

        Observation memory _observation = observations[length-1];
        uint price0Cumulative = IArchiSwapPair(pair).price0CumulativeLast() * e10 / Q112;
        uint price1Cumulative = IArchiSwapPair(pair).price1CumulativeLast() * e10 / Q112;
        (,,uint timestamp) = IArchiSwapPair(pair).getReserves();

        // Handle edge cases where we have no updates, will revert on first reading set
        if (timestamp == _observation.timestamp) {
            _observation = observations[length-2];
        }

        uint timeElapsed = timestamp - _observation.timestamp;
        timeElapsed = timeElapsed == 0 ? 1 : timeElapsed;
        if (token0 == tokenIn) {
            amountOut = _computeAmountOut(_observation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            amountOut = _computeAmountOut(_observation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
        lastUpdatedAgo = timeElapsed;
    }

    function setUpdater(address _newUpdater) external onlyUpdater {
        updater = _newUpdater;
    }

    function setEveryoneUpdate(bool _newIsEveryoneUpdate) external onlyUpdater {
        isEveryoneUpdate = _newIsEveryoneUpdate;
    }

    modifier onlyUpdater() {
        if(!isEveryoneUpdate) {
            require(msg.sender == updater, "ONLY_UPDATER");
        }
        _;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}