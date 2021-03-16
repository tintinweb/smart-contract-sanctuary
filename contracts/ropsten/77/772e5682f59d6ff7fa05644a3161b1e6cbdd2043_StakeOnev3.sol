/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
 
contract Ownable {
    address public owner;
    
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
     
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Destructible is Ownable {}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) internal constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title ProofOfStakeToken
 * @dev the interface of ProofOfStakeToken
 */
 
contract ProofOfStakeToken {
    uint256 public stakeStartTime;
    uint256 public minTokenHold;
    
    function mint() public returns (bool);
    function continuousMint() internal returns (uint256);
    function coinbase() internal view returns (uint256);
    function annualRate() internal constant returns (uint256);
    
    event Mint(address indexed _address, uint _reward);
    event ContinuousMint(address indexed _address, uint _reward);
}

//------------------------------------------------------------------------------
//Contructor
//------------------------------------------------------------------------------

contract StakeOnev3 is ERC20, ProofOfStakeToken, Ownable {
    using SafeMath for uint256;

    string public name = "StakeOnev3";
    string public symbol = "SONE3";
    uint public decimals = 18;

    uint public chainStartTime; //Chain start time
    uint public chainStartBlockNumber; //Chain start block number
    uint public stakeStartTime; //Stake start time
    uint public minTokenHold;
    uint public defaultInterest = 10**17; //Default 10% annual interest

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;
    uint public presaleSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    address public tokenContractAddress = address(this);

    event Burn(address indexed burner, uint256 value);
    event ChangeMaxTotalSupply(uint256 value);
    event ChangeMinTokenHold(uint256 value);
    event ChangeDefaultInterest(uint256 value);

    /**
     * @dev Fix for the ERC20 short address attack.
     */
     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier PoSMinter () {
        require(totalSupply <= maxTotalSupply);
        _;
    }

    function StakeOnev3 () public {
        maxTotalSupply = 500000*10**18;
        totalInitialSupply = 20000*10**18;
        presaleSupply = 30000*10**18;
        
        minTokenHold = 500*10**18;
        
        stakeStartTime = now;
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        
        balances[msg.sender] = totalInitialSupply;
        balances[0x0] = presaleSupply;
        
        totalSupply = totalInitialSupply;
    }

//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
        if(msg.sender == _to && balances[msg.sender] < minTokenHold) revert ();
        if(msg.sender == _to && balances[msg.sender] >= minTokenHold) return mint();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
        require(_to != address(0));
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) internal constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//------------------------------------------------------------------------------
//Internal Proof Of Stake function
//------------------------------------------------------------------------------

    function mint() public PoSMinter returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(balances[msg.sender] < minTokenHold) return false;

        uint mintReward = getMintReward();
        assert(mintReward <= maxTotalSupply);
        if(mintReward <= 0) return false;

        totalSupply = totalSupply.add(mintReward);
        balances[msg.sender] = balances[msg.sender].add(mintReward);

        Mint(msg.sender, mintReward);
        
        Transfer(address(0), msg.sender, mintReward);
        ERC20(tokenContractAddress).transfer(msg.sender, mintReward);
        
        continuousMint();
        
        return true;
    }
    
    function continuousMint() internal returns (uint256) {
        uint mintReward = getMintReward();
        
        ContinuousMint(msg.sender, mintReward);
        Mint(msg.sender, mintReward);
        
        Transfer(address(0), msg.sender, mintReward);
        ERC20(tokenContractAddress).transfer(msg.sender, mintReward);
        
        return mintReward;
    }
    
    function coinbase() internal view returns (uint myCoinBase) {
        myCoinBase = getCoinBase();
    }

    function getCoinBase() internal view returns (uint _coinBase) {
        _coinBase = balances[msg.sender];
    }
    
    function annualRate() internal constant returns (uint interest) {
        uint _now = now;
        interest = defaultInterest;
        if((_now.sub(stakeStartTime)).div(365 days) == 0) {
            interest = (1000 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 1){
            interest = (500 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 2){
            interest = (250 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 3){
            interest = (125 * defaultInterest).div(100);
        }
    }

    function getMintReward() internal constant returns (uint256) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));

        uint _now = now;
        uint _coinBase = getCoinBase();
        if(_coinBase < minTokenHold) return 0;

        uint interest = defaultInterest;
        if((_now.sub(stakeStartTime)).div(365 days) == 0) {
            // 1st year effective annual interest rate is 100%
            interest = (1000 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 1){
            // 2nd year effective annual interest rate is 50%
            interest = (500 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 2){
            // 3rd year effective annual interest rate is 25%
            interest = (250 * defaultInterest).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 3){
            // 4th year effective annual interest rate is 12.5%
            interest = (125 * defaultInterest).div(100);
        }
        // 5th year - end effective annual interest rate is 10%
        return ((_coinBase * 30*10**18).mul(interest)).div(365);
    }
    
    function getBlockNumber() internal view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function burnSupply(uint _value) public onlyOwner {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
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
    }
    
    function setStakeStartTime(uint timestamp) public onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }
    
    function changeMinTokenHold(uint256 _minTokenHold) public onlyOwner {
        minTokenHold = _minTokenHold;
        ChangeMinTokenHold(minTokenHold);
    }
    
    function changeDefaultInterest(uint256 _defaultInterest) public onlyOwner {
        defaultInterest = _defaultInterest;
        ChangeDefaultInterest(defaultInterest);
    }

    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        ChangeMaxTotalSupply(maxTotalSupply);
    }

///------------------------------------------------------------------------------
///Presale
///------------------------------------------------------------------------------

    event ChangeRate(uint256 value);
    event ChangePresaleSupply(uint256 value);
    event Purchase(address indexed purchaser, uint256 amount);
    
    bool public closed;
    
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
        balances[0x0] = balances[0x0].sub(purchasedAmount);
        
        require((now >= startDate) && (startDate > 0));
        require(!closed);
        require(msg.value >= ETHMin && msg.value <= ETHMax);
        if (purchasedAmount > balances[0x0]) {revert();}
        
        Transfer(0x0, msg.sender, purchasedAmount);
        Purchase(msg.sender, purchasedAmount);
        ERC20(tokenContractAddress).transfer(msg.sender, purchasedAmount);
    }
    
    function closeSale() public onlyOwner {
        require(!closed); closed = true;
    }
    
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate; ChangeRate(rate);
    }
    
    function withdraw(uint _value) public onlyOwner {
        balances[0x0] = balances[0x0].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        totalSupply = totalInitialSupply.add(_value);
        Transfer(0x0, msg.sender, _value);
    }
    
    function changePresaleSupply(uint256 _presaleSupply) public onlyOwner {
        presaleSupply = _presaleSupply;
        ChangePresaleSupply(presaleSupply);
    }
}