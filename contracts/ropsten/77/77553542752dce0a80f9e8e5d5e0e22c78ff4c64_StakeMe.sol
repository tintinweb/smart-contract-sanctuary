/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a); return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b; assert(c >= a); return c;
    }
}

contract Ownable {
    address public owner;
    function Ownable() {owner = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner);_;}
    function transferOwnership(address newOwner) onlyOwner {require(newOwner != address(0)); owner = newOwner;}
}

contract Destructible is Ownable {}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge() constant returns (uint256);
    function annualPercentage() returns (uint256);
    event Mint(address indexed _address, uint _reward);
}

//--------------------------------------------------------------------------------------
//Contructor
//--------------------------------------------------------------------------------------

contract StakeMe is ERC20, PoSTokenStandard, Ownable {
    using SafeMath for uint256;

    string public name = "StakeMe";
    string public symbol = "STAKE";
    uint public decimals = 18;

    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 1 days; // minimum age for coin age: 5 D
    uint public stakeMaxAge = 10 days; // stake age of full weight: 10 D
    uint public basePercentage = 2500; //Default percentage rate 25%

    uint public totalSupply;
    uint public totalInitialSupply;
    uint public MaxTotalSupply = 50000000e18;
    uint public PresaleSupply = 3000000e18; //Only 3% from Maximum Total Supply

    struct transferInStruct{
    uint128 amount;
    uint64 time;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    /**
     * @dev Fix for the ERC20 short address attack.
     */

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier canPoSMint() {
        require(totalSupply < MaxTotalSupply);
        _;
    }

    function StakeMe() public {
        totalInitialSupply = 2000000e18; // 1 Mil.

        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
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

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool) {
        require(_to != address(0));
        var _allowance = allowed[_from][msg.sender];
        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);
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

    function approve(address _spender, uint256 _value) returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//--------------------------------------------------------------------------------------
//Proof Of Stake Mechanism Implementation
//--------------------------------------------------------------------------------------
    //There are 2 ways to activate POS mining.
    //Send any amount of POS tokens back to your self (same ethereum address that holds the POS tokens).
    //Interact with the contract with any ethereum wallet that is capable of calling smart contract functions
    //See tutorial : https://medium.com/@btcmasterflex/postoken-the-worlds-first-pos-smart-contract-token-287932d7c668
    
    function mint() public canPoSMint returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Mint(msg.sender, reward);
        return true;
    }

    function getBlockNumber() returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() constant returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualPercentage() returns(uint percentage) {
        uint _now = now;
        percentage = basePercentage;
        if((_now.sub(stakeStartTime)) == 0){
            //1st years : 100%
            percentage = percentage.mul(4);
        } else if((_now.sub(stakeStartTime)) == 1){
            //2nd years : 100%
            percentage = percentage.mul(4);
        } else if((_now.sub(stakeStartTime)) == 2){
            //3rd years : 100%
            percentage = percentage.mul(4);
        } else if((_now.sub(stakeStartTime)) == 3){
            //4th years : 75%
            percentage = percentage.mul(3);
        } else if((_now.sub(stakeStartTime)) == 4){
            //5th years : 75%
            percentage = percentage.mul(3);
        } else if((_now.sub(stakeStartTime)) == 5){
            //6th years : 75%
            percentage = percentage.mul(3);
        } else if((_now.sub(stakeStartTime)) == 6){
            //7th years : 50%
            percentage = percentage.mul(2);
        } else if((_now.sub(stakeStartTime)) == 7){
            //8th years : 50%
            percentage = percentage.mul(2);
        } else if((_now.sub(stakeStartTime)) == 8){
            //9th years : 50%
            percentage = percentage.mul(2);
        }
    }

    function getProofOfStakeReward(address _address) internal returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );
        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;
        uint percentage = basePercentage;
        if((_now.sub(stakeStartTime)) == 0){
            //1st years : 100%
            percentage = percentage.mul(4);
        } else if((_now.sub(stakeStartTime)) == 1){
            //2nd years : 100%
            percentage = percentage.mul(4);
        } else if((_now.sub(stakeStartTime)) == 2){
            //3rd years : 100%
            percentage = percentage.mul(4);
        } else if((_now.sub(stakeStartTime)) == 3){
            //4th years : 75%
            percentage = percentage.mul(3);
        } else if((_now.sub(stakeStartTime)) == 4){
            //5th years : 75%
            percentage = percentage.mul(3);
        } else if((_now.sub(stakeStartTime)) == 5){
            //6th years : 75%
            percentage = percentage.mul(3);
        } else if((_now.sub(stakeStartTime)) == 6){
            //7th years : 50%
            percentage = percentage.mul(2);
        } else if((_now.sub(stakeStartTime)) == 7){
            //8th years : 50%
            percentage = percentage.mul(2);
        } else if((_now.sub(stakeStartTime)) == 8){
            //9th years : 50%
            percentage = percentage.mul(2);
        }
        //10th - 12th years percentage : 25%
        return _coinAge.mul(percentage).div(365).div(1e4);
    }

    function getCoinAge(address _address, uint _now) internal returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;
            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    function ownerSetStakeStartTime(uint timestamp) public onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

    /* Batch token transfer. Used by contract creator to distribute initial tokens to holders */
    function batchTransfer(address[] _recipients, uint[] _values) onlyOwner returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for(uint i = 0; i < _values.length; i++){
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);
        for(uint j = 0; j < _recipients.length; j++){
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            transferIns[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now));
            emit Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        if(balances[msg.sender] > 0) transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));

        return true;
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
    function supply(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        balances[account] = balances[account].add(amount);
        totalSupply = balances[account].add(amount);
        MaxTotalSupply = MaxTotalSupply.add(amount);
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
    
    uint public rate = 4000; //1 ETH = 4000 ETHC
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