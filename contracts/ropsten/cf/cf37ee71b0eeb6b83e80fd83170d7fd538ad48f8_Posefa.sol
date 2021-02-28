/**
 *Submitted for verification at Etherscan.io on 2021-02-28
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
}

library ExtendedMath {
    //return the smaller of the two inputs (a or b)
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

contract Destructible is Ownable {
    function destroy() public onlyOwner {selfdestruct(address(this));}
}

contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function name() public constant returns  (string _name);
    function symbol() public constant returns  (string _symbol);
    function decimals() public constant returns  (uint8 _decimals);
    function totalSupply() public constant returns  (uint256 _supply);
    function transfer(address to, uint value) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 /**
 * @title PoSTokenStandard
 * @dev the interface of PoSTokenStandard
 */
 
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint public ageCoin;
    function publicMint() public returns (bool);
    function annualPercentage() internal view returns(uint256);
    function coinAge(address _tokenHolder) public view returns (uint256);
    event PublicMint(address indexed _address, uint _reward);
}

//------------------------------------------------------------------------------
//Contructor
//------------------------------------------------------------------------------

contract Posefa is ERC20, PoSTokenStandard, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string public name = "Posefa";
    string public symbol = "POSEFA";
    uint8 public decimals = 18;

    uint public chainStartTime; //Chain Start Time
    uint public chainStartBlockNumber; //Chain start block number
    uint public stakeStartTime; //Stake start time
    uint public ageCoin = 1; //Default minimum time age for coin to stake and earn a reward
    uint public rewardPercentage = 9125; //Default percentage rate 91.25% (see line : 206 & 220)
    uint public constant rewardInterval = 365 days;

    uint public totalSupply;
    uint public totalInitialSupply;
    uint public MaxTotalSupply = 50000000e18;
    uint public PresaleSupply = 3000000e18; //Only 3% from Maximum Total Supply

    struct transferInStruct{uint128 amount;uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    modifier canMint() {
        require(totalSupply < MaxTotalSupply);
        _;
    }
    
    function Posefa () public {
        totalInitialSupply = 2000000e18; //Only 2% from Maximum Total Supply
        chainStartTime = now;
        stakeStartTime = now + 5 days;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

//------------------------------------------------------------------------------
//Proof Of Stake Implementation
//------------------------------------------------------------------------------
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if(msg.sender == _to) return publicMint();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }
    //Public minting function for token holder
    //To call this function, token holder just send transaction
    //to their own wallet address with any or 0 amount of token
    function publicMint() public canMint returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;
        uint reward = getMintingReward(msg.sender); reward = MaxTotalSupply;
        if(reward <= 0) return false;
        
        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit PublicMint(msg.sender, reward);
        emit Transfer (address(0), msg.sender, reward);
        return true;
    }

    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function annualPercentage() internal view returns(uint percentage) {
        uint _now = now;
        percentage = rewardPercentage;
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

    function getMintingReward(address _address) public view returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;
        uint percentage = rewardPercentage;
        uint stakedAmount = balances[msg.sender];
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
        return stakedAmount.mul(percentage).div(rewardInterval).div(1e4);
    }

    function coinAge(address _tokenHolder) public view returns (uint256) {
        return getCoinAge(_tokenHolder, now);
    }
    
    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(ageCoin)) continue;
            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }
    
    event ChangeRewardPercentage(uint256 value);
    //Dev has ability to change reward percentage
    function changeRewardPercentage(uint256 _rewardPercentage) public onlyOwner {
        rewardPercentage = _rewardPercentage;
        emit ChangeRewardPercentage(rewardPercentage);
    }
    
    event SetAgeCoin(uint256 value);
    //Dev has ability to change Coin Age
    function setAgeCoin(uint256 _ageCoin) public onlyOwner {
        ageCoin = _ageCoin;
        emit SetAgeCoin(ageCoin);
    }

//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

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

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


//------------------------------------------------------------------------------
//Change Max Supply, Minting and Burn Supply
//------------------------------------------------------------------------------

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
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
    
//------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ChangeRate(uint256 _value);
    
    bool public closed;
    
    uint public rate = 1000; //1 ETH = 1000 ETHC
    uint public startDate = now;
    uint public constant EthMin = 0.01 ether; //Minimum purchase
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