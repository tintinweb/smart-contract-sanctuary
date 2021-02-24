/**
 *Submitted for verification at Etherscan.io on 2021-02-24
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

library ExtendedMath {
    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b; return a;}
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
    function balanceOf(address tokenOwner) public constant returns (uint256);
    function transfer(address to, uint256 value) internal returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) internal constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) internal returns (bool);
    function approve(address spender, uint256 value) internal returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PoSMiningStandard {
    uint256 public MiningStartTime;
    function publicMine() public returns (bool);
    event PublicMining(address indexed from, uint miningreward);
}

//------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------

contract PublicTestNet is ERC20, PoSMiningStandard, Ownable {
    using SafeMath for uint256;
    
    string public name = "PublicTestNet";
    string public symbol = "PTN";
    uint public decimals = 18;

    uint public MiningStartTime;
    uint public MiningRewardEra = 6;

    uint public totalSupply;
    uint public totalInitialSupply;
    uint public MaximumTotalSupply = 50000000e18;
    uint public MiningRewardSupply = 45000000e18;
    uint public constant PresaleSupply = 3000000e18;
    
    address GenesisAddress = 0xEF8938c2296E16d05a301a42F6e6Cb8f85a386c1;
    //Address Contract Owner - Cannot Mining

    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;
    modifier PoSMiner() {require(totalSupply <= MaximumTotalSupply);_;}

    function PublicTestNet() public {
        totalInitialSupply = 2000000e18;
        MiningStartTime = now + 5 days;
        balances[msg.sender] = totalInitialSupply;
        balances[address(this)] = MiningRewardSupply;
        totalSupply = totalInitialSupply;
    }

//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) internal returns (bool) {
        if(msg.sender == _to) return publicMine();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_from != address(this));
        if(msg.sender == _to) return publicMine();
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
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
    
//------------------------------------------------------------------------------
//Proof of Stake Implementation
//------------------------------------------------------------------------------

    function publicMine() public PoSMiner returns (bool) {
        require(now >= MiningStartTime);
        require(miningreward == MiningRewardSupply);
        if (msg.sender == GenesisAddress) revert();
        if(balances[msg.sender] <= 0) revert();
        if(miningreward <= 0) return false;
        uint rewardEra = MiningRewardEra;
        uint miningreward = balances[msg.sender].div(365 days/rewardEra);
        totalSupply = totalSupply.add(miningreward);
        balances[msg.sender] = balances[msg.sender].add(miningreward);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        emit PublicMining(msg.sender, miningreward);
        emit Transfer(address(this), msg.sender, miningreward);
        return true;
    }
    
    function mintRewardSupply(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), address(this), MiningRewardSupply);
    }

//------------------------------------------------------------------------------
//Change Max Supply
//------------------------------------------------------------------------------
    
    event ChangeMaximumTotalSupply(uint256 value);
    
    function changeMaximumTotalSupply(uint256 _MaximumTotalSupply) public onlyOwner {
        MaximumTotalSupply = _MaximumTotalSupply;
        emit ChangeMaximumTotalSupply(MaximumTotalSupply);
    }
    
    event ChangeMiningRewardSupply(uint256 value);
    
    function changeMiningRewardSupply(uint256 _MiningRewardSupply) public onlyOwner {
        MiningRewardSupply = _MiningRewardSupply;
        emit ChangeMiningRewardSupply(MiningRewardSupply);
    }
    
    event Burn(address indexed burner, uint256 value);
    
    function BurnToken(uint _value) public onlyOwner {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        MaximumTotalSupply = MaximumTotalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
    
//------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 value);
    event ChangeRate(uint256 value);
    
    bool public closed;
    
    uint public rate = 1000; // 1 ETH = 1000;
    uint public startDate = now;
    uint public constant EthMin = 0.005 ether;
    uint public constant EthMax = 50 ether;

    function () public payable {
        uint amount;
        owner.transfer(msg.value);
        amount = msg.value * rate;
        balances[msg.sender] += amount;
        totalSupply = totalInitialSupply + balances[msg.sender];
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