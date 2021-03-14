/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
     
    function Ownable() {
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
     
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Destructible is Ownable {}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) internal constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title ProofOfStakeToken
 * @dev the interface of ProofOfStakeToken
 */
 
contract ProofOfStakeToken {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() returns (bool);
    function coinAge() internal constant returns (uint256);
    function annualInterest() internal constant returns (uint256);
    event Mint(address indexed _address, uint _reward);
}

//------------------------------------------------------------------------------
//Contructor
//------------------------------------------------------------------------------

contract StakeOnev2 is ERC20, ProofOfStakeToken, Ownable {
    using SafeMath for uint256;

    string public name = "StakeOnev2";
    string public symbol = "SONE2";
    uint public decimals = 18;

    uint public chainStartTime; //Chain start time
    uint public chainStartBlockNumber; //Chain start block number
    uint public stakeStartTime; //Stake start time
    uint public stakeMinAge = 1 days;
    uint public stakeMaxAge = 30 days;
    uint public defaultInterest = 10**17; //Default 10% annual interest

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
    
    address public tokenContractAddress = address(this);

    event Burn(address indexed burner, uint256 value);
    event ChangeMaxTotalSupply(uint256 value);
    event ChangeDefaultInterest(uint256 value);

    /**
     * @dev Fix for the ERC20 short address attack.
     */
     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier PoSMinter() {
        require(totalSupply <= maxTotalSupply);
        _;
    }

    function StakeOnev2 () {
        maxTotalSupply = 500000*10**18;
        totalInitialSupply = 50000*10**18;
        
        stakeStartTime = now;
        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
        if(msg.sender == _to) return mint();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool) {
        require(_to != address(0));
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        if(transferIns[_from].length > 0) delete transferIns[_from];
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

    function allowance(address _owner, address _spender) internal constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//------------------------------------------------------------------------------
//Internal Proof Of Stake function
//------------------------------------------------------------------------------

    function mint() PoSMinter returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;

        uint reward = getReward(msg.sender);
        assert(reward <= maxTotalSupply);
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        Mint(msg.sender, reward);
        Transfer(address(0), msg.sender, reward);
        ERC20(tokenContractAddress).transfer(msg.sender, reward);
        return true;
    }

    function getBlockNumber() internal returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() internal constant returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() internal constant returns (uint interest) {
        uint _now = now;
        interest = defaultInterest;
        if((_now.sub(stakeStartTime)).div(365 days) == 0) {
            interest = (1000 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 1){
            interest = (500 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 2){
            interest = (250 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 3){
            interest = (125 * defaultInterest).div(100);
        }
    }

    function getReward(address _address) internal returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;

        uint interest = defaultInterest;
        if((_now.sub(stakeStartTime)).div(365 days) == 0) {
            // 1st year effective annual interest rate is 100%
            interest = (1000 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 1){
            // 2nd year effective annual interest rate is 50%
            interest = (500 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 2){
            // 3rd year effective annual interest rate is 25%
            interest = (250 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 3){
            // 4th year effective annual interest rate is 12.5%
            interest = (125 * defaultInterest).div(100);
        }
        // 5th year - end effective annual interest rate is 10%
        return (_coinAge * interest).div(365);
    }

    function getCoinAge(address _address, uint _now) internal returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(stakeMinAge)) continue;
            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(nCoinSeconds > stakeMaxAge) nCoinSeconds = stakeMaxAge;
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    function setStakeStartTime(uint timestamp) public onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

    function burnSupply(uint _value) public onlyOwner {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);

        Burn(msg.sender, _value);
    }

    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        ChangeMaxTotalSupply(maxTotalSupply);
    }
    
    function changeDefaultInterest(uint256 _defaultInterest) public onlyOwner {
        defaultInterest = _defaultInterest;
        ChangeDefaultInterest(defaultInterest);
    }
}