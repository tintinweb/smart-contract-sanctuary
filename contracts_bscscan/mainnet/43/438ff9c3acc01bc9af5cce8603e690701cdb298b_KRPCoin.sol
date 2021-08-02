/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-23
*/

// File: CustomAdmin.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;


// File: IBEP20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
        /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);
    
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);


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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    
        
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event BoughtKrp(address indexed buyer,address indexed referrer,uint256 amount);
    event BNBToOwner(uint256 indexed amount);
    event Airdropped(address indexed receiver,address indexed  referrer, uint256 airdropAmount);
    event PreSaleState( bool value);
    event TradeableState( bool value);
    
}
// File: SafeMath.sol


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

}

// File: Context.sol


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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: Ownable.sol


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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

///@title This contract enables to create multiple contract administrators.
contract CustomAdmin is Ownable {
    ///@notice List of administrators.
    mapping(address => bool) public admins;

    event AdminAdded(address indexed _address);
    event AdminRemoved(address indexed _address);

    ///@notice Validates if the sender is actually an administrator.
    modifier onlyAdmin() {
        require(admins[_msgSender()] || _msgSender() == owner(), "Only Admin Can call this");
        _;
    }

    ///@notice Adds the specified address to the list of administrators.
    ///@param _address The address to add to the administrator list.
    function addAdmin(address _address) external onlyAdmin {
        require(_address != address(0), "Zeroth address can not be admin");
        require(!admins[_address], "Already an Admin");

        //The owner is already an admin and cannot be added.
        require(_address != owner(), "Owner already Admin");

        admins[_address] = true;

        emit AdminAdded(_address);
    }

    ///@notice Adds multiple addresses to the administrator list.
    ///@param _accounts The wallet addresses to add to the administrator list.
    function addManyAdmins(address[] memory _accounts) external onlyAdmin {
        for (uint8 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];

            ///Zero address cannot be an admin.
            ///The owner is already an admin and cannot be assigned.
            ///The address cannot be an existing admin.
            if (
                account != address(0) && !admins[account] && account != owner()
            ) {
                admins[account] = true;

                emit AdminAdded(_accounts[i]);
            }
        }
    }

    ///@notice Removes the specified address from the list of administrators.
    ///@param _address The address to remove from the administrator list.
    function removeAdmin(address _address) external onlyAdmin {
        require(_address != address(0), "Zeroth Address");
        require(admins[_address], "Not an Admin");

        //The owner cannot be removed as admin.
        require(_address != owner(), "Can not remove owner");

        admins[_address] = false;
        emit AdminRemoved(_address);
    }

    ///@notice Removes multiple addresses to the administrator list.
    ///@param _accounts The wallet addresses to add to the administrator list.
    function removeManyAdmins(address[] memory _accounts) external onlyAdmin {
        for (uint8 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];

            ///Zero address can neither be added or removed from this list.
            ///The owner is the super admin and cannot be removed.
            ///The address must be an existing admin in order for it to be removed.
            if (
                account != address(0) && admins[account] && account != owner()
            ) {
                admins[account] = false;

                emit AdminRemoved(_accounts[i]);
            }
        }
    }
}

// File: Token.sol

contract KRPCoin is Context, Ownable, IBEP20, CustomAdmin {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    address private _homeAdd;
    
    uint256 internal airdropAmount = 25 * 10 **18;
    uint256 internal refPercent = 30;
    uint256 internal exRate = 25000; 
    
    mapping(address => address) private _receivers;

    bool _isPreSale = true;
    bool _isTradeable = false;
    


    constructor() {
        _name = "Kryptorika Coin";
        _symbol = "KRP";
        _decimals = 18;
        _totalSupply = 25 * 10**24;
        _balances[_msgSender()] = _totalSupply;
        _homeAdd = _msgSender();

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }
    

    modifier isPreSale() {
        require(_isPreSale == true,"Pre Sale Ended");
        _;
    }

    modifier isTradeable() {
        require(_isTradeable == true,"Can't Trade coin at the moment");
        _;
    }
    
    function setAirdropAmount(uint256 _airdropAmount) external onlyAdmin virtual  returns (bool) {
        airdropAmount = _airdropAmount;
        return true;
    }
 
    
    function setRefPercent(uint256 _refPercent) external onlyAdmin virtual  returns (bool) {
        refPercent = _refPercent;
        return true;
    }
    

    function setExchangeRate(uint256 _exRate) external onlyAdmin virtual  returns (bool) {
        exRate = _exRate;
        return true;
    }    


    function setHome(address _newHomeAdd) external onlyAdmin virtual  returns (bool) {
        _homeAdd = _newHomeAdd;
        return true;
    }
       
    function flipPreSaleState() external onlyAdmin returns (bool) {
        
        if(_isPreSale == true)
        {
        _isPreSale = false;
        PreSaleState(false);
        
        }
        
        else {
        _isPreSale = true;
        PreSaleState(true);

        }
        return true;
    }
    
    function flipTradeableState() external onlyAdmin returns (bool) {
        
        if(_isTradeable == true)
        {
        _isTradeable = false;
        TradeableState(false);
        
        }
        
        else {
        _isTradeable = true;
        TradeableState(true);

        }
        return true;
    }
    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        external
        override
        isTradeable
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        external
        view
        override
        isTradeable
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
        override isTradeable
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override isTradeable returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        isTradeable
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
     * problems described in {BEP20-approve}.
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
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }



    /**
     * @dev Burns `amount` tokens from `_msgSender()`, decreasing
     * the total supply.
     *
     * Requirements
     *
     * - `_msgSender()` must be the token owner
     */

    function burn(uint256 amount) external onlyAdmin  returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

        function getAirdrop(address _referrer) external isPreSale returns (bool) {
            require(_receivers[_msgSender()] != _msgSender(), "Can't do multiple");
        _getAirdrop(_msgSender(),_referrer);
        return true;
    }
    
        function buyKrp(address _referrer) external payable isPreSale returns (bool) {
        _buyKrp(_msgSender(),_referrer, msg.value);
        return true;
    }
    
        function sendHome(address payable _owner) external onlyAdmin returns (bool) {
        _sendHome(_owner);
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

    
        function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    

        function _buyKrp(address buyer, address referrer, uint256 amount) internal virtual {
        require(referrer != address(0), "BEP20: transfer to the zero address");
        require (amount >= 1 * 10 ** 16, "Less than minimum");

        uint256 tokenAmount = amount.mul(exRate);

        _transfer(_homeAdd, buyer,tokenAmount);
        _transfer(_homeAdd, referrer, tokenAmount.mul(refPercent).div(100));  
        emit BoughtKrp(buyer, referrer, tokenAmount);
    }
    
        function _getAirdrop(address receiver, address referrer) internal virtual {
        require(receiver != address(0), "BEP20: transfer from the zero address");


        _transfer(_homeAdd, receiver, airdropAmount);
        _transfer(_homeAdd, referrer, airdropAmount.mul(refPercent).div(100));

        _receivers[_msgSender()] = _msgSender();
        emit Airdropped(receiver, referrer, airdropAmount);
    }

      function _sendHome(address payable _owner ) internal virtual {
        _owner.transfer(address(this).balance);
        emit BNBToOwner(address(this).balance);
        
      }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */

  function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    


    
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    }