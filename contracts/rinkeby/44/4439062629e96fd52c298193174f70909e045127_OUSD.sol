/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract ERC20 is IERC20 {
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

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
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

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

interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

interface IgOHM {
    function safeTransfer(address to, uint amount) external;
    function safeTransferFrom(address from, address to, uint amount) external;
    function balanceFrom(uint amount) external view returns (uint);
    function balanceTo(uint amount) external view returns (uint);
}

interface IOracle {
    function assetPrice() external view returns (uint);
}

/**
 * OUSD is a CDP stablecoin backed by staked OHM deposits. It accepts both s and g OHM
 * as collateral. It charges a fixed interest rate after an origination fee. Debt
 * is capped beneath a global ceiling. Loan origination is constrained by a maximum
 * loan-to-value. Liquidations occur at a liquidation threshold, with the liquidator
 * incentivized by an incentive. Liquidations occur in max tranches, as decided by the
 * close factor. Fees collected are sent to the Olympus treasury.
 */
contract OUSD is ERC20, Ownable {
    
    /* ========== DEPENDENCIES ========== */
    
    using SafeERC20 for IERC20;
    using SafeERC20 for IgOHM;
    
    /* ========== EVENTS ========== */

    event UpdateExchangeRate(uint256 newExchangeRate);
    event AddCollateral(address depositor, uint256 amount);
    event RemoveCollateral(address depositor, uint256 amount);
    event Borrow(address depositor, uint256 amount);
    event Repay(address depositor, uint256 amount);
    event Liquidate(address depositor, uint256 repaid, uint256 liquidated, uint256 exchangeRate);
    event ChangeParam(PARAM param, uint256 setTo);
    
    /* ========== STATE VARIABLES ========== */

    uint256 internal FEE_DECIMALS = 1e5;
    uint256 internal INTEREST_DECIMALS = 1e12;
    uint256 internal LIQUIDATION_DECIMALS = 1e5;
    uint256 internal CLOSE_FACTOR_DECIMALS = 1e5;

    IERC20 internal immutable sOHM; // collateral
    IgOHM internal immutable gOHM; // collateral
    
    address internal immutable treasury; // to send fees to
    IOracle public immutable oracle; // provides exchange rate data
    
    bool public allowStaked; // sOHM collateral enabled if true
    
    /* ========== STRUCTS ========== */

    struct UserInfo {
        uint256 collateral; // sOHM deposited (stored as g balance)
        uint256 borrowed; // OUSD borrowed
        uint256 interest; // interest accrued
        uint256 lastBlock; // last interest taken
    }
    mapping(address => UserInfo) public userInfo;

    struct Global {
        uint256 LI; // liquidation incentive
        uint256 LT; // liquidation threshold
        uint256 LTV; // maximum loan to value
        uint256 CF; // close factor
        uint256 IR; // interest rate
        uint256 fee; // borrow fee
        uint256 ceiling; // max debt
        uint256 outstanding; // current debt
        uint256 interest; // fees collected
        uint256 lastBlock; // last block when interest updated
        uint256 lastExchangeRate; // last price from oracle
    }
    Global public terms;
    
    /* ========== INITIALIZATION ========== */

    constructor(
        address _sohm, 
        address _gohm,
        address _treasury,
        address _oracle
    ) ERC20( 'Olympus USD', 'OUSD' ) { 
        require(_sohm != address(0), "Zero address: sOHM");
        sOHM = IERC20(_sohm);
        require(_gohm != address(0), "Zero address: gOHM");
        gOHM = IgOHM(_gohm);
        require(_treasury != address(0), "Zero address: Treasury");
        treasury = _treasury;
        require(_oracle != address(0), "Zero address: Oracle");
        oracle = IOracle(_oracle);
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    // deposit collateral
    function deposit (
        uint256 amount,
        address depositor,
        bool staked // sOHM or gOHM
    ) public {
        uint256 collateral;
        if (staked && allowStaked) {
            sOHM.safeTransferFrom(msg.sender, address(this), amount);
            collateral = gOHM.balanceTo(amount);
        } else {
            gOHM.safeTransferFrom(msg.sender, address(this), amount);
            collateral = amount;
        }

        userInfo[depositor].collateral += collateral;
        emit AddCollateral(depositor, collateral);
    }

    // withdraw collateral
    function withdraw (uint256 amount, bool staked) public {
        _updateExchangeRate();
        require(amount <= _canWithdraw(msg.sender, terms.lastExchangeRate), "Cannot withdraw amount");

        uint256 collateral;
        if (staked && allowStaked) {
            collateral = gOHM.balanceTo(amount);
            sOHM.safeTransfer(msg.sender, amount);
        } else {
            collateral = amount;
            gOHM.safeTransfer(msg.sender, amount);
        }

        userInfo[msg.sender].collateral -= collateral;
        emit RemoveCollateral(msg.sender, collateral);
    }

    // borrow stablecoin
    function borrow (uint256 amount) public {
        _updateExchangeRate();
        _takeInterest(msg.sender);

        UserInfo storage info = userInfo[msg.sender];

        require(terms.ceiling >= (terms.outstanding + terms.interest + amount), "Global debt limit");
        require(_maxBorrow(info.collateral, terms.lastExchangeRate) >= (info.borrowed + info.interest + amount), "Greater than max LTV");

        uint256 fee = amount * terms.fee / FEE_DECIMALS;

        terms.outstanding += amount;
        terms.interest += fee;

        info.borrowed += amount;
        info.interest += fee;

        _mint(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    // repay loan
    function repay (uint256 amount, address depositor) public {
        _updateExchangeRate();
        _takeInterest(depositor);

        _repay(depositor, amount);

        _burn(msg.sender, amount);
        emit Repay(msg.sender, amount);
    }
    
    // gas saving function
    function depositAndBorrow(
        uint256 amount,
        bool staked,
        uint256 toBorrow
    ) external {
        deposit(amount, msg.sender, staked);
        borrow(toBorrow);
    }

    // gas saving function
    function repayAndWithdraw(
        uint256 toRepay,
        uint256 amount,
        bool staked
    ) external {
        repay(toRepay, msg.sender);
        withdraw(amount, staked);
    }

    // liquidate borrower
    function liquidate (address depositor, uint256 amount, bool staked) external {
        _updateExchangeRate();
        _takeInterest(depositor);

        UserInfo storage info = userInfo[depositor];

        uint max = _debtCanLiquidate(depositor, terms.lastExchangeRate);
        require(amount <= max && max != 0, "Repayment too large");
        _burn(msg.sender, amount);

        uint256 liquidated = collateralForLiquidation(depositor, amount);

        info.collateral -= liquidated;

        _repay(depositor, amount);
        terms.outstanding -= amount;

        if (staked && allowStaked) {
            sOHM.safeTransfer(msg.sender, gOHM.balanceFrom(liquidated));
        } else {
            gOHM.safeTransfer(msg.sender, liquidated);
        }

        emit Liquidate(depositor, amount, liquidated, terms.lastExchangeRate);
    }

    // send collected interest fees to treasury
    function collect() external {
        if (terms.interest > 0) {
            _mint(treasury, terms.interest);
            terms.interest = 0;
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // add interest accrued since last interaction
    function _takeInterest (address depositor) internal {
        uint256 userBlocks = block.number - userInfo[depositor].lastBlock;
        uint256 userInterest = userInfo[depositor].borrowed * terms.IR * userBlocks / INTEREST_DECIMALS;
        userInfo[depositor].interest += userInterest;
        userInfo[depositor].lastBlock = block.number;

        uint256 globalBlocks = block.number - terms.lastBlock;
        uint256 globalInterest = terms.outstanding * terms.IR * globalBlocks / INTEREST_DECIMALS;
        terms.interest += globalInterest;
        terms.lastBlock = block.number;
    }

    // remove amount from interest before borrowed
    function _repay(address depositor, uint256 amount) internal {
        UserInfo storage info = userInfo[depositor];
        if (info.interest >= amount) {
            info.interest -= amount;
        } else if (info.interest > 0) {
            info.borrowed -= (amount - info.interest);
            info.interest = 0;
        } else {
            info.borrowed -= amount;
        }
    }

    // maximum amount depositor can withdraw given outstanding loan
    function _canWithdraw (address depositor, uint256 exchangeRate) internal view returns (uint256) {
        UserInfo memory info = userInfo[depositor];
        uint256 locked = info.collateral * (info.borrowed + info.interest) / _maxOutstanding(info.collateral, exchangeRate);
        return info.collateral - locked;
    }

    // amount of debt can be repaid to liquidate depositor
    function _debtCanLiquidate (address depositor, uint256 exchangeRate) internal view returns (uint256) {
        UserInfo memory info = userInfo[depositor];
        if (_maxOutstanding(info.collateral, exchangeRate) >= info.borrowed) {
            return 0;
        }
        return info.borrowed * terms.CF / CLOSE_FACTOR_DECIMALS;
    }

    // max a user with given balance can borrow
    function _maxBorrow (uint256 balance, uint256 exchangeRate) internal view returns (uint256) {
        // 9 decimals * 8 decimals * 5 decimals / 4 decimals = 18 decimals
        return gOHM.balanceFrom(balance) * exchangeRate * terms.LTV / 1e4;
    }

    // max a user with given balance can have outstanding
    function _maxOutstanding (uint256 balance, uint256 exchangeRate) internal view returns (uint256) {
        // 9 decimals * 8 decimals * 5 decimals / 4 decimals = 18 decimals
        return gOHM.balanceFrom(balance) * exchangeRate * terms.LT / 1e4;
    }

    // fetch exchange rate from oracle
    function _updateExchangeRate() internal {
        uint256 exchangeRate = oracle.assetPrice();
        if (exchangeRate != terms.lastExchangeRate && exchangeRate != 0) {
            terms.lastExchangeRate = exchangeRate;
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    // collateral returned when liquidating amount
    function collateralForLiquidation(address depositor, uint256 amount) public view returns (uint256) {
        UserInfo memory info = userInfo[depositor];
        uint256 liquidatable = info.collateral * (terms.LT + terms.LI) / LIQUIDATION_DECIMALS;
        return liquidatable * amount / (info.borrowed + info.interest);
    }

    // amount of collateral can be liquidated for depositor
    function collateralCanLiquidate (address depositor) external view returns (uint256) {
        UserInfo memory info = userInfo[depositor];
        if (_maxOutstanding(info.collateral, oracle.assetPrice()) >= (info.borrowed + info.interest)) {
            return 0;
        }
        uint256 liquidatable = info.collateral * (terms.LT + terms.LI) / LIQUIDATION_DECIMALS;
        return liquidatable * terms.CF / CLOSE_FACTOR_DECIMALS;
    }

    // calls internal function with current oracle price
    function canWithdraw (address depositor) external view returns (uint256) {  
        return _canWithdraw(depositor, oracle.assetPrice());
    }

    // calls internal function with current oracle price
    function debtCanLiquidate (address depositor) external view returns (uint256) {
        return _debtCanLiquidate(depositor, oracle.assetPrice());
    }

    // calls internal function with current oracle price
    function maxBorrow (uint256 balance) external view returns (uint256) {
        return _maxBorrow(balance, oracle.assetPrice());
    }

    // calls internal function with current oracle price
    function maxOutstanding (uint256 balance) external view returns (uint256) {
        return _maxOutstanding(balance, oracle.assetPrice());
    }

    /* ========== OWNABLE FUNCTIONS ========== */

    enum PARAM {LT, LI, LTV, CF, INTEREST, FEE, CEILING, MIGRATED}

    function set (PARAM param, uint256 input) external onlyOwner {
        if (param == PARAM.LT) { // Liquidation Threshold
            terms.LT = input; // 5 decimals
        } else if (param == PARAM.LI) { // Liquidation Incentive
            terms.LI = input; // 5 decimals
        } else if (param == PARAM.LTV) { // Max Loan-To-Value
            terms.LTV = input; // 5 decimals
        } else if (param == PARAM.CF) { // Close Factor
            terms.CF = input; // 5 decimals
        } else if (param == PARAM.INTEREST) { // Interest Per Block
            terms.IR = input; // 12 decimals
        } else if (param == PARAM.FEE) { // Open Fee
            terms.fee = input; // 5 decimals
        } else if (param == PARAM.CEILING) { // Debt Ceiling
            terms.ceiling = input; // 18 decimals
        } else if (param == PARAM.MIGRATED) { // Enable sOHM
            allowStaked = true;
        }
        emit ChangeParam(param, input);
    }
}