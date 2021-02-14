/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;



// Part: BoostersStringUtils

library BoostersStringUtils {

    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b)  internal pure returns (bool) {
        return compare(_a, _b) == 0;
    }

    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int) {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
    				{
    					subindex++;
    				}	
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }
}

// Part: Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: IERC20

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// Part: IERC721Receiver

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// Part: ISIGHBoosters

interface ISIGHBoosters {

    // ########################
    // ######## EVENTS ########
    // ########################

    event baseURIUpdated(string baseURI);
    event newCategoryAdded(string _type, uint256 _platformFeeDiscount_, uint256 _sighPayDiscount_, uint256 _maxBoosters);
    event BoosterMinted(address _owner, string _type,string boosterURI,uint256 newItemId,uint256 totalBoostersOfThisCategory);
    event boosterURIUpdated(uint256 boosterId, string _boosterURI);
    event discountMultiplierUpdated(string _type,uint256 _platformFeeDiscount_,uint256 _sighPayDiscount_ );

    event BoosterWhiteListed(uint256 boosterId);
    event BoosterBlackListed(uint256 boosterId);

    // #################################
    // ######## ADMIN FUNCTIONS ########
    // #################################
    
    function addNewBoosterType(string memory _type, uint256 _platformFeeDiscount_, uint256 _sighPayDiscount_, uint256 _maxBoosters) external returns (bool) ;
    function createNewBoosters(address _owner, string[] memory _type,  string[] memory boosterURI) external returns (uint256);
    function createNewSIGHBooster(address _owner, string memory _type,  string memory boosterURI, bytes memory _data ) external returns (uint256) ;
    function _updateBaseURI(string memory baseURI )  external ;
    function updateBoosterURI(uint256 boosterId, string memory boosterURI )  external returns (bool) ;
    function updateDiscountMultiplier(string memory _type, uint256 _platformFeeDiscount_,uint256 _sighPayDiscount_)  external returns (bool) ;

    function blackListBooster(uint256 boosterId) external;
    function whiteListBooster(uint256 boosterId) external;
    // ###########################################
    // ######## STANDARD ERC721 FUNCTIONS ########
    // ###########################################

    function name() external view  returns (string memory) ;
    function symbol() external view  returns (string memory) ;
    function totalSupply() external view  returns (uint256) ;
    function baseURI() external view returns (string memory) ;

    function tokenByIndex(uint256 index) external view  returns (uint256) ;

    function balanceOf(address _owner) external view returns (uint256 balance) ;    // Returns total number of Boosters owned by the _owner
    function tokenOfOwnerByIndex(address owner, uint256 index) external view  returns (uint256) ; //  See {IERC721Enumerable-tokenOfOwnerByIndex}.

    function ownerOfBooster(uint256 boosterId) external view returns (address owner) ; // Returns current owner of the Booster having the ID = boosterId
    function tokenURI(uint256 boosterId) external view  returns (string memory) ;   // Returns the boostURI for the Booster

    function approve(address to, uint256 boosterId) external ;  // A BOOSTER owner can approve anyone to be able to transfer the underlying booster
    function setApprovalForAll(address operator, bool _approved) external;


    function getApproved(uint256 boosterId) external view  returns (address);   // Returns the Address currently approved for the Booster with ID = boosterId
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(address from, address to, uint256 boosterId) external;
    function safeTransferFrom(address from, address to, uint256 boosterId) external;
    function safeTransferFrom(address from, address to, uint256 boosterId, bytes memory data) external;

    // #############################################################
    // ######## FUNCTIONS SPECIFIC TO SIGH FINANCE BOOSTERS ########
    // #############################################################

    function getAllBoosterTypes() external view returns (string[] memory);

    function isCategorySupported(string memory _category) external view returns (bool);
    function getDiscountRatiosForBoosterCategory(string memory _category) external view returns ( uint platformFeeDiscount, uint sighPayDiscount );

    function totalBoostersAvailable(string memory _category) external view returns (uint256);
    function maxBoostersAllowed(string memory _category) external view returns (uint256);

    function totalBoostersOwnedOfType(address owner, string memory _category) external view returns (uint256) ;  // Returns the number of Boosters of a particular category owned by the owner address

    function isValidBooster(uint256 boosterId) external view returns (bool);
    function getBoosterCategory(uint256 boosterId) external view returns ( string memory boosterType );
    function getDiscountRatiosForBooster(uint256 boosterId) external view returns ( uint platformFeeDiscount, uint sighPayDiscount );
    function getBoosterInfo(uint256 boosterId) external view returns (address farmer, string memory boosterType,uint platformFeeDiscount, uint sighPayDiscount, uint _maxBoosters );

    function isBlacklisted(uint boosterId) external view returns(bool) ;
//     function getAllBoosterTypesSupported() external view returns (string[] memory) ;

}

// Part: ISIGHBoostersSale

interface ISIGHBoostersSale {

    event BoosterAddedForSale(string _type,uint boosterid);
    event SalePriceUpdated(string _type,uint _price);
    event PaymentTokenUpdated(address token);
    event FundsTransferred(uint amount);
    event TokensTransferred(address token,address to,uint amount);
    event SaleTimeUpdated(uint initiateTimestamp);
    event BoosterSold(address _to, string _BoosterType,uint _boosterId, uint salePrice );
    event BoostersBought(address caller,address receiver,string _BoosterType,uint boostersBought,uint amountToBePaid);
    event BoosterAdded(address operator,address from,uint tokenId);

    // #################################
    // ######## ADMIN FUNCTIONS ########
    // #################################

    // Add a list of Boosters for sale at a particular price
//    function addBoostersForSale(string calldata _BoosterType, uint[] memory boosterIds) external;

    // Update the sale price for a particular type of Boosters
    function updateSalePrice(string calldata _BoosterType, uint256 _price ) external;

    // Update the token accepted as payment
    function updateAcceptedToken(address token) external;

    // Transfer part of the the token collected for payments to the 'to' address
    function transferBalance(address to, uint amount) external;

    // Updates time when the Booster sale will go live
    function updateSaleTime(uint timestamp) external;

    function transferTokens(address token, address to, uint amount) external ;
    // ##########################################
    // ######## FUNCTION TO BY BOOSTERS  ########
    // ##########################################

    // Buy the 'boostersToBuy' no. of Boosters for the '_BoosterType' type of boosters
    function buyBoosters(address receiver, string memory _BoosterType, uint boostersToBuy) external;

    // #########################################
    // ######## EXTERNAL VIEW FUNCTIONS ########
    // #########################################

    // Get the current available no. of boosters, its price and total sold for the provided Booster category
    function getBoosterSaleDetails(string memory _Boostertype) external view returns (uint256 available,uint256 price, uint256 sold);

    // Get the symbol and address of the token accepted for payments
    function getTokenAccepted() external view returns(string memory symbol, address tokenAddress);

    // Get current balance of the token accepted for payments.
    function getCurrentFundsBalance() external view returns (uint256);

    function getTokenBalance(address token) external view returns (uint256) ;

}

// Part: SafeMath

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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Part: ERC20

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

// Part: Ownable

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

// File: SIGHBoostersSale.sol

contract SIGHBoostersSale is IERC721Receiver,Ownable,ISIGHBoostersSale {

    using BoostersStringUtils for string;
    using SafeMath for uint256;

    ISIGHBoosters private _SIGH_NFT_BoostersContract;    // SIGH Finance NFT Boosters Contract
    uint public initiateTimestamp;

    ERC20 private tokenAcceptedAsPayment;         // Address of token accepted as payment

    struct boosterList {
        uint256 totalAvailable;             // No. of Boosters of a particular type currently available for sale
        uint256[] boosterIdsList;          // List of BoosterIds for the boosters of a particular type currently available for sale
        uint256 salePrice;                  // Sale price for a particular type of Booster
        uint256 totalBoostersSold;           // Boosters sold
    }

    mapping (string => boosterList) private listOfBoosters;   // (Booster Type => boosterList struct)
    mapping (uint256 => bool) private boosterIdsForSale;      // Booster Ids that have been included for sale
    mapping (string => bool) private boosterTypes;            // Booster Type => Yes/No

    constructor(address _SIGHNFTBoostersContract) {
        require(_SIGHNFTBoostersContract != address(0),'SIGH Finance : Invalid _SIGHNFTBoostersContract address');
        _SIGH_NFT_BoostersContract = ISIGHBoosters(_SIGHNFTBoostersContract);
    }

    // #################################
    // ######## ADMIN FUNCTIONS ########
    // #################################

//    function addBoostersForSale(uint256[] memory boosterids) external override onlyOwner {
//
//        for (uint i; i < boosterids.length; i++ ) {
//            addBoosterForSaleInternal(boosterids[i]);
//        }
//    }

    // Updates the Sale price for '_BoosterType' type of Boosters. Only owner can call this function
    function updateSalePrice(string memory _BoosterType, uint256 _price ) external override onlyOwner {
        require( _SIGH_NFT_BoostersContract.isCategorySupported(_BoosterType),"Invalid Type");
        require( boosterTypes[_BoosterType] ,"Not yet initialized");
        listOfBoosters[_BoosterType].salePrice = _price;
        emit SalePriceUpdated(_BoosterType,_price);
    }

    // Update the token accepted as payment
    function updateAcceptedToken(address token) external override onlyOwner {
        require( token != address(0) ,"Invalid address");
        tokenAcceptedAsPayment = ERC20(token);
        emit PaymentTokenUpdated(token);
    }

    // Transfers part of the collected Funds to the 'to' address . Only owner can call this function
    function transferBalance(address to, uint amount) external override onlyOwner {
        require( to != address(0) ,"Invalid address");
        require( amount <= getCurrentFundsBalance() ,"Invalid amount");
        tokenAcceptedAsPayment.transfer(to,amount);
        emit FundsTransferred(amount);
    }

    // Updates time when the Booster sale will go live
    function updateSaleTime(uint timestamp) external override onlyOwner {
        require( block.timestamp < timestamp,'Invalid stamp');
        initiateTimestamp = timestamp;
        emit SaleTimeUpdated(initiateTimestamp);
    }

    // Transfers part of the collected DAI to the 'to' address . Only owner can call this function
    function transferTokens(address token, address to, uint amount) external override onlyOwner {
        require( to != address(0) ,"Invalid address");
        ERC20 token_ = ERC20(token);
        uint balance = token_.balanceOf(address(this));
        require( amount <= balance ,"Invalid amount");
        token_.transfer(to,amount);
        emit TokensTransferred(token,to,amount);
    }

    // ###########################################
    // ######## FUNCTION TO BUY A BOOSTER ########
    // ###########################################

    function buyBoosters(address receiver, string memory _BoosterType, uint boostersToBuy) override external {
        require( block.timestamp > initiateTimestamp,'Sale not begin');
        require(listOfBoosters[_BoosterType].salePrice > 0 ,"Price cannot be Zero");
        require(boosterTypes[_BoosterType],"Invalid Booster Type");
        require(boostersToBuy >= 1,"Invalid number of boosters");
        require(listOfBoosters[_BoosterType].totalAvailable >=  boostersToBuy,"Boosters not available");

        uint amountToBePaid = boostersToBuy.mul(listOfBoosters[_BoosterType].salePrice);

        require(transferFunds(msg.sender,amountToBePaid),'Funds transfer Failed');
        require(transferBoosters(receiver, _BoosterType, boostersToBuy),'Boosters transfer Failed');

        emit BoostersBought(msg.sender,receiver,_BoosterType,boostersToBuy,amountToBePaid);
    }


    // #########################################
    // ######## EXTERNAL VIEW FUNCTIONS ########
    // #########################################

    function getBoosterSaleDetails(string memory _Boostertype) external view override returns (uint256 available,uint256 price, uint256 sold) {
        require( _SIGH_NFT_BoostersContract.isCategorySupported(_Boostertype),"SIGH Finance : Not a valid Booster Type");
        available = listOfBoosters[_Boostertype].totalAvailable;
        price = listOfBoosters[_Boostertype].salePrice;
        sold = listOfBoosters[_Boostertype].totalBoostersSold;
    }

    function getTokenAccepted() public view override returns(string memory symbol, address tokenAddress) {
        require( address(tokenAcceptedAsPayment) != address(0) );
        symbol = tokenAcceptedAsPayment.symbol();
        tokenAddress = address(tokenAcceptedAsPayment);
    }

    function getCurrentFundsBalance() public view override returns (uint256) {
        require( address(tokenAcceptedAsPayment) != address(0) );
        return tokenAcceptedAsPayment.balanceOf(address(this));
    }

    function getTokenBalance(address token) public view override returns (uint256) {
        require( token != address(0) );
        ERC20 token_ = ERC20(token);
        uint balance = token_.balanceOf(address(this));
        return balance;
    }

    // ####################################
    // ######## INTERNAL FUNCTIONS ########
    // ####################################

    function addBoosterForSaleInternal(uint256 boosterId) internal {
        require( !boosterIdsForSale[boosterId], "Already Added");
        ( , string memory _BoosterType, , ,) = _SIGH_NFT_BoostersContract.getBoosterInfo(boosterId);

        if (!boosterTypes[_BoosterType]) {
            boosterTypes[_BoosterType] = true;
        }

        listOfBoosters[_BoosterType].boosterIdsList.push( boosterId ); // ADDED the boosterID to the list of Boosters available for sale
        listOfBoosters[_BoosterType].totalAvailable = listOfBoosters[_BoosterType].totalAvailable.add(1); // Incremented total available by 1
        boosterIdsForSale[boosterId] = true;
        require( _SIGH_NFT_BoostersContract.ownerOfBooster(boosterId) == address(this) ); // ONLY SIGH BOOSTERS CAN BE SENT TO THIS CONTRACT

        emit BoosterAddedForSale(_BoosterType , boosterId);
    }

    // Transfers 'totalBoosters' number of BOOSTERS of type '_BoosterType' to the 'to' address
    function transferBoosters(address to, string memory _BoosterType, uint totalBoosters) internal returns (bool) {
        uint listLength = listOfBoosters[_BoosterType].boosterIdsList.length;

        for (uint i=0; i < totalBoosters; i++ ) {
            uint256 _boosterId = listOfBoosters[_BoosterType].boosterIdsList[0];  // current BoosterID

            if (boosterIdsForSale[_boosterId]) {
                // Transfer the Booster and Verify the same
                _SIGH_NFT_BoostersContract.safeTransferFrom(address(this),to,_boosterId);
                require(to == _SIGH_NFT_BoostersContract.ownerOfBooster(_boosterId),"Booster Transfer failed");

                // Remove the Booster ID
                listOfBoosters[_BoosterType].boosterIdsList[0] = listOfBoosters[_BoosterType].boosterIdsList[listLength.sub(1)];
                listOfBoosters[_BoosterType].boosterIdsList.pop();
                listLength = listLength.sub(1);

                // Update the number of boosters available & sold
                listOfBoosters[_BoosterType].totalAvailable = listOfBoosters[_BoosterType].totalAvailable.sub(1);
                listOfBoosters[_BoosterType].totalBoostersSold = listOfBoosters[_BoosterType].totalBoostersSold.add(1);

                // Mark the BoosterID as sold and update the counter
                boosterIdsForSale[_boosterId] = false;

                emit BoosterSold(to, _BoosterType, _boosterId, listOfBoosters[_BoosterType].salePrice );
            }
        }
        return true;
    }

    // Transfers 'amount' of DAI to the contract
    function transferFunds(address from, uint amount) internal returns (bool) {
        uint prevBalance = tokenAcceptedAsPayment.balanceOf(address(this));
        tokenAcceptedAsPayment.transferFrom(from,address(this),amount);
        uint newBalance = tokenAcceptedAsPayment.balanceOf(address(this));
        require(newBalance == prevBalance.add(amount),'Funds Transfer failed');
        return true;
    }

    // ############################################
    // ######## onERC721Received FUNCTIONS ########
    // ############################################

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory _data) public virtual override returns (bytes4) {
        addBoosterForSaleInternal(tokenId);
        emit BoosterAdded(operator,from,tokenId);
        return this.onERC721Received.selector;
    }
}