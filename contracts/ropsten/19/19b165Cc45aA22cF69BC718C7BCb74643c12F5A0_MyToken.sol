/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.6;

/**
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MyToken is Context, IERC20, Ownable {
    
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) private _allowances;

	struct Holder {
		address _address;
		bool _isValid;
	}
	mapping (address => uint256) private addressToIndex;
	mapping (uint256 => Holder) private indexToHolder;
	uint256 public lastIndexUsed = 0;
	
    string private _name = "MyToken";
    string private _symbol = "MTK";
    uint8 private _decimals= 9;
    uint256 private _totalSupply = 100000000000000 * 10 ** _decimals;
    
    //Tokenomics rates
    uint8 public communityFundRate = 1;
    uint8 public liquidityPoolFundRate = 1;
    uint8 public burnFundRate = 1;
    uint8 public redistributionFundRate = 1;
    
    //Tokenomics funds
    uint256 public communityFunds = 0;
    uint256 public liquidityPoolFunds = 0;
    uint256 public burnedFunds = 0;

    function addHolder (address walletAddress) private {
        if (addressToIndex[walletAddress] != 0) {
            return;
        }
        uint256 index = lastIndexUsed +1;
        
		indexToHolder[index] = Holder({
		    _address: walletAddress,
		    _isValid: true
		});
		
		addressToIndex[walletAddress] = index;
		lastIndexUsed = index;
	}
	
	function removeHolder (address walletAddress) private {
	    if (addressToIndex[walletAddress] == 0) {
            return;
        }
        uint256 index = addressToIndex[walletAddress];
        addressToIndex[walletAddress] = 0;
        
        if (index != lastIndexUsed) {
            indexToHolder[index] = indexToHolder[lastIndexUsed];
            addressToIndex[indexToHolder[lastIndexUsed]._address] = index;
        }
        indexToHolder[lastIndexUsed]._isValid = false;
        lastIndexUsed = lastIndexUsed - 1;
	}
	
    /**
     * @dev Constructor
     *
     */
    constructor() {
        _balance[_msgSender()] += _totalSupply;
        addHolder(_msgSender());
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
        return _balance[account];
    }
    
    /**
     * @dev Change communityFundRate
     */
    function changeCommunityFundRate(uint8 newRate) public onlyOwner {
        require(newRate <= 3, "Tokenomics: new rate can't exceed 3");
        communityFundRate = newRate;
    }
    
    /**
     * @dev Change liquidityPoolFundRate
     */
    function changeLiquidityPoolFundRate(uint8 newRate) public onlyOwner {
        require(newRate <= 3, "Tokenomics: new rate can't exceed 3");
        liquidityPoolFundRate = newRate;
    }
    
    /**
     * @dev Change burnFundRate
     */
    function changeBurnFundRate(uint8 newRate) public onlyOwner {
        require(newRate <= 3, "Tokenomics: new rate can't exceed 3");
        burnFundRate = newRate;
    }
    
    /**
     * @dev Change redistributionFundRate
     */
    function changeRedistributionFundRate(uint8 newRate) public onlyOwner {
        require(newRate <= 3, "Tokenomics: new rate can't exceed 3");
        redistributionFundRate = newRate;
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
        uint256 senderBalance = _balance[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        (uint256 amountAfterFees, uint256 redistributionAmount) = _beforeTokenTransfer(amount);
        unchecked {
            _balance[sender] = senderBalance - amount;
        }
        _balance[recipient] += amountAfterFees;
        
        _afterTokenTransfer(sender,recipient,redistributionAmount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Destroys `amount` of tokens, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     */
    function burnToken(uint256 amount) private {
        _totalSupply -= amount;
        emit Transfer(_msgSender(), address(0), amount);
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
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * calculating community,liquidity,burn and distribution funds.
     *
     */
    function _beforeTokenTransfer(
        uint256 amount
    ) private returns (uint256, uint256) {
        uint extractedCommunityFund = amount * communityFundRate / 100;
        uint extractedLiquidityPoolFund =  amount * liquidityPoolFundRate / 100;
        uint extractedBurnFund =  amount * burnFundRate / 100;
        uint extractedRedistrbution = amount * redistributionFundRate / 100;
        communityFunds += extractedCommunityFund;
        liquidityPoolFunds += extractedLiquidityPoolFund;
        burnedFunds += extractedBurnFund;
        burnToken(extractedBurnFund);
        uint256 newAmount = amount - extractedCommunityFund - extractedLiquidityPoolFund - extractedBurnFund - extractedRedistrbution;
        return (newAmount, extractedRedistrbution);
    }
    
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * keeping track of holders and making distrbution.
     *
     */
    function _afterTokenTransfer(
        address sender,
        address recipient,
        uint256 redistributionAmount
    ) private  {
        if (_balance[recipient] > 0 && recipient != address(this)){
        	addHolder(recipient);
        }
        if (_balance[sender] == 0 && sender != address(this)) {
        	removeHolder(sender);
        }
        
        for (uint256 i = 1; i < lastIndexUsed; i++) {
            if(indexToHolder[i]._isValid == true 
            && indexToHolder[i]._address != sender 
            && indexToHolder[i]._address != recipient ){
                _balance[indexToHolder[i]._address] += redistributionAmount / lastIndexUsed;
            }
        }
    }
    
    function withdrawCommunityFunds (address walletAddress, uint256 amount) public onlyOwner {
        require(walletAddress != address(0), "Tokenomics: can't withdraw to the zero address");
        require(amount < communityFunds, "Tokenomics: amount exceeds communityFund");
        communityFunds -= amount;
        _balance[walletAddress] += amount;
        addHolder(walletAddress);
        emit Transfer(address(this), walletAddress, amount);
    }

}