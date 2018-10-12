pragma solidity 0.4.19;

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

    event AcceptConfirm(bytes32 operation, address indexed who, uint confirmTotal);
    
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
        
        AcceptConfirm(operation, currentUser, confirmTotal);

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

// File: contracts\AdvisorGPX.sol

/**
 * The updated body of smart contract.
 * %6 fund will be transferred to ParcelX advisors automatically. 
 */
contract AdvisorGPX is MultiOwnable, Pausable {

    using SafeMath for uint256;
    
    address internal advisor = 0xd173bdd2f4ccd88b35b83a8bc35dd05a3b5a3c79;
    uint internal payAdvisorFlag = 0;

    function AdvisorGPX(address[] _multiOwners, uint _multiRequires) 
        MultiOwnable(_multiOwners, _multiRequires) public {
    }
    
    event Deposit(address indexed who, uint256 value);
    event Withdraw(address indexed who, uint256 value, address indexed lastApprover, string extra);
    event AdviseFee(address advisor, uint256 advfee);

    function getTime() public view returns (uint256) {
        return now;
    }

    function getBalance() public view returns (uint256) {
        return this.balance;
    }
    
    /**
     * FEATURE : Buyable
     * minimum of 0.001 ether for purchase in the public, pre-ico, and private sale
     * Code caculates the endtime via python: 
     *   d1 = datetime.datetime.strptime("2018-10-31 23:59:59", &#39;%Y-%m-%d %H:%M:%S&#39;)
     *   t = time.mktime(d1.timetuple())
     *   d2 = datetime.datetime.fromtimestamp(t)
     *   assert (d1 == d2)  # print d2.strftime(&#39;%Y-%m-%d %H:%M:%S&#39;)
     *   print t # = 1541001599
     */
    function buy() payable whenNotPaused public returns (bool) {
        Deposit(msg.sender, msg.value);
        require(msg.value >= 0.001 ether);
        
        // Fee to advisors
        if (now > 1541001599 && payAdvisorFlag == 0) {
            payAdvisorFlag = payAdvisorFlag + 1;
            uint256 advfee = this.balance.div(20) + this.balance.div(100);  // = 6.0 %, Not float in Solidity, So use INT/div to approach. 
            if (advfee > 0) {
                advisor.transfer(advfee);   // Prevent using call() or send()
            }
            AdviseFee(advisor, advfee);
            return true;
        }
        else {
            return false;
        }
    }

    // gets called when no other function matches
    function () payable public {
        if (msg.value > 0) {
            buy();
        }
    }

    function execute(address _to, uint256 _value, string _extra) mostOwner(keccak256(msg.data)) external returns (bool){
        require(_to != address(0));
        _to.transfer(_value);   // Prevent using call() or send()
        Withdraw(_to, _value, msg.sender, _extra);
        return true;
    }

}