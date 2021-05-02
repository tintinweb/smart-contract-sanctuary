/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

/**
 *Submitted for verification at Etherscan.io on 2019-12-26
*/

/**
 *Submitted for verification at Etherscan.io on 2019-09-24
*/

pragma solidity ^0.5.11;

// ----------------------------------------------------------------------------
// forgivenet token contract
//
// Symbol      : FRGVN
// Name        : PRE-ICO forgivenetToken
// Total supply: 1,000,000,000,000.000000000000000000
// Decimals    : 18
//
// (c) Nandi Niramisa & Co Limited 2019. The MIT Licence. https://opensource.org/licenses/MIT
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
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


contract ERC20TokenInterface {

    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address _from, address _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



contract ForgivenetToken is ERC20TokenInterface, Owned {

    using SafeMath for uint256;

    string public symbol;
    string public name;
    string public version;
    uint8 public decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping (address => uint256)) private allowed;


    constructor() public {
        symbol = "FRGVN";
        name = "forgivenet Token";
        version = "1.0";
        decimals = 18;
        _totalSupply = 1000000000000 * 10**uint256(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }



    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }



    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = (
        allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = (
        allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

}