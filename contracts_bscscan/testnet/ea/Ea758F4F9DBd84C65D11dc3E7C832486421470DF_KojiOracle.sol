//KOJI BSC Testnet contract address 0xe1528C08A7ddBBFa06e4876ff04Da967b3a43A6A
//BSC Testnet LP address 0x4e1052aB157d3cc240aD178FbdE82c222A322A21

pragma solidity ^0.8.9;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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
      uint256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract KojiOracle {

    using SafeMath for uint256;

    AggregatorV3Interface internal priceFeed;
    IPancakePair internal LP;

    uint256 public minTier1Amount = 1500000000000;
    uint256 public minTier2Amount = 500000000000;

    constructor() {
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);  //bscmainet bnb/usd 0x0567f2323251f0aab15c8dfb1967e4e8a7d42aee
        LP = IPancakePair(0x4e1052aB157d3cc240aD178FbdE82c222A322A21);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundID, 
            uint256 price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getReserves() public view returns (uint256 reserve0, uint256 reserve1) {
      (uint256 Res0, uint256 Res1, uint timestamp) = LP.getReserves();
      return (Res0, Res1);
    }

    function getKojiUSDPrice() public view returns (uint256, uint256, uint256) {

      uint256 bnbusdprice = getLatestPrice();
      bnbusdprice = bnbusdprice.div(100);
      
      (uint256 pooledBNB, uint256 pooledKOJI) = getReserves();

      IBEP20 token0 = IBEP20(LP.token0()); //BNB
      IBEP20 token1 = IBEP20(LP.token1()); //KOJI  (Mainnet pair is opposite!!!)

      bnbusdprice = bnbusdprice.mul(10**token1.decimals()); //make bnb usd price have 9 decimals
      pooledBNB = pooledBNB.div(10**token1.decimals()); //make pooled bnb have 9 decimals

      uint256 pooledBNBUSD = pooledBNB.mul(bnbusdprice); //multiply pooled bnb x usd price of 1 bnb
      uint256 kojiUSD = pooledBNBUSD.div(pooledKOJI); //divide pooled bnb usd price by amount of pooled KOJI
      kojiUSD = kojiUSD.div(10**token1.decimals());

      return (bnbusdprice, pooledBNBUSD, kojiUSD);
    }

    function getMinKOJITier1Amount() public view returns (uint256) {
      (,,uint256 kojiusd) = getKojiUSDPrice();
      return minTier1Amount.div(kojiusd);

    }

    function getMinKOJITier2Amount() public view returns (uint256) {
      (,,uint256 kojiusd) = getKojiUSDPrice();
      return minTier2Amount.div(kojiusd);
    }
}