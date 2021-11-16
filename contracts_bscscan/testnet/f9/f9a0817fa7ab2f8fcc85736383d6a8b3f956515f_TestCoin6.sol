/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.1;


interface ERC20 {
    function balanceOf(address _owner) external view returns(uint256);
    function allowance(address _owner, address _spender) external view returns(uint256);
    function transfer(address _to, uint _amount) external returns(bool);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if(a == 0) {
            return 0;
        }

        uint c = a * b;
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
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TestCoin6 is ERC20 {
    using SafeMath for uint256;
    address private minter;
    uint8 public constant decimals = 18;
    uint256 private constant decimalFactor = 10 ** uint256(decimals); // 10^18
    uint256 public totalSupply = 100000 * decimalFactor;
    uint256 public initialSupply = 100000 * decimalFactor;

    string public name = "Test Coin 6";
    string public symbol = "TCoin6";

    bool public minted = false;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor() public {
        minter = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function decreaseApproval(address _spender, uint _subtractValue) public returns(bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if(_subtractValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function owner() public view returns (address) {
        return minter;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _minter, address _spender) public view returns(uint256) {
        return allowed[_minter][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool) {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public returns(bool) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}