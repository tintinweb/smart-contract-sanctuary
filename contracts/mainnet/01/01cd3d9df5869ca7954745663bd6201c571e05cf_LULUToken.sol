pragma solidity ^0.4.19;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
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

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract LULUToken is StandardToken {
  using SafeMath for uint256;

  string public name = "LULU Token";
  string public symbol = "LULU";
  string public releaseArr = &#39;0000000000000000000&#39;;
 
  uint public decimals = 18;
  
  function LULUToken() {
    totalSupply = 100000000000 * 1000000000000000000;
    balances[msg.sender] = totalSupply / 5;
  }

  function tokenRelease() public returns (string) {
     
    uint256 y2019 = 1557936000;
    uint256 y2020 = 1589558400;
    uint256 y2021 = 1621094400;
    uint256 y2022 = 1652630400;
    uint256 y2023 = 1684166400;

    if (now > y2019 && now <= 1573833600 && bytes(releaseArr)[0] == &#39;0&#39;) {
        bytes(releaseArr)[0] = &#39;1&#39;;
        balances[msg.sender] = balances[msg.sender] + totalSupply / 10;
        return releaseArr;
    } else if (now > 1573833600 && now <= y2020 && bytes(releaseArr)[1] == &#39;0&#39;) {
        bytes(releaseArr)[1] = &#39;1&#39;;
        balances[msg.sender] = balances[msg.sender] + totalSupply / 10;
        return releaseArr;
    }
    
    if (now > y2020 && now <= 1605456000 && bytes(releaseArr)[2] == &#39;0&#39;) {
        bytes(releaseArr)[2] = &#39;1&#39;;
        balances[msg.sender] = balances[msg.sender] + totalSupply / 10;
        return releaseArr;
    } else if (now > 1605456000 && now <= y2021  && bytes(releaseArr)[3] == &#39;0&#39;) {
        bytes(releaseArr)[3] = &#39;1&#39;;
        balances[msg.sender] = balances[msg.sender] + totalSupply / 10;
        return releaseArr;
    }
    
    if (now > y2021 && now <= 1636992000 && bytes(releaseArr)[4] == &#39;0&#39;) {
        bytes(releaseArr)[4] = &#39;1&#39;;
        balances[msg.sender] = balances[msg.sender] + totalSupply / 10;
        return releaseArr;
    } else if (now > 1636992000 && now <= y2022 && bytes(releaseArr)[5] == &#39;0&#39;) {
        bytes(releaseArr)[5] = &#39;1&#39;;
        balances[msg.sender] = balances[msg.sender] + totalSupply / 10;
        return releaseArr;
    }
    
    if (now > y2022 && now <= 1668528000 && bytes(releaseArr)[6] == &#39;0&#39;) {
        bytes(releaseArr)[6] = &#39;1&#39;;
        balances[msg.sender] = balances[msg.sender] + totalSupply / 10;
        return releaseArr;
    }else if (now > 1668528000  && now <= y2023 && bytes(releaseArr)[7] == &#39;0&#39;) {
        bytes(releaseArr)[7] = &#39;1&#39;;
        balances[msg.sender] = balances[msg.sender] + totalSupply / 10;
        return releaseArr;
    }

    return releaseArr;
  }
}