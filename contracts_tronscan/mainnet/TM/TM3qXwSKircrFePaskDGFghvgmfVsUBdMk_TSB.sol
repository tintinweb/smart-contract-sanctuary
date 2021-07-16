//SourceUnit: TSB.sol

pragma solidity ^0.5.8;


library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount);

        (bool success, ) = recipient.call.value(amount)("");
        require(success);
    }
}

contract Ownable {
    using Address for address;
    address payable public Owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(Owner, _newOwner);
        Owner = _newOwner.toPayable();
    }
}

interface ITRC20 {
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint amount, address token, bytes calldata extraData) external;
}

contract TRC20 is ITRC20, Ownable {
    using SafeMath for uint;
    using Address for address;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    uint internal _totalSupply;
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function burn(uint amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
    
    function approveAndCall(address spender, uint amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0));
        require(recipient != address(0));

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint amount) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint amount) internal {
        require(account != address(0));

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract TRC20Detailed is ITRC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

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

library SafeTRC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContract());

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)));
        }
    }
}

interface ICash {
    function trxPrice() external view returns (uint);
    function usdtPrice() external view returns (uint);
    function rebaseTime() external view returns (uint);

    function burn(uint amount) external returns (bool);
}

contract TSB is TRC20Detailed, TRC20 {
    using SafeTRC20 for ITRC20;
    using Address for address;
    using SafeMath for uint;
    
    uint public decimalVal;
    
    constructor () public TRC20Detailed("TSB", "TSB", 18) {
        decimalVal = 10 ** 18;
    }

    function burn(uint amount) public returns (bool) {
        super._burn(msg.sender, amount);
    }

    ITRC20 public cashToken = ITRC20(0x417d0a446d2465887b5a92728e44dded9148ce6f81);
    
    function setCashToken(address token) public onlyOwner returns (bool) {
        cashToken = ITRC20(token);
        return true;
    }

    uint public LowPrice = 950000; // 0.95 USDT
    uint public HighPrice = 1050000; // 1.05 USDT

    function usdtPrice() public view returns (uint) {
        require(address(cashToken) != address(0), "invalid cash token");
        uint price = ICash(address(cashToken)).usdtPrice();

        if (price < LowPrice) {
            return price *  price / 1e6;
        }
        return price;
    }
    
    function toBond(uint amount) public returns (bool) {
        require(address(cashToken) != address(0), "invalid cash token");
        uint price = ICash(address(cashToken)).usdtPrice();

        require(price < LowPrice, "Cash price should lower than LowPrice");

        cashToken.transferFrom(msg.sender, address(this), amount);
        ICash(address(cashToken)).burn(amount);

        uint exAmount = amount * 1e6 / price;
        _mint(msg.sender, exAmount);
        return true;
    }

    bool public toCashTimeLimitFlag;
    function setTimeLimitFlag(bool flag) public onlyOwner returns (bool) {
        toCashTimeLimitFlag = flag;
        return true;
    }
    
    function toCash(uint amount) public returns (bool) {
        require(address(cashToken) != address(0), "invalid cash token");

        if (toCashTimeLimitFlag) {
            uint rebaseTime = ICash(address(cashToken)).rebaseTime();
            require(rebaseTime <= now && rebaseTime + 12 hours >= now, "invalid exchange time");
        }
        
        burn(amount);
        cashToken.transferFrom(address(cashToken), msg.sender, amount);
        return true;
    }
}