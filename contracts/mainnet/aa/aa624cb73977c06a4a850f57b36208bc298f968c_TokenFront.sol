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

/*
    TokenFront
*/
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenFront is Ownable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    ITokenLogic private _tokenLogic;
    
    constructor(string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    
    // detail info
    function name() external view returns (string) {
        return _name;
    }
    
    function symbol() external view returns (string) {
        return _symbol;
    }
    
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    
    // tokenLogic
    event ChangeTokenLogic(address newTokenLogic); 
    
    function tokenLogic() external view returns (address) {
        return _tokenLogic;
    }
    
    function setTokenLogic(ITokenLogic newTokenLogic) external onlyOwner {
        _tokenLogic = newTokenLogic;
        emit ChangeTokenLogic(newTokenLogic);
    }
    
    // ERC20
    function totalSupply() external view returns (uint256) {
        return _tokenLogic.totalSupply();
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return _tokenLogic.balanceOf(account);
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _tokenLogic.allowance(owner, spender);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(_tokenLogic.transfer(msg.sender, to, value));
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(_tokenLogic.transferFrom(from, to, value, msg.sender));
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        require(_tokenLogic.approve(spender, value, msg.sender));
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        require(_tokenLogic.increaseAllowance(spender, addedValue, msg.sender));
        emit Approval(msg.sender, spender, _tokenLogic.allowance(msg.sender, spender));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        require(_tokenLogic.decreaseAllowance(spender, subtractedValue, msg.sender));
        emit Approval(msg.sender, spender, _tokenLogic.allowance(msg.sender, spender));
        return true;
    }
}