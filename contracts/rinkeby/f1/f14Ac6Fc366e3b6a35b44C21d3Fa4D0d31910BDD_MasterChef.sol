pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "./interfaces/I_sDFIANCE.sol";
import "./libs/BlockReentrancyGuard.sol";

contract MasterChef is BlockReentrancyGuard{
    using SafeMath for uint256;

    // info about each user
    struct FarmerInfo {
        uint256 distributionRatio; // average distribution ratio between sDFIANCE <=> lp when staker deposited
        uint256 lpAmount; // amount of lp amount the staker has
    }

    // info about each pool
    struct PoolInfo {
        uint256 tokenDistributionPerBlock; // token distributed per block (note : tokenDistributionPerBlock is subject to a multiplier => normal amount is distributed if distributionMultiplier = 1000)
        uint256 lpSupply; // staked lp supply
        uint256 sDFIANCESupply; // total sDFIANCE collateral in the pool
        uint256 lastUpdateBlock; // last block when there was an update

        uint256 startBlock; // (note : can be 0 if there isn't startBlock)
        bool stopped; // (note : stopped is true until startBlock is reached)

        mapping (address => FarmerInfo) farmerInfo; // list of all farmers in each pool
    }

    I_sDFIANCE public sDFIANCE; // minted token
    mapping (address => PoolInfo) public poolInfo; // poolInfo for each lp pair (which represent their respective pool)
    address public operatorAddress; // operator address
    uint256 public distributionMultiplier; // distribution multiplier which allows operator to decrease the total minted amount of sDFIANCE (note : based on 1/1000)
    uint256 public maximumDistributionMultiplier; // maximum distributionMultiplier

    constructor(address _sDFIANCE, uint256 _distributionMultiplier) public {
        sDFIANCE = I_sDFIANCE(_sDFIANCE);
        operatorAddress = msg.sender;
        distributionMultiplier = _distributionMultiplier;

        maximumDistributionMultiplier = 2000; // max mint mulitplier is at the start at x2
    }

    modifier poolValid(address _lpPair) {
        require(poolInfo[_lpPair].lastUpdateBlock != 0, "pool doesn't exist"); // verify that the pool is valid for use
        require(poolInfo[_lpPair].stopped == false, "pool not activated");
        require(block.number > poolInfo[_lpPair].startBlock, "pool startBlock not yet reached");
        _;
    }

    modifier poolNotExist(address _lpPair) {
        require(poolInfo[_lpPair].lastUpdateBlock == 0, "pool already exist"); // verify that the pool doesn't exist
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "caller is not the operator");
        _;
    }

    function setOperator(address _operator) external onlyOperator {
        operatorAddress = _operator;
    }

    function setDistributionMultiplier(uint256 newMultiplier) public onlyOperator {
        require(newMultiplier <= maximumDistributionMultiplier);
        distributionMultiplier = newMultiplier;
    }

    // add, remove or modify contract's pools
    function addPool(address _lpPair, uint256 _tokenDistributionPerBlock, uint256 _startBlock) external onlyOperator poolNotExist(_lpPair) {         
        poolInfo[_lpPair].lastUpdateBlock = block.number;
        poolInfo[_lpPair].tokenDistributionPerBlock = _tokenDistributionPerBlock; 
        poolInfo[_lpPair].startBlock = _startBlock;
        poolInfo[_lpPair].stopped = true; // new pools need manual activation by operator

        poolInfo[_lpPair].lpSupply = 1; // initialize to avoid div by 0
    }

    function removePool(address _lpPair) external onlyOperator poolValid(_lpPair) {         
        poolInfo[_lpPair].lastUpdateBlock = 0; // reset the identifier of pool existence
        poolInfo[_lpPair].tokenDistributionPerBlock = 0; 
        poolInfo[_lpPair].startBlock = 0;
        poolInfo[_lpPair].stopped = true; // stop the pool just in case
    }

    function modifyPool(address _lpPair, uint256 _tokenDistributionPerBlock, uint256 _startBlock) external onlyOperator poolValid(_lpPair) {
        updateDistributionRatio(_lpPair);

        poolInfo[_lpPair].startBlock = _startBlock;
        poolInfo[_lpPair].tokenDistributionPerBlock = _tokenDistributionPerBlock;
    }

    // activate or desactivate pools in emergency cases
    function activatePool(address _lpPair) external onlyOperator { poolInfo[_lpPair].stopped = false; }

    function desactivatePool(address _lpPair) external onlyOperator { poolInfo[_lpPair].stopped = true; }

    // update the distribution ratio to have the correct reward allocation
    function updateDistributionRatio(address _lpPair) private {
        PoolInfo storage _pool = poolInfo[_lpPair];
        uint256 _newReward = block.number.sub(_pool.lastUpdateBlock).mul(_pool.tokenDistributionPerBlock.mul(distributionMultiplier));

        _pool.sDFIANCESupply = _pool.sDFIANCESupply.add(_newReward);
        _pool.lastUpdateBlock = block.number;
    }

    // get the real distribution ratio (sDFIANCE for lpSupply)
    function getRealDistributionRatio(address _lpPair) public view poolValid(_lpPair) returns (uint256) {
        uint256 _newReward = block.number.sub(poolInfo[_lpPair].lastUpdateBlock).mul(poolInfo[_lpPair].tokenDistributionPerBlock.mul(distributionMultiplier));
        
        return poolInfo[_lpPair].sDFIANCESupply.add(_newReward).div(poolInfo[_lpPair].lpSupply);
    }
 
    // deposit lp to the masterChef
    function deposit(address _lpPair, uint _lpAmount) external poolValid(_lpPair) nonBlockReentrant {
        address _account = msg.sender;
        require(ERC20(_lpPair).transferFrom(_account, address(this), _lpAmount), "lp transfer from user to contract failed");

        // just before adding the new staker, update the reward (distributionRatio) for the pool
        updateDistributionRatio(_lpPair);

        uint actualDistributionRatio = getRealDistributionRatio(_lpPair);
        FarmerInfo storage _user = poolInfo[_lpPair].farmerInfo[_account];

        poolInfo[_lpPair].lpSupply = poolInfo[_lpPair].lpSupply.add(_lpAmount);
        _user.lpAmount = _user.lpAmount.add(_lpAmount);

        // calculate the amount of A token we need to borrow to keep the distribution ratio when we adding more lp token
        uint256 virtualCollateralAmount = poolInfo[_lpPair].lpSupply.mul(actualDistributionRatio).sub(poolInfo[_lpPair].sDFIANCESupply);
        poolInfo[_lpPair].sDFIANCESupply = poolInfo[_lpPair].sDFIANCESupply.add(virtualCollateralAmount);

        if (_user.lpAmount == 0) {
            
            // set the entry distribution ratio to the actual
            _user.distributionRatio = actualDistributionRatio;
        } 
        else {
            uint lastLpAmount = _user.lpAmount;

            // calculate the average distribution ratio entry
            _user.distributionRatio = actualDistributionRatio.mul(_lpAmount).add(_user.distributionRatio.mul(lastLpAmount)).div(_lpAmount.add(lastLpAmount));
        }
    }

    // withdraw lp and harvest rewards with safety checks
    function withdraw(address _lpPair, uint _lpAmount) external poolValid(_lpPair) nonBlockReentrant {
        address _account = msg.sender;
        FarmerInfo storage _user = poolInfo[_lpPair].farmerInfo[_account];
        require(_user.lpAmount >= _lpAmount, "invalid withdraw lp amount");

        _harvestReward(_lpPair, _account); // private call (to avoid block reentrancy)

        // just before removing the staker, update the reward (distributionRatio) for the pool
        updateDistributionRatio(_lpPair);

        uint actualDistributionRatio = getRealDistributionRatio(_lpPair);

        poolInfo[_lpPair].lpSupply = poolInfo[_lpPair].lpSupply.sub(_lpAmount);
        _user.lpAmount = _user.lpAmount.sub(_lpAmount);

        // calculate the amount of A token we need to remove to keep the distribution ratio
        uint256 virtualCollateralAmount = poolInfo[_lpPair].sDFIANCESupply.sub(_lpAmount.mul(actualDistributionRatio));
        poolInfo[_lpPair].sDFIANCESupply = poolInfo[_lpPair].sDFIANCESupply.sub(virtualCollateralAmount);

        // make transfers
        ERC20(_lpPair).transfer(_account, _lpAmount);
    }

    // withdraw lp without worrying about rewards and pools validation
    function emergencyWithdraw(address _lpPair, uint _lpAmount) external nonBlockReentrant {
        address _account = msg.sender;
        require(poolInfo[_lpPair].farmerInfo[_account].lpAmount >= _lpAmount, "invalid withdraw lp amount");

        // just before removing the staker, update the reward (distributionRatio) for the pool
        updateDistributionRatio(_lpPair);

        uint actualDistributionRatio = getRealDistributionRatio(_lpPair);

        poolInfo[_lpPair].lpSupply = poolInfo[_lpPair].lpSupply.sub(_lpAmount);
        poolInfo[_lpPair].farmerInfo[_account].lpAmount = poolInfo[_lpPair].farmerInfo[_account].lpAmount.sub(_lpAmount);

        // calculate the amount of A token we need to remove to keep the distribution ratio
        uint256 virtualCollateralAmount = poolInfo[_lpPair].sDFIANCESupply.sub(_lpAmount.mul(actualDistributionRatio));
        poolInfo[_lpPair].sDFIANCESupply = poolInfo[_lpPair].sDFIANCESupply.sub(virtualCollateralAmount);

        // send lp
        ERC20(_lpPair).transfer(_account, _lpAmount);
    }

    // get the total reward amount that the user can claim (used in the front-end and for harvest reward)
    function getPendingReward(address _lpPair, address _account) public view poolValid(_lpPair) returns (uint256) {
        uint reward = getRealDistributionRatio(_lpPair).sub(poolInfo[_lpPair].farmerInfo[_account].distributionRatio).mul(poolInfo[_lpPair].farmerInfo[_account].lpAmount);
        return reward;
    }

    // harvest function call a lower-level harvest reward function to allow the reward claiming in this contract (from withdraw function)
    function harvestReward(address _lpPair, address _from) external poolValid(_lpPair) nonBlockReentrant {
        _harvestReward(_lpPair, _from);
    }

    // only used directly by withdraw function
    function _harvestReward(address _lpPair, address _from) private {
        uint256 reward = getPendingReward(_lpPair, _from);

        require(reward > 0, "MoneyPot : reward must be up to 0");
        sDFIANCE.mint(_from, reward);
        poolInfo[_lpPair].farmerInfo[_from].distributionRatio = getRealDistributionRatio(_lpPair);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/* 
* note : This contract prevents from executing more than 1 "nonBlockReentrant" function during the same block, so any form of 
* inter-block manipulation with an external contract is blocked.
*/

abstract contract BlockReentrancyGuard {

    mapping (address => uint256) userLastCall;

    modifier nonBlockReentrant() {
        uint256 _blockCount = block.number;
        address _sender = msg.sender;

        require(userLastCall[_sender] != _blockCount, "Multiple calls in the same block are not allow");

        // Any calls to nonBlockReentrant after this point will fail
        userLastCall[_sender] = _blockCount;

        _;
    }
}

pragma solidity =0.6.12;

interface I_sDFIANCE {
    function mint(address _to, uint256 _amount) external;
    function getAvgSwapTimeInHours(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}