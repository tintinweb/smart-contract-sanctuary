/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.4.23;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
	address public owner;
	uint256 public basisPointsRate = 0;
	uint256 public maximumFee = 0;
	uint256 public minimumFee = 0;

    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezes;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event CollectFee(address indexed _from, address indexed _owner, uint256 fee);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Params(address indexed _owner, uint256 feeBasisPoints, uint256 minFee, uint256 maxFee);
    event Freeze(address indexed to, uint256 value);
    event Unfreeze(address indexed to, uint256 value);
	event Withdraw(address indexed to, uint256 value);

    constructor(uint256 initialSupply, uint8 decimalUnits, string tokenName, string tokenSymbol) public {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
		owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
		require(_to != address(0));
        uint256 fee = calFee(_value);
        require(_value > fee);
        uint256 sendAmount = _value.sub(fee);
		require(balanceOf[msg.sender] >= _value && _value > 0 && balanceOf[_to] + sendAmount > balanceOf[_to]);
		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
		balanceOf[_to] = balanceOf[_to].add(sendAmount);
		if (fee > 0) {
            balanceOf[owner] = balanceOf[owner].add(fee);
            emit CollectFee(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);
		return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
		require(_spender != address(0));
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require((_from != address(0)) && (_to != address(0)));
        uint256 fee = calFee(_value);
        require(_value > fee);
        uint256 sendAmount = _value.sub(fee);
		require(balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value && _value > 0 && balanceOf[_to] + sendAmount > balanceOf[_to]);
		balanceOf[_to] = balanceOf[_to].add(sendAmount);
		balanceOf[_from] = balanceOf[_from].sub(_value);
		allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
		if (fee > 0) {
            balanceOf[owner] = balanceOf[owner].add(fee);
            emit CollectFee(msg.sender, owner, fee);
        }
		emit Transfer(_from, _to, _value);
		return true;
    }

    function freeze(address _to,uint256 _value) public returns (bool success) {
		require(msg.sender == owner);
        require(balanceOf[_to] >= _value);
        require(_value > 0);
        balanceOf[_to] = balanceOf[_to].sub(_value);
        freezes[_to] = freezes[_to].add(_value);
        emit Freeze(_to, _value);
        return true;
    }

	function unfreeze(address _to,uint256 _value) public returns (bool success) {
		require(msg.sender == owner);
        require(freezes[_to] >= _value);
        require(_value > 0);
        freezes[_to] = freezes[_to].sub(_value);
		balanceOf[_to] = balanceOf[_to].add(_value);
        emit Unfreeze(_to, _value);
        return true;
    }

	function setParams(uint256 newBasisPoints, uint256 newMinFee, uint256 newMaxFee) public returns (bool success) {
	    require(msg.sender == owner);
        require(newBasisPoints <= 20);
        require(newMinFee <= 50);
        require(newMaxFee <= 50);
		require(newMinFee <= newMaxFee);
        basisPointsRate = newBasisPoints;
        minimumFee = newMinFee.mul(10**decimals);
        maximumFee = newMaxFee.mul(10**decimals);
        emit Params(msg.sender, basisPointsRate, minimumFee, maximumFee);
        return true;
    }

    function calFee(uint256 _value) private view returns (uint256 fee) {
        fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (fee < minimumFee) {
            fee = minimumFee;
        }
    }

	function withdrawEther(uint256 amount) public returns (bool success) {
		require (msg.sender == owner);
		owner.transfer(amount);
		emit Withdraw(msg.sender,amount);
		return true;
	}

	function destructor() public returns (bool success) {
	    require(msg.sender == owner);
        selfdestruct(owner);
        return true;
    }

	function() payable private {
    }
}