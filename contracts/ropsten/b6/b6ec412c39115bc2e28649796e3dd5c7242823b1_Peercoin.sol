/**
 *Submitted for verification at Etherscan.io on 2021-02-19
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
    function transfer(address to, uint256 value) public returns (bool success);
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
    function coinAge(address staker) public view returns (uint256);
    function annualInterest() public view returns (uint256);
    event Mint(address indexed from, address indexed _address, uint _reward);
}

contract ContractReceiver {
    function tokenFallback(address from, uint value, bytes data) public;
}

//------------------------------------------------------------------------------
//Contructor
//------------------------------------------------------------------------------

contract Peercoin is ERC20, PoSTokenStandard, Ownable {
    using SafeMath for uint256;

    string public name = "Peercoin";
    string public symbol = "PEER";
    uint public decimals = 18;

    uint public totalSupply;
    uint public MaxSupply;
    uint public TotalInitialSupply;

    function Peercoin () public {
        MaxSupply = 100000000e18;
        TotalInitialSupply = 4000000e18;
        chainStartTime = now;
        stakeStartTime = now + 5 days;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = TotalInitialSupply;
        totalSupply = TotalInitialSupply;
    }

//------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------
    
    event ChangePrice(uint256 value);
    
    bool public closed;
    
    uint public price = 100;
    uint public startDate = now;
    uint public constant EthMin = 0.005 ether;
    uint public constant EthMax = 50 ether;
    uint public constant PresaleSupply = 6000000e18;

    function () public payable {
        uint tokens;
        owner.transfer(msg.value);
        tokens = msg.value * price;
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
    
    function changePrice(uint256 _price) public onlyOwner {
        price = _price;
        ChangePrice(price);
    }

//------------------------------------------------------------------------------
//Proof Of Stake Function
//------------------------------------------------------------------------------

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed from, address indexed _address, uint _reward);
    
    event ChangeYearOneInterest(uint256 value);
    event ChangeYearTwoInterest(uint256 value);
    event ChangeYearThreeInterest(uint256 value);
    event ChangeOffsetInterest(uint256 value);
    
    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = now; // minimum age for coin age: 10 Days
    uint public stakeMaxAge = 90 days; // stake age of full weight: 90 Days
    
    uint public maxMintProofOfStake = 10**17; // default 10% annual interest
    uint public yearOneInterest = 1000**18;
    uint public yearTwoInterest = 500**18;
    uint public yearThreeInterest = 250**18;
    uint public offsetInterest = 10**18;
    
    modifier canPoSMint() {require(totalSupply <= MaxSupply);_;}
    struct transferInStruct{uint128 amount; uint64 time;}

    function mint() public canPoSMint returns (bool) {
        require(totalSupply <= MaxSupply);
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;
        uint reward = getProofOfStakeReward(msg.sender);
        if(reward <= 0) return false;
        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        Mint(address(0), msg.sender, reward);
        return true;
    }
    
    function transfer(address to, uint256 value) public canPoSMint returns (bool success) {
        if(msg.sender == to) return mint();
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        return true;
    }
    
    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge(address staker) public view returns (uint256 myCoinAge) {
        return getCoinAge(staker, now);
    }

    function annualInterest() public view returns (uint interest) {
        uint _now = now;
        interest = maxMintProofOfStake;
        if((_now.sub(stakeStartTime)).div(365) == 0) {
            interest = (yearOneInterest * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 1){
            interest = (yearTwoInterest * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 2){
            interest = (yearThreeInterest * maxMintProofOfStake).div(100);
        }
    }

    function getProofOfStakeReward(address _address) internal view returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        if(_coinAge <= 0) return 0;
        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        uint interest = maxMintProofOfStake;
        // Due to the high interest rate for the first three years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(365) == 0) {
            // 1st year effective annual interest rate is 100% when we select the stakeMaxAge (90 days) as the compounding period.
            interest = (yearOneInterest * maxMintProofOfStake).div(100);
            //example : 100 token * 90 days of coinage = 9,000
            //9,000 * interest (1000e18 (1000) of yearOneInterest * 10e17 (0.1) of maxMintProofOfStake) / 100 = 9,000
            //9,000 / (365 * 10e18 of offsetInterest) = 2.645 (reward)
            //100 token + 2.645 = 102.645 tokens
        } else if((_now.sub(stakeStartTime)).div(365) == 1){
            // 2nd year effective annual interest rate is 50%
            interest = (yearTwoInterest * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 2){
            // 3rd year effective annual interest rate is 25%
            interest = (yearThreeInterest * maxMintProofOfStake).div(100);
        }
        return (_coinAge * interest).div(365 * offsetInterest);
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
    
    function changeYearOneInterest(uint _yearOneInterest) public onlyOwner{
        yearOneInterest = _yearOneInterest; ChangeYearOneInterest(yearOneInterest);
    }
    
    function changeYearTwoInterest(uint _yearTwoInterest) public onlyOwner{
        yearTwoInterest = _yearTwoInterest; ChangeYearTwoInterest(yearTwoInterest);
    }
    
    function changeYearThreeInterest(uint _yearThreeInterest) public onlyOwner{
        yearThreeInterest = _yearThreeInterest; ChangeYearThreeInterest(yearThreeInterest);
    }

    function changeOffsetInterest(uint _offsetInterest) public onlyOwner{
        offsetInterest = _offsetInterest; ChangeOffsetInterest(offsetInterest);
    }
    
//------------------------------------------------------------------------------
//Increasing and Decreasing Max Supply
//------------------------------------------------------------------------------
    
    event ChangeMaxSupply(uint256 value);
    
    function mintSupply(address account, uint256 amount) public onlyOwner {
        require(totalSupply <= MaxSupply);
        require(account != address(0));
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        Transfer(address(0), account, totalSupply);
    }
    
    function changeMaxSupply(uint256 _MaxSupply) public onlyOwner {
        MaxSupply = _MaxSupply; ChangeMaxSupply(MaxSupply);
    }
    
    function burn(uint value) public onlyOwner {
        require(value > 0);
        balances[msg.sender] = balances[msg.sender].sub(value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        totalSupply = totalSupply.sub(value);
        TotalInitialSupply = TotalInitialSupply.sub(value);
        MaxSupply = MaxSupply.sub(value);
        Burn(msg.sender, value);
    }

    function transferFrom(address from, address to, uint256 value) public canPoSMint returns (bool success) {
        require(to != address(0));
        var _allowance = allowed[from][msg.sender];
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
    
    function approve(address spender, uint256 value) public returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
}