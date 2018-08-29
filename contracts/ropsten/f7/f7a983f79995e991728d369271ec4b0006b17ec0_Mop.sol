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
        owner = 0x3c390e7f986273df9623d2B27Ae8606F10766B41;
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


contract Mop is ERC20,PoSTokenStandard,Ownable {
    using SafeMath for uint256;

    string public name = "Mop";
    string public symbol = "MOP";
    uint public decimals = 8;

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
    address GamificationReserve = 0x809A528dfAfF67c696Ed3C91702858f0B19B2F59;
    address AirdropOne = 0xF4CB49142d440239E93728CD96A6Ff8B9755F571;
    address AirdropTwo = 0xa528e691663fE230d6860F087034E7066877Ee0b;
    address PrivateFunding = 0x76c9E4abD8acEA2a0aC15Ea3a1D773e6BEe2eb2e;
    address MarketingAllocation = 0x0Fe858C5FFB6dAD08aa3C16de47AD7B18764BA35;
    address BountyPayments = 0x40E5Ef8277167578aa1798BDb54FBc1d9b060FC9;
    address PallyNetworkFoundation = 0x89B24D393E25926B6Bde764Fc0481A840Faa51F5;
    address TeamAllocation = 0xe5cf1d41a4e7f603941066cB02539b804c6AE53c;
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
        
        maxTotalSupply = 999999999 * 10 ** uint256(decimals); // 999.999.999m maximum supply
        totalInitialSupply = 666666666 * 10 ** uint256(decimals); // 666.666.666m initial supply
        totalSupply = totalInitialSupply;

        chainStartTime = now; //when contract is deployed
        stakeStartTime = now;
        
        balances[GamificationReserve] = 333333333* 10 ** uint256(decimals);//333m        
        transferIns[GamificationReserve].push(transferInStruct(uint128(balances[GamificationReserve]),_now));
        balances[AirdropOne] = 66666666* 10 ** uint256(decimals); //66m
        transferIns[AirdropOne].push(transferInStruct(uint128(balances[AirdropOne]),_now));
balances[AirdropTwo] = 33333333* 10 ** uint256(decimals); //33m
        transferIns[AirdropTwo].push(transferInStruct(uint128(balances[AirdropTwo]),_now));
        balances[PrivateFunding] =  93333336* 10 ** uint256(decimals);//93m
        transferIns[PrivateFunding].push(transferInStruct(uint128(balances[PrivateFunding]),_now));

        balances[MarketingAllocation] =  33333333* 10 ** uint256(decimals);//33m
        transferIns[MarketingAllocation].push(transferInStruct(uint128(balances[MarketingAllocation]),_now));

        balances[BountyPayments] =  9999999* 10 ** uint256(decimals);//9m
        transferIns[BountyPayments].push(transferInStruct(uint128(balances[BountyPayments]),_now));

        balances[PallyNetworkFoundation] =  33333333* 10 ** uint256(decimals);//33m
        transferIns[PallyNetworkFoundation].push(transferInStruct(uint128(balances[PallyNetworkFoundation]),_now));

        balances[TeamAllocation] =  63333333* 10 ** uint256(decimals);//63m
        transferIns[TeamAllocation].push(transferInStruct(uint128(balances[TeamAllocation]),_now));

        //initial logs
        emit Transfer(address(0), GamificationReserve, balances[GamificationReserve]);
        emit Transfer(address(0), AirdropOne, balances[AirdropOne]);
        emit Transfer(address(0), AirdropTwo, balances[AirdropTwo]);
        emit Transfer(address(0), PrivateFunding, balances[PrivateFunding]);
        emit Transfer(address(0), MarketingAllocation, balances[MarketingAllocation]); 
        emit Transfer(address(0), BountyPayments, balances[BountyPayments]);
        emit Transfer(address(0), PallyNetworkFoundation, balances[PallyNetworkFoundation]);
        emit Transfer(address(0), TeamAllocation, balances[TeamAllocation]);
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
        interest = 0; // After 9 years no PoS interest 
        // Due to the monthly  interests, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 10% when we select the stakeMaxAge (30 days) as the compounding period.
            interest = (97 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) <= 10){
            // 2nd to 8th year effective annual interest rate is 10%
            interest = (97 * baseIntCalc).div(100);
        }
    }

    function getProofOfStakeReward(address _address) public view returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge == 0) return 0;

        uint interest = 0; // After 9 years no PoS interest
        // Due to the monthly interests, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 10% when we select the stakeMaxAge (30 days) as the compounding period.
            interest = (97 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) <= 10){
            // 2nd to 8th year effective annual interest rate is 10%
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