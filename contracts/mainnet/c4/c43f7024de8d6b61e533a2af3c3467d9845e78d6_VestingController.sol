/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/utils/math/Math.sol



pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

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

// File: contracts/stakedBalance/StakingContractI.sol

pragma solidity 0.8.4;


interface StakingContractI {
    function stakedBalance(address who, address token) external view returns (uint);
}

// File: contracts/stakedBalance/StakedBalanceFetcher.sol

pragma solidity 0.8.4;




// We'll have a low number of staking contracts (less than 10) so O(n) insertions and deletions should be ok.
contract StakedBalanceFetcher is Ownable {

    event StakingContractAdded(address indexed stakingContract);
    event StakingContractRemoved(address indexed stakingContract);

    StakingContractI[] public stakingContracts;

    function addStakingContract(address _stakingContract) external onlyOwner {
        (bool exists,) = getStakingContractIndex(_stakingContract);
        require(!exists, "StakedBalanceFetcher: Staking contract already added");

        stakingContracts.push(StakingContractI(_stakingContract));

        emit StakingContractAdded(_stakingContract);
    }

    // We don't need to preserve ordering in the stakingContracts array
    function removeStakingContract(address _stakingContract) external onlyOwner {
        (bool exists, uint index) = getStakingContractIndex(_stakingContract);
        require(exists, "StakedBalanceFetcher: Staking contract not added");

        if(index != stakingContracts.length - 1){
            StakingContractI lastItem = stakingContracts[stakingContracts.length - 1];
            stakingContracts.pop();
            stakingContracts[index] = lastItem;
        }else{
            stakingContracts.pop();
        }

        emit StakingContractRemoved(_stakingContract);
    }

    function getStakingContractIndex(address _stakingContract) private view returns (bool found, uint index){
        uint stakingContractsCount = stakingContracts.length;
        for(uint i = 0; i < stakingContractsCount; i++){
            if(address(stakingContracts[i]) == _stakingContract){
                return (true, i);
            }
        }
        return (false, 0);
    }

    function getStakedBalance(address _holder, address token) public view returns(uint) {
        uint stakedAmount = 0;

        uint stakingContractsCount = stakingContracts.length;
        for(uint i = 0; i < stakingContractsCount; i++){
            stakedAmount += stakingContracts[i].stakedBalance(_holder, address(token));
        }

        return stakedAmount;
    }

}

// File: contracts/VestingStorage.sol

pragma solidity 0.8.4;


contract VestingStorage is Ownable {
    struct VestingCategory{
        uint cliff;
        uint vestingDuration;
    }

    struct Vesting {
        string category;
        uint startingAmount;
    }


    event VestingCategoryAdded(string name);
    event VestingSet(address indexed vester, string categoryName, uint startingAmount);
    event VestingRemoved(address indexed vester, string categoryName, uint startingAmount);


    mapping(string => VestingCategory) private vestingCategoriesByName;
    string[] public vestingCategoryNames;

    mapping(address => Vesting) private vesters;


    modifier onlyVester(address who){
        require(doVestingExist(vesters[who]), "VestingStorage: Only accessible by vesters");
        _;
    }


    function doVestingCategoryExist(VestingCategory storage _category) internal view returns (bool) {
        return _category.vestingDuration > 0;
    }

    function addVestingCategory(string calldata _name, VestingCategory calldata _category) external onlyOwner{
        require(!doVestingCategoryExist(vestingCategoriesByName[_name]), "VestingStorage: Vesting category already exists");
        require(_category.vestingDuration > 0, "VestingStorage: Vesting duration has to be greater than zero");

        vestingCategoryNames.push(_name);
        vestingCategoriesByName[_name] = _category;

        emit VestingCategoryAdded(_name);
    }

    function getVestingCategory(string memory _name) public view returns(VestingCategory memory) {
        VestingCategory storage category = vestingCategoriesByName[_name];
        require(doVestingCategoryExist(category), "VestingStorage: Vesting category does not exist");
        return category;
    }


    function doVestingExist(Vesting storage _vesting) internal view returns (bool) {
        return _vesting.startingAmount > 0;
    }

    function setVestings(address[] calldata _vesters, Vesting[] calldata _vestings) external onlyOwner{
        require(_vesters.length == _vestings.length, "VestingStorage: Vester and vestings amounts don't match up");
        for(uint i = 0; i < _vesters.length; i++){
            address vester = _vesters[i];
            Vesting calldata vesting = _vestings[i];
            require(vesting.startingAmount > 0, "VestingStorage: Vesting should have greater than zero starting amount");
            require(doVestingCategoryExist(vestingCategoriesByName[vesting.category]), "VestingStorage: Vesting category does not exist");

            vesters[vester] = vesting;

            emit VestingSet(vester, vesting.category, vesting.startingAmount);
        }
    }

    function getVesting(address _vester) public view onlyVester(_vester) returns(Vesting memory){
        return vesters[_vester];
    }

    function removeVesting(address[] calldata _vesters) external onlyOwner{
        for(uint i = 0; i < _vesters.length; i++){
            address vester = _vesters[i];
            require(doVestingExist(vesters[vester]), "VestingStorage: Address is not vesting");

            Vesting memory vesting = vesters[vester];
            
            delete vesters[vester];

            emit VestingRemoved(vester, vesting.category, vesting.startingAmount);
        }
    }

}

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



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
         {
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

// File: contracts/RecoverTokens.sol

pragma solidity 0.8.4;




contract RecoverTokens is Ownable {
    using SafeERC20 for IERC20;

    event TokensRecovered(address indexed token, uint amount);

    function recoverTokens(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint balance = token.balanceOf(address(this));
        require(balance != 0, "RecoverTokens: no balance to recover");

        token.safeTransfer(owner(), balance);

        emit TokensRecovered(_tokenAddress, balance);
    }

}

// File: contracts/VestingController.sol

pragma solidity 0.8.4;






contract VestingController is StakedBalanceFetcher, VestingStorage, RecoverTokens {

    event AmountClaimed(address indexed vester, address indexed recipient, uint amount);

    uint immutable public startDate;
    IERC20 immutable public token;

    constructor(uint _vestingStart, address _tokenAddress){
        startDate = _vestingStart;
        token = IERC20(_tokenAddress);
    }

    function claimTo(address _recipient) external onlyVester(msg.sender) {
        uint currentBalance = token.balanceOf(msg.sender);
        require(currentBalance > 0, "VestingController: Not enough balance for claim");

        uint lockedBalance = currentBalance + getStakedBalance(msg.sender, address(token));

        Vesting memory vesting = getVesting(msg.sender);
        uint amountNotVestedYet = vesting.startingAmount - calculateAmountVested(msg.sender);

        require(lockedBalance > amountNotVestedYet, "VestingController: No claimable amount");

        uint claimableAmount = lockedBalance - amountNotVestedYet;
        uint transferableAmount = Math.min(claimableAmount, currentBalance);
        
        // Two step operation since msg.sender has no permission to move tokens other than through address(this)
        require(token.transferFrom(msg.sender, address(this), transferableAmount));
        require(token.transfer(_recipient, transferableAmount));

        emit AmountClaimed(msg.sender, _recipient, transferableAmount);
    }

    function calculateAmountVested(address _vester) public view onlyVester(_vester) returns(uint) {
        Vesting memory vesting = getVesting(_vester);
        VestingCategory memory category = getVestingCategory(vesting.category);

        uint vestingStart = startDate + category.cliff;

        if(block.timestamp <= vestingStart){
            return 0;
        } else {
            uint timePassed = block.timestamp - vestingStart;

            if(timePassed >= category.vestingDuration){
                return vesting.startingAmount;
            } else {
                return (vesting.startingAmount * timePassed) / category.vestingDuration;
            }
        }
    }

}