//
//                 ,/
//               ,'/
//             ,' /
//           ,'  /_____,
//         .'____    ,'
//              /  ,'
//             / ,'
//            /,'
//           /'
//
// Ascii art made by Evan M Corcoran
//
// A full explanation of the protocol can be found at https://github.com/corollari/ln2tBTC/blob/master/README.md

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

// We are not using SafeMath because there's no operation in the contract where an overflow/underflow can cause problems
// More concretely, there are only two functions in the contract that can overflow/underflow, `addFees` and `removeFees`
// and the results of these functions are not trusted through the contract
contract LN2tBTC {

	// ---------------------------------------------------------------
	// OPERATORS
	// ---------------------------------------------------------------
	// All the functions that are meant to be called by operators have their names prefixed with `operator`

	// All of this information could be stored off-chain, but then we would need a way for users to discover the operators available.
	// To achieve that we would need to build a decentralized and uncensorable list of operators, which would be really hard,
	// as the operators are incentivized to prevent users from finding out about other operators.
	// It would also be possible to store only a few bits on-chain and the rest off-chain, but given that this is only a one-time cost for operators,
	// the cost difference is negligible and doing that would probably harm user UX, I believe it's best to store this info on-chain.
	// Moving this info off-chain may be re-evaluated in the future tho, as it would allow for things such as custom algorithms for setting the fees
	struct Operator {
		// URL of a public HTTP server that is used to exchange data off-chain between operator and user.
		string publicUrl;
		// Balance in tBTC (held in the contract to prevent operators from providing fake data).
		// It may seem like holding all the balance in the contract increases the risks for the operators, as if the contract gets hacked
		// they would lose all the funds they have parked there instead of only the funds currently being used in trades.
		// However, if a hacker found an exploit they could make operators put all their money in swap operations (by starting swaps),
		// so there's no real difference in risk (operators are also free to only keep the amount currently used in swaps in the contract).
		// On the other side, this makes it much harder for operators to grief users, so that's a good thign to have while
		// a better anti-user-griefing system is developed (see the section on griefing on README.md for more info).
		uint tBTCBalance;
		// Balance in BTC held by the operator on the Lightning network
		// There's no verification performed on this data point
		// Even if we built a proof system that checked this we would have trouble
		// dealing with the unknown capacity limitation on the LN channels that connect user and operator
		uint lnBalance;
		// Just a simple bool that will be used to check if an item already exists in a mapping
		// Will always be set to true on creation
		bool exists;
		// A fee imposed by the provider that increases linearly with the value of the swap
		// It will be multiplied by the swapped amount and divided by 10^8 to obtain the fee that will be charged to the user
		uint linearFee;
		// A constant fee charged by the provider that will just be added to the value requested
		uint constantFee;
		// totalFee = (amount*linearFee)/10^8 + constantFee
	}

	// The denominator against which linear fees will be divided
	// It's necessary for doing floating-point arithmetic using EVM's integer arithmetic
	// Conversion: a fee of 0.1% would be 0.1*linearFeeDenominator/100
	uint constant linearFeeDenominator = 10**8;
	// Bitcoin uses 8 decimals but tBTC uses 18, this should be corrected
	uint constant tBTCDenominator = 10**10;

	// Contains all operator info addressed by operator address
	// Used by users in conjuction with `operatorList` to search for operators
	mapping (address => Operator) public operators;
	// List of operators, used by users to find the best operator for a swap
	address[] public operatorList;
	// ERC20 tBTC contract (vending machine)
	IERC20 tBTContract = IERC20(0x8dAEBADE922dF735c38C80C7eBD708Af50815fAa);

	// Register a new operator
	// Must only be called once by the operator itself when it starts operating
	// Requires a previous approve() call to the ERC20 tBTC contract to allow the token transfer
	function operatorRegister(uint tBTCBalance, uint lnBalance, uint linearFee, uint constantFee, string memory publicUrl) public {
		require(operators[msg.sender].exists==false, "Operator has already been registered before");
		operators[msg.sender] = Operator(publicUrl, tBTCBalance, lnBalance, true, linearFee, constantFee);
		if(tBTCBalance > 0){
			tBTContract.transferFrom(msg.sender, address(this), tBTCBalance);
		}
		operatorList.push(msg.sender);
	}

	// Returns the length of the `operatorList` array
	// Used by clients to iterate over the operators when searching for the lowest fees
	function getOperatorListLength() view public returns(uint length){
		return operatorList.length;
	}

	// Simple withdraw operation for the ERC20 tBTC tokens held in the contract in behalf of an operator
	function operatorWithdrawTBTC(uint amount) public returns(bool){
		Operator storage op = operators[msg.sender];
		require(op.tBTCBalance >= amount);
		op.tBTCBalance -= amount;
		tBTContract.transfer(msg.sender, amount);
		return true;
	}

	// Simple deposit operation
	// Requires a previous approve() call to the ERC20 tBTC contract to allow the token transfer
	function operatorDepositTBTC(uint amount) public returns(bool){
		Operator storage op = operators[msg.sender];
		require(op.exists == true); // Not needed, just there to make sure people don't lose money
		op.tBTCBalance += amount;
		tBTContract.transferFrom(msg.sender, address(this), amount);
		return true;
	}

	// Set the fees of the operator calling the function
	function operatorSetFees(uint newLinearFee, uint newConstantFee) public {
		operators[msg.sender].linearFee = newLinearFee;
		operators[msg.sender].constantFee = newConstantFee;
	}

	// Set the amount of LN-bound BTC that the operator makes available
	// This number is completely unverified and can be faked
	function operatorSetLNBalance(uint newLNBalance) public {
		operators[msg.sender].lnBalance = newLNBalance;
	}

	// Set the url of the operator node
	function operatorSetPublicUrl(string memory newUrl) public {
		operators[msg.sender].publicUrl = newUrl;
	}

	// ---------------------------------------------------------------
	// tBTC -> LN SWAPS
	// ---------------------------------------------------------------
	// TODO: Move some steps off-chain to lower the cost and make the whole process faster (no need to wait for confirmations)
	// This is harder that it seems because you have to avoid impersonation attacks from other users
	// (eg: A locks tBTC and B sends to the operator an invoice that pays to B, the operator won't be able to tell which invoice is the right one: A's or B's)
	// To prevent these attacks, an authentication system must be put in place, but the obvious solutions all have downsides:
	//   - Signing the message with metamask requires an additional step for the user -> worse UX
	//   - Creating an ephemeral key in the browser can cause problems if the history is deleted mid-swap and it involves extra data (pubkey) sent on txs
	// So I'm still unsure on what's the best solution for this.

	// Time it takes for a step of the swap to time out if the counter-party is unresponsive
	// Constant chosen arbitrarily
	uint public timeoutPeriod = 1 hours;

	struct TBTC2LNSwap {
		// Provider that is serving the swap
		address provider;
		// Amount of tBTC that is locked in the swap
		// A value of 0 is used to represent that the swap has been finalized
		uint tBTCAmount;
		// Timestamp of the moment the swap will time out
		// Always set to `now + lockTime` on creation, where lockTime is the maximum swap duration as set by the user
		// This field is also used to check for struct existence by comparing it against 0
		uint timeoutTimestamp;
	}

	// A double mapping is used for the following reasons:
	//   - It splits the storage spaces of different users, preventing attacks where one user can front-run another user's txs to prevent them from creating a swap
	//   - The space of each user is indexed using a unique identifier, in this case the paymentHash (which must be unique, otherwise it's pre-image may be public)
	// This allows a user to have multiple swaps running concurrently while preventing attacks
	mapping (address => mapping (bytes32 => TBTC2LNSwap)) public tbtcSwaps;

	// Event fired when a new tBTC->LN swap process has been started
	event TBTC2LNSwapCreated(bytes32 paymentHash, uint amount, address userAddress, address providerAddress, uint lockTime, string invoice);

	// TODO: Send LN invoice to operator through an off-chain medium to lower costs (not by much tho)
	// Create a new swap from tBTC to LN, locking the tBTC tokens required from the swap in the contract
	// Requires a previous approve() call to the ERC20 tBTC contract to allow the token transfer
	// Note that this function doesn't reduce the `tBTCBalance` of the provider, as doing otherwise would open the provider to griefing attacks,
	// so, if two users create swaps concurrently, a provider may not have enough liquidity to serve both of them
	// This can be solved by having the users listen to the `TBTC2LNSwapCreated` events emitted by the contract
	function createTBTC2LNSwap(bytes32 paymentHash, uint amount, address providerAddress, uint lockTime, string memory invoice) public {
		require(tbtcSwaps[msg.sender][paymentHash].timeoutTimestamp == 0, "Swap already exists");
		tbtcSwaps[msg.sender][paymentHash] = TBTC2LNSwap(providerAddress, amount, now + lockTime);
		tBTContract.transferFrom(msg.sender, address(this), amount);
		emit TBTC2LNSwapCreated(paymentHash, amount, msg.sender, providerAddress, lockTime, invoice);
	}

	// Reverts a swap, returning the locked tBTC tokens to the user, if the pre-image hasn't been revealed within 1 hour of swap creation
	// This could happen because either the operator is unresponsive and hasn't paid the invoice on time
	// or because the user hasn't revealed the pre-image before the timeout
	// (it could also happen if the operator malfunctions and doesn't claim it's payment after the swap, but this should never happen)
	function revertTBTC2LNSwap(bytes32 paymentHash) public {
		TBTC2LNSwap storage swap = tbtcSwaps[msg.sender][paymentHash];
		require(swap.timeoutTimestamp != 0, "Swap doesn't exist");
		require(swap.tBTCAmount > 0, "Swap has already been finalized");
		require(swap.timeoutTimestamp < now, "Swap hasn't timed out yet");
		uint tBTCAmount = swap.tBTCAmount;
		swap.tBTCAmount = 0;
		tBTContract.transfer(msg.sender, tBTCAmount);
	}

	// Finalizes a successful swap by transferring the locked tBTC tokens to the operator
	// This is called by the swap operator and requires the preimage of the HTLC used in the lightning invoice,
	// which is revealed when the invoice is accepted by the user's wallet/node
	function operatorClaimPayment(address userAddress, bytes32 paymentHash, bytes memory preimage) public {
		TBTC2LNSwap storage swap = tbtcSwaps[userAddress][paymentHash];
		require(swap.provider == msg.sender, "Swap doesn't use this provider or doesn't exist at all");
		require(swap.tBTCAmount > 0, "Swap has already been finalized");
		require(sha256(preimage) == paymentHash, "Preimage doesn't match the payment hash");
		Operator storage operator = operators[msg.sender];
		operator.tBTCBalance += swap.tBTCAmount;
		swap.tBTCAmount = 0;
		// The call to removeFees can overflow/underflow
		// But given that this can only happen if the operator assigns malicious fee parameters and
		// the result only affects `lnBalance`, which is unverified and can be already set to any value by the operator
		// then an overflow here won't cause any problems
		operator.lnBalance -= removeFees(swap.tBTCAmount/tBTCDenominator, operator.linearFee, operator.constantFee); 
	}

	// The calculations done in this function may overflow or underflow
	// Extra care must be taken to ensure that the results from this function are only used in situations where this is fine
	function removeFees(uint amount, uint linearFee, uint constantFee) pure public returns (uint amountWithoutFees){
		return ((amount - constantFee)*linearFeeDenominator)/(linearFeeDenominator+linearFee);
	}

	// ---------------------------------------------------------------
	// LN -> tBTC SWAPS
	// ---------------------------------------------------------------

	// A security deposit that is provided by the user on swap creation
	// It is returned to the user if either the swap concludes successfully or the operator is unresponsive and times out
	// If the user doesn't reveal the pre-image on time after the operator has locked tBTC, then it is awarded to the provider
	// Currently it is a simple constant value in ETH, which is not perfect for the following reasons:
	//   - This deposit should cover the operator's tx fees, but these are dynamic whereas the deposit is constant so it's possible
	//     that at some point tx fees are greater than this deposit
	//   - The deposit doesn't scale with the value of locked tBTC, so it's possible to make an operator lock a large amount of value
	//     while only losing a much smaller fee
	// However, doing something more complex would require an oracle, and, as it is, maintaining this kind of attack for a day
	// would cost 24 ETH, which is unsutainable, so the current system should already do a good job at deterring malicious actors
	// Furthemore, operators can defend against this attack by being selective on the swaps they allow (eg: they can reject big amounts)
	uint public securityDepositAmount = 1 ether;

	struct LN2TBTCSwap {
		// Provider that is serving the swap
		address provider;
		// Amount of tBTC that the user is requesting for their LN-bound BTC
		// It will locked in the contract by the operator after the user has sent an invoice payment request
		// A value of 0 is used to represent that the swap has been finalized
		uint tBTCAmount;
		// Timestamp of the moment the swap was created.
		// Always set to `now` on creation
		// This field is also used to check for struct existence by comparing it against 0
		uint startTimestamp;
		// Timestamp of the moment the operator locks it's tBTC tokens (after the user has sent the LN payment request)
		// Will be used to keep track of the timeout that is triggered when the user hasn't revealed the pre-image on time
		uint tBTCLockTimestamp;
	}

	// The reasons why this structure has been chosen are outlined in the definition of `tbtcSwaps`
	mapping (address => mapping (bytes32 => LN2TBTCSwap)) public lnSwaps;

	// Fired on swap creation, should be answered by the operator by providing the user with an LN invoice
	event LN2TBTCSwapCreated(address userAddress, bytes32 paymentHash, address providerAddress, uint tBTCAmount);
	// Fired when the operator locks tBTC in expectance of the pre-image reveal, should be answered by the user with a call to `claimTBTCPayment`
	event LN2TBTCOperatorLockedTBTC(address userAddress, bytes32 paymentHash);
	// Fired when the HTLC pre-image has been revealed, concludes the swap as the operator can now claim the LN payment and finalize everything
	event LN2TBTCPreimageRevealed(address userAddress, bytes32 paymentHash, address providerAddress, bytes preimage);

	// Creates a new LN -> tBTC swap
	// Locks the ETH security deposit in the contract
	// This function doesn't reduce the `lnBalance` of an operator, see the comment on the definition of `createTBTC2LNSwap` for more details on this
	function createLN2TBTCSwap(bytes32 paymentHash, address providerAddress, uint tBTCAmount) payable public {
		require(lnSwaps[msg.sender][paymentHash].startTimestamp == 0, "Swap already exists");
		require(msg.value == securityDepositAmount, "ETH security deposit provided isn't the right amount (should be 1 ETH)");
		require(tBTCAmount > 0, "The amount requested cannot be zero (why swap something for nothing?)");
		lnSwaps[msg.sender][paymentHash] = LN2TBTCSwap(providerAddress, tBTCAmount, now, 0);
		emit LN2TBTCSwapCreated(msg.sender, paymentHash, providerAddress, tBTCAmount);
	}

	// Abort swap if the operator has been unresponsive and hasn't locked the tBTC tokens before the timeout (or the user hasn't sent a payment request)
	// Returns the security deposit to the user
	function revertLN2TBTCSwap(bytes32 paymentHash) public {
		LN2TBTCSwap storage swap = lnSwaps[msg.sender][paymentHash];
		require(swap.tBTCAmount > 0, "Swap doesn't exist or has already been finalized");
		require((swap.startTimestamp + timeoutPeriod) < now, "Swap hasn't timed out yet");
		require(swap.tBTCLockTimestamp == 0, "Operator has locked the tBTC tokens before the timeout");
		swap.tBTCAmount = 0;
		msg.sender.transfer(securityDepositAmount); // Return security deposit
	}

	// Lock tBTC tokens and make them claimable by the user if they provide a valid pre-image before timeout
	function operatorLockTBTCForLN2TBTCSwap(address userAddress, bytes32 paymentHash) public {
		LN2TBTCSwap storage swap = lnSwaps[userAddress][paymentHash];
		require(swap.provider == msg.sender, "Swap doesn't use this provider or doesn't exist at all");
		require(swap.tBTCAmount > 0, "Swap has already been finalized");
		require(swap.tBTCLockTimestamp == 0, "tBTC tokens have already been locked before for this swap");
		Operator storage op = operators[msg.sender];
		require(op.tBTCBalance >= swap.tBTCAmount, "Operator doesn't have enough funds to conduct the swap");
		op.tBTCBalance -= swap.tBTCAmount;
		swap.tBTCLockTimestamp = now;
		emit LN2TBTCOperatorLockedTBTC(userAddress, paymentHash);
	}

	// Revert swap if, once the operator has locked the tBTC tokens, the user hasn't revealed the pre-image before timeout
	// It will also transfer the security deposit provided by the user on swap creation to the operator, in order to:
	//   - Make up for the fees that the operator spent sending the transaction that called `operatorLockTBTCForLN2TBTCSwap`
	//   - Make up for the opportunity cost on the operator's side of having their tBTC locked for some time
	function operatorRevertLN2TBTCSwap(address userAddress, bytes32 paymentHash) public {
		LN2TBTCSwap storage swap = lnSwaps[userAddress][paymentHash];
		require(swap.provider == msg.sender, "Swap doesn't use this provider or doesn't exist at all");
		require(swap.tBTCAmount > 0, "Swap has already been finalized");
		require(swap.tBTCLockTimestamp != 0, "tBTC tokens have not been locked for this swap");
		require((swap.tBTCLockTimestamp + timeoutPeriod) < now, "Swap hasn't timed out yet");
		operators[msg.sender].tBTCBalance += swap.tBTCAmount;
		swap.tBTCAmount = 0;
		msg.sender.transfer(securityDepositAmount); // Award security deposit to the operator as compensation
	}

	// Claim the tBTC tokens locked by the operator, revealing the HTLC preimage and thus allowing the operator to finalise the LN payment
	function claimTBTCPayment(bytes32 paymentHash, bytes memory preimage) public {
		LN2TBTCSwap storage swap = lnSwaps[msg.sender][paymentHash];
		require(swap.tBTCAmount > 0, "Swap doesn't exist or has already been finalized");
		require(swap.tBTCLockTimestamp != 0, "tBTC tokens have not been locked for this swap");
		require(sha256(preimage) == paymentHash, "Preimage doesn't match the payment hash");
		uint tBTCAmount = swap.tBTCAmount;
		swap.tBTCAmount = 0;
		tBTContract.transfer(msg.sender, tBTCAmount);
		msg.sender.transfer(securityDepositAmount); // Return security deposit to user
		Operator storage op = operators[swap.provider];
		// The result of `addFees` must not be trusted as it can overflow/underflow. However, given that here we are
		// using it to set the value of `Operator.lnBalance`, which is already under the control of the operator, it's fine.
		op.lnBalance += addFees(tBTCAmount/tBTCDenominator, op.linearFee, op.constantFee); // Update operator balance
		emit LN2TBTCPreimageRevealed(msg.sender, paymentHash, swap.provider, preimage);
	}

	// The calculations done in this function may overflow or underflow
	// Extra care must be taken to ensure that the results from this function are only used in situations where this is fine
	function addFees(uint amount, uint linearFee, uint constantFee) pure public returns (uint amountWithFees){
		return (amount * (linearFeeDenominator + linearFee))/linearFeeDenominator + constantFee;
	}
}