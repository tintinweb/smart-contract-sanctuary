/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity ^0.4.11;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
    function Ownable() {
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
    function transferOwnership(address newOwner) onlyOwner {
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
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title PoSTokenStandard
 * @dev the interface of PoSTokenStandard
 */
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    function mint() returns (bool);
    function annualInterest() constant returns (uint256);
    event Mint(address indexed _address, uint _reward);
}

//------------------------------------------------------------------------------
//Contructor
//------------------------------------------------------------------------------

contract ISENG is ERC20,PoSTokenStandard, Ownable {
    using SafeMath for uint256;

    string public name = "ISENG";
    string public symbol = "ISENG";
    uint public decimals = 18;

    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public defaultRate = 10**17; // default 10% annual interest

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    event Burn(address indexed burner, uint256 value);
    event ChangeMaxTotalSupply(uint256 value);
    event ChangeDefaultRate(uint256 _value);
    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier PoSMinter() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    function ISENG() {
        maxTotalSupply = 500000*10**18;
        totalInitialSupply = 50000*10**18;

        chainStartTime = now;
        stakeStartTime = now + 10 days;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
        if(msg.sender == _to) return mint();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
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
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//------------------------------------------------------------------------------
//Internal Wallet Proof Of Stake Implementation
//------------------------------------------------------------------------------

    function mint() PoSMinter returns (bool) {
        if(balances[msg.sender] <= 0) return false;

        uint reward = getReward();
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);

        Mint(msg.sender, reward);
        return true;
    }

    function getBlockNumber() returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function annualInterest() constant returns(uint interest) {
        uint _now = now;
        interest = defaultRate;
        if((_now.sub(stakeStartTime)).div(365) == 0) {
            interest = (1000 * defaultRate).div(100);
            // 1st year effective annual interest rate is 100%
        } else if((_now.sub(stakeStartTime)).div(365) == 1) {
            // 2nd year effective annual interest rate is 75%
            interest = (500 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 2) {
            // 3rd year effective annual interest rate is 50%
            interest = (250 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 3) {
            // 4th year effective annual interest rate is 12.5%
            interest = (125 * defaultRate).div(100);
        }
    }

    function getReward() internal returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));

        uint _now = now;
        uint stakedAmount = balances[msg.sender];
        uint interest = defaultRate;

        if((_now.sub(stakeStartTime)).div(365) == 0) {
            // 1st year effective annual interest rate is 100%
            interest = (1000 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 1) {
            // 2nd year effective annual interest rate is 75%
            interest = (500 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 2) {
            // 3rd year effective annual interest rate is 50%
            interest = (250 * defaultRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365) == 3) {
            // 4th year effective annual interest rate is 12.5%
            interest = (125 * defaultRate).div(100);
        }

        return stakedAmount.mul(interest).div(365 * (10**decimals));
    }

    function burn(uint _value) onlyOwner {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        Burn(msg.sender, _value);
    }

    function changeDefaultRate(uint _defaultRate) public onlyOwner{
        defaultRate = _defaultRate;
        ChangeDefaultRate(defaultRate);
    }

    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        ChangeMaxTotalSupply(maxTotalSupply);
    }

///------------------------------------------------------------------------------
///Presale
///------------------------------------------------------------------------------

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ChangeRate(uint256 _value);
    
    bool public closed;
    
    uint public presaleSupply = 20000*10*18;
    uint public rate = 100;
    uint public startDate = now;
    uint public constant ETHMin = 0.1 ether; //Minimum purchase
    uint public constant ETHMax = 50 ether; //Maximum purchase

    function () public payable {
        uint amount;
        owner.transfer(msg.value);
        amount = msg.value * rate;
        balances[msg.sender] += amount;
        totalSupply = totalInitialSupply.add(balances[msg.sender]);
        presaleSupply = presaleSupply.sub(balances[msg.sender]);
        
        require((now >= startDate) && (startDate > 0));
        require(!closed);
        require(amount <= presaleSupply);
        require(msg.value >= ETHMin && msg.value <= ETHMax);
        
        Transfer(address(0), msg.sender, amount);
    }
    
    function closeSale() public onlyOwner {
        require(!closed); closed = true;
    }
    
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate; ChangeRate(rate);
    }
}