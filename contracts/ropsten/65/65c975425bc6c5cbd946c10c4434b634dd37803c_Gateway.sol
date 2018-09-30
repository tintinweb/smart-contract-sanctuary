pragma solidity ^0.4.24;


/**
 * @title Owned
 */
contract Owned {
    address public owner;
    address public newOwner;
    mapping (address => bool) public admins;

    event OwnershipTransferred(
        address indexed _from, 
        address indexed _to
    );

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmins {
        require(admins[msg.sender]);
        _;
    }

    function transferOwnership(address _newOwner) 
        public 
        onlyOwner 
    {
        newOwner = _newOwner;
    }

    function acceptOwnership() 
        public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function addAdmin(address _admin) 
        onlyOwner 
        public 
    {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) 
        onlyOwner 
        public 
    {
        delete admins[_admin];
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() 
        onlyAdmins 
        whenNotPaused 
        public 
    {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() 
        onlyAdmins 
        whenPaused 
        public 
    {
        paused = false;
        emit Unpause();
    }
}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        /**
         * @dev Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
         * benefit is lost if &#39;b&#39; is also tested.
         * See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
         */
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Gateway
 * @dev player recharge TAT to dappchain and withdraw TAT from dappchain
 * @dev only support recharge once a period.
 */
contract Gateway is Pausable {
    using SafeMath for uint256;

    event Recharge(address indexed _user, uint256 indexed tatAmount);
    event Withdraw(address indexed _user, uint256 indexed tatAmount);
    event BackTo(address indexed _user, uint256 indexed tatAmount);

    address ERC20address;
    uint256 public lockTime = 1 days;
    mapping (address  => locker) lockers;

    struct locker{
        uint256 unlockTime;
        uint256 balance;
        bytes32 hashStr;
        address to;
    }


    constructor() public {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    function setTatAddress(address _address)
        public
        onlyAdmins
    {
        ERC20address = _address;
    }

    function setLockTime(uint256 _time)
        public
        onlyAdmins
    {
        lockTime = _time;
    }


    /**
     * @dev Hashed Timelock Contracts
     */
    function recharge(bytes32 _hash, uint256 _token, address _to) 
        public
        whenNotPaused
    {
        require(ERC20address != address(0), "Not nitialize");
        ERC20Interface token = ERC20Interface(ERC20address);

        if(token.transferFrom(msg.sender, address(this), _token)) {
            lockers[msg.sender].unlockTime = now.add(lockTime);
            lockers[msg.sender].balance = _token;
            lockers[msg.sender].hashStr = _hash;
            lockers[msg.sender].to = _to;
        }

        emit Recharge(msg.sender, _token);
    }

/*
    function recharge(address _addr, uint256 _amount)
        public
        onlyAdmins
    {
        blance[_addr] = blance[_addr].add(_amount);
        emit Recharge(_addr, _amount);
    }
*/
    function withdrawTo(string _key, address _addr)
        public
        whenNotPaused
    {
        bytes32 _hash = keccak256(abi.encodePacked(_key));
        require(_hash == lockers[_addr].hashStr, "key error");
        require(now < lockers[_addr].unlockTime, "unlocked");
        
        ERC20Interface token = ERC20Interface(ERC20address);

        if(token.transfer(lockers[_addr].to, lockers[_addr].balance)) {
            delete lockers[_addr];
        }

        emit Withdraw(lockers[_addr].to, lockers[_addr].balance);
    }


    function backTo(address _from)
        public
        whenNotPaused
    {
        require(lockers[_from].unlockTime >= now, "locked");
        
        ERC20Interface token = ERC20Interface(ERC20address);
        
        if(token.transfer(_from, lockers[_from].balance)) {
            delete lockers[msg.sender];
        }

        emit BackTo(msg.sender, lockers[msg.sender].balance);
    }
   
/*
    function withdraw(address _addr, uint256 _amount)
        public
        onlyAdmins
    {
        require(blance[_addr] >= _amount);

        ERC20Interface token = ERC20Interface(ERC20address);
        token.transfer(_addr, _amount);
        blance[_addr] = blance[_addr].sub(_amount);

        emit Withdraw(_addr, _amount);
    }

    function withdrawTatAmount(uint256 _amount)
        public
        onlyOwner
        whenNotPaused
    {
        ERC20Interface token = ERC20Interface(ERC20address);
        token.transfer(msg.sender, _amount);    
    }

    function withdrawAll()
        public
        onlyOwner
        whenNotPaused
    {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawAmount(uint256 _amount)
        public
        onlyOwner
        whenNotPaused
    {
        msg.sender.transfer(_amount);
    }
*/
    function blanceOf(address _addr)
        public
        view
        returns (uint256)
    {
        return lockers[_addr].balance;
    }

    function getHashOf(address _addr)
        public
        view
        returns (bytes32)
    {   
        return  lockers[_addr].hashStr;
    }

    function getUnlockTime(address _addr)
        public
        view
        returns (uint256)
    {
        uint256 _time = lockers[_addr].unlockTime;
        require(_time > now, "end time");

        return _time.sub(now); 
    }

}

interface ERC20Interface {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}