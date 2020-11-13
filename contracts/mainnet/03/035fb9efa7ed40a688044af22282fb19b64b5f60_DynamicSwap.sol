pragma solidity 0.5.17;


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
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        if(a % b != 0)
            c = c + 1;
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

library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;
    function mul(int256 a, int256 b) internal pure returns (int256) {
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
    function sqrt(int256 x) internal pure returns (int256) {
        int256 z = add(x / 2, 1);
        int256 y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
        return y;
    }
}

interface Normalizer {
    function getPrice(address) external view returns (uint exchange, uint decimal);
}

contract DynamicSwap is ERC20, ERC20Detailed {
    using SafeMath for uint;
    using SignedSafeMath for int256;
    using SafeERC20 for IERC20;
    
    mapping(address => bool) public coins;
    mapping(address => Normalizer) public normalizers;
    
    address public governance;
    
    constructor() public ERC20Detailed("DynamicSwap", "dUSD", 18) {
        governance = msg.sender;
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function approveCoins(address _coin, Normalizer _normalizer) external {
        require(msg.sender == governance, "!governance");
        coins[_coin] = true;
        if (address(_normalizer) != address(0)) {
            normalizers[_coin] = _normalizer;
        }
    }
    
    uint public fee = 99985;
    uint public constant BASE = 100000;
    
    uint public constant A = 0.75e18;
    uint public count = 0;
    mapping(address => bool) tokens;
    
    function f(int256 _x, int256 x, int256 y) internal pure returns (int256 _y) {
        int256 k;
        int256 c;
        {
            int256 u = x.add(y.mul(int256(A)).div(1e18));
            int256 v = y.add(x.mul(int256(A)).div(1e18));
            k = u.mul(v);
            c = _x.mul(_x).sub(k.mul(1e18).div(int256(A)));
        }
        
        int256 cst = int256(A).add(int256(1e36).div(int256(A)));
        int256 _b = _x.mul(cst).div(1e18);

        int256 D = _b.mul(_b).sub(c.mul(4));

        require(D >= 0, "!root");

        _y = (-_b).add(D.sqrt()).div(2);
    }

    // Calculate output given exact input
    function getOutExactIn(address token, int256 input, int256 x, int256 y) public view returns (uint output) {
        int256 _x = x.add(input);
        int256 _y = f(_x, x, y);
        output = uint(y.sub(_y));
        if (address(normalizers[token]) != address(0)) {
            (uint exchange, uint decimals) = normalizers[token].getPrice(token);
            output = output.mul(decimals).div(exchange);
        }
    }

    // Calculate input given exact output
    function getInExactOut(address token, int256 output, int256 x, int256 y) public view returns (uint input) {
        int256 _y = y.sub(output);
        int256 _x = f(_y, y, x);
        input = uint(_x.sub(x));
        if (address(normalizers[token]) != address(0)) {
            (uint exchange, uint decimals) = normalizers[token].getPrice(token);
            input = input.mul(decimals).div(exchange);
        }
    }
    
    // Normalize coin to 1e18
    function normalize1e18(IERC20 token, uint _amount) public view returns (uint) {
        uint _decimals = ERC20Detailed(address(token)).decimals();
        if (_decimals == uint(18)) {
            return _amount;
        } else {
            return _amount.mul(1e18).div(uint(10)**_decimals);
        }
    }
    
    // Normalize coin to original decimals 
    function normalize(IERC20 token, uint _amount) public view returns (uint) {
        uint _decimals = ERC20Detailed(address(token)).decimals();
        if (_decimals == uint(18)) {
            return _amount;
        } else {
            return _amount.mul(uint(10)**_decimals).div(1e18);
        }
    }
    
    // Contract balance of coin normalized to 1e18
    function balance(IERC20 token) public view returns (uint) {
        address _token = address(token);
        uint _balance = IERC20(_token).balanceOf(address(this));
        if (address(normalizers[_token]) != address(0)) {
            (uint exchange, uint decimals) = normalizers[_token].getPrice(_token);
            _balance = _balance.mul(exchange).div(decimals);
        }
        return normalize1e18(token, _balance);
    }
    
    // Converter helper to int256
    function i(uint x) public pure returns (int256) {
        return int256(x);
    }

    function swapExactAmountIn(IERC20 from, IERC20 to, uint input, uint minOutput, uint deadline) external returns (uint output) {
        require(block.timestamp <= deadline, "expired");
        
        output = normalize(to, getOutExactIn(address(from), i(normalize1e18(from, input.mul(fee).div(BASE))), i(balance(from)), i(balance(to))));
        
        require(output >= minOutput, "slippage");
        
        from.safeTransferFrom(msg.sender, address(this), input);
        to.safeTransfer(msg.sender, output);
    }

    function swapExactAmountOut(IERC20 from, IERC20 to, uint maxInput, uint output, uint deadline) external returns (uint input) {
        require(block.timestamp <= deadline, "expired");
        
        input = normalize(from, getInExactOut(address(to), i(normalize1e18(to, output)), i(balance(from)), i(balance(to))));
        input = input.mul(BASE).divCeil(fee);
        
        require(input <= maxInput, "slippage");
        
        from.safeTransferFrom(msg.sender, address(this), input);
        to.safeTransfer(msg.sender, output);
    }
    
    function addLiquidityExactIn(IERC20 from, uint input, uint minOutput, uint deadline) external returns (uint output) {
        require(coins[address(from)]==true, "!coin");
        require(block.timestamp <= deadline, "expired");
        
        if (totalSupply() == 0) {
            output = normalize1e18(from, input);
        } else {
            output = getOutExactIn(address(from), i(normalize1e18(from, input.mul(fee).div(BASE))), i(balance(from)), i(totalSupply().div(count)));
        }
        
        require(output >= minOutput, "slippage");
        
        from.safeTransferFrom(msg.sender, address(this), input);
        _mint(msg.sender, output);
        
        if (!tokens[address(from)] && balance(from) > 0 ) {
            tokens[address(from)] = true;
            count = count.add(1);
        }
    }
    
    function addLiquidityExactOut(IERC20 from, uint maxInput, uint output, uint deadline) external returns (uint input) {
        require(coins[address(from)] == true, "!coin");
        require(block.timestamp <= deadline, "expired");
        
        if (totalSupply() == 0) {
            input = normalize(from, output);
        } else {
            input = normalize(from, getInExactOut(address(from), i(output), i(balance(from)), i(totalSupply().div(count))));
            input = input.mul(BASE).divCeil(fee);
        }
        
        require(input <= maxInput, "slippage");

        from.safeTransferFrom(msg.sender, address(this), input);
        _mint(msg.sender, output);
        
        if (!tokens[address(from)] && balance(from) > 0 ) {
            tokens[address(from)] = true;
            count = count.add(1);
        }
    }
    
    function removeLiquidityExactIn(IERC20 to, uint input, uint minOutput, uint deadline) external returns (uint output) {
        require(block.timestamp <= deadline, "expired");
        
        output = normalize(to, getOutExactIn(address(this), i(input.mul(fee).div(BASE)), i(totalSupply().div(count)), i(balance(to))));
        
        require(output >= minOutput, "slippage");
        
        _burn(msg.sender, input);
        to.safeTransfer(msg.sender, output);
        
        if (balance(to)==0) {
            tokens[address(to)] = false;
        }
    }
    
    function removeLiquidityExactOut(IERC20 to, uint maxInput, uint output, uint deadline) external returns (uint input) {
        require(block.timestamp <= deadline, "expired");
        
        input = getInExactOut(address(to), i(normalize1e18(to, input)), i(totalSupply().div(count)), i(balance(to)));
        input = input.mul(BASE).divCeil(fee);
        
        require(input <= maxInput, "slippage");

        _burn(msg.sender, input);
        to.safeTransfer(msg.sender, output);
        
        if (balance(to)==0) {
            tokens[address(to)] = false;
        }
    }
}