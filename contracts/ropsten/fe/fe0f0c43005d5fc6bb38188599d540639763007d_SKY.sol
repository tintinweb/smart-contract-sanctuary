/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-04
*/

pragma solidity ^0.5.10;


contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


contract SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
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

contract Pausable is Owned {
    bool public paused = false;
    event Pause();
    event Unpause();

    modifier notPaused {
        require(!paused);
        _;
    }

    function pause() public onlyOwner {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner {
        paused = false;
        emit Unpause();
    }
}

contract EIP20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract SKY is Owned, SafeMath, Pausable, EIP20Interface {
    uint256 private totalSupply_;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    constructor() public {
        name = "SKY Token";
        symbol = "SKY";
        decimals = 8;
        totalSupply_ = 1000000000 * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
    }
    
    // erc20 part
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _addr) public view returns (uint256 balance) {
        return balances[_addr];
    }

    function transfer(address _to, uint256 _value) public notPaused returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public notPaused returns (bool success) {
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        require(allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public notPaused returns (bool success) {
        require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    } 
}