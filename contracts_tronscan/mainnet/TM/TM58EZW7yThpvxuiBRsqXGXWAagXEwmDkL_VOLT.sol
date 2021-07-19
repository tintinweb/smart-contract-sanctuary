//SourceUnit: VOLT.sol

pragma solidity ^0.5.8;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {return sub(a, b, "SafeMath: subtraction overflow");}
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;
        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {return 0;}
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {return div(a, b, "SafeMath: division by zero");}
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
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
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");}
    }
}

interface Medianizer {
    function read() external view returns (uint);
}

interface IJustswapFactory {
	event NewExchange(address indexed token, address indexed exchange);

	function initializeFactory(address template) external;
	function createExchange(address token) external returns (address payable);
	function getExchange(address token) external view returns (address payable);
	function getToken(address token) external view returns (address);
	function getTokenWihId(uint256 token_id) external view returns (address);
}

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

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function sell(uint256 _amountOfTokens) external;
    function reinvest() external;
    function withdraw() external;
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function balanceOf(address _customerAddress) view external returns(uint256);
    function myDividends(bool _includeReferralBonus) external view returns(uint256);
}

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {return msg.sender;}
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    
    function totalSupply() public view returns (uint) {return _totalSupply;}
    function balanceOf(address account) public view returns (uint) {return _balances[account];}
    function allowance(address owner, address spender) public view returns (uint) {return _allowances[owner][spender];}
    
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
    
    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
}

contract VOLT is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;
    
    address public hourglass;
    
    mapping (address => address) public vaultOf;
    
    event CreatedVault(address indexed owner, address indexed strongHand);

    constructor (address _hourglassAddress) public ERC20Detailed("VOLT Token", "VOLT", 18) {
        hourglass = _hourglassAddress;
    }
    
    function isVaultOwner() public view returns (bool) {return vaultOf[msg.sender] != address(0);}
    
    function myVault() external view returns (address) {  
        require(isVaultOwner(), "YOU_DO_NOT_OWN_A_VAULT");
        return vaultOf[msg.sender];
    }
    
    function createVault(uint256 _daysToLockD1VSFor) public returns (bool _success) {
        require(!isVaultOwner(), "YOU_ALREADY_OWN_A_VAULT");
        require(_daysToLockD1VSFor > 0);
        
        uint _tokens = ((_daysToLockD1VSFor * 10) * (10**18));
        
        address payable owner = msg.sender;
        vaultOf[owner] = address(new D1VSGauntlet(owner, _daysToLockD1VSFor, hourglass));
        
        _mint(msg.sender, _tokens);
        
        emit CreatedVault(owner, vaultOf[owner]);
        return true;
    }
}

contract D1VSGauntlet {
    HourglassInterface D1VS = HourglassInterface(_D1VSGame);
    
    address payable owner;
    address private _D1VSGame;
    
    uint256 public creationDate;
    uint256 public unlockAfterNDays;
    
    modifier timeLocked() {require(now >= creationDate + unlockAfterNDays * 1 days);_;}
    modifier onlyOwner() {require(msg.sender == owner);_;}
    
    constructor(address payable _owner, uint256 _daysToLockD1VSFor, address _hourglass) public {
        owner = _owner;
        unlockAfterNDays =_daysToLockD1VSFor;
        creationDate = now;
        _D1VSGame = _hourglass;
    }
    
    function() external payable {}
    
    function isLocked() public view returns(bool) {return now < creationDate + unlockAfterNDays * 1 days;}
    function lockedUntil() external view returns(uint256) {return creationDate + unlockAfterNDays * 1 days;}
    
    function balanceOf() external view returns(uint256) {return D1VS.balanceOf(address(this));}
    function dividendsOf() external view returns(uint256) {return D1VS.myDividends(true);}
    
    function reinvest() external onlyOwner {D1VS.reinvest();}
    function withdraw() external onlyOwner {owner.transfer(address(this).balance);}
    
    function buy() external payable onlyOwner {D1VS.buy.value(msg.value)(owner);}
    function buyWithBalance() external onlyOwner {D1VS.buy.value(address(this).balance)(owner);}
    
    function transfer(address _toAddress, uint256 _amountOfTokens) external timeLocked onlyOwner returns(bool) {return D1VS.transfer(_toAddress, _amountOfTokens);}
    
    function extendLock(uint256 _howManyDays) external onlyOwner {
        uint256 newLockTime = unlockAfterNDays + _howManyDays;
        require(newLockTime > unlockAfterNDays);
        unlockAfterNDays = newLockTime;
    }
    
    function withdrawDividends() external onlyOwner {
        D1VS.withdraw();
        owner.transfer(address(this).balance);
    }
    
    function sell(uint256 _amount) external timeLocked onlyOwner {
        D1VS.sell(_amount);
        owner.transfer(address(this).balance);
    }
}