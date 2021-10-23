/**
 *Submitted for verification at polygonscan.com on 2021-10-22
*/

pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * dev Simpler version of ERC20 interface
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
 * dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Basic token
 * dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * dev Transfer token for a specified address
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
    * dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

/**
 * @title ERC20 interface
 * dev see https://github.com/ethereum/EIPs/issues/20
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
 * dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * dev Transfer tokens from one address to another
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
     * dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
     * dev Function to check the amount of tokens that an owner allowed to a spender.
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
     * dev Increase the amount of tokens that an owner allowed to a spender.
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
     * dev Decrease the amount of tokens that an owner allowed to a spender.
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
 * @title MultiOwnable
 * dev
 */
contract MultiOwnable {
    using SafeMath for uint256;

    address public root; // 혹시 몰라 준비해둔 superOwner 의 백업. 하드웨어 월렛 주소로 세팅할 예정.
    address public superOwner;
    mapping (address => bool) public owners;
    address[] public ownerList;

    // for changeSuperOwnerByDAO
    // mapping(address => mapping (address => bool)) public preSuperOwnerMap;
    mapping(address => address) public candidateSuperOwnerMap;


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
     * dev root 교체 (root 는 root 와 superOwner 를 교체할 수 있는 권리가 있다.)
     * dev 기존 루트가 관리자에서 지워지지 않고, 새 루트가 자동으로 관리자에 등록되지 않음을 유의!
     */
    function changeRoot(address newRoot) onlyRoot public returns (bool) {
        require(newRoot != address(0), "This address to be set is zero address(0). Check the input address.");

        root = newRoot;

        emit ChangedRoot(newRoot);
        return true;
    }

    /**
     * dev superOwner 교체 (root 는 root 와 superOwner 를 교체할 수 있는 권리가 있다.)
     * dev 기존 superOwner 가 관리자에서 지워지지 않고, 새 superOwner 가 자동으로 관리자에 등록되지 않음을 유의!
     */
    function changeSuperOwner(address newSuperOwner) onlyRoot public returns (bool) {
        require(newSuperOwner != address(0), "This address to be set is zero address(0). Check the input address.");

        superOwner = newSuperOwner;

        emit ChangedSuperOwner(newSuperOwner);
        return true;
    }

    /**
     * dev owner 들의 1/2 초과가 합의하면 superOwner 를 교체할 수 있다.
     */
    function changeSuperOwnerByDAO(address newSuperOwner) onlyOwner public returns (bool) {
        require(newSuperOwner != address(0), "This address to be set is zero address(0). Check the input address.");
        require(newSuperOwner != candidateSuperOwnerMap[msg.sender], "You have already voted for this account.");

        candidateSuperOwnerMap[msg.sender] = newSuperOwner;

        uint8 votingNumForSuperOwner = 0;
        uint8 i = 0;

        for (i = 0; i < ownerList.length; i++) {
            if (candidateSuperOwnerMap[ownerList[i]] == newSuperOwner)
                votingNumForSuperOwner++;
        }

        if (votingNumForSuperOwner > ownerList.length / 2) { // 과반수 이상이면 DAO 성립 => superOwner 교체
            superOwner = newSuperOwner;

            // 초기화
            for (i = 0; i < ownerList.length; i++) {
                delete candidateSuperOwnerMap[ownerList[i]];
            }

            emit ChangedSuperOwner(newSuperOwner);
        }

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
        require(owners[owner], "This input address is not a super owner.");
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
     * dev 락 상태에서도 거래 가능한 언락 계정
     */
    mapping(address => bool) public unlockAddrs;

    /**
     * dev 계정 별로 lock value 만큼 잔고가 잠김
     * dev - 값이 0 일 때 : 잔고가 0 이어도 되므로 제한이 없는 것임.
     * dev - 값이 LOCK_MAX 일 때 : 잔고가 uint256 의 최대값이므로 아예 잠긴 것임.
     */
    mapping(address => uint256) public lockValues;

    event Locked(bool locked, string note);
    event LockedTo(address indexed addr, bool locked, string note);
    event SetLockValue(address indexed addr, uint256 value, string note);

    constructor() public {
        unlockTo(msg.sender,  "");
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
     * dev 이체 가능 금액을 조회한다.
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
 * @title DelayLockableToken
 * dev 보안 차원에서 본인 계좌 잔고에 lock 을 걸 수 있다. 잔고 제한 기준을 낮추면 적용되기까지 12시간을 기다려야 한다.
 */
contract DelayLockableToken is LockableToken {
    mapping(address => uint256) public delayLockValues;
    mapping(address => uint256) public delayLockBeforeValues;
    mapping(address => uint256) public delayLockTimes;

    event SetDelayLockValue(address indexed addr, uint256 value, uint256 time);

    modifier checkDelayUnlock (address addr, uint256 value) {
        if (delayLockTimes[msg.sender] <= now) {
            require (balances[addr].sub(value) >= delayLockValues[addr], "Transferable limit exceeded. Change the balance lock value first and then use it");
        } else {
            require (balances[addr].sub(value) >= delayLockBeforeValues[addr], "Transferable limit exceeded. Please note that the residual lock value has changed and it will take 12 hours to apply.");
        }
        _;
    }

    /**
     * dev 자신의 계좌에 잔고 제한을 건다. 더 크게 걸 땐 바로 적용되고, 더 작게 걸 땐 12시간 이후에 변경된다.
     */
    function delayLock(uint256 value) public returns (bool) {
        require (value <= balances[msg.sender], "Your balance is insufficient.");

        if (value >= delayLockValues[msg.sender])
            delayLockTimes[msg.sender] = now;
        else {
            require (delayLockTimes[msg.sender] <= now, "The remaining money in the account cannot be unlocked continuously. You cannot renew until 12 hours after the first run.");
            delayLockTimes[msg.sender] = now + 12 hours;
            delayLockBeforeValues[msg.sender] = delayLockValues[msg.sender];
        }

        delayLockValues[msg.sender] = value;

        emit SetDelayLockValue(msg.sender, value, delayLockTimes[msg.sender]);
        return true;
    }

    /**
     * dev 자신의 계좌의 잔고 제한을 푼다.
     */
    function delayUnlock() public returns (bool) {
        return delayLock(0);
    }

    /**
     * dev 이체 가능 금액을 조회한다.
     */
    function getMyUnlockValue() public view returns (uint256) {
        uint256 myUnlockValue;
        address addr = msg.sender;
        if (delayLockTimes[addr] <= now) {
            myUnlockValue = balances[addr].sub(delayLockValues[addr]);
        } else {
            myUnlockValue = balances[addr].sub(delayLockBeforeValues[addr]);
        }

        uint256 superUnlockValue = super.getMyUnlockValue();

        if (myUnlockValue > superUnlockValue)
            return superUnlockValue;
        else
            return myUnlockValue;
    }

    function transfer(address to, uint256 value) checkDelayUnlock(msg.sender, value) public returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) checkDelayUnlock(from, value) public returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

/**
 * @title QUZBaseToken
 * dev 트랜잭션 실행 시 메모를 남길 수 있도록 하였음.
 */
contract QUZBaseToken is DelayLockableToken {
    event QUZTransfer(address indexed from, address indexed to, uint256 value, string note);
    event QUZTransferFrom(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event QUZApproval(address indexed owner, address indexed spender, uint256 value, string note);

    event QUZMintTo(address indexed controller, address indexed to, uint256 amount, string note);
    event QUZBurnFrom(address indexed controller, address indexed from, uint256 value, string note);

    event QUZBurnWhenMoveToMainnet(address indexed controller, address indexed from, uint256 value, string note);

    event QUZSell(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event QUZSellByOtherCoin(address indexed owner, address indexed spender, address indexed to, uint256 value,  uint256 processIdHash, uint256 userIdHash, string note);

    event QUZTransferToTeam(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event QUZTransferToPartner(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);

    event QUZTransferToEcosystem(address indexed owner, address indexed spender, address indexed to, uint256 value, uint256 processIdHash, uint256 userIdHash, string note);
    event QUZTransferToBounty(address indexed owner, address indexed spender, address indexed to, uint256 value, uint256 processIdHash, uint256 userIdHash, string note);

    // ERC20 함수들을 오버라이딩하여 super 로 올라가지 않고 무조건 quz~ 함수로 지나가게 한다.
    function transfer(address to, uint256 value) public returns (bool ret) {
        return quzTransfer(to, value, "");
    }

    function quzTransfer(address to, uint256 value, string note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of QUZCoin. You cannot send money to this address.");

        ret = super.transfer(to, value);
        emit QUZTransfer(msg.sender, to, value, note);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return quzTransferFrom(from, to, value, "");
    }

    function quzTransferFrom(address from, address to, uint256 value, string note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of QUZCoin. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit QUZTransferFrom(from, msg.sender, to, value, note);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        return quzApprove(spender, value, "");
    }

    function quzApprove(address spender, uint256 value, string note) public returns (bool ret) {
        ret = super.approve(spender, value);
        emit QUZApproval(msg.sender, spender, value, note);
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        return quzIncreaseApproval(spender, addedValue, "");
    }

    function quzIncreaseApproval(address spender, uint256 addedValue, string note) public returns (bool ret) {
        ret = super.increaseApproval(spender, addedValue);
        emit QUZApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        return quzDecreaseApproval(spender, subtractedValue, "");
    }

    function quzDecreaseApproval(address spender, uint256 subtractedValue, string note) public returns (bool ret) {
        ret = super.decreaseApproval(spender, subtractedValue);
        emit QUZApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    /**
     * dev 신규 화폐 발행. 반드시 이유를 메모로 남겨라.
     */
    function mintTo(address to, uint256 amount) internal returns (bool) {
        require(to != address(0x0), "This address to be set is zero address(0). Check the input address.");

        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);

        emit Transfer(address(0), to, amount);
        return true;
    }

    function quzMintTo(address to, uint256 amount, string note) onlyOwner public returns (bool ret) {
        ret = mintTo(to, amount);
        emit QUZMintTo(msg.sender, to, amount, note);
    }

    /**
     * dev 화폐 소각. 반드시 이유를 메모로 남겨라.
     */
    function burnFrom(address from, uint256 value) internal returns (bool) {
        require(value <= balances[from], "Your balance is insufficient.");

        balances[from] = balances[from].sub(value);
        totalSupply_ = totalSupply_.sub(value);

        emit Transfer(from, address(0), value);
        return true;
    }

    function quzBurnFrom(address from, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = burnFrom(from, value);
        emit QUZBurnFrom(msg.sender, from, value, note);
    }

    /**
     * dev 메인넷으로 이동하며 화폐 소각.
     */
    function quzBurnWhenMoveToMainnet(address burner, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = burnFrom(burner, value);
        emit QUZBurnWhenMoveToMainnet(msg.sender, burner, value, note);
    }

    function quzBatchBurnWhenMoveToMainnet(address[] burners, uint256[] values, string note) onlyOwner public returns (bool ret) {
        uint256 length = burners.length;
        require(length == values.length, "The size of \'burners\' and \'values\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            ret = ret && quzBurnWhenMoveToMainnet(burners[i], values[i], note);
        }
    }

    /**
     * dev 이더로 QUZ 를 구입하는 경우
     */
    function quzSell(
        address from,
        address to,
        uint256 value,
        string note
    ) onlyOwner public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of QUZCoin. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit QUZSell(from, msg.sender, to, value, note);
    }

    /**
     * dev 비트코인 등의 다른 코인으로 QUZ 를 구입하는 경우
     * dev EOA 가 트랜잭션을 일으켜서 처리해야 하기 때문에 다계좌를 기준으로 한다. (가스비 아끼기 위함)
     */
    function quzBatchSellByOtherCoin(
        address from,
        address[] to,
        uint256[] values,
        uint256 processIdHash,
        uint256[] userIdHash,
        string note
    ) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length, "The size of \'to\' and \'values\' array is different.");
        require(length == userIdHash.length, "The size of \'to\' and \'userIdHash\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of QUZCoin. You cannot send money to this address.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit QUZSellByOtherCoin(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

    /**
     * dev 팀에게 전송하는 경우
     */
    function quzTransferToTeam(
        address from,
        address to,
        uint256 value,
        string note
    ) onlyOwner public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of QUZCoin. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit QUZTransferToTeam(from, msg.sender, to, value, note);
    }

    /**
     * dev 파트너 및 어드바이저에게 전송하는 경우
     */
    function quzTransferToPartner(
        address from,
        address to,
        uint256 value,
        string note
    ) onlyOwner public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of QUZCoin. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit QUZTransferToPartner(from, msg.sender, to, value, note);
    }

    /**
     * dev 에코시스템(커뮤니티 활동을 통한 보상 등)으로 QUZ 지급
     * dev EOA 가 트랜잭션을 일으켜서 처리해야 하기 때문에 다계좌를 기준으로 한다. (가스비 아끼기 위함)
     */
    function quzBatchTransferToEcosystem(
        address from, address[] to,
        uint256[] values,
        uint256 processIdHash,
        uint256[] userIdHash,
        string note
    ) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length, "The size of \'to\' and \'values\' array is different.");
        require(length == userIdHash.length, "The size of \'to\' and \'userIdHash\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of QUZCoin. You cannot send money to this address.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit QUZTransferToEcosystem(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

    /**
     * dev 바운티 참여자에게 QUZ 지급
     * dev EOA 가 트랜잭션을 일으켜서 처리해야 하기 때문에 다계좌를 기준으로 한다. (가스비 아끼기 위함)
     */
    function quzBatchTransferToBounty(
        address from,
        address[] to,
        uint256[] values,
        uint256 processIdHash,
        uint256[] userIdHash,
        string note
    ) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(to.length == values.length, "The size of \'to\' and \'values\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of QUZCoin. You cannot send money to this address.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit QUZTransferToBounty(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

    function destroy() onlyRoot public {
        selfdestruct(root);
    }
}

/**
 * @title QUZCoin
 */
contract QUZCoin is QUZBaseToken {
    using AddressUtils for address;

    event TransferedToQUZDapp(
        address indexed owner,
        address indexed spender,
        address indexed to, uint256 value, QUZReceiver.QUZReceiveType receiveType);

    string public constant name = "QUZCoin";
    string public constant symbol = "QUZ";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1e9 * (10 ** uint256(decimals));

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function quzTransfer(address to, uint256 value, string note) public returns (bool ret) {
        ret = super.quzTransfer(to, value, note);
        postTransfer(msg.sender, msg.sender, to, value, QUZReceiver.QUZReceiveType.QUZ_TRANSFER);
    }

    function quzTransferFrom(address from, address to, uint256 value, string note) public returns (bool ret) {
        ret = super.quzTransferFrom(from, to, value, note);
        postTransfer(from, msg.sender, to, value, QUZReceiver.QUZReceiveType.QUZ_TRANSFER);
    }

    function postTransfer(address owner, address spender, address to, uint256 value, QUZReceiver.QUZReceiveType receiveType) internal returns (bool) {
        if (to.isContract()) {
            bool callOk = address(to).call(bytes4(keccak256("onQUZReceived(address,address,uint256,uint8)")), owner, spender, value, receiveType);
            if (callOk) {
                emit TransferedToQUZDapp(owner, spender, to, value, receiveType);
            }
        }

        return true;
    }

    function quzMintTo(address to, uint256 amount, string note) onlyOwner public returns (bool ret) {
        ret = super.quzMintTo(to, amount, note);
        postTransfer(0x0, msg.sender, to, amount, QUZReceiver.QUZReceiveType.QUZ_MINT);
    }

    function quzBurnFrom(address from, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = super.quzBurnFrom(from, value, note);
        postTransfer(0x0, msg.sender, from, value, QUZReceiver.QUZReceiveType.QUZ_BURN);
    }
}


/**
 * @title QUZCoin Receiver
 */
contract QUZReceiver {
    enum QUZReceiveType { QUZ_TRANSFER, QUZ_MINT, QUZ_BURN }
    function onQUZReceived(address owner, address spender, uint256 value, QUZReceiveType receiveType) public returns (bool);
}

/**
 * @title QUZDappSample
 */
contract QUZDappSample is QUZReceiver {
    event LogOnReceiveQUZ(string message, address indexed owner, address indexed spender, uint256 value, QUZReceiveType receiveType);

    function onQUZReceived(address owner, address spender, uint256 value, QUZReceiveType receiveType) public returns (bool) {
        emit LogOnReceiveQUZ("I receive QUZCoin.", owner, spender, value, receiveType);
        return true;
    }
}