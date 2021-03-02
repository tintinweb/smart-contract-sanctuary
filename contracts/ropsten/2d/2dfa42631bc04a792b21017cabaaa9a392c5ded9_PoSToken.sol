/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;assert(a == 0 || c / a == b); return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b; return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; assert(c >= a); return c;
    }
}

contract Ownable {
    address public owner;
    function Ownable() public {owner = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner);_;}
    function transferOwnership(address newOwner) public onlyOwner {require(newOwner != address(0));owner = newOwner;}
}

contract Destructible is Ownable {}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) internal returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) internal constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) internal returns (bool);
    function approve(address spender, uint256 value) internal returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PoSTokenStandard {
    uint256 public stakeStartTime;
    function mint() internal returns (bool);
    function annualPercentage() internal returns (uint256);
    event Mint(address indexed _address, uint _reward);
}

//--------------------------------------------------------------------------------------
//Contructor
//--------------------------------------------------------------------------------------

contract PoSToken is ERC20, PoSTokenStandard, Ownable {
    using SafeMath for uint256;

    string public name = "PoSToken";
    string public symbol = "POS";
    uint public decimals = 18;

    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public basePercentage = 9125; //Default percentage rate 91.25%
    uint public constant rewardInterval = 365 days;

    uint public totalSupply;
    uint public totalInitialSupply;
    uint public MaxTotalSupply = 50000000e18;
    uint public PresaleSupply = 3000000e18; //Only 3% from Maximum Total Supply

    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    modifier onlyPayloadSize(uint size) {require(msg.data.length >= size + 4);_;}
    modifier onlyMinter() {require(totalSupply < MaxTotalSupply);_;}

    function PoSToken() public {
        totalInitialSupply = 2000000e18;
        chainStartTime = now;
        stakeStartTime = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

    function transfer(address _to, uint256 _value) internal onlyPayloadSize(2 * 32) returns (bool) {
        if(msg.sender == _to) return mint();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) internal onlyPayloadSize(3 * 32) returns (bool) {
        require(_to != address(0));
        uint256 _allowance = allowed[_from][msg.sender];
        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function approve(address _spender, uint256 _value) internal returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) internal constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//-----------------------------------------------------------------------------------------------------------
//Proof Of Stake Mechanism Implementation
//-----------------------------------------------------------------------------------------------------------

    //There are 2 ways to activate POS mining.
    //Send any amount of tokens back to yourself (same Ethereum address that holds the tokens).
    //Interact with the contract with any Ethereum wallet that is capable of calling smart contract functions.
    
    function mint() internal onlyMinter returns (bool) {
        if(balances[msg.sender] <= 0) return false;

        uint reward = getReward();
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Mint(msg.sender, reward);
        return true;
    }

    function getBlockNumber() internal view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function annualPercentage() internal returns(uint percentage) {
        uint _now = now;
        percentage = basePercentage;
        if((_now.sub(stakeStartTime)) == 0){
            //1st years : 1825%
            percentage = percentage.mul(20);
        } else if((_now.sub(stakeStartTime)) == 1){
            //2nd years percentage : 1460%
            percentage = percentage.mul(16);
        } else if((_now.sub(stakeStartTime)) == 2){
            //3rd years percentage : 1095%
            percentage = percentage.mul(12);
        } else if((_now.sub(stakeStartTime)) == 3){
            //4th years percentage : 730%
            percentage = percentage.mul(8);
        } else if((_now.sub(stakeStartTime)) == 4){
            //5th years percentage : 365%
            percentage = percentage.mul(4);
        } else if((_now.sub(stakeStartTime)) == 5){
            //6th years percentage : 182.5%
            percentage = percentage.mul(2);
        }
    }

    function getReward() internal view returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );
        uint _now = now;
        uint PoSHash = balances[msg.sender];
        uint percentage = basePercentage;
        if((_now.sub(stakeStartTime)) == 0){
            //1st years : 1825%
            percentage = percentage.mul(20);
            //Example : User have 1000 tokens
            //1,000 tokens x 182,500 of percentage / 365 of reward Interval / 10,000
            //50 tokens rewards
            //1,000 + 50 = 1,050 tokens
        } else if((_now.sub(stakeStartTime)) == 1){
            //2nd years percentage : 1460%
            percentage = percentage.mul(16);
        } else if((_now.sub(stakeStartTime)) == 2){
            //3rd years percentage : 1095%
            percentage = percentage.mul(12);
        } else if((_now.sub(stakeStartTime)) == 3){
            //4th years percentage : 730%
            percentage = percentage.mul(8);
        } else if((_now.sub(stakeStartTime)) == 4){
            //5th years percentage : 365%
            percentage = percentage.mul(4);
        } else if((_now.sub(stakeStartTime)) == 5){
            //6th years percentage : 182.5%
            percentage = percentage.mul(2);
        }
        // 7th years - end percentage : 91.25%
        return PoSHash.mul(percentage).div(rewardInterval).div(1e4);
    }

    function ownerSetStakeStartTime(uint timestamp) public onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

//--------------------------------------------------------------------------------------
//Change Max Supply and Burn Supply
//--------------------------------------------------------------------------------------

    event ChangeMaxTotalSupply(uint256 value);
    //Dev has ability to change Maximum Total Supply
    function changeMaxTotalSupply(uint256 _MaxTotalSupply) public onlyOwner {
        MaxTotalSupply = _MaxTotalSupply;
        emit ChangeMaxTotalSupply(MaxTotalSupply);
    }
    
    event ChangeBasePercentage(uint256 value);
    //Dev has ability to change reward percentage
    function changeBasePercentage(uint256 _basePercentage) public onlyOwner {
        basePercentage = _basePercentage;
        emit ChangeBasePercentage(basePercentage);
    }
    //Mint function is a failsafe if internal Public Mint contract doesn't work
    //Dev will mint supply for external stake contract
    function mintSupply(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        balances[account] = balances[account].add(amount);
        totalSupply = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        require(amount > 0);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        totalInitialSupply = totalInitialSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
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