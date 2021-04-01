/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// File: contracts\modules\SafeInt256.sol

pragma solidity =0.5.16;
library SafeInt256 {
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require(((z = x + y) >= x) == (y >= 0), 'SafeInt256: addition overflow');
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require(((z = x - y) <= x) == (y >= 0), 'SafeInt256: substraction underflow');
    }

    function mul(int256 x, int256 y) internal pure returns (int256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeInt256: multiplication overflow');
    }
}

// File: contracts\modules\SafeMath.sol

pragma solidity =0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'SafeMath: addition overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'SafeMath: substraction underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeMath: multiplication overflow');
    }
}

// File: contracts\ERC20\IERC20.sol

pragma solidity =0.5.16;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts\modules\Ownable.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\modules\Managerable.sol

pragma solidity =0.5.16;

contract Managerable is Ownable {

    address private _managerAddress;
    /**
     * @dev modifier, Only manager can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyManager() {
        require(_managerAddress == msg.sender,"Managerable: caller is not the Manager");
        _;
    }
    /**
     * @dev set manager by owner. 
     *
     */
    function setManager(address managerAddress)
    public
    onlyOwner
    {
        _managerAddress = managerAddress;
    }
    /**
     * @dev get manager address. 
     *
     */
    function getManager()public view returns (address) {
        return _managerAddress;
    }
}

// File: contracts\modules\Halt.sol

pragma solidity =0.5.16;


contract Halt is Ownable {
    
    bool private halted = false; 
    
    modifier notHalted() {
        require(!halted,"This contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted,"This contract is not halted");
        _;
    }
    
    /// @notice function Emergency situation that requires 
    /// @notice contribution period to stop or not.
    function setHalt(bool halt) 
        public 
        onlyOwner
    {
        halted = halt;
    }
}

// File: contracts\modules\whiteList.sol

pragma solidity =0.5.16;
    /**
     * @dev Implementation of a whitelist which filters a eligible uint32.
     */
library whiteListUint32 {
    /**
     * @dev add uint32 into white list.
     * @param whiteList the storage whiteList.
     * @param temp input value
     */

    function addWhiteListUint32(uint32[] storage whiteList,uint32 temp) internal{
        if (!isEligibleUint32(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    /**
     * @dev remove uint32 from whitelist.
     */
    function removeWhiteListUint32(uint32[] storage whiteList,uint32 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible uint256.
     */
library whiteListUint256 {
    // add whiteList
    function addWhiteListUint256(uint256[] storage whiteList,uint256 temp) internal{
        if (!isEligibleUint256(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListUint256(uint256[] storage whiteList,uint256 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible address.
     */
library whiteListAddress {
    // add whiteList
    function addWhiteListAddress(address[] storage whiteList,address temp) internal{
        if (!isEligibleAddress(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListAddress(address[] storage whiteList,address temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleAddress(address[] memory whiteList,address temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexAddress(address[] memory whiteList,address temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}

// File: contracts\modules\AddressWhiteList.sol

pragma solidity =0.5.16;


    /**
     * @dev Implementation of a whitelist filters a eligible address.
     */
contract AddressWhiteList is Halt {

    using whiteListAddress for address[];
    uint256 constant internal allPermission = 0xffffffff;
    uint256 constant internal allowBuyOptions = 1;
    uint256 constant internal allowSellOptions = 1<<1;
    uint256 constant internal allowExerciseOptions = 1<<2;
    uint256 constant internal allowAddCollateral = 1<<3;
    uint256 constant internal allowRedeemCollateral = 1<<4;
    // The eligible adress list
    address[] internal whiteList;
    mapping(address => uint256) internal addressPermission;
    /**
     * @dev Implementation of add an eligible address into the whitelist.
     * @param addAddress new eligible address.
     */
    function addWhiteList(address addAddress)public onlyOwner{
        whiteList.addWhiteListAddress(addAddress);
        addressPermission[addAddress] = allPermission;
    }
    function modifyPermission(address addAddress,uint256 permission)public onlyOwner{
        addressPermission[addAddress] = permission;
    }
    /**
     * @dev Implementation of revoke an invalid address from the whitelist.
     * @param removeAddress revoked address.
     */
    function removeWhiteList(address removeAddress)public onlyOwner returns (bool){
        addressPermission[removeAddress] = 0;
        return whiteList.removeWhiteListAddress(removeAddress);
    }
    /**
     * @dev Implementation of getting the eligible whitelist.
     */
    function getWhiteList()public view returns (address[] memory){
        return whiteList;
    }
    /**
     * @dev Implementation of testing whether the input address is eligible.
     * @param tmpAddress input address for testing.
     */    
    function isEligibleAddress(address tmpAddress) public view returns (bool){
        return whiteList.isEligibleAddress(tmpAddress);
    }
    function checkAddressPermission(address tmpAddress,uint256 state) public view returns (bool){
        return  (addressPermission[tmpAddress]&state) == state;
    }
    modifier addressPermissionAllowed(address tmpAddress,uint256 state){
        require(checkAddressPermission(tmpAddress,state) , "Input address is not allowed");
        _;
    }
}

// File: contracts\OptionsPool\IOptionsPool.sol

pragma solidity =0.5.16;

interface IOptionsPool {
//    function getOptionBalances(address user) external view returns(uint256[]);

    function getExpirationList()external view returns (uint32[] memory);
    function createOptions(address from,address settlement,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) external returns(uint256);
    function setSharedState(uint256 newFirstOption,int256[] calldata latestNetWorth,address[] calldata whiteList) external;
    function getAllTotalOccupiedCollateral() external view returns (uint256,uint256);
    function getCallTotalOccupiedCollateral() external view returns (uint256);
    function getPutTotalOccupiedCollateral() external view returns (uint256);
    function getTotalOccupiedCollateral() external view returns (uint256);
//    function buyOptionCheck(uint32 expiration,uint32 underlying)external view;
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)external;
    function getOptionsById(uint256 optionsId)external view returns(uint256,address,uint8,uint32,uint256,uint256,uint256);
    function getExerciseWorth(uint256 optionsId,uint256 amount)external view returns(uint256);
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList) external view returns(int256[] memory);
    function getOptionInfoLength()external view returns (uint256);
    function getNetWrothCalInfo(address[] calldata whiteList)external view returns(uint256,int256[] memory);
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList)external view returns(int256[] memory,uint256[] memory,uint256);
    function getNetWrothLatestWorth(address settlement)external view returns(int256);
    function getBurnedFullPay(uint256 optionID,uint256 amount) external view returns(address,uint256);

}
contract ImportOptionsPool is Ownable{
    IOptionsPool internal _optionsPool;
    function getOptionsPoolAddress() public view returns(address){
        return address(_optionsPool);
    }
    function setOptionsPoolAddress(address optionsPool)public onlyOwner{
        _optionsPool = IOptionsPool(optionsPool);
    }
}

// File: contracts\modules\Operator.sol

pragma solidity =0.5.16;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Operator is Ownable {
    using whiteListAddress for address[];
    address[] private _operatorList;
    /**
     * @dev modifier, every operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperator() {
        require(_operatorList.isEligibleAddress(msg.sender),"Managerable: caller is not the Operator");
        _;
    }
    /**
     * @dev modifier, Only indexed operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperatorIndex(uint256 index) {
        require(_operatorList.length>index && _operatorList[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    /**
     * @dev add a new operator by owner. 
     *
     */
    function addOperator(address addAddress)public onlyOwner{
        _operatorList.addWhiteListAddress(addAddress);
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address addAddress)public onlyOwner{
        _operatorList[index] = addAddress;
    }
    /**
     * @dev remove operator by owner. 
     *
     */
    function removeOperator(address removeAddress)public onlyOwner returns (bool){
        return _operatorList.removeWhiteListAddress(removeAddress);
    }
    /**
     * @dev get all operators. 
     *
     */
    function getOperator()public view returns (address[] memory) {
        return _operatorList;
    }
    /**
     * @dev set all operators by owner. 
     *
     */
    function setOperators(address[] memory operators)public onlyOwner {
        _operatorList = operators;
    }
}

// File: contracts\CollateralPool\CollateralData.sol

pragma solidity =0.5.16;




/**
 * @title collateral pool contract with coin and necessary storage data.
 * @dev A smart-contract which stores user's deposited collateral.
 *
 */
contract CollateralData is AddressWhiteList,Managerable,Operator,ImportOptionsPool{
        // The total fees accumulated in the contract
    mapping (address => uint256) 	internal feeBalances;
    uint32[] internal FeeRates;
     /**
     * @dev Returns the rate of trasaction fee.
     */   
    uint256 constant internal buyFee = 0;
    uint256 constant internal sellFee = 1;
    uint256 constant internal exerciseFee = 2;
    uint256 constant internal addColFee = 3;
    uint256 constant internal redeemColFee = 4;
    event RedeemFee(address indexed recieptor,address indexed settlement,uint256 payback);
    event AddFee(address indexed settlement,uint256 payback);
    event TransferPayback(address indexed recieptor,address indexed settlement,uint256 payback);

    //token net worth balance
    mapping (address => int256) internal netWorthBalances;
    //total user deposited collateral balance
    // map from collateral address to amount
    mapping (address => uint256) internal collateralBalances;
    //user total paying for collateral, priced in usd;
    mapping (address => uint256) internal userCollateralPaying;
    //user original deposited collateral.
    //map account -> collateral -> amount
    mapping (address => mapping (address => uint256)) internal userInputCollateral;
}

// File: contracts\modules\Address.sol

pragma solidity =0.5.16;

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
        (bool success, ) = recipient.call.value(amount)("");
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
        (bool success, bytes memory returndata) = target.call.value(value )(data);
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

// File: contracts\ERC20\safeErc20.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.5.16;




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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// File: contracts\CollateralPool\TransactionFee.sol

pragma solidity =0.5.16;




    /**
     * @dev Implementation of a transaction fee manager.
     */
contract TransactionFee is CollateralData {
    using SafeMath for uint256;
    constructor() internal{
        initialize();
    }
    function initialize() onlyOwner public{
        FeeRates.push(50);
        FeeRates.push(0);
        FeeRates.push(50);
        FeeRates.push(0);
        FeeRates.push(0);
    }
    function getFeeRateAll()public view returns (uint32[] memory){
        return FeeRates;
    }
    function getFeeRate(uint256 feeType)public view returns (uint32){
        return FeeRates[feeType];
    }
    /**
     * @dev set the rate of trasaction fee.
     * @param feeType the transaction fee type
     * @param thousandth the numerator of transaction fee .
     * transaction fee = thousandth/1000;
     */   
    function setTransactionFee(uint256 feeType,uint32 thousandth)public onlyOwner{
        FeeRates[feeType] = thousandth;
    }

    function getFeeBalance(address settlement)public view returns(uint256){
        return feeBalances[settlement];
    }
    function getAllFeeBalances()public view returns(address[] memory,uint256[] memory){
        uint256[] memory balances = new uint256[](whiteList.length);
        for (uint256 i=0;i<whiteList.length;i++){
            balances[i] = feeBalances[whiteList[i]];
        }
        return (whiteList,balances);
    }
    function redeem(address currency)public onlyOwner{
        uint256 fee = feeBalances[currency];
        require (fee > 0, "It's empty balance");
        feeBalances[currency] = 0;
         if (currency == address(0)){
            msg.sender.transfer(fee);
        }else{
            IERC20 currencyToken = IERC20(currency);
            uint256 preBalance = currencyToken.balanceOf(address(this));
            SafeERC20.safeTransfer(currencyToken,msg.sender,fee);
//            currencyToken.transfer(msg.sender,fee);
            uint256 afterBalance = currencyToken.balanceOf(address(this));
            require(preBalance - afterBalance == fee,"settlement token transfer error!");
        }
        emit RedeemFee(msg.sender,currency,fee);
    }
    function redeemAll()public onlyOwner{
        for (uint256 i=0;i<whiteList.length;i++){
            redeem(whiteList[i]);
        }
    }
    function _addTransactionFee(address settlement,uint256 amount) internal {
        if (amount > 0){
            feeBalances[settlement] = feeBalances[settlement]+amount;
            emit AddFee(settlement,amount);
        }
    }
    function calculateFee(uint256 feeType,uint256 amount)public view returns (uint256){
        return FeeRates[feeType]*amount/1000;
    }
    /**
      * @dev  transfer settlement payback amount;
      * @param recieptor payback recieptor
      * @param settlement settlement address
      * @param payback amount of settlement will payback 
      */
    function _transferPaybackAndFee(address payable recieptor,address settlement,uint256 payback,uint256 feeType)internal{
        if (payback == 0){
            return;
        }
        uint256 fee = FeeRates[feeType]*payback/1000;
        _transferPayback(recieptor,settlement,payback-fee);
        _addTransactionFee(settlement,fee);
    }
    /**
      * @dev  transfer settlement payback amount;
      * @param recieptor payback recieptor
      * @param settlement settlement address
      * @param payback amount of settlement will payback 
      */
    function _transferPayback(address payable recieptor,address settlement,uint256 payback)internal{
        if (payback == 0){
            return;
        }
        if (settlement == address(0)){
            recieptor.transfer(payback);
        }else{
            IERC20 collateralToken = IERC20(settlement);
            uint256 preBalance = collateralToken.balanceOf(address(this));
            SafeERC20.safeTransfer(collateralToken,recieptor,payback);
            //collateralToken.transfer(recieptor,payback);
            uint256 afterBalance = collateralToken.balanceOf(address(this));
            require(preBalance - afterBalance == payback,"settlement token transfer error!");
        }
        emit TransferPayback(recieptor,settlement,payback);
    }
}

// File: contracts\CollateralPool\CollateralPool.sol

pragma solidity =0.5.16;


/**
 * @title collateral pool contract with coin and necessary storage data.
 * @dev A smart-contract which stores user's deposited collateral.
 *
 */
contract CollateralPool is TransactionFee{
    using SafeMath for uint256;
    using SafeInt256 for int256;
    constructor(address optionsPool)public{
        _optionsPool = IOptionsPool(optionsPool);
    }
    /**
     * @dev Transfer colleteral from manager contract to this contract.
     *  Only manager contract can invoke this function.
     */
    function () external payable onlyManager{

    }
    function initialize() onlyOwner public {
        TransactionFee.initialize();
    }
    function update() onlyOwner public{
    }
    /**
     * @dev An interface for add transaction fee.
     *  Only manager contract can invoke this function.
     * @param collateral collateral address, also is the coin for fee.
     * @param amount total transaction amount.
     * @param feeType transaction fee type. see TransactionFee contract
     */
    function addTransactionFee(address collateral,uint256 amount,uint256 feeType)public onlyManager returns (uint256) {
        uint256 fee = FeeRates[feeType]*amount/1000;
        _addTransactionFee(collateral,fee);
        return fee;
    }
    /**
     * @dev Retrieve user's cost of collateral, priced in USD.
     * @param user input retrieved account 
     */
    function getUserPayingUsd(address user)public view returns (uint256){
        return userCollateralPaying[user];
    }
    /**
     * @dev Retrieve user's amount of the specified collateral.
     * @param user input retrieved account 
     * @param collateral input retrieved collateral coin address 
     */
    function getUserInputCollateral(address user,address collateral)public view returns (uint256){
        return userInputCollateral[user][collateral];
    }

    /**
     * @dev Retrieve collateral balance data.
     * @param collateral input retrieved collateral coin address 
     */
    function getCollateralBalance(address collateral)public view returns (uint256){
        return collateralBalances[collateral];
    }
    /**
     * @dev Opterator user paying data, priced in USD. Only manager contract can modify database.
     * @param user input user account which need add paying amount.
     * @param amount the input paying amount.
     */
    function addUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = userCollateralPaying[user].add(amount);
    }
    /**
     * @dev Opterator user input collateral data. Only manager contract can modify database.
     * @param user input user account which need add input collateral.
     * @param collateral the collateral address.
     * @param amount the input collateral amount.
     */
    function addUserInputCollateral(address user,address collateral,uint256 amount)public onlyManager{
        userInputCollateral[user][collateral] = userInputCollateral[user][collateral].add(amount);
        collateralBalances[collateral] = collateralBalances[collateral].add(amount);
        netWorthBalances[collateral] = netWorthBalances[collateral].add(int256(amount));
    }
    /**
     * @dev Opterator net worth balance data. Only manager contract can modify database.
     * @param whiteList available colleteral address list.
     * @param newNetworth collateral net worth list.
     */
    function addNetWorthBalances(address[] memory whiteList,int256[] memory newNetworth)internal{
        for (uint i=0;i<newNetworth.length;i++){
            netWorthBalances[whiteList[i]] = netWorthBalances[whiteList[i]].add(newNetworth[i]);
        }
    }
    /**
     * @dev Opterator net worth balance data. Only manager contract can modify database.
     * @param collateral available colleteral address.
     * @param amount collateral net worth increase amount.
     */
    function addNetWorthBalance(address collateral,int256 amount)public onlyManager{
        netWorthBalances[collateral] = netWorthBalances[collateral].add(amount);
    }
    /**
     * @dev Opterator collateral balance data. Only manager contract can modify database.
     * @param collateral available colleteral address.
     * @param amount collateral colleteral increase amount.
     */
    function addCollateralBalance(address collateral,uint256 amount)public onlyManager{
        collateralBalances[collateral] = collateralBalances[collateral].add(amount);
    }
    /**
     * @dev Substract user paying data,priced in USD. Only manager contract can modify database.
     * @param user user's account.
     * @param amount user's decrease amount.
     */
    function subUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = userCollateralPaying[user].sub(amount);
    }
    /**
     * @dev Substract user's collateral balance. Only manager contract can modify database.
     * @param user user's account.
     * @param collateral collateral address.
     * @param amount user's decrease amount.
     */
    function subUserInputCollateral(address user,address collateral,uint256 amount)public onlyManager{
        userInputCollateral[user][collateral] = userInputCollateral[user][collateral].sub(amount);
    }
    /**
     * @dev Substract net worth balance. Only manager contract can modify database.
     * @param collateral collateral address.
     * @param amount the decrease amount.
     */
    function subNetWorthBalance(address collateral,int256 amount)public onlyManager{
        netWorthBalances[collateral] = netWorthBalances[collateral].sub(amount);
    }
    /**
     * @dev Substract collateral balance. Only manager contract can modify database.
     * @param collateral collateral address.
     * @param amount the decrease amount.
     */
    function subCollateralBalance(address collateral,uint256 amount)public onlyManager{
        collateralBalances[collateral] = collateralBalances[collateral].sub(amount);
    }
    /**
     * @dev set user paying data,priced in USD. Only manager contract can modify database.
     * @param user user's account.
     * @param amount user's new amount.
     */
    function setUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = amount;
    }
    /**
     * @dev set user's collateral balance. Only manager contract can modify database.
     * @param user user's account.
     * @param collateral collateral address.
     * @param amount user's new amount.
     */
    function setUserInputCollateral(address user,address collateral,uint256 amount)public onlyManager{
        userInputCollateral[user][collateral] = amount;
    }
    /**
     * @dev set net worth balance. Only manager contract can modify database.
     * @param collateral collateral address.
     * @param amount the new amount.
     */
    function setNetWorthBalance(address collateral,int256 amount)public onlyManager{
        netWorthBalances[collateral] = amount;
    }
    /**
     * @dev set collateral balance. Only manager contract can modify database.
     * @param collateral collateral address.
     * @param amount the new amount.
     */
    function setCollateralBalance(address collateral,uint256 amount)public onlyManager{
        collateralBalances[collateral] = amount;
    }
    /**
     * @dev Operation for transfer user's payback and deduct transaction fee. Only manager contract can invoke this function.
     * @param recieptor the recieptor account.
     * @param settlement the settlement coin address.
     * @param payback the payback amount
     * @param feeType the transaction fee type. see transactionFee contract
     */
    function transferPaybackAndFee(address payable recieptor,address settlement,uint256 payback,
            uint256 feeType)public onlyManager{
        _transferPaybackAndFee(recieptor,settlement,payback,feeType);
        netWorthBalances[settlement] = netWorthBalances[settlement].sub(int256(payback));
    }
        /**
     * @dev Operation for transfer user's payback. Only manager contract can invoke this function.
     * @param recieptor the recieptor account.
     * @param allPay the payback amount
     */
    function buyOptionsPayfor(address payable recieptor,address settlement,uint256 settlementAmount,uint256 allPay)public onlyManager{
        uint256 fee = addTransactionFee(settlement,allPay,0);
        require(settlementAmount>=allPay+fee,"settlement asset is insufficient!");
        settlementAmount = settlementAmount-(allPay+fee);
        if (settlementAmount > 0){
            _transferPayback(recieptor,settlement,settlementAmount);
        }
    }
    /**
     * @dev Operation for transfer user's payback. Only manager contract can invoke this function.
     * @param recieptor the recieptor account.
     * @param settlement the settlement coin address.
     * @param payback the payback amount
     */
    function transferPayback(address payable recieptor,address settlement,uint256 payback)public onlyManager{
        _transferPayback(recieptor,settlement,payback);
    }
    /**
     * @dev Operation for transfer user's payback and deduct transaction fee for multiple settlement Coin.
     *       Specially used for redeem collateral.Only manager contract can invoke this function.
     * @param account the recieptor account.
     * @param redeemWorth the redeem worth, priced in USD.
     * @param tmpWhiteList the settlement coin white list
     * @param colBalances the Collateral balance based for user's input collateral.
     * @param PremiumBalances the premium collateral balance if redeem worth is exceeded user's input collateral.
     * @param prices the collateral prices list.
     */
    function transferPaybackBalances(address payable account,uint256 redeemWorth,address[] memory tmpWhiteList,uint256[] memory colBalances,
        uint256[] memory PremiumBalances,uint256[] memory prices)public onlyManager {
        uint256 ln = tmpWhiteList.length;
        uint256[] memory PaybackBalances = new uint256[](ln);
        uint256 i=0;
        uint256 amount;
        for(; i<ln && redeemWorth>0;i++){
            //address addr = tmpWhiteList[i];
            if (colBalances[i] > 0){
                amount = redeemWorth/prices[i];
                if (amount < colBalances[i]){
                    redeemWorth = 0;
                }else{
                    amount = colBalances[i];
                    redeemWorth = redeemWorth - colBalances[i]*prices[i];
                }
                PaybackBalances[i] = amount;
                amount = amount * userInputCollateral[account][tmpWhiteList[i]]/colBalances[i];
                userInputCollateral[account][tmpWhiteList[i]] =userInputCollateral[account][tmpWhiteList[i]].sub(amount);
                collateralBalances[tmpWhiteList[i]] = collateralBalances[tmpWhiteList[i]].sub(amount);

            }
        }
        if (redeemWorth>0) {
           amount = 0;
            for (i=0; i<ln;i++){
                amount = amount.add(PremiumBalances[i]*prices[i]);
            }
//            require(amount >= redeemWorth ,"redeem collateral is insufficient");
            if (amount<redeemWorth){
                amount = redeemWorth;
            }
            for (i=0; i<ln;i++){
                PaybackBalances[i] = PaybackBalances[i].add(PremiumBalances[i].mul(redeemWorth)/amount);
            }
        }
        for (i=0;i<ln;i++){ 
            transferPaybackAndFee(account,tmpWhiteList[i],PaybackBalances[i],redeemColFee);
        } 
    }
    /**
     * @dev calculate user's input collateral balance and premium collateral balance.
     *      Specially used for user's redeem collateral.
     * @param account the recieptor account.
     * @param userTotalWorth the user's total FPTCoin worth, priced in USD.
     * @param tmpWhiteList the settlement coin white list
     * @param _RealBalances the real Collateral balance.
     * @param prices the collateral prices list.
     */
    function getCollateralAndPremiumBalances(address account,uint256 userTotalWorth,address[] memory tmpWhiteList,
        uint256[] memory _RealBalances,uint256[] memory prices) public view returns(uint256[] memory,uint256[] memory){
//        uint256 ln = tmpWhiteList.length;
        uint256[] memory colBalances = new uint256[](tmpWhiteList.length);
        uint256[] memory PremiumBalances = new uint256[](tmpWhiteList.length);
        uint256 totalWorth = 0;
        uint256 PremiumWorth = 0;
        uint256 i=0;
        for(; i<tmpWhiteList.length;i++){
            (colBalances[i],PremiumBalances[i]) = calUserNetWorthBalanceRate(tmpWhiteList[i],account,_RealBalances[i]);
            totalWorth = totalWorth.add(prices[i]*colBalances[i]);
            PremiumWorth = PremiumWorth.add(prices[i]*PremiumBalances[i]);
        }
        if (totalWorth >= userTotalWorth){
            for (i=0; i<tmpWhiteList.length;i++){
                colBalances[i] = colBalances[i].mul(userTotalWorth)/totalWorth;
            }
        }else if (PremiumWorth>0){
            userTotalWorth = userTotalWorth - totalWorth;
            for (i=0; i<tmpWhiteList.length;i++){
                PremiumBalances[i] = PremiumBalances[i].mul(userTotalWorth)/PremiumWorth;
            }
        }
        return (colBalances,PremiumBalances);
    } 
    /**
     * @dev calculate user's input collateral balance.
     *      Specially used for user's redeem collateral.
     * @param settlement the settlement coin address.
     * @param user the recieptor account.
     * @param netWorthBalance the settlement coin real balance
     */
    function calUserNetWorthBalanceRate(address settlement,address user,uint256 netWorthBalance)internal view returns(uint256,uint256){
        uint256 collateralBalance = collateralBalances[settlement];
        uint256 amount = userInputCollateral[user][settlement];
        if (collateralBalance > 0){
            uint256 curAmount = netWorthBalance.mul(amount)/collateralBalance;
            return (curAmount,netWorthBalance.sub(curAmount));
        }else{
            return (0,netWorthBalance);
        }
    }
    function getAllRealBalance(address[] memory whiteList)public view returns(int256[] memory){
        uint256 len = whiteList.length;
        int256[] memory realBalances = new int256[](len); 
        for (uint i = 0;i<len;i++){
            int256 latestWorth = _optionsPool.getNetWrothLatestWorth(whiteList[i]);
            realBalances[i] = netWorthBalances[whiteList[i]].add(latestWorth);
        }
        return realBalances;
    }
        /**
     * @dev Retrieve the balance of collateral, the auxiliary function for the total collateral calculation. 
     */
    function getRealBalance(address settlement)public view returns(int256){
        int256 latestWorth = _optionsPool.getNetWrothLatestWorth(settlement);
        return netWorthBalances[settlement].add(latestWorth);
    }
    function getNetWorthBalance(address settlement)public view returns(uint256){
        int256 latestWorth = _optionsPool.getNetWrothLatestWorth(settlement);
        int256 netWorth = netWorthBalances[settlement].add(latestWorth);
        if (netWorth>0){
            return uint256(netWorth);
        }
        return 0;
    }
        /**
     * @dev  The foundation operator want to add some coin to netbalance, which can increase the FPTCoin net worth.
     * @param settlement the settlement coin address which the foundation operator want to transfer in this contract address.
     * @param amount the amount of the settlement coin which the foundation operator want to transfer in this contract address.
     */
    function addNetBalance(address settlement,uint256 amount) public payable {
        amount = getPayableAmount(settlement,amount);
        netWorthBalances[settlement] = netWorthBalances[settlement].add(int256(amount));
    }
        /**
     * @dev the auxiliary function for getting user's transer
     */
    function getPayableAmount(address settlement,uint256 settlementAmount) internal returns (uint256) {
        if (settlement == address(0)){
            settlementAmount = msg.value;
        }else if (settlementAmount > 0){
            IERC20 oToken = IERC20(settlement);
            uint256 preBalance = oToken.balanceOf(address(this));
            oToken.transferFrom(msg.sender, address(this), settlementAmount);
            uint256 afterBalance = oToken.balanceOf(address(this));
            require(afterBalance-preBalance==settlementAmount,"settlement token transfer error!");
        }
        return settlementAmount;
    }
        /**
     * @dev Calculate the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     */
    function calSharedPayment(address[] memory _whiteList) public onlyOperatorIndex(0) {
        (uint256 firstOption,int256[] memory latestShared) = _optionsPool.getNetWrothCalInfo(_whiteList);
        uint256 lastOption = _optionsPool.getOptionInfoLength();
        (int256[] memory newNetworth,uint256[] memory sharedBalance,uint256 newFirst) =
                     _optionsPool.calRangeSharedPayment(lastOption,firstOption,lastOption,_whiteList);
        int256[] memory fallBalance = _optionsPool.calculatePhaseOptionsFall(lastOption,newFirst,lastOption,_whiteList);
        for (uint256 i= 0;i<fallBalance.length;i++){
            fallBalance[i] = int256(sharedBalance[i]).sub(latestShared[i]).add(fallBalance[i]);
        }
        setSharedPayment(_whiteList,newNetworth,fallBalance,newFirst);
    }
    /**
     * @dev Set the calculation results of the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     * @param newNetworth Current expired options' net worth 
     * @param sharedBalances All unexpired options' shared balance distributed by time.
     * @param firstOption The new first unexpired option's index.
     */
    function setSharedPayment(address[] memory _whiteList,int256[] memory newNetworth,int256[] memory sharedBalances,uint256 firstOption) public onlyOperatorIndex(0){
        _optionsPool.setSharedState(firstOption,sharedBalances,_whiteList);
        addNetWorthBalances(_whiteList,newNetworth);
    }
}