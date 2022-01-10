/**
 *Submitted for verification at BscScan.com on 2022-01-09
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

    address manager = 0x2DEbCd8eCD0aecd3234c92eaA8B4Eb7421b7aBe6;
    address owner = 0x2DEbCd8eCD0aecd3234c92eaA8B4Eb7421b7aBe6;
    address ecosystem = address(0);
    address ido = address(0);
    address publicPresale = address(0);
    address rewardPool = address(0);
    address team = address(0);
    address dex = address(0);
    address marketing = address(0);
    address staking = address(0);
    address advisor = address(0);
    address airdrop = address(0);
    address charity = address(0);
    address privateSale = address(0);

    string _name = "Darling Waifu Peach Storage";
    string _symbol = "PSTR";
    uint8 _decimals = 18;
    uint256 _totalSupply = 5000000 * 10**_decimals;

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        // balances[owner] = _totalSupply / 100;
        balances[ecosystem] = 500000 * 10**_decimals;
        balances[ido] = 400000 * 10**_decimals;
        balances[publicPresale] = 100000 * 10**_decimals;
        balances[rewardPool] = 2300000 * 10**_decimals;
        balances[team] = 500000 * 10**_decimals;
        balances[dex]  = 400000 * 10**_decimals;
        balances[marketing] = 200000 * 10**_decimals;
        balances[staking] = 200000 * 10**_decimals;
        balances[advisor] = 150000 * 10**_decimals;
        balances[airdrop] = 100000 * 10**_decimals;
        balances[charity] = 50000 * 10**_decimals;
        balances[privateSale] = 100000 * 10**_decimals;
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

    function upgradePeach(address _newPeach) external onlyOwner {
        manager = _newPeach;
    }

    function getPeach() external view returns (address) {
        return manager;
    }

    function balanceOf(address _wallet) external view returns (uint256) {
        return balances[_wallet];
    }

    event Transfer(address from, address to, uint256 ammount);

    function transfer(
        address _from,
        address _to,
        uint256 _ammount
    ) external onlyManager {
        require(balances[_from] >= _ammount);
        balances[_from] = balances[_from].sub(_ammount);
        balances[_to] = balances[_to].add(_ammount);
        emit Transfer(_from, _to, _ammount);
    }

    function claim(address _target, uint256 _ammount) external onlyManager {
        require(locked[_target] >= _ammount);
        locked[_target] = locked[_target].sub(_ammount);
        balances[_target] = balances[_target].add(_ammount);
        emit Transfer(address(0), _target, _ammount);
    }
}