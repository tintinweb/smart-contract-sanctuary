/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// File: contracts/interfaces/IKIP7Receiver.sol


pragma solidity ^0.8.0;

abstract contract IKIP7Receiver {
    function onKIP7Received(address _operator, address _from, uint256 _amount, bytes memory _data) external virtual returns (bytes4);
}

// File: contracts/interfaces/IKIP7.sol



/// @title KIP-7 Fungible Token Standard
///  Note: the KIP-13 identifier for this interface is 0x65787371.
interface IKIP7 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to
    /// another (`to`) and created (`from` == 0) and destroyed(`to` == 0).
    ///
    /// Note that `value` may be zero.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set by
    /// a call to {approve}. `value` is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    /// @return the total supply of this token.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    /// @param account An address for whom to query the balance
    /// @return the amount of tokens owned by `account.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    /// @dev Throws if the message caller's balance does not have enough tokens to spend.
    /// Throws if the contract is pausable and paused.
    ///
    /// Emits a {Transfer} event.
    /// @param recipient The owner will receive the tokens.
    /// @param amount The token amount will be transferred.
    /// @return A boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` will be
    /// allowed to spend on behalf of `owner` through {transferFrom}. This is
    /// zero by default.
    /// @dev Throws if the contract is pausable and paused.
    ///
    /// This value changes when {approve} or {transferFrom} are called.
    /// @param owner The account allowed `spender` to withdraw the tokens from the account.
    /// @param spender The address is approved to withdraw the tokens.
    /// @return An amount of spender's token approved by owner.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Throws if the contract is pausable and paused.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk
    /// that someone may use both the old and the new allowance by unfortunate
    /// transaction ordering. One possible solution to mitigate this race
    /// condition is to first reduce the spender's allowance to 0 and set the
    /// desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Emits an {Approval} event.
    /// @param spender The address is approved to withdraw the tokens.
    /// @param amount The token amount will be approved.
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the
    /// allowance mechanism. `amount` is then deducted from the caller's
    /// allowance.
    /// @dev Throw unless the `sender` account has deliberately authorized the sender of the message via some mechanism.
    /// Throw if `sender` or `recipient` is the zero address.
    /// Throws if the contract is pausable and paused.
    ///
    /// Emits a {Transfer} event.
    /// Emits an `Approval` event indicating the updated allowance.
    /// @param sender The current owner of the tokens.
    /// @param recipient The owner will receive the tokens.
    /// @param amount The token amount will be transferred.
    /// @return A boolean value indicating whether the operation succeeded.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    /// @dev Throws if the message caller's balance does not have enough tokens to spend.
    /// Throws if the contract is pausable and paused.
    /// Throws if `_to` is the zero address.
    /// When transfer is complete, this function checks if `_to` is a smart
    /// contract (code size > 0). If so, it calls
    ///  `onKIP7Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onKIP7Received(address,address,uint256,bytes)"))`.
    /// @param recipient The owner will receive the tokens.
    /// @param amount The token amount will be transferred.
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransfer(address recipient, uint256 amount, bytes calldata data) external;


    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param recipient The owner will receive the tokens.
    /// @param amount The token amount will be transferred.
    function safeTransfer(address recipient, uint256 amount) external;

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the
    /// allowance mechanism. `amount` is then deducted from the caller's
    /// allowance.
    /// @dev Throw unless the `sender` account has deliberately authorized the sender of the message via some mechanism.
    /// Throw if `sender` or `recipient` is the zero address.
    /// Throws if the contract is pausable and paused.
    /// When transfer is complete, this function checks if `_to` is a smart
    /// contract (code size > 0). If so, it calls
    ///  `onKIP7Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onKIP7Received(address,address,uint256,bytes)"))`.
    /// Emits a {Transfer} event.
    /// Emits an `Approval` event indicating the updated allowance.
    /// @param sender The current owner of the tokens.
    /// @param recipient The owner will receive the tokens.
    /// @param amount The token amount will be transferred.
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address sender, address recipient, uint256 amount, bytes calldata data) external;

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the
    /// allowance mechanism. `amount` is then deducted from the caller's
    /// allowance.
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param sender The current owner of the tokens.
    /// @param recipient The owner will receive the tokens.
    /// @param amount The token amount will be transferred.
    function safeTransferFrom(address sender, address recipient, uint256 amount) external;
}

// File: contracts/interfaces/IKIP13.sol




/**
 * @dev Interface of the KIP-13 standard, as defined in the
 * [KIP-13](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others.
 *
 * For an implementation, see `KIP13`.
 */
interface IKIP13 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [KIP-13 section](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard#how-interface-identifiers-are-defined)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/KIP13/KIP13.sol



/**
 * @dev Implementation of the `IKIP13` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
abstract contract KIP13 is IKIP13 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_KIP13 = type(IKIP13).interfaceId;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for KIP13 itself here
        _registerInterface(_INTERFACE_ID_KIP13);
    }

    /**
     * @dev See `IKIP13.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual KIP13 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IKIP13.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the KIP13 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "KIP13: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: contracts/KIP7/KIP7.sol




abstract contract KIP7 is KIP13, IKIP7 {
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    bytes4 private constant _INTERFACE_ID_KIP7 = type(IKIP7).interfaceId;

    constructor () {
        _registerInterface(_INTERFACE_ID_KIP7);
    }

    function _transfer(address from, address to, uint256 value)
        internal
        returns (bool success)
    {
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;
        emit Transfer(from, to, value);
        success = true;
    }

    function _approve(address owner, address spender, uint256 value)
        internal
        returns (bool success)
    {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
        success = true;
    }

    function _mint(address _to, uint256 _amount)
        internal
        returns (bool success)
    {
        _totalSupply = _totalSupply + _amount;
        _balances[_to] = _balances[_to] + _amount;
        emit Transfer(address(0), _to, _amount);
        success = true;
    }

    /*
   * public view functions to view common data
   */

    function totalSupply() external override view returns (uint256 total) {
        total = _totalSupply;
    }
    function balanceOf(address account) external override view returns (uint256 balance) {
        balance = _balances[account];
    }

    function allowance(address owner, address spender)
        external
        override
        view
        returns (uint256 remaining)
    {
        remaining = _allowances[owner][spender];
    }
}

// File: contracts/library/Ownable.sol

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed currentOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Ownable : Function called by unauthorized user."
        );
        _;
    }

    function owner() external view returns (address ownerAddress) {
        ownerAddress = _owner;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
        returns (bool success)
    {
        require(newOwner != address(0), "Ownable/transferOwnership : cannot transfer ownership to zero address");
        success = _transferOwnership(newOwner);
    }

    function renounceOwnership() external onlyOwner returns (bool success) {
        success = _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal returns (bool success) {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        success = true;
    }
}

// File: contracts/KIP7/KIP7Lockable.sol

abstract contract KIP7Lockable is KIP7, Ownable {
    struct LockInfo {
        uint256 amount;
        uint256 due;
    }

    mapping(address => LockInfo[]) internal _locks;
    mapping(address => uint256) internal _totalLocked;

    event Lock(address indexed from, uint256 amount, uint256 due);
    event Unlock(address indexed from, uint256 amount);

    modifier checkLock(address from, uint256 amount) {
        require(_balances[from] >= _totalLocked[from] + amount, "KIP7Lockable/Cannot send more than unlocked amount");
        _;
    }

    function _lock(address from, uint256 amount, uint256 due)
    internal
    returns (bool success)
    {
        require(due > block.timestamp, "KIP7Lockable/lock : Cannot set due to past");
        require(
            _balances[from] >= amount + _totalLocked[from],
            "KIP7Lockable/lock : locked total should be smaller than balance"
        );
        _totalLocked[from] = _totalLocked[from] + amount;
        _locks[from].push(LockInfo(amount, due));
        emit Lock(from, amount, due);
        success = true;
    }

    function _unlock(address from, uint256 index) internal returns (bool success) {
        LockInfo storage lock = _locks[from][index];
        _totalLocked[from] = _totalLocked[from] - lock.amount;
        emit Unlock(from, lock.amount);
        _locks[from][index] = _locks[from][_locks[from].length - 1];
        _locks[from].pop();
        success = true;
    }

    function unlock(address from, uint256 idx) external returns(bool success){
        require(_locks[from][idx].due < block.timestamp,"KIP7Lockable/unlock: cannot unlock before due");
        return _unlock(from, idx);
    }

    function unlockAll(address from) external returns (bool success) {
        for(uint256 i = 0; i < _locks[from].length;){
            i++;
            if(_locks[from][i - 1].due < block.timestamp){
                if(_unlock(from, i - 1)){
                    i--;
                }
            }
        }
        success = true;
    }

    function releaseLock(address from)
    external
    onlyOwner
    returns (bool success)
    {
        for(uint256 i = 0; i < _locks[from].length;){
            i++;
            if(_unlock(from, i - 1)){
                i--;
            }
        }
        success = true;
    }

    function transferWithLockUp(address recipient, uint256 amount, uint256 due)
    external
    onlyOwner
    returns (bool success)
    {
        require(
            recipient != address(0),
            "KIP7Lockable/transferWithLockUp : Cannot send to zero address"
        );
        _transfer(msg.sender, recipient, amount);
        _lock(recipient, amount, due);
        success = true;
    }

    function lockInfo(address locked, uint256 index)
    external
    view
    returns (uint256 amount, uint256 due)
    {
        LockInfo memory lock = _locks[locked][index];
        amount = lock.amount;
        due = lock.due;
    }

    function totalLocked(address locked) external view returns(uint256 amount, uint256 length){
        amount = _totalLocked[locked];
        length = _locks[locked].length;
    }
}

// File: contracts/library/KIP7Pausable.sol


contract KIP7Pausable is Ownable {
    bool internal _paused;

    event Paused(address _account);
    event Unpaused(address _account);

    modifier whenPaused() {
        require(_paused, "Paused : This function can only be called when paused");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Paused : This function can only be called when not paused");
        _;
    }

    function pause() external onlyOwner whenNotPaused returns (bool success) {
        _paused = true;
        emit Paused(msg.sender);
        success = true;
    }

    function unPause() external onlyOwner whenPaused returns (bool success) {
        _paused = false;
        emit Unpaused(msg.sender);
        success = true;
    }

    function paused() external view returns (bool) {
        return _paused;
    }
}

// File: contracts/KIP7/KIP7Mintable.sol



abstract contract KIP7Mintable is KIP7, KIP7Pausable {
    event Mint(address indexed _to, uint256 _amount);
    event MintFinished();
    uint256 internal _cap;

    bool internal _mintingFinished;
    ///@notice mint token
    ///@dev only owner can call this function
    function mint(address _to, uint256 _amount)
        external
        onlyOwner
        whenNotPaused
        returns (bool success)
    {
        require(
            _to != address(0),
            "KIP7Mintable/mint : Should not mint to zero address"
        );
        require(
            _totalSupply + _amount <= _cap,
            "KIP7Mintable/mint : Cannot mint over cap"
        );
        require(
            !_mintingFinished,
            "KIP7Mintable/mint : Cannot mint after finished"
        );
        _mint(_to, _amount);
        emit Mint(_to, _amount);
        success = true;
    }

    ///@notice finish minting, cannot mint after calling this function
    ///@dev only owner can call this function
    function finishMint()
        external
        onlyOwner
        returns (bool success)
    {
        require(
            !_mintingFinished,
            "KIP7Mintable/finishMinting : Already finished"
        );
        _mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function cap()
        external
        view
        returns (uint256)
    {
        return _cap;
    }

    function isFinished() external view returns(bool finished) {
        finished = _mintingFinished;
    }
}

// File: contracts/interfaces/IKIP7Metadata.sol


/// @title KIP-7 Fungible Token Standard, optional metadata extension
///  Note: the KIP-13 identifier for this interface is 0xa219a025.
interface IKIP7Metadata {
    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the
    /// name.
    function symbol() external view returns (string memory);

    /// @notice Returns the number of decimals used to get its user representation.
    /// For example, if `decimals` equals `2`, a balance of `505` tokens should
    /// be displayed to a user as `5,05` (`505 / 10 ** 2`).
    ///  Tokens usually opt for a value of 18, imitating the relationship between
    /// KLAY and Peb.
    /// NOTE: This information is only used for _display_ purposes: it in
    /// no way affects any of the arithmetic of the contract, including
    /// `IKIP7.balanceOf` and `IKIP7.transfer`.
    /// @return The number of decimals of this token.
    function decimals() external view returns (uint8);
}

// File: contracts/library/Freezable.sol


contract Freezable is Ownable {
    mapping(address => bool) private _frozen;

    event Freeze(address indexed target);
    event Unfreeze(address indexed target);

    modifier whenNotFrozen(address target) {
        require(!_frozen[target], "Freezable : target is frozen");
        _;
    }

    function freeze(address target) external onlyOwner returns (bool success) {
        _frozen[target] = true;
        emit Freeze(target);
        success = true;
    }

    function unFreeze(address target)
        external
        onlyOwner
        returns (bool success)
    {
        _frozen[target] = false;
        emit Unfreeze(target);
        success = true;
    }

    function isFrozen(address target)
        external
        view
        returns (bool frozen)
    {
        return _frozen[target];
    }
}

// File: contracts/library/Address.sol

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/Beeblock.sol







contract Beeblock is
    KIP7Lockable,
    KIP7Mintable,
    IKIP7Metadata,
    Freezable
{
    using Address for address;

    bytes4 private constant _KIP7_RECEIVED = 0x9d188c22;
    string constant private _name = "Beeblock";
    string constant private _symbol = "BUZ";
    uint8 constant private _decimals = 18;
    uint256 constant private _initial_supply = 200_000_000;

    constructor() Ownable() {
        _registerInterface(type(IKIP7Metadata).interfaceId);
        _cap = 900_000_000 * (10**uint256(_decimals));
        _mint(msg.sender, _initial_supply * (10**uint256(_decimals)));
    }

    function transfer(address recipient, uint256 amount)
        override
        public
        whenNotFrozen(msg.sender)
        whenNotPaused
        checkLock(msg.sender, amount)
        returns (bool success)
    {
        require(
            recipient != address(0),
            "BUZ/transfer : Should not send to zero address"
        );
        _transfer(msg.sender, recipient, amount);
        success = true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        override
        public
        whenNotFrozen(sender)
        whenNotPaused
        checkLock(sender, amount)
        returns (bool success)
    {
        require(
            recipient != address(0),
            "BUZ/transferFrom : Should not send to zero address"
        );
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender] - amount
        );
        success = true;
    }

    function approve(address spender, uint256 amount)
        override
        public
        returns (bool success)
    {
        require(
            spender != address(0),
            "BUZ/approve : Should not approve zero address"
        );
        _approve(msg.sender, spender, amount);
        success = true;
    }

    function name() override external pure returns (string memory tokenName) {
        tokenName = _name;
    }

    function symbol() override external pure returns (string memory tokenSymbol) {
        tokenSymbol = _symbol;
    }

    function decimals() override external pure returns (uint8 tokenDecimals) {
        tokenDecimals = _decimals;
    }

    function safeTransfer(address recipient, uint256 amount, bytes memory data) public override {
        transfer(recipient, amount);
        require(_checkOnKIP7Received(msg.sender, recipient, amount, data), "KIP7: transfer to non KIP7Receiver implementer");
    }

    function safeTransfer(address recipient, uint256 amount) public override {
        safeTransfer(recipient, amount, "");
    }

    function safeTransferFrom(address sender, address recipient, uint256 amount, bytes memory data) public override {
        transferFrom(sender, recipient, amount);
        require(_checkOnKIP7Received(sender, recipient, amount, data), "KIP7: transfer to non KIP7Receiver implementer");
    }

    function safeTransferFrom(address sender, address recipient, uint256 amount) public override {
        safeTransferFrom(sender, recipient, amount, "");
    }

    function _checkOnKIP7Received(address sender, address recipient, uint256 amount, bytes memory _data)
        internal returns (bool)
    {
        if (!recipient.isContract()) {
            return true;
        }

        bytes4 retval = IKIP7Receiver(recipient).onKIP7Received(msg.sender, sender, amount, _data);
        return (retval == _KIP7_RECEIVED);
    }
}