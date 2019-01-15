pragma solidity ^0.4.24;

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
      		return 0;
    	}

    	c = a * b;
    	assert(c / a == b);
    	return c;
  	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
    	return a / b;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    	assert(b <= a);
    	return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    	c = a + b;
    	assert(c >= a);
    	return c;
	}
	
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address internal _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "you are not the owner!");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "cannot transfer ownership to ZERO address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ITokenStore {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address src, address dest, uint256 amount) external;
    function approve(address owner, address spender, uint256 amount) external;
    function mint(address dest, uint256 amount) external;
    function burn(address dest, uint256 amount) external;
}

/*
    TokenStore
*/
contract TokenStore is ITokenStore, Ownable {
    using SafeMath for uint256;
    
    address private _tokenLogic;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    constructor(uint256 totalSupply, address holder) public {
        _totalSupply = totalSupply;
        _balances[holder] = totalSupply;
    }
    
    // token logic
    event ChangeTokenLogic(address newTokenLogic);
    
    modifier onlyTokenLogic() {
        require(msg.sender == _tokenLogic, "this method MUST be called by the security&#39;s logic address");
        _;
    }
    
    function tokenLogic() public view returns (address) {
        return _tokenLogic;
    }
    
    function setTokenLogic(ITokenLogic newTokenLogic) public onlyOwner {
        _tokenLogic = newTokenLogic;
        emit ChangeTokenLogic(newTokenLogic);
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view returns(uint256) {
        return _allowed[owner][spender];
    }
    
    function transfer(address src, address dest, uint256 amount) public onlyTokenLogic {
        _balances[src] = _balances[src].sub(amount);
        _balances[dest] = _balances[dest].add(amount);
    }
    
    function approve(address owner, address spender, uint256 amount) public onlyTokenLogic {
        _allowed[owner][spender] = amount;
    }
    
    function mint(address dest, uint256 amount) public onlyTokenLogic {
        _balances[dest] = _balances[dest].add(amount);
        _totalSupply = _totalSupply.add(amount);
    }
    
    function burn(address dest, uint256 amount) public onlyTokenLogic {
        _balances[dest] = _balances[dest].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
    }
}

/*
    TokenLogic
*/
interface ITokenLogic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value, address owner) external returns (bool);
    function transferFrom(address from, address to, uint256 value, address spender) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue, address owner) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue, address owner) external returns (bool);
}