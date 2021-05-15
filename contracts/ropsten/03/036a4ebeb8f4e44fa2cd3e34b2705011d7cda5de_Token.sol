pragma solidity ^0.4.23;

import "./StandardToken.sol";
import "./Ownable.sol";


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract Token is StandardToken, Ownable {

  modifier tokensReleased() {
    require(block.timestamp > releaseTime);
    _;
  }

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public timeLock;
  uint256 public releaseTime;
  uint256 _totalSupply = 10000000;

  function pow(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        }
        else if (exponent == 1) {
            return base;
        }
        else if (base == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = base;
            for (uint256 i = 1; i < exponent; i++)
                z = z.mul(base);
            return z;
        }
    }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    tokensReleased
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  constructor(
    string _name,
    string _symbol,
    uint8 _decimals,
    uint256 _timeLock
  )
  public
  {
    require(_decimals < 19);
    require(_totalSupply >= 0);
    require(_timeLock >= 0);
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply_ = _totalSupply.mul(pow(10, _decimals));
    balances[msg.sender] = totalSupply_;
    timeLock = _timeLock;
    releaseTime = (block.timestamp).add(timeLock);
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(
    address _to,
    uint256 _value
  )
  public
  tokensReleased
  returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


}