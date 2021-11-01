/**
 *Submitted for verification at polygonscan.com on 2021-11-01
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: newo.sol



pragma solidity 0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IXVMCgovernor {
    function costToVote() external returns (uint256);
    function maximumVoteTokens() external returns (uint256);
    function delayBeforeEnforce() external returns (uint256);
    function eventFibonacceningActive() external returns (bool);
    
    function fibonacciDelayed() external returns (bool);
    function delayFibonacci(bool _arg) external;
    function changeGovernorEnforced() external returns (bool);
    function eligibleNewGovernor() external returns (address);
    function changeGovernorActivated() external returns (bool);
    function setNewGovernor(address beneficiary) external;
    function executeWithdraw(uint256 withdrawID) external;
    function treasuryRequest(address _tokenAddr, address _recipient, uint256 _amountToSend) external;
    function newGovernorRequestBlock() external returns (uint256);
    function enforceGovernor() external;
}

interface IMasterChef {
    function XVMCPerBlock() external returns (uint256);
}

interface IacPool {
    function totalShares() external returns (uint256);
    function totalVotesFor(uint256 proposalID) external returns (uint256);
}

contract XVMCconsensus is Ownable {
    using SafeERC20 for IERC20;
	
	struct HaltFibonacci {
		bool valid;
		bool enforced;
		uint256 consensusVoteID;
		uint256 startTimestamp;
		uint256 delayInSeconds;
	}
    struct TreasuryTransfer {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
		address tokenAddress;
        address beneficiary;
		uint256 amountToSend;
		uint256 consensusProposalID;
    }
	struct ConsensusVote {
        uint16 typeOfChange; // 0 == governor change, 1 == treasury transfer, 2 == halt fibonaccening
        address beneficiaryAddress; 
    }
	struct GovernorInvalidated {
        bool isInvalidated; 
        bool hasPassed;
    }

	HaltFibonacci[] public haltProposal;
	TreasuryTransfer[] public treasuryProposal;
	ConsensusVote[] public consensusProposal;
	
	uint256 public immutable goldenRatio = 1618; //1.618 is the golden ratio
    address public immutable token = 0x6d0c966c8A09e354Df9C48b446A474CE3343D912; //XVMC token
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    //masterchef address
    address public immutable masterchef = 0x9BD741F077241b594EBdD745945B577d59C8768e;
	
    //addresses for time-locked deposits(autocompounding pools)
    address public immutable acPool1 = 0x9b6ae196A358Ea81c305D8A32018a4F4C90FC207;
    address public immutable acPool2 = 0x38d2503d751F35c2671cdae6E9011e7Be5CdF174;
    address public immutable acPool3 = 0x418E16d46c66435E72aC646A7bC2a0c286349C55;
    address public immutable acPool4 = 0x321521b99Dbb21705259eA3d84a1d83c37C98D0A;
    address public immutable acPool5 = 0x984981089d06A514AB54Bc3562850aFc75620e26;
    address public immutable acPool6 = 0xfD08FA4a344D147DCcE4f29D258B9F4ae18e6ee0;
    
    mapping(address => GovernorInvalidated) public isGovInvalidated;
    
	constructor() {
            consensusProposal.push(ConsensusVote(0, address(this))); //vote to 0 by default
    }
    
	
	event ProposalAgainstCommonEnemy(uint256 HaltID, uint256 consensusProposalID, uint256 startTimestamp, uint256 delayInSeconds, address indexed enforcer);
	event EnforceDelay(uint256 consensusProposalID, address indexed enforcer);
	event RemoveDelay(uint256 consensusProposalID, address indexed enforcer);
	
	event TreasuryProposal(uint256 proposalID, uint256 sacrificedTokens, address tokenAddress, address recipient, uint256 amount, uint256 consensusVoteID, address indexed enforcer);
	event TreasuryProposalVeto(uint256 proposalID, address indexed enforcer);
	event TreasuryProposalRequested(uint256 proposalID, address indexed enforcer);
    
    event ProposeGovernor(uint256 proposalID, address newGovernor, address indexed enforcer);
    event ChangeGovernor(uint256 proposalID, address indexed enforcer);
    
    modifier whenReady() {
      require(block.timestamp > 1637147532, "after 17 Nov");
      _;
    }
	
	/*
	* If XVMC is to be listed on margin trading exchanges
	* As a lot of supply is printed during Fibonaccening events
	* It could provide "free revenue" for traders shorting XVMC
	* This is a mechanism meant to give XVMC holders an opportunity
	* to unite against the common enemy(shorters).
	* The function effectively delays the fibonaccening event
	* XVMC is smarter, makes the enemies pay for their sins
	* Requires atleast 25% votes, with less than 50% voting against
	*/
	function uniteAgainstTheCommonEnemy(uint256 startTimestamp, uint256 delayInSeconds) external whenReady {
		require(startTimestamp > (block.timestamp + 3600) && delayInSeconds < 72 * 3600);
		
		IERC20(token).safeTransferFrom(msg.sender, owner(), IXVMCgovernor(owner()).costToVote());
		
		consensusProposal.push(
		    ConsensusVote(2, address(this))
		    ); // vote for
    	consensusProposal.push(
    	    ConsensusVote(2, address(this))
    	    ); // vote against
		
		 haltProposal.push(
    	    HaltFibonacci(true, false, consensusProposal.length - 2, startTimestamp, delayInSeconds)
    	   );  
	
        emit ProposalAgainstCommonEnemy(haltProposal.length - 1, consensusProposal.length - 2, startTimestamp, delayInSeconds, msg.sender);
	}
    function enforceDelay(uint256 fibonacciHaltID) external whenReady {
		require(haltProposal[fibonacciHaltID].valid && !haltProposal[fibonacciHaltID].enforced &&
		    haltProposal[fibonacciHaltID].startTimestamp < block.timestamp &&
		    block.timestamp < haltProposal[fibonacciHaltID].startTimestamp + haltProposal[fibonacciHaltID].delayInSeconds);
		uint256 consensusID = haltProposal[fibonacciHaltID].consensusVoteID;
		require(
			consensusProposal[consensusID].typeOfChange == 2,
				"Incorrect proposal type"
			);

		 require(
            IacPool(acPool6).totalVotesFor(consensusID) >= IacPool(acPool6).totalShares() * 20 / 100,
				"No consensus in Pool 6"
        );
        require(
            IacPool(acPool5).totalVotesFor(consensusID) >= IacPool(acPool5).totalShares() * 20 / 100,
				"No consensus in Pool 5"
        );
        require(
            IacPool(acPool4).totalVotesFor(consensusID) >= IacPool(acPool4).totalShares() * 20 / 100,
				"No consensus in Pool 4"
        );
		
		
        require(
            IacPool(acPool6).totalVotesFor(consensusID + 1) <= IacPool(acPool6).totalVotesFor(consensusID) / 2,
				"No consensus in Pool 6"
        );
        require(
            IacPool(acPool5).totalVotesFor(consensusID + 1) <= IacPool(acPool5).totalVotesFor(consensusID) / 2,
				"No consensus in Pool 5"
        );
        require(
            IacPool(acPool4).totalVotesFor(consensusID + 1) <= IacPool(acPool4).totalVotesFor(consensusID) / 2,
				"No consensus in Pool 4"
        );
		
		haltProposal[fibonacciHaltID].enforced = true;
		IXVMCgovernor(owner()).delayFibonacci(true);
		
		emit EnforceDelay(consensusID, msg.sender);
	}
	function removeDelay(uint256 haltProposalID) external whenReady {
		require(IXVMCgovernor(owner()).fibonacciDelayed() && haltProposal[haltProposalID].enforced && haltProposal[haltProposalID].valid);
		
		haltProposal[haltProposalID].valid = false;
		IXVMCgovernor(owner()).delayFibonacci(false);
		
		emit RemoveDelay(haltProposalID, msg.sender);
	}	

     /**
     * Initiates a request to transfer tokens from the treasury wallet
	 * Can be voted against during the "delay before enforce" period
	 * For extra safety
	 * Requires vote from long term stakers to enforce the transfer
	 * Requires 25% of votes to pass
	 * If only 5% of voters disagree, the proposal is rejected
	 *
	 * The possibilities here are endless
	 *
	 * Could act as a NFT marketplace too, could act as a treasury that pays "contractors",..
	 * Since it's upgradeable, this can be added later on anyways....
	 * Should probably make universal private function for Consensus Votes
     */
	function initiateTreasuryTransferProposal(uint256 depositingTokens,  address tokenAddress, address recipient, uint256 amountToSend) external whenReady { 
    	require(
    	    depositingTokens <= IXVMCgovernor(owner()).maximumVoteTokens() && depositingTokens >= IXVMCgovernor(owner()).costToVote() * 25,
    	    "Minimum or maximum cost not met/exceeded"
    	    );
    	
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
		
		consensusProposal.push(
		    ConsensusVote(1, address(this))
		    ); // vote for
    	consensusProposal.push(
    	    ConsensusVote(1, address(this))
    	    ); // vote against
		
		 treasuryProposal.push(
    	    TreasuryTransfer(true, block.timestamp, depositingTokens, tokenAddress, recipient, amountToSend, consensusProposal.length - 2)
    	   );  
		   
        emit TreasuryProposal(
            treasuryProposal.length - 1, depositingTokens, tokenAddress, recipient, amountToSend, consensusProposal.length - 2, msg.sender
            );
    }
    function vetoTreasuryTransferProposal(uint256 proposalID) external whenReady {
    	require(treasuryProposal[proposalID].valid == true, "Proposal already invalid");
		require(
			treasuryProposal[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() > block.timestamp,
			"Can only be vettod during delayBeforeEnforce period"
		);
    	
		IERC20(token).safeTransferFrom(msg.sender, owner(), treasuryProposal[proposalID].valueSacrificedForVote); 
    	treasuryProposal[proposalID].valid = false;  
		
    	emit TreasuryProposalVeto(proposalID, msg.sender);
    }
    /*
    * Might need to make some sort of delay here
    * Unlikely but in theory there could be a coup
    */
	function approveTreasuryTransfer(uint256 proposalID) external whenReady {
		require(proposalID % 2 == 1);
		require(treasuryProposal[proposalID].valid, "Proposal already invalid");
		uint256 consensusID = treasuryProposal[proposalID].consensusProposalID;
		require(
			treasuryProposal[proposalID].firstCallTimestamp + 2 * IXVMCgovernor(owner()).delayBeforeEnforce() < block.timestamp,
			"Enough time must pass before enforcing"
		);
		require(
			consensusProposal[consensusID].typeOfChange == 1,
				"Incorrect proposal type"
			);

		 require(
            IacPool(acPool6).totalVotesFor(consensusID) >= IacPool(acPool6).totalShares() * 25 / 100,
				"No consensus in Pool 6"
        );
        require(
            IacPool(acPool5).totalVotesFor(consensusID) >= IacPool(acPool5).totalShares() * 25 / 100,
				"No consensus in Pool 5"
        );
        require(
            IacPool(acPool4).totalVotesFor(consensusID) >= IacPool(acPool4).totalShares() * 25 / 100,
				"No consensus in Pool 4"
        );
		
		if(IacPool(acPool6).totalVotesFor(consensusID + 1) >= IacPool(acPool6).totalShares() * 5 / 100 ||
		    IacPool(acPool5).totalVotesFor(consensusID + 1) >= IacPool(acPool5).totalShares() * 5 / 100 ||
		        IacPool(acPool4).totalVotesFor(consensusID + 1) >= IacPool(acPool4).totalShares() * 5 / 100) 
        {
            treasuryProposal[proposalID].valid = false;
        } else {
    		IXVMCgovernor(owner()).treasuryRequest(
    		    treasuryProposal[proposalID].tokenAddress, treasuryProposal[proposalID].beneficiary, treasuryProposal[proposalID].amountToSend
    		   );
    		treasuryProposal[proposalID].valid = false;  
    		
    		emit TreasuryProposalRequested(proposalID, msg.sender);
        }
	}
	
	 /**
     * Note: A similar function could be used to kill(veto) any proposal through long term stakers
	 * One of the things that probably should get added in the future....
	 * Create an universal function that can Veto any proposal through consensus vote
     */
	function killTreasuryTransferProposal(uint256 proposalID) external whenReady {
		require(proposalID % 2 == 0 && proposalID != 0);
		require(!treasuryProposal[proposalID].valid, "Proposal already invalid");
		uint256 consensusID = treasuryProposal[proposalID].consensusProposalID;
		require(
			consensusProposal[consensusID].typeOfChange == 1,
				"Incorrect proposal type"
			);
		
        require(
            IacPool(acPool6).totalVotesFor(consensusID) <= IacPool(acPool6).totalShares() * 5 / 100,
				"No consensus in Pool 6"
        );
        require(
            IacPool(acPool5).totalVotesFor(consensusID) <= IacPool(acPool5).totalShares() * 5 / 100,
				"No consensus in Pool 5"
        );
        require(
            IacPool(acPool4).totalVotesFor(consensusID) <= IacPool(acPool4).totalShares() * 5 / 100,
				"No consensus in Pool 4"
        );
		
    	treasuryProposal[proposalID].valid = false;  
		
    	emit TreasuryProposalVeto(proposalID, msg.sender);
	}
	
    /**
     * Calls execute function after delay has been passed
	 * Requires ownerOnly, must call through governor.
     */
    function executeWithdraw(uint256 withdrawID) external whenReady {
    	IXVMCgovernor(owner()).executeWithdraw(withdrawID);
    }
	
    function proposeGovernor(address _newGovernor) external whenReady {
        IERC20(token).safeTransferFrom(msg.sender, owner(), IXVMCgovernor(owner()).costToVote() * 100);
    	consensusProposal.push(
    	    ConsensusVote(0, _newGovernor)
    	    );
    	consensusProposal.push(
    	    ConsensusVote(0, _newGovernor)
    	    ); //even numbers are basically VETO (for voting against)
    	
    	emit ProposeGovernor(consensusProposal.length - 2, _newGovernor, msg.sender);
    }
    
    /**
     * Atleast 40% of voters required
     * with 90% consensus
     */
    function changeGovernor(uint256 proposalID) external whenReady { 
        require(!(isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated), "invalidated");
		require(consensusProposal.length > proposalID && proposalID % 2 == 1 && proposalID != 0);
        require(!(IXVMCgovernor(owner()).changeGovernorActivated()));
		require(consensusProposal[proposalID].typeOfChange == 0);
		
        IERC20(token).safeTransferFrom(msg.sender, owner(), IXVMCgovernor(owner()).costToVote());

        require(
            IacPool(acPool6).totalVotesFor(proposalID) >= IacPool(acPool6).totalShares() * 40 / 100,
				"No consensus in Pool 6"
        );
        require(
            IacPool(acPool5).totalVotesFor(proposalID) >= IacPool(acPool5).totalShares() * 40 / 100,
				"No consensus in Pool 5"
        );
        require(
            IacPool(acPool4).totalVotesFor(proposalID) >= IacPool(acPool4).totalShares() * 40 / 100,
				"No consensus in Pool 4"
        );
        //requires 90% consensus
        if(IacPool(acPool6).totalVotesFor(proposalID + 1) >= IacPool(acPool6).totalVotesFor(proposalID) / 10 ||
            IacPool(acPool5).totalVotesFor(proposalID + 1) >= IacPool(acPool5).totalVotesFor(proposalID) / 10 ||
                IacPool(acPool4).totalVotesFor(proposalID + 1) >= IacPool(acPool4).totalVotesFor(proposalID) / 10)
            {
                isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated = true;
                
            } else {
                IXVMCgovernor(owner()).setNewGovernor(consensusProposal[proposalID].beneficiaryAddress);
                
                isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].hasPassed = true;
                
                emit ChangeGovernor(proposalID, msg.sender);
            }
    }
    
    /**
     * After approved, still roughly 6 days to cancle the new governor, if less than 90% consensus
     */
    function vetoGovernor(uint256 proposalID) external whenReady {
        require(isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].hasPassed);
        if(IacPool(acPool6).totalVotesFor(proposalID + 1) >= IacPool(acPool6).totalVotesFor(proposalID) / 10 ||
            IacPool(acPool5).totalVotesFor(proposalID + 1) >= IacPool(acPool5).totalVotesFor(proposalID) / 10 ||
                IacPool(acPool4).totalVotesFor(proposalID + 1) >= IacPool(acPool4).totalVotesFor(proposalID) / 10) {
                    
              isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated = true;
        }    
    }
    function enforceGovernor(uint256 proposalID) external whenReady {
        require(!isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated, "invalid");
        
        require(consensusProposal[proposalID].beneficiaryAddress == IXVMCgovernor(owner()).eligibleNewGovernor());
        require(IXVMCgovernor(owner()).newGovernorRequestBlock() + 206680 < block.timestamp, "must wait roughly 6days");
        if(IacPool(acPool6).totalVotesFor(proposalID + 1) >= IacPool(acPool6).totalVotesFor(proposalID) / 10 ||
            IacPool(acPool5).totalVotesFor(proposalID + 1) >= IacPool(acPool5).totalVotesFor(proposalID) / 10 ||
                IacPool(acPool4).totalVotesFor(proposalID + 1) >= IacPool(acPool4).totalVotesFor(proposalID) / 10) {
                    
              isGovInvalidated[consensusProposal[proposalID].beneficiaryAddress].isInvalidated = true;
        }
        IXVMCgovernor(owner()).enforceGovernor();
    }
    
    //transfers ownership of this contract to new governor(if eligible)
    function changeGovernor() external {
        require(IXVMCgovernor(owner()).changeGovernorEnforced());
        transferOwnership(IXVMCgovernor(owner()).eligibleNewGovernor());
    }
}