// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./TokenBar.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Next steps...
//Create some test functions to send and receive funds. Will later be used for lending/payments
//Test those functions with  truffle. See if the token bar is good as is, or if it should be updated
contract LoanWolfPool is TokenBar, Ownable{

    //interest rate is consistent for each pool
    uint public interestRate = 1000;       //10% interest default for now
    uint public constant ONE_HUNDRED_PERCENT = 10000;

    //Loan object. Stores lots of info about each loan
    struct loan {
        bool issued;
        address ERC20Address;
        address borrower;
        uint256 paymentPeriod;
        uint256 paymentDueDate;
        uint256 minPayment;
        uint256 principal;
        uint256 totalPaymentsValue;
        uint256 paymentComplete;
    }
    
    //Two mappings. One to get the loans for a user. And the other to get the the loans based off id
    mapping(uint256 => loan) public loanLookup;
    mapping(address => uint256[]) public loanIDs;
    
    constructor(address _dai) TokenBar(_dai){}

    
    /// @notice requires contract is not paid off
    modifier incomplete(uint256 _id){
        require(loanLookup[_id].paymentComplete <
        loanLookup[_id].totalPaymentsValue,
        "This contract is alreayd paid off");
        _;
    }

    function setInterestRate(uint _new) external onlyOwner{
        require(_new <= ONE_HUNDRED_PERCENT, "Cannot have interest over 100%");
        interestRate = _new;
    }

    /**
    * @dev function for a lender to deposit funds and get lDAI back
    * @param _amount is the amount to lend
    * @notice the contract must be approved to spend _amount amount of DAI first
     */
    function lend(uint _amount)external{
        _enter(_amount, msg.sender);
    }

    /**
    * @dev borrow function to accept a configured loan as a borrower
    * @param _id is the configured loan ID to borrow
     */
    function borrow(uint _id)external{
        require(loanLookup[_id].borrower == msg.sender, "Caller must be a configured borrower");
        loanLookup[_id].issued = true;
        token.transfer(msg.sender, loanLookup[_id].principal);
    }
    
    /**
    * @notice gets the number of loans a person has
    * @param _who is who to look up
    * @return length
     */
    function getNumberOfLoans(address _who) external virtual view returns(uint256){
        return loanIDs[_who].length;
    }
    
    // /**
    // * @notice This contract is not very forgiving. Miss one payment and you're marked as delinquent. Unless contract is complete
    // * @param _id is the hash id of the loan. Same as bond ERC1155 ID as well
    // * @return if delinquent or not. Meaning missed a payment
    //  */
    // function isDelinquent(uint256 _id) public virtual view returns(bool){
    //     return (block.timestamp >= loanLookup[_id].paymentDueDate && !isComplete(_id));
    // }
    
     /**
    * @notice contract must be configured before bonds are issued. Pushes new loan to array for user
    * @dev borrower is msg.sender for testing. In production might want to make this a param
    * @param _borrower is the borrower loan is being configured for. Keep in mind. ONLY this borrower can mint bonds to start the loan
    * @param _minPayment is the minimum payment that must be made before the payment period ends
    * @param _paymentPeriod payment must be made by this time or delinquent function will return true
    * @param _principal the origional loan value before interest
    * @return the id it just created
     */
    function configureNew(
    address _borrower,
    uint256 _minPayment, 
    uint256 _paymentPeriod, 
    uint256 _principal
    )
    external
    virtual
    onlyOwner()
    returns(uint256)
    {   
        require(_principal <= token.balanceOf(address(this)), "Principal cannot be greater than the token balance");
        //Create new ID for the loan
        uint256 id = getId(_borrower, loanIDs[_borrower].length);
        //Push to loan IDs
        loanIDs[_borrower].push(id);

        //Add loan info to lookup
        loanLookup[id] = loan(
        {
            issued: false,
            ERC20Address: address(token),
            borrower: _borrower,
            paymentPeriod: _paymentPeriod,
            paymentDueDate: block.timestamp + _paymentPeriod,
            minPayment: _minPayment,
            principal: _principal,
            totalPaymentsValue: _principal,               //For now. Will update with interest updates
            paymentComplete: 0
            }
        );

        //For Truffle tests. Just skip Chainlink request. I don't have a local chainlink system
        //To mimic, just set chainlinkRequestId to hash of ID and merkle root to hash of "Hello World"
        // bytes32 reqID = keccak256(abi.encodePacked(id));
        // loanLookup[id].chainlinkRequestId = reqID;
        // merkleRoots[reqID] = keccak256("Hello World");
        return id;
    }
    
    /**
    * @notice function handles the payment of the loan. Does not have to be borrower
    *as payment comes in. The contract holds it until collection by bond owners. MUST APPROVE FIRST in ERC20 contract first
    * @param _id to pay off
    * @param _erc20Ammount is ammount in loan's ERC20 to pay
     */
    function payment(uint256 _id, uint256 _erc20Ammount) 
    external 
    virtual
    incomplete(_id)
    {
        loan memory ln = loanLookup[_id];
        require(_erc20Ammount >= ln.minPayment ||                                   //Payment must be more than min payment
                ln.totalPaymentsValue - ln.paymentComplete < ln.minPayment,     //Exception for the last payment (remainder)
                "You must make the minimum payment");
                
        IERC20(ln.ERC20Address).transferFrom(msg.sender, address(this), _erc20Ammount);     
        loanLookup[_id].paymentDueDate = block.timestamp + ln.paymentPeriod;             //Reset paymentTimer;
        loanLookup[_id].paymentComplete += _erc20Ammount;                                //Increase paymentComplete
        //Then update interest based of remainder due if there is a remainder due
        if(!isComplete(_id)){
            loanLookup[_id].totalPaymentsValue += 
            ((loanLookup[_id].totalPaymentsValue - loanLookup[_id].paymentComplete) *
            interestRate) /
            ONE_HUNDRED_PERCENT;
        }
    }
    
    /**
    * @notice helper function
    * @param _id of loan to check
    * @return return if the contract is payed off or not as bool
     */
    function isComplete(uint256 _id) public virtual view returns(bool){
        return loanLookup[_id].paymentComplete >=
        loanLookup[_id].totalPaymentsValue ||
        !loanLookup[_id].issued;
    }

    /**
    * @notice Returns the ID for a loan given the borrower and index in the array
    * @param _borrower is borrower
    * @param _index is the index in the borrowers loan array
    * @return the loan ID
     */
    //
    function getId(address _borrower, uint256 _index) public virtual view returns(uint256){
        uint256 id = uint256(
            keccak256(abi.encodePacked(
            address(this),
            _borrower,
            _index
        )));
        return id;
    }

}

// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// TokenBar is the coolest bar in town. You come in with some Token, and leave with more! The longer you stay, the more Token you get.
//
// This contract handles swapping to and from xToken, the staking token.
contract TokenBar is ERC20{
    IERC20 public token;

    // Define the Token token contract
    constructor(address _token) ERC20("Roci DAI", "rDAI"){
        token = IERC20(_token);
    }

    // Enter the bar. Pay some TOKENs. Earn some shares.
    // Locks Token and mints xToken
    function _enter(uint256 _amount, address _entering) internal {
        // Gets the amount of Token locked in the contract
        uint256 totalToken = token.balanceOf(address(this));
        // Gets the amount of xToken in existence
        uint256 totalShares = totalSupply();
        // If no xToken exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalToken == 0) {
            _mint(_entering, _amount);
        }
        // Calculate and mint the amount of xToken the Token is worth. The ratio will change overtime, as xToken is burned/minted and Token deposited + gained from fees / withdrawn.
        else {
            uint256 what = (_amount * totalShares) / (totalToken);
            _mint(_entering, what);
        }
        // Lock the Token in the contract
        token.transferFrom(_entering, address(this), _amount);
    }

    // Leave the bar. Claim back your TOKENs.
    // Unlocks the staked + gained Token and burns xToken
    function _leave(uint256 _share) internal {
        // Gets the amount of xToken in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Token the xToken is worth
        uint256 what = (_share * token.balanceOf(address(this))) / (totalShares);
        _burn(msg.sender, _share);
        token.transfer(msg.sender, what);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}