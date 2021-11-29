// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import './TokenTimelock.sol';

contract Dinoland is ERC20, Ownable {
    uint256 private _maxTotalSupply;
    address public constant SEED_ADDRESS  = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant PRIVATE_SALE_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant IDO_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant GAME_INCENTIVES_AND_FARMING_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant RESERVE_AND_LIQUIDITY_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant MARKETING_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant TEAM_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant ADVISOR_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    
    constructor() ERC20("Dinoland Metaverse", "DNL") {
        _maxTotalSupply = 1e9 ether;
        TimelockFactory timelockFactory = new TimelockFactory();

        mint(SEED_ADDRESS, 2100000 ether);
        address seedERC20Lock = timelockFactory.createTimelock(this, SEED_ADDRESS, block.timestamp + 60 days, 2325000 ether, 30 days);
        mint(seedERC20Lock, 27900000 ether);
        
        mint(PRIVATE_SALE_ADDRESS, 9000000 ether);
        address privateERC20Lock = timelockFactory.createTimelock(this, PRIVATE_SALE_ADDRESS, block.timestamp + 60 days, 9100000 ether, 30 days);
        mint(privateERC20Lock, 91000000 ether);
        
        mint(IDO_ADDRESS, 6000000 ether);
        address idoERC20Lock = timelockFactory.createTimelock(this, IDO_ADDRESS, block.timestamp + 60 days, 6000000 ether, 30 days);
        mint(idoERC20Lock, 24000000 ether);
        
        address gameIncentiveAndFarmingERC20Lock = timelockFactory.createTimelock(this, GAME_INCENTIVES_AND_FARMING_ADDRESS, block.timestamp + 14 days, 8888889 ether, 30 days);
        mint(gameIncentiveAndFarmingERC20Lock, 320000000 ether);

        address reserveAndLiquidityERC20Lock = timelockFactory.createTimelock(this, RESERVE_AND_LIQUIDITY_ADDRESS, block.timestamp + 14 days, 0, 0);
        mint(reserveAndLiquidityERC20Lock, 270000000 ether);

        address marketingERC20Lock = timelockFactory.createTimelock(this, MARKETING_ADDRESS, block.timestamp, 0, 0);
        mint(marketingERC20Lock, 80000000 ether);

        address teamERC20Lock = timelockFactory.createTimelock(this, TEAM_ADDRESS, block.timestamp + 180 days, 4000000 ether, 30 days);
        mint(teamERC20Lock, 120000000 ether);
        
        mint(ADVISOR_ADDRESS, 1000000 ether);
        address advisorERC20Lock = timelockFactory.createTimelock(this, ADVISOR_ADDRESS, block.timestamp + 180 days, 2041667 ether, 30 days);
        mint(advisorERC20Lock, 49000000 ether);
        
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        require(totalSupply() + amount <= _maxTotalSupply, "Mint more than the max total supply");
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenTimelock {
    IERC20 private _token;
    address private _beneficiary;
    uint256 private _nextReleaseTime;
    uint256 private _releaseAmount;
    uint256 private _releasePeriod;

    TimelockFactory private _factory;

    event Released(address indexed beneficiary, uint256 amount);
    event BeneficiaryTransferred(address indexed previousBeneficiary, address indexed newBeneficiary);

	constructor(){
		_token = IERC20(address(1));
	}

	function init(IERC20 token_, address beneficiary_, uint256 releaseStart_, uint256 releaseAmount_, uint256 releasePeriod_) external {
		require(_token == IERC20(address(0)), "TokenTimelock: already initialized");
		require(token_ != IERC20(address(0)), "TokenTimelock: erc20 token address is zero");
        require(beneficiary_ != address(0), "TokenTimelock: beneficiary address is zero");
        require(releasePeriod_ == 0 || releaseAmount_ != 0, "TokenTimelock: release amount is zero");

        emit BeneficiaryTransferred(address(0), beneficiary_);

        _token = token_;
        _beneficiary = beneficiary_;
        _nextReleaseTime = releaseStart_;
        _releaseAmount = releaseAmount_;
        _releasePeriod = releasePeriod_;

        _factory = TimelockFactory(msg.sender);
	}

    function token() public view virtual returns (IERC20) {
        return _token;
    }

    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    function nextReleaseTime() public view virtual returns (uint256) {
        return _nextReleaseTime;
    }

    function releaseAmount() public view virtual returns (uint256) {
        return _releaseAmount;
    }

    function balance() public view virtual returns (uint256) {
        return token().balanceOf(address(this));
    }

    function releasableAmount() public view virtual returns (uint256) {
        if (block.timestamp < _nextReleaseTime) return 0;

        uint256 amount = balance();
        if (amount == 0) return 0;
        if (_releasePeriod == 0) return amount;

        uint256 passedPeriods = (block.timestamp - _nextReleaseTime) / _releasePeriod;
        uint256 maxReleasableAmount = (passedPeriods + 1) * _releaseAmount;
        
        if (amount <= maxReleasableAmount) return amount;
        return maxReleasableAmount;
    }

    function releasePeriod() public view virtual returns (uint256) {
        return _releasePeriod;
    }

    function release() public virtual returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= nextReleaseTime(), "TokenTimelock: current time is before release time");

        uint256 _releasableAmount = releasableAmount();
        require(_releasableAmount > 0, "TokenTimelock: no releasable tokens");

        emit Released(beneficiary(), _releasableAmount);
        require(token().transfer(beneficiary(), _releasableAmount));

        if (_releasePeriod != 0) {
            uint256 passedPeriods = (block.timestamp - _nextReleaseTime) / _releasePeriod;
            _nextReleaseTime += (passedPeriods + 1) * _releasePeriod;
        }

        return true;
    }
    

    function transferBeneficiary(address newBeneficiary) public virtual returns (bool) {
		require(msg.sender == beneficiary(), "TokenTimelock: caller is not the beneficiary");
		require(newBeneficiary != address(0), "TokenTimelock: the new beneficiary is zero address");
		
        emit BeneficiaryTransferred(beneficiary(), newBeneficiary);
		_beneficiary = newBeneficiary;
		return true;
	}

    function split(address splitBeneficiary, uint256 splitAmount) public virtual returns (bool) {
        uint256 _amount = balance();
		require(msg.sender == beneficiary(), "TokenTimelock: caller is not the beneficiary");
		require(splitBeneficiary != address(0), "TokenTimelock: beneficiary address is zero");
        require(splitAmount > 0, "TokenTimelock: amount is zero");
        require(splitAmount <= _amount, "TokenTimelock: amount exceeds balance");

        uint256 splitReleaseAmount;
        if (_releasePeriod > 0) {
            splitReleaseAmount = _releaseAmount * splitAmount / _amount;
        }

        address newTimelock = _factory.createTimelock(token(), splitBeneficiary, _nextReleaseTime, splitReleaseAmount, _releasePeriod);

        require(token().transfer(newTimelock, splitAmount));
        _releaseAmount -= splitReleaseAmount;
		return true;
	}
}

contract CloneFactory {
  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }
}

contract TimelockFactory is CloneFactory {
	address private _tokenTimelockImpl;
	event Timelock(address timelockContract);
	constructor() {
		_tokenTimelockImpl = address(new TokenTimelock());
	}
	function createTimelock(IERC20 token, address to, uint256 releaseTime, uint256 releaseAmount, uint256 period) public returns (address) {
		address clone = createClone(_tokenTimelockImpl);
		TokenTimelock(clone).init(token, to, releaseTime, releaseAmount, period);

		emit Timelock(clone);
		return clone;
	}
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