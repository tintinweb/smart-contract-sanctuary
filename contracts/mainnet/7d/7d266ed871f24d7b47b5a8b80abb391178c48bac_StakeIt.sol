pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.4.23;


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title StakeItStandard
 * @dev the interface of StakeItStandard
 */
contract StakeItStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge() public constant returns (uint256);
    function annualInterest() public constant returns (uint256);
    event Mint(address indexed _address, uint _reward);
}


contract StakeIt is ERC20, StakeItStandard, Ownable {
    using SafeMath for uint256;

    string public name = "StakeIt";
    string public symbol = "STAKE";
    uint public decimals = 8;

    uint public chainStartTime; // chain start time
    uint public chainStartBlockNumber; // chain start block number
    uint public stakeStartTime; // stake start time
    uint public stakeMinAge = 1 days; // minimum age for coin age: 1 Day
    uint public stakeMaxAge = 90 days; // stake age of full weight: 90 Days
    uint public MintProofOfStake = 100 * 10 ** uint256(decimals); // default 100% annual interest

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    struct transferInStruct{
    uint128 amount;
    uint64 time;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier canPoSMint() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    constructor() public {
        maxTotalSupply = 100000000 * 10 ** uint256(decimals); // 100,000,000
        totalInitialSupply = 5000000 * 10 ** uint256(decimals); // 5,000,000

        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        if(msg.sender == _to) return mint();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        if(transferIns[_from].length > 0) delete transferIns[_from];
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function changeRate(uint _rate) public onlyOwner {
        MintProofOfStake = _rate * 10 ** uint256(decimals);
    }

    function mint() canPoSMint public returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Mint(msg.sender, reward);
        return true;
    }

    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() public constant returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender, now);
    }

    function annualInterest() public constant returns(uint interest) {
        interest = MintProofOfStake;
    }

    function getProofOfStakeReward(address _address) internal view returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;

        uint interest = MintProofOfStake;

        return (_coinAge * interest).div(365 * (10**uint256(decimals)));
    }

    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;

        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    function ownerSetStakeStartTime(uint timestamp) public onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

    function ownerBurnToken(uint _value) public onlyOwner {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        maxTotalSupply = maxTotalSupply.sub(_value*10);

        emit Burn(msg.sender, _value);
    }

    /* Batch token transfer. Used by contract creator to distribute initial tokens to holders */
    function batchTransfer(address[] _recipients, uint[] _values) public onlyOwner returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for(uint i = 0; i < _values.length; i++){
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);
        for(uint j = 0; j < _recipients.length; j++){
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            transferIns[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now));
            emit Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        if(balances[msg.sender] > 0) transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));

        return true;
    }
}