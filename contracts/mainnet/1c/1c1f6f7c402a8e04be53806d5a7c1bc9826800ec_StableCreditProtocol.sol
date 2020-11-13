pragma solidity ^0.5.17;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface UniswapPair {
    function mint(address to) external returns (uint liquidity);
}

interface Oracle {
    function getPriceUSD(address reserve) external view returns (uint);
}

interface UniswapRouter {
  function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function factory() external view returns (address);
}

interface UniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract StableCreditProtocol is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;

    // Oracle used for price debt data (external to the AMM balance to avoid internal manipulation)
    Oracle public constant LINK = Oracle(0x271bf4568fb737cc2e6277e9B1EE0034098cDA2a);
    // Uniswap v2
    UniswapRouter public constant UNI = UniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    // Maximum credit issued off of deposits (to avoid infinite leverage)
    uint public constant MAX = 7500;
    uint public constant BASE = 10000;
    
    // user => token => credit
    mapping (address => mapping(address => uint)) public credit;
    // user => token => balance
    mapping (address => mapping(address => uint)) public balances;
    
    // How much system liquidity is provided by this asset
    function utilization(address token) public view returns (uint) {
        address pair = UniswapFactory(UNI.factory()).getPair(token, address(this));
        uint _ratio = BASE.sub(BASE.mul(balanceOf(pair)).div(totalSupply()));
        return  _ratio > MAX ? MAX : _ratio;
    }
    
    constructor () public ERC20Detailed("StableCredit", "USD", 8) {}
    
    function depositAll(address token) external {
        deposit(token, IERC20(token).balanceOf(msg.sender));
    }
    
    function deposit(address token, uint amount) public {
        _deposit(token, amount);
    }
    
    // UNSAFE: No slippage protection, should not be called directly
    function _deposit(address token, uint amount) internal {
        uint value = LINK.getPriceUSD(token).mul(amount).div(uint256(10)**ERC20Detailed(token).decimals());
        require(value > 0, "!value");
        
        address pair = UniswapFactory(UNI.factory()).getPair(token, address(this));
        if (pair == address(0)) {
            pair = UniswapFactory(UNI.factory()).createPair(token, address(this));
        }
        
        IERC20(token).safeTransferFrom(msg.sender, pair, amount);
        _mint(pair, value); // Amount of aUSD to mint
        
        uint _before = IERC20(pair).balanceOf(address(this));
        UniswapPair(pair).mint(address(this));
        uint _after = IERC20(pair).balanceOf(address(this));
        

        // Assign LP tokens to user, token <> pair is deterministic thanks to CREATE2
        balances[msg.sender][token] = balances[msg.sender][token].add(_after.sub(_before));
        
        // Calculate utilization ratio of the asset. The more an asset contributes to the system, the less credit issued
        // This mechanism avoids large influx of deposits to overpower the system
        // Calculated after deposit to see impact of current deposit (prevents front-running credit)
        uint _credit = value.mul(utilization(token)).div(BASE);
        credit[msg.sender][token] = credit[msg.sender][token].add(_credit);
        _mint(msg.sender, _credit);
    }
    
    function withdrawAll(address token) external {
        _withdraw(token, IERC20(this).balanceOf(msg.sender));
    }
    
    function withdraw(address token, uint amount) external {
        _withdraw(token, amount);
    }

    // UNSAFE: No slippage protection, should not be called directly
    function _withdraw(address token, uint amount) internal {
        
        uint _credit = credit[msg.sender][token];
        uint _uni = balances[msg.sender][token];
        
        if (_credit < amount) {
            amount = _credit;
        }
        
        _burn(msg.sender, amount);
        credit[msg.sender][token] = credit[msg.sender][token].sub(amount);
        
        // Calculate % of collateral to release
        _uni = _uni.mul(amount).div(_credit);
        
        address pair = UniswapFactory(UNI.factory()).getPair(token, address(this));
        
        IERC20(pair).safeApprove(address(UNI), 0);
        IERC20(pair).safeApprove(address(UNI), _uni);
        
        UNI.removeLiquidity(
          token,
          address(this),
          _uni,
          0,
          0,
          address(this),
          now.add(1800)
        );
        
        uint amountA = IERC20(token).balanceOf(address(this));
        uint amountB = balanceOf(address(this));
        
        uint valueA = LINK.getPriceUSD(token).mul(amountA).div(uint256(10)**ERC20Detailed(token).decimals());
        require(valueA > 0, "!value");
        
        // Collateral increased in value, but we max at amount B withdrawn
        if (valueA > amountB) {
            valueA = amountB;
        }
        
        _burn(address(this), valueA); // Amount of aUSD to burn (value of A leaving the system)
        
        IERC20(token).safeTransfer(msg.sender, amountA);
        if (amountB > valueA) { // Asset A appreciated in value, receive credit diff
            IERC20(this).safeTransfer(msg.sender, balanceOf(address(this)));
        }
    }
}