pragma solidity ^0.4.23;

// File: contracts/Utils/Math.sol

library MathUtils {
    function add(uint a, uint b) internal pure returns (uint) {
        uint result = a + b;

        if (a == 0 || b == 0) {
            return result;
        }

        require(result > a && result > b);

        return result;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(a >= b);

        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }

        uint result = a * b;

        require(result / a == b);

        return result;
    }
}

// File: contracts/Token/Balance.sol

contract Balance {
    mapping(address => uint) public balances;

    // ERC20 function
    function balanceOf(address account) public constant returns (uint) {
        return balances[account];
    }

    modifier hasSufficientBalance(address account, uint balance) {
        require(balances[account] >= balance);
        _;
    }
}

// File: contracts/Utils/Ownable.sol

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function isOwner() view public returns (bool) {
        return msg.sender == owner;
    }

    modifier grantOwner {
        require(isOwner());
        _;
    }
}

// File: contracts/Token/CrowdsaleState.sol

interface CrowdsaleState {
    function isCrowdsaleSuccessful() external view returns(bool);
}

// File: contracts/Token/HardCap.sol

interface HardCap {
    function getHardCap() external pure returns(uint);
}

// File: contracts/Token/Crowdsale.sol

contract Crowdsale is Ownable {
    address public crowdsaleContract;

    function isCrowdsale() internal view returns(bool) {
        return crowdsaleSet() && msg.sender == crowdsaleContract;
    }

    function crowdsaleSet() internal view returns(bool) {
        return crowdsaleContract != address(0);
    }

    function addressIsCrowdsale(address _address) public view returns(bool) {
        return crowdsaleSet() && crowdsaleContract == _address;
    }

    function setCrowdsaleContract(address crowdsale) public grantOwner {
        require(crowdsaleContract == address(0));
        crowdsaleContract = crowdsale;
    }

    function crowdsaleSuccessful() internal view returns(bool) {
        require(crowdsaleSet());
        return CrowdsaleState(crowdsaleContract).isCrowdsaleSuccessful();
    }

    function getCrowdsaleHardCap() internal view returns(uint) {
        require(crowdsaleSet());
        return HardCap(crowdsaleContract).getHardCap();
    }
}

// File: contracts/Token/TotalSupply.sol

contract TotalSupply {
    uint public totalSupply = 1000000000 * 10**18;

    // ERC20 function
    function totalSupply() external constant returns (uint) {
        return totalSupply;
    }
}

// File: contracts/Token/Burnable.sol

contract Burnable is TotalSupply, Balance, Ownable, Crowdsale {
    using MathUtils for uint;

    event Burn(address account, uint value);

    function burn(uint amount) public grantBurner hasSufficientBalance(msg.sender, amount) {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Burn(msg.sender, amount);
    }

    modifier grantBurner {
        require(isCrowdsale());
        _;
    }
}

// File: contracts/Token/TokenRecipient.sol

interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

// File: contracts/Token/CryptoPoliceOfficerToken.sol

/// ERC20 compliant token contract
contract CryptoPoliceOfficerToken is TotalSupply, Balance, Burnable {
    using MathUtils for uint;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    mapping(address => mapping(address => uint)) allowances;
    
    bool public publicTransfersEnabled = false;
    uint public releaseStartTime;

    uint public lockedAmount;
    TokenLock[] public locks;

    struct TokenLock {
        uint amount;
        uint timespan;
        bool released;
    }

    event Transfer(
        address indexed fromAccount,
        address indexed destination,
        uint amount
    );
    
    event Approval(
        address indexed fromAccount,
        address indexed destination,
        uint amount
    );
    
    constructor(
        string tokenName,
        string tokenSymbol
    )
        public
    {
        name = tokenName;
        symbol = tokenSymbol;
        balances[msg.sender] = totalSupply;
    }
    
    function _transfer(
        address source,
        address destination,
        uint amount
    )
        internal
        hasSufficientBalance(source, amount)
        whenTransferable(destination)
        hasUnlockedAmount(source, amount)
    {
        require(destination != address(this) && destination != 0x0);

        if (amount > 0) {
            balances[source] -= amount;
            balances[destination] = balances[destination].add(amount);
        }

        emit Transfer(source, destination, amount);
    }

    function transfer(address destination, uint amount)
    public returns (bool)
    {
        _transfer(msg.sender, destination, amount);
        return true;
    }

    function transferFrom(
        address source,
        address destination,
        uint amount
    )
        public returns (bool)
    {
        require(allowances[source][msg.sender] >= amount);

        allowances[source][msg.sender] -= amount;

        _transfer(source, destination, amount);
        
        return true;
    }
    
    /**
     * Allow destination address to withdraw funds from account that is caller
     * of this function
     *
     * @param destination The one who receives permission
     * @param amount How much funds can be withdrawn
     * @return Whether or not approval was successful
     */
    function approve(
        address destination,
        uint amount
    )
        public returns (bool)
    {
        allowances[msg.sender][destination] = amount;
        emit Approval(msg.sender, destination, amount);
        
        return true;
    }
    
    function allowance(
        address fromAccount,
        address destination
    )
        public constant returns (uint)
    {
        return allowances[fromAccount][destination];
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _extraData
    )
        public
        returns (bool)
    {
        TokenRecipient spender = TokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }

        return false;
    }

    function enablePublicTransfers()
    public grantOwner
    {
        require(crowdsaleSuccessful());
        
        publicTransfersEnabled = true;
        releaseStartTime = now;
    }

    function addTokenLock(uint amount, uint timespan)
    public grantOwner
    {
        require(releaseStartTime == 0);
        requireOwnerUnlockedAmount(amount);

        locks.push(TokenLock({
            amount: amount,
            timespan: timespan,
            released: false
        }));

        lockedAmount += amount;
    }

    function releaseLockedTokens(uint8 idx)
    public grantOwner
    {
        require(releaseStartTime > 0);
        require(!locks[idx].released);
        require((releaseStartTime + locks[idx].timespan) < now);

        locks[idx].released = true;
        lockedAmount -= locks[idx].amount;
    }

    function requireOwnerUnlockedAmount(uint amount)
    internal view
    {
        require(balanceOf(owner).sub(lockedAmount) >= amount);
    }

    function setCrowdsaleContract(address crowdsale)
    public grantOwner
    {
        super.setCrowdsaleContract(crowdsale);
        transfer(crowdsale, getCrowdsaleHardCap());
    }

    modifier hasUnlockedAmount(address account, uint amount) {
        if (owner == account) {
            requireOwnerUnlockedAmount(amount);
        }
        _;
    }

    modifier whenTransferable(address destination) {
        require(publicTransfersEnabled
            || isCrowdsale()
            || (isOwner() && addressIsCrowdsale(destination) && balanceOf(crowdsaleContract) == 0)
            || (isOwner() && !crowdsaleSet())
        );
        _;
    }
}