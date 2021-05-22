/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        
	return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CharityFundHeard is Ownable {
	using SafeMath for uint256;
	uint public totalSupply;
	
	string public name;
	uint8 public decimals;
	string public symbol;
	
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint)) allowed;
	
	constructor() public {
		totalSupply = 1000000000000000000000000000;
		name = "Charity fund heart";
		decimals = 18;
		symbol = "CFH";
		balances[msg.sender] = totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint balance) {
		return balances[_owner];
	}
	
	function sendCharity(address _recipient) public onlyOwner {
	    uint256 value = balances[address(this)];
	    balances[_recipient] = balances[_recipient].add(value);
	    balances[address(this)] = 0;
	    
	    emit CharitySent(_recipient, value);        
        }

	function transfer(address _recipient, uint _value) public{
	    require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    
	    uint256 fund = _value.mul(4).div(1000);
	    uint256 charity = _value.div(100);
	    uint256 new_amount = _value.sub(charity).sub(fund);
	    
	    balances[_recipient] = balances[_recipient].add(new_amount);
	    balances[owner()] = balances[owner()].add(fund);
	    balances[address(this)] = balances[address(this)].add(charity);
	    
	    emit Transfer(msg.sender, _recipient, _value);        
        }

	function transferFrom(address _from, address _to, uint _value) public {
	    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
	        balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
	    
	        uint256 fund = _value.mul(4).div(1000);
    	    uint256 charity = _value.div(100);
    	    uint256 new_amount = _value.sub(charity).sub(fund);
    	    
            balances[_to] = balances[_to].add(new_amount);
            balances[owner()] = balances[owner()].add(fund);
	        balances[address(this)] = balances[address(this)].add(charity);
            
            emit Transfer(_from, _to, _value);
        }

	function  approve(address _spender, uint _value) public {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
	}

	function allowance(address _spender, address _owner) public view returns (uint balance) {
		return allowed[_owner][_spender];
	}

	//Event which is triggered to log all transfers to this contract's event log
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
		
	//Event which is triggered whenever an owner approves a new allowance for a spender.
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint _value
		);
		
	event CharitySent(
		address indexed _recipient,
		uint _value
		);
}