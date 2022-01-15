// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFactory.sol";
import "./TicketToken.sol";
import "./Pool.sol";
import "./libs/String.sol";

contract Factory is Context, Ownable, IFactory {
  function setupTickets(uint256[] calldata ids_, uint256[] calldata fees_) external override onlyOwner {
    require(ids_.length == fees_.length, "Factory: Mismatch in ids and fees length");

    for(uint256 i = 0; i < ids_.length; i++) {
      TicketToken token = new TicketToken(String.concat("AavegotchiTicketToken_", ids_[i]), String.concat("ATT_", ids_[i]));
      Pool pool = new Pool(ids_[i], address(this), address(token), fees_[i]);
  
      lpToken.grantRole(lpToken.MANAGER_ROLE(), address(pool));

      tickets[ids_[i]] = Ticket({
        supported: true,
        poolAddress: address(pool),
        tokenAddress: address(token)
      });

      emit TicketSetup(ids_[i], address(pool), address(token));
    }
  }

  function setTreasury(address treasury_) external override onlyOwner {
    treasury = treasury_;
    emit TreasurySet(treasury_);
  }

  function setTicket(address ticket_) external override onlyOwner {
    ticketToken = IERC1155(ticket_);
    emit TicketTokenSet(ticket_);
  }

  function setDai(address dai_) external override onlyOwner {
    daiToken = IERC20(dai_);
    emit DaiTokenSet(dai_);
  }

  function setLp(address lp_) external override onlyOwner {
    lpToken = ILpToken(lp_);
    emit LpTokenSet(lp_);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

library String {
  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
        return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
  }

  function concat(string memory str, uint256 num) internal pure returns (string memory) {
    return string(abi.encodePacked(str, String.toString(num)));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITicketToken is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ITicketToken.sol";
import "./IFactory.sol";

abstract contract IPool {
  IFactory public factory;
  ITicketToken public token;
  uint256 public poolId;
  uint256 public fee;
  uint256 public tokenReserve;
  uint256 public daiReserve;
  bool public initialized;

  event Swapped(address indexed user, uint256 daiAmount, uint256 tokenAmount, uint256 feeAmount);
  event LiquidityAdded(address indexed user, uint256 daiAmount, uint256 tokenAmount, uint256 lpAmount);
  event LiquidityRemoved(address indexed user, uint256 lpAmount);
  event RewardClaimed(address indexed user, uint256 rewardAmount);

  function addLiquidity(uint256 _daiAmount, uint256 _tokenAmount) external virtual;

  function removeLiquidity(uint256 _lpAmount) external virtual;

  function estimateSwapToDaiByToken(uint256 _tokenAmount) external virtual view returns(uint256);

  function swapToDaiByToken(uint256 _tokenAmount) external virtual returns(uint256);

  function estimateSwapToDaiByDai(uint256 _daiAmount) external virtual view returns(uint256);

  function swapToDaiByDai(uint256 _daiAmount) external virtual returns(uint256);

  function estimateSwapFromDaiByToken(uint256 _tokenAmount) external virtual view returns(uint256);

  function swapFromDaiByToken(uint256 _tokenAmount) external virtual returns(uint256);

  function estimateSwapFromDaiByDai(uint256 _daiAmount) external virtual view returns(uint256);

  function swapFromDaiByDai(uint256 _daiAmount) external virtual returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract ILpToken is IERC1155 {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  mapping(uint256 => bool) internal supportedIds;
  mapping(uint256 => uint256) public totalSupply;

  function setConfig(uint256[] calldata _ids, bool[] calldata _supported) virtual external;

  function mint(address _to, uint256 _id, uint256 _amount) virtual external;

  function burn(address _from, uint256 _id, uint256 _amount) virtual external;

  function grantRole(bytes32 role, address account) virtual external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILpToken.sol";

abstract contract IFactory {
  struct Ticket {
    bool supported;
    address tokenAddress;
    address poolAddress;
  } 

  IERC1155 public ticketToken;
  IERC20 public daiToken;
  ILpToken public lpToken;
  address public treasury;

  mapping(uint256 => Ticket) public tickets;

  event TicketSetup(uint256 indexed id, address pool, address token);
  
  event TreasurySet(address newAddress);
  event TicketTokenSet(address newAddress);
  event DaiTokenSet(address newAddress);
  event LpTokenSet(address newAddress);

  function setupTickets(uint256[] calldata ids_, uint256[] calldata fees_) external virtual;

  function setTreasury(address treasury_) external virtual;

  function setTicket(address ticket_) external virtual;

  function setDai(address dai_) external virtual;

  function setLp(address lp_) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITicketToken.sol";

contract TicketToken is ITicketToken, ERC20, Ownable {
  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
  }

  function mint(address _to, uint256 _amount) external override onlyOwner {
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) external override onlyOwner {
    _burn(_from, _amount);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/ILpToken.sol";
import "./interfaces/IPool.sol";

contract Pool is ReentrancyGuard, Context, IPool {
  constructor(uint256 _id, address _factory, address _token, uint256 _fee) {
    token = ITicketToken(_token);
    factory = IFactory(_factory);
    poolId = _id;
    fee = _fee;
  }

  function addLiquidity(uint256 _daiAmount, uint256 _tokenAmount) external override nonReentrant {
    if (!initialized) {
      initialized = true;
    } else {
      require(_daiAmount == _tokenAmount * daiReserve / tokenReserve, "Pool: Invalid relation");
    }

    IERC20(factory.daiToken()).transferFrom(_msgSender(), address(this), _daiAmount);
    token.transferFrom(_msgSender(), address(this), _tokenAmount);

    daiReserve += _daiAmount;
    tokenReserve += _tokenAmount;
    
    uint256 amount = (_daiAmount + _tokenAmount * (daiReserve / tokenReserve)) / 1000;
    ILpToken(factory.lpToken()).mint(_msgSender(), poolId, amount);

    emit LiquidityAdded(_msgSender(), _daiAmount, _tokenAmount, amount);
  }

  function removeLiquidity(uint256 _lpAmount) external override nonReentrant {
    uint256 part = _lpAmount * 1e8 / ILpToken(factory.lpToken()).totalSupply(poolId);
    
    ILpToken(factory.lpToken()).burn(_msgSender(), poolId, _lpAmount);

    uint256 daiAmount = part * daiReserve / 1e8;
    uint256 tokenAmount = part * tokenReserve / 1e8;

    IERC20(factory.daiToken()).transfer(_msgSender(), daiAmount);
    token.transfer(_msgSender(), tokenAmount);

    daiReserve -= daiAmount;
    tokenReserve -= tokenAmount;

    emit LiquidityRemoved(_msgSender(), _lpAmount);
  }

  function estimateSwapToDaiByToken(uint256 _tokenAmount) public view override returns(uint256) {
    uint256 currRelation = daiReserve / tokenReserve;
    uint256 nextRelation = (daiReserve - (_tokenAmount * currRelation)) / (tokenReserve + _tokenAmount);
    return _tokenAmount * ((currRelation + nextRelation) / 2);
  }

  function swapToDaiByToken(uint256 _tokenAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 daiAmount = estimateSwapToDaiByToken(_tokenAmount);

    token.transferFrom(_msgSender(), address(this), _tokenAmount);
    IERC20(factory.daiToken()).transfer(_msgSender(), daiAmount);

    tokenReserve += _tokenAmount;
    daiReserve -= daiAmount;

    uint256 totalFee = _tokenAmount * fee / 1 ether;

    IERC20(factory.daiToken()).transferFrom(_msgSender(), factory.treasury(), uint256(totalFee));
    
    emit Swapped(_msgSender(), daiAmount, _tokenAmount, uint256(totalFee));
    return daiAmount;
  }

  function estimateSwapToDaiByDai(uint256 _daiAmount) public view override returns(uint256) {
    uint256 currRelation = daiReserve / tokenReserve;
    uint256 nextRelation = (daiReserve - _daiAmount) / (tokenReserve + (_daiAmount / currRelation));
    return _daiAmount / ((currRelation + nextRelation) / 2);
  }

  function swapToDaiByDai(uint256 _daiAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 tokenAmount = estimateSwapToDaiByDai(_daiAmount);

    token.transferFrom(_msgSender(), address(this), tokenAmount);
    IERC20(factory.daiToken()).transfer(_msgSender(), _daiAmount);

    tokenReserve += tokenAmount;
    daiReserve -= _daiAmount;

    uint256 totalFee = tokenAmount * fee / 1 ether;

    IERC20(factory.daiToken()).transferFrom(_msgSender(), factory.treasury(), uint256(totalFee));
    
    emit Swapped(_msgSender(), _daiAmount, tokenAmount, uint256(totalFee));
    return tokenAmount;
  }

  function estimateSwapFromDaiByToken(uint256 _tokenAmount) public view override returns(uint256) {
    uint256 currRelation = daiReserve / tokenReserve;
    uint256 nextRelation = (daiReserve + (_tokenAmount * currRelation)) / (tokenReserve - _tokenAmount);
    return _tokenAmount * ((currRelation + nextRelation) / 2);
  }

  function swapFromDaiByToken(uint256 _tokenAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 daiAmount = estimateSwapFromDaiByToken(_tokenAmount);

    IERC20(factory.daiToken()).transferFrom(_msgSender(), address(this), daiAmount);
    token.transfer(_msgSender(), _tokenAmount);

    tokenReserve -= _tokenAmount;
    daiReserve += daiAmount;

    uint256 totalFee = _tokenAmount * fee / 1 ether;

    IERC20(factory.daiToken()).transferFrom(_msgSender(), factory.treasury(), uint256(totalFee));

    emit Swapped(_msgSender(), daiAmount, _tokenAmount, uint256(totalFee));
    return daiAmount;
  }

  function estimateSwapFromDaiByDai(uint256 _daiAmount) public view override returns(uint256) {
    uint256 currRelation = daiReserve / tokenReserve;
    uint256 nextRelation = (daiReserve + _daiAmount) / (tokenReserve - (_daiAmount / currRelation));
    return _daiAmount / ((currRelation + nextRelation) / 2);
  }

  function swapFromDaiByDai(uint256 _daiAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 tokenAmount = estimateSwapFromDaiByDai(_daiAmount);

    IERC20(factory.daiToken()).transferFrom(_msgSender(), address(this), _daiAmount);
    token.transfer(_msgSender(), tokenAmount);

    tokenReserve -= tokenAmount;
    daiReserve += _daiAmount;

    uint256 totalFee = tokenAmount * fee / 1 ether;

    IERC20(factory.daiToken()).transferFrom(_msgSender(), factory.treasury(), uint256(totalFee));

    emit Swapped(_msgSender(), _daiAmount, tokenAmount, uint256(totalFee));
    return tokenAmount;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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