pragma solidity ^0.4.19;

// File: contracts\Convertible.sol

/**
 * Exchange all my ParcelX token to mainchain GPX
 */
contract Convertible {

    function convertMainchainGPX(string destinationAccount, string extra) external returns (bool);
  
    // ParcelX deamon program is monitoring this event. 
    // Once it triggered, ParcelX will transfer corresponding GPX to destination account
    event Converted(address indexed who, string destinationAccount, uint256 amount, string extra);
}

// File: contracts\ERC20.sol

/**
 * Starndard ERC20 interface: https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    /**	
    * @dev Fix for the ERC20 short address attack.	
    * Remove short address attack checks from tokens(https://github.com/OpenZeppelin/openzeppelin-solidity/issues/261)
    */	
    modifier onlyPayloadSize(uint256 size) {	
        require(msg.data.length >= size + 4);
        _;	
    }
    
}

// File: contracts\MultiOwnable.sol

/**
 * FEATURE 2): MultiOwnable implementation
 * Transactions approved by _multiRequires of _multiOwners&#39; addresses will be executed. 

 * All functions needing unit-tests cannot be INTERNAL
 */
contract MultiOwnable {

    address[8] m_owners;
    uint m_numOwners;
    uint m_multiRequires;

    mapping (bytes32 => uint) internal m_pendings;

    event AcceptConfirm(address indexed who, uint confirmTotal);
    
    // constructor is given number of sigs required to do protected "multiOwner" transactions
    function MultiOwnable (address[] _multiOwners, uint _multiRequires) public {
        require(0 < _multiRequires && _multiRequires <= _multiOwners.length);
        m_numOwners = _multiOwners.length;
        require(m_numOwners <= 8);   // Bigger then 8 co-owners, not support !
        for (uint i = 0; i < _multiOwners.length; ++i) {
            m_owners[i] = _multiOwners[i];
            require(m_owners[i] != address(0));
        }
        m_multiRequires = _multiRequires;
    }

    // Any one of the owners, will approve the action
    modifier anyOwner {
        if (isOwner(msg.sender)) {
            _;
        }
    }

    // Requiring num > m_multiRequires owners, to approve the action
    modifier mostOwner(bytes32 operation) {
        if (checkAndConfirm(msg.sender, operation)) {
            _;
        }
    }

    function isOwner(address currentUser) public view returns (bool) {
        for (uint i = 0; i < m_numOwners; ++i) {
            if (m_owners[i] == currentUser) {
                return true;
            }
        }
        return false;
    }

    function checkAndConfirm(address currentUser, bytes32 operation) public returns (bool) {
        uint ownerIndex = m_numOwners;
        uint i;
        for (i = 0; i < m_numOwners; ++i) {
            if (m_owners[i] == currentUser) {
                ownerIndex = i;
            }
        }
        if (ownerIndex == m_numOwners) {
            return false;  // Not Owner
        }
        
        uint newBitFinger = (m_pendings[operation] | (2 ** ownerIndex));

        uint confirmTotal = 0;
        for (i = 0; i < m_numOwners; ++i) {
            if ((newBitFinger & (2 ** i)) > 0) {
                confirmTotal ++;
            }
        }
        
        AcceptConfirm(currentUser, confirmTotal);

        if (confirmTotal >= m_multiRequires) {
            delete m_pendings[operation];
            return true;
        }
        else {
            m_pendings[operation] = newBitFinger;
            return false;
        }
    }
}

// File: contracts\Pausable.sol

/**
 * FEATURE 3): Pausable implementation
 */
contract Pausable is MultiOwnable {
    event Pause();
    event Unpause();

    bool paused = false;

    // Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    // Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(paused);
        _;
    }

    // called by the owner to pause, triggers stopped state
    function pause() mostOwner(keccak256(msg.data)) whenNotPaused public {
        paused = true;
        Pause();
    }

    // called by the owner to unpause, returns to normal state
    function unpause() mostOwner(keccak256(msg.data)) whenPaused public {
        paused = false;
        Unpause();
    }

    function isPause() view public returns(bool) {
        return paused;
    }
}

// File: contracts\SafeMath.sol

/**
* Standard SafeMath Library: zeppelin-solidity/contracts/math/SafeMath.sol
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

// File: contracts\ParcelXGPX.sol

/**
 * The main body of final smart contract 
 */
contract ParcelXGPX is ERC20, MultiOwnable, Pausable, Convertible {

    using SafeMath for uint256;
  
    string public constant name = "ParcelX Token";
    string public constant symbol = "GPX";
    uint8 public constant decimals = 18;
    uint256 public constant TOTAL_SUPPLY = uint256(1000000000) * (uint256(10) ** decimals);  // 10,0000,0000

    address internal tokenPool;      // Use a token pool holding all GPX. Avoid using sender address.
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function ParcelXGPX(address[] _multiOwners, uint _multiRequires) 
        MultiOwnable(_multiOwners, _multiRequires) public {
        tokenPool = this;
        require(tokenPool != address(0));
        balances[tokenPool] = TOTAL_SUPPLY;
    }

    /**
     * FEATURE 1): ERC20 implementation
     */
    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;       
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
  }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * FEATURE 4): Buyable implements
     * 0.000268 eth per GPX, so the rate is 1.0 / 0.000268 = 3731.3432835820895
     */
    uint256 internal buyRate = uint256(3731); 
    
    event Deposit(address indexed who, uint256 value);
    event Withdraw(address indexed who, uint256 value, address indexed lastApprover, string extra);
        

    function getBuyRate() external view returns (uint256) {
        return buyRate;
    }

    function setBuyRate(uint256 newBuyRate) mostOwner(keccak256(msg.data)) external {
        buyRate = newBuyRate;
    }

    /**
     * FEATURE 4): Buyable
     * minimum of 0.001 ether for purchase in the public, pre-ico, and private sale
     */
    function buy() payable whenNotPaused public returns (uint256) {
        Deposit(msg.sender, msg.value);
        require(msg.value >= 0.001 ether);

        // Token compute & transfer
        uint256 tokens = msg.value.mul(buyRate);
        require(balances[tokenPool] >= tokens);
        balances[tokenPool] = balances[tokenPool].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        Transfer(tokenPool, msg.sender, tokens);
        
        return tokens;
    }

    // gets called when no other function matches
    function () payable public {
        if (msg.value > 0) {
            buy();
        }
    }

    /**
     * FEATURE 6): Budget control
     * Malloc GPX for airdrops, marketing-events, etc 
     */
    function mallocBudget(address _admin, uint256 _value) mostOwner(keccak256(msg.data)) external returns (bool) {
        require(_admin != address(0));
        require(_value <= balances[tokenPool]);

        balances[tokenPool] = balances[tokenPool].sub(_value);
        balances[_admin] = balances[_admin].add(_value);
        Transfer(tokenPool, _admin, _value);
        return true;
    }
    
    function execute(address _to, uint256 _value, string _extra) mostOwner(keccak256(msg.data)) external returns (bool){
        require(_to != address(0));
        Withdraw(_to, _value, msg.sender, _extra);
        _to.transfer(_value);   // Prevent using call() or send()
        return true;
    }

    /**
     * FEATURE 5): Convertible implements
     */
    function convertMainchainGPX(string destinationAccount, string extra) external returns (bool) {
        require(bytes(destinationAccount).length > 10 && bytes(destinationAccount).length < 128);
        require(balances[msg.sender] > 0);
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        balances[tokenPool] = balances[tokenPool].add(amount);   // recycle ParcelX to tokenPool&#39;s init account
        Converted(msg.sender, destinationAccount, amount, extra);
        return true;
    }

}