/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity ^0.5.8;

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
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        assert(newOwner != address(0));
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
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title InternalPoS
 * @dev the interface of Proof-Of-Stake
 */
 
contract InternalPoS {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge() public view returns (uint);
    function annualInterest() public view returns (uint256);
    event Mint(address indexed _address, uint _reward);
}

contract EthosOri_580 is ERC20, InternalPoS, Ownable {
    using SafeMath for uint256;

    string public name = "EthosOri_580";
    string public symbol = "ET0R580";
    uint public decimals = 18;

    uint public chainStartTime; 
    uint public chainStartBlockNumber;
    uint public stakeStartTime;
    uint public stakeMinAge = 1 days;
    uint public stakeMaxAge = 30 days;
    uint public defaultRate = 10**17; // default 10% annual interest

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    struct transferInStruct{
        uint128 amount;
        uint64 time;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) txIns;

    event Burn(address indexed burner, uint256 value);
    event ChangeMaxTotalSupply(uint256 value);

    /**
     * @dev Fix for the ERC20 short address attack.
     */
     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier PoSMinter () {
        assert(totalSupply < maxTotalSupply);
        _;
    }

    constructor () public {
        maxTotalSupply = 500000*10**18;
        totalInitialSupply = 50000*10**18;

        chainStartTime = now;
        chainStartBlockNumber = block.number;
        stakeStartTime = now;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        if(msg.sender == _to) return mint();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        if(txIns[msg.sender].length > 0) delete txIns[msg.sender];
        uint64 _now = uint64(now);
        txIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        txIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        if(txIns[_from].length > 0) delete txIns[_from];
        uint64 _now = uint64(now);
        txIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
        txIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(0));
    }

    function mint() PoSMinter public returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(txIns[msg.sender].length <= 0) return false;

        uint reward = getReward(msg.sender);
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete txIns[msg.sender];
        txIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Mint(msg.sender, reward);
        return true;
    }

    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() public view returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() public view returns(uint interest) {
        uint _now = now;
        interest = defaultRate;
        if((_now.sub(stakeStartTime)).div(365) == 0) {
            interest = (1000 * defaultRate).div(100);
            // 1st year effective annual interest rate is 100%
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
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;

        uint interest = defaultRate;

        if((_now.sub(stakeStartTime)).div(365) == 0) {
            interest = (1000 * defaultRate).div(100);
            // 1st year effective annual interest rate is 100%
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
        
        return (_coinAge * interest).div(365 * (10**decimals));
    }

    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) 
    {
        if(txIns[_address].length <= 0) return 0;

        for (uint i = 0; i < txIns[_address].length; i++){
            if( _now < uint(txIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(txIns[_address][i].time));
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(txIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    function multiSend(address[] memory _recipients, uint[] memory _values) onlyOwner public returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for(uint i = 0; i < _values.length; i++)
        {
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);
        for(uint j = 0; j < _recipients.length; j++)
        {
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            txIns[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now));
            emit Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        if(txIns[msg.sender].length > 0) delete txIns[msg.sender];
        if(balances[msg.sender] > 0) txIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));

        return true;
    }

    function burnSupply(uint _value) public onlyOwner {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);

        delete txIns[msg.sender];
        txIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        maxTotalSupply = maxTotalSupply.sub(_value);

        emit Burn(msg.sender, _value);
    }

    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        emit ChangeMaxTotalSupply(maxTotalSupply);
    }
}