/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IUniswap {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract CharityFundHeard is Ownable {
	using SafeMath for uint256;
	uint public totalSupply;
	
	string public name;
	uint8 public decimals;
	string public symbol;
	
	address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Kovan
	
	mapping (address => uint256) private balances;
	mapping (address => mapping (address => uint)) private allowed;
	uint256 private _chariryAmount = 0;
	uint256 private _liquidityAmount = 0;
	IUniswap public uniswap;
	
	constructor() {
	    uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);
		totalSupply = 1000000000000000000000000000;
		name = "Charity fund heart";
		decimals = 18;
		symbol = "CFH";
		balances[msg.sender] = totalSupply;
		emit Transfer(address(0) , msg.sender, totalSupply);
	}

	function balanceOf(address _owner) public view returns (uint balance) {
		return balances[_owner];
	}
	
	function liquidityAmount() public view returns (uint liquidity) {
		return _liquidityAmount;
	}
	
	function chariryAmount() public view returns (uint chariry) {
		return _chariryAmount;
	}
	
	function sendCharity(address _recipient) public onlyOwner {
	    uint256 value = _chariryAmount;
	    balances[_recipient] = balances[_recipient].add(value);
	    balances[address(this)] = balances[address(this)].sub(value);
	    
	    emit Transfer(address(this), _recipient, value);
	    emit CharitySent(_recipient, value);        
    }
        
    function changeName(string memory _name) public onlyOwner {
        name = _name;
    }
    
    function addLiquidity() external payable onlyOwner {
        allowed[address(this)][UNISWAP_ROUTER_ADDRESS] = _liquidityAmount;
		emit Approval(address(this), UNISWAP_ROUTER_ADDRESS, _liquidityAmount);
		
        uniswap.addLiquidityETH{ value: msg.value }(address(this), _liquidityAmount, _liquidityAmount, msg.value, owner(), block.timestamp.add(300));
        
        _liquidityAmount = 0;
    }


	function transfer(address _recipient, uint _value) public{
	    require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    
	    uint256 fund = _value.mul(4).div(1000);
    	    uint256 charity = _value.div(100);
    	    uint256 liquidity = _value.mul(59).div(10000);
    	    uint256 newAmount = _value.sub(charity).sub(fund).sub(liquidity);
    	    
    	    _chariryAmount = _chariryAmount.add(charity);
    	    _liquidityAmount = _liquidityAmount.add(liquidity);
    	    
            balances[_recipient] = balances[_recipient].add(newAmount);
            balances[owner()] = balances[owner()].add(fund);
	        balances[address(this)] = balances[address(this)].add(charity).add(liquidity);
	        
            emit Transfer(msg.sender, _recipient, newAmount);
            emit Transfer(msg.sender, address(this), charity.add(liquidity));
            emit Transfer(msg.sender, owner(), fund);
        }

	function transferFrom(address _from, address _to, uint _value) public {
	    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
	        balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
	    
	        uint256 fund = _value.mul(4).div(1000);
    	    uint256 charity = _value.div(100);
    	    uint256 liquidity = _value.mul(59).div(10000);
    	    uint256 newAmount = _value.sub(charity).sub(fund).sub(liquidity);
    	    
    	    _chariryAmount = _chariryAmount.add(charity);
    	    _liquidityAmount = _liquidityAmount.add(liquidity);
    	    
            balances[_to] = balances[_to].add(newAmount);
            balances[owner()] = balances[owner()].add(fund);
	        balances[address(this)] = balances[address(this)].add(charity).add(liquidity);
            
            emit Transfer(_from, _to, newAmount);
            emit Transfer(_from, address(this), charity.add(liquidity));
            emit Transfer(_from, owner(), fund);
        }

	function  approve(address _spender, uint _value) public {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
	}

	function allowance(address _spender, address _owner) public view returns (uint balance) {
		return allowed[_owner][_spender];
	}

	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
		
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