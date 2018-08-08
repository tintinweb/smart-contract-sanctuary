pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

/**
 * @title MultiOwnable
 * @dev 
 */
contract MultiOwnable {
    address public root;
    mapping (address => bool) public owners;
    
    constructor() public {
        root = msg.sender;
        owners[root] = true;
    }
    
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }
    
    modifier onlyRoot() {
        require(msg.sender == root);
        _;
    }
    
    function newOwner(address owner) onlyRoot public returns (bool) {
        require(owner != address(0));
        
        owners[owner] = true;
        return true;
    }
    
    function deleteOwner(address owner) onlyRoot public returns (bool) {
        require(owner != root);
        
        delete owners[owner];
        return true;
    }
}

/**
 * @title Lockable token
 **/
contract LockableToken is StandardToken, MultiOwnable {
    bool public locked = true;
    uint256 public constant LOCK_MAX = uint256(-1);
    
    /**
     * @dev 락 상태에서도 거래 가능한 언락 계정
     */
    mapping(address => bool) public unlockAddrs;
    
    /**
     * @dev 계정 별로 lock value 만큼 잔고가 잠김
     * @dev - 값이 0 일 때 : 잔고가 0 이어도 되므로 제한이 없는 것임.
     * @dev - 값이 LOCK_MAX 일 때 : 잔고가 uint256 의 최대값이므로 아예 잠긴 것임.
     */
    mapping(address => uint256) public lockValues;
    
    event Locked(bool locked, string note);
    event LockedTo(address indexed addr, bool locked, string note);
    event SetLockValue(address indexed addr, uint256 value, string note);
    
    constructor() public {
        unlockTo(msg.sender, "");
    }
    
    modifier checkUnlock (address addr, uint256 value) {
        require(!locked || unlockAddrs[addr]);
        require(balances[addr].sub(value) >= lockValues[addr]);
        _;
    }
    
    function lock(string note) onlyOwner public {
        locked = true;  
        emit Locked(locked, note);
    }
    
    function unlock(string note) onlyOwner public {
        locked = false;
        emit Locked(locked, note);
    }
    
    function lockTo(address addr, string note) onlyOwner public {
        require(addr != root);
        
        setLockValue(addr, LOCK_MAX, note);
        unlockAddrs[addr] = false;
        
        emit LockedTo(addr, true, note);
    }
    
    function unlockTo(address addr, string note) onlyOwner public {
        if (lockValues[addr] == LOCK_MAX)
            setLockValue(addr, 0, note);
        unlockAddrs[addr] = true;
        
        emit LockedTo(addr, false, note);
    }
    
    function setLockValue(address addr, uint256 value, string note) onlyOwner public {
        lockValues[addr] = value;
        emit SetLockValue(addr, value, note);
    }
    
    /**
     * @dev 이체 가능 금액을 조회한다.
     */ 
    function getMyUnlockValue() public view returns (uint256) {
        address addr = msg.sender;
        if ((!locked || unlockAddrs[addr]) && balances[addr] >= lockValues[addr])
            return balances[addr].sub(lockValues[addr]);
        else
            return 0;
    }
    
    function transfer(address to, uint256 value) checkUnlock(msg.sender, value) public returns (bool) {
        return super.transfer(to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) checkUnlock(from, value) public returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

/**
 * @title KSCBaseToken
 * @dev 트랜잭션 실행 시 메모를 남길 수 있도록 하였음.
 */
contract KSCBaseToken is LockableToken {
    using AddressUtils for address;
    
    event KSCTransfer(address indexed from, address indexed to, uint256 value, string note);
    event KSCTransferFrom(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event KSCApproval(address indexed owner, address indexed spender, uint256 value, string note);

    event KSCMintTo(address indexed controller, address indexed to, uint256 amount, string note);
    event KSCBurnFrom(address indexed controller, address indexed from, uint256 value, string note);

    event KSCBurnWhenMoveToMainnet(address indexed controller, address indexed from, uint256 value, string note);
    event KSCBurnWhenUseInSidechain(address indexed controller, address indexed from, uint256 value, string note);

    event KSCSell(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event KSCSellByOtherCoin(address indexed owner, address indexed spender, address indexed to, uint256 value,  uint256 processIdHash, uint256 userIdHash, string note);

    event KSCTransferToEcosystem(address indexed owner, address indexed spender, address indexed to, uint256 value, uint256 processIdHash, uint256 userIdHash, string note);
    event KSCTransferToBounty(address indexed owner, address indexed spender, address indexed to, uint256 value, uint256 processIdHash, uint256 userIdHash, string note);

    // ERC20 함수들을 오버라이딩하여 super 로 올라가지 않고 무조건 ksc~ 함수로 지나가게 한다.
    function transfer(address to, uint256 value) public returns (bool ret) {
        return kscTransfer(to, value, "");
    }
    
    function kscTransfer(address to, uint256 value, string note) public returns (bool ret) {
        require(to != address(this));
        
        ret = super.transfer(to, value);
        emit KSCTransfer(msg.sender, to, value, note);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return kscTransferFrom(from, to, value, "");
    }
    
    function kscTransferFrom(address from, address to, uint256 value, string note) public returns (bool ret) {
        require(to != address(this));
        
        ret = super.transferFrom(from, to, value);
        emit KSCTransferFrom(from, msg.sender, to, value, note);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        return kscApprove(spender, value, "");
    }
    
    function kscApprove(address spender, uint256 value, string note) public returns (bool ret) {
        ret = super.approve(spender, value);
        emit KSCApproval(msg.sender, spender, value, note);
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        return kscIncreaseApproval(spender, addedValue, "");
    }

    function kscIncreaseApproval(address spender, uint256 addedValue, string note) public returns (bool ret) {
        ret = super.increaseApproval(spender, addedValue);
        emit KSCApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        return kscDecreaseApproval(spender, subtractedValue, "");
    }

    function kscDecreaseApproval(address spender, uint256 subtractedValue, string note) public returns (bool ret) {
        ret = super.decreaseApproval(spender, subtractedValue);
        emit KSCApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    /**
     * @dev 신규 화폐 발행. 반드시 이유를 메모로 남겨라.
     */
    function mintTo(address to, uint256 amount) internal returns (bool) {
        require(to != address(0x0));

        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);
        
        emit Transfer(address(0), to, amount);
        return true;
    }
    
    function kscMintTo(address to, uint256 amount, string note) onlyOwner public returns (bool ret) {
        ret = mintTo(to, amount);
        emit KSCMintTo(msg.sender, to, amount, note);
    }

    /**
     * @dev 화폐 소각. 반드시 이유를 메모로 남겨라.
     */
    function burnFrom(address from, uint256 value) internal returns (bool) {
        require(value <= balances[from]);
        
        balances[from] = balances[from].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        
        emit Transfer(from, address(0), value);
        return true;        
    }
    
    function kscBurnFrom(address from, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = burnFrom(from, value);
        emit KSCBurnFrom(msg.sender, from, value, note);
    }

    /**
     * @dev 메인넷으로 이동하며 화폐 소각.
     */
    function kscBurnWhenMoveToMainnet(address burner, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = burnFrom(burner, value);
        emit KSCBurnWhenMoveToMainnet(msg.sender, burner, value, note);
    }
    
    function kscBatchBurnWhenMoveToMainnet(address[] burners, uint256[] values, string note) onlyOwner public returns (bool ret) {
        uint256 length = burners.length;
        require(length == values.length);
        
        ret = true;
        for (uint256 i = 0; i < length; i++) {
            ret = ret && kscBurnWhenMoveToMainnet(burners[i], values[i], note);
        }
    }

    /**
     * @dev 사이드체인에서 사용하여 화폐 소각.
     */
    function kscBurnWhenUseInSidechain(address burner, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = burnFrom(burner, value);
        emit KSCBurnWhenUseInSidechain(msg.sender, burner, value, note);
    }

    function kscBatchBurnWhenUseInSidechain(address[] burners, uint256[] values, string note) onlyOwner public returns (bool ret) {
        uint256 length = burners.length;
        require(length == values.length);
        
        ret = true;
        for (uint256 i = 0; i < length; i++) {
            ret = ret && kscBurnWhenUseInSidechain(burners[i], values[i], note);
        }
    }

    /**
     * @dev 이더로 KSC 를 구입하는 경우
     */
    function kscSell(address from, address to, uint256 value, string note) onlyOwner public returns (bool ret) {
        require(to != address(this));        

        ret = super.transferFrom(from, to, value);
        emit KSCSell(from, msg.sender, to, value, note);
    }
    
    /**
     * @dev 비트코인 등의 다른 코인으로 KSC 를 구입하는 경우
     * @dev EOA 가 트랜잭션을 일으켜서 처리해야 하기 때문에 다계좌를 기준으로 한다. (가스비 아끼기 위함)
     */
    function kscBatchSellByOtherCoin(address from, address[] to, uint256[] values, uint256 processIdHash, uint256[] userIdHash, string note) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length);
        require(length == userIdHash.length);
        
        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this));            
            
            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit KSCSellByOtherCoin(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }
    
    /**
     * @dev 에코시스템(커뮤니티 활동을 통한 보상 등)으로 KSC 지급
     * @dev EOA 가 트랜잭션을 일으켜서 처리해야 하기 때문에 다계좌를 기준으로 한다. (가스비 아끼기 위함)
     */
    function kscBatchTransferToEcosystem(address from, address[] to, uint256[] values, uint256 processIdHash, uint256[] userIdHash, string note) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length);
        require(length == userIdHash.length);

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this));            
            
            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit KSCTransferToEcosystem(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

    /**
     * @dev 바운티 참여자에게 KSC 지급
     * @dev EOA 가 트랜잭션을 일으켜서 처리해야 하기 때문에 다계좌를 기준으로 한다. (가스비 아끼기 위함)
     */
    function kscBatchTransferToBounty(address from, address[] to, uint256[] values, uint256 processIdHash, uint256[] userIdHash, string note) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(to.length == values.length);

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this));            
            
            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit KSCTransferToBounty(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

    function destroy() onlyRoot public {
        selfdestruct(root);
    }
}

/**
 * @title KStarCoin
 */
contract KStarCoin is KSCBaseToken {
    using AddressUtils for address;
    
    string public constant name = "KStarCoin";
    string public constant symbol = "KSC";
    uint8 public constant decimals = 18;
    
    uint256 public constant INITIAL_SUPPLY = 1e9 * (10 ** uint256(decimals));
    
    bytes4 internal constant KSC_RECEIVED = 0xe6947547; // KSCReceiver.onKSCReceived.selector
    
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    
    function kscTransfer(address to, uint256 value, string note) public returns (bool ret) {
        ret = super.kscTransfer(to, value, note);
        require(postTransfer(msg.sender, msg.sender, to, value, KSCReceiver.KSCReceiveType.KSC_TRANSFER));
    }
    
    function kscTransferFrom(address from, address to, uint256 value, string note) public returns (bool ret) {
        ret = super.kscTransferFrom(from, to, value, note);
        require(postTransfer(from, msg.sender, to, value, KSCReceiver.KSCReceiveType.KSC_TRANSFER));
    }
    
    function postTransfer(address owner, address spender, address to, uint256 value, KSCReceiver.KSCReceiveType receiveType) internal returns (bool) {
        if (!to.isContract())
            return true;
        
        bytes4 retval = KSCReceiver(to).onKSCReceived(owner, spender, value, receiveType);
        return (retval == KSC_RECEIVED);
    }
    
    function kscMintTo(address to, uint256 amount, string note) onlyOwner public returns (bool ret) {
        ret = super.kscMintTo(to, amount, note);
        require(postTransfer(0x0, msg.sender, to, amount, KSCReceiver.KSCReceiveType.KSC_MINT));
    }
    
    function kscBurnFrom(address from, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = super.kscBurnFrom(from, value, note);
        require(postTransfer(0x0, msg.sender, from, value, KSCReceiver.KSCReceiveType.KSC_BURN));
    }
}


/**
 * @title KStarCoin Receiver
 */ 
contract KSCReceiver {
    bytes4 internal constant KSC_RECEIVED = 0xe6947547; // this.onKSCReceived.selector
    enum KSCReceiveType { KSC_TRANSFER, KSC_MINT, KSC_BURN }
    
    function onKSCReceived(address owner, address spender, uint256 value, KSCReceiveType receiveType) public returns (bytes4);
}

/**
 * @title KSCDappSample 
 */
contract KSCDappSample is KSCReceiver {
    event LogOnReceiveKSC(string message, address indexed owner, address indexed spender, uint256 value, KSCReceiveType receiveType);
    
    function onKSCReceived(address owner, address spender, uint256 value, KSCReceiveType receiveType) public returns (bytes4) {
        emit LogOnReceiveKSC("I receive KstarCoin.", owner, spender, value, receiveType);
        
        return KSC_RECEIVED; // must return this value if successful
    }
}