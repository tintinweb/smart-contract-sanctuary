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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "./Cohort.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Actuary is Ownable {
    address[] public cohortCreators;
    uint256 public cohortCreateFee;

    event CohortCreated(address indexed cohort, address indexed owner);
    event WithdrewCreateFee(address indexed _to, uint256 _amount);

    constructor() {
        cohortCreators.push(msg.sender);
    }

    modifier onlyCohortCreator() {
        require(isCohortCreator(msg.sender) == true, "UnoRe: Forbidden");
        _;
    }

    function cohortCreatorsLength() public view returns (uint256) {
        return cohortCreators.length;
    }

    function addCohortCreator(address _creator) external onlyOwner {
        require(isCohortCreator(_creator) == false, "UnoRe: Already registered");
        cohortCreators.push(_creator);
    }

    /** return created cohort address */
    // We collect Cohort create key using ETH
    // We have one another option, We can deploy Cohort indepently
    // But then user should deploy from DAPP whenever he creates Cohort. Lol
    function createCohort(
        string calldata _name,
        address _claimAssessor,
        uint256 _cohortStartCapital
    ) external payable onlyCohortCreator returns (address cohort) {
        require(msg.value >= cohortCreateFee, "UnoRe: Insufficient creation fee");
        bytes memory bytecode = type(Cohort).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _name, block.number));

        assembly {
            cohort := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ICohort(cohort).initialize(msg.sender, _name, _claimAssessor, _cohortStartCapital);
        // Clean dust from msg.value
        {
            uint256 dust = msg.value - cohortCreateFee;
            if (dust > 0) {
                TransferHelper.safeTransferETH(msg.sender, dust);
            }
        }
        emit CohortCreated(cohort, msg.sender);
    }

    function isCohortCreator(address _creator) public view returns (bool) {
        uint256 len = cohortCreators.length;
        for (uint256 ii = 0; ii < len; ii++) {
            if (cohortCreators[ii] == _creator) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev when setting fee, please consider ETH decimal(8)
     */
    function setCohortCreationFee(uint256 _fee) external onlyOwner {
        cohortCreateFee = _fee;
    }

    function withdrawCreateFee(address _to) external onlyOwner {
        uint256 feeCollected = address(this).balance;
        TransferHelper.safeTransferETH(_to, address(this).balance);
        emit WithdrewCreateFee(_to, feeCollected);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "./RiskPool.sol";
import "./interfaces/ICohort.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Cohort is ICohort {
    // It should be okay if Protocol is struct
    struct Protocol {
        string name; // protocol name
        address protocolAddress; // Address of that protocol
        address currency;
        uint256 TVL; // Total Value Locked, initial value 0
        string productType; // Type of product i.e. Wallet insurance, smart contract bug insurance, etc. initial value ''
        uint256 coverDuration; // Duration of the protocol cover products
        uint16 avgLR; // LR means Loss Ratio, default 1000 = 1
        uint256 premium; // premium, initial 0
        uint256 investment; // total investment that protocol will take
        bool exist; // initial true
    }

    address public actuary;
    address public claimAssessor;
    address public owner;
    string public name;
    uint256 public TVLc;
    uint256 public combinedRisk;
    uint256 public duration;
    uint8 public status;
    uint256 public cohortActiveFrom;
    uint256 public cohortCapital;

    // for now we set this as constant
    uint256 public COHORT_START_CAPITAL;

    mapping(uint16 => Protocol) public getProtocol;
    uint16[] allProtocols;

    mapping(address => uint16) riskPools;
    address[] public getRiskPool;

    // pool => protocol => rewards from premium
    mapping(address => mapping(uint16 => uint256)) premiumRewards;
    mapping(address => uint256) poolCapital;

    event RiskPoolCreated(address indexed cohort, address indexed pool);
    event StakedInPool(address indexed staker, address indexed pool, uint256 amount);
    event Withdrew(address indexed staker, address indexed pool);
    event ClaimPaid(address indexed claimer, address indexed payer, uint256 amount);
    event PremiumDeposited(address indexed from, uint16 indexed protocolIdx, uint256 amount);

    constructor() {
        actuary = msg.sender;
    }

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyCohortOwner() {
        require(msg.sender == owner, "UnoRe: Forbidden");
        _;
    }

    function allProtocolsLength() external view returns (uint256) {
        return allProtocols.length;
    }

    function getRiskPoolLength() public view returns (uint256) {
        return getRiskPool.length;
    }

    function initialize(
        address _owner,
        string calldata _name,
        address _claimAssessor,
        uint256 _cohortStartCapital
    ) external override {
        require(msg.sender == actuary, "UnoRe: Forbidden");
        owner = _owner;
        name = _name;
        COHORT_START_CAPITAL = _cohortStartCapital;
        claimAssessor = _claimAssessor;
    }

    // This action can be done only by cohort owner
    function addProtocol(
        string calldata _name,
        address _protocolAddress,
        address _currency,
        uint256 _coverDuration,
        uint256 _investment
    ) external override onlyCohortOwner {
        uint16 lastIdx = allProtocols.length > 0 ? allProtocols[allProtocols.length - 1] + 1 : 0;
        allProtocols.push(lastIdx);
        getProtocol[lastIdx] = Protocol({
            name: _name,
            protocolAddress: _protocolAddress,
            currency: _currency,
            TVL: 0,
            productType: "",
            coverDuration: _coverDuration,
            avgLR: 1000,
            premium: 0,
            investment: _investment,
            exist: true
        });

        if (duration < _coverDuration) {
            duration = _coverDuration;
        }
    }

    /**
     * @dev create Risk pool from cohort owner
     */
    function createRiskPool(address _currency, uint256 _period) external onlyCohortOwner returns (address pool) {
        bytes memory bytecode = type(RiskPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender));

        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // hardcoded params at the moment
        IRiskPool(pool).initialize(_currency, _period);

        uint16 lastIdx = uint16(getRiskPool.length);
        riskPools[pool] = lastIdx;
        getRiskPool.push(pool);

        emit RiskPoolCreated(address(this), pool);
    }

    function depositPremium(uint256 _amount, uint16 _protocolIdx) external {
        Protocol memory protocol = getProtocol[_protocolIdx];
        TransferHelper.safeTransferFrom(protocol.currency, msg.sender, address(this), _amount);
        protocol.premium += _amount;
        protocol.investment += _amount;
        emit PremiumDeposited(msg.sender, _protocolIdx, _amount);
    }

    /*
     * when staking comes, we should check if we can start to cover products
     * @dev this function can be called only through Actuary
     * TODO Research we have no compensation calculation here
     */
    function enterInPool(
        address _from,
        address _pool,
        uint256 _amount
    ) external {
        require(cohortActiveFrom == 0, "UnoRe: Staking is Ended");
        require(riskPools[_pool] > 0, "UnoRe: RiskPool not exist");
        address token = IRiskPool(_pool).currency();
        TransferHelper.safeTransferFrom(token, _from, _pool, _amount);
        // we should mint _xRiskPool to _from
        IRiskPool(_pool).enter(_from, _amount);
        cohortCapital += _amount;
        _startCohort();

        StakedInPool(_from, _pool, _amount);
    }

    /**
     * @dev this function can be called only through Actuary
     * @dev for now we assume protocols send premium to cohort smart contract
     */
    function leaveFromPool(address _to, address _pool) external {
        require(block.timestamp - cohortActiveFrom > duration, "UnoRe: Forbidden");
        // Withdraw remaining from pool
        uint256 amount = IERC20(_pool).balanceOf(_to);
        // get premium rewards
        for (uint256 ii = 0; ii < allProtocols.length; ii++) {
            uint16 protocolIdx = allProtocols[ii];
            if (premiumRewards[_pool][protocolIdx] == 0) {
                poolCapital[_pool] = IERC20(_pool).totalSupply();
                premiumRewards[_pool][protocolIdx] =
                    (getProtocol[protocolIdx].premium * (poolCapital[_pool] / cohortCapital) * IRiskPool(_pool).APR()) /
                    100;
            }
            // TODO Transfer assets to _to
            uint256 _pr = premiumRewards[_pool][protocolIdx] * (amount / poolCapital[_pool]);
            TransferHelper.safeTransfer(getProtocol[protocolIdx].currency, _to, _pr);
        }

        IRiskPool(_pool).leave(_to);
        Withdrew(_to, _pool);
    }

    function _startCohort() private {
        if (cohortCapital > COHORT_START_CAPITAL) {
            cohortActiveFrom = block.timestamp;
        }
    }

    /**
     * @dev for now all premiums and risk pools are paid in stable coin
     */
    function requestClaim(
        address _from,
        uint256 _amount,
        uint16 _protocolIdx
    ) external override lock returns (bool) {
        /**
         * @dev we can trust claim request from ClaimAssesor
         */
        require(msg.sender == claimAssessor, "UnoRe: Forbidden");
        require(hasEnoughCapital(_amount, _protocolIdx) == true, "UnoRe: Capital is not enough");
        Protocol memory _protocol = getProtocol[_protocolIdx];
        if (_amount <= _protocol.premium) {
            // Transfer from Premium
            _protocol.premium -= _amount;
            TransferHelper.safeTransfer(_protocol.currency, _from, _amount);
            ClaimPaid(_from, _protocol.protocolAddress, _amount);
            return true;
        }
        if (_protocol.premium > 0) {
            // Tranfer from premium
            _amount -= _protocol.premium;
            _protocol.premium = 0;
            TransferHelper.safeTransfer(_protocol.currency, _from, _protocol.premium);

            ClaimPaid(_from, _protocol.protocolAddress, _amount);
        }
        for (uint256 ii = 0; ii < getRiskPool.length; ii++) {
            if (_amount == 0) break;
            address _pool = getRiskPool[ii];
            address _token = IRiskPool(_pool).currency();
            uint256 _poolCapital = IERC20(_token).balanceOf(_pool);
            if (_amount <= _poolCapital) {
                _requestClaimToPool(_from, _amount, _pool);
                _amount = 0;
            } else {
                _requestClaimToPool(_from, _poolCapital, _pool);
                _amount -= _poolCapital;
            }
        }
        return true;
    }

    function hasEnoughCapital(uint256 _amount, uint16 _protocolIdx) private view returns (bool) {
        uint256 totalCapital = getProtocol[_protocolIdx].premium;
        for (uint256 ii = 0; ii < getRiskPool.length; ii++) {
            address pool = getRiskPool[ii];
            address token = IRiskPool(pool).currency();
            totalCapital += IERC20(token).balanceOf(pool);
        }
        return totalCapital >= _amount ? true : false;
    }

    function _requestClaimToPool(
        address _from,
        uint256 _amount,
        address _pool
    ) private {
        IRiskPool(_pool).requestClaim(_from, _amount);
        ClaimPaid(_from, _pool, _amount);
    }

    function setClaimAssessor(address _assessor) external onlyCohortOwner {
        claimAssessor = _assessor;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "./interfaces/IRiskPool.sol";
// This is for Remix development
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.1/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/TransferHelper.sol";

contract RiskPool is ERC20("Uno Pool", "xUnoRP"), IRiskPool {
    // ERC20 attributes

    address public cohort;
    address public override currency; // for now we should accept only USDT
    uint256 public stakingPeriod; // time in seconds
    uint256 public minInvestment;
    uint256 public maxInvestment;
    uint256 public startedTime;
    uint256 public override APR;

    uint256 public totalPaidClaims;

    constructor() {
        cohort = msg.sender;
    }

    modifier onlyCohort() {
        require(msg.sender == cohort, "UnoRe: RiskPool Forbidden");
        _;
    }

    function initialize(address _currency, uint256 _period) external override onlyCohort {
        currency = _currency;
        stakingPeriod = _period;
        maxInvestment = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    /**
     * @dev Users can stake only through Cohort
     */
    function enter(address _from, uint256 _amount) external override onlyCohort {
        // check lock status of pool
        require(_amount > minInvestment, "UnoRe: Insufficient staking value");
        uint256 desired = balanceOf(_from) + _amount;
        require(desired < maxInvestment, "UnoRe: Overflow max staking value");
        if (startedTime == 0) {
            startedTime = block.timestamp;
        }

        _mint(_from, _amount);
    }

    function leave(address _to) external override onlyCohort {
        uint256 poolAmount = IERC20(currency).balanceOf(address(this));
        uint256 amount = (poolAmount * balanceOf(_to)) / totalSupply();
        _burn(_to, amount);
        TransferHelper.safeTransfer(currency, _to, amount);
    }

    /**
     * @dev We can trust claim request if its sender is cohort
     */
    function requestClaim(address _from, uint256 _amount) external override onlyCohort {
        totalPaidClaims += _amount;
        TransferHelper.safeTransfer(currency, _from, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ICohort {
    function initialize(
        address _owner,
        string calldata _name,
        address _claimAssessor,
        uint256 _cohortStartCapital
    ) external;

    function addProtocol(
        string calldata _name,
        address _protocolAddress,
        address _currency,
        uint256 _coverDuration,
        uint256 _investment
    ) external;

    function requestClaim(
        address _from,
        uint256 _amount,
        uint16 _protocolIdx
    ) external returns (bool);
    // function stakeInPool(
    //     address _staker,
    //     uint32 _poolIdx,
    //     uint256 _amount
    // ) external;

    // function withdrawFromPool(
    //     address _staker,
    //     uint32 _poolIdx,
    //     address token
    // ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRiskPool {
    function initialize(address _currency, uint256 _period) external;

    function enter(address _from, uint256 _amount) external;

    function leave(address _to) external;

    function requestClaim(address _from, uint256 _amount) external;

    function currency() external view returns (address);

    function APR() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 500
  },
  "remappings": [],
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