pragma solidity 0.4.23;

/**
 * @title SafeMath by OpenZepelin
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
    constructor() public {
        owner = 0x6eDABCe168c6A63EB528B4fb83A0767d4e40E3B4;
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
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title PoSTokenStandard
 * @dev the interface of PoSTokenStandard
 */
contract PoSTokenStandard {
    uint256 public stakeStartTime; //when staking start to count
    uint256 public stakeMinAge; //minimum valid staking time
    uint256 public stakeMaxAge; //maximum valid staking time
    function mint() public returns (bool);
    function coinAge() constant public returns (uint256);
    function annualInterest() constant public returns (uint256);
    event Mint(address indexed _address, uint _reward);
}


contract PallyNetwork is ERC20,PoSTokenStandard,Ownable {
    using SafeMath for uint256;

    string public name = "PallyNetwork";
    string public symbol = "Pally";
    uint public decimals = 4;

    uint public chainStartTime; //chain start time
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 3 days; // minimum age for coin age: 3 Days
    uint public stakeMaxAge = 30 days; // stake age of full weight: 30 Days
    uint public baseIntCalc = 10**uint256(decimals - 1); // default 10% annual interest

    uint public totalSupply; //actual supply
    uint public maxTotalSupply; //maximum supply ever 
    uint public totalInitialSupply; //initial supply on deployment

    //struct to define stake stacks
    struct transferInStruct{
    uint128 amount;
    uint64 time;
    }

    //HardCodedAddresses
    address GamificationRewards = 0x62874D9863626684ab0c7e8Bd8a977680304771D;
    address AirdropDistribution = 0xCb58865a7DDf4B70354D689d640102F029C05b1f;
    address BlockchainDev = 0xC493640aE532F41E1c3188985913eD3Ca8d31Fb9;
    address MarketingAllocation = 0x609CBCa5674a1Ac2B8aA44214Cd6A4A8256Fd27f;
    address BountyPayments = 0x1d0585571518F705E4fB12fc5C01659b6eDf71E6;
    address PallyFoundation = 0x70F580B083D67949854A3A5cE1D6941504542AA8;
    address TeamSalaries = 0x840Bf950be68260fcAa127111787f98c02a4d329;
    //Mappings
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns; //mapping to stake stacks

    event Burn(address indexed burner, uint256 value);


    //modifier to limit the minting to not exceed maximum supply limit
    modifier canPoSMint() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    constructor() public {

        uint64 _now = uint64(now);
        
        maxTotalSupply = 7073844 * 10 ** uint256(decimals); // 7.073.844 maximum supply
        totalInitialSupply = 300000 * 10 ** uint256(decimals); // 300k initial supply
        totalSupply = totalInitialSupply;

        chainStartTime = now; //when contract is deployed
        stakeStartTime = now;
        
        balances[GamificationRewards] = 200000 * 10 ** uint256(decimals);//200k        
        transferIns[GamificationRewards].push(transferInStruct(uint128(balances[GamificationRewards]),_now));

        balances[AirdropDistribution] = 60000 * 10 ** uint256(decimals); //60k
        transferIns[AirdropDistribution].push(transferInStruct(uint128(balances[AirdropDistribution]),_now));

        balances[BlockchainDev] =  10000 * 10 ** uint256(decimals);//10k
        transferIns[BlockchainDev].push(transferInStruct(uint128(balances[BlockchainDev]),_now));

        balances[MarketingAllocation] =  10000 * 10 ** uint256(decimals);//10k
        transferIns[MarketingAllocation].push(transferInStruct(uint128(balances[MarketingAllocation]),_now));

        balances[BountyPayments] =  5000 * 10 ** uint256(decimals);//5k
        transferIns[BountyPayments].push(transferInStruct(uint128(balances[BountyPayments]),_now));

        balances[PallyFoundation] =  5000 * 10 ** uint256(decimals);//5k
        transferIns[PallyFoundation].push(transferInStruct(uint128(balances[PallyFoundation]),_now));

        balances[TeamSalaries] =  10000 * 10 ** uint256(decimals);//10k
        transferIns[TeamSalaries].push(transferInStruct(uint128(balances[TeamSalaries]),_now));

        //initial logs
        emit Transfer(address(0), GamificationRewards, balances[GamificationRewards]);
        emit Transfer(address(0), AirdropDistribution, balances[AirdropDistribution]);
        emit Transfer(address(0), BlockchainDev, balances[BlockchainDev]);
        emit Transfer(address(0), MarketingAllocation, balances[MarketingAllocation]); 
        emit Transfer(address(0), BountyPayments, balances[BountyPayments]);
        emit Transfer(address(0), PallyFoundation, balances[PallyFoundation]);
        emit Transfer(address(0), TeamSalaries, balances[TeamSalaries]);
            }

    function transfer(address _to, uint256 _value) public returns (bool) {

        if(msg.sender == _to || _to == address(0)) return mint(); //if self/zero transfer, trigger stake claim
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        //if there is any stake on stack, delete the stack
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        //take actual time
        uint64 _now = uint64(now);
        //reset counter for sender
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        //add counter to stack for receiver
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0)); //empty/zero address send is not allowed
        //check
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        //if there is any stake on stack, delete the stack
        if(transferIns[_from].length > 0) delete transferIns[_from];
        //take actual time
        uint64 _now = uint64(now);
        //reset counter for sender
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
         //add counter to stack for receiver
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0)); //exploit mitigation

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    //funtion to claim stake reward
    function mint() canPoSMint public returns (bool) {        
        if(balances[msg.sender] <= 0) return false;//no balance = no stake
        if(transferIns[msg.sender].length <= 0) return false;//no stake = no reward

        uint reward = getProofOfStakeReward(msg.sender);

        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward); //supply is increased
        balances[msg.sender] = balances[msg.sender].add(reward); //assigned to holder
        delete transferIns[msg.sender]; //stake stack get reset
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        //Logs
        emit Mint(msg.sender, reward);
        return true;
    }

    function coinAge() constant public returns (uint myCoinAge) {
        return myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() constant public returns(uint interest) {
        uint _now = now;
        interest = 0; // After 10 years no PoS
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 900% when we select the stakeMaxAge (30 days) as the compounding period.
            interest = (2573 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) <= 10){
            // 2nd to 10th year effective annual interest rate is 10%
            interest = (97 * baseIntCalc).div(100);
        }
    }

    function getProofOfStakeReward(address _address) public view returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge == 0) return 0;

        uint interest = 0; // After 10 years no PoS
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 900% when we select the stakeMaxAge (30 days) as the compounding period.
            interest = (2573 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) <= 10){
            // 2nd to 10th year effective annual interest rate is 10%
            interest = (97 * baseIntCalc).div(100);
        }

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

    function ownerBurnToken(uint _value) onlyOwner public {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        totalSupply = totalSupply.sub(_value);

        emit Burn(msg.sender, _value);
    }

    /* Batch token transfer. Used by contract creator to distribute initial tokens to holders */
    function batchTransfer(address[] _recipients, uint[] _values) onlyOwner public returns (bool) {
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