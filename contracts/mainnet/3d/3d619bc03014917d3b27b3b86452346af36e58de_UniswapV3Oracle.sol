/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function mint(address account, uint amount) external;
  function burn(address account, uint amount) external;
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV3Pool {

  function slot0() external view returns (
    uint160 sqrtPriceX96,
    int24 tick,
    uint16 observationIndex,
    uint16 observationCardinality,
    uint16 observationCardinalityNext,
    uint8 feeProtocol,
    bool unlocked
  );

  function increaseObservationCardinalityNext(
    uint16 observationCardinalityNext
  ) external;
}

interface IUniswapV3Factory {

  function getPool(
    address tokenA,
    address tokenB,
    uint24 fee
  ) external view returns (address pool);
}

interface ILinkOracle {
  function latestAnswer() external view returns(uint);
  function decimals() external view returns(int256);
}

interface IUniswapPriceConverter {

  function assetToAssetThruRoute(
    address _tokenIn,
    uint256 _amountIn,
    address _tokenOut,
    uint32 _twapPeriod,
    address _routeThruToken,
    uint24[2] memory _poolFees
  ) external view returns (uint256 amountOut);
}

contract Ownable {

  address public owner;
  address public pendingOwner;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract UniswapV3Oracle is Ownable {

  IUniswapV3Factory public constant uniFactory    = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
  ILinkOracle       public constant wethOracle    = ILinkOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
  address           public constant WETH          = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  uint24            public constant WETH_POOL_FEE = 3000;

  struct Pool {
    address pairToken;
    uint24  poolFee;
  }

  uint32 public twapPeriod;
  uint16 public minObservations;

  IUniswapPriceConverter public uniPriceConverter;

  mapping(address => Pool) public pools;

  event PoolAdded(address indexed token);
  event PoolRemoved(address indexed token);
  event NewTwapPeriod(uint32 value);
  event NewMinObservations(uint16 value);
  event NewUniPriceConverter(IUniswapPriceConverter value);

  constructor(
    IUniswapPriceConverter _uniPriceConverter,
    uint32       _twapPeriod,
    uint16       _minObservations
  ) {
    uniPriceConverter = _uniPriceConverter;
    twapPeriod        = _twapPeriod;
    minObservations   = _minObservations;
  }

  function addPool(
    address _token,
    address _pairToken,
    uint24  _poolFee
  ) external onlyOwner {

    _validatePool(_token, _pairToken, _poolFee);

    pools[_token] = Pool({
      pairToken: _pairToken,
      poolFee: _poolFee
    });

    emit PoolAdded(_token);
  }

  function removePool(address _token) external onlyOwner {
    pools[_token] = Pool(address(0), 0);
    emit PoolRemoved(_token);
  }

  function setUniPriceConverter(IUniswapPriceConverter _value) external onlyOwner {
    uniPriceConverter = _value;
    emit NewUniPriceConverter(_value);
  }

  function setTwapPeriod(uint32 _value) external onlyOwner {
    twapPeriod = _value;
    emit NewTwapPeriod(_value);
  }

  function setMinObservations(uint16 _value) external onlyOwner {
    minObservations = _value;
    emit NewMinObservations(_value);
  }

  function tokenPrice(address _token) external view returns(uint) {
    require(pools[_token].pairToken != address(0), "UniswapV3Oracle: token not supported");
    _validatePool(_token, pools[_token].pairToken, pools[_token].poolFee);

    uint ethValue = uniPriceConverter.assetToAssetThruRoute(
      _token,
      10 ** IERC20(_token).decimals(),
      WETH,
      twapPeriod,
      pools[_token].pairToken,
      [pools[_token].poolFee, WETH_POOL_FEE]
    );

    return ethValue * ethPrice() / 1e18;
  }

  function ethPrice() public view returns(uint) {
    uint latestAnswer = wethOracle.latestAnswer();
    require(latestAnswer > 1, "LinkPriceOracle: invalid oracle value");
    return latestAnswer * 1e10;
  }

  function isPoolValid(address _token, address _pairToken, uint24 _poolFee) public view returns(bool) {
    address poolAddress = uniFactory.getPool(_token, _pairToken, _poolFee);
    if (poolAddress == address(0)) { return false; }

    (, , , , uint16 observationSlots, ,) = IUniswapV3Pool(poolAddress).slot0();
    return observationSlots >= minObservations;
  }

  function tokenSupported(address _token) external view returns(bool) {
    return pools[_token].pairToken != address(0);
  }

  function _validatePool(address _token, address _pairToken, uint24 _poolFee) internal view {
    require(isPoolValid(_token, _pairToken, _poolFee), "UniswapV3Oracle: invalid pool");
  }
}