/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.0;

interface IOracle {
    function assetPrice() external view returns (uint);
}

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

interface IgOHM is IERC20 {
    function balanceFrom(uint amount) external view returns (uint);
    function balanceTo(uint amount) external view returns (uint);
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IOUSD {
    function mint(address to, uint amount) external;
    function burn(address from, uint amount) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

/**
 * OUSD is a CDP stablecoin backed by staked OHM deposits. It accepts both s and g OHM
 * as collateral. It charges a fixed interest rate plus an origination fee. 
 * Loan origination is constrained by a maximum loan-to-value and capped by a global
 * debt ceiling. Liquidations occur at a liquidation threshold, with the liquidator
 * compensated by an incentive. Liquidations occur in max tranches, as decided by the
 * close factor. Fees collected are sent to the Olympus treasury.
 */
contract OUSDVault is Ownable {
    
    using SafeERC20 for IERC20;
    using SafeERC20 for IgOHM;

    IERC20 internal immutable sOHM; // collateral
    IgOHM internal immutable gOHM; // collateral
    IOUSD public OUSD; // debt token

    struct UserInfo {
        uint collateral; // sOHM deposited (stored as g balance)
        uint borrowed; // OUSD borrowed
        uint lastBlock; // last interest taken
    }
    mapping(address => UserInfo) public userInfo;

    struct Global {
        uint LI; // liquidation incentive
        uint LT; // liquidation threshold
        uint LTV; // maximum loan to value
        uint CF; // close factor
        uint interest; // interest rate
        uint fee; // borrow fee
        uint ceiling; // max debt
        uint outstanding; // current debt
        uint accrued; // fees collected
    }
    Global public terms;
    
    IOracle public immutable oracle;
    address internal immutable treasury; // to send fees to

    constructor(
        address _sohm, 
        address _gohm,
        address _treasury,
        address _oracle
    )  { 
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
        uint amount,
        address depositor,
        bool staked // sOHM or gOHM
    ) public {
        if (staked) {
            sOHM.safeTransferFrom(msg.sender, address(this), amount);
            userInfo[depositor].collateral += gOHM.balanceTo(amount);
        } else {
            gOHM.safeTransferFrom(msg.sender, address(this), amount);
            userInfo[depositor].collateral += amount;
        }
    }

    // withdraw collateral
    function withdraw (uint amount, bool staked) public {
        require(amount <= canWithdraw(msg.sender), "Cannot withdraw amount");

        if (staked) {
            userInfo[msg.sender].collateral -= gOHM.balanceTo(amount);
            sOHM.safeTransfer(msg.sender, amount);
        } else {
            userInfo[msg.sender].collateral -= amount;
            gOHM.safeTransfer(msg.sender, amount);
        }
    }

    // borrow stablecoin
    function borrow (uint amount) public {
        _takeInterest(msg.sender);

        require(terms.ceiling >= terms.outstanding + amount, "Global debt limit");
        require(maxBorrow(userBalance(msg.sender)) >= amount + userInfo[msg.sender].borrowed, "Greater than max LTV");

        uint fee = amount * terms.fee / 1e4;

        terms.accrued += fee;
        terms.outstanding += (amount + fee);
        userInfo[msg.sender].borrowed += (amount + fee);

        OUSD.mint(msg.sender, amount);
    }

    // repay loan
    function repay (uint amount, address depositor) public {
        _takeInterest(depositor);

        userInfo[depositor].borrowed -= amount;
        OUSD.burn(msg.sender, amount);
    }

    // liquidate borrower
    function liquidate (address depositor, uint amount, bool staked) external {
        _takeInterest(depositor);

        uint max = debtCanLiquidate(depositor);
        require(amount <= max && max != 0, "Repayment too large");
        OUSD.burn(msg.sender, amount);

        uint liquidatable = userBalance(depositor) * (terms.LT + terms.LI) / 1e4;
        uint liquidated = liquidatable * amount / userInfo[depositor].borrowed;

        if (staked) {
            userInfo[depositor].collateral -= gOHM.balanceTo(liquidated);
            sOHM.safeTransfer(msg.sender, liquidated);
        } else {
            userInfo[depositor].collateral -= gOHM.balanceTo(liquidated);
            gOHM.safeTransfer(msg.sender, gOHM.balanceTo(liquidated));
        }
    }

    // send collected interest fees to treasury
    function collect() external {
        if (terms.accrued > 0) {
            OUSD.mint(treasury, terms.accrued);
            terms.accrued = 0;
        }
    }

    /* ========== HELPER FUNCTIONS ========== */

    // gas saving function
    function depositAndBorrow(
        uint amount,
        bool staked,
        uint toBorrow
    ) external {
        deposit(amount, msg.sender, staked);
        borrow(toBorrow);
    }

    // gas saving function
    function repayAndWithdraw(
        uint toRepay,
        uint amount,
        bool staked
    ) external {
        repay(toRepay, msg.sender);
        withdraw(amount, staked);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // charge user interest accrued since last interaction
    function _takeInterest (address depositor) internal {
        uint blocks = block.number - userInfo[depositor].lastBlock;
        uint interest = userInfo[depositor].borrowed * terms.interest * blocks / 1e12;
        
        userInfo[depositor].borrowed += interest;
        terms.accrued += interest;
        terms.outstanding += interest;

        userInfo[depositor].lastBlock = block.number;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // maximum amount depositor can withdraw given outstanding loan
    function canWithdraw (address depositor) public view returns (uint) {
        uint balance = userBalance(depositor);
        uint locked = balance * userInfo[depositor].borrowed / maxLoan(balance);
        return balance - locked;
    }

    // amount of collateral can be liquidator for depositor
    function collateralCanLiquidate (address depositor) public view returns (uint) {
        uint balance = userBalance(depositor);
        if (maxLoan(balance) >= userInfo[depositor].borrowed) {
            return 0;
        }
        uint liquidatable = balance * (terms.LT + terms.LI) / 1e4;
        return liquidatable * terms.CF / 1e4;
    }

    // amount of debt can be repaid to liquidate depositor
    function debtCanLiquidate (address depositor) public view returns (uint) {
        uint borrowed = userInfo[depositor].borrowed;
        if (maxLoan(userBalance(depositor)) >= borrowed) {
            return 0;
        }
        return borrowed * terms.CF / 1e4;
    }

    // user balances converted to sOHM balance
    function userBalance (address depositor) public view returns (uint) {
        return gOHM.balanceFrom(userInfo[depositor].collateral);
    }

    // max a user with given balance can borrow
    function maxBorrow (uint balance) public view returns (uint) {
        return balance * oracle.assetPrice() * terms.LTV / 1e3;
    }

    // max a user with given balance can have outstanding
    function maxLoan (uint balance) public view returns (uint) {
        return balance * oracle.assetPrice() * terms.LT / 1e3;
    }

    /* ========== OWNABLE FUNCTIONS ========== */

    enum PARAM {LT, LI, LTV, CF, INTEREST, FEE, CEILING, OUSD}

    // set term
    function set (PARAM param, uint input) external onlyOwner {
        if (param == PARAM.LT) { // Liquidation Threshold
            terms.LT = input; // 4 decimals
        } else if (param == PARAM.LI) { // Liquidation Incentive
            terms.LI = input; // 4 decimals
        } else if (param == PARAM.LTV) { // Max Loan-To-Value
            terms.LTV = input; // 4 decimals
        } else if (param == PARAM.CF) { // Close Factor
            terms.CF = input; // 4 decimals
        } else if (param == PARAM.INTEREST) { // Interest Per Block
            terms.interest = input; // 12 decimals
        } else if (param == PARAM.FEE) { // Open Fee
            terms.fee = input; // 4 decimals
        } else if (param == PARAM.CEILING) { // Debt Ceiling
            terms.ceiling = input; // 18 decimals
        }
    }

    // set OUSD -- do first!
    function init(address _ousd) external onlyOwner {
        require(address(OUSD) == address(0), "Already set");
        require(_ousd != address(0), "Zero address: OUSD");
        OUSD = IOUSD(_ousd);
    }
}