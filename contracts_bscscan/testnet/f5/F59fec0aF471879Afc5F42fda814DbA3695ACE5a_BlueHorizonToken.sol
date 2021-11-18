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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlueHorizonToken is Ownable, ERC20 {
    uint256 public constant MONTH_IN_SECONDS = 30 * 86400;
    uint256 public constant MAX_SUPPLY = 100000000e18; // 100,000,000

    uint256 public constant SEED_SALE = 3500000e18; // 3.5%
    uint256 public constant PRIVATE_SALE = 15500000e18; // 15.5%
    uint256 public constant PUBLIC_SALE = 3000000e18; // 3%
    uint256 public constant LIQUIDITY = 5000000e18; // 5%

    uint256 public constant TEAM = 8000000e18; // 8%
    uint256 public constant ADVISOR = 5000000e18; // 5%
    uint256 public constant DEVELOPMENT = 10000000e18; // 10%
    uint256 public constant MARKETING = 10000000e18; // 10%
    uint256 public constant FARMING = 40000000e18; // 40%

    uint256 public initTime;

    address public masterChef;
    address public nftMasterChef;

    uint256 public seedSaleUnlocked = 0;
    uint256 public privateSaleUnlocked = 0;
    uint256 public teamUnlocked = 0;
    uint256 public advisorUnlocked = 0;
    uint256 public developmentUnlocked = 0;
    uint256 public marketingUnlocked = 0;
    uint256 public farmingUnlocked = 0;

    constructor(uint256 _initTime, address _recipient) ERC20("BlueHorizon", "BLH") {
        initTime = _initTime != 0 ? _initTime : block.timestamp;

        uint256 totalUnlocked = 0;
        totalUnlocked += PUBLIC_SALE;
        totalUnlocked += LIQUIDITY;
        _mint(_recipient, totalUnlocked);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            require(
                totalSupply() + amount <= MAX_SUPPLY,
                "BlueHorizonToken::_beforeTokenTransfer::MAX_SUPPLY_EXCEEDED"
            );
        }
    }

    /**
     * @dev mint tokens for masterChef
     * callable by masterChef contracts only
     */
    function mint(address _recipient, uint256 _amount) public {
        require(msg.sender == masterChef || msg.sender == nftMasterChef, "BlueHorizonToken::mint::MASTER_ONLY");
        require(FARMING >= _amount, "BlueHorizonToken::mint::LIMIT_EXCEEDED");

        uint256 amount = mintableFarming();
        amount = amount > _amount ? _amount : amount;
        if (amount > 0) {
            farmingUnlocked += amount;
            _mint(_recipient, amount);
        }
    }

    /**
     * @dev mintable tokens for farming
     */
    function mintableFarming() public view returns (uint256) {
        if (initTime == 0) return 0;
        uint256 startReleasing = initTime;
        if (startReleasing > block.timestamp) return 0;

        uint256 gap = block.timestamp - startReleasing;
        uint256 months = gap / MONTH_IN_SECONDS + 1;
        uint256 totalMintable = (months * FARMING) / 24;
        if (totalMintable > FARMING) {
            totalMintable = FARMING;
        }
        return totalMintable - farmingUnlocked;
    }

    /**
     * @dev mintable tokens for seed sale
     */
    function mintableSeedSale() public view returns (uint256) {
        if (initTime == 0) return 0;
        uint256 startReleasing = initTime;
        if (startReleasing > block.timestamp) return 0;

        uint256 gap = block.timestamp - startReleasing;
        uint256 months = gap / MONTH_IN_SECONDS + 1;
        uint256 totalMintable = (months * SEED_SALE) / 12;
        if (totalMintable > SEED_SALE) {
            totalMintable = SEED_SALE;
        }
        return totalMintable - seedSaleUnlocked;
    }

    /**
     * @dev mintable tokens for private sale
     */
    function mintablePrivateSale() public view returns (uint256) {
        if (initTime == 0) return 0;
        uint256 startReleasing = initTime;
        if (startReleasing > block.timestamp) return 0;

        uint256 gap = block.timestamp - startReleasing;
        uint256 months = gap / MONTH_IN_SECONDS + 1;
        uint256 totalMintable = (months * PRIVATE_SALE) / 6;
        if (totalMintable > PRIVATE_SALE) {
            totalMintable = PRIVATE_SALE;
        }
        return totalMintable - privateSaleUnlocked;
    }

    /**
     * @dev mintable tokens for team
     */
    function mintableTeam() public view returns (uint256) {
        if (initTime == 0) return 0;
        uint256 startReleasing = initTime + 3 * MONTH_IN_SECONDS;
        if (startReleasing > block.timestamp) return 0;

        uint256 gap = block.timestamp - startReleasing;
        uint256 months = gap / MONTH_IN_SECONDS + 1;
        uint256 totalMintable = (months * TEAM) / 15;
        if (totalMintable > TEAM) {
            totalMintable = TEAM;
        }
        return totalMintable - teamUnlocked;
    }

    /**
     * @dev mintable tokens for advisor
     */
    function mintableAdvisor() public view returns (uint256) {
        if (initTime == 0) return 0;
        uint256 startReleasing = initTime + 3 * MONTH_IN_SECONDS;
        if (startReleasing > block.timestamp) return 0;

        uint256 gap = block.timestamp - startReleasing;
        uint256 months = gap / MONTH_IN_SECONDS + 1;
        uint256 totalMintable = (months * ADVISOR) / 9;
        if (totalMintable > ADVISOR) {
            totalMintable = ADVISOR;
        }
        return totalMintable - advisorUnlocked;
    }

    /**
     * @dev mintable tokens for development
     */
    function mintableDevelopment() public view returns (uint256) {
        if (initTime == 0) return 0;
        uint256 startReleasing = initTime + 1 * MONTH_IN_SECONDS;
        if (startReleasing > block.timestamp) return 0;

        uint256 gap = block.timestamp - startReleasing;
        uint256 months = gap / MONTH_IN_SECONDS + 1;
        uint256 totalMintable = (months * DEVELOPMENT) / 23;
        if (totalMintable > DEVELOPMENT) {
            totalMintable = DEVELOPMENT;
        }
        return totalMintable - developmentUnlocked;
    }

    /**
     * @dev mintable tokens for marketing
     */
    function mintableMarketing() public view returns (uint256) {
        if (initTime == 0) return 0;
        uint256 startReleasing = initTime + 1 * MONTH_IN_SECONDS;
        if (startReleasing > block.timestamp) return 0;

        uint256 gap = block.timestamp - startReleasing;
        uint256 months = gap / MONTH_IN_SECONDS + 1;
        uint256 totalMintable = (months * MARKETING) / 23;
        if (totalMintable > MARKETING) {
            totalMintable = MARKETING;
        }
        return totalMintable - marketingUnlocked;
    }

    /**
     * @dev mint tokens for seed sale
     * callable by owner
     */
    function mintSeedSale(address _recipient) external onlyOwner {
        uint256 mintable = mintableSeedSale();
        if (mintable > 0) {
            seedSaleUnlocked += mintable;
            _mint(_recipient, mintable);
        }
    }

    /**
     * @dev mint tokens for private sale
     * callable by owner
     */
    function mintPrivateSale(address _recipient) external onlyOwner {
        uint256 mintable = mintablePrivateSale();
        if (mintable > 0) {
            privateSaleUnlocked += mintable;
            _mint(_recipient, mintable);
        }
    }

    /**
     * @dev mint tokens for team
     * callable by owner
     */
    function mintTeam(address _recipient) external onlyOwner {
        uint256 mintable = mintableTeam();
        if (mintable > 0) {
            teamUnlocked += mintable;
            _mint(_recipient, mintable);
        }
    }

    /**
     * @dev mint tokens for advisor
     * callable by owner
     */
    function mintAdvisor(address _recipient) external onlyOwner {
        uint256 mintable = mintableAdvisor();
        if (mintable > 0) {
            advisorUnlocked += mintable;
            _mint(_recipient, mintable);
        }
    }

    /**
     * @dev mint tokens for development
     * callable by owner
     */
    function mintDevelopment(address _recipient) external onlyOwner {
        uint256 mintable = mintableDevelopment();
        if (mintable > 0) {
            developmentUnlocked += mintable;
            _mint(_recipient, mintable);
        }
    }

    /**
     * @dev mint tokens for marketing
     * callable by owner
     */
    function mintMarketing(address _recipient) external onlyOwner {
        uint256 mintable = mintableMarketing();
        if (mintable > 0) {
            marketingUnlocked += mintable;
            _mint(_recipient, mintable);
        }
    }

    /**
     * @dev set masterChef
     * callable by owner
     */
    function setMaster(address _masterChef) external onlyOwner {
        require(_masterChef != address(0), "BlueHorizonToken::setMaster::INVALID");
        masterChef = _masterChef;
    }

    /**
     * @dev set nftMasterChef
     * callable by owner
     */
    function setNftMaster(address _masterChef) external onlyOwner {
        require(_masterChef != address(0), "BlueHorizonToken::setNftMaster::INVALID");
        nftMasterChef = _masterChef;
    }
}