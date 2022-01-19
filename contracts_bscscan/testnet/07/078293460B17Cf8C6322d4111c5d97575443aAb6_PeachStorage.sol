/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract PeachStorage {
    using SafeMath for uint256;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private locked;
    mapping(address => uint256) private claimed;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => mapping(uint256 => uint256)) expenditures;

    /**
      Liquidity pools go here
    */
    address internal manager;
    address internal owner = msg.sender;
    address internal support;
    address internal oracle;
    address rewardsPool = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    string _name = "DW Teach Storage";
    string _symbol = "TSTR";
    uint8 _decimals = 18;
    uint256 _totalSupply = 5000000 * 10**_decimals;
    uint256 TGE;
    uint256 internal currentPrice; // 3 decimals

    modifier onlyManager() {
        require(msg.sender == manager, "You are not the manager");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlySupport() {
        require(msg.sender == support, "You are not the owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "You are not the owner");
        _;
    }

    constructor() {
        balances[owner] = _totalSupply / 100;
        TGE = block.timestamp;
    }

    // Token information functions
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function upgradePeach(address _newPeach) external onlySupport {
        manager = _newPeach;
    }
    
    function setSupport(address _support) external onlyOwner {
        support = _support;
    }

    function setOracle(address _oracle) external onlySupport {
        oracle = _oracle;
    }

    function setCurrentPrice(uint256 _newPrice) external onlyOracle {
        currentPrice = _newPrice;
    }

    function getCurrentPrice() external view returns(uint256) {
        return currentPrice;
    }

    function getPeach() external view returns (address) {
        return manager;
    }

    function balanceOf(address _wallet) external view returns (uint256) {
        return balances[_wallet];
    }

    // ERC20 proxied functions and events
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address _owner, address _spender, uint256 _value);

    function transfer(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _comission
    ) external onlyManager {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        _transfer(_from, _to, _amount, _comission);
        emit Transfer(_from, _to, _amount.sub(_comission));
        emit Transfer(_from, rewardsPool, _comission);
    }

    function transferFrom(
        address _from,
        address _spender,
        address _to,
        uint256 _amount,
        uint256 _comission
    ) external onlyManager {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(
            allowances[_from][_spender] >= _amount,
            "Allowance is lower tan requested funds"
        );
        allowances[_from][_spender] = allowances[_from][_spender].sub(_amount);
        _transfer(_from, _to, _amount, _comission);
        emit Transfer(_from, _to, _amount.sub(_comission));
        emit Transfer(_from, rewardsPool, _comission);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _comission
    ) internal {
        require(balances[_from] >= _amount, "Not enough funds");
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount.sub(_comission));
        balances[rewardsPool] = balances[rewardsPool].add(_comission);
        uint256 thisHour = (block.timestamp - TGE) / 3600;
        expenditures[_from][thisHour] = expenditures[
            _from
        ][thisHour].add(_amount.mul(currentPrice));
    }

    function getExpenditure(address _target, uint256 _hours)
        external
        view
        returns (uint256)
    {
        uint256 result = 0;
        uint256 thisHour = (block.timestamp - TGE) / 3600;
        uint256 minHours = thisHour >= _hours ? thisHour - _hours + 1: 0;
        for (
            uint256 i = thisHour + 1; // We get hours this way
            i > minHours;
            i--
        ) {
            result = result.add(expenditures[_target][i - 1]);
        }
        return result;
    }

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return allowances[_owner][_spender];
    }

    function approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) external onlyManager returns (bool) {
        _approve(_owner, _spender, _amount);
        emit Approval(_owner, _spender, _amount);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowances[_owner][_spender] = _amount;
    }
}