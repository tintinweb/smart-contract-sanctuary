pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./interfaces/IPriceFeed.sol";

contract Stablecoin is ERC20 {
    IPriceFeed public priceFeed;
    
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor (string memory _name, string memory _symbol, uint256 initialSupply, uint8 _decimals, address oracle) public {
        require(initialSupply != 0);
        require(oracle != address(0));

        name = _name;
        symbol = _symbol;
        decimals =  _decimals;

        _totalSupply = initialSupply;

        priceFeed = IPriceFeed(oracle);
    }

    function issue() public payable {
        uint amount = (msg.value * priceFeed.getPrice()) / 1 ether;
        
        _totalSupply += amount;
        balances[msg.sender] += amount;
    }

    function withdraw(uint _amount) public payable {
        require(_amount >= balances[msg.sender]);

        uint256 amount = (_amount * 1 ether) / priceFeed.getPrice();
        
        balances[msg.sender] -= amount;
        _totalSupply -= amount;

        msg.sender.transfer(amount);
    }
}

pragma solidity ^0.6.0;

import "./interfaces/IERC20.sol";

contract ERC20 is IERC20 {
    uint256 _totalSupply = 0;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) external override returns (bool) {
        if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external override returns (bool) {
        if (
            balances[_from] >= _amount &&
            allowed[_from][msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]
        ) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

pragma solidity ^0.6.0;

interface IPriceFeed {
    function getPrice() external view returns(uint);
}

pragma solidity ^0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}