/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity 0.4.21;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b);
    }
}

library ExtendedMath {
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
    }
}

library Address {
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory){
        require(isContract(target));
        return functionCall(target, data);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory){
        require(isContract(target));
        return functionCallWithValue(target, data, value);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory){
        require(isContract(target));
        return functionStaticCall(target, data);
    }
}

contract Ownable {
    address public owner;
    address public newOwner;
    
    modifier onlyOwner() {require(msg.sender == owner);_;}
    
    function Ownable() public {owner = msg.sender;}
    function transferOwnership(address _newOwner) public onlyOwner {newOwner = _newOwner;}
    function acceptOwnership() public {require(msg.sender == newOwner); owner = newOwner;}
}

contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function name() public constant returns  (string _name);
    function symbol() public constant returns  (string _symbol);
    function decimals() public constant returns  (uint8 _decimals);
    function totalSupply() public constant returns  (uint256 _supply);
    function transfer(address to, uint value) internal returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) internal constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) internal returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PoSMiningStandard {
    uint256 public miningStartTime;
    function publicMining() public returns (bool);
    function annualPublicReward() internal view returns(uint256);
    function getMiningReward() internal view returns (uint256);
    event Mint(address indexed owner, address indexed spender, uint256 reward);
}

//--------------------------------------------------------------------------------------
//Contructor
//--------------------------------------------------------------------------------------

contract BlockMiner2 is ERC20, PoSMiningStandard, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string public name = "BlockMiner2";
    string public symbol = "BLOCK2";
    uint8 public decimals = 18;

    uint public chainStartTime; //Chain Start Time
    uint public chainStartBlockNumber; //Chain start block number
    uint public miningStartTime; 
    uint public rewardAnnual = 9125; //Default percentage rate 91.25% (see line : 206 & 220)
    uint internal constant rewardInterval = 365 days;

    uint public totalSupply;
    uint public totalInitialSupply;
    uint public MaxTotalSupply = 50000000e18;
    uint public PresaleSupply = 3000000e18; //Only 3% from Maximum Total Supply

    address ContractOwner = 0xEF8938c2296E16d05a301a42F6e6Cb8f85a386c1;
    
    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;
    
    mapping (address => bool) internal minters;

    modifier onlyMiner() {require(totalSupply <= MaxTotalSupply);_;}
    
    function BlockMinerII () public {
        totalInitialSupply = 2000000e18; //Only 2% from Maximum Total Supply
        chainStartTime = now;
        miningStartTime = now + 24 hours;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    //Dev can set stake start time
    //Mining start time will be set after presale is close
    function SetMiningStartTime(uint timestamp) public onlyOwner {
        require((miningStartTime <= 0) && (timestamp >= chainStartTime));
        miningStartTime = timestamp;
    }

//--------------------------------------------------------------------------------------
//Proof Of Stake standard Implementation
//--------------------------------------------------------------------------------------
    
    function transfer(address _to, uint256 _value) internal returns (bool success) {
        if(msg.sender == _to) return publicMining(); getMiningReward();
        if(balances[msg.sender] <= 0) return false;
        if(msg.sender == ContractOwner) revert();
        balances[_to] = balances[_to].add(_value);
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        emit Transfer(address(0), msg.sender, _value);
        return true;
    }
    
    function publicMining() public onlyMiner returns (bool) {
        require(totalSupply <= MaxTotalSupply);
        require(reward == MaxTotalSupply);
        require(minters[msg.sender]);
        
        if(balances[msg.sender] <= 0) return false;
        if(reward <= 0) return false;
        if(balances[address(this)] <= 0) return false;
        if(msg.sender == ContractOwner) revert();
        
        uint reward = getMiningReward();
        balances[address(this)] = reward;
        
        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        balances[address(this)] = balances[address(this)].sub(reward);
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        
        emit Mint(address(this), msg.sender, reward);
        
        return true;
    }
    
    function Minter() internal {
        minters[msg.sender] = true;
    }

    function getBlockNumber() internal view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function annualPublicReward() internal view returns (uint publicReward) {
        uint _now = now;
        publicReward = rewardAnnual;
        if((_now.sub(miningStartTime)) == 0){
            //1st years : 1825%
            publicReward = publicReward.mul(20);
        } else if((_now.sub(miningStartTime)) == 1){
            //2nd years percentage : 1460%
            publicReward = publicReward.mul(16);
        } else if((_now.sub(miningStartTime)) == 2){
            //3rd years percentage : 1095%
            publicReward = publicReward.mul(12);
        } else if((_now.sub(miningStartTime)) == 3){
            //4th years percentage : 730%
            publicReward = publicReward.mul(8);
        } else if((_now.sub(miningStartTime)) == 4){
            //5th years percentage : 365%
            publicReward = publicReward.mul(4);
        } else if((_now.sub(miningStartTime)) == 5){
            //6th years percentage : 182.5%
            publicReward = publicReward.mul(2);
        }
    }

    function getMiningReward() internal view returns (uint) {
        require((now >= miningStartTime) && (miningStartTime > 0));
        uint _now = now;
        uint publicReward = rewardAnnual;
        uint hashMiner = balances[msg.sender];
        if((_now.sub(miningStartTime)) == 0){
            //1st years : 1825%
            publicReward = publicReward.mul(20);
            //Example : User have 1000 tokens
            //1,000 tokens x 182,500 of percentage / 365 of reward Interval / 10,000
            //50 tokens rewards
            //1,000 + 50 = 1,050 tokens
        } else if((_now.sub(miningStartTime)) == 1){
            //2nd years percentage : 1460%
            publicReward = publicReward.mul(16);
        } else if((_now.sub(miningStartTime)) == 2){
            //3rd years percentage : 1095%
            publicReward = publicReward.mul(12);
        } else if((_now.sub(miningStartTime)) == 3){
            //4th years percentage : 730%
            publicReward = publicReward.mul(8);
        } else if((_now.sub(miningStartTime)) == 4){
            //5th years percentage : 365%
            publicReward = publicReward.mul(4);
        } else if((_now.sub(miningStartTime)) == 5){
            //6th years percentage : 182.5%
            publicReward = publicReward.mul(2);
        }
        // 7th years - end percentage : 91.25%
        return hashMiner.mul(publicReward).div(rewardInterval).div(1e4);
    }
    
    event ChangeRewardAnnual(uint256 value);
    //Dev has ability to change reward percentage
    function changeRewardAnnual(uint256 _rewardAnnual) public onlyOwner {
        rewardAnnual = _rewardAnnual;
        emit ChangeRewardAnnual(rewardAnnual);
    }

//--------------------------------------------------------------------------------------
//ERC20 Function
//--------------------------------------------------------------------------------------

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
    //Function to access name of token
    function name() public constant returns (string _name) {
        return name;
    }
    //Function to access symbol of token
    function symbol() public constant returns (string _symbol) {
        return symbol;
    }
    //Function to access decimals of token
    function decimals() public constant returns (uint8 _decimals) {
        return decimals;
    }
    //Function to access total supply of tokens
    function totalSupply() public constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) internal constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        emit Transfer(_from, _to, _value);
        return true;
    }


//--------------------------------------------------------------------------------------
//Change Max Supply, Minting and Burn Supply
//--------------------------------------------------------------------------------------

    event ChangeMaxTotalSupply(uint256 value);
    //Dev has ability to change Maximum Total Supply
    function changeMaxTotalSupply(uint256 _MaxTotalSupply) public onlyOwner {
        MaxTotalSupply = _MaxTotalSupply;
        emit ChangeMaxTotalSupply(MaxTotalSupply);
    }
    //Mint function is a failsafe if internal Public Mint contract doesn't work
    //Dev will mint supply for external stake contract
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        balances[account] = balances[account].add(amount);
        totalSupply = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    event Burn(address indexed burner, uint256 value);
    
    function BurnToken(uint _value) public onlyOwner {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
    
//--------------------------------------------------------------------------------------
//Presale
//--------------------------------------------------------------------------------------

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ChangeRate(uint256 _value);
    
    bool public closed;
    
    uint public rate = 1000; //1 ETH = 1000 ETHC
    uint public startDate = now;
    uint public constant EthMin = 0.001 ether; //Minimum purchase
    uint public constant EthMax = 50 ether; //Maximum purchase

    function () public payable {
        uint amount;
        owner.transfer(msg.value);
        amount = msg.value * rate;
        balances[msg.sender] += amount;
        totalSupply = totalInitialSupply + balances[msg.sender];
        PresaleSupply = PresaleSupply - balances[msg.sender];
        require((now >= startDate) && (startDate > 0));
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