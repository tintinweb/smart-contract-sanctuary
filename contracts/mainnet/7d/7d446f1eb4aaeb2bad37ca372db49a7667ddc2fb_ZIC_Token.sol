pragma solidity ^0.4.24;

/**
 * SmartEth.co
 * ERC20 Token and ICO smart contracts development, smart contracts audit, ICO websites.
 * contact@smarteth.co
 */

/**
 * @title SafeMath
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ZIC_Token is ERC20, Ownable {
    using SafeMath for uint256;

    string public name = "Zinscoin";
    string public symbol = "ZIC";
    uint public decimals = 5;

    uint public chainStartTime;
    uint public chainStartBlockNumber;
    uint public stakeStartTime;
    uint public stakeMinAge = 10 days; // minimum coin age: 10 Days
    uint public maxMintProofOfStake = 5 * 10 ** uint256(decimals-2); // Anual reward after 50 years: 5%

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
    
    event Mint(address indexed _address, uint _reward);
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
        maxTotalSupply = 2100000000 * 10 ** uint256(decimals); // Max supply: 2,100,000,000
        totalInitialSupply = 50000 * 10 ** uint256(decimals); // Initial supply: 50,000

        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[owner] = totalInitialSupply;
        emit Transfer(0x0, owner, totalInitialSupply);
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
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() public constant returns(uint interest) {
        uint _now = now;
        interest = maxMintProofOfStake;
        if((_now.sub(stakeStartTime)) <= 30 years) {
            interest = 4 * maxMintProofOfStake; // Anual reward years (0, 30]: 20%
        } else if((_now.sub(stakeStartTime)) > 30 years && (_now.sub(stakeStartTime)) <= 50 years){
            interest = 2 * maxMintProofOfStake; // Anual reward years (30, 50]: 20%
        }
    }

    function getProofOfStakeReward(address _address) internal returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;
        
        uint interest = maxMintProofOfStake;
        if((_now.sub(stakeStartTime)) <= 30 years) {
            interest = 4 * maxMintProofOfStake; // Anual reward years (0, 30]: 20%
        } else if((_now.sub(stakeStartTime)) > 30 years && (_now.sub(stakeStartTime)) <= 50 years){
            interest = 2 * maxMintProofOfStake; // Anual reward years (30, 50]: 20%
        }

        return (_coinAge * interest).div(365 * 10 ** uint256(decimals));
    }

    function getCoinAge(address _address, uint _now) internal returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;

        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));

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
}