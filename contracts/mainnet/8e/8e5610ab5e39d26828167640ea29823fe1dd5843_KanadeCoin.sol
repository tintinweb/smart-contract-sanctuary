pragma solidity ^0.4.23;



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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


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


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}



contract KanadeCoin is StandardToken, Ownable {
    using SafeMath for uint256;

    struct VoteStruct {
        uint128 number;
        uint256 amount;
        address from;
        uint128 time;
    }

    struct QuestionStruct {
        uint8   isStarted;
        address recipient;
        uint128 finish;
        uint    under;
        VoteStruct[] votes;
    }

    struct RandomBoxStruct {
        uint8   isStarted;
        address recipient;
        uint64  volume;
        uint256 amount;
        uint128 finish;
    }

    struct RandomItemStruct {
        mapping(bytes32 => uint256[]) values;
    }


    address public constant addrDevTeam      = 0x4d85FCF252c02FA849258f16c5464aF529ebFA5F; // 1%
    address public constant addrLockUp       = 0x0101010101010101010101010101010101010101; // 9%
    address public constant addrBounty       = 0x3CCDb82F43EEF681A39AE854Be37ad1C40446F0d; // 25%
    address public constant addrDistribution = 0x9D6FB734a716306a9575E3ce971AB8839eDcEdF3; // 10%
    address public constant addrAirDrop      = 0xD6A4ce07f18619Ec73f91CcDbefcCE53f048AE05; // 55%

    uint public constant atto = 100000000;
    uint public constant decimals = 8;

    string public constant name   = "KanadeCoin";
    string public constant symbol = "KNDC";

    uint public contractStartTime;

    uint64 public constant lockupSeconds = 60 * 60 * 24 * 365 * 3;

    mapping(bytes32 => QuestionStruct) questions;
    mapping(address => string) saveData;
    mapping(bytes32 => RandomBoxStruct) randomBoxes;
    mapping(address => RandomItemStruct) randomItems;

    constructor() public {
    }

    function initializeContract() onlyOwner public {
        if (totalSupply_ != 0) return;

        contractStartTime = now;

        balances[addrDevTeam]      = 10000000000 * 0.01 * atto;
        balances[addrLockUp]       = 10000000000 * 0.09 * atto;
        balances[addrBounty]       = 10000000000 * 0.25 * atto;
        balances[addrDistribution] = 10000000000 * 0.10 * atto;
        balances[addrAirDrop]      = 10000000000 * 0.55 * atto;

        Transfer(0x0, addrDevTeam, balances[addrDevTeam]);
        Transfer(0x0, addrLockUp, balances[addrLockUp]);
        Transfer(0x0, addrBounty, balances[addrBounty]);
        Transfer(0x0, addrDistribution, balances[addrDistribution]);
        Transfer(0x0, addrAirDrop, balances[addrAirDrop]);

        totalSupply_ = 10000000000 * atto;
    }


    ////////////////////////////////////////////////////////////////////////

    function unLockup() onlyOwner public {
        require(uint256(now).sub(lockupSeconds) > contractStartTime);
        uint _amount = balances[addrLockUp];
        balances[addrLockUp] = balances[addrLockUp].sub(_amount);
        balances[addrDevTeam] = balances[addrDevTeam].add(_amount);
        Transfer(addrLockUp, addrDevTeam, _amount);
    }


    ////////////////////////////////////////////////////////////////////////

    function createQuestion(string _id_max32, address _recipient, uint128 _finish, uint _under) public {
        bytes32 _idByte = keccak256(_id_max32);
        require(questions[_idByte].isStarted == 0);

        transfer(addrBounty, 5000 * atto);

        questions[_idByte].isStarted = 1;
        questions[_idByte].recipient = _recipient;
        questions[_idByte].finish = _finish;
        questions[_idByte].under = _under;
    }

    function getQuestion(string _id_max32) constant public returns (uint[4]) {
        bytes32 _idByte = keccak256(_id_max32);
        uint[4] values;
        values[0] = questions[_idByte].isStarted;
        values[1] = uint(questions[_idByte].recipient);
        values[2] = questions[_idByte].finish;
        values[3] = questions[_idByte].under;
        return values;
    }

    function vote(string _id_max32, uint128 _number, uint _amount) public {
        bytes32 _idByte = keccak256(_id_max32);
        require(
            questions[_idByte].isStarted == 1 &&
            questions[_idByte].under <= _amount &&
            questions[_idByte].finish >= uint128(now));

        if (_amount > 0) {
            transfer(questions[_idByte].recipient, _amount);
        }

        questions[_idByte].votes.push(VoteStruct(_number, _amount, msg.sender, uint128(now)));
    }

    function getQuestionVotesAllCount(string _id_max32) constant public returns (uint) {
        return questions[keccak256(_id_max32)].votes.length;
    }

    function getQuestionVote(string _id_max32, uint _position) constant public returns (uint[4]) {
        bytes32 _idByte = keccak256(_id_max32);
        uint[4] values;
        values[0] = questions[_idByte].votes[_position].number;
        values[1] = questions[_idByte].votes[_position].amount;
        values[2] = uint(questions[_idByte].votes[_position].from);
        values[3] = questions[_idByte].votes[_position].time;
        return values;
    }


    ////////////////////////////////////////////////////////////////////////

    function putSaveData(string _text) public {
        saveData[msg.sender] = _text;
    }

    function getSaveData(address _address) constant public returns (string) {
        return saveData[_address];
    }


    ////////////////////////////////////////////////////////////////////////

    function createRandomBox(string _id_max32, address _recipient, uint64 _volume, uint256 _amount, uint128 _finish) public {
        require(_volume > 0);

        bytes32 _idByte = keccak256(_id_max32);
        require(randomBoxes[_idByte].isStarted == 0);

        transfer(addrBounty, 5000 * atto);

        randomBoxes[_idByte].isStarted = 1;
        randomBoxes[_idByte].recipient = _recipient;
        randomBoxes[_idByte].volume = _volume;
        randomBoxes[_idByte].amount = _amount;
        randomBoxes[_idByte].finish = _finish;
    }

    function getRandomBox(string _id_max32) constant public returns (uint[5]) {
        bytes32 _idByte = keccak256(_id_max32);
        uint[5] values;
        values[0] = randomBoxes[_idByte].isStarted;
        values[1] = uint(randomBoxes[_idByte].recipient);
        values[2] = randomBoxes[_idByte].volume;
        values[3] = randomBoxes[_idByte].amount;
        values[4] = randomBoxes[_idByte].finish;
        return values;
    }

    function drawRandomItem(string _id_max32, uint _count) public {
        require(_count > 0 && _count <= 1000);

        bytes32 _idByte = keccak256(_id_max32);
        uint _totalAmount = randomBoxes[_idByte].amount.mul(_count);
        require(
            randomBoxes[_idByte].isStarted == 1 &&
            randomBoxes[_idByte].finish >= uint128(now));

        transfer(randomBoxes[_idByte].recipient, _totalAmount);

        for (uint i = 0; i < _count; i++) {
            uint randomVal = uint(
                keccak256(blockhash(block.number-1), randomItems[msg.sender].values[_idByte].length))
                % randomBoxes[_idByte].volume;
            randomItems[msg.sender].values[_idByte].push(randomVal);
        }
    }

    function getRandomItems(address _addrss, string _id_max32) constant public returns (uint[]) {
        return randomItems[_addrss].values[keccak256(_id_max32)];
    }


    ////////////////////////////////////////////////////////////////////////

    function airDrop(address[] _recipients, uint[] _values) onlyOwner public returns (bool) {
        return distribute(addrAirDrop, _recipients, _values);
    }

    function rain(address[] _recipients, uint[] _values) public returns (bool) {
        return distribute(msg.sender, _recipients, _values);
    }

    function distribute(address _from, address[] _recipients, uint[] _values) internal returns (bool) {
        require(_recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for(uint i = 0; i < _values.length; i++) {
            total = total.add(_values[i]);
        }
        require(total <= balances[_from]);

        for(uint j = 0; j < _recipients.length; j++) {
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            Transfer(_from, _recipients[j], _values[j]);
        }

        balances[_from] = balances[_from].sub(total);

        return true;
    }

}