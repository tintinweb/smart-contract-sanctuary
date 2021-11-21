/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

// File: futureExchange/IERC20.sol

pragma solidity 0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: futureExchange/SafeMath.sol

pragma solidity 0.8.9;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    function div(
    uint256 a,
    uint256 b
      )
        internal
        pure
        returns (
          uint256
        )
      {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    
        return c;
      }
}

// File: futureExchange/IRGPFutureExchange.sol

pragma solidity 0.8.9;

interface IRGPFutureExchange {
    enum SIDE {
        buy,
        sell
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event transact(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event marginTrader(address magProvider, uint256 amount);

    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint256 reserve);

    function mint( uint256 amount) external returns (uint liquidity);
    function burn( uint256 amount) external  returns (uint liquidity);

    function initialize(address, address) external;
    function getTrading(uint256 amount, uint256 filled, uint256 _leverage, SIDE side) external view returns(uint256 totalTradeable, uint256 liquidation, uint256 userGetProfit);
    function getTraderBalance() external returns(uint256 traderBalance);
    function updateTraderBalance(uint256 _amount, bool status) external;
    function createLimitOrder(address order, uint256 amount, uint256 price0, uint256 price,  uint256 _leverage, SIDE side) external  
        returns (uint256 totalTradeable, uint256 liquidation, uint256 userGetProfit);
    
}

// File: futureExchange/rigelFutureExchangeInterface.sol


pragma solidity 0.8.9;

interface rigelFutureExchangeInterface {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: futureExchange/RGPExchangeERC20.sol


pragma solidity 0.8.9;

contract RGPExchangeERC20 {
    using SafeMath for uint;

    string public constant name = 'RGP Future Exchange';
    string public constant symbol = 'FLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint256 chainId = getChainID();
        
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }
    
    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != 0) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// File: futureExchange/rigelFutureExchangePair.sol

pragma solidity 0.8.9;

// import './futureExchangeCal.sol';

contract rigelFutureExchangePair is IRGPFutureExchange, RGPExchangeERC20 {
    using SafeMath  for uint;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;
    
    uint256 private constant liquidityRatio = 25000;
    uint private reserve;
    uint256 public nextOrderID;
    
    struct Order {
        SIDE side;              // chose the side of the Order to place
        address ticker;         // the address of the token
        uint256 amount;         // amount
        uint256 filled;
        uint256 price;
        uint256 date;
        uint256 id;             // to represent the ID of the Order
    }
    
    mapping(address => mapping(uint256 => Order[]))  public orderBook;
    mapping(address => mapping(address => uint256)) private traderBalances;

    modifier tokenNotTradeable(address order) {
        require(order != token0, "cannot trade leverage Token");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'rigelFutureExchangeFactory: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }
    
    function getTraderBalance() public view returns(uint256 traderBalance) {
        traderBalance = (traderBalances[token0][msg.sender]);
        return traderBalance;
    }
    
    function updateTraderBalance( uint256 _amount, bool status) public override{
        if(status == true) {
            RGPExchangeERC20(token0).transferFrom(msg.sender, address(this), _amount);
            traderBalances[token0][msg.sender] += _amount;
            emit marginTrader(msg.sender, _amount);
        }  else {
            require(_amount <= traderBalances[token0][msg.sender], "INSUFFICIENT_TRADING_AMOUNT");
            traderBalances[token0][msg.sender] -= _amount;
            RGPExchangeERC20(token0).transfer(msg.sender, _amount);
            emit marginTrader(msg.sender, _amount);
        }
    }

    function getReserves() public view returns (uint256 reserve0) {
        return reserve;
    }
    
    function mint( uint256 amount) external returns (uint256 liquidity) {
        require(msg.sender != address(0), "ERC20: mint to the zero address");
        liquidity = amount / liquidityRatio;
        require(liquidity > 0, 'RGP: INSUFFICIENT_LIQUIDITY_MINTED');
        RGPExchangeERC20(token0).transferFrom(msg.sender, address(this), amount);
        reserve = reserve + amount;
        _mint(msg.sender, liquidity);
        
    }
    
    function burn(uint256 amount) external returns (uint256 _amount) {
        require(msg.sender != address(0), "ERC20: mint to the zero address");
        (_amount = amount * liquidityRatio);
        reserve = reserve - _amount;
        _burn(msg.sender, amount);
        RGPExchangeERC20(token0).transfer(msg.sender, _amount);
        
    }
    
    function getTrading(uint256 amount, uint256 filled, uint256 _leverage, SIDE side) public view returns(uint256 totalTradeable, uint256 liquidation, uint256 userGetProfit) {
        if(side == SIDE.buy) {
            // get user liquidation price
            liquidation = filled - (filled * _leverage / 100E18);
            // get user reward price
            userGetProfit = filled + (filled * _leverage / 100E18);
            // user tradeable amount in X
            uint256 tradeable = (amount * _leverage - amount) / 1E18;
            // amount that user can trade
            totalTradeable = tradeable + (amount / 1E18);
            
            uint256 allowable_lev = (getReserves() * 10E18 / 100E18);
            require(totalTradeable <= allowable_lev, "Rigel: Amount is greater than max allowable");
            
        } else {
            // get user liquidation price
            liquidation = filled + (filled * _leverage / 100E18);
            // get user reward price
            userGetProfit = filled - (filled * _leverage / 100E18);
            // user tradeable amount in X
            uint256 tradeable = amount * _leverage - amount;
            // amount that user can trade
            totalTradeable = tradeable + (amount / 1E18);
            
            uint256 allowable_lev = (getReserves() * 10E18 / 100E18);
            require(totalTradeable <= allowable_lev, "Rigel: Amount is greater than max allowable");
        }
        
        return (totalTradeable, liquidation, userGetProfit);
    
    }
    
    function createLimitOrder(address order, uint256 amount, uint256 filled, uint256 price,  uint256 _leverage, SIDE side) external tokenNotTradeable(order) 
        returns (uint256 totalTradeable, uint256 liquidation, uint256 userGetProfit) {
        
        uint256 totalLiquidity = getReserves();
        require(amount <= getTraderBalance(), "Rigel: INSUFFICIENT_TRADING_AMOUNT");
        
        
        if(side == SIDE.buy) {
            (totalTradeable, liquidation, userGetProfit) = getTrading(amount, filled, _leverage, side);
            // reserve = (totalLiquidity - ( userGetProfit - amount));
            
            totalLiquidity -= (totalTradeable - amount);
            uint256 pairProfit = amount * 3E18 / 100E18;
            price <= liquidation ? traderBalances[token0][msg.sender] -= amount : traderBalances[token0][msg.sender] += (amount - pairProfit);
            
            totalLiquidity += (userGetProfit);
            
        } else {
            (totalTradeable, liquidation, userGetProfit) = getTrading(amount, filled, _leverage, side);
            totalLiquidity - (userGetProfit - amount);
            
            totalLiquidity -= (userGetProfit - amount);
            
            uint256 pairProfit = amount * 3E18 / 100E18;
            price <= liquidation ? traderBalances[token0][msg.sender] -= amount : traderBalances[token0][msg.sender] += (amount - pairProfit);
            totalLiquidity += (userGetProfit);
        }
        
        Order[] storage orders = orderBook[order][uint256(side)];
        orders.push(Order(
            side,
            order,
            amount,
            filled,
            price,
            block.timestamp,
            nextOrderID
        ));
        
        uint256 i = orders.length - 1;
        while(i > 0) {
            if(side == SIDE.buy && orders[i - 1].price > orders[i].price) {
                break;
            }
            if(side == SIDE.sell && orders[i - 1].price > orders[i].price) {
                break;
            }
            
            Order memory getOrder = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i]  = getOrder;
            i--;
        }
        nextOrderID ++;
        
    }
    

}

// File: futureExchange/rigelFutureExchangeFactory.sol

pragma solidity 0.8.9;

contract rigelFutureExchangeFactory is rigelFutureExchangeInterface {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;


    constructor() {
        feeToSetter = msg.sender;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
    
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'RGPFutrueExchange: IDENTICAL_ADDRESSES');
        
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        require(token0 != address(0), 'RIGEL: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'RGPFutrueExchange: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(rigelFutureExchangePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        rigelFutureExchangePair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'RGPFutrueExchange: FORBIDDEN');
        feeTo = _feeTo;
    } // 100000000

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'RGPFutrueExchange: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
     
}