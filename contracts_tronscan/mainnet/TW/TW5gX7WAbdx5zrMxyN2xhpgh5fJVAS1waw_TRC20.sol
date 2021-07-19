//SourceUnit: trc20.sol

pragma solidity ^0.5.10;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IJustswapFactory {
  event NewExchange(address indexed token, address indexed exchange);

  function initializeFactory(address template) external;
  function createExchange(address token) external returns (address payable);
  function getExchange(address token) external view returns (address payable);
  function getToken(address token) external view returns (address);
  function getTokenWihId(uint256 token_id) external view returns (address);
}


interface IJustswapExchange {
  event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
  event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
  event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
  event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);

  function () external payable;

  function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

  function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

  function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);

  function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);

  function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);

  function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);


  function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);

  function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address recipient) external returns (uint256);

  function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);


  function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);


  function tokenToTokenSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address token_addr) 
    external returns (uint256);

  function tokenToTokenTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    external returns (uint256);

  function tokenToTokenSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address token_addr) 
    external returns (uint256);


  function tokenToTokenTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    external returns (uint256);


  function tokenToExchangeSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address exchange_addr) 
    external returns (uint256);

  function tokenToExchangeTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address recipient, 
    address exchange_addr) 
    external returns (uint256);


  function tokenToExchangeSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address exchange_addr) 
    external returns (uint256);


  function tokenToExchangeTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address recipient, 
    address exchange_addr) 
    external returns (uint256);


  function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);


  function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);


  function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);


  function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);

  function tokenAddress() external view returns (address);

  function factoryAddress() external view returns (address);


  function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);


  function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}





contract TRC20 is IERC20{
  using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
  
  
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    
    address public factory;
    address public exchange;
  
    constructor(string memory _NAME, string memory _SYMBOL, uint256 _DECIMALS,uint256 _supply, address _factory) public {
        _name = _NAME;
        _symbol = _SYMBOL;
        _decimals = _DECIMALS;
        _totalSupply = _supply * 10 ** _decimals;
        factory = _factory;
        exchange = IJustswapFactory(factory).createExchange(address(this));
        _balances[msg.sender] = _totalSupply;
    }
  

  uint256 internal _totalSupply;

   function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }


  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }


  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }


  function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }


  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }


  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }


  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    // 2% to pool and 1% to address(0)
    if(from == exchange){
        // buy
        uint256 inPool = value * 2 / 100;
        uint256 inBlank = value * 1 / 100;
        _burn(from,inBlank);
        value = value - inPool - inBlank;
    } else if (to == exchange){
        // sell or addLiquidity
        if (msg.value != 0){
            // only sell
            uint256 inPool = value * 2 / 100;
            uint256 inBlank = value * 1 / 100;
            _burn(from,inBlank);
            value = value - inPool - inBlank;
        }
    }
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }


  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }


  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }


  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));

    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }


  function _burnFrom(address account, uint256 value) internal {
    _burn(account, value);
    _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
  }
}