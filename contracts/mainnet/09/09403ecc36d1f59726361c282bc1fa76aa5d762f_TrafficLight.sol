/**
 *Submitted for verification at Etherscan.io on 2020-11-15
*/

/**
 * SPDX-License-Identifier: UNLICENSED
 * TrafficLight.Finance -> Token Contract
 *       _____          __  __ _    _    _      _   _   
 *     |_   _| _ __ _ / _|/ _(_)__| |  (_)__ _| |_| |_ 
 *       | || '_/ _` |  _|  _| / _| |__| / _` | ' \  _|
 *       |_||_| \__,_|_| |_| |_\__|____|_\__, |_||_\__|
 *                                       |___/          
*/

pragma solidity 0.6.12;

library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Ownable {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract TrafficLight is Ownable {
  using SafeMath for uint256;

  // standard ERC20 variables. 
  string public constant name = "TrafficLight.Finance";
  string public constant symbol = "TFL";
  uint256 public constant decimals = 18;
  uint256 private constant _maximumSupply = 10 ** decimals;
  uint256 public _totalSupply;
  uint256 public light;
  uint256 public reward;
  bool public start;
  uint256 public burnPercent;
  uint256 public rewardPercent;
  uint256 public rewardDistributionPercent;

  // events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event changeLight(uint value);


  mapping(address => uint256) public _balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor(uint256 _initialSupply) public {

    _owner = msg.sender;
    _totalSupply = _maximumSupply * _initialSupply;
    _balanceOf[msg.sender] = _maximumSupply * _initialSupply;
    reward = 0;
    start = false;
    light = 1;
    burnPercent = 3;
    rewardPercent = 3;
    rewardDistributionPercent = 10;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function totalSupply () public view returns (uint256) {
    return _totalSupply; 
  }

  function balanceOf (address who) public view returns (uint256) {
    return _balanceOf[who];
  }

  function findReward (uint256 value) public view returns (uint256)  {
    uint256 reward_val = value.mul(rewardPercent).div(100);  
    return reward_val;
  }
  
  function findBurn (uint256 value) public view returns (uint256)  {
    uint256 burn_val = value.mul(burnPercent).div(100); 
    return burn_val;
  }


  function _transfer(address _from, address _to, uint256 _value) internal {
    
    if (light==1)
    {
        if (start==false)
        {
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        } else {
            
            uint256 tokensToBurn = findBurn (_value);
            uint256 valueToSend = _value.sub(tokensToBurn);
            
            _balanceOf[_from] = _balanceOf[_from].sub(_value);
            _balanceOf[0x0000000000000000000000000000000000000000] = _balanceOf[0x0000000000000000000000000000000000000000].add(tokensToBurn);
            _balanceOf[_to] = _balanceOf[_to].add(valueToSend);
        
            emit Transfer(_from, 0x0000000000000000000000000000000000000000, tokensToBurn);
            emit Transfer(_from, _to, valueToSend);
            
        }
    } else if (light==2) {
            
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        
        if (reward > 2)
        {
            uint256 reward_to_send = reward.div(rewardDistributionPercent);
            _balanceOf[address(this)] = _balanceOf[address(this)].sub(reward_to_send);
            _balanceOf[_to] = _balanceOf[_to].add(reward_to_send);
            reward = reward.sub(reward_to_send);
            emit Transfer(address(this), _to, reward_to_send);
        }
    } else {
        uint256 tokensToReward = findReward(_value);
        uint256 tokensToBurn = findBurn (_value);
        uint256 tokensToTransfer = _value.sub(tokensToReward).sub(tokensToBurn);
        
        

        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(tokensToTransfer);
        _balanceOf[address(this)] = _balanceOf[address(this)].add(tokensToReward);
        _balanceOf[0x0000000000000000000000000000000000000000] = _balanceOf[0x0000000000000000000000000000000000000000].add(tokensToBurn);
        reward = reward.add(tokensToReward);
        
        emit Transfer(_from, _to, tokensToTransfer);
        emit Transfer(_from, 0x0000000000000000000000000000000000000000, tokensToBurn);
        emit Transfer(_from, address(this), tokensToReward);
    }
  }


  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_balanceOf[msg.sender] >= _value);//*10 ** decimals
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function burn (uint256 _burnAmount) public onlyOwner returns (bool success) {
    _transfer(_owner, address(0), _burnAmount);
    _totalSupply = _totalSupply.sub(_burnAmount);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0));
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }
  
  function switchlight() public {
        require(msg.sender == _owner);
        if (light==1)
        {
            light=2;
            emit changeLight(2);
        }
        else if (light==2)
        {
            light = 3;
            emit changeLight(3);
        }
        else if (light==3)
        {
            light = 1;
            emit changeLight(1);
        }
        else
        {
            light = 1;
            emit changeLight(1);
        }
    }
  
  
   function switchstart() public {
        require(msg.sender == _owner);
        if (start==false) 
            start = true;
        else
            start = false;
   }
   
   function setBurnPercent (uint256 value) public {
        require(msg.sender == _owner);
        burnPercent = value;
   }
   
   function setRewardPercent (uint256 value) public {
        require(msg.sender == _owner);
        rewardPercent = value;
   }
  
   function setRewardDistributionPercent (uint256 value) public {
        require(msg.sender == _owner);
        rewardDistributionPercent = value;
   }
  
}