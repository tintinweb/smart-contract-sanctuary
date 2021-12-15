// SPDX-License-Identifier: SimPL-2.0

import "./interfaces/ICore.sol";
import "./interfaces/Iincentive.sol";
import "./interfaces/IPcv.sol";
import "./utils/Address.sol";
import "./utils/Context.sol";
import "./interfaces/IDp.sol";

pragma solidity ^0.8.0;

contract Core is ICore{
    
    IDp public _dp;

    address public _admin;
    
    Iincentive public incentiveContract;
    IPcv public pcvContract;
    
    bool public _openIncentive = false;
    bool public _openPcv = false;
    
    mapping(address => bool) excludeIncentive;
    mapping(address => bool) excludePcv;
    
    mapping(address => bool) minters;
    mapping(address => bool) burners;

    constructor(){
        _admin = msg.sender;
    }

    function setDp(address token) external onlyAdmin {
        _dp = IDp(token);
    }

    // ----- Set up various incentive contracts ------
    function setIncentiveContract(address _incentiveContract) external onlyAdmin {
        incentiveContract = Iincentive(_incentiveContract);
    }

    function setPcvContract(address _pcvContract) external onlyAdmin {
        pcvContract = IPcv(_pcvContract);
    }

    function setIncentiveEnable(bool _isEnable) external onlyAdmin {
        require(address(incentiveContract) != address(0),"Core: incentive contract address is 0");
        _openIncentive = _isEnable;
    }

    function setPcvEnable(bool _isEnable) external onlyAdmin {
        require(address(pcvContract) != address(0),"Core: pcv contract address is 0");
        _openPcv = _isEnable;
    }

    function getIncentiveState() external view override returns(bool){
        return _openIncentive;
    }

    function getPcvState() external view override returns(bool){
        return _openPcv;
    }

    // ------ Minting authority related -------
    function setMinter(address account) external onlyAdmin{
        minters[account] = true;
    }

    function setBurner(address account) external onlyAdmin{
        burners[account] = true;
    }

    function removeMinter(address account) external onlyAdmin{
        delete minters[account] ;
    }

    function removeBurner(address account) external onlyAdmin{
        delete burners[account] ;
    }

    function isMinter(address account) external override view returns(bool){
        if(minters[account] == true){
            return true;
        }
        return false;
    }

    modifier onlyMinter(){
        address account = msg.sender;
        require(minters[account] == true,"core: caller is not minter");
        _;
    }


    function isBurner(address account)  external override view returns(bool){
        if(burners[account] == true){
            return true;
        }
        return false;
    }
    
    function executeExtra(address sender,address recipient,uint256 amount) external override onlyDp returns(uint256) {
        uint256  newAmount = executePcv(sender,recipient,amount);
        newAmount = executeIncentive(sender,recipient,newAmount);
        return newAmount;
    }

    // Perform transfer deflation
    function executePcv(address sender,address recipient,uint256 amount) internal returns(uint256){
        // Exclude address
        if(excludePcv[sender] || excludePcv[recipient]){
            return amount;
        }
        if(!_openPcv){
            return amount;
        }

        uint256 newAmount = pcvContract.execute(sender,recipient,amount);
        emit executedPcv(sender,recipient,amount);
        return newAmount;
    }

    // Exercise price self-care incentive
    function executeIncentive(address sender,address recipient,uint256 amount) internal returns(uint256){
        // Exclude address
        if(excludeIncentive[sender] || excludeIncentive[recipient]){
            return amount;
        }
        if(!_openIncentive){
            return amount;
        }

        uint256 newAmount = incentiveContract.execute(sender,recipient,amount);
        emit executedIncentive(sender,recipient,amount);
        return newAmount;
    }

    modifier onlyDp(){
        require( address(_dp) == msg.sender,"Core: caller is not dp");
        _;
    }

    // Can the reward be withdrawn
    function ifGetReward() external view override returns(bool){
        return incentiveContract.priceOverAvg();
    }

    // Get the total rewards generated
    function getTotalReward() external view override returns(uint256){
        uint256 _totalReward;
        if(address(incentiveContract) != address(0)){
            _totalReward = incentiveContract.getTotalReward();
        }
        if(address(pcvContract) != address(0)){
            _totalReward += pcvContract.getTotalFee();
        }
        return _totalReward;
    }

    // Exclude incentive address
    function isExcludeIncentive(address account) public view returns(bool){
        return excludeIncentive[account];
    }

    // Is it an address that excludes handling fees?
    function isExcludePcv(address account) public view returns(bool){
        return excludePcv[account];
    }

    // Set exclusion incentive address
    function setExcludeIncentive(address account) external onlyAdmin{
        excludeIncentive[account] = true;
    }

    // Set up exclusion fee address
    function removeExcludePcv(address account) external onlyAdmin{
        delete excludePcv[account];
    }

    // Set exclusion incentive address
    function removeExcludeIncentive(address account) external onlyAdmin{
        delete excludeIncentive[account];
    }

    // Set up exclusion fee address
    function setExcludePcv(address account) external onlyAdmin{
        excludePcv[account] = true;
    }

    event executedPcv(address sender,address recipient,uint256 amount);
    event executedIncentive(address sender,address recipient,uint256 amount);

    // ----- Access control -----
    modifier onlyAdmin() {
        require(_admin == msg.sender,"Core: caller is not admin");
        _;
    }

    function isOverSold() external view returns(bool){
        (,bool oversold) = incentiveContract.getTradeSignal();
        return oversold;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: SimPL-2.0

pragma solidity ^0.8.0;

interface Iincentive {

    // 获取所有产生的奖励
    function getTotalReward() view external returns(uint256) ;

    // 获取交易信号 （是否超买，是否超卖）
    function getTradeSignal() external view returns(bool,bool);

    // 执行激励
    function execute(address sender,address recipient,uint256 amount) external returns(uint256);

    function priceOverAvg() external view returns(bool);


}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

interface IPcv {

    function getFeeRate()  external view returns(uint256,uint256);

    function execute(address sender,address recipient,uint256 amount) external returns(uint256);

    function getTotalFee() external view returns(uint256);

}

// SPDX-License-Identifier: SimPL-2.0

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

interface IDp is IERC20 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;


    function mint(address account, uint256 amount) external;


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICore {

    function getIncentiveState() external view returns(bool);

    function getPcvState() external view returns(bool);

    function isMinter(address account) external view returns(bool);

    function isBurner(address account)  external view returns(bool);

    function executeExtra(address sender,address recipient,uint256 amount) external returns(uint256);

    function ifGetReward() external view returns(bool);

    function getTotalReward() external view returns(uint256);

}