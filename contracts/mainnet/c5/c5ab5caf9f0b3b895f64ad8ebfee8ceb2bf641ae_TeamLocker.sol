pragma solidity ^0.4.18;

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

// File: contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/token/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: contracts/TeamLocker.sol

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TeamLocker is SafeMath, Ownable {
    using SafeERC20 for ERC20Basic;

    ERC20Basic public token;

    address[] public beneficiaries;
    uint256[] public ratios;
    uint256 public genTime;
    
    uint256 public collectedTokens;

    function TeamLocker(address _token, address[] _beneficiaries, uint256[] _ratios, uint256 _genTime) {

        require(_token != 0x00);
        require(_beneficiaries.length > 0 && _beneficiaries.length == _ratios.length);
        require(_genTime > 0);

        for (uint i = 0; i < _beneficiaries.length; i++) {
            require(_beneficiaries[i] != 0x00);
        }

        token = ERC20Basic(_token);
        beneficiaries = _beneficiaries;
        ratios = _ratios;
        genTime = _genTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {

        uint256 balance = token.balanceOf(address(this));
        uint256 total = add(balance, collectedTokens);

        uint256 lockTime1 = add(genTime, 183 days); // 6 months
        uint256 lockTime2 = add(genTime, 1 years); // 1 year

        uint256 currentRatio = 20;

        if (now >= lockTime1) {
            currentRatio = 50;
        }

        if (now >= lockTime2) {
            currentRatio = 100;
        }

        uint256 releasedAmount = div(mul(total, currentRatio), 100);
        uint256 grantAmount = sub(releasedAmount, collectedTokens);
        require(grantAmount > 0);
        collectedTokens = add(collectedTokens, grantAmount);


        uint256 grantAmountForEach; // = div(grantAmount, 3);

        for (uint i = 0; i < beneficiaries.length; i++) {
            grantAmountForEach = div(mul(grantAmount, ratios[i]), 100);
            token.safeTransfer(beneficiaries[i], grantAmountForEach);
        }
    }


    function setGenTime(uint256 _genTime) public onlyOwner {
        require(_genTime > 0);
        genTime = _genTime;
    }

    function setToken(address newToken) public onlyOwner {
        require(newToken != 0x00);
        token = ERC20Basic(newToken);
    }
    
    function destruct(address to) public onlyOwner {
        require(to != 0x00);
        selfdestruct(to);
    }
}