pragma solidity ^0.4.20;

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

/**
 * Buy GPX automatically when Ethers are received
 */
contract Buyable {

    function buy() payable public returns (uint256);

}



/**
 * Exchange all my ParcelX token to mainchain GPX
 */
contract Convertible {

    function convertMainchainGPX(string destinationAccount, string extra) external returns (bool);
  
    // ParcelX deamon program is monitoring this event. 
    // Once it triggered, ParcelX will transfer corresponding GPX to destination account
    event Converted(address indexed who, string destinationAccount, uint256 amount, string extra);
}

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
}

/**
 * FEATURE 2): MultiOwnable implementation
 */
contract MultiOwnable {

    address[8] m_owners;
    uint m_numOwners;
    uint m_multiRequires;

    mapping (bytes32 => uint) internal m_pendings;

    // constructor is given number of sigs required to do protected "multiOwner" transactions
    // as well as the selection of addresses capable of confirming them.
    function MultiOwnable (address[] _otherOwners, uint _multiRequires) internal {
        require(0 < _multiRequires && _multiRequires <= _otherOwners.length + 1);
        m_numOwners = _otherOwners.length + 1;
        require(m_numOwners <= 8);   // 不支持大于8人
        m_owners[0] = msg.sender;
        for (uint i = 0; i < _otherOwners.length; ++i) {
            m_owners[1 + i] = _otherOwners[i];
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

    function isOwner(address currentOwner) internal view returns (bool) {
        for (uint i = 0; i < m_numOwners; ++i) {
            if (m_owners[i] == currentOwner) {
                return true;
            }
        }
        return false;
    }

    function checkAndConfirm(address currentOwner, bytes32 operation) internal returns (bool) {
        uint ownerIndex = m_numOwners;
        uint i;
        for (i = 0; i < m_numOwners; ++i) {
            if (m_owners[i] == currentOwner) {
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

/**
 * The main body of final smart contract 
 */
contract ParcelXToken is ERC20, MultiOwnable, Pausable, Buyable, Convertible {

    using SafeMath for uint256;
  
    string public constant name = "TestGPX-name";
    string public constant symbol = "TestGPX-symbol";
    uint8 public constant decimals = 18;
    uint256 public constant TOTAL_SUPPLY = uint256(1000000000) * (uint256(10) ** decimals);  // 10,0000,0000

    address internal tokenPool;      // Use a token pool holding all GPX. Avoid using sender address.
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function ParcelXToken(address[] _otherOwners, uint _multiRequires) 
        MultiOwnable(_otherOwners, _multiRequires) public {
        tokenPool = this;
        balances[tokenPool] = TOTAL_SUPPLY;
    }

    /**
     * FEATURE 1): ERC20 implementation
     */
    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;       
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
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

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
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
    event Withdraw(address indexed who, uint256 value, address indexed lastApprover);
        

    function getBuyRate() external view returns (uint256) {
        return buyRate;
    }

    function setBuyRate(uint256 newBuyRate) mostOwner(keccak256(msg.data)) external {
        buyRate = newBuyRate;
    }

    // minimum of 0.001 ether for purchase in the public, pre-ico, and private sale
    function buy() payable whenNotPaused public returns (uint256) {
        require(msg.value >= 0.001 ether);
        uint256 tokens = msg.value.mul(buyRate);  // calculates the amount
        require(balances[tokenPool] >= tokens);               // checks if it has enough to sell
        balances[tokenPool] = balances[tokenPool].sub(tokens);                        // subtracts amount from seller&#39;s balance
        balances[msg.sender] = balances[msg.sender].add(tokens);                  // adds the amount to buyer&#39;s balance
        Transfer(tokenPool, msg.sender, tokens);               // execute an event reflecting the change
        return tokens;                                    // ends function and returns
    }

    // gets called when no other function matches
    function () public payable {
        if (msg.value > 0) {
            buy();
            Deposit(msg.sender, msg.value);
        }
    }

    function execute(address _to, uint256 _value, bytes _data) mostOwner(keccak256(msg.data)) external returns (bool){
        require(_to != address(0));
        Withdraw(_to, _value, msg.sender);
        return _to.call.value(_value)(_data);
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