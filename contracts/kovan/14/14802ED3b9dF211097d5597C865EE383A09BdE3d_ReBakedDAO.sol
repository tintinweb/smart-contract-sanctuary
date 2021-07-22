/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


// 
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

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// 
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

// 
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

interface ITokenFactory {
	function deployToken(uint256 totalSupply_) external returns(address);
}

interface IIOUToken {
	function burn(uint256 amount_) 	external;
}

struct Project {
	address initiator;
	address token;
	bool isOwnToken;
	uint256 budget;
	uint256 budgetAllocated;
	uint256 budgetPaid;
	uint256 budgetObservers;
	uint256 budgetObserversPaid;
	uint256 timeCreated;
	uint256 timeApproved;
	uint256 timeStarted;
	uint256 timeFinished;
	uint256 totalObservers;
	uint256 totalPackages;
	uint256 totalFinishedPackages;
}

library ProjectLibrary {

	using SafeERC20 for IERC20;

	event CreatedProject(bytes32 indexed projectId, address initiator, address token, uint256 budget);
	event AddedObservers(bytes32 indexed projectId, address[] observers);
	event ApprovedProject(bytes32 indexed projectId);
	event StartedProject(bytes32 indexed projectId);
	event FinishedProject(bytes32 indexed projectId);
	event PaidDao(bytes32 indexed projectId, uint256 amount);
	event PaidMgp(bytes32 indexed projectId, bytes32 indexed packageId, address indexed collaborator, uint256 amount);
	event PaidBonus(bytes32 indexed projectId, bytes32 indexed packageId, address indexed collaborator, uint256 amount);
	event PaidObserver(bytes32 indexed projectId, address indexed observer, uint256 amount);

	/**
	@dev Throws if there is no such project
	 */
	modifier onlyExistingProject(Project storage project_) {
		require(project_.timeCreated != 0, "no such project");
		_;
	}

	/**
	 * @dev Throws if project is not started
	 */
	modifier onlyStartedProject(Project storage project_) {
		require(project_.timeStarted != 0, "project is not started");
		_;
	}

	/**
	* @dev Creates project proposal
	* @param project_ reference to Project struct
	* @param token_ project token address
	* @param budget_ total budget
	*/
	function _createProject(
		Project storage project_,
		bytes32 projectId_,
		address token_,
		uint256 budget_
	)
		public
	{
		project_.initiator = msg.sender;
		project_.token = token_;
		project_.isOwnToken = token_ != address(0);
		project_.budget = budget_;
		project_.timeCreated = block.timestamp;
		emit CreatedProject(projectId_, msg.sender, token_, budget_);
	}

	/**
	* @dev Adds observers to project proposal
	* @param project_ reference to Project struct
	* @param projectId_ Id of the project proposal
	* @param observers_ array of observer addresses
	*/
	function addObservers(
		Project storage project_,
		bytes32 projectId_,
		address[] calldata observers_
	)
		public
		onlyExistingProject(project_)
	{
		require(project_.timeApproved == 0, "can't add observers when project is approved");
		project_.totalObservers += observers_.length;
		emit AddedObservers(projectId_, observers_);
	}

	/**
	* @dev Approves project
	* @param project_ reference to Project struct
	* @param projectId_ Id of the project
	*/
	function approveProject(
		Project storage project_,
		bytes32 projectId_
	)
		public
		onlyExistingProject(project_)
	{
		require(!project_.isOwnToken, "project with exsiting token does not require approval");
		_approveProject(project_, projectId_);
	}

	/**
	* @dev Approves project, needed for external approval failure for projects with own tokens
	* @param project_ reference to Project struct
	* @param projectId_ Id of the project
	*/
	function _approveProject(
		Project storage project_,
		bytes32 projectId_
	)
		internal
	{
		require(project_.timeApproved == 0, "already approved project");
		require(project_.totalObservers >= 3, "observers should be 3 or more");
		project_.timeApproved = block.timestamp;
		emit ApprovedProject(projectId_);
	}


	/**
	* @dev Starts project, if project own token auto approve, otherwise deploys IOUToken
	* @param project_ reference to Project struct
	* transfers fee to DAO wallet and reserves fee for observers
	* @param projectId_ Id of the project
	* @param treasury_ address of DAO wallet
	* @param feeDaoAmount_ DAO fee amount
	* @param feeObserversAmount_ Observers fee amount
	* @param tokenFactory_ address of token factory contract
	*/
	function _startProject(
		Project storage project_,
		bytes32 projectId_,
		address treasury_,
		uint256 feeDaoAmount_,
		uint256 feeObserversAmount_,
		address tokenFactory_
	)
		public
		onlyExistingProject(project_)
	{
		require(project_.timeStarted == 0, "project already started");
		if(project_.isOwnToken)
			_approveProject(project_, projectId_);
		require(project_.timeApproved != 0, "project is not approved");
		if(project_.isOwnToken)
			IERC20(project_.token).safeTransferFrom(msg.sender, address(this), project_.budget);
		else
			project_.token = ITokenFactory(tokenFactory_).deployToken(project_.budget);
		project_.budgetAllocated = feeDaoAmount_ + feeObserversAmount_;
		project_.budgetObservers = feeObserversAmount_;
		IERC20(project_.token).safeTransfer(treasury_, feeDaoAmount_);
		project_.budgetPaid = feeDaoAmount_;
		project_.timeStarted = block.timestamp;
		emit StartedProject(projectId_);
		emit PaidDao(projectId_, feeDaoAmount_);
	}

	/**
	* @dev Finishes project, checks if already finished or unfinished packages left
	* unallocated budget returned to initiator or burned (in case of IOUToken)
	* @param project_ reference to Project struct
	* @param projectId_ Id of the project
	*/
	function finishProject(
		Project storage project_,
		bytes32 projectId_
	)
		public
		onlyExistingProject(project_)
	{
		require(project_.timeFinished == 0, "already finished project");
		require(project_.totalPackages == project_.totalFinishedPackages, "unfinished packages left in project");
		project_.timeFinished = block.timestamp;
		uint256 budgetLeft_ = project_.budget - project_.budgetAllocated;
		if(project_.timeStarted != 0 && budgetLeft_ != 0){
			if(project_.isOwnToken)
				IERC20(project_.token).safeTransfer(project_.initiator, budgetLeft_);
			else
				IIOUToken(address(project_.token)).burn(budgetLeft_);
		}
		emit FinishedProject(projectId_);
	}

	/**
	* @dev Creates package in project, check if there is budget available
	* allocates budget and increase total number of packages
	* @param project_ reference to Project struct
	* @param budget_ MGP budget 
	* @param bonus_ Bonus budget 
	*/
	function _createPackage(
		Project storage project_,
		uint256 budget_,
		uint256 bonus_
	)
		public
		onlyExistingProject(project_)
		onlyStartedProject(project_)
	{
		uint256 _projectBudgetAvaiable = project_.budget - project_.budgetAllocated;
		uint256 _totalPackageBudget = budget_ + bonus_;
		require(_projectBudgetAvaiable >= _totalPackageBudget, "not enough project budget left");
		project_.budgetAllocated += _totalPackageBudget;
		project_.totalPackages++;
	}

	/**
	* @dev Fihishes package in project, budget left addded refunded back to project budget
	* increases total number of finished packages
	* @param project_ reference to Project struct
	* @param budgetLeft_ amount of budget left
	*/
	function finishPackage(
		Project storage project_,
		uint256 budgetLeft_
	)
		public
		onlyExistingProject(project_)
	{
		if(budgetLeft_ != 0)
			project_.budgetAllocated -= budgetLeft_;
		project_.totalFinishedPackages++;
	}

	/**
	* @dev Sends approved MGP to collaborator, increases project budget paid
	* @param project_ reference to Project struct
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package   
	* @param amount_ mgp amount  
	*/
	function _getMgp(
		Project storage project_,
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 amount_
	)
		public
		onlyExistingProject(project_)
	{ 
		IERC20(project_.token).safeTransfer(msg.sender, amount_);
		project_.budgetPaid += amount_;
		emit PaidMgp(projectId_, packageId_, msg.sender, amount_);
	}

	/**
	* @dev Sends approved Bonus to collaborator, increases projec budget paid
	* @param project_ reference to Project struct
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param amount_ bonus amount     
	*/
	function _getBonus(
		Project storage project_,
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 amount_
	)
		public
		onlyExistingProject(project_)
	{
		IERC20(project_.token).safeTransfer(msg.sender, amount_);
		project_.budgetPaid += amount_;
		emit PaidBonus(projectId_, packageId_, msg.sender, amount_);
	}

	/**
	* @dev Sends observer fee after project is finished, increses project budget and observers' budget paid
	* @param project_ reference to Project struct
	* @param projectId_ Id of the project  
	*/
	function getObserverFee(
		Project storage project_,
		bytes32 projectId_
	)
		public
		onlyExistingProject(project_)
	{
		require(project_.timeFinished != 0, "project is not finished");
		uint256 _amount = project_.budgetObservers / project_.totalObservers;
		IERC20(project_.token).safeTransfer(msg.sender, _amount);
		project_.budgetPaid += _amount;
		project_.budgetObserversPaid += _amount;
		emit PaidObserver(projectId_, msg.sender, _amount);
	}

}

struct Package {
	uint256 budget;
	uint256 budgetAllocated;
	uint256 budgetPaid;
	uint256 bonus;
	uint256 bonusAllocated;
	uint256 bonusPaid;
	uint256 timeCreated;
	uint256 timeFinished;
	uint256 totalCollaborators;
	uint256 approvedCollaborators;
}

library PackageLibrary {

	event CreatedPackage(bytes32 indexed projectId, bytes32 indexed packageId, uint256 budget, uint256 bonus);
	event FinishedPackage(bytes32 indexed projectId, bytes32 indexed packageId);

	/**
	@dev Throws if there is no package
	 */
	modifier onlyExistingPackage(Package storage package_) {
		require(package_.timeCreated != 0, "no such package");
		_;
	}

	/**
	* @dev Creates package in project
	* @param package_ reference to Package struct
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param budget_ MGP budget 
	* @param bonus_ Bonus budget 
	*/
	function _createPackage(
		Package storage package_,
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 budget_,
		uint256 bonus_
	)
		public
	{
		package_.budget = budget_;
		package_.bonus = bonus_;
		package_.timeCreated = block.timestamp;
		emit CreatedPackage(projectId_, packageId_, budget_, bonus_);
	}

	/**
	* @dev Adds collaborator to package, checks if there is budget available and allocates it  
	* @param package_ reference to Package struct
	* @param mgp_ minmal garanteed payment
	*/
	function addCollaborator(
		Package storage package_,
		uint256 mgp_
	)
		public
		onlyExistingPackage(package_)
	{
		require(package_.timeFinished == 0, "already finished package");
		require(
			package_.budget - package_.budgetAllocated >= mgp_, 
			"not enough package budget left"
		);
		package_.budgetAllocated += mgp_;
		package_.totalCollaborators++;
	}

	/**
	* @dev Refund package budget and decreace total collaborators if not approved
	* @param package_ reference to Package struct
	* @param approve_ whether to approve or not collaborator payment 
	* @param mgp_ MGP amount
	*/
	function approveCollaborator(
		Package storage package_,
		bool approve_,
		uint256 mgp_
	)
		public
		onlyExistingPackage(package_)
	{
		if(!approve_){
			package_.budgetAllocated -= mgp_;
			package_.totalCollaborators--;
		}else{
			package_.approvedCollaborators++;
		}
	}

	/**
	* @dev Fihishes package in project, checks if already finished, records time
	* if budget left and there is no collaborators, bonus is refunded to package budget
	* @param package_ reference to Package struct
	* @param projectId_ Id of the project 
	*/
	function finishPackage(
		Package storage package_,
		bytes32 projectId_,
		bytes32 packageId_
	)
		public
		onlyExistingPackage(package_)
		returns(uint256 budgetLeft_)
	{
		require(package_.timeFinished == 0, "already finished package");
		require(package_.totalCollaborators == package_.approvedCollaborators, "unapproved collaborators left");
		budgetLeft_ = package_.budget - package_.budgetAllocated;
		if(budgetLeft_ != 0)
			package_.budget = package_.budgetAllocated;
		if(package_.totalCollaborators == 0){
			budgetLeft_ += package_.bonus;
			package_.bonus = 0;
		}
		package_.timeFinished = block.timestamp;
		emit FinishedPackage(projectId_, packageId_);
	}

	/**
	* @dev Sets scores for collaborator bonuses 
	* @param package_ reference to Package struct
	* @param package_ reference to Package struct
	* @param totalBonusScores_ total sum of bonus scores
	* @param maxBonusScores_ max bonus scores (PPM)
	*/
	function _setBonusScores(
		Package storage package_,
		uint256 totalBonusScores_,
		uint256 maxBonusScores_
	)
		public
		onlyExistingPackage(package_)
	{
		require(package_.bonus != 0, "bonus budget is zero");
		require(package_.timeFinished != 0, "package is not finished");
		require(package_.bonusAllocated + totalBonusScores_ <= maxBonusScores_, "no more bonus left");
		package_.bonusAllocated += totalBonusScores_;
	}

	/**
	* @dev Increases package budget paid
	* @param package_ reference to Package struct
	* @param amount_ MGP amount
	*/
	function _getMgp(
		Package storage package_,
		uint256 amount_
	)
		public
		onlyExistingPackage(package_)
	{	
		package_.budgetPaid += amount_;
	}

	/**
	* @dev Increases package bonus paid
	* @param package_ reference to Package struct
	* @param amount_ Bonus amount
	*/
	function _getBonus(
		Package storage package_,
		uint256 amount_
	)
		public
		onlyExistingPackage(package_)
	{
		require(package_.timeFinished != 0, "package not finished");
		require(package_.bonus != 0, "package has no bonus");
		package_.bonusPaid += amount_;
	}

}

struct Collaborator {
	uint256 mgp;
	uint256 timeMgpApproved;
	uint256 timeMgpPaid;
	uint256 timeBonusPaid;
	uint256 bonusScore;
}

library CollaboratorLibrary {

	event AddedCollaborator(
		bytes32 indexed projectId, bytes32 indexed packageId, address indexed collaborator, uint256 mgp
	);
	event ApprovedCollaborator(bytes32 indexed projectId, bytes32 indexed packageId, address indexed collaborator);
	event RemovedCollaborator(bytes32 indexed projectId, bytes32 indexed packageId, address indexed collaborator);

	/**
	@dev Throws if there is no such collaborator
	*/
	modifier onlyExistingCollaborator(Collaborator storage collaborator_) {
		require(collaborator_.mgp != 0, "no such collaborator");
		_;
	}

	/**
	* @dev Adds collaborator, checks for zero address and if already added, records mgp 
	* @param collaborator_ reference to Collaborator struct
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address  
	* @param mgp_ minmal garanteed payment
	*/
	function addCollaborator(
		Collaborator storage collaborator_,
		bytes32 projectId_,
		bytes32 packageId_,
		address collaboratorAddress_,
		uint256 mgp_
	)
		public
	{
		require(collaborator_.mgp == 0, "collaborator already added");
		require(collaboratorAddress_ != address(0), "collaborator's address is zero");
		collaborator_.mgp = mgp_;
		emit AddedCollaborator(projectId_, packageId_, collaboratorAddress_, mgp_);
	}

	/**
	* @dev Approves collaborator's MPG or deletes collaborator 
	* @param collaborator_ reference to Collaborator struct
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address 
	* @param approve_ whether to approve or not collaborator payment  
	*/
	function approveCollaborator(
		Collaborator storage collaborator_,
		bytes32 projectId_,
		bytes32 packageId_,
		address collaboratorAddress_,
		bool approve_
	)
		public
		onlyExistingCollaborator(collaborator_)
	{
		require(collaborator_.timeMgpApproved == 0, "already approved collaborator mgp");
		if(approve_){
			collaborator_.timeMgpApproved = block.timestamp;
			emit ApprovedCollaborator(projectId_, packageId_, collaboratorAddress_);
		}else{
			emit RemovedCollaborator(projectId_, packageId_, collaboratorAddress_);
		}
	}

	/**
	* @dev Sets scores for collaborator bonuses 
	* @param collaborator_ reference to Collaborator struct
	* @param bonusScore_ collaborator's bonus score
	*/
	function _setBonusScore(
		Collaborator storage collaborator_,
		uint256 bonusScore_
	)
		public
		onlyExistingCollaborator(collaborator_)
	{
		collaborator_.bonusScore = bonusScore_;
	}

	/**
	* @dev Sets MGP time paid flag, checks if approved and already paid
	* @param collaborator_ reference to Collaborator struct
	*/
	function getMgp(
		Collaborator storage collaborator_
	)
		public
		onlyExistingCollaborator(collaborator_)
	{
		require(collaborator_.timeMgpApproved != 0, "mgp is not approved");
		require(collaborator_.timeMgpPaid == 0, "mgp already paid");
		collaborator_.timeMgpPaid = block.timestamp;
	}

	/**
	* @dev Sets Bonus time paid flag, checks is approved and already paid
	* @param collaborator_ reference to Collaborator struct
	*/
	function getBonus(
		Collaborator storage collaborator_
	)
		public
		onlyExistingCollaborator(collaborator_)
	{
		require(collaborator_.timeBonusPaid == 0, "bonus already paid");
		collaborator_.timeBonusPaid = block.timestamp;
	}

}

contract Collaborators {
	
	using CollaboratorLibrary for Collaborator;

	mapping (bytes32 => mapping(bytes32 => mapping(address => Collaborator))) internal collaboratorData;

	/**
	* @dev Adds collaborator
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address  
	* @param mgp_ minimal garanteed payment
	*/
	function addCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		uint256 mgp_
	)
		public
		virtual
	{
		 collaboratorData[projectId_][packageId_][collaborator_].addCollaborator(
		 	projectId_, packageId_, collaborator_, mgp_);
	}

	/**
	* @dev Approves collaborator's MPG or deletes collaborator 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address 
	* @param approve_ whether to approve or not collaborator payment  
	*/
	function approveCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		bool approve_
	)
		public
		virtual
		returns(uint256 mgp_)
	{
		mgp_ = collaboratorData[projectId_][packageId_][collaborator_].mgp; 
		collaboratorData[projectId_][packageId_][collaborator_].approveCollaborator(
			projectId_, packageId_, collaborator_, approve_);
		if(!approve_)
			delete collaboratorData[projectId_][packageId_][collaborator_];
	}

	/**
	* @dev Sets scores for collaborator bonuses 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address 
	* @param bonusScore_ collaborator's bonus score
	*/
	function _setBonusScore(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		uint256 bonusScore_
	)
		internal
	{
		collaboratorData[projectId_][packageId_][collaborator_]._setBonusScore(bonusScore_);
	}

	/**
	* @dev Sets MGP time paid flag
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	*/
	function getMgp(
		bytes32 projectId_,
		bytes32 packageId_
	)
		public
		virtual
	{
		collaboratorData[projectId_][packageId_][msg.sender].getMgp();
	}

	/**
	* @dev Sets Bonus time paid flag
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	*/
	function getBonus(
		bytes32 projectId_,
		bytes32 packageId_
	)
		public
		virtual
	{
		collaboratorData[projectId_][packageId_][msg.sender].getBonus();
	}

	/**
	* @dev Returns collaborator data for given project id, package id and address.
	* @param projectId_ project ID
	* @param packageId_ package ID
	* @param collaborator_ collaborator's address 
	* @return collaboratorData_
	*/
	function getCollaboratorData(bytes32 projectId_, bytes32 packageId_, address collaborator_)
		external
		view
		returns(Collaborator memory)
	{
		return collaboratorData[projectId_][packageId_][collaborator_];
	}

}

contract Packages is Collaborators {
	
	using PackageLibrary for Package;

	mapping (bytes32 => mapping(bytes32 => Package)) internal packageData;

	/**
	* @dev Creates package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param budget_ MGP budget 
	* @param bonus_ Bonus budget 
	*/
	function _createPackage(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 budget_,
		uint256 bonus_
	)
		internal
		virtual
	{
		packageData[projectId_][packageId_]._createPackage(projectId_, packageId_, budget_, bonus_);
	}

	/**
	* @dev Adds collaborator to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address  
	* @param mgp_ minmal garanteed payment
	*/
	function addCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		uint256 mgp_
	)
		public
		virtual
		override
	{
		packageData[projectId_][packageId_].addCollaborator(mgp_);
		super.addCollaborator(projectId_, packageId_, collaborator_, mgp_);
	}

	/**
	* @dev Refund package budget and decreace total collaborators if not approved
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param collaborator_ address of collaborator
	* @param approve_ - whether to approve or not collaborator payment 
	*/
	function approveCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		bool approve_
	)
		public
		virtual
		override
		returns(uint256 mgp_)
	{
		mgp_ = super.approveCollaborator(projectId_, packageId_, collaborator_, approve_);
		packageData[projectId_][packageId_].approveCollaborator(approve_, mgp_);
	}

	/**
	* @dev Fihishes package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	*/
	function finishPackage(
		bytes32 projectId_,
		bytes32 packageId_
	)
		public
		virtual
		returns(uint256)
	{
		return packageData[projectId_][packageId_].finishPackage(projectId_, packageId_);
	}

	/**
	* @dev Sets allocated bonuses
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param totalBonusScores_ total sum of bonus scores
	* @param maxBonusScores_ max bonus scores (PPM)
	*/
	function _setBonusScores(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 totalBonusScores_,
		uint256 maxBonusScores_
	)
		internal
	{
		packageData[projectId_][packageId_]._setBonusScores(totalBonusScores_, maxBonusScores_);
	}

	/**
	* @dev Increases package budget paid
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param amount_ mgp amount   
	*/
	function _getMgp(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 amount_
	)
		internal
		virtual
	{	
		packageData[projectId_][packageId_]._getMgp(amount_);
	}

	/**
	* @dev Increases package bonus paid
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param amount_ bonus amount   
	*/
	function _getBonus(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 amount_
	)
		internal
		virtual
	{ 
		packageData[projectId_][packageId_]._getBonus(amount_);
	}

	/**
	* @dev Returns package data for given project id and package id.
	* @param projectId_ project ID
	* @param packageId_ package ID
	* @return packageData_
	*/
	function getPackageData(bytes32 projectId_, bytes32 packageId_)
		external
		view
		returns(Package memory)
	{
		return packageData[projectId_][packageId_];
	}

}

struct Observer {
	uint256 timeCreated;
	uint256 timePaid;
}

contract Observers {

	mapping (bytes32 => mapping(address => Observer)) internal observerData;

	/**
	* @dev Checks if observer can be added and records time
	* @param projectId_ Id of the project proposal
	* @param observer_ observer addresses
	*/
	function addObserver(
		bytes32 projectId_,
		address observer_
	)
		internal
	{
		require(observer_ != address(0), "observer address is zero");
		Observer storage _observer = observerData[projectId_][observer_];
		require(_observer.timeCreated == 0, "observer already added");
		_observer.timeCreated = block.timestamp;
	}

	/**
	* @dev Checks if observer can be paid and records time
	* @param projectId_ Id of the project  
	*/
	function getObserverFee(
		bytes32 projectId_
	)
		public
		virtual
	{
		Observer storage _observer = observerData[projectId_][msg.sender];
		require(_observer.timeCreated != 0, "no such observer");
		require(_observer.timePaid == 0, "observer already paid");
		_observer.timePaid = block.timestamp;
	}

	/**
	* @dev Returns observer data for project id and address.
	* @param projectId_ project ID
	* @param observer_ observer's address
	* @return observerData_
	*/
	function getObserverData(bytes32 projectId_, address observer_)
		external
		view
		returns(Observer memory)
	{
		return observerData[projectId_][observer_];
	}

}

contract Projects is Packages, Observers {
	
	using ProjectLibrary for Project;

	mapping (bytes32 => Project) internal projectData;

	/**
	* @dev Creates project proposal
	* @param token_ project token address
	* @param budget_ total budget
	*/
	function _createProject(
		bytes32 projectId_,
		address token_,
		uint256 budget_
	)
		internal
	{
		projectData[projectId_]._createProject(projectId_, token_, budget_);
	}

	/**
	* @dev Adds observers to project proposal
	* @param projectId_ Id of the project proposal
	* @param observers_ array of observer addresses
	*/
	function addObservers(
		bytes32 projectId_,
		address[] calldata observers_
	)
		public
		virtual
	{
		projectData[projectId_].addObservers(projectId_, observers_);
		for(uint256 i = 0; i < observers_.length; i++)
			addObserver(projectId_, observers_[i]);
	}

	/**
	* @dev Approves project
	* @param projectId_ Id of the project
	*/
	function approveProject(
		bytes32 projectId_
	)
		public
		virtual
	{
		projectData[projectId_].approveProject(projectId_);
	}

	/**
	* @dev Starts project
	*/
	function _startProject(
		bytes32 projectId_,
		address treasury_,
		uint256 feeDaoAmount_,
		uint256 feeObserversAmount_,
		address tokenFactory_
	)
		internal
	{
		projectData[projectId_]._startProject(projectId_, treasury_, feeDaoAmount_, feeObserversAmount_, tokenFactory_);
	}

	/**
	* @dev Finishes project
	* @param projectId_ Id of the project
	*/
	function finishProject(
		bytes32 projectId_
	)
		public
		virtual
	{
		projectData[projectId_].finishProject(projectId_);
	}

	/**
	* @dev Creates package in project and allocates budget for it
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param budget_ MGP budget 
	* @param bonus_ Bonus budget 
	*/
	function _createPackage(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 budget_,
		uint256 bonus_
	)
		internal
		virtual
		override
	{
		projectData[projectId_]._createPackage(budget_, bonus_);
		super._createPackage(projectId_, packageId_, budget_, bonus_);
	}

	/**
	* @dev Fihishes package in project
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	*/
	function finishPackage(
		bytes32 projectId_,
		bytes32 packageId_
	)
		public
		virtual
		override
		returns(uint256 budgetLeft_)
	{
		budgetLeft_ = super.finishPackage(projectId_, packageId_);
		projectData[projectId_].finishPackage(budgetLeft_);
	}

	/**
	* @dev Sends MGP to collaborator and adds amount to budgetPaid
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param amount_ mgp amount   
	*/
	function _getMgp(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 amount_
	)
		internal
		override
	{
		super._getMgp(projectId_, packageId_, amount_);
		projectData[projectId_]._getMgp(projectId_, packageId_, amount_);
	}

	/**
	* @dev Sends Bonus to collaborator and adds amount to budgetPaid
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param amount_ bonus amount   
	*/
	function _getBonus(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 amount_
	)
		internal
		override
	{
		super._getBonus(projectId_, packageId_, amount_);
		projectData[projectId_]._getBonus(projectId_, packageId_, amount_);
	}

	/**
	* @dev Sends observer fee after project is finished
	* @param projectId_ Id of the project  
	*/
	function getObserverFee(
		bytes32 projectId_
	)
		public
		virtual
		override
	{
		super.getObserverFee(projectId_);
		projectData[projectId_].getObserverFee(projectId_);
	}

	/**
	* @dev Returns project data for given project id.
	* @param projectId_ project ID
	* @return projectData_
	*/
	function getProjectData(bytes32 projectId_)
		external
		view
		returns(Project memory)
	{
		return projectData[projectId_];
	}


}

// 
contract ReBakedDAO is Ownable, ReentrancyGuard, Projects {

	// Rebaked DAO wallet
	address public treasury;
	// Percent Precision PPM (parts per million)
	uint256 constant public PCT_PRECISION = 1e6;
	// Fee for DAO for new projects
	uint256 public feeDao;
	// Fee for Observers for new projects
	uint256 public feeObservers;
	// Token Factory contract address
	address public tokenFactory;
	
	event ChangedFees(uint256 feeDao, uint256 feeObservers);

	constructor (
		address treasury_,
		uint256 feeDao_,
		uint256 feeObservers_,
		address tokenFactory_
	)
	{
		treasury = treasury_;
		changeFees(feeDao_, feeObservers_);
		tokenFactory = tokenFactory_;
	}

	/**
	 * @dev Throws if amount provided is zero
	 */
	modifier onlyAmountGreaterThanZero(uint256 amount_) {
		require(amount_ != 0, "amount must be greater than 0");
		_;
	}

	/**
	 * @dev Throws if called by any account other than the project initiator
	 */
	modifier onlyInitiator(bytes32 projectId_) {
		require(projectData[projectId_].initiator == msg.sender, "caller is not the project initiator");
		_;
	}

	/***************************************
					PRIVATE
	****************************************/
	/**
	* @dev Generates unique id hash based on msg.sender address and previous block hash. 
	* @return Id
	*/
	function _generateId()
		private
		view
		returns(bytes32)
	{
		return keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1)));
	}

	/**
	* @dev Returns a new unique project id. 
	* @return projectId_ Id of the project.
	*/
	function _generateProjectId()
		private
		view
		returns(bytes32 projectId_)
	{
		projectId_ = _generateId();
		require(projectData[projectId_].timeCreated == 0, "duplicate project id");
	}

	/**
	* @dev Returns a new unique package id. 
	* @param projectId_ Id of the project
	* @return packageId_ Id of the package
	*/
	function _generatePackageId(bytes32 projectId_)
		private
		view
		returns(bytes32 packageId_)
	{
		packageId_ = _generateId();
		require(packageData[projectId_][packageId_].timeCreated == 0, "duplicate package id");
	}

	/***************************************
					ADMIN
	****************************************/
	
	/**
	 * @dev Sets new fees
	 * @param feeDao_ DAO fee in ppm
	 * @param feeObservers_ Observers fee in ppm
	 */
	function changeFees (
		uint256 feeDao_,
		uint256 feeObservers_
	)
		public
		onlyOwner
	{
		feeDao = feeDao_;
		feeObservers = feeObservers_;
		emit ChangedFees(feeDao_, feeObservers_);
	}

	/**
	* @dev Approves project
	* @param projectId_ Id of the project
	*/
	function approveProject(
		bytes32 projectId_
	)
		public
		override
		onlyOwner
	{
		super.approveProject(projectId_);
	}

	/**
	* @dev Approves collaborator's MPG or deletes collaborator 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address
	* @param approve_ - whether to approve or not collaborator payment 
	* @return uint256 mgp amount approved or refunded to package budget  
	*/
	function approveCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		bool approve_
	)
		public
		override
		onlyOwner
		returns(uint256)
	{
		return super.approveCollaborator(projectId_, packageId_, collaborator_, approve_);
	}

	/**
	* @dev Sets scores for collaborator bonuses 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborators_ array of collaborators' addresses
	* @param scores_ array of collaboratos' scores in PPM
	*/
	function setBonusScores(
		bytes32 projectId_,
		bytes32 packageId_,
		address[] calldata collaborators_,
		uint256[] calldata scores_
	)
		public
		onlyOwner
	{
		require(collaborators_.length == scores_.length, "collaborators' and scores' length are not the same");
		require(collaborators_.length > 0, "zero length collaborators array");
		uint256 _totalBonusScores;
		for(uint256 i = 0; i < collaborators_.length; i++){
			_setBonusScore(projectId_, packageId_, collaborators_[i], scores_[i]);
			_totalBonusScores += scores_[i];
		}
		_setBonusScores(projectId_, packageId_, _totalBonusScores, PCT_PRECISION);
	}

	/**
	* @dev Finishes project
	* @param projectId_ Id of the project
	*/
	function finishProject(
		bytes32 projectId_
	)
		public
		override
		onlyOwner
	{
		super.finishProject(projectId_);
	}

	/***************************************
			PROJECT INITIATOR ACTIONS
	****************************************/

	/**
	* @dev Creates project proposal
	* @param token_ project token address, zero addres if project has not token yet 
	* (IOUT will be deployed on project approval) 
	* @param budget_ total budget (has to be approved on token contract if project has its own token)
	* @return projectId_ Id of the project proposal created
	*/
	function createProject(
		address token_,
		uint256 budget_
	)
		external
		onlyAmountGreaterThanZero(budget_)
		returns(bytes32 projectId_)
	{
		projectId_ = _generateProjectId();
		_createProject(projectId_, token_, budget_);
	}

	/**
	* @dev Adds observers to project proposal
	* @param projectId_ Id of the project proposal
	* @param observers_ array of observer addresses
	*/
	function addObservers(
		bytes32 projectId_,
		address[] calldata observers_
	)
		public
		override
		onlyInitiator(projectId_)
	{
		require(observers_.length > 0, "zero length observers array");
		super.addObservers(projectId_, observers_);
	}

	/**
	* @dev Starts project
	* @param projectId_ Id of the project
	*/
	function startProject(
		bytes32 projectId_
	)
		external
		onlyInitiator(projectId_)
	{
		_startProject(
			projectId_, 
			treasury, 
			projectData[projectId_].budget * feeDao / PCT_PRECISION, 
			projectData[projectId_].budget * feeObservers / PCT_PRECISION, 
			tokenFactory)
		;
	}

	/**
	* @dev Creates package in project
	* @param projectId_ Id of the project
	* @param budget_ MGP budget 
	* @param bonus_ Bonus budget 
	* @return packageId_ Id of the package created
	*/
	function createPackage(
		bytes32 projectId_,
		uint256 budget_,
		uint256 bonus_
	)
		external
		onlyInitiator(projectId_)
		onlyAmountGreaterThanZero(budget_)
		returns(bytes32 packageId_)
	{
		packageId_ = _generatePackageId(projectId_);
		_createPackage(projectId_, packageId_, budget_, bonus_);
	}

	/**
	* @dev Adds collaborator to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address  
	* @param mgp_ minmal garanteed payment
	*/
	function addCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		uint256 mgp_
	)
		public
		override
		onlyInitiator(projectId_)
		onlyAmountGreaterThanZero(mgp_)
	{
		super.addCollaborator(projectId_, packageId_, collaborator_, mgp_);
	}

	/**
	* @dev Fihishes package in project
	* @param projectId_ Id of the project 
	*/
	function finishPackage(
		bytes32 projectId_,
		bytes32 packageId_
	)
		public
		override
		onlyInitiator(projectId_)
		returns(uint256)
	{
		return super.finishPackage(projectId_, packageId_);
	}
	
	/***************************************
			COLLABORATOR ACTIONS
	****************************************/

	/**
	* @dev Sends approved MGP to collaborator, should be called from collaborator's address
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package   
	*/
	function getMgp(
		bytes32 projectId_,
		bytes32 packageId_
	)
		public
		override
		nonReentrant
	{
		super.getMgp(projectId_, packageId_);
		_getMgp(projectId_, packageId_, collaboratorData[projectId_][packageId_][msg.sender].mgp);
	}

	/**
	* @dev Sends approved Bonus to collaborator, should be called from collaborator's address
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package   
	*/
	function getBonus(
		bytes32 projectId_,
		bytes32 packageId_
	)
		public
		override
		nonReentrant
	{
		uint256 _amount = 
			packageData[projectId_][packageId_].bonus * 
			collaboratorData[projectId_][packageId_][msg.sender].bonusScore / 
			PCT_PRECISION;
		_getBonus(projectId_, packageId_, _amount);
		super.getBonus(projectId_, packageId_);
	}

	/***************************************
			OBSERVER ACTIONS
	****************************************/

	/**
	* @dev Sends observer fee after project is finished, should be called from observer's address
	* @param projectId_ Id of the project  
	*/
	function getObserverFee(
		bytes32 projectId_
	)
		public
		override
		nonReentrant
	{
		super.getObserverFee(projectId_);
	}

}