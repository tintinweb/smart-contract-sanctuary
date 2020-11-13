//   _    _ _   _                __ _                            
//  | |  (_) | | |              / _(_)                           
//  | | ___| |_| |_ ___ _ __   | |_ _ _ __   __ _ _ __   ___ ___ 
//  | |/ / | __| __/ _ \ '_ \  |  _| | '_ \ / _` | '_ \ / __/ _ \
//  |   <| | |_| ||  __/ | | |_| | | | | | | (_| | | | | (_|  __/
//  |_|\_\_|\__|\__\___|_| |_(_)_| |_|_| |_|\__,_|_| |_|\___\___|
//
pragma solidity ^0.5.16;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

interface IUniswapV2Pair {
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

interface kBASEv0 {
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function governance (  ) external view returns ( address );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function monetaryPolicy (  ) external view returns ( address );
  function name (  ) external view returns ( string memory );
  function rebase ( uint256 epoch, int256 supplyDelta ) external returns ( uint256 );
  function setGovernance ( address _governance ) external;
  function setMonetaryPolicy ( address monetaryPolicy_ ) external;
  function symbol (  ) external view returns ( string memory );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
}

contract kBASEPolicyV0 {
    using SafeMath for uint;

    uint public constant PERIOD = 10 minutes; // will be 10 minutes in REAL CONTRACT

    IUniswapV2Pair public pair;
    kBASEv0 public token;

    uint    public price0CumulativeLast = 0;
    uint32  public blockTimestampLast = 0;
    uint224 public price0RawAverage = 0;
    
    uint    public epoch = 0;

    constructor(address _pair) public {
        pair = IUniswapV2Pair(_pair);
        token = kBASEv0(pair.token0());
        price0CumulativeLast = pair.price0CumulativeLast();
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'NO_RESERVES');
    }
    
    uint private constant MAX_INT256 = ~(uint(1) << 255);
    function toInt256Safe(uint a) internal pure returns (int) {
        require(a <= MAX_INT256);
        return int(a);
    }

    function rebase() external {
        uint timestamp = block.timestamp;
        require(timestamp % 3600 < 3 * 60); // rebase can only happen between XX:00:00 ~ XX:02:59 of every hour
        
        uint price0Cumulative = pair.price0CumulativeLast();
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestamp;
        (reserve0, reserve1, blockTimestamp) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'NO_RESERVES');
        
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        require(timeElapsed >= PERIOD, 'PERIOD_NOT_ELAPSED');

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0RawAverage = uint224((price0Cumulative - price0CumulativeLast) / timeElapsed);

        price0CumulativeLast = price0Cumulative;
        blockTimestampLast = blockTimestamp;
        
        // compute rebase
        
        uint price = price0RawAverage;
        price = price.mul(10 ** 17).div(2 ** 112); // USDC decimals = 6, 100000 = 10^5, 18 - 6 + 5 = 17
 
        require(price != 100000, 'NO_NEED_TO_REBASE'); // don't rebase if price = 1.00000
        
        // rebase & sync
        
        if (price > 100000) { // positive rebase
            uint delta = price.sub(100000);
            token.rebase(epoch, toInt256Safe(token.totalSupply().mul(delta).div(100000 * 10))); // rebase using 10% of price delta
        } 
        else { // negative rebase
            uint delta = 100000;
            delta = delta.sub(price);
            token.rebase(epoch, -toInt256Safe(token.totalSupply().mul(delta).div(100000 * 2))); // get out of "death spiral" ASAP
        }
        
        pair.sync();
        epoch = epoch.add(1);
    }
}