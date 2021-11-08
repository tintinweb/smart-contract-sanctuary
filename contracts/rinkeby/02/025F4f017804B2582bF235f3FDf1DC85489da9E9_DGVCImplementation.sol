pragma solidity 0.8.4;

import "./Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDGVC.sol";


contract DGVCImplementation is IDGVC, Context, Ownable {
    using SafeERC20 for IERC20;

    mapping (address => uint) private _reflectionOwned;
    mapping (address => uint) private _actualOwned;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping (address => CustomFees) public customFees;
    mapping (address => DexFOT) public dexFOT;

    struct DexFOT {
        bool enabled;
        uint16 buy;
        uint16 sell;
        uint16 burn;
    }

    struct CustomFees {
       bool enabled;
       uint16 fot;
       uint16 burn;
    }


    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    address public feeReceiver;
    address public router;

    string  private constant _NAME = "Degen.vc";
    string  private constant _SYMBOL = "DGVC";
    uint8   private constant _DECIMALS = 18;

    uint private constant _MAX = type(uint).max;
    uint private constant _DECIMALFACTOR = 10 ** uint(_DECIMALS);
    uint private constant _DIVIDER = 10000;

    uint private _actualTotal;
    uint private _reflectionTotal;

    uint private _actualFeeTotal;
    uint private _actualBurnTotal;

    uint public actualBurnCycle;

    uint public commonBurnFee;
    uint public commonFotFee;

    uint public rebaseDelta;
    uint public burnCycleLimit;

    uint private constant _MAX_TX_SIZE = 12000000 * _DECIMALFACTOR;

    bool public initiated;

    event BurnCycleLimitSet(uint cycleLimit);
    event RebaseDeltaSet(uint delta);
    event Rebase(uint rebased);
    event TokensRecovered(address token, address to, uint value);


    function init(address _router) external returns (bool) {
        require(!initiated, 'Already initiated');
        _actualTotal = 12000000 * _DECIMALFACTOR;
        _reflectionTotal = (_MAX - (_MAX % _actualTotal));
        _setOwnership();
        _reflectionOwned[_msgSender()] = _reflectionTotal;
        router = _router;
        emit Transfer(address(0), _msgSender(), _actualTotal);

        initiated = true;
        return true;
    }

    function name() public pure returns (string memory) {
        return _NAME;
    }

    function symbol() public pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint) {
        return _actualTotal;
    }

    function balanceOf(address account) public view override returns (uint) {
        if (_isExcluded[account]) return _actualOwned[account];
        return tokenFromReflection(_reflectionOwned[account]);
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint) {
        return _actualFeeTotal;
    }

    function totalBurn() public view returns (uint) {
        return _actualBurnTotal;
    }

    function setFeeReceiver(address receiver) external onlyOwner returns (bool) {
        require(receiver != address(0), "Zero address not allowed");
        feeReceiver = receiver;
        return true;
    }

    function reflectionFromToken(uint transferAmount, bool deductTransferFee) public view returns(uint) {
        require(transferAmount <= _actualTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint reflectionAmount,,,,,) = _getValues(transferAmount, address(0), address(0));
            return reflectionAmount;
        } else {
            (,uint reflectionTransferAmount,,,,) = _getValues(transferAmount, address(0), address(0));
            return reflectionTransferAmount;
        }
    }

    function tokenFromReflection(uint reflectionAmount) public view returns(uint) {
        require(reflectionAmount <= _reflectionTotal, "Amount must be less than total reflections");
        return reflectionAmount / _getRate();
    }

    function excludeAccount(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(account != router, 'Not allowed to exclude router');
        require(account != feeReceiver, "Can not exclude fee receiver");
        if (_reflectionOwned[account] > 0) {
            _actualOwned[account] = tokenFromReflection(_reflectionOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        for (uint i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _actualOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (sender != owner() && recipient != owner())
            require(amount <= _MAX_TX_SIZE, "Transfer amount exceeds the maxTxAmount.");

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint transferAmount) private {
        uint currentRate =  _getRate();
        (uint reflectionAmount, uint reflectionTransferAmount, uint reflectionFee, uint actualTransferAmount, uint transferFee, uint transferBurn) = _getValues(transferAmount, sender, recipient);
        uint reflectionBurn =  transferBurn * currentRate;
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _reflectionOwned[recipient] = _reflectionOwned[recipient] + reflectionTransferAmount;

        _reflectionOwned[feeReceiver] = _reflectionOwned[feeReceiver] + reflectionFee;

        _burnAndRebase(reflectionBurn, transferFee, transferBurn);
        emit Transfer(sender, recipient, actualTransferAmount);

        if (transferFee > 0) {
            emit Transfer(sender, feeReceiver, transferFee);
        }
    }

    function _transferToExcluded(address sender, address recipient, uint transferAmount) private {
        uint currentRate =  _getRate();
        (uint reflectionAmount, uint reflectionTransferAmount, uint reflectionFee, uint actualTransferAmount, uint transferFee, uint transferBurn) = _getValues(transferAmount, sender, recipient);
        uint reflectionBurn =  transferBurn * currentRate;
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _actualOwned[recipient] = _actualOwned[recipient] + actualTransferAmount;
        _reflectionOwned[recipient] = _reflectionOwned[recipient] + reflectionTransferAmount;

        _reflectionOwned[feeReceiver] = _reflectionOwned[feeReceiver] + reflectionFee;

        _burnAndRebase(reflectionBurn, transferFee, transferBurn);
        emit Transfer(sender, recipient, actualTransferAmount);

        if (transferFee > 0) {
            emit Transfer(sender, feeReceiver, transferFee);
        }
    }

    function _transferFromExcluded(address sender, address recipient, uint transferAmount) private {
        uint currentRate =  _getRate();
        (uint reflectionAmount, uint reflectionTransferAmount, uint reflectionFee, uint actualTransferAmount, uint transferFee, uint transferBurn) = _getValues(transferAmount, sender, recipient);
        uint reflectionBurn =  transferBurn * currentRate;
        _actualOwned[sender] = _actualOwned[sender] - transferAmount;
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _reflectionOwned[recipient] = _reflectionOwned[recipient] + reflectionTransferAmount;

        _reflectionOwned[feeReceiver] = _reflectionOwned[feeReceiver] + reflectionFee;

        _burnAndRebase(reflectionBurn, transferFee, transferBurn);
        emit Transfer(sender, recipient, actualTransferAmount);

        if (transferFee > 0) {
            emit Transfer(sender, feeReceiver, transferFee);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint transferAmount) private {
        uint currentRate =  _getRate();
        (uint reflectionAmount, uint reflectionTransferAmount, uint reflectionFee, uint actualTransferAmount, uint transferFee, uint transferBurn) = _getValues(transferAmount, sender, recipient);
        uint reflectionBurn =  transferBurn * currentRate;
        _actualOwned[sender] = _actualOwned[sender] - transferAmount;
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _actualOwned[recipient] = _actualOwned[recipient] + actualTransferAmount;
        _reflectionOwned[recipient] = _reflectionOwned[recipient] + reflectionTransferAmount;

        _reflectionOwned[feeReceiver] = _reflectionOwned[feeReceiver] + reflectionFee;

        _burnAndRebase(reflectionBurn, transferFee, transferBurn);
        emit Transfer(sender, recipient, actualTransferAmount);

        if (transferFee > 0) {
            emit Transfer(sender, feeReceiver, transferFee);
        }
    }

    function _burnAndRebase(uint reflectionBurn, uint transferFee, uint transferBurn) private {
        _reflectionTotal = _reflectionTotal - reflectionBurn;
        _actualFeeTotal = _actualFeeTotal + transferFee;
        _actualBurnTotal = _actualBurnTotal + transferBurn;
        actualBurnCycle = actualBurnCycle + transferBurn;
        _actualTotal = _actualTotal - transferBurn;


        if (actualBurnCycle >= burnCycleLimit) {
            actualBurnCycle = actualBurnCycle - burnCycleLimit;
            _rebase();
        }
    }

    function burn(uint amount) external override returns (bool) {
        address sender  = _msgSender();
        uint balance = balanceOf(sender);
        require(balance >= amount, "Cannot burn more than on balance");
        require(sender == feeReceiver, "Only feeReceiver");

        uint reflectionBurn =  amount * _getRate();
        _reflectionTotal = _reflectionTotal - reflectionBurn;
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionBurn;

        _actualBurnTotal = _actualBurnTotal + amount;
        _actualTotal = _actualTotal - amount;

        emit Transfer(sender, address(0), amount);
        return true;
    }

    function _commonFotFee(address sender, address recipient) private view returns (uint fotFee, uint burnFee) {
        DexFOT memory dexFotSender = dexFOT[sender];
        DexFOT memory dexFotRecepient = dexFOT[recipient];
        CustomFees memory _customFees = customFees[sender];

        if (dexFotSender.enabled) {
            return (dexFotSender.buy, dexFotSender.burn);
        } else if (dexFotRecepient.enabled) {
            return (dexFotRecepient.sell, dexFotRecepient.burn);
        }
        else if (_customFees.enabled) {
            return (_customFees.fot, _customFees.burn);
        } else {
            return (commonFotFee, commonBurnFee);
        }
    }

    function _getValues(uint transferAmount, address sender, address recipient) private view returns (uint, uint, uint, uint, uint, uint) {
        (uint actualTransferAmount, uint transferFee, uint transferBurn) = _getActualValues(transferAmount, sender, recipient);
        (uint reflectionAmount, uint reflectionTransferAmount, uint reflectionFee) = _getReflectionValues(transferAmount, transferFee, transferBurn);
        return (reflectionAmount, reflectionTransferAmount, reflectionFee, actualTransferAmount, transferFee, transferBurn);
    }

    function _getActualValues(uint transferAmount, address sender, address recipient) private view returns (uint, uint, uint) {
        (uint fotFee, uint burnFee) = _commonFotFee(sender, recipient);
        uint transferFee = transferAmount * fotFee / _DIVIDER;
        uint transferBurn = transferAmount * burnFee / _DIVIDER;
        uint actualTransferAmount = transferAmount - transferFee - transferBurn;
        return (actualTransferAmount, transferFee, transferBurn);
    }

    function _getReflectionValues(uint transferAmount, uint transferFee, uint transferBurn) private view returns (uint, uint, uint) {
        uint currentRate =  _getRate();
        uint reflectionAmount = transferAmount * currentRate;
        uint reflectionFee = transferFee * currentRate;
        uint reflectionBurn = transferBurn * currentRate;
        uint reflectionTransferAmount = reflectionAmount - reflectionFee - reflectionBurn;
        return (reflectionAmount, reflectionTransferAmount, reflectionFee);
    }

    function _getRate() private view returns(uint) {
        (uint reflectionSupply, uint actualSupply) = _getCurrentSupply();
        return reflectionSupply / actualSupply;
    }

    function _getCurrentSupply() private view returns(uint, uint) {
        uint reflectionSupply = _reflectionTotal;
        uint actualSupply = _actualTotal;
        for (uint i = 0; i < _excluded.length; i++) {
            if (_reflectionOwned[_excluded[i]] > reflectionSupply || _actualOwned[_excluded[i]] > actualSupply) return (_reflectionTotal, _actualTotal);
            reflectionSupply = reflectionSupply - _reflectionOwned[_excluded[i]];
            actualSupply = actualSupply - _actualOwned[_excluded[i]];
        }
        if (reflectionSupply < _reflectionTotal / _actualTotal) return (_reflectionTotal, _actualTotal);
        return (reflectionSupply, actualSupply);
    }

    function setUserCustomFee(address account, uint16 fee, uint16 burnFee) external onlyOwner {
        require(fee + burnFee <= _DIVIDER, "Total fee should be in 0 - 100%");
        require(account != address(0), "Zero address not allowed");
        customFees[account] = CustomFees(true, fee, burnFee);
    }

    function setDexFee(address pair, uint16 buyFee, uint16 sellFee, uint16 burnFee) external onlyOwner {
        require(pair != address(0), "Zero address not allowed");
        require(buyFee + burnFee <= _DIVIDER, "Total fee should be in 0 - 100%");
        require(sellFee + burnFee <= _DIVIDER, "Total fee should be in 0 - 100%");
        dexFOT[pair] = DexFOT(true, buyFee, sellFee, burnFee);
    }

    function setCommonFee(uint fee) external onlyOwner {
        require(fee + commonBurnFee <= _DIVIDER, "Total fee should be in 0 - 100%");
        commonFotFee = fee;
    }

    function setBurnFee(uint fee) external onlyOwner {
        require(commonFotFee + fee <= _DIVIDER, "Total fee should be in 0 - 100%");
        commonBurnFee = fee;
    }

    function setBurnCycle(uint cycleLimit) external onlyOwner {
        burnCycleLimit = cycleLimit;
        emit BurnCycleLimitSet(burnCycleLimit);
    }

    function setRebaseDelta(uint delta) external onlyOwner {
        rebaseDelta = delta;
        emit RebaseDeltaSet(rebaseDelta);
    }

    function _rebase() internal {
        _actualTotal = _actualTotal + rebaseDelta;
        emit Rebase(rebaseDelta);
    }

    function recoverTokens(IERC20 token, address destination) external onlyOwner {
        require(destination != address(0), "Zero address not allowed");
        uint balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(destination, balance);
            emit TokensRecovered(address(token), destination, balance);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
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

    function _setOwnership() internal virtual {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDGVC is IERC20 {
    function burn(uint amount) external returns (bool);
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}