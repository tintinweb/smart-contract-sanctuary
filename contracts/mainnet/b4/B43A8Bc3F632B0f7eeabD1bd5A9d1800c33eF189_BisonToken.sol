/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1 <0.9.0;

contract ERC20 {
    uint256 public totalSupply;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    using SafeMath for uint256;

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowanceOf(address _owner, address _delegate) public view returns (uint256) {
        return allowances[_owner][_delegate];
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = balances[_to] + _amount;

        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    function approve(address _delegate, uint256 _amount) public returns (bool success) {
        allowances[msg.sender][_delegate] = _amount;

        emit Approval(msg.sender, _delegate, _amount);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _amount;

        balances[_from] = balances[_from] - _amount;
        balances[_to] = balances[_to] + _amount;
        
        emit Transfer(_from, _to, _amount);

        return true;
    }

    event Approval(address indexed _owner, address indexed _delegate, uint256 _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
}

abstract contract ERC677 is ERC20 {
    function transferAndCall(address _to, uint256 _amount, bytes calldata _data) public virtual returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount, bytes _data);
}

abstract contract ERC677Receiver {
  function onTokenTransfer(address _sender, uint256 _amount, bytes calldata _data) virtual public;
}

contract StarterToken is ERC20 {
    function increaseApproval (address _delegate, uint256 _amount) public returns (bool success) {
        allowances[msg.sender][_delegate] = allowances[msg.sender][_delegate] + _amount;

        emit Approval(msg.sender, _delegate, allowances[msg.sender][_delegate]);

        return true;
    }

    function decreaseApproval (address _delegate, uint256 _amount) public returns (bool success) {
        uint256 currVal = allowances[msg.sender][_delegate];
    
        if (_amount > currVal) {
            allowances[msg.sender][_delegate] = 0;
        } else {
            allowances[msg.sender][_delegate] = currVal - _amount;
        }
    
        emit Approval(msg.sender, _delegate, allowances[msg.sender][_delegate]);
    
        return true;
    }
}

contract ERC677Token is ERC677 {
    function transferAndCall(address _to, uint256 _amount, bytes calldata _data) public virtual override returns (bool success)
    {
        super.transfer(_to, _amount);

        emit Transfer(msg.sender, _to, _amount, _data);
    
        if (isContract(_to)) {
            contractFallback(_to, _amount, _data);
        }
    
        return true;
    }

    // PRIVATE

    function contractFallback(address _to, uint256 _amount, bytes calldata _data) private {
        ERC677Receiver receiver = ERC677Receiver(_to);
    
        receiver.onTokenTransfer(msg.sender, _amount, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode)
    {
        uint256 length;

        assembly { length := extcodesize(_addr) }

        return length > 0;
    }
}

contract BisonToken is StarterToken, ERC677Token {
    string public constant name = "Bison";
    string public constant symbol = "BSN";
    uint8 public constant decimals = 18;

	address public owner;

    event Burn(address indexed _from, uint256 _amount);

    using SafeMath for uint256;

    constructor() {
        owner = msg.sender;
        totalSupply = 10**27;
        balances[msg.sender] = totalSupply;
    }

    function transferAndCall(address _to, uint _amount, bytes calldata _data) public override validReciever(_to) returns (bool success) {
        return super.transferAndCall(_to, _amount, _data);
    }

    function burn(uint256 _amount) isOwner public returns (bool success) {
        require(_amount > 0);

        balances[msg.sender] = balances[msg.sender] - _amount;
        totalSupply = totalSupply - _amount;

        emit Burn(msg.sender, _amount);

        return true;
    }
	
    // MODIFIERS

    modifier validReciever(address _to) {
        require(_to != address(0x0) && _to != address(this));
        _;
    }

    modifier isOwner {
        require(msg.sender == owner);
        _;
    }
}

library SafeMath {
  function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
    if (_x == 0) {
        return 0;
    }
    uint256 z = _x * _y;
    require(z / _x == _y, "SafeMath: multiplication overflow");
    return z;
  }

  function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
    require(_y > 0, "SafeMath: division by zero");
    uint256 z = _x / _y;
    return z;
  }

  function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
    require(_y <= _x, "SafeMath: subtraction overflow");
    return _x - _y;
  }

  function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
    uint256 z = _x + _y;
    require(z >= _x, "SafeMath: addition overflow");
    return z;
  }
}