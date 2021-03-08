/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity ^0.4.19;

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

contract Ownable {
    address public owner;
    function Ownable() public {owner = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner);_;}
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0)); owner = newOwner;}
}

contract Destructible is Ownable {}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) private constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) private returns (bool);
    function approve(address spender, uint256 value) private returns (bool);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    
    function mint() public returns (bool);
    function coinAge() public constant returns (uint256);
    function annualInterest() internal constant returns (uint256);
    
    event Mint(address indexed _address, uint _reward);
}

///------------------------------------------------------------------------------
///Contructor
///------------------------------------------------------------------------------

contract EtherZero is ERC20, PoSTokenStandard,Ownable {
    using SafeMath for uint256;
    
    string public name = "EtherZero";
    string public symbol = "ETHERZ";
    uint public decimals = 18;

    uint public chainStartTime; //Chain start time
    uint public chainStartBlockNumber; //Chain start block number
    uint public stakeStartTime; //Stake start time
    uint public stakeMinAge = 1 days; //Minimum age for coin age : 1 Day
    uint public stakeMaxAge = 30 days; //Stake age of full weight : 30 Days
    uint public defaultRate = 10**17; //Default 10% annual rate

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;
    uint public presaleSupply = 3000000*10**18;

    struct transferInStruct{
        uint128 amount;
        uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    ///@dev Fix for the ERC20 short address attack.
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
    
    modifier onlyMinter() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    function EtherZero() public {
        maxTotalSupply = 50000000*10**18;
        totalInitialSupply = 2000000*10**18;
        
        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

///------------------------------------------------------------------------------
///ERC20 Function
///------------------------------------------------------------------------------

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

    function transferFrom(address _from, address _to, uint256 _value) private onlyPayloadSize(3 * 32) returns (bool) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

        //Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        //require (_value <= _allowance);

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

    function approve(address _spender, uint256 _value) private returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) private constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

///------------------------------------------------------------------------------
///Internal Proof Of Stake Implementation
///------------------------------------------------------------------------------

    function mint() public onlyMinter returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;
        
        uint reward = getReward(msg.sender);
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        
        delete transferIns[msg.sender]; //After stake and earn reward, CoinAge will reset to zero
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        Mint(msg.sender, reward);
        return true;
    }

    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() public view returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() internal constant returns (uint interest) {
        uint _now = now;
        interest = defaultRate;
        if((_now.sub(stakeStartTime)).div(365) == 0) {
            // 1st year effective annual interest rate is 100%
            interest = (1000 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 1) {
            // 2nd year effective annual interest rate is 50%
            interest = (500 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 2) {
            // 3rd year effective annual interest rate is 25%
            interest = (250 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 3) {
            // 4th year effective annual interest rate is 12.5%
            interest = (125 * defaultRate).div(100);
        }
    }

    function getReward(address _address) internal view returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;

        uint interest = defaultRate;

        if((_now.sub(stakeStartTime)).div(365) == 0) {
            // 1st year effective annual interest rate is 100%
            interest = (1000 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 1) {
            // 2nd year effective annual interest rate is 50%
            interest = (500 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 2) {
            // 3rd year effective annual interest rate is 25%
            interest = (250 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 3) {
            // 4th year effective annual interest rate is 12.5%
            interest = (125 * defaultRate).div(100);
        }

        return (_coinAge * interest).div(365 * (10 ** decimals));
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
    
///------------------------------------------------------------------------------
///Change Maximum Supply, Burn and Add Supply
///------------------------------------------------------------------------------

    event burn(address indexed burner, uint256 value);
    event ChangeMaxTotalSupply(uint256 value);
    
    function burnSupply(uint _value) public onlyOwner {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        burn(msg.sender, _value);
    }
    
    function addSupply(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        require(totalSupply < maxTotalSupply);
        balances[account] = balances[account].add(amount);
        totalSupply = balances[account].add(amount);
        transferIns[account]; transferIns[account].length = 1;
        Transfer(address(0), account, amount);
    }
    
    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply; ChangeMaxTotalSupply(maxTotalSupply);
    }
    
    function setStakeStartTime(uint timestamp) public onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }
    
///------------------------------------------------------------------------------
///Presale
///------------------------------------------------------------------------------

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ChangeRate(uint256 _value);
    event ChangePresaleSupply(uint256 _value);
    
    bool public closed;
    
    uint public rate = 1000;
    uint public startDate = now;
    uint public constant ETHMin = 0.1 ether; //Minimum purchase
    uint public constant ETHMax = 50 ether; //Maximum purchase

    function () public payable {
        uint amount; owner.transfer(msg.value);
        amount = msg.value * rate;
        balances[msg.sender] += amount;
        totalSupply = totalInitialSupply + balances[msg.sender];
        presaleSupply = presaleSupply - balances[msg.sender];
        transferIns[msg.sender]; transferIns[msg.sender].length = 1;
        
        require((now >= startDate) && (startDate > 0));
        require(!closed);
        require(msg.value >= ETHMin && msg.value <= ETHMax);
        require(amount <= presaleSupply);
        
        Transfer(address(0), msg.sender, amount);
    }
    
    function closeSale() public onlyOwner {
        require(!closed); closed = true;
    }
    
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate; ChangeRate(rate);
    }

    function changePresaleSupply(uint256 _presaleSupply) public onlyOwner {
        presaleSupply = _presaleSupply; ChangePresaleSupply(presaleSupply);
    }
}