/**
 *Submitted for verification at Etherscan.io on 2021-02-25
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
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b; return a;}
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 value, address token, bytes data) public;
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
    function transfer(address to, uint256 value) public returns (bool);
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
    function PublicMine() public returns (bool);
    function getMiningReward() internal view returns (uint);
    event PublicMining(address indexed from, address indexed to, uint miningreward);
}

//------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------

contract Minethereum is ERC20, PoSMiningStandard, Ownable {
    using SafeMath for uint256;
    
    string public name = "Minethereum";
    string public symbol = "MTH";
    uint public decimals = 18;

    uint public MiningStartTime;
    uint public MiningRewardEra = 6;

    uint public totalSupply;
    uint public totalInitialSupply;
    uint public MaximumTotalSupply = 50000000e18;
    uint public constant PresaleSupply = 3000000e18;
    uint public MiningRewardSupply;
    
    address GenesisAddress = 0xEF8938c2296E16d05a301a42F6e6Cb8f85a386c1;
    //Address Contract Owner - Cannot Mining

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    modifier PoSMiner() {require(totalSupply <= MaximumTotalSupply);_;}

    function Minethereum() public {
        totalInitialSupply = 2000000e18;
        MiningStartTime = now + 5 days;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
        balances[address(this)] = 45000000e18;
    }

//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length; assembly {length := extcodesize(_addr)} return (length > 0);
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory){
        require(isContract(address(this)));
        return functionCall(target, data);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory){
        require(isContract(address(this)));
        return functionCallWithValue(target, data, value);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory){
        require(isContract(address(this)));
        return functionStaticCall(target, data);
    }
    
    function approveAndCall(address spender, uint value, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, value, this, data);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if(msg.sender == _to) return PublicMine();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_from != address(this));
        allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
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
//Proof of Stake Mining Implementation
//------------------------------------------------------------------------------
    
    function PublicMine() public PoSMiner returns (bool) {
        require(balances[msg.sender] > 0);
        require(miningreward == MiningRewardSupply);
        if(balances[msg.sender] <= 0) return false;
        if(msg.sender == GenesisAddress) revert();
        if(miningreward <= 0) return false;
        uint miningreward = getMiningReward();
        totalSupply = totalSupply.add(miningreward);
        balances[msg.sender] = balances[msg.sender].add(miningreward);
        emit PublicMining(address(this), msg.sender, miningreward);
        return true;
    }

    function getMiningReward() internal view returns (uint) {
        require(now >= MiningStartTime);
        uint rewardEra = MiningRewardEra;
        return balances[msg.sender].div(365 / rewardEra);
    }
    
    function mint(address account, uint256 amount) public onlyOwner {
        require(MiningRewardSupply <= MaximumTotalSupply);
        require(account != address(0));
        balances[address(this)] = balances[address(this)].add(amount);
        emit Transfer(address(0), address(this), MiningRewardSupply);
    }
    
    event ChangeMiningRewardEra(uint256 value);
    
    function changeMiningRewardEra(uint256 _MiningRewardEra) public onlyOwner {
        MiningRewardEra = _MiningRewardEra;
        emit ChangeMiningRewardEra(MiningRewardEra);
    }

//------------------------------------------------------------------------------
//Change Max Supply
//------------------------------------------------------------------------------
    
    event ChangeMaximumTotalSupply(uint256 value);
    
    function changeMaximumTotalSupply(uint256 _MaximumTotalSupply) public onlyOwner {
        MaximumTotalSupply = _MaximumTotalSupply;
        emit ChangeMaximumTotalSupply(MaximumTotalSupply);
    }
    
    event Burn(address indexed burner, uint256 value);
    
    function BurnToken(uint _value) public onlyOwner {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
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