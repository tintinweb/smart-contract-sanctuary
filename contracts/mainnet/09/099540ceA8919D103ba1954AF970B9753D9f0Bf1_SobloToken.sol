pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

    /**
     * Returns whether the target address is a contract
     * dev This function will return false if invoked during the constructor of a contract,
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
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
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
        require(_to != address(0), "Recipient address is zero address(0). Check the address again.");
        require(_value <= balances[msg.sender], "The balance of account is insufficient.");

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
        require(_to != address(0), "Recipient address is zero address(0). Check the address again.");
        require(_value <= balances[_from], "The balance of account is insufficient.");
        require(_value <= allowed[_from][msg.sender], "Insufficient tokens approved from account owner.");

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
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
 * @title MultiOwnable
 * @dev root -> superOwner -> owners 의 형태로 관리하는 멀티 관리자 기능
 */
contract MultiOwnable {
    using SafeMath for uint256;

    address public root; // 혹시 몰라 준비해둔 superOwner 의 백업. 하드웨어 월렛 주소로 세팅할 예정.
    address public superOwner;
    mapping (address => bool) public owners;
    address[] public ownerList;

    event ChangedRoot(address newRoot);
    event ChangedSuperOwner(address newSuperOwner);
    event AddedNewOwner(address newOwner);
    event DeletedOwner(address deletedOwner);

    constructor() public {
        root = msg.sender;
        superOwner = msg.sender;
        owners[root] = true;

        ownerList.push(msg.sender);
    }

    modifier onlyRoot() {
        require(msg.sender == root, "Root privilege is required.");
        _;
    }

    modifier onlySuperOwner() {
        require(msg.sender == superOwner, "SuperOwner priviledge is required.");
        _;
    }

    modifier onlyOwner() {
        require(owners[msg.sender], "Owner priviledge is required.");
        _;
    }

    /**
     * @dev root 교체 (root 는 root 와 superOwner 를 교체할 수 있는 권리가 있다.)
     * @dev 기존 루트가 관리자에서 지워지지 않고, 새 루트가 자동으로 관리자에 등록되지 않음을 유의!
     */
    function changeRoot(address newRoot) onlyRoot public returns (bool) {
        require(newRoot != address(0), "This address to be set is zero address(0). Check the input address.");

        root = newRoot;

        emit ChangedRoot(newRoot);
        return true;
    }

    /**
     * @dev superOwner 교체 (root 는 root 와 superOwner 를 교체할 수 있는 권리가 있다.)
     * @dev 기존 superOwner 가 관리자에서 지워지지 않고, 새 superOwner 가 자동으로 관리자에 등록되지 않음을 유의!
     */
    function changeSuperOwner(address newSuperOwner) onlyRoot public returns (bool) {
        require(newSuperOwner != address(0), "This address to be set is zero address(0). Check the input address.");

        superOwner = newSuperOwner;

        emit ChangedSuperOwner(newSuperOwner);
        return true;
    }


    function newOwner(address owner) onlySuperOwner public returns (bool) {
        require(owner != address(0), "This address to be set is zero address(0). Check the input address.");
        require(!owners[owner], "This address is already registered.");

        owners[owner] = true;
        ownerList.push(owner);

        emit AddedNewOwner(owner);
        return true;
    }

    function deleteOwner(address owner) onlySuperOwner public returns (bool) {
        require(owners[owner], "This input address is not an owner.");
        delete owners[owner];

        for (uint256 i = 0; i < ownerList.length; i++) {
            if (ownerList[i] == owner) {
                ownerList[i] = ownerList[ownerList.length.sub(1)];
                ownerList.length = ownerList.length.sub(1);
                break;
            }
        }

        emit DeletedOwner(owner);
        return true;
    }
}

/**
 * @title Lockable token
 */
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
        unlockTo(msg.sender,  "Default Unlock To Root");
    }

    modifier checkUnlock (address addr, uint256 value) {
        require(!locked || unlockAddrs[addr], "The account is currently locked.");
        require(balances[addr].sub(value) >= lockValues[addr], "Transferable limit exceeded. Check the status of the lock value.");
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
        if ((!locked || unlockAddrs[addr]) && balances[addr] > lockValues[addr])
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
 * @title SobloTokenReceiver Receiver
 */
contract SobloTokenReceiver {
    enum SobloTokenReceiveType { TOKEN_TRANSFER, TOKEN_MINT }
    function onSobloTokenReceived(address owner, address spender, uint256 value, SobloTokenReceiveType receiveType) public returns (bool);
}


/**
 * @title SobloToken
 */
contract SobloToken is LockableToken {
    using AddressUtils for address;
    
    enum SobloTransferType {
        TRANSFER_TO_TEAM, 
        TRANSFER_TO_PARTNER, 
        TRANSFER_TO_ECOSYSTEM, 
        TRANSFER_TO_BOUNTY, 
        TRANSFER_TO_RESERVE, 
        TRANSFER_TO_ETC 
    }
    
    event SobloTransferred(address indexed from, address indexed to, uint256 value, uint256 fromBalance, uint256 toBalance, string note);
    event SobloTransferredFrom(address indexed owner, address indexed spender, address indexed to, uint256 value, uint256 fromBalance, uint256 toBalance, string note);
    event SobloApproval(address indexed owner, address indexed spender, uint256 value, string note);
 
    
    event SobloMultiTransferred(address indexed owner, address indexed spender, address indexed to, uint256 value, SobloTransferType purpose, uint256 fromBalance, uint256 toBalance, string note);

    event TransferredToSobloDapp(
        address indexed owner,
        address indexed spender,
        address indexed to, 
        uint256 value, 
        string note, 
        SobloTokenReceiver.SobloTokenReceiveType receiveType
    );

    constructor() public {
	}


    // ERC20 함수들을 오버라이딩하여 super 로 올라가지 않고 무조건 soblo~ 함수로 지나가게 한다.
    function transfer(address to, uint256 value) public returns (bool ret) {
        return sobloTransfer(to, value, "called by transfer()");
    }

    function sobloTransfer(address to, uint256 value, string note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of Soblo Token. You cannot send money to this address.");

        ret = super.transfer(to, value);
        postTransfer(msg.sender, msg.sender, to, value, note, SobloTokenReceiver.SobloTokenReceiveType.TOKEN_TRANSFER);
        
        emit SobloTransferred(msg.sender, to, value, balanceOf(msg.sender), balanceOf(to), note);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return sobloTransferFrom(from, to, value, "called by transferFrom()");
    }

    function sobloTransferFrom(address from, address to, uint256 value, string note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of Soblo Token. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        postTransfer(from, msg.sender, to, value, note, SobloTokenReceiver.SobloTokenReceiveType.TOKEN_TRANSFER);

        emit SobloTransferredFrom(from, msg.sender, to, value, balanceOf(from), balanceOf(to), note);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        return sobloApprove(spender, value, "called by approve()");
    }

    function sobloApprove(address spender, uint256 value, string note) public returns (bool ret) {
        ret = super.approve(spender, value);
        emit SobloApproval(msg.sender, spender, value, note);
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        return sobloIncreaseApproval(spender, addedValue, "called by increaseApproval()");
    }

    function sobloIncreaseApproval(address spender, uint256 addedValue, string note) public returns (bool ret) {
        ret = super.increaseApproval(spender, addedValue);
        emit SobloApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        return sobloDecreaseApproval(spender, subtractedValue, "called by decreaseApproval()");
    }

    function sobloDecreaseApproval(address spender, uint256 subtractedValue, string note) public returns (bool ret) {
        ret = super.decreaseApproval(spender, subtractedValue);
        emit SobloApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }


    
    function postTransfer(
        address owner, 
        address spender,
        address to,
        uint256 value,
        string note,
        SobloTokenReceiver.SobloTokenReceiveType receiveType
    ) internal returns (bool) {
        if (to.isContract()) {
            bool callOk = address(to).call(
                bytes4(keccak256("onSobloTokenReceived(address,address,uint256,uint8)")),
                owner,
                spender,
                value,
                receiveType
            );
            if (callOk) {
                emit TransferredToSobloDapp(owner, spender, to, value, note, receiveType);
                return true;
            }
        }
        
        return false;
    }    

    /**
     * @dev 다계좌 전송 (postTransfer 를 호출하지 않음에 유의!)
     * 
     * @param from 보낼 토큰의 주인 (내부적으로 transferFrom 을 이용함)
     * @param to 토큰을 받을 주소
     * @param purpose 팀에게 보내기, 파트너에게 보내기, 바운티 참여자에게 보내기 등의 목적을 선택
     * @param note 일반적인 메모
     */ 
    function sobloMultiTransfer(
        address from, address[] to,
        uint256[] values,
        SobloTransferType purpose,
        string note
    ) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length, "The size of \'to\' and \'values\' array is different.");
        require(uint8(purpose) < 6);

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of Soblo Token. You cannot send money to this address.");

            ret = ret && super.transferFrom(from, to[i], values[i]); // 관리자 기능으로 post 프로세스(댑의 onReceived 를 일깨움)를 타지 않기 위해 super.transferFrom 를 호출한다.
            emit SobloMultiTransferred(from, msg.sender, to[i], values[i], purpose, balanceOf(from), balanceOf(to[i]), note);
        }
    }

    function destroy() onlyRoot public {
        selfdestruct(root);
    }
    
    
    
}




/**
 * @title SobloTokenDappBase
 */
contract SobloTokenDappBase is SobloTokenReceiver {
    address internal _sobloToken;
    event LogOnReceivedSobloToken(address indexed owner, address indexed spender, uint256 value, SobloTokenReceiveType receiveType);

    constructor(address sobloToken) public {
        _sobloToken = sobloToken;
    }
    
    modifier onlySobloToken() {
        require(msg.sender == _sobloToken, "msg.sender must be the registered token contract");
        _;
    }
    
    // Override this function
    function onSobloTokenReceived(address owner, address spender, uint256 value, SobloTokenReceiveType receiveType)
        public onlySobloToken returns (bool)
    {
        emit LogOnReceivedSobloToken(owner, spender, value, receiveType);
    }
}