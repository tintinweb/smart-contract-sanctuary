pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable {

  string public contactInformation;

  /**
    * @dev Allows the owner to set a string with their contact information.
    * @param _info The contact information to attach to the contract.
    */
  function setContactInformation(string _info) public onlyOwner {
    contactInformation = _info;
  }
}


contract IERC223Basic {
  function balanceOf(address _owner) public constant returns (uint);
  function transfer(address _to, uint _value) public;
  function transfer(address _to, uint _value, bytes _data) public;
  event Transfer(
    address indexed from,
    address indexed to,
    uint value,
    bytes data
  );
}


contract IERC223 is IERC223Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint);

  function transferFrom(address _from, address _to, uint _value, bytes _data)
    public;

  function approve(address _spender, uint _value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract IERC223BasicReceiver {
  function tokenFallback(address _from, uint _value, bytes _data) public;
}


contract IERC223Receiver is IERC223BasicReceiver {
  function receiveApproval(address _owner, uint _value) public;
}


/**
 * @title Basic contract that will hold ERC223 tokens
 */
contract ERC223BasicReceiver is IERC223BasicReceiver {
  event TokensReceived(address sender, address origin, uint value, bytes data);

  /**
   * @dev Standard ERC223 function that will handle incoming token transfers
   * @param _from address the tokens owner
   * @param _value uint the sent tokens amount
   * @param _data bytes metadata
   */
  function tokenFallback(address _from, uint _value, bytes _data) public {
    require(_from != address(0));
    emit TokensReceived(msg.sender, _from, _value, _data);
  }
}


/**
 * @title Contract that will hold ERC223 tokens
 */
contract ERC223Receiver is ERC223BasicReceiver, IERC223Receiver {
  event ApprovalReceived(address sender, address owner, uint value);

  /**
   * @dev Function that will handle incoming token approvals
   * @param _owner address the tokens owner
   * @param _value uint the approved tokens amount
   */
  function receiveApproval(address _owner, uint _value) public {
    require(_owner != address(0));
    emit ApprovalReceived(msg.sender, _owner, _value);
  }
}


/**
 * @title Contract that can hold and transfer ERC-223 tokens
 */
contract Fund is ERC223Receiver, Contactable {
  IERC223 public token;
  string public fundName;

  /**
   * @dev Constructor that sets the initial contract parameters
   * @param _token ERC223 address of the ERC-223 token
   * @param _fundName string the fund name
   */
  constructor(IERC223 _token, string _fundName) public {
    require(address(_token) != address(0));
    token = _token;
    fundName = _fundName;
  }

  /**
   * @dev ERC-20 compatible function to transfer tokens
   * @param _to address the tokens recepient
   * @param _value uint amount of the tokens to be transferred
   */
  function transfer(address _to, uint _value) public onlyOwner {
    token.transfer(_to, _value);
  }

  /**
   * @dev Function to transfer tokens
   * @param _to address the tokens recepient
   * @param _value uint amount of the tokens to be transferred
   * @param _data bytes metadata
   */
  function transfer(address _to, uint _value, bytes _data) public onlyOwner {
    token.transfer(_to, _value, _data);
  }

  /**
   * @dev Function to transfer tokens from the approved `msg.sender` account
   * @param _from address the tokens owner
   * @param _to address the tokens recepient
   * @param _value uint amount of the tokens to be transferred
   * @param _data bytes metadata
   */
  function transferFrom(
    address _from,
    address _to,
    uint _value,
    bytes _data
  )
    public
    onlyOwner
  {
    token.transferFrom(_from, _to, _value, _data);
  }

  /**
   * @dev Function to approve account to spend owned tokens
   * @param _spender address the tokens spender
   * @param _value uint amount of the tokens to be approved
   */
  function approve(address _spender, uint _value) public onlyOwner {
    token.approve(_spender, _value);
  }
}


/**
 * @title HEdpAY
 */
contract Hedpay is IERC223, Contactable {
  using AddressUtils for address;
  using SafeMath for uint;

  string public constant name = "HEdpAY";
  string public constant symbol = "Hdp.ф";
  uint8 public constant decimals = 4;
  uint8 public constant secondPhaseBonus = 33;
  uint8[3] public thirdPhaseBonus = [10, 15, 20];
  uint public constant totalSupply = 10000000000000;
  uint public constant secondPhaseStartTime = 1537401600; //20.09.2018
  uint public constant secondPhaseEndTime = 1540943999; //30.10.2018
  uint public constant thirdPhaseStartTime = 1540944000;//31.10.2018
  uint public constant thirdPhaseEndTime = 1543622399;//30.11.2018
  uint public constant cap = 200000 ether;
  uint public constant goal = 25000 ether;
  uint public constant rate = 100;
  uint public constant minimumWeiAmount = 100 finney;
  uint public constant salePercent = 14;
  uint public constant bonusPercent = 1;
  uint public constant teamPercent = 2;
  uint public constant preSalePercent = 3;

  uint public creationTime;
  uint public weiRaised;
  uint public tokensSold;
  uint public buyersCount;
  uint public saleAmount;
  uint public bonusAmount;
  uint public teamAmount;
  uint public preSaleAmount;
  uint public unsoldTokens;

  address public teamAddress = 0x7d4E738477B6e8BaF03c4CB4944446dA690f76B5;
  
  Fund public reservedFund;

  mapping (address => uint) internal balances;
  mapping (address => mapping (address => uint)) internal allowed;
  mapping (address => uint) internal bonuses;

  /**
   * @dev Constructor that sets initial contract parameters
   */
  constructor() public {
    balances[owner] = totalSupply;
    creationTime = block.timestamp;
    saleAmount = totalSupply.div(100).mul(salePercent).mul(
      10 ** uint(decimals)
    );
    bonusAmount = totalSupply.div(100).mul(bonusPercent).mul(
      10 ** uint(decimals)
    );
    teamAmount = totalSupply.div(100).mul(teamPercent).mul(
      10 ** uint(decimals)
    );
    preSaleAmount = totalSupply.div(100).mul(preSalePercent).mul(
      10 ** uint(decimals)
    );
  }

  /**
   * @dev Gets an account tokens balance
   * @param _owner address the tokens owner
   * @return uint the specified address owned tokens amount
   */
  function balanceOf(address _owner) public view returns (uint) {
    require(_owner != address(0));
    return balances[_owner];
  }

  /**
   * @dev Gets the specified accounts approval value
   * @param _owner address the tokens owner
   * @param _spender address the tokens spender
   * @return uint the specified accounts spending tokens amount
   */
  function allowance(address _owner, address _spender)
    public view returns (uint)
  {
    require(_owner != address(0));
    require(_spender != address(0));
    return allowed[_owner][_spender];
  }

  /**
   * @dev Checks whether the ICO has started
   * @return bool true if the crowdsale began
   */
  function hasStarted() public view returns (bool) {
    return block.timestamp >= secondPhaseStartTime;
  }

  /**
   * @dev Checks whether the ICO has ended
   * @return bool `true` if the crowdsale is over
   */
  function hasEnded() public view returns (bool) {
    return block.timestamp > thirdPhaseEndTime;
  }

  /**
   * @dev Checks whether the cap has reached
   * @return bool `true` if the cap has reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Gets the current tokens amount can be purchased for the specified
   * @dev wei amount
   * @param _weiAmount uint wei amount
   * @return uint tokens amount
   */
  function getTokenAmount(uint _weiAmount) public pure returns (uint) {
    return _weiAmount.mul(rate).div((18 - uint(decimals)) ** 10);
  }

  /**
   * @dev Gets the current tokens amount can be purchased for the specified
   * @dev wei amount (including bonuses)
   * @param _weiAmount uint wei amount
   * @return uint tokens amount
   */
  function getTokenAmountBonus(uint _weiAmount)
    public view returns (uint)
  {
    if (hasStarted() && secondPhaseEndTime >= block.timestamp) {
      return(
        getTokenAmount(_weiAmount).
        add(
          getTokenAmount(_weiAmount).
          div(100).
          mul(uint(secondPhaseBonus))
        )
      );
    } else if (thirdPhaseStartTime <= block.timestamp && !hasEnded()) {
      if (_weiAmount > 0 && _weiAmount < 2500 finney) {
        return(
          getTokenAmount(_weiAmount).
          add(
            getTokenAmount(_weiAmount).
            div(100).
            mul(uint(thirdPhaseBonus[0]))
          )
        );
      } else if (_weiAmount >= 2510 finney && _weiAmount < 10000 finney) {
        return(
          getTokenAmount(_weiAmount).
          add(
            getTokenAmount(_weiAmount).
            div(100).
            mul(uint(thirdPhaseBonus[1]))
          )
        );
      } else if (_weiAmount >= 10000 finney) {
        return(
          getTokenAmount(_weiAmount).
          add(
            getTokenAmount(_weiAmount).
            div(100).
            mul(uint(thirdPhaseBonus[2]))
          )
        );
      }
    } else {
      return getTokenAmount(_weiAmount);
    }
  }

  /**
   * @dev Gets an account tokens bonus
   * @param _owner address the tokens owner
   * @return uint owned tokens bonus
   */
  function bonusOf(address _owner) public view returns (uint) {
    require(_owner != address(0));
    return bonuses[_owner];
  }

  /**
   * @dev Gets an account tokens balance without freezed part of the bonuses
   * @param _owner address the tokens owner
   * @return uint owned tokens amount without freezed bonuses
   */
  function balanceWithoutFreezedBonus(address _owner)
    public view returns (uint)
  {
    require(_owner != address(0));
    if (block.timestamp >= thirdPhaseEndTime.add(90 days)) {
      if (bonusOf(_owner) < 10000) {
        return balanceOf(_owner);
      } else {
        return balanceOf(_owner).sub(bonuses[_owner].div(2));
      }
    } else if (block.timestamp >= thirdPhaseEndTime.add(180 days)) {
      return balanceOf(_owner);
    } else {
      return balanceOf(_owner).sub(bonuses[_owner]);
    }
  }

  /**
   * @dev ERC-20 compatible function to transfer tokens
   * @param _to address the tokens recepient
   * @param _value uint amount of the tokens to be transferred
   */
  function transfer(address _to, uint _value) public {
    transfer(_to, _value, "");
  }

  /**
   * @dev Function to transfer tokens
   * @param _to address the tokens recepient
   * @param _value uint amount of the tokens to be transferred
   * @param _data bytes metadata
   */
  function transfer(address _to, uint _value, bytes _data) public {
    require(_value <= balanceWithoutFreezedBonus(msg.sender));
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    _safeTransfer(msg.sender, _to, _value, _data);

    emit Transfer(msg.sender, _to, _value, _data);
  }

  /**
   * @dev Function to transfer tokens from the approved `msg.sender` account
   * @param _from address the tokens owner
   * @param _to address the tokens recepient
   * @param _value uint amount of the tokens to be transferred
   * @param _data bytes metadata
   */
  function transferFrom(
    address _from,
    address _to,
    uint _value,
    bytes _data
  )
    public
  {
    require(_from != address(0));
    require(_to != address(0));
    require(_value <= allowance(_from, msg.sender));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _safeTransfer(_from, _to, _value, _data);

    emit Transfer(_from, _to, _value, _data);
    emit Approval(_from, msg.sender, allowance(_from, msg.sender));
  }

  /**
   * @dev Function to approve account to spend owned tokens
   * @param _spender address the tokens spender
   * @param _value uint amount of the tokens to be approved
   */
  function approve(address _spender, uint _value) public {
    require(_spender != address(0));
    require(_value <= balanceWithoutFreezedBonus(msg.sender));
    allowed[msg.sender][_spender] = _value;
    _safeApprove(_spender, _value);
    emit Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to increase spending tokens amount
   * @param _spender address the tokens spender
   * @param _value uint increase tokens amount
   */
  function increaseApproval(address _spender, uint _value) public {
    require(_spender != address(0));
    require(
      allowance(msg.sender, _spender).add(_value) <=
      balanceWithoutFreezedBonus(msg.sender)
    );

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);
    _safeApprove(_spender, allowance(msg.sender, _spender));
    emit Approval(msg.sender, _spender, allowance(msg.sender, _spender));
  }

  /**
   * @dev Function to decrease spending tokens amount
   * @param _spender address the tokens spender
   * @param _value uint decrease tokens amount
   */
  function decreaseApproval(address _spender, uint _value) public {
    require(_spender != address(0));
    require(_value <= allowance(msg.sender, _spender));
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_value);
    _safeApprove(_spender, allowance(msg.sender, _spender));
    emit Approval(msg.sender, _spender, allowance(msg.sender, _spender));
  }

  /**
   * @dev Function to set an account bonus
   * @param _owner address the tokens owner
   * @param _value uint bonus tokens amount
   */
  function setBonus(address _owner, uint _value, bool preSale)
    public onlyOwner
  {
    require(_owner != address(0));
    require(_value <= balanceOf(_owner));
    require(bonusAmount > 0);
    require(_value <= bonusAmount);

    bonuses[_owner] = _value;
    if (preSale) {
      preSaleAmount = preSaleAmount.sub(_value);
      transfer(_owner, _value, abi.encode("transfer the bonus"));
    } else {
      if (_value <= bonusAmount) {
        bonusAmount = bonusAmount.sub(_value);
        transfer(_owner, _value, abi.encode("transfer the bonus"));
      }
    }

  }

  /**
   * @dev Function to refill balance of the specified account
   * @param _to address the tokens recepient
   * @param _weiAmount uint amount of the tokens to be transferred
   */
  function refill(address _to, uint _weiAmount) public onlyOwner {
    require(_preValidateRefill(_to, _weiAmount));
    setBonus(
      _to,
      getTokenAmountBonus(_weiAmount).sub(
        getTokenAmount(_weiAmount)
      ),
      false
    );
    buyersCount = buyersCount.add(1);
    saleAmount = saleAmount.sub(getTokenAmount(_weiAmount));
    transfer(_to, getTokenAmount(_weiAmount), abi.encode("refill"));
  }

  /**
   * @dev Function to refill balances of the specified accounts
   * @param _to address[] the tokens recepients
   * @param _weiAmount uint[] amounts of the tokens to be transferred
   */
  function refillArray(address[] _to, uint[] _weiAmount) public onlyOwner {
    require(_to.length == _weiAmount.length);
    for (uint i = 0; i < _to.length; i++) {
      refill(_to[i], _weiAmount[i]);
    }
  }
  
  /**
   * @dev Function that transfers tokens to team address
   */
  function setTeamFund() public onlyOwner{
    transfer(
      teamAddress,
      teamAmount,
      abi.encode("transfer reserved for team tokens to the team fund")
      );
    teamAmount = 0;
  }

  /**
   * @dev Function to finalize the sale and define reservedFund
   * @param _reservedFund fund that holds unsold tokens 
   */
  function finalize(Fund _reservedFund) public onlyOwner {
    require(saleAmount > 0);
    transfer(
      address(_reservedFund),
      saleAmount,
      abi.encode("transfer reserved for team tokens to the team fund")
    );
    saleAmount = 0;
  }

  /**
   * @dev Internal function to call the `tokenFallback` if the tokens
   * @dev recepient is the smart-contract. If the contract doesn&#39;t implement
   * @dev this function transaction fails
   * @param _from address the tokens owner
   * @param _to address the tokens recepient (perhaps the contract)
   * @param _value uint amount of the tokens to be transferred
   * @param _data bytes metadata
   */
  function _safeTransfer(
    address _from,
    address _to,
    uint _value,
    bytes _data
  )
    internal
  {
    if (_to.isContract()) {
      IERC223BasicReceiver receiver = IERC223BasicReceiver(_to);
      receiver.tokenFallback(_from, _value, _data);
    }
  }

  /**
   * @dev Internal function to call the `receiveApproval` if the tokens
   * @dev recepient is the smart-contract. If the contract doesn&#39;t implement
   * @dev this function transaction fails
   * @param _spender address the tokens recepient (perhaps the contract)
   * @param _value uint amount of the tokens to be approved
   */
  function _safeApprove(address _spender, uint _value) internal {
    if (_spender.isContract()) {
      IERC223Receiver receiver = IERC223Receiver(_spender);
      receiver.receiveApproval(msg.sender, _value);
    }
  }

  /**
   * @dev Internal function to prevalidate refill before execution
   * @param _to address the tokens recepient
   * @param _weiAmount uint amount of the tokens to be transferred
   * @return bool `true` if the refill can be executed
   */
  function _preValidateRefill(address _to, uint _weiAmount)
    internal view returns (bool)
  {
    return(
      hasStarted() && _weiAmount > 0 &&  weiRaised.add(_weiAmount) <= cap
      && _to != address(0) && _weiAmount >= minimumWeiAmount &&
      getTokenAmount(_weiAmount) <= saleAmount
    );
  }
}