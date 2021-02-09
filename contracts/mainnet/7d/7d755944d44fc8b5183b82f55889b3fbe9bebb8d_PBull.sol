/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

pragma solidity 0.5.0;

// Using Uniswap interface for price feed of Peerex


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

/*
interface IUniswapSync {
    function sync() external;
}*/

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}


contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  function isConstructor() private view returns (bool) {
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  uint256[50] private ______gap;
}

contract Ownable is Initializable {

  address private _owner;
  uint256 private _ownershipLocked;

  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  function initialize(address sender) internal initializer {
    _owner = sender;
	_ownershipLocked = 0;
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  // Set _ownershipLocked flag to lock contract owner forever
  function lockOwnership() public onlyOwner {
	require(_ownershipLocked == 0);
	emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private ______gap;
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function initialize(string memory name, string memory symbol, uint8 decimals) internal initializer {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }

  uint256[50] private ______gap;
}

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
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
MIT License
Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/


library SafeMathInt {

    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}

contract PBull is Ownable, ERC20Detailed {




    using SafeMath for uint256;
    using SafeMathInt for int256;
	using UInt256Lib for uint256;

	struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }


    event TransactionFailed(address indexed destination, uint index, bytes data);

	// Stable ordering is not guaranteed.

    Transaction[] public transactions;


    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }



    IUniswapV2Pair private _pairUSD;
    IUniswapV2Pair private _pairAAA;
    uint256 private constant ETH_DECIMALS = 18;
    //Currently using USDC
    uint256 private constant USD_DECIMALS = 6;

	uint256 private constant PRICE_PRECISION = 10**9;


  uint256 public PerxNow;
  uint256 public PerxOld;
  uint256 public LevUp;
  uint256 public LevDown;
  uint256 public TokenBurn;
  uint256 public TokenAdd;
  uint256 public Change;
  uint256 public DLimit;
  uint256 public EnableReb;
  uint256 public EnableFee;
  address public UniAdd;
  address public Collector;
  address public UniLP;
  uint256 public Collect;
  uint256 public Rvalue;
  uint256 public Fee;
  uint256 public constant PrPrecision = 1000000;
  address public Rebalancer;


    uint256 public constant DECIMALS = 9;
    uint256 public constant MAX_UINT256 = ~uint256(0);
    uint256 public constant INITIAL_SUPPLY = 5 * 10**4 * 10**DECIMALS;



    uint256 public _totalSupply;



    mapping(address => uint256) public _updatedBalance;
    mapping(address => uint256) public blacklist;



    mapping (address => mapping (address => uint256)) public _allowance;

	constructor() public {

		Ownable.initialize(msg.sender);
		ERC20Detailed.initialize("PeerEx Bull", "PBULL", uint8(DECIMALS));

        _totalSupply = INITIAL_SUPPLY;
        _updatedBalance[msg.sender] = _totalSupply;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }


    modifier onlyRebalancer() {
      require(isRebalancer());
      _;
    }

    function isRebalancer() public view returns(bool) {
      return msg.sender == Rebalancer;
    }

    /// Set Rebalancer
            function setRebalancer(address _rebalance)
                  external
                onlyOwner
                {
                Rebalancer = _rebalance;
                }


    //Set value for address to 1 for blacklisting
    //Blacklisting is created for protection against front run bots on uniswap
    function Addblacklist(address _blackadd, uint256 _blackvalue)
    external
    onlyOwner
    {
        blacklist[_blackadd] = _blackvalue;
    }


    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

	/**
     * @param who The address to query.
     * @return The balance of the specified address.
     */

    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        return _updatedBalance[who];
    }

	/**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */

    function transfer(address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {
      require(blacklist[msg.sender]!=1);

        _updatedBalance[msg.sender] = _updatedBalance[msg.sender].sub(value);

        if(EnableFee==1)
        {
          Rvalue=TransferFee(value);
          emit Transfer(msg.sender, Collector, Collect);
        }
        else
        {
        Rvalue=value;

        }
        _updatedBalance[to] = _updatedBalance[to].add(Rvalue);


        emit Transfer(msg.sender, to, value);


        return true;
    }




	/**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */

    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowance[owner_][spender];
    }

	/**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */

    function transferFrom(address from, address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {
       require(blacklist[from]!=1);

        _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);

        _updatedBalance[from] = _updatedBalance[from].sub(value);

        if(EnableFee==1)
        {
          Rvalue=TransferFee(value);
          emit Transfer(from, Collector, Collect);
        }
        else
        {
        Rvalue=value;
        }
        _updatedBalance[to] = _updatedBalance[to].add(Rvalue);


        emit Transfer(from, to, Rvalue);


        return true;
    }


	/**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */

    function approve(address spender, uint256 value)
        public
        returns (bool)
    {
        _allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

	/**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

	/**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowance[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

// Transction fee collection
    function TransferFee(uint256 value) internal returns (uint256)

    {
      Collect = value.mul(Fee).div(100000);  // fee is the percentage value * 1000
      Rvalue=value.sub(Collect);
      _updatedBalance[Collector] = _updatedBalance[Collector].add(Collect);



      return Rvalue;
    }

/// Set fee collector
        function setCollector(address _Collector)
              external
            onlyOwner
            {
            Collector = _Collector;
            }

/// Set EnableFee==1 for enabling transaction fees
         function setEnablefee(uint256 _EnableFee)
                  external
                  onlyOwner
              {
              EnableFee = _EnableFee;
              }
  /// Set Transaction fee %, example, if 1% is the fee then set fee= 1000;
         function setTransfee(uint256 _TransFee)
            external
          onlyOwner
          {
          Fee = _TransFee;
          }

/// Set EnableReb==1 for enabling rebalance function
          function setEnableReb(uint256 _EnableReb)
              external
              onlyOwner
          {
          EnableReb = _EnableReb;
          }

/// Set Uniswap pair of ETH/USD for price input
      function setPairUSD(address factory, address token0, address token1)
          external
          onlyOwner
      {
      _pairUSD = IUniswapV2Pair(UniswapV2Library.pairFor(factory, token0, token1));
      }

      function setPairAAA(address factory, address token0, address token1)
            external
            onlyOwner
        {
    		_pairAAA = IUniswapV2Pair(UniswapV2Library.pairFor(factory, token0, token1));

        }

// Get price of above set pair
      function getPriceETH_USD() public view returns (uint256) {

          require(address(_pairUSD) != address(0));

  	    (uint256 reserves0, uint256 reserves1,) = _pairUSD.getReserves();

  	    // reserves0 = USDC (8 decimals) ETH
  	    // reserves1 = ETH (18 decimals) USD

          uint256 price = reserves0.mul(10**(18-USD_DECIMALS)).mul(PRICE_PRECISION).div(reserves1);

          return price;
      }

      function getPriceAAA_ETH() public view returns (uint256) {

    	    require(address(_pairAAA) != address(0));

    	    (uint256 reserves0, uint256 reserves1,) = _pairAAA.getReserves();

    	    // reserves0 = peerex
    	    // reserves1 = EThereum

    	    // multiply to equate decimals, multiply up to PRICE_PRECISION
            uint256 price = reserves1.mul(PRICE_PRECISION).div(reserves0);

            return price;
        }


      function getPriceAAA_USD() public view returns (uint256) {

          require(address(_pairAAA) != address(0));
          require(address(_pairUSD) != address(0));

          uint256 priceAAA_ETH = getPriceAAA_ETH();
          uint256 priceETH_USD = getPriceETH_USD();
  	    uint256 priceAAA_USD = priceAAA_ETH.mul(priceETH_USD).div(PRICE_PRECISION);

          return priceAAA_USD;
      }



// Set the address of Ebull uniswap Liquidity contract to be used in rebalance function
      function InputUniLP(address _UniLP)
       onlyOwner
          external
      {
          UniLP= _UniLP;
      }

      function UniLPAddress()
          public
          view
          returns (address)
      {
          return UniLP;
      }

/// Set the upside leverage
      function setLevUp(uint256 _LevUp) //  set integer values like 1,2,3...etc.
          external
          onlyOwner
      {
      LevUp = _LevUp;
      }

/// Set the Downside leverage
      function setLevDown(uint256 _LevDown) //  set integer values like 1,2,3...etc.
          external
          onlyOwner
        {
          LevDown = _LevDown;
        }
// Set Downside limit per rebalance call. This limit is needed as price cannot go down more than 100%,
      function setDLimit(uint256 _DLimit) //  Example, for 50% down limit, set value to 0.5*e6
            external
            onlyOwner
          {
            DLimit = _DLimit;
          }

// Initialise the price of PerxOld for the first rebalance call
  function InitialPerxPrice()
    external
    onlyOwner
  {
    PerxOld = getPriceAAA_USD();
  }




// Rebalance function changes the price of ebull in uniswap depending on the leveraged fluctuation in perx Price
    function ReBalance()
      public
      onlyRebalancer
    returns (bool)
    { require(EnableReb==1,"Rebalance not enabled");

        PerxNow = getPriceAAA_USD();

        if(PerxNow >= PerxOld)
        {
         Change= PrPrecision.add(LevUp.mul(PrPrecision).mul(PerxNow.sub(PerxOld)).div(PerxOld));  // LevUp is upside leverage = 3
          TokenBurn = _updatedBalance[UniLP].sub(_updatedBalance[UniLP].mul(PrPrecision).div(Change));
          TokenBurn=TokenBurn.div(10**DECIMALS);
          _updatedBalance[UniLP] = _updatedBalance[UniLP].sub(TokenBurn.mul(10**DECIMALS));
          _totalSupply = _totalSupply.sub(TokenBurn.mul(10**DECIMALS));
        }
        else
        {
          Change= LevDown.mul(PrPrecision).mul(PerxOld.sub(PerxNow)).div(PerxOld);  // LevDown is downside leverage = 2

          if(Change>DLimit) // downside limit per transaction = 0.5*10**6
          {
          Change = DLimit;
          }

          Change= PrPrecision.sub(Change);
          TokenAdd = _updatedBalance[UniLP].mul(PrPrecision).div(Change);
          TokenAdd = TokenAdd.sub(_updatedBalance[UniLP]);
          TokenAdd=TokenAdd.div(10**DECIMALS);
          _updatedBalance[UniLP] = _updatedBalance[UniLP].add(TokenAdd.mul(10**DECIMALS));
          _totalSupply = _totalSupply.add(TokenAdd.mul(10**DECIMALS));
        }



    IUniswapV2Pair(UniLP).sync();
    PerxOld = PerxNow;
    return true;
}



}