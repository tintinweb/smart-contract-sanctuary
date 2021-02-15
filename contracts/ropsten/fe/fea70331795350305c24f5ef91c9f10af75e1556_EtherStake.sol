/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

pragma solidity ^0.4.19;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b; assert(a == 0 || c / a == b); return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b; return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
    function name() public constant returns (string _name);
    function symbol() public constant returns (string _symbol);
    function decimals() public constant returns (uint8 _decimals);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge(address staker) public view returns (uint256);
    function annualInterest() public view returns (uint256);
    event Mint(address indexed _address, uint _reward);
}

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data);
}

contract EtherStake is ERC20, PoSTokenStandard, Ownable {
    using SafeMath for uint256;

    string public name = "EtherStake";
    string public symbol = "ETHAS";
    uint public decimals = 18;

    uint256 public totalSupply;
    uint256 public MaxTotalSupply;
    uint256 public TotalInitialSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

//----------------------------------------------------------------------------------
//ERC20 Basic Function
//----------------------------------------------------------------------------------

    function name() public constant returns (string _name) {
        return _name;

    }

    function symbol() public constant returns (string _symbol) {
        return _symbol;

    }

    function decimals() public constant returns (uint8 _decimals) {
        return _decimals;

    }

//------------------------------------------------------------------------------
//Contructor
//------------------------------------------------------------------------------

    function EtherStake () public {
        MaxTotalSupply = 50000000e18;
        TotalInitialSupply = 670000e18;
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = TotalInitialSupply;
        totalSupply = TotalInitialSupply;
    }

//------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------
    
    bool public closed;
    
    uint public price = 100;
    uint public startDate = now;
    uint public constant EthMin = 0.01 ether;
    uint public constant EthMax = 5 ether;
    uint public constant presaleSupply = 330000e18;

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
        require(tokens <= presaleSupply);
        Transfer(address(0), msg.sender, tokens);
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }

//------------------------------------------------------------------------------
//Proof Of Stake Function
//------------------------------------------------------------------------------

    struct transferInStruct{uint128 amount;uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    modifier canPoSMint() {require(totalSupply < MaxTotalSupply); _;}

    event Burn(address indexed burner, uint256 value);
    event Change(uint256 value);

    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 3 days; // minimum age for coin age: 3 Days
    uint public stakeMaxAge = 90 days; // stake age of full weight: 90 Days
    uint public maxMintProofOfStake = 25e17; // default 25% annual interest

    function mint() canPoSMint public returns (bool) {
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
    
    function change(uint256 _maxMintProofOfStake) public onlyOwner{
        maxMintProofOfStake = _maxMintProofOfStake;
        Change(maxMintProofOfStake);
    }
    
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;assembly {length := extcodesize(_addr)}
        return (length > 0);

    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
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

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(_to != address(0));
        var _allowance = allowed[_from][msg.sender];
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
    
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
      if(msg.sender == _to) return mint();
      if(balanceOf(msg.sender) < _value) revert();
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
      balances[_to] = balanceOf(_to).add(_value);
      if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
      uint64 _now = uint64(now);
      transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
      transferIns[_to].push(transferInStruct(uint128(_value),_now));
      Transfer(msg.sender, _to, _value);
      return true;

    }

    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
      if(msg.sender == _to) return mint();
      if (balanceOf(msg.sender) < _value) revert();
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
      balances[_to] = balanceOf(_to).add(_value);
      ContractReceiver reciever = ContractReceiver(_to);
      reciever.tokenFallback(msg.sender, _value, _data);
      if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
      uint64 _now = uint64(now);
      transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
      transferIns[_to].push(transferInStruct(uint128(_value),_now));
      Transfer(msg.sender, _to, _value);
      return true;

    }

    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge(address staker) public view returns (uint256 myCoinAge) {
        return getCoinAge(staker,now);
    }

    function annualInterest() public view returns (uint interest) {
        uint _now = now;
        interest = maxMintProofOfStake;
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            interest = (770 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            interest = (435 * maxMintProofOfStake).div(100);
        }
    }

    function getProofOfStakeReward(address _address) internal view returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );
        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;
        uint interest = maxMintProofOfStake;
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 100% when we select the stakeMaxAge (90 days) as the compounding period.
            interest = (770 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            // 2nd year effective annual interest rate is 50%
            interest = (435 * maxMintProofOfStake).div(100);
        }
        uint offset = 10e18;
        return (_coinAge * interest).div(365 * offset);
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

    function burn(uint _value) public onlyOwner {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        totalSupply = totalSupply.sub(_value);
        TotalInitialSupply = TotalInitialSupply.sub(_value);
        MaxTotalSupply = MaxTotalSupply.sub(_value);
        Burn(msg.sender, _value);
    }
}