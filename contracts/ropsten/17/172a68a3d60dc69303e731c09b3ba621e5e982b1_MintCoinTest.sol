/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

pragma solidity ^0.4.21;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b; assert(a == 0 || c / a == b); return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b; return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a); return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; assert(c >= a); return c;
    }
}

contract Ownable {
    address public owner;
    function Ownable() public {owner = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner);_;}
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0)); owner = newOwner;}
}


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge() public view returns (uint256);
    function annualRewardEra() public constant returns (uint256);
    event Mint(address indexed _address, uint _reward);
}

//------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------

contract MintCoinTest is ERC20, PoSTokenStandard, Ownable {
    using SafeMath for uint256;
    
    string public name = "MintCoinTest";
    string public symbol = "MTCT";
    uint public decimals = 18;

    uint public chainStartTime;
    uint public chainStartBlockNumber;
    uint public stakeStartTime;
    uint public stakeMinAge = 1 days;
    uint public stakeMaxAge = 5 days;
    
    uint public maxMintProofOfStake = 10**7;

    uint public totalSupply;
    uint public MaxTotalSupply;
    uint public totalInitialSupply;

    struct transferInStruct{uint128 amount; uint64 time; }

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;
    
    /**
    * @dev Fix for the ERC20 short address attack.
    */
    
    modifier onlyPayloadSize(uint size) {require(msg.data.length >= size + 4);_;}
    modifier canPoSMint() {require(totalSupply < MaxTotalSupply);_;}
    event Burn(address indexed burner, uint256 value);

    function MintCoinTest() public {
        
        MaxTotalSupply = 50000000e18;
        totalInitialSupply = 2000000e18;
        chainStartTime = now;
        stakeStartTime;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) public  onlyPayloadSize(2 * 32) returns (bool) {
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

    function transferFrom(address _from, address _to, uint256 _value) public  onlyPayloadSize(3 * 32) returns (bool) {
        require(_to != address(0));
        var _allowance = allowed[_from][msg.sender];
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

    function allowance(address _owner, address _spender) public  constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
//------------------------------------------------------------------------------
//Proof of Stake Implementation
//------------------------------------------------------------------------------

    function mint() public canPoSMint returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;
        uint reward = getMintingReward(msg.sender);
        if(reward <= 0) return false;
        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        emit Mint(msg.sender, reward);
        emit Transfer(address(0), msg.sender, reward);
        return true;
    }

    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() public view returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualRewardEra() public constant returns (uint rewardEra) {
        uint _now = now;
        rewardEra = maxMintProofOfStake;
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods)
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            rewardEra = (1000 * maxMintProofOfStake).div(100); // 100%
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1) {
            rewardEra = (500 * maxMintProofOfStake).div(100); // 50%
        } else if((_now.sub(stakeStartTime)).div(1 years) == 2){
            rewardEra = (250 * maxMintProofOfStake).div(100); // 25%
        } else if((_now.sub(stakeStartTime)).div(1 years) == 3){
            rewardEra = (125 * maxMintProofOfStake).div(100); // 12,5%
        } else if((_now.sub(stakeStartTime)).div(1 years) == 4){
            rewardEra = (100 * maxMintProofOfStake).div(100); // 10%
        }
    }

    function getMintingReward(address _address) public view returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );
        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;
        uint rewardEra = maxMintProofOfStake;
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual reward era is 100% when we select the stakeMaxAge (30 days) as the compounding period.
            rewardEra = (1000 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1) {
            // 2nd year effective annual reward era rate is 50%
            rewardEra = (500 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 2){
            // 3rd year effective annual reward era rate is 25%
            rewardEra = (250 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 3){
            // 4th year effective annual reward era is 12,5%
            rewardEra = (125 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 4){
            // 5th year effective annual reward era is 10%
            rewardEra = (100 * maxMintProofOfStake).div(100);
        }
        // 6th - 15th year effective annual reward era is 5%
        return (_coinAge * rewardEra).div(365 * (5**decimals)); // 5%
    }

    function getCoinAge(address _address, uint _now) public view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;
            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }
    
//------------------------------------------------------------------------------
//Set Stake Time and Change Max Supply
//------------------------------------------------------------------------------

    event SetStakeStartTime(uint timestamp);

    function ownerSetStakeStartTime(uint timestamp) public onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;  //Unix timestamp can be used.
    }
    
    event ChangeMaxTotalSupply(uint256 value);
    
    function changeMaxTotalSupply(uint256 _MaxTotalSupply) public onlyOwner {
        MaxTotalSupply = _MaxTotalSupply;
        emit ChangeMaxTotalSupply(MaxTotalSupply);
    }
    
    function BurnToken(uint _value) public onlyOwner {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        MaxTotalSupply = MaxTotalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
    
//------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 value);
    event ChangeRate(uint256 value);
    
    bool public closed;
    
    uint public rate = 100;
    uint public startDate = now;
    uint public constant EthMin = 0.005 ether;
    uint public constant EthMax = 50 ether;
    uint public constant PresaleSupply = 3000000e18;

    function () public payable {
        uint amount;
        owner.transfer(msg.value);
        amount = msg.value * rate;
        balances[msg.sender] += amount;
        totalSupply = totalInitialSupply + balances[msg.sender];
        require(now >= startDate || (msg.sender == owner));
        require(!closed);
        require(msg.value >= EthMin);
        require(msg.value <= EthMax);
        require(amount <= PresaleSupply);
        emit Transfer(address(0), msg.sender, amount);
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate;
        emit ChangeRate(rate);
    }

}