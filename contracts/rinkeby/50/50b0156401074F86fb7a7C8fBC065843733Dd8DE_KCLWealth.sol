// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


contract KCLWealth is Ownable {
    
    using SafeMath for uint;
    
    uint totalKCLPoints;
    
    ERC20 public token;
    
    mapping(address => bool) blacklist;
    
    mapping(address => bool) excludeTax;
    
    mapping(address => uint) private myKCLPoints;
    mapping(address => uint) private myKCLRewards;
    mapping(address => uint) private myKCLReferrals;
    mapping(address => bool) public isInvestor;
    
    mapping(address => uint) private lastInvestment;
    
    mapping(address => address) private referrer;
    
    uint[] public packPrices = [50, 100, 500];
    
    uint public tokenDecimals;
    
    uint public adminTax = 10;
    
    uint public distributeTax = 10;
    
    uint public up1Tax = 5;
    
    uint public up2Tax = 2;
    
    uint public up3Tax = 2;
    
    uint public up4Tax = 1;
    
    uint public earlyWithdrawalPercent = 5;
    
    address[] basicInvestors;
    address[] standardInvestors;
    address[] premiumInvestors;
    
    constructor(address _token) {
        token = ERC20(_token);
        tokenDecimals = token.decimals();
        
        packPrices[0] = packPrices[0] * 10 ** tokenDecimals;
        packPrices[1] = packPrices[1] * 10 ** tokenDecimals;
        packPrices[2] = packPrices[2] * 10 ** tokenDecimals;        
        
    }
    
    mapping(address => bool) public isBasic;
    mapping(address => bool) public isStandard;
    mapping(address => bool) public isPremium;
    
    
    function buyKCLPoints(uint plan) public {
        require(plan == 0 || plan == 1 || plan == 2, "Not a valid plan");
        require(!blacklist[msg.sender], "You are blacklisted");
        require(!isInvestor[msg.sender]);
        
        if (plan == 0) {
            isBasic[msg.sender] = true;
        } else if (plan == 1) {
            isStandard[msg.sender] = true;
        } else {
            isPremium[msg.sender] = true;
        }
        
        token.transferFrom(msg.sender, address(this), packPrices[plan]);
        
        uint fullTax = getFullTax();
        
        uint taxed = packPrices[plan].div(100).mul(100 - fullTax);
        
        if (!excludeTax[msg.sender]) {
            myKCLPoints[msg.sender] = myKCLPoints[msg.sender].add(taxed);
            totalKCLPoints = totalKCLPoints.add(taxed);
            isInvestor[msg.sender] = true;
            if (plan == 0) {
                basicInvestors.push(msg.sender);       
            } else if (plan == 1) {
                standardInvestors.push(msg.sender);
            } else {
                premiumInvestors.push(msg.sender);
            }
        } else {
            myKCLPoints[msg.sender] = myKCLPoints[msg.sender].add(packPrices[plan]);
            totalKCLPoints = totalKCLPoints.add(packPrices[plan]);
            isInvestor[msg.sender] = true;
            if (plan == 0) {
                basicInvestors.push(msg.sender);       
            } else if (plan == 1) {
                standardInvestors.push(msg.sender);
            } else {
                premiumInvestors.push(msg.sender);
            }
            return;
        }
        
        
        lastInvestment[msg.sender] = block.timestamp;

        totalKCLPoints = totalKCLPoints.add(taxed);
        
        // Distribute admin percentage
        
        uint adminAmt = packPrices[plan].div(100).mul(adminTax);
        token.transfer(owner(), adminAmt);

        
        // Distribute to holders
        
        if (isBasic[msg.sender]) {
            uint proportionBasic = packPrices[plan].div(100).mul(distributeTax).div(basicInvestors.length);
            for (uint i = 0; i < basicInvestors.length; i++) {
                if (isBasic[basicInvestors[i]]) {
                    myKCLRewards[basicInvestors[i]] = myKCLRewards[basicInvestors[i]].add(proportionBasic);       
                }
            }            
        }
        
        if (isStandard[msg.sender]) {
            uint proportionStandard = packPrices[plan].div(100).mul(distributeTax).div(standardInvestors.length);
            for (uint i = 0; i < standardInvestors.length; i++) {
                if (isStandard[standardInvestors[i]]) {
                    myKCLRewards[standardInvestors[i]] = myKCLRewards[standardInvestors[i]].add(proportionStandard);       
                }
            }            
        }

        if (isPremium[msg.sender]) {
            uint proportionPremium = packPrices[plan].div(100).mul(distributeTax).div(premiumInvestors.length);
            for (uint i = 0; i < premiumInvestors.length; i++) {
                if (isPremium[premiumInvestors[i]]) {
                    myKCLRewards[premiumInvestors[i]] = myKCLRewards[premiumInvestors[i]].add(proportionPremium);       
                }
            }    
        }

        
    }
    
    function buyKCLPoints(address _referrer, uint plan) public {
        require(plan == 0 || plan == 1 || plan == 2, "Not a valid plan");
        require(!blacklist[msg.sender], "You are blacklisted");
        require(!isInvestor[msg.sender]);
        
        if (plan == 0) {
            isBasic[msg.sender] = true;
        } else if (plan == 1) {
            isStandard[msg.sender] = true;
        } else {
            isPremium[msg.sender] = true;
        }
        
        token.transferFrom(msg.sender, address(this), packPrices[plan]);
        
        uint fullTax = getFullTax();
        
        referrer[msg.sender] = _referrer;
        
        uint taxed = packPrices[plan].div(100).mul(100 - fullTax);
        
        if (!excludeTax[msg.sender]) {
            myKCLPoints[msg.sender] = myKCLPoints[msg.sender].add(taxed);
            totalKCLPoints = totalKCLPoints.add(taxed);
            isInvestor[msg.sender] = true;
            if (plan == 0) {
                basicInvestors.push(msg.sender);       
            } else if (plan == 1) {
                standardInvestors.push(msg.sender);
            } else {
                premiumInvestors.push(msg.sender);
            }
        } else {
            myKCLPoints[msg.sender] = myKCLPoints[msg.sender].add(packPrices[plan]);
            totalKCLPoints = totalKCLPoints.add(packPrices[plan]);
            isInvestor[msg.sender] = true;
            if (plan == 0) {
                basicInvestors.push(msg.sender);       
            } else if (plan == 1) {
                standardInvestors.push(msg.sender);
            } else {
                premiumInvestors.push(msg.sender);
            }
            return;
        }
        
        
        lastInvestment[msg.sender] = block.timestamp;
        
        // Distribute admin percentage
        
        uint adminAmt = packPrices[plan].div(100).mul(adminTax);
        token.transfer(owner(), adminAmt);
        
        // Distribute to holders
        
        
        if (isBasic[msg.sender]) {
            uint proportionBasic = packPrices[plan].div(100).mul(distributeTax).div(basicInvestors.length);
            for (uint i = 0; i < basicInvestors.length; i++) {
                if (isBasic[basicInvestors[i]]) {
                    myKCLRewards[basicInvestors[i]] = myKCLRewards[basicInvestors[i]].add(proportionBasic);       
                }
            }            
        }
        
        if (isStandard[msg.sender]) {
            uint proportionStandard = packPrices[plan].div(100).mul(distributeTax).div(standardInvestors.length);
            for (uint i = 0; i < standardInvestors.length; i++) {
                if (isStandard[standardInvestors[i]]) {
                    myKCLRewards[standardInvestors[i]] = myKCLRewards[standardInvestors[i]].add(proportionStandard);       
                }
            }            
        }

        if (isPremium[msg.sender]) {
            uint proportionPremium = packPrices[plan].div(100).mul(distributeTax).div(premiumInvestors.length);
            for (uint i = 0; i < premiumInvestors.length; i++) {
                if (isPremium[premiumInvestors[i]]) {
                    myKCLRewards[premiumInvestors[i]] = myKCLRewards[premiumInvestors[i]].add(proportionPremium);       
                }
            }    
        }

        // Distribute uplines
        address up = _referrer;
        
        uint counter = 1;
        if (referrer[up] != address(0)) {
            while (referrer[up] != address(0)) {
                counter++;
                if (counter < 5) {
                    up = referrer[up];
                    if (counter == 2) {
                        myKCLReferrals[up] = myKCLReferrals[up].add(packPrices[plan].div(100).mul(up2Tax));
                    } else if (counter == 3) {
                        myKCLReferrals[up] = myKCLReferrals[up].add(packPrices[plan].div(100).mul(up3Tax));
                    } else {
                        myKCLReferrals[up] = myKCLReferrals[up].add(packPrices[plan].div(100).mul(up4Tax));                 
                    }                    
                } else {
                    break;
                }
            }
        } else {
            uint directTax = packPrices[plan].div(100).mul(up1Tax);
            myKCLReferrals[up] = myKCLReferrals[up].add(directTax);
        }

    }
    
    // Get Functions
    
    function getKCLPoints() public view returns(uint) {
        return myKCLPoints[msg.sender];
    }
    
    function getRewardBalance() public view returns(uint) {
        return myKCLRewards[msg.sender];
    }
    
    function getReferralBalance() public view returns(uint) {
        return myKCLReferrals[msg.sender];
    }
    
    function getMyPlan() public view returns(uint) {
        if (isBasic[msg.sender]) {
            return 0;
        } else if (isStandard[msg.sender]) {
            return 1;
        } else if (isPremium[msg.sender]) {
            return 2;
        } else {
            return 200;
        }
        
    }
    
    // Withdraw Functions
    
    function withdrawPoints() public {
        require(myKCLPoints[msg.sender] > 0, "You don't have any KCL Points");
        
        isBasic[msg.sender] = false;
        isStandard[msg.sender] = false;
        isPremium[msg.sender] = false;

        isInvestor[msg.sender] = false;
        
        uint withdraw = myKCLPoints[msg.sender];
        myKCLPoints[msg.sender] = 0;
        if ((block.timestamp < lastInvestment[msg.sender] + 60 days) && !excludeTax[msg.sender]) {
            uint taxed = withdraw.div(100).mul(100-earlyWithdrawalPercent);
            token.transfer(msg.sender, taxed);
        } else {
            
            token.transfer(msg.sender, withdraw);

        }
    }
    
    function withdrawReferrals() public {
        require(myKCLReferrals[msg.sender] > 0, "You don't have any referral rewards");
        uint withdraw = myKCLReferrals[msg.sender];
        myKCLReferrals[msg.sender] = 0;
        token.transfer(msg.sender, withdraw);

    }
    
    function withdrawRewards() public {
        require(myKCLRewards[msg.sender] > 0, "You don't have any rewards");
        uint withdraw = myKCLRewards[msg.sender];
        myKCLRewards[msg.sender] = 0;
        token.transfer(msg.sender, withdraw);

    }
    
    // Tax functions / Admin Functions
    
    function getFullTax() public view returns(uint) {
        uint fullTax = SafeMath.add(adminTax, distributeTax).add(up1Tax).add(up2Tax).add(up3Tax).add(up4Tax);
        return fullTax;
    }
    
    function changeAdminTax(uint _newTax) public onlyOwner {
        adminTax = _newTax;
    }
    
    function changeDistributionTax(uint _newTax) public onlyOwner {
        distributeTax = _newTax;
    }
    
    function changeUp1Tax(uint _newTax) public onlyOwner {
        up1Tax = _newTax;
    }
    
    function changeUp2Tax(uint _newTax) public onlyOwner {
        up2Tax = _newTax;
    }
    
    function changeUp3Tax(uint _newTax) public onlyOwner {
        up3Tax = _newTax;
    }
    
    function changeUp4Tax(uint _newTax) public onlyOwner {
        up4Tax = _newTax;
    }
    
    function changeEarlyWithdrawalTax(uint _newTax) public onlyOwner {
        earlyWithdrawalPercent = _newTax;
    }
    
    function blackListAddress(address _user) public onlyOwner {
        blacklist[_user] = true;
    }
    
    function excludeFromTax(address _user) public onlyOwner {
        excludeTax[_user] = true;
    }
    
    function changeAdminWallet(address _newWallet) public onlyOwner {
        transferOwnership(_newWallet);
    }
    
    function setBasicPrice(uint _newPrice) public onlyOwner {
        packPrices[0] = _newPrice;
    }
    
    function setStandardPrice(uint _newPrice) public onlyOwner {
        packPrices[1] = _newPrice;
    }
    
    function setPremiumPrice(uint _newPrice) public onlyOwner {
        packPrices[2] = _newPrice;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}