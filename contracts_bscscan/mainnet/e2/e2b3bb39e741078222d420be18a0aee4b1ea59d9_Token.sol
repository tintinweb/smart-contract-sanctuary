/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

pragma solidity 0.4.24;

contract BEP20Interface {

    function symbol()
        public
        view
        returns (string memory);

    function name()
        public
        view
        returns (string memory);

    function decimals()
        public
        view
        returns (uint8);

    function totalSupply()
        public
        view
        returns (uint256);

    function balanceOf(
        address _address)
        public
        view
        returns (uint256 balance);

    function allowance(
        address _address,
        address _to)
        public
        view
        returns (uint256 remaining);

    function transfer(
        address _to,
        uint256 _value)
        public
        returns (bool success);

    function approve(
        address _to,
        uint256 _value)
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool success);

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}


contract Owned {
    address owner;
    address newOwner;
    uint32 transferCount;

    event TransferInitiated(
        address indexed _from,
        address indexed _to
    );

    event TransferOwnership(
        address indexed _from,
        address indexed _to
    );

    constructor() public {
        owner = msg.sender;
        transferCount = 0;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(
        address _newOwner)
        public
        onlyOwner
    {
        newOwner = _newOwner;
        emit TransferInitiated(
            msg.sender,
            newOwner
        );
    }

    function getOwner()
        public
        view
        returns (address)
    {
        return owner;
    }

    function viewTransferCount()
        public
        view
        onlyOwner
        returns (uint32)
    {
        return transferCount;
    }

    function isTransferPending()
        public
        view
        returns (bool) {
        require(
            msg.sender == owner ||
            msg.sender == newOwner);
        return newOwner != address(0);
    }

    function acceptOwnership()
         public
    {
        require(msg.sender == newOwner);

        owner = newOwner;
        newOwner = address(0);
        transferCount++;

        emit TransferOwnership(
            owner,
            newOwner
        );
    }
}

library SafeMath {
    function add(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c)
    {
        c = a + b;
        require(c >= a);
    }

    function sub(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c)
    {
        require(b <= a);
        c = a - b;
    }

    function mul(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address _from,
        uint256 _value,
        address token,
        bytes data)
        public
        returns (bool success);
}


contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/**
 * @title ERC1132 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1132
 */
contract ERC1132 {
    /**
     * @dev Reasons why a user's tokens have been locked
     */
    mapping(address => bytes32[]) public lockReason;

    /**
     * @dev locked token structure
     */
    struct lockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }

    /**
     * @dev Holds number & validity of tokens locked for a given reason for
     *      a specified address
     */
    mapping(address => mapping(bytes32 => lockToken)) public locked;

    /**
     * @dev Records data of all the tokens Locked
     */
    event Locked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount,
        uint256 _validity
    );

    /**
     * @dev Records data of all the tokens unlocked
     */
    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );

    /**
     * @dev Locks a specified amount of tokens against an address,
     *      for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be locked
     * @param _time Lock time in seconds
     */
    function lock(bytes32 _reason, uint256 _amount, uint256 _time)
        public returns (bool);

    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     */
    function tokensLocked(address _of, bytes32 _reason)
        public view returns (uint256 amount);

    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason at a specific time
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     * @param _time The timestamp to query the lock tokens for
     */
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public view returns (uint256 amount);

    /**
     * @dev Returns total tokens held by an address (locked + transferable)
     * @param _of The address to query the total balance of
     */
    function totalBalanceOf(address _of)
        public view returns (uint256 amount);

    /**
     * @dev Extends lock for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _time Lock extension time in seconds
     */
    function extendLock(bytes32 _reason, uint256 _time)
        public returns (bool);

    /**
     * @dev Increase number of tokens locked for a specified reason
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be increased
     */
    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public returns (bool);

    /**
     * @dev Returns unlockable tokens for a specified address for a specified reason
     * @param _of The address to query the the unlockable token count of
     * @param _reason The reason to query the unlockable tokens for
     */
    function tokensUnlockable(address _of, bytes32 _reason)
        public view returns (uint256 amount);

    /**
     * @dev Unlocks the unlockable tokens of a specified address
     * @param _of Address of user, claiming back unlockable tokens
     */
    function unlock(address _of)
        public returns (uint256 unlockableTokens);

    /**
     * @dev Gets the unlockable tokens of a specified address
     * @param _of The address to query the the unlockable token count of
     */
    function getUnlockableTokens(address _of)
        public view returns (uint256 unlockableTokens);

}


contract Token is BEP20Interface, Owned, Pausable, ERC1132 {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;

    string internal constant ALREADY_LOCKED = 'Tokens already locked';
    string internal constant NOT_LOCKED = 'No tokens locked';
    string internal constant AMOUNT_ZERO = 'Amount can not be 0';

    /* always capped by 3B tokens */
    uint256 internal constant MAX_TOTAL_SUPPLY = 3000000000;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) incomes;
    mapping(address => uint256) expenses;

    constructor()
        public
    {
        symbol = 'PLGRT';
        name = 'pig Finance test';
        decimals = 18;
        _totalSupply = 0;
    }

    function symbol() public view returns (string memory) {
        return symbol;
    }

    function name() public view returns (string memory) {
        return name;
    }

    function decimals() public view returns (uint8) {
        return decimals;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value)
        internal
        returns (bool success)
    {
        require (_to != 0x0);
        require (balances[_from] >= _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        incomes[_to] = incomes[_to].add(_value);
        expenses[_from] = expenses[_from].add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function transfer(
        address _to,
        uint256 _value)
        public
        whenNotPaused
        returns (bool success)
    {
        return _transfer(msg.sender, _to, _value);
    }

    function approve(
        address _spender,
        uint256 _value)
        public
        whenNotPaused
        returns (bool success)
    {
        require (_spender != 0x0);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        whenNotPaused
        returns (bool success)
    {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    function balanceOf(
        address _address)
        public
        view
        returns (uint256 remaining)
    {
        require(_address != 0x0);

        return balances[_address];
    }

    function incomeOf(
        address _address)
        public
        view
        returns (uint256 income)
    {
        require(_address != 0x0);

        return incomes[_address];
    }

    function expenseOf(
        address _address)
        public
        view
        returns (uint256 expense)
    {
        require(_address != 0x0);

        return expenses[_address];
    }

    function allowance(
        address _owner,
        address _spender)
        public
        view
        returns (uint256 remaining)
    {
        require(_owner != 0x0);
        require(_spender != 0x0);
        return allowed[_owner][_spender];
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _data)
        public
        whenNotPaused
        returns (bool success)
    {
        if (approve(_spender, _value)) {
            require(ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, this, _data) == true);
            return true;
        }
        return false;
    }


    function mint(
        uint256 amount)
        public
        onlyOwner
        returns (bool success)
    {
        uint256 newSupply = _totalSupply + amount;
        require(newSupply <= MAX_TOTAL_SUPPLY.mul(10 ** uint256(decimals)));

        _totalSupply = newSupply;
        balances[owner] = balances[owner].add(amount);
        emit Transfer(address(0), owner, amount);
        return true;
    }

    function burn(
        uint256 amount)
        public
        whenNotPaused
        returns (bool success)
    {
        require (balances[msg.sender] >= amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

     function lock(
         bytes32 _reason,
         uint256 _amount,
         uint256 _time)
        public
        whenNotPaused
        returns (bool)
    {
        uint256 validUntil = now.add(_time); //solhint-disable-line

        // If tokens are already locked, then functions extendLock or
        // increaseLockAmount should be used to make any changes
        require(tokensLocked(msg.sender, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[msg.sender][_reason].amount == 0)
            lockReason[msg.sender].push(_reason);

        transfer(address(this), _amount);

        locked[msg.sender][_reason] = lockToken(_amount, validUntil, false);

        emit Locked(msg.sender, _reason, _amount, validUntil);
        return true;
    }

    function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _time)
        public
        whenNotPaused
        returns (bool)
    {
        uint256 validUntil = now.add(_time); //solhint-disable-line

        require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[_to][_reason].amount == 0)
            lockReason[_to].push(_reason);

        transfer(address(this), _amount);

        locked[_to][_reason] = lockToken(_amount, validUntil, false);

        emit Locked(_to, _reason, _amount, validUntil);
        return true;
    }

    function tokensLocked(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (!locked[_of][_reason].claimed)
            amount = locked[_of][_reason].amount;
    }

    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity > _time)
            amount = locked[_of][_reason].amount;
    }

    function totalBalanceOf(address _of)
        public
        view
        returns (uint256 amount)
    {
        amount = balanceOf(_of);

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount = amount.add(tokensLocked(_of, lockReason[_of][i]));
        }
    }

     function extendLock(bytes32 _reason, uint256 _time)
        public
        whenNotPaused
        returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);

        locked[msg.sender][_reason].validity = locked[msg.sender][_reason].validity.add(_time);

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }

    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public
        whenNotPaused
        returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
        transfer(address(this), _amount);

        locked[msg.sender][_reason].amount = locked[msg.sender][_reason].amount.add(_amount);

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }

    function tokensUnlockable(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed) //solhint-disable-line
            amount = locked[_of][_reason].amount;
    }

    function unlock(address _of)
        public
        whenNotPaused
        returns (uint256 unlockableTokens)
    {
        uint256 lockedTokens;

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
            if (lockedTokens > 0) {
                unlockableTokens = unlockableTokens.add(lockedTokens);
                locked[_of][lockReason[_of][i]].claimed = true;
                emit Unlocked(_of, lockReason[_of][i], lockedTokens);
            }
        }

        if (unlockableTokens > 0)
            this.transfer(_of, unlockableTokens);
    }

    function getUnlockableTokens(address _of)
        public
        view
        returns (uint256 unlockableTokens)
    {
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            unlockableTokens = unlockableTokens.add(tokensUnlockable(_of, lockReason[_of][i]));
        }
    }

    function () public payable {
        revert();
    }
}