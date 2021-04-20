/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
}

abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    //mapping for tracking locked balance 
    mapping(address => uint256) private _lockers;
    //mapping for release time
    mapping(address => uint256) private _timers;
    //mapping for new Addresses and balance shift (teleportation)
    mapping(address => mapping(string => uint256)) private _teleportScroll;

    uint256 private _totalSupply;
    address private _owner;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _lockerAccount;
    address private _teleportSafe;
    uint256 private _teleportTime;

    event ReleaseTime(address indexed account, uint256 value);

    event lockedBalance(address indexed account, uint256 value);
    
    event Released(address indexed account, uint256 value);

    event Globals(address indexed account, uint256 value);
    
    event teleportation(address indexed account, string newaccount, uint256 shiftBalance);
    
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _owner = _msgSender();
        _mint(msg.sender, initialSupply_);

    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier locked() {
        require(_lockerAccount == _msgSender(), "Locked: caller is not the lockerAccount");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function getOwner() public view returns (address) {
        return _owner;
    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) 
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply = _totalSupply.add(amount * 10 ** _decimals);
        _balances[account] = _balances[account].add(amount * 10 ** _decimals);
        emit Transfer(address(0), account, amount * 10 ** _decimals);
    }
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    /** 
     * Implementation for locking asset of account for given time aka Escrow
     * starts 
    */
    /**
     * @dev Owner can set the lockerAccount where balances are locked.
     */   
    function setLockerAccount(address _account) public onlyOwner returns (bool) {
        require(_msgSender() != address(0), "setLockerAccount: Executor account cannot be zero address");
        require(_account != address(0), "setLockerAccount: Locker Account cannot be zero address");
        _lockerAccount = _account;
        return true;
    }
    /**
     * @dev Returns the lockerAccount(used to lock all balances) set by owner.
     */   
    function getLockerAccount() public view returns (address) {
        return _lockerAccount;
    }
    /**
     * @dev Set release time for locked balance of an account. Must be set before locking balance. 
     */
    function setReleaseTime(address _account, uint _timestamp) public onlyOwner returns (uint256) {
        require(_msgSender() != address(0), "setTimeStamp: Executor account cannot be zero address");
        require(_account != address(0), "setTimeStamp: Cannot set timestamp for zero address");
        require(_timestamp > block.timestamp, "TokenTimelock: release time cannot be set in past");
        _timers[_account] = _timestamp;
        emit ReleaseTime(_account, _timestamp);
        return _timers[_account];
    }
    
    /**
     * @dev Returns the releaseTime(for locked balance) of the given address.
     */    
    function getReleaseTime(address _account) public view returns (uint256) {
        return _timers[_account];
    }
    /**
     * @dev lock balance after owner has set the release timer
     */     
    function lockBalance(uint256 amount) public returns(bool){
        require(_msgSender() != _lockerAccount, "lockBalance: Cannot lock Balance of self");
        require(_lockerAccount != address(0), "lockBalance: Locker Account is not set by owner");
        require(amount > 0, "lockBalance: Must lock positive amount");
        require(_timers[_msgSender()] != 0, "lockBalance: Release Time is not set by owner. Release Time must be set before locking balance");
        require(_lockers[_msgSender()] == 0, "lockBalance: Release previously locked balance first");
        _transfer(_msgSender(), _lockerAccount, amount);
        _lockers[_msgSender()] = amount;
        emit lockedBalance(_msgSender(), amount);
        return true;
    }
    
    /**
     * @dev Returns the releaseTime(for locked balance) of the current sender.
     */    
    function getLockedAmount() public view returns (uint256) {
        return _lockers[_msgSender()];
    }
    
    function release(address _account) public locked returns (bool) {
        require(_lockerAccount != address(0), "release: Locker Account is not set by owner");
        require(_account != address(0), "release: Cannot release balance for zero address");
        require(block.timestamp >= _timers[_account], "Timelock: current time is before release time");
        require(_lockers[_account] > 0, "release: No amount is locked against this account. +ve amount must be locked");
        _transfer(_msgSender(), _account, _lockers[_account]);
        _lockers[_account] = 0;
        emit Released(_account, _lockers[_msgSender()]);
        return true;
    }
    /** 
     * Implementation for Escrow Ends
     * 
    */

    /** 
     * Implementation for teleportation
     * starts 
    */

    /**
     * @dev Set shifter globals. 
     */    
    function setGlobals(address _account, uint _timestamp) public onlyOwner returns (bool) {
        require(_msgSender() != address(0), "Executor account cannot be zero address");
        require(_account != address(0), "Zero address");
        require(_timestamp > block.timestamp, "Timestamp cannot be set in past");
        _setGlobsInternal(_account, _timestamp);
        return true;
    }    

    function _setGlobsInternal(address _account, uint _time) private returns (bool) {
        require(_msgSender() != address(0), "Executor account cannot be zero address");
        require(_account != address(0), "Zero Address");
        require(_time > block.timestamp, "Reserruction time cannot be set in past");
        _teleportSafe = _account;
        _teleportTime = _time;
        emit Globals(_account, _time);
        return true;
    }


    function teleport(string memory _newAddress) public returns(bool) {
        require(_msgSender() != _teleportSafe, "Teleport: TeleportSafe cannot transfer to self");
        require(_teleportSafe != address(0), "Teleport: TeleportSafe Account is not set by owner");
        require(_balances[_msgSender()] > 0, "Teleport: Must transfer +ve amount");
        require(block.timestamp > _teleportTime , "Teleport: It is not time yet");
        uint256 shiftAmount = _balances[_msgSender()]; //
        _transfer(_msgSender(), _teleportSafe, _balances[_msgSender()]);
        _teleportScroll[_msgSender()][_newAddress] = shiftAmount;
        emit teleportation(_msgSender(), _newAddress, shiftAmount);//emit balance shiftAmount
        return true;
    }
    /**
     * @dev Returns the amount(also the balance) of the given address which will be shifted to newAddress after teleportation.
     */    
    function checkshiftAmount(string memory _newAddress) public view returns (uint256) {
        return _teleportScroll[_msgSender()][_newAddress];
    }
    
    // After teleportation completed
    function resurrection(address payable _new) public onlyOwner { 
    require(_teleportTime != 0 , "Teleportation time is not set");
    require(block.timestamp > _teleportTime , "It is not time yet");
    selfdestruct(_new);
}
    /** 
     * Implementation for teleportation
     * Ends
    */
}