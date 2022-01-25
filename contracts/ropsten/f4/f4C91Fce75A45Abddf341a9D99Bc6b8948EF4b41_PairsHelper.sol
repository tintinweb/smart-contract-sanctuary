pragma solidity ^0.8.2;

interface IERC20 {
  function allowance(address spender, address owner)
    external
    view
    returns (uint256);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);
}

interface IPair {
  struct Observation {
    uint256 timestamp;
    uint256 reserve0Cumulative;
    uint256 reserve1Cumulative;
  }

  function token0() external view returns (address);

  function token1() external view returns (address);

  function observationLength() external view returns (uint256);

  function reserve0CumulativeLast() external view returns (uint256);

  function reserve1CumulativeLast() external view returns (uint256);

  function blockTimestampLast() external view returns (uint256);

  function fees() external view returns (address);

  function stable() external view returns (bool);

  function symbol() external view returns (string memory);

  function index0() external view returns (uint256);

  function index1() external view returns (uint256);

  function reserve0() external view returns (uint256);

  function reserve1() external view returns (uint256);
}

contract PairsHelper {
  address public ownerAddress;
  address public defaultFactoryAddress;

  constructor(address _defaultFactoryAddress) {
    defaultFactoryAddress = _defaultFactoryAddress;
  }

  function setDefaultFactoryAddress(address _defaultFactoryAddress) external {
    require(msg.sender == ownerAddress, "Ownable: only owner");
    defaultFactoryAddress = _defaultFactoryAddress;
  }

  function setOwnerAddress(address _ownerAddress) external {
    require(msg.sender == ownerAddress, "Ownable: only owner");
    ownerAddress = _ownerAddress;
  }

  function pairsLength() public view returns (uint256) {
    return IUniswapV2Factory(defaultFactoryAddress).allPairsLength();
  }

  function pairsLength(address factoryAddress) public view returns (uint256) {
    return IUniswapV2Factory(factoryAddress).allPairsLength();
  }

  function pagesLength(uint256 pageSize) public view returns (uint256) {
    return pagesLength(defaultFactoryAddress, pageSize);
  }

  function pagesLength(address factoryAddress, uint256 pageSize)
    public
    view
    returns (uint256)
  {
    uint256 _pairsLength = pairsLength(factoryAddress);
    uint256 _pagesLength = _pairsLength / pageSize;
    return _pagesLength + 1;
  }

  function pairsAddresses(uint256 pageSize, uint256 pageNbr)
    external
    view
    returns (address[] memory)
  {
    return pairsAddresses(defaultFactoryAddress, pageSize, pageNbr);
  }

  function pairsAddresses(
    address factoryAddress,
    uint256 pageSize,
    uint256 pageNbr
  ) public view returns (address[] memory) {
    uint256 _pairsLength = pairsLength(factoryAddress);
    uint256 startIdx = pageNbr * pageSize;
    uint256 endIdx = startIdx + pageSize;
    if (startIdx > _pairsLength - 1) {
      return new address[](0);
    }
    if (endIdx > _pairsLength - 1) {
      endIdx = _pairsLength;
    }

    uint256 numberOfPairsToReturn = endIdx - startIdx;
    address[] memory _pairsAddresses = new address[](numberOfPairsToReturn);
    for (uint256 pairIdx; pairIdx < numberOfPairsToReturn; pairIdx++) {
      address pairAddress = IUniswapV2Factory(factoryAddress).allPairs(
        pairIdx + startIdx
      );
      _pairsAddresses[pairIdx] = pairAddress;
    }
    return _pairsAddresses;
  }

  function pairsAddresses() public view returns (address[] memory) {
    return pairsAddresses(defaultFactoryAddress);
  }

  function pairsAddresses(address factoryAddress)
    public
    view
    returns (address[] memory)
  {
    uint256 _pairsLength = pairsLength(factoryAddress);
    return pairsAddresses(factoryAddress, _pairsLength, 0);
  }

  struct Pair {
    address id;
    string symbol;
    bool stable;
    address token0;
    address token1;
    uint256 observationLength;
    uint256 reserve0CumulativeLast;
    uint256 reserve1CumulativeLast;
    uint256 blockTimestampLast;
    address fees;
    uint256 index0;
    uint256 index1;
    uint256 reserve0;
    uint256 reserve1;
  }

  function pairsInfo(address[] memory _pairsAddresses)
    public
    view
    returns (Pair[] memory)
  {
    Pair[] memory pairs = new Pair[](_pairsAddresses.length);
    for (uint256 pairIdx; pairIdx < _pairsAddresses.length; pairIdx++) {
      address pairAddress = _pairsAddresses[pairIdx];
      IPair pair = IPair(pairAddress);

      pairs[pairIdx] = Pair({
        id: pairAddress,
        symbol: pair.symbol(),
        stable: pair.stable(),
        token0: pair.token0(),
        token1: pair.token1(),
        observationLength: pair.observationLength(),
        reserve0CumulativeLast: pair.reserve0CumulativeLast(),
        reserve1CumulativeLast: pair.reserve1CumulativeLast(),
        blockTimestampLast: pair.blockTimestampLast(),
        fees: pair.fees(),
        index0: pair.index0(),
        index1: pair.index1(),
        reserve0: pair.reserve0(),
        reserve1: pair.reserve1()
      });
    }
    return pairs;
  }

  function pairsInfo() external view returns (Pair[] memory) {
    return pairsInfo(pairsAddresses());
  }
}