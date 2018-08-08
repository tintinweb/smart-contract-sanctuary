pragma solidity ^0.4.18;

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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title PoSTokenStandard
 * @dev the interface of PoSTokenStandard
 */
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge() constant public returns (uint256);
    function annualInterest() constant public returns (uint256);
    event Mint(address indexed _address, uint _reward);
}


contract BITTOToken is ERC20,PoSTokenStandard,Ownable {
    using SafeMath for uint256;

    string public name = "BITTO";
    string public symbol = "BITTO";
    uint public decimals = 18;

    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 15 days; // minimum age for coin age: 3D
    uint public stakeMaxAge = 90 days; // stake age of full weight: 90D
    // uint public maxMintProofOfStake = 10**17; // default 10% annual interest
    uint constant REWARDS_PER_AGE = 622665006227000;  // token rewards per coin age.

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    mapping(address => bool) public noPOSRewards;

    struct transferInStruct {
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

    function BITTOToken() public {
        // 5 mil is reserved for POS rewards
        maxTotalSupply = 223 * 10**23; // 22.3 Mil.
        totalInitialSupply = 173 * 10**23; // 17.3 Mil. 10 mil = crowdsale, 7.3 team account

        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        if (msg.sender == _to)
            return mint();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        if (transferIns[msg.sender].length > 0)
            delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        if (transferIns[_from].length > 0)
            delete transferIns[_from];
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function mint() canPoSMint public returns (bool) {
        // minimum stake of 5000 BITTO is required to earn staking.
        if (balances[msg.sender] < 5000 ether)
            return false;
        if (transferIns[msg.sender].length <= 0)
            return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if (reward <= 0)
            return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        Transfer(address(0), msg.sender, reward);
        Mint(msg.sender, reward);
        return true;
    }

    function getBlockNumber() view public returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() constant public returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() constant public returns (uint interest) {
        // uint _now = now;
        // interest = maxMintProofOfStake;
        // if ((_now.sub(stakeStartTime)).div(1 years) == 0) {
        //     interest = (770 * maxMintProofOfStake).div(100);
        // } else if ((_now.sub(stakeStartTime)).div(1 years) == 1) {
        //     interest = (435 * maxMintProofOfStake).div(100);
        // }

        return REWARDS_PER_AGE;
    }

    function getProofOfStakeReward(address _address) internal returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        require(!noPOSRewards[_address]);

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if (_coinAge <= 0)
            return 0;

        // uint interest = maxMintProofOfStake;
        // // Due to the high interest rate for the first two years, compounding should be taken into account.
        // // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        // if ((_now.sub(stakeStartTime)).div(1 years) == 0) {
        //     // 1st year effective annual interest rate is 100% when we select the stakeMaxAge (90 days) as the compounding period.
        //     interest = (770 * maxMintProofOfStake).div(100);
        // } else if ((_now.sub(stakeStartTime)).div(1 years) == 1) {
        //     // 2nd year effective annual interest rate is 50%
        //     interest = (435 * maxMintProofOfStake).div(100);
        // }

        // return (_coinAge * interest).div(365 * (10**decimals));
        return _coinAge.mul(REWARDS_PER_AGE);
    }

    function getCoinAge(address _address, uint _now) internal returns (uint _coinAge) {
        if (transferIns[_address].length <= 0)
            return 0;

        for (uint i = 0; i < transferIns[_address].length; i++) {
            if (_now < uint(transferIns[_address][i].time).add(stakeMinAge))
                continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if ( nCoinSeconds > stakeMaxAge )
                nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
        _coinAge = _coinAge.div(5000 ether);
    }

    function ownerSetStakeStartTime(uint timestamp) onlyOwner public {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

    function ownerBurnToken(uint _value) onlyOwner public {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        maxTotalSupply = maxTotalSupply.sub(_value*10);

        Burn(msg.sender, _value);
    }

    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

    /* Batch token transfer. Used by contract creator to distribute initial tokens to holders */
    function batchTransfer(address[] _recipients, uint[] _values) onlyOwner public returns (bool) {
        require(_recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for (uint i = 0; i < _values.length; i++) {
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);
        for (uint j = 0; j < _recipients.length; j++) {
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            transferIns[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now));
            Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        if (transferIns[msg.sender].length > 0)
            delete transferIns[msg.sender];
        if (balances[msg.sender] > 0)
            transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));

        return true;
    }

    function disablePOSReward(address _account, bool _enabled) onlyOwner public {
        noPOSRewards[_account] = _enabled;
    }
}