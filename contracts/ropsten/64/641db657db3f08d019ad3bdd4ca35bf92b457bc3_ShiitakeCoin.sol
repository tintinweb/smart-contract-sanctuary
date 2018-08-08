pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
 * @dev The Ownable contract has an owner address, and provides basic authorization
 *      control functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the
     *      sender account.
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
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title ERC223
 * @dev ERC223 contract interface with ERC20 functions and events
 *      Fully backward compatible with ERC20
 *      Recommended implementation used at https://github.com/Dexaran/ERC223-token-standard/tree/Recommended
 */
contract ERC223 {
    uint public totalSupply;

    // ERC223 and ERC20 functions and events
    function balanceOf(address who) public view returns (uint);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string customFallback) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);

    // ERC223 functions
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);

    // ERC20 functions and events
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * @title ContractReceiver
 * @dev Contract that is working with ERC223 tokens
 */
 contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
        
        /*
         * tkn variable is analogue of msg variable of Ether transaction
         * tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
         * tkn.value the number of tokens that were sent   (analogue of msg.value)
         * tkn.data is data of token transaction   (analogue of msg.data)
         * tkn.sig is 4 bytes signature of function if data of token transaction is a function execution
         */
    }
}

/**
 * @title ShiitakeCoin
 * @author ShiitakeCoin
 * @dev ShiitakeCoin is an ERC223 Token with ERC20 functions and events
 *      Fully backward compatible with ERC20
 */
contract ShiitakeCoin is ERC223, Ownable {
    using SafeMath for uint256;

    string  public name = "ShiitakeCoin";
    string  public symbol = "SHTKC";
    bool    public mintingFinished = false;
    uint8   public decimals = 8;
    uint256 public totalInitialSupply = 20e6 * 1e8;
    uint256 public totalSupply;
    uint256 public maxTotalSupply = 10e7 * 1e8;
    uint256 public distributeAmount = 0;
    uint256 public chainStartTime; //chain start time
    uint256 public chainStartBlockNumber; //chain start block number
    uint256 public stakeStartTime; //stake start time
    uint256 public stakeMinAge = 3; // minimum age for coin age: 3D
    uint256 public stakeMaxAge = 90; // stake age of full weight: 90
    uint256 public overStakeAge = 180; // over stake age of burn weight: 180
    uint256 public maxMintProofOfStake = 5**7; // default 5% annual interest
    address[] public coinHaving;
    
    struct transferInStruct{
      uint128 amount;
      uint64 time;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public unlockUnixTime;
    mapping(address => bool) public frozenAccount;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping(address => transferInStruct[]) transferIns;
    
    event FrozenFunds(address indexed target, bool frozen);
    event LockedFunds(address indexed target, uint256 locked);
    event Burn(address indexed from, uint256 amount);
    event MintFinished();
    event Mint(address indexed _address, uint _reward);

    /** 
     * @dev Constructor is called only once and can not be called again
     */
    constructor () public {
        chainStartTime = now;
        stakeStartTime = now;
        chainStartBlockNumber = block.number;

        balanceOf[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

    /** Finds the index of a given value in an array. */
    function arrayIndexOf(address[] _addresses, address _address) pure public returns(uint) {
    for (uint i = 0; i < _addresses.length; i++) {
        if (_addresses[i] == _address)
            return i;      
    }
    return 9999999999;
    }

    /**
     * @dev Prevent targets from sending or receiving tokens
     * @param targets Addresses to be frozen
     * @param isFrozen either to freeze it or not
     */
    function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
        require(targets.length > 0);

        for (uint i = 0; i < targets.length; i++) {
            require(targets[i] != 0x0);
            frozenAccount[targets[i]] = isFrozen;
            FrozenFunds(targets[i], isFrozen);
        }
    }

    /**
     * @dev Prevent targets from sending or receiving tokens by setting Unix times
     * @param targets Addresses to be locked funds
     * @param unixTimes Unix times when locking up will be finished
     */
    function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
        require(targets.length > 0
                && targets.length == unixTimes.length);
                
        for(uint i = 0; i < targets.length; i++){
            require(unlockUnixTime[targets[i]] < unixTimes[i]);
            unlockUnixTime[targets[i]] = unixTimes[i];
            LockedFunds(targets[i], unixTimes[i]);
        }
    }

    /**
     * @dev Function that is called when a user or another contract wants to transfer funds
     */
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
        require(_value > 0
                && frozenAccount[msg.sender] == false 
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender] 
                && now > unlockUnixTime[_to]);

        if (arrayIndexOf(coinHaving, _to) != 9999999999)
            coinHaving.push(_to);

        if (isContract(_to)) {
            require(balanceOf[msg.sender] >= _value);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value, _data);
            Transfer(msg.sender, _to, _value);

            if(transferIns[msg.sender].length > 0)
                delete transferIns[msg.sender];
            uint64 _now = uint64(now);
            transferIns[msg.sender].push(transferInStruct(uint128(balanceOf[msg.sender]),_now));
            transferIns[_to].push(transferInStruct(uint128(_value),_now));
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint _value, bytes _data) public  returns (bool success) {
        require(_value > 0
                && frozenAccount[msg.sender] == false 
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender] 
                && now > unlockUnixTime[_to]);

        if (arrayIndexOf(coinHaving, _to) != 9999999999)
            coinHaving.push(_to);

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    /**
     * @dev Standard function transfer similar to ERC20 transfer with no _data
     *      Added due to backwards compatibility reasons
     */
    function transfer(address _to, uint _value) public returns (bool success) {
        require(_value > 0
                && frozenAccount[msg.sender] == false 
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender] 
                && now > unlockUnixTime[_to]);

        if (arrayIndexOf(coinHaving, _to) != 9999999999)
            coinHaving.push(_to);

        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    // assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    // function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);

        if (arrayIndexOf(coinHaving, _to) != 9999999999)
            coinHaving.push(_to);

        if(transferIns[msg.sender].length > 0)
            delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balanceOf[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    // function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);

        if (arrayIndexOf(coinHaving, _to) != 9999999999)
            coinHaving.push(_to);

        if(transferIns[msg.sender].length > 0)
            delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balanceOf[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     *      Added due to backwards compatibility with ERC20
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balanceOf[_from] >= _value
                && allowance[_from][msg.sender] >= _value
                && frozenAccount[_from] == false 
                && frozenAccount[_to] == false
                && now > unlockUnixTime[_from] 
                && now > unlockUnixTime[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);

        if (arrayIndexOf(coinHaving, _to) != 9999999999)
            coinHaving.push(_to);

        if(transferIns[msg.sender].length > 0)
            delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balanceOf[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    /**
     * @dev Allows _spender to spend no more than _value tokens in your behalf
     *      Added due to backwards compatibility with ERC20
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     *      Added due to backwards compatibility with ERC20
     * @param _owner address The address which owns the funds
     * @param _spender address The address which will spend the funds
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _from The address that will burn the tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(address _from, uint256 _value) onlyOwner public {
        require(_value > 0
                && balanceOf[_from] >= _value);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_from, _value);
    }

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier canPoSMint() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    function overStakeAgeBurn() public {
        require(coinHaving.length <= 0);

        for (uint i = 0; i < coinHaving.length; i++){
            if(transferIns[coinHaving[i]].length <= 0)
                continue;
            if( overStakeAge < uint(transferIns[coinHaving[i]][i].time))
                delete transferIns[coinHaving[i]];
                burn(coinHaving[i], balanceOf[coinHaving[i]]);
        }
    }

    /**
     * @dev Function to mint tokens
     */
    function mint() canPoSMint canMint public returns (bool) {
        if(balanceOf[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if(reward <= 0)
            return false;

        totalSupply = totalSupply.add(reward);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balanceOf[msg.sender]),uint64(now)));

        Mint(msg.sender, reward);
        overStakeAgeBurn();
        return true;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _value The amount of tokens to mint.
     */
    function ownerMint(address _to, uint256 _value) onlyOwner canMint public returns (bool) {
        require(_value > 0);
        
        totalSupply = totalSupply.add(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balanceOf[msg.sender]), _now));
        transferIns[_to].push(transferInStruct(uint128(_value), _now));

        Mint(_to, _value);
        Transfer(address(0), _to, _value);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    /**
     * @dev Function to distribute tokens to the list of addresses by the provided amount
     */
    function distributeAirdrop(address[] addresses, uint256 amount) public returns (bool) {
        require(amount > 0 
                && addresses.length > 0
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);

        amount = amount.mul(1e8);
        uint256 totalAmount = amount.mul(addresses.length);
        require(balanceOf[msg.sender] >= totalAmount);
        
        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != 0x0
                    && frozenAccount[addresses[i]] == false
                    && now > unlockUnixTime[addresses[i]]);

            balanceOf[addresses[i]] = balanceOf[addresses[i]].add(amount);
            Transfer(msg.sender, addresses[i], amount);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

    function distributeAirdrop(address[] addresses, uint[] amounts) public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);
                
        uint256 totalAmount = 0;
        
        for(uint i = 0; i < addresses.length; i++){
            require(amounts[i] > 0
                    && addresses[i] != 0x0
                    && frozenAccount[addresses[i]] == false
                    && now > unlockUnixTime[addresses[i]]);
                    
            amounts[i] = amounts[i].mul(1e8);
            totalAmount = totalAmount.add(amounts[i]);
        }
        require(balanceOf[msg.sender] >= totalAmount);
        
        for (i = 0; i < addresses.length; i++) {
            balanceOf[addresses[i]] = balanceOf[addresses[i]].add(amounts[i]);
            Transfer(msg.sender, addresses[i], amounts[i]);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

    /**
     * @dev Function to collect tokens from the list of addresses
     */
    function collectTokens(address[] addresses, uint[] amounts) onlyOwner public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length);

        uint256 totalAmount = 0;
        
        for (uint i = 0; i < addresses.length; i++) {
            require(amounts[i] > 0
                    && addresses[i] != 0x0
                    && frozenAccount[addresses[i]] == false
                    && now > unlockUnixTime[addresses[i]]);
                    
            amounts[i] = amounts[i].mul(1e8);
            require(balanceOf[addresses[i]] >= amounts[i]);
            balanceOf[addresses[i]] = balanceOf[addresses[i]].sub(amounts[i]);
            totalAmount = totalAmount.add(amounts[i]);
            Transfer(addresses[i], msg.sender, amounts[i]);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].add(totalAmount);
        return true;
    }

    function setDistributeAmount(uint256 _value) onlyOwner public {
        distributeAmount = _value;
    }
    
    /**
     * @dev Function to distribute tokens to the msg.sender automatically
     *      If distributeAmount is 0, this function doesn&#39;t work
     */
    function autoDistribute() payable public {
        require(distributeAmount > 0
                && balanceOf[owner] >= distributeAmount
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);
        if(msg.value > 0) owner.transfer(msg.value);
        
        balanceOf[owner] = balanceOf[owner].sub(distributeAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(distributeAmount);
        Transfer(owner, msg.sender, distributeAmount);
    }

    /**
     * @dev fallback function
     */
    function() payable public {
        autoDistribute();
     }

    function getBlockNumber() view public returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() view public returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() constant public returns(uint interest) {
        uint _now = now;
        interest = maxMintProofOfStake;
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 50% when we select the stakeMaxAge (90 days) as the compounding period.
            interest = (770 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            // 2nd year effective annual interest rate is 25%
            interest = (435 * maxMintProofOfStake).div(100);
        }
    }

    function getProofOfStakeReward(address _address) view internal returns (uint) {
        require( now >= stakeStartTime
                && stakeStartTime > 0 );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0)
            return 0;

        uint interest = annualInterest();

        return (_coinAge * interest).div(365 * (10**decimals));
    }

    function getCoinAge(address _address, uint _now) view internal returns (uint _coinAge) {
        if(transferIns[_address].length <= 0)
            return 0;

        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(stakeMinAge))
                continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(nCoinSeconds > stakeMaxAge)
                nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    function setStakeStartTime(uint timestamp) public onlyOwner {
        require(stakeStartTime <= 0
                && timestamp >= chainStartTime);

        stakeStartTime = timestamp;
    }

}