pragma solidity ^0.4.24;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}



    /**
    * @title Basic token
    * @dev Basic version of StandardToken, with no allowances.
    */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract MultiOwnable {
    address public hiddenOwner;
    address public superOwner;
    address public tokenExchanger;
    address[10] public chkOwnerList;

    mapping (address => bool) public owners;
    
    event AddOwner(address indexed newOwner);
    event DeleteOwner(address indexed toDeleteOwner);
    event SetTex(address indexed newTex);
    event ChangeSuperOwner(address indexed newSuperOwner);
    event ChangeHiddenOwner(address indexed newHiddenOwner);

    constructor() public {
        hiddenOwner = msg.sender;
        superOwner = msg.sender;
        owners[superOwner] = true;
        chkOwnerList[0] = msg.sender;
        tokenExchanger = msg.sender;
    }

    modifier onlySuperOwner() {
        require(superOwner == msg.sender);
        _;
    }
    modifier onlyHiddenOwner() {
        require(hiddenOwner == msg.sender);
        _;
    }
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    function changeSuperOwnership(address newSuperOwner) public onlyHiddenOwner returns(bool) {
        require(newSuperOwner != address(0));
        superOwner = newSuperOwner;
        emit ChangeSuperOwner(superOwner);
        return true;
    }
    
    function changeHiddenOwnership(address newHiddenOwner) public onlyHiddenOwner returns(bool) {
        require(newHiddenOwner != address(0));
        hiddenOwner = newHiddenOwner;
        emit ChangeHiddenOwner(hiddenOwner);
        return true;
    }

    function addOwner(address owner, uint8 num) public onlySuperOwner returns (bool) {
        require(num < 10);
        require(owner != address(0));
        require(chkOwnerList[num] == address(0));
        owners[owner] = true;
        chkOwnerList[num] = owner;
        emit AddOwner(owner);
        return true;
    }

    function setTEx(address tex) public onlySuperOwner returns (bool) {
        require(tex != address(0));
        tokenExchanger = tex;
        emit SetTex(tex);
        return true;
    }

    function deleteOwner(address owner, uint8 num) public onlySuperOwner returns (bool) {
        require(chkOwnerList[num] == owner);
        require(owner != address(0));
        owners[owner] = false;
        chkOwnerList[num] = address(0);
        emit DeleteOwner(owner);
        return true;
    }
}

contract HasNoEther is MultiOwnable {
    
    /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
    constructor() public payable {
        require(msg.value == 0);
    }
    
    /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
    function() external {
    }
    
    /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
    function reclaimEther() external onlySuperOwner returns(bool) {
        superOwner.transfer(address(this).balance);

        return true;
    }
}

contract Blacklist is MultiOwnable {
   
    mapping(address => bool) blacklisted;
    
    event Blacklisted(address indexed blacklist);
    event Whitelisted(address indexed whitelist);

    modifier whenPermitted(address node) {
        require(!blacklisted[node]);
        _;
    }
    
    /**
    * @dev Check a certain node is in a blacklist
    * @param node  Check whether the user at a certain node is in a blacklist
    */
    function isPermitted(address node) public view returns (bool) {
        return !blacklisted[node];
    }

    /**
    * @dev Process blacklisting
    * @param node Process blacklisting. Put the user in the blacklist.   
    */
    function blacklist(address node) public onlyOwner returns (bool) {
        blacklisted[node] = true;
        emit Blacklisted(node);

        return blacklisted[node];
    }

    /**
    * @dev Process unBlacklisting. 
    * @param node Remove the user from the blacklist.   
    */
    function unblacklist(address node) public onlySuperOwner returns (bool) {
        blacklisted[node] = false;
        emit Whitelisted(node);

        return blacklisted[node];
    }
}

contract TimelockToken is StandardToken, HasNoEther, Blacklist {
    bool public timelock;
    uint256 public openingTime;

    struct chkBalance {
        uint256 _sent;
        uint256 _initial;
        uint256 _limit;
    }

    mapping(address => bool) public p2pAddrs;
    mapping(address => chkBalance) public chkInvestorBalance;
    
    event Postcomplete(address indexed _from, address indexed _spender, address indexed _to, uint256 _value);
    event OnTimeLock(address who);
    event OffTimeLock(address who);
    event P2pUnlocker(address addr);
    event P2pLocker(address addr);
    

    constructor() public {
        openingTime = block.timestamp;
        p2pAddrs[msg.sender] = true;
        timelock = false;
    }

    function postTransfer(address from, address spender, address to, uint256 value) internal returns (bool) {
        emit Postcomplete(from, spender, to, value);
        return true;
    }
    
    function p2pUnlocker (address addr) public onlySuperOwner returns (bool) {
        p2pAddrs[addr] = true;
        
        emit P2pUnlocker(addr);

        return p2pAddrs[addr];
    }

    function p2pLocker (address addr) public onlyOwner returns (bool) {
        p2pAddrs[addr] = false;
        
        emit P2pLocker(addr);

        return p2pAddrs[addr];
    }

    function onTimeLock() public onlySuperOwner returns (bool) {
        timelock = true;
        
        emit OnTimeLock(msg.sender);
        
        return timelock;
    }

    function offTimeLock() public onlySuperOwner returns (bool) {
        timelock = false;
        
        emit OffTimeLock(msg.sender);
        
        return timelock;
    }
  
    function transfer(address to, uint256 value) public 
    whenPermitted(msg.sender) returns (bool) {
        
        bool ret;
        
        if (!timelock) { // phase 1
            
            require(p2pAddrs[msg.sender]);
            ret = super.transfer(to, value);
        } else { // phase 2
            if (owners[msg.sender]) {
                require(p2pAddrs[msg.sender]);
                
                uint _totalAmount = balances[to].add(value);
                chkInvestorBalance[to] = chkBalance(0,_totalAmount,_totalAmount.div(5));
                ret = super.transfer(to, value);
            } else {
                require(!p2pAddrs[msg.sender] && to == tokenExchanger);
                require(_timeLimit() > 0);
                
                if (chkInvestorBalance[msg.sender]._initial == 0) { // first transfer
                    uint256 new_initial = balances[msg.sender];
                    chkInvestorBalance[msg.sender] = chkBalance(0, new_initial, new_initial.div(5));
                }
                
                uint256 addedValue = chkInvestorBalance[msg.sender]._sent.add(value);
                require(addedValue <= _timeLimit().mul(chkInvestorBalance[msg.sender]._limit));
                chkInvestorBalance[msg.sender]._sent = addedValue;
                ret = super.transfer(to, value);
            }
        }
        if (ret) 
            return postTransfer(msg.sender, msg.sender, to, value);
        else
            return false;
    }

    function transferFrom(address from, address to, uint256 value) public 
    whenPermitted(msg.sender) returns (bool) {
        require (owners[msg.sender] && p2pAddrs[msg.sender]);
        require (timelock);
        
        if (owners[from]) {
            uint _totalAmount = balances[to].add(value);
            chkInvestorBalance[to] = chkBalance(0,_totalAmount,_totalAmount.div(5));
        } else {
            require (owners[to] || to == tokenExchanger);
            
            if (chkInvestorBalance[from]._initial == 0) { // first transfer
                uint256 new_initial = balances[from];
                chkInvestorBalance[from] = chkBalance(0, new_initial, new_initial.div(5));
            }

            uint256 addedValue = chkInvestorBalance[from]._sent.add(value);
            require(addedValue <= _timeLimit().mul(chkInvestorBalance[from]._limit));
            chkInvestorBalance[from]._sent = addedValue;
        }
        
        bool ret = super.transferFrom(from, to, value);
        
        if (ret) 
            return postTransfer(from, msg.sender, to, value);
        else
            return false;
    }

    function _timeLimit() internal view returns (uint256) {
        uint256 presentTime = block.timestamp;
        uint256 timeValue = presentTime.sub(openingTime);
        uint256 _result = timeValue.div(31 days);

        return _result;
    }

    function setOpeningTime() public onlySuperOwner returns(bool) {
        openingTime = block.timestamp;
        return true;
    }

    function getLimitPeriod() external view returns (uint256) {
        uint256 presentTime = block.timestamp;
        uint256 timeValue = presentTime.sub(openingTime);
        uint256 result = timeValue.div(31 days);
        return result;
    }

}

/**
 * Utility library of inline functions on addresses
 */
library Address {

    /**
    * Returns whether the target address is a contract
    * @dev This function will return false if invoked during the constructor of a contract,
    * as the code is not actually created until after the constructor finishes.
    * @param account address of the account to check
    * @return whether the target address is a contract
    */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}



contract luxbio_bio is TimelockToken {
    using Address for address;
    
    event Burn(address indexed burner, uint256 value);
    
    string public constant name = "LB-COIN";
    uint8 public constant decimals = 18;
    string public constant symbol = "LB";
    uint256 public constant INITIAL_SUPPLY = 1e10 * (10 ** uint256(decimals)); 

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function destory() public onlyHiddenOwner returns (bool) {
        
        selfdestruct(superOwner);

        return true;

    }

    function burn(address _to,uint256 _value) public onlySuperOwner {
        _burn(_to, _value);
    }

    function _burn(address _who, uint256 _value) internal {     
        require(_value <= balances[_who]);
    
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
    
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
  
    // override
    function postTransfer(address from, address spender, address to, uint256 value) internal returns (bool) {
        if (to == tokenExchanger && to.isContract()) {
            emit Postcomplete(from, spender, to, value);
            return luxbio_dapp(to).doExchange(from, spender, to, value);
        }
        return true;
    }
}
contract luxbio_dapp {
    function doExchange(address from, address spender, address to, uint256 value) public returns (bool);
    event DoExchange(address indexed from, address indexed _spender, address indexed _to, uint256 _value);
}