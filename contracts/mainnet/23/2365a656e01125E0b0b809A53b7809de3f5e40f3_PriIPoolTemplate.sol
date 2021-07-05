/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-06-21
*/

// File: localhost/interface/IERC20.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
     * @dev Emitted when `amount` tokens are moved from one account (`sender`) to
     * another (`recipient`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}
// File: localhost/base/Rootable.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

contract Rootable {

    address internal _ROOT_;
    bool internal _INIT_;

    event RootTransferred(address indexed previousRoot, address indexed newRoot);

    modifier notInit() {
        require(!_INIT_, "INITIALIZED");
        _;
    }

    function initRoot(address newRoot) internal notInit {
        _INIT_ = true;
        _ROOT_ = newRoot;

        emit RootTransferred(address(0), newRoot);
    }

    /**
     * @dev Returns the address of the current root.
     */
    function root() public view returns (address) {
        return _ROOT_;
    }

    /**
     * @dev Throws if called by any account other than the root.
     */
    modifier onlyRoot() {
        require(_ROOT_ == msg.sender, "YouSwap: CALLER_IS_NOT_THE_ROOT");
        _;
    }

    /**
     * @dev Leaves the contract without root. It will not be possible to call
     * `onlyRoot` functions anymore. Can only be called by the current root.
     *
     * NOTE: Renouncing root will leave the contract without an root,
     * thereby removing any functionality that is only available to the root.
     */
    function renounceRoot() public onlyRoot {
        emit RootTransferred(_ROOT_, address(0));
        _ROOT_ = address(0);
    }

    /**
     * @dev Transfers root of the contract to a new account (`newRoot`).
     * Can only be called by the current root.
     */
    function transferRoot(address newRoot) public onlyRoot {
        require(newRoot != address(0), "NEW_ROOT_IS_THE_ZERO_ADDRESS");
        emit RootTransferred(_ROOT_, newRoot);
        _ROOT_ = newRoot;
    }
}
// File: localhost/interface/IPoolFactory.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

interface IPoolFactory {

    function createPriPool(
        string calldata _proName,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenIn,
        address _tokenOut,
        uint256 _tokenOutSupply,
        uint256 _upperLimitOfTokenIn,
        uint256 _tokenOutPrice
    ) external returns (address newPool);

    function createPubPool(
        string calldata _proName,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenIn,
        address _tokenOut,
        uint256 _targetAmountOfTokenIn,
        uint256 _targetAmountOfTokenOut,
        uint256 _bottomLimitOfTokenIn
    ) external returns (address newPool);

    function addTokenInToWhiteList(address tokenIn) external;

    function removeTokenInFromWhiteList(address tokenIn) external;

    function tokenInWhiteList(address tokenIn) external view returns (bool);

    function getPools() external view returns (address[] memory pools);

    function getPoolsByCreator(address creator) external view returns (address[] memory pools);

    function getPoolsByParticipant(address creator) external view returns (address[] memory pools);

    function enroll(address participant, address pool) external returns (bool);

    function getPoolInfo(address poolAddr) external view returns (
        string memory proName,
        uint256 tokenOutPrice,
        string memory tokenInSymbol,
        string memory tokenOutSymbol,
        uint8 poolType,
        uint8 state,
        bool homePageShow,
        string memory proLink
    );
}

// File: localhost/interface/IPool.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

interface IPool {

    struct Participation {
        uint256 timeStamp;
        uint256 amountOfTokenIn;
        uint256 availableAmountOfTokenIn;
        uint256 amountOfTokenOut;
        bool claimed;
    }

    function getParticipation(address participant) external view returns (
        uint256 timeStamp,
        uint256 amountOfTokenIn,
        uint256 availableAmountOfTokenIn,
        uint256 amountOfTokenOut,
        bool claimed
    );

    function proName() external view returns (string memory);

    function proLink() external view returns (string memory);

    function homePageShow() external view returns (bool);

    function poolType() external view returns (uint8);

    function startTime() external view returns (uint256);

    function endTime() external view returns (uint256);

    function tokenOutPrice() external view returns (uint256);

    function nameOfTokenOut() external view returns (string memory);

    function symbolOfTokenOut() external view returns (string memory);

    function symbolOfTokenIn() external view returns (string memory);

    function decimalsOfTokenOut() external view returns (uint8);

    function isOver() external view returns (bool);

    function canClaim(address participant) external view returns (bool);

    function state() external view returns (uint8);

    function setStartTime(uint256 time) external returns (bool);

    function setEndTime(uint256 time) external returns (bool);

    function setVault(address newVault) external returns (bool);

    function activate(bool bActivated, bool bHomePageShow, string calldata prolink, uint256 feeRate) external returns (bool);

    function swap(uint256 amountOfTokenIn) external returns (bool);

    function claim() external returns (bool);

    function withdraw() external returns (bool);

    function claimTime() external view returns (uint256);

    function setClaimTime(uint256 time) external returns (bool);

    function getFeeRate() external view returns (uint256);

    function getFeeTo() external view returns (address);

    function setFeeTo(address account) external returns (bool);
}
// File: localhost/lib/Address.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isNotZero(address account) internal pure returns (bool) {
        return account != address(0);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
        (bool success,) = recipient.call{value : amount}("");
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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
// File: localhost/base/InitializableOwnable.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier notInitialized() {
        require(!_INITIALIZED_, "INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}
// File: localhost/lib/SafeMath.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
// File: localhost/token/IDO/PriIPoolTemplate.sol

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;








contract PriIPoolTemplate is IPool, InitializableOwnable, Rootable {
    using SafeMath for uint256;

    mapping(address => uint256) private _orders;
    mapping(address => Participation) private _participations;
    uint256 private _startTime;
    uint256 private _endTime;
    uint256 private _claimTime;
    uint256 private _tokenOutSupply;
    uint256 private _tokenOutReserved;
    uint256 private _totalAmountOfTokenIn;
    uint256 private _upperLimitOfTokenIn;
    bool private _isOver = false;
    string private _proName;
    string private _proLink;

    IPoolFactory public _FACTORY_;

    event PrivateOffering(address indexed participant, uint256 amountOfTokenIn, uint256 amountOfTokenOut);
    event PrivateOfferingClaimed(address indexed participant, uint256 amountOfTokenOut);

    uint256 private _tokenOutPrice;// TOKENOUT/TOKENIN * FACTOR
    uint256 public constant _FACTOR_ = 10000;

    mapping(address => uint8) private _whiteList;

    IERC20  public _TOKEN_IN_;
    IERC20  public _TOKEN_OUT_;

    bool private _withdrawn = false;
    uint8 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    bool private _activated = false;
    modifier activated() {
        require(_activated, "NOT_ACTIVATED");
        _;
    }
    modifier whenNotActivated() {
        require(!_activated, "ACTIVATED");
        _;
    }

    uint256 private _feeRate = 10;//10% as default
    address private _feeTo;

    address private _vault;
    bool private _homePageShow;
    bool public initialized;

    function init(
        address __factory,
        address __root,
        address __creator,
        string calldata __proName,
        uint256 __startTime,
        uint256 __endTime,
        address __tokenIn,
        address __tokenOut,
        uint256 __tokenOutSupply,
        uint256 __upperLimitOfTokenIn,
        uint256 __tokenOutPrice
    ) external {
        require(!initialized, "INITIALIZED");
        initOwner(__creator);
        initRoot(__root);
        _feeTo = __root;
        _vault = __creator;
        _FACTORY_ = IPoolFactory(__factory);
        _proName = __proName;
        _startTime = __startTime;
        _endTime = __endTime;
        _TOKEN_IN_ = IERC20(__tokenIn);
        _TOKEN_OUT_ = IERC20(__tokenOut);
        _tokenOutSupply = __tokenOutSupply;
        _upperLimitOfTokenIn = __upperLimitOfTokenIn;
        _tokenOutPrice = __tokenOutPrice;
        _totalAmountOfTokenIn = 0;
        initialized = true;
        unlocked = 1;
    }

    function setTokenOutPrice(uint256 newPrice) external whenNotActivated onlyOwner {
        _tokenOutPrice = newPrice;
    }

    function inWhiteList(address account) external view returns (bool) {
        return _whiteList[account] == 1;
    }

    function addToWhiteList(address account) external onlyOwner {
        _whiteList[account] = 1;
    }

    function addBatchToWhiteList(address[] calldata accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _whiteList[accounts[i]] = 1;
        }
    }

    function removeFromWhiteList(address account) external onlyOwner {
        _whiteList[account] = 0;
    }

    function tokenOutSupply() external view returns (uint256) {
        return _tokenOutSupply;
    }

    function tokenOutReserved() external view returns (uint256) {
        return _tokenOutReserved;
    }

    function totalAmountOfTokenIn() external view returns (uint256) {
        return _totalAmountOfTokenIn;
    }

    function setTokenOutSupply(uint256 newSupply) external whenNotActivated onlyOwner {
        _tokenOutSupply = newSupply;
    }

    function setUpperLimitOfTokenIn(uint256 newVal) external whenNotActivated onlyOwner {
        _upperLimitOfTokenIn = newVal;
    }

    function upperLimitOfTokenIn() external view returns (uint256) {
        return _upperLimitOfTokenIn;
    }

    //IPool
    function getParticipation(address participant) external override view returns (
        uint256 timeStamp,
        uint256 amountOfTokenIn,
        uint256 availableAmountOfTokenIn,
        uint256 amountOfTokenOut,
        bool claimed
    ){
        Participation memory p = _participations[participant];
        return (p.timeStamp, p.amountOfTokenIn, p.availableAmountOfTokenIn, p.amountOfTokenOut, p.claimed);
    }

    function proName() external override view returns (string memory){
        return _proName;
    }

    function proLink() external override view returns (string memory){
        return _proLink;
    }

    function homePageShow() external override view returns (bool){
        return _homePageShow;
    }

    function poolType() external view override returns (uint8){
        return 1;
    }

    function startTime() external view override returns (uint256){
        return _startTime;
    }

    function endTime() external override view returns (uint256){
        return _endTime;
    }

    function tokenOutPrice() external override view returns (uint256){
        return _tokenOutPrice;
    }

    function nameOfTokenOut() external override view returns (string memory) {
        return _TOKEN_OUT_.name();
    }

    function symbolOfTokenOut() external override view returns (string memory) {
        return _TOKEN_OUT_.symbol();
    }

    function symbolOfTokenIn() external override view returns (string memory) {
        return _TOKEN_IN_.symbol();
    }

    function decimalsOfTokenOut() external override view returns (uint8) {
        return _TOKEN_OUT_.decimals();
    }

    function isOver() public override view returns (bool) {
        return block.timestamp > _endTime || _isOver;
    }

    function canClaim(address participant) public override view returns (bool){
        return isOver() && _orders[participant] > 0 && block.timestamp >= _claimTime;
    }

    function state() external override view returns (uint8){
        if (_activated) {
            if (block.timestamp < _startTime) {//NOT STARTED
                return 1;
            }
            else if (!_isOver && block.timestamp >= _startTime && block.timestamp <= _endTime) {//IN PROGRESS
                return 2;
            }
            else {//IS OVER
                return 3;
            }
        }
        else {//NOT ACTIVATED
            return 0;
        }
    }

    function setStartTime(uint256 time) onlyOwner external override whenNotActivated returns (bool){
        require(time > block.timestamp.add(300), "INVALID_START_TIME");
        _startTime = time;
        return true;
    }

    function setEndTime(uint256 time) onlyOwner external override whenNotActivated returns (bool){
        require(time > block.timestamp.add(600), "INVALID_END_TIME");
        _endTime = time;
        return true;
    }

    function setVault(address newVault) onlyOwner external override whenNotActivated returns (bool){
        require(Address.isNotZero(newVault), 'ZERO_ADDRESS_NOT_ALLOWED');
        _vault = newVault;
        return true;
    }

    function activate(bool bActivated, bool bHomePageShow, string calldata sProlink, uint256 feeRate) onlyRoot external override returns (bool){
        require(_startTime > block.timestamp.add(300), "INVALID_START_TIME");
        require(_endTime >= _startTime.add(300), "INVALID_END_TIME");
        require(Address.isContract(address(_TOKEN_IN_)), "INVALID_TOKEN_IN");
        require(Address.isContract(address(_TOKEN_OUT_)), "INVALID_TOKEN_OUT");
        require(feeRate <= 100, "INVALID_FEE_RATE");

        if (_claimTime < _endTime) {
            _claimTime = _endTime;
        }

        _activated = bActivated;
        _homePageShow = bHomePageShow;
        _proLink = sProlink;
        _feeRate = feeRate;

        return true;
    }

    function swap(uint256 amountOfTokenIn) activated lock external override returns (bool)  {
        require(_whiteList[msg.sender] == 1, "NOT_IN_WHITE_LIST");
        require(block.timestamp >= _startTime, 'NOT_STARTED');
        require(!isOver(), 'PRIVATE_OFFERING_IS_OVER');
        require(_orders[msg.sender] == 0, 'ENROLLED_ALREADY');
        require(amountOfTokenIn <= _upperLimitOfTokenIn, 'EXCEEDS_THE_UPPER_LIMIT');
        require(amountOfTokenIn > 0, "INVALID_AMOUNT");
        require(_tokenOutReserved < _tokenOutSupply, 'INSUFFICIENT_TOKEN_OUT');

        uint256 tokenOutDeci = uint256(10) ** _TOKEN_OUT_.decimals();
        uint256 tokenInDeci = uint256(10) ** _TOKEN_IN_.decimals();

        uint256 amountOfTokenOut = amountOfTokenIn.mul(tokenOutDeci).mul(_tokenOutPrice).div(_FACTOR_).div(tokenInDeci);

        if (_tokenOutReserved.add(amountOfTokenOut) >= _tokenOutSupply) {
            amountOfTokenOut = _tokenOutSupply.sub(_tokenOutReserved);
            amountOfTokenIn = amountOfTokenOut.mul(_FACTOR_).mul(tokenInDeci).div(tokenOutDeci).div(_tokenOutPrice);
            _isOver = true;
        }

        _transferFrom(address(_TOKEN_IN_), msg.sender, address(this), amountOfTokenIn);
        _orders[msg.sender] = amountOfTokenOut;
        _tokenOutReserved = _tokenOutReserved.add(amountOfTokenOut);
        _totalAmountOfTokenIn = _totalAmountOfTokenIn.add(amountOfTokenIn);
        emit PrivateOffering(msg.sender, amountOfTokenIn, amountOfTokenOut);

        _FACTORY_.enroll(msg.sender, address(this));
        Participation storage p = _participations[msg.sender];
        p.timeStamp = block.timestamp;
        p.amountOfTokenIn = amountOfTokenIn;
        p.availableAmountOfTokenIn = amountOfTokenIn;
        p.amountOfTokenOut = amountOfTokenOut;

        return true;
    }

    function claim() lock external override returns (bool){
        require(canClaim(msg.sender), 'FORBIDDEN');

        uint256 reserved = _orders[msg.sender];
        _transfer(address(_TOKEN_OUT_), msg.sender, reserved);
        _orders[msg.sender] = 0;
        emit PrivateOfferingClaimed(msg.sender, reserved);

        Participation storage p = _participations[msg.sender];
        p.claimed = true;

        return true;
    }

    function withdraw() onlyRoot external override returns (bool){
        require(isOver(), 'IS_NOT_OVER');
        require(!_withdrawn, 'WITHDRAWN');

        uint256 fee = _totalAmountOfTokenIn.mul(_feeRate).div(100);
        if (fee > 0) {
            _transfer(address(_TOKEN_IN_), _feeTo, fee);
        }

        uint256 reserve = _totalAmountOfTokenIn.sub(fee);
        if (reserve > 0) {
            _transfer(address(_TOKEN_IN_), _vault, reserve);
        }

        _withdrawn = true;
        return true;
    }

    function claimTime() external override view returns (uint256){
        return _claimTime;
    }

    function setClaimTime(uint256 time) onlyRoot external override returns (bool){
        require(time > _endTime, 'FORBIDDEN');
        _claimTime = time;
        return true;
    }

    function getFeeRate() external override view returns (uint256){
        return _feeRate;
    }

    function getFeeTo() external override view returns (address){
        return _feeTo;
    }

    function setFeeTo(address account) onlyRoot override external returns (bool){
        _feeTo = account;
    }

    //Only can call  this function 7 days later when PRI OFFERING was over, in case of emergency
    function emergencyWithdraw(address token, address recipient, uint256 amount) onlyRoot external {
        require(block.timestamp > _claimTime.add(7 days), 'FORBIDDEN');

        bytes4 methodId = bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function _transfer(address token, address recipient, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function _transferFrom(address token, address sender, address recipient, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, sender, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');
    }
}