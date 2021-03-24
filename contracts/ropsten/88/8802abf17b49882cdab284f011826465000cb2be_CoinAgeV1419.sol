/**
 *Submitted for verification at Etherscan.io on 2021-03-24
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
 
    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Destructible is Ownable {}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) internal view returns (uint256);
    function transferFrom(address from, address to, uint256 value) internal returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ProofOfStakeAndHoldToken {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    uint256 public tokenHold;
    function mint() public returns (bool);
    function coinAge() internal view returns (uint);
    function annualMintRate() internal view returns (uint256);
    event Mint(address indexed _address, uint _tokenMint);
}

//------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------

contract CoinAgeV1419 is ERC20, ProofOfStakeAndHoldToken, Ownable {
    using SafeMath for uint256;

    string public name = "CoinAgeV1419";
    string public symbol = "CV1419";
    uint public decimals = 18;

    uint public chainStartTime; // Chain start time
    uint public chainStartBlockNumber; // Chain start block number
    uint public stakeStartTime; // Stake start time 
    
    uint public stakeMinAge = 1 days; // Minimum age for coin age: 1 day
    uint public stakeMaxAge = 90 days; // Stake age of full weight: 90 days
    uint public defaultMintRate = 10**17; // Default minting rate is 10%
    uint public tokenHold = 1000 * (10**decimals); // Minimum token hold in wallet to trigger mint

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    struct transferInStruct{
        uint128 amount;
        uint64 time;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    event Burn(address indexed burner, uint256 value);
    event ChangeMaxTotalSupply(uint256 value);
    event ChangeDefaultMintRate(uint256 value);
    event ChangeTokenHold(uint value);

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier PoSHMinter () {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= tokenHold);
        _;
    }

    function CoinAgeV1419 () public {
        maxTotalSupply = 500000 * (10**decimals);
        totalInitialSupply = 50000 * (10**decimals);

        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    
//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        
        //Function to trigger mint by sending transaction without any amount
        //to own wallet address that hold minimun token.
        
        if(msg.sender == _to && balances[msg.sender] >= tokenHold) return mint();
        if(msg.sender == _to && balances[msg.sender] < tokenHold) revert();
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) internal returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

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

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) internal view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//------------------------------------------------------------------------------
//Internal Proof Of Stake and Hold function implementation
//------------------------------------------------------------------------------

    function mint() PoSHMinter public returns (bool) {
        require(balances[msg.sender] >= tokenHold);
        if(transferIns[msg.sender].length <= 0) return false;

        uint tokenMint = getMintReward(msg.sender);
        
        if(tokenMint <= 0) return false;
        assert(tokenMint <= maxTotalSupply);

        totalSupply = totalSupply.add(tokenMint);
        balances[msg.sender] = balances[msg.sender].add(tokenMint);
        
        //Function to reset coin age to zero after receive mint reward token
        //and user must hold for certain of coin age time again before mint reward token
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        Mint(msg.sender, tokenMint);
        return true;
    }

    function annualMintRate() internal view returns (uint mintRate) {
        uint _now = now;
        mintRate = defaultMintRate;
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            //1st year minting rate is 100%
            mintRate = (1000 * defaultMintRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            //2nd year minting rate is 50%
            mintRate = (500 * defaultMintRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 2){
            //3rd year minting rate is 25%
            mintRate = (250 * defaultMintRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 3){
            //4th year minting rate is 12.5%
            mintRate = (125 * defaultMintRate).div(100);
        }
    }

    function getMintReward(address _address) internal view returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;

        uint mintRate = defaultMintRate;
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            //1st year minting rate is 100%
            mintRate = (1000 * defaultMintRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            //2nd year minting rate is 50%
            mintRate = (500 * defaultMintRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 2){
            //3rd year minting rate is 25%
            mintRate = (250 * defaultMintRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 3){
            //4th year minting rate is 12.5%
            mintRate = (125 * defaultMintRate).div(100);
        }
        //5th year - 12th year minting rate is 10%
        return (_coinAge * mintRate).div(365 * (10**decimals));
    }
    
    function coinAge() internal view returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
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
    
    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function burnSupply(uint _value) public onlyOwner {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        Burn(msg.sender, _value);
    }

    function mintSupply(uint _value) public onlyOwner {
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        balances[msg.sender] = balances[msg.sender].add(_value);
        totalSupply = totalSupply.add(_value);
        totalInitialSupply = totalInitialSupply.add(_value);
        Transfer(address(0), msg.sender, _value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
    }

    function setStakeStartTime(uint timestamp) public onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

    function changeDefaultMintRate(uint256 _defaultMintRate) public onlyOwner {
        defaultMintRate = _defaultMintRate;
        ChangeDefaultMintRate(defaultMintRate);
    }

    function changeTokenHold(uint256 _tokenHold) public onlyOwner {
        tokenHold = _tokenHold;
        ChangeTokenHold(tokenHold);
    }

    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        ChangeMaxTotalSupply(maxTotalSupply);
    }

//------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------

    event ChangeRate(uint256 _value);
    event ChangePresaleSupply(uint256 _value);
    event Purchase(address indexed _purchaser, uint256 _purchasedAmount);
    
    bool public closed;
    
    uint public presaleSupply = 30000 * (10**decimals);
    uint public rate = 1000;
    uint public startDate = now;
    uint public constant ETHMin = 0.1 ether; //Minimum purchase
    uint public constant ETHMax = 100 ether; //Maximum purchase

    function () public payable {
        uint purchasedAmount = msg.value * rate;
        owner.transfer(msg.value);
        
        totalSupply = totalInitialSupply.add(purchasedAmount);
        presaleSupply = presaleSupply.sub(purchasedAmount);

        balances[msg.sender] = balances[msg.sender].add(purchasedAmount);
        
        transferIns[msg.sender]; transferIns[msg.sender].length += 1;
        
        require((now >= startDate) && (startDate > 0));
        require(!closed);
        require(msg.value >= ETHMin && msg.value <= ETHMax);
        assert(purchasedAmount <= presaleSupply);
        if (purchasedAmount > presaleSupply) {revert();}
        
        Transfer(address(0), msg.sender, purchasedAmount);
        Purchase(msg.sender, purchasedAmount);
    }
    
    function closeSale() public onlyOwner {
        require(!closed); closed = true;
    }
    
    function changePresaleSupply(uint256 _presaleSupply) public onlyOwner {
        presaleSupply = _presaleSupply;
        ChangePresaleSupply(presaleSupply);
    }
}