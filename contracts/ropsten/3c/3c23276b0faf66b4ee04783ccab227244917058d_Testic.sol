/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

pragma solidity ^0.4.19;

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
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address tokenOwner) public constant returns (uint256 balances);
    function transfer(address to, uint value, bytes data) internal returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

contract ERC20 is ERC20Basic {
    function transferFrom(address from, address to, uint256 value) internal returns (bool);
    function approve(address spender, uint256 value) internal returns (bool);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}

contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function transferToAddress(address to, uint value, bytes data) internal returns (bool success);
    function transferToContract(address to, uint value, bytes data) internal returns (bool success);
    function mint() internal returns (bool);
    function mine() internal returns (bool);
    function coinAge(address staker) public view returns (uint256);
    function annualCompounding() public view returns (uint256);
    event Mint(address indexed _address, uint reward);
}

contract ContractReceiver {
    function tokenFallback(address from, uint value, bytes data) public;
}

//------------------------------------------------------------------------------
//Contructor
//------------------------------------------------------------------------------

contract Testic is ERC20, PoSTokenStandard, Ownable {
    using SafeMath for uint256;

    string public name = "Testic";
    string public symbol = "TESTIC";
    uint public decimals = 18;

    uint public totalSupply;
    uint public MaximumSupply;
    uint public TotalInitialSupply;

    function Testic () public {
        MaximumSupply = 1000000e18;
        TotalInitialSupply = 40000e18;
        chainStartTime = now;
        stakeStartTime = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = TotalInitialSupply;
        totalSupply = TotalInitialSupply;
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
    uint public constant PresaleSupply = 60000e18;

    function () public payable {
        uint tokens;
        owner.transfer(msg.value);
        tokens = msg.value * rate;
        balances[msg.sender] += tokens;
        totalSupply = TotalInitialSupply + balances[msg.sender];
        require(now >= startDate || (msg.sender == owner));
        require(!closed);
        require(msg.value >= EthMin);
        require(msg.value <= EthMax);
        require(tokens <= PresaleSupply);
        Transfer(address(0), msg.sender, tokens);
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate;
        ChangeRate(rate);
    }

//------------------------------------------------------------------------------
//Proof Of Stake Function
//------------------------------------------------------------------------------

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;
    
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
    event Burn(address indexed burner, uint256 value);
    event ChangeStakeInterest(uint256 value);
    
    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 1 days; // minimum age for coin age: 10 Days
    uint public stakeMaxAge = 30 days; // stake age of full weight: 30 Days

    uint public MaxMintProofOfStake = 10e17; // default 10% annual interest
    uint public StakeInterest = 10e18;
    
    modifier PoSMint(){require(totalSupply <= MaximumSupply);_;}
    
    struct transferInStruct{uint128 amount;uint64 time;}
    
    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    //retrieve the size of the code on target address, this needs assembly
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length; assembly {length := extcodesize(_addr)} return (length > 0);
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
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory){
        require(isContract(target));
        return functionDelegateCall(target, data);
    }
    
    // Calling Function when a user or another contract wants to transfer funds
    function transfer(address to, uint value, bytes data) internal returns (bool success) {
        if(isContract(to)){return transferToContract(to, value, data);}
        else{return transferToAddress(to, value, data);}
    }
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    // Overrides the base transfer function of the standard ERC20 token
    // Added due to backwards compatibility reasons
    function transfer(address to, uint value) private returns (bool success) {
        bytes memory empty;
        if(isContract(to)) {return transferToContract(to, value, empty);}
        else {return transferToAddress(to, value, empty);}
    }
    //Calling function when transaction target is an address
    function transferToAddress(address to, uint value, bytes data) internal returns (bool success) {
        if(msg.sender == to) return mint();
        if(msg.sender == to) return mine();
        if(balanceOf(msg.sender) < value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(value);
        balances[to] = balanceOf(to).add(value);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        Transfer(msg.sender, to, value, data);
        return true;
    }
    //Calling function when transaction target is a contract
    function transferToContract(address to, uint value, bytes data) internal returns (bool success) {
        if(msg.sender == to) return mint();
        if(msg.sender == to) return mine();
        if (balanceOf(msg.sender) < value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(value);
        balances[to] = balanceOf(to).add(value);
        ContractReceiver reciever = ContractReceiver(to);
        reciever.tokenFallback(msg.sender, value, data);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        Transfer(msg.sender, to, value, data);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) internal returns (bool) {
        require(to != address(0));
        var _allowance = allowed[from][msg.sender];
        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = _allowance.sub(value);
        Transfer(from, to, value);
        if(transferIns[from].length > 0) delete transferIns[from];
        uint64 _now = uint64(now);
        transferIns[from].push(transferInStruct(uint128(balances[from]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        return true;
    }
    
    function approve(address spender, uint256 value) internal returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function mint() internal PoSMint returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;
        uint reward = getProofOfStakeReward(msg.sender);
        if(reward <= 0) return false;
        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        Mint(msg.sender, reward);
        return true;
    }
    
    function mine() internal PoSMint returns (bool) {
        require(totalSupply <= MaximumSupply);
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;
        uint reward = getProofOfStakeReward(msg.sender);
        if(reward <= 0) return false;
        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        Transfer(address(0), msg.sender, reward);
        return true;
    }
    
    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge(address staker) public view returns (uint256 myCoinAge) {
        return getCoinAge(staker, now);
    }

    function annualCompounding() public view returns (uint compounding) {
        uint _now = now;
        compounding = MaxMintProofOfStake;
        if((_now.sub(stakeStartTime)).div(365) == 0) {
            compounding = (1000 * MaxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 1){
            compounding = (500 * MaxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 2){
            compounding = (250 * MaxMintProofOfStake).div(100);
        }
    }

    function getProofOfStakeReward(address _address) internal view returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        if(_coinAge <= 0) return 0;
        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        uint compounding = MaxMintProofOfStake;
        // Due to the high interest rate for the first three years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(365) == 0) {
            // 1st year effective annual interest rate is 100% when we select the stakeMaxAge (90 days) as the compounding period.
            compounding = (1000 * MaxMintProofOfStake).div(100);
            //example : 100 token * 90 days of coinage = 9,000
            //          9,000 * interest (1000 * 10e17 (0.1) of MaxMintProofOfStake) / 100 = 9,000
            //          9,000 / (365 * 10e18 of StakeInterest) = 2.645 (reward)
            //          100 token + 2.645 = 102.645 tokens
        } else if((_now.sub(stakeStartTime)).div(365) == 1){
            // 2nd year effective annual interest rate is 50%
            compounding = (500 * MaxMintProofOfStake).div(100);
            //example : 100 token * 90 days of coinage = 9,000
            //          9,000 * interest (500 * 10e17 (0.1) of MaxMintProofOfStake) / 100 = 4,500
            //          4,500 / (365 * 10e18 of StakeInterest) = 1.232 (reward)
            //          100 token + 1.232 = 101.232 tokens
        } else if((_now.sub(stakeStartTime)).div(365) == 2){
            // 3rd year effective annual interest rate is 25%
            compounding = (250 * MaxMintProofOfStake).div(100);
            //example : 100 token * 90 days of coinage = 9,000
            //          9,000 * interest (250 * 10e17 (0.1) of MaxMintProofOfStake) / 100 = 2,250
            //          2,250 / (365 * 10e18 of StakeInterest) = 0.616 (reward)
            //          100 token + 0.616 = 100.616 tokens
        }
        // 4th - 10th effective annual interest rate is 10%
        return (_coinAge * compounding).div(365 * StakeInterest);
    }

    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(stakeMinAge)) continue;
            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(nCoinSeconds > stakeMaxAge) nCoinSeconds = stakeMaxAge;
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount)*nCoinSeconds.div(1 days));
        }
    }

    function changeStakeInterest(uint _StakeInterest) public onlyOwner{
        StakeInterest = _StakeInterest; ChangeStakeInterest(StakeInterest);
    }

//------------------------------------------------------------------------------
//Increasing and Decreasing Max Supply
//------------------------------------------------------------------------------
    
    event ChangeMaximumSupply(uint256 value);
    
    function mintSupply(address account, uint256 amount) public onlyOwner {
        require(totalSupply <= MaximumSupply);
        require(account != address(0));
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        Transfer(address(0), account, totalSupply);
    }
    
    function changeMaximumSupply(uint256 _MaximumSupply) public onlyOwner {
        MaximumSupply = _MaximumSupply; ChangeMaximumSupply(MaximumSupply);
    }
    
    function burn(uint value) public onlyOwner {
        require(value > 0);
        balances[msg.sender] = balances[msg.sender].sub(value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        totalSupply = totalSupply.sub(value);
        TotalInitialSupply = TotalInitialSupply.sub(value);
        MaximumSupply = MaximumSupply.sub(value);
        Burn(msg.sender, value);
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
}