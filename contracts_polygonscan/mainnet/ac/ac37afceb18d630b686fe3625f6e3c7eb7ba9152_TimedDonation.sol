/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\TokenEscrow.sol



pragma solidity ^0.8.0;



contract TokenEscrow is Ownable {
    

    event Deposited(address indexed payee, uint256 amount);
    event Withdrawn(address indexed payee, uint256 amount);

    mapping(address => uint256) private _deposits;
    IERC20 private _escrowToken;

    constructor(IERC20 escrowToken_) {
        require(address(escrowToken_) != address(0),"TokenEscrow: escrowToken is the zero address");
        _escrowToken = escrowToken_;
    }

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    function escrowToken() public view returns(IERC20){
        return _escrowToken;
    }

    
    function deposit(uint256 amount) public virtual {
        address payee = _msgSender();
        escrowToken().transferFrom(payee, address(this), amount);
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    function withdraw() public virtual {
        address payee = _msgSender();
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        escrowToken().transfer(payee, payment);

        emit Withdrawn(payee, payment);
    }
}

// File: contracts\TokenConditionalEscrow.sol



pragma solidity ^0.8.0;



abstract contract TokenConditionalEscrow is TokenEscrow {
    /**
     * @dev Returns whether an address is allowed to withdraw their funds. To be
     * implemented by derived contracts.
     */
    function withdrawalAllowed() public view virtual returns (bool);

    function withdraw() public virtual override {
        require(withdrawalAllowed(), "ConditionalEscrow: payee is not allowed to withdraw");
        super.withdraw();
    }
}

// File: contracts\TokenRefundEscrow.sol



pragma solidity ^0.8.0;



contract TokenRefundEscrow is TokenConditionalEscrow {

    enum State {
        Active,
        Refunding,
        Closed
    }

    event RefundsClosed();
    event RefundsEnabled();

    State internal _state;
    address private immutable _beneficiary;


    
    constructor(address beneficiary_, IERC20 escrowToken_) TokenEscrow(escrowToken_) {
        require(beneficiary_ != address(0), "RefundEscrow: beneficiary is the zero address");
        _beneficiary = beneficiary_;
        _state = State.Active;
    }

    
    function state() public view virtual returns (State) {
        return _state;
    }

    
    
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    
    function deposit(uint256 amount) public virtual override {
        require(state() == State.Active, "RefundEscrow: can only deposit while active");
        super.deposit(amount);
    }


    function close() public virtual onlyOwner {
        require(state() == State.Active, "RefundEscrow: can only close while active");
        _state = State.Closed;
        emit RefundsClosed();
    }

 
    function enableRefunds() public virtual onlyOwner {
        require(state() == State.Active, "RefundEscrow: can only enable refunds while active");
        _state = State.Refunding;
        emit RefundsEnabled();
    }


    function beneficiaryWithdraw() public virtual {
        require(state() == State.Closed, "RefundEscrow: beneficiary can only withdraw while closed");
        uint256 amount = escrowToken().balanceOf(address(this));
        escrowToken().transfer(beneficiary(), amount);
    }

    
    function withdrawalAllowed() public view override returns (bool) {
        return state() == State.Refunding;
    }
}

// File: contracts\TimedDonation.sol



pragma solidity ^0.8.0;



contract TimedDonation is TokenRefundEscrow{
    
    address[] private _donors;
    uint256 private immutable _timeLimit;
    string private _reason = "Empty Reason";
    uint256 private immutable _goalAmount;

    constructor(address beneficiary_, IERC20 escrowToken_, uint256 goalAmount_, uint256 timeLimit_) TokenRefundEscrow(beneficiary_, escrowToken_){
        _timeLimit = timeLimit_;
        _goalAmount = goalAmount_;
    }

    function setReason(string memory reason_) public virtual onlyOwner{
        _reason = reason_;
    }

    function reason() public view virtual returns(string memory){
        return _reason;
    }

    function goalAmount() public view virtual returns(uint256){
        return _goalAmount;
    }

    function inTime() public view virtual returns(bool){
        return block.timestamp <= _timeLimit;
    }

    function timeLimit() public view virtual returns(uint256){
        return _timeLimit;
    }

    function deposit(uint256 amount) public virtual override {
        require(inTime(),"error not in time");
        if (depositsOf(_msgSender()) == uint256(0)){
            _donors.push(_msgSender());
        }
        uint256 balance = escrowToken().balanceOf(address(this));
        uint256 maxInput = _goalAmount - balance;
        uint256 effectiveInput = maxInput >= amount ? amount : maxInput;
        super.deposit(effectiveInput);
        _checkState();
    }

    function checkState() public virtual{
        _checkState();
    }

    function _checkState() internal virtual{
        uint256 balance = escrowToken().balanceOf(address(this));
        if( balance == _goalAmount){
            _state = State.Closed;
        }else if (!inTime()){
            _state = State.Refunding;
        }
    }

    function donors() public virtual returns(address[] memory){
        return _donors;
    }

    function donorsAmount() public virtual returns(uint256){
        return _donors.length;
    }


}