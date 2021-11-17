// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IDarknodeRegistry.sol";
import "../interfaces/IDarknodePayment.sol";
import "../interfaces/IClaimRewards.sol";
import "../interfaces/IGateway.sol";
// TODO: use safeMath
// TODO: Ownable + Ownable.initialize(_owner);

contract RenPool {
	uint8 public constant DECIMALS = 18;

	address public owner; // This will be our address, in case we need to refund everyone
	address public nodeOperator;
	address public darknodeID;

	bytes public publicKey;
	// ^ What happens if we register and deregister and register back again?

	uint256 public bond;
	uint256 public totalPooled;
	uint256 public ownerFee; // Percentage
	uint256 public nodeOperatorFee; // Percentage

	uint64 public nonce;

	bool public isLocked;
  // ^ we could use enum instead POOL_STATUS = { OPEN /* 0 */, CLOSE /* 1 */ }

	mapping(address => uint256) public balances;
	mapping(address => uint256) public withdrawRequests;

	IERC20 public renToken;
	IDarknodeRegistry public darknodeRegistry;
	IDarknodePayment public darknodePayment;
	IClaimRewards public claimRewards;
	IGateway public gateway; // OR IMintGateway????

	event RenDeposited(address indexed _from, uint256 _amount);
	event RenWithdrawn(address indexed _from, uint256 _amount);
	event EthDeposited(address indexed _from, uint256 _amount);
	event EthWithdrawn(address indexed _from, uint256 _amount);
	event PoolLocked();
	event PoolUnlocked();

	/**
	 * @notice Deploy a new RenPool instance.
	 *
	 * @param _renTokenAddr The REN token contract address.
	 * @param _darknodeRegistryAddr The DarknodeRegistry contract address.
	 * @param _darknodePaymentAddr The DarknodePayment contract address.
	 * @param _claimRewardsAddr The ClaimRewards contract address.
	 * @param _gatewayAddr The Gateway contract address.
	 * @param _owner The protocol owner's address. Possibly a multising wallet.
	 * @param _bond The amount of REN tokens required to register a darknode.
	 */
	constructor(
		address _renTokenAddr,
		address _darknodeRegistryAddr,
		address _darknodePaymentAddr,
		address _claimRewardsAddr,
		address _gatewayAddr,
		address _owner,
		uint256 _bond
	)
	{
		owner = _owner;
		nodeOperator = msg.sender;
		renToken = IERC20(_renTokenAddr);
		darknodeRegistry = IDarknodeRegistry(_darknodeRegistryAddr);
		darknodePayment = IDarknodePayment(_darknodePaymentAddr);
		claimRewards = IClaimRewards(_claimRewardsAddr);
		gateway = IGateway(_gatewayAddr);
		bond = _bond;
		isLocked = false;
		totalPooled = 0;
		ownerFee = 5;
		nodeOperatorFee = 5;
		nonce = 0;

		// TODO: register pool into RenPoolStore
	}

	modifier onlyNodeOperator() {
		require (
			msg.sender == nodeOperator,
			"RenPool: Caller is not node operator"
		);
		_;
	}

	modifier onlyOwnerNodeOperator() {
		require (
			msg.sender == owner || msg.sender == nodeOperator,
			"Caller is not owner/nodeOperator"
		);
		_;
	}

	modifier onlyOwner() {
		require (
			msg.sender == owner,
			"Caller is not owner"
		);
		_;
	}

	/**
	 * @notice Lock pool so that no direct deposits/withdrawals can
	 * be performed.
	 */
	function _lockPool() private {
		isLocked = true;
		emit PoolLocked();
	}

	function unlockPool() external onlyOwnerNodeOperator {
		require(renToken.balanceOf(address(this)) > 0, "Pool balance is zero");
		isLocked = false;
		emit PoolUnlocked();
	}

	/**
	 * @notice Deposit REN into the RenPool contract. Before depositing,
	 * the transfer must be approved in the REN contract. In case the
	 * predefined bond is reached, the pool is locked preventing any
	 * further deposits or withdrawals.
	 *
	 * @param _amount The amount of REN to be deposited into the pool.
	 */
	function deposit(uint256 _amount) external {
		address sender = msg.sender;

		require(isLocked == false, "RenPool: Pool is locked");
		require(_amount > 0, "RenPool: Invalid amount");
		require(_amount + totalPooled <= bond, "RenPool: Amount surpasses bond");

		balances[sender] += _amount;
		totalPooled += _amount;

		renToken.transferFrom(sender, address(this), _amount);

		emit RenDeposited(sender, _amount);

		if (totalPooled == bond) {
			_lockPool();
		}
	}

	/**
	 * @notice Withdraw REN tokens while the pool is still open.
	 */
	function withdraw(uint256 _amount) external {
		address sender = msg.sender;
		uint256 senderBalance = balances[sender];

		require(senderBalance > 0 && senderBalance >= _amount, "Insufficient funds");
		require(isLocked == false, "Pool is locked");

		totalPooled -= _amount;
		balances[sender] -= _amount;

		require(
			renToken.transfer(sender, _amount) == true,
			"Withdraw failed"
		);

		emit RenWithdrawn(sender, _amount);
	}

	/**
	 * TODO
	 * @dev Users can have up to a single request active. In case of several
	 * calls to this method, only the last request will be preserved.
	 */
	function requestWithdraw(uint256 _amount) external {
		address sender = msg.sender;
		uint256 senderBalance = balances[sender];

		require(senderBalance > 0 && senderBalance >= _amount, "Insufficient funds");
		require(isLocked == true, "Pool is not locked");

		withdrawRequests[sender] = _amount;

		// TODO emit event
	}

	/**
	 * TODO
	 */
	function fulfillWithdrawRequest(address _target) external {
		address sender = msg.sender;
		uint256 amount = withdrawRequests[_target];
		// ^ This could not be defined plus make sure amount > 0
		// TODO: make sure user cannot fullfil his own request
		// TODO: add test for when _target doesn't have an associated withdrawRequest

		require(isLocked == true, "Pool is not locked");

		balances[sender] += amount;
		balances[_target] -= amount;
		delete withdrawRequests[_target];

		// Transfer funds from sender to _target
		require(
			renToken.transferFrom(sender, address(this), amount) == true,
			"Deposit failed"
		);
		require(
			renToken.transfer(_target, amount) == true,
			"Refund failed"
		);

		// TODO emit event
	}

	// TODO: cancelWithdrawRequest
	// TODO: getWithdrawRequests

	/**
	 * @notice Return REN balance for the given address.
	 *
	 * @param _target Address to be queried.
	 */
	function balanceOf(address _target) external view returns(uint) {
		return balances[_target];
	}

	/**
	 * @notice Transfer bond to the darknodeRegistry contract prior to
	 * registering the darknode.
	 */
	function approveBondTransfer() external onlyNodeOperator {
		require(isLocked == true, "Pool is not locked");

		require(
			renToken.approve(address(darknodeRegistry), bond) == true,
			"Bond transfer failed"
		);
	}

	/**
	 * @notice Register a darknode and transfer the bond to the darknodeRegistry
	 * contract. Before registering, the bond transfer must be approved in the
	 * darknodeRegistry contract (see approveTransferBond). The caller must
	 * provide a public encryption key for the darknode. The darknode will remain
	 * pending registration until the next epoch. Only after this period can the
	 * darknode be deregistered. The caller of this method will be stored as the
	 * owner of the darknode.
	 *
	 * @param _darknodeID The darknode ID that will be registered.
	 * @param _publicKey The public key of the darknode. It is stored to allow
	 * other darknodes and traders to encrypt messages to the trader.
	 */
	function registerDarknode(address _darknodeID, bytes calldata _publicKey) external onlyNodeOperator {
		require(isLocked == true, "Pool is not locked");

		darknodeRegistry.register(_darknodeID, _publicKey);

		darknodeID = _darknodeID;
		publicKey = _publicKey;
	}

	/**
	 * @notice Deregister a darknode. The darknode will not be deregistered
	 * until the end of the epoch. After another epoch, the bond can be
	 * refunded by calling the refund method.
	 *
	 * @dev We don't reset darknodeID/publicKey values after deregistration in order
	 * to being able to call refund.
	 */
	function deregisterDarknode() external onlyOwnerNodeOperator {
		darknodeRegistry.deregister(darknodeID);
	}

	/**
	 * @notice Refund the bond of a deregistered darknode. This will make the
	 * darknode available for registration again. Anyone can call this function
	 * but the bond will always be refunded to the darknode owner.
	 *
	 * @dev No need to reset darknodeID/publicKey values after refund.
	 */
	function refundBond() external {
		darknodeRegistry.refund(darknodeID);
	}

	/**
	 * @notice Allow ETH deposits in case gas is necessary to pay for transactions.
	 */
	receive() external payable {
		emit EthDeposited(msg.sender, msg.value);
	}

	/**
	 * @notice Allow node operator to withdraw any remaining gas.
	 */
	function withdrawGas() external onlyNodeOperator {
		uint256 balance = address(this).balance;
		payable(nodeOperator).transfer(balance);
		emit EthWithdrawn(nodeOperator, balance);
	}

	/**
	 * @notice Transfer rewards from darknode to darknode owner prior to calling claimDarknodeRewards.
	 *
	 * @param _tokens List of tokens to transfer. (here we could have a list with all available tokens)
	 */
	function transferRewardsToDarknodeOwner(address[] calldata _tokens) external {
		darknodePayment.withdrawMultiple(address(this), _tokens);
	}

	/**
	 * @notice Claim darknode rewards.
	 *
	 * @param _assetSymbol The asset being claimed. e.g. "BTC" or "DOGE".
	 * @param _amount The amount of the token being minted, in its smallest
	 * denomination (e.g. satoshis for BTC).
	 * @param _recipientAddress The Ethereum address to which the assets are
	 * being withdrawn to. This same address must then call `mint` on
	 * the asset's Ren Gateway contract.
	 */
	function claimDarknodeRewards(
		string memory _assetSymbol,
		uint256 _amount, // avoid this param, read from user balance instead. What about airdrops?
		address _recipientAddress
	)
		external
		returns(uint256, uint256)
	{
		// TODO: check that sender has the amount to be claimed
		uint256 fractionInBps = 10_000; // TODO: this should be the share of the user for the given token
		uint256 sig = claimRewards.claimRewardsToEthereum(_assetSymbol, _recipientAddress, fractionInBps);
		nonce += 1;

		return (sig, nonce);
		// bytes32 pHash = keccak256(abi.encode(_assetSymbol, _recipientAddress));
		// bytes32 nHash = keccak256(abi.encode(nonce, _amount, pHash));

		// gateway.mint(pHash, _amount, nHash, sig);

		/*
                    const nHash = randomBytes(32);
                    const pHash = randomBytes(32);

                    const hash = await gateway.hashForSignature.call(
                        pHash,
                        value,
                        user,
                        nHash
                    );
                    const sig = ecsign(
                        Buffer.from(hash.slice(2), "hex"),
                        privKey
                    );
										See: https://github.com/renproject/gateway-sol/blob/7bd51d8a897952a31134875d7b2b621e4542deaa/test/Gateway.ts
		*/
	}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDarknodeRegistry {
	/**
		* @notice Register a darknode and transfer the bond to the REN contract.
		* Before registering, the bond transfer must be approved in the REN
		* contract. The caller must provide a public encryption key for the
		* darknode. The darknode will remain pending registration until the next
		* epoch. Only after this period can the darknode be deregistered. The
		* caller of this method will be stored as the owner of the darknode.
		*
		* @param _darknodeID The darknode ID that will be registered.
		* @param _publicKey The public key of the darknode. It is stored to allow
		* other darknodes and traders to encrypt messages to the trader.
		*/
	function register(address _darknodeID, bytes calldata _publicKey) external;

	/**
		* @notice Retrieves the address of the account that registered a darknode.
		*
		* @param _darknodeID The ID of the darknode to retrieve the owner for.
		*/
	function getDarknodeOperator(address _darknodeID) external view returns (address payable);

	/**
		* @notice Deregister a darknode. The darknode will not be deregistered
		* until the end of the epoch. After another epoch, the bond can be
		* refunded by calling the refund method.
		*
		* @param _darknodeID The darknode ID that will be deregistered. The caller
		* of this method store.darknodeRegisteredAt(_darknodeID) must be
		* the owner of this darknode.
		*/
	function deregister(address _darknodeID) external;

	/**
		* @notice Refund the bond of a deregistered darknode. This will make the
		* darknode available for registration again. Anyone can call this function
		* but the bond will always be refunded to the darknode owner.
		*
		* @param _darknodeID The darknode ID that will be refunded. The caller
		* of this method must be the owner of this darknode.
		*/
	function refund(address _darknodeID) external;

	/**
		* @notice Returns whether a darknode is scheduled to become registered
		* at next epoch.
		*
		* @param _darknodeID The ID of the darknode to return
		*/
	function isPendingRegistration(address _darknodeID) external view returns (bool);

	/**
		* @notice Returns if a darknode is in the pending deregistered state. In
		* this state a darknode is still considered registered.
		*/
	function isPendingDeregistration(address _darknodeID) external view returns (bool);

	/**
		* @notice Returns if a darknode is in the registered state.
		*/
	function isRegistered(address _darknodeID) external view returns (bool);

	/**
		* @notice Returns if a darknode is in the deregistered state.
		*/
	function isDeregistered(address _darknodeID) external view returns (bool);

	/**
		* @notice Progress the epoch if it is possible to do so. This captures
		* the current timestamp and current blockhash and overrides the current
		* epoch.
		*/
	function epoch() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
// pragma solidity 0.5.16;

interface IDarknodePayment {
	/**
	 * @notice Transfers the funds allocated to the darknode to the darknode owner.
	 *
	 * @param _darknode The address of the darknode
	 * @param _token Which token to transfer
	 */
	function withdraw(address _darknode, address _token) external;

	function withdrawMultiple(address _darknode, address[] calldata _tokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IClaimRewards {
	/**
	 * `claimRewardsToEthereum` triggers a withdrawal of a darknode operator's
	 * rewards. `claimRewardsToEthereum` must be called by the operator
	 * performing the withdrawals. When RenVM sees the claim, it will produce a
	 * signature which needs to be submitted to the asset's Ren Gateway contract
	 * on Ethereum.
	 *
	 * @param assetSymbol_ The asset being claimed. e.g. "BTC" or "DOGE"
	 * @param recipientAddress_ The Ethereum address to which the assets are
	 * being withdrawn to. This same address must then call `mint` on
	 * the asset's Ren Gateway contract.
	 * @param fractionInBps_ A value between 0 and 10000 that indicates the
	 * percent to withdraw from each of the operator's darknodes.
	 * 10000 represents 100%, 5000 represents 50%, etc.
	 */
	function claimRewardsToEthereum(
		string memory assetSymbol_,
		address recipientAddress_,
		uint256 fractionInBps_
	) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IMintGateway {
	function mint(
		bytes32 _pHash,
		uint256 _amount,
		bytes32 _nHash,
		bytes calldata _sig
	) external returns (uint256);

	function mintFee() external view returns (uint256);
}

interface IBurnGateway {
	function burn(bytes calldata _to, uint256 _amountScaled) external returns (uint256);
	function burnFee() external view returns (uint256);
}

// TODO: In ^0.6.0, should be `interface IGateway is IMintGateway,IBurnGateway {}`
interface IGateway {
	/**
	 * @notice mint verifies a mint approval signature from RenVM and creates
	 * tokens after taking a fee for the `_feeRecipient`.
	 *
	 * @param _pHash (payload hash) The hash of the payload associated with the
	 * mint, ie, asset symbol and recipient address.
	 * @param _amount The amount of the token being minted, in its smallest
	 * denomination (e.g. satoshis for BTC).
	 * @param _nHash (nonce hash) The hash of the nonce, amount and pHash.
	 * @param _sig The signature of the hash of the following values:
	 * (pHash, amount, msg.sender, nHash), signed by the mintAuthority. Where
	 * mintAuthority refers to the address of the key that can sign mint requests.
	 *
	 * @dev See: https://github.com/renproject/gateway-sol/blob/7bd51d8a897952a31134875d7b2b621e4542deaa/contracts/Gateway/MintGatewayV3.sol
	 */
	// is IMintGateway
	function mint(
		bytes32 _pHash,
		uint256 _amount,
		bytes32 _nHash,
		bytes calldata _sig
	) external returns (uint256);

	function mintFee() external view returns (uint256);

	// is IBurnGateway
	function burn(bytes calldata _to, uint256 _amountScaled) external returns (uint256);
	function burnFee() external view returns (uint256);
}