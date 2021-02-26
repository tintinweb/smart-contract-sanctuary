pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./OTCTypes.sol";
import "./ACOAssetHelper.sol";
import "./SafeMath.sol";
import "./IACOFactory.sol";
import "./IWETH.sol";
import "./IACOToken.sol";

/**
 * @title ACOOTC
 * @dev Contract to trade OTC on ACO tokens. 
 * Inspired on Swap SC by AirSwap, under Apache License, Version 2.0
 * https://github.com/airswap/airswap-protocols/blob/master/source/swap/contracts/Swap.sol
 */
contract ACOOTC {
	using SafeMath for uint256;
	
	event Swap(
		uint256 indexed nonce,
		address indexed signer,
		address indexed sender,
		bool isAskOrder,
		uint256 signerAmount,
		address signerToken,
		uint256 senderAmount,
		address senderToken,
		address affiliate,
		uint256 affiliateAmount,
		address affiliateToken
	);
	event Cancel(uint256 indexed nonce, address indexed signer);
	event CancelUpTo(uint256 indexed nonce, address indexed signer);
	event AuthorizeSender(address indexed authorizerAddress, address indexed authorizedSender);
	event AuthorizeSigner(address indexed authorizerAddress, address indexed authorizedSigner);
	event RevokeSender(address indexed authorizerAddress, address indexed revokedSender);
	event RevokeSigner(address indexed authorizerAddress, address indexed revokedSigner);
	
	//Domain and version for use in signatures (EIP-712)
	bytes internal constant DOMAIN_NAME = "ACOOTC";
	bytes internal constant DOMAIN_VERSION = "1";

	// Unique domain identifier for use in signatures (EIP-712)
	bytes32 private immutable _domainSeparator;

	// Possible nonce statuses
	bytes1 internal constant AVAILABLE = 0x00;
	bytes1 internal constant UNAVAILABLE = 0x01;

	// Address of the ACO Factory contract
	IACOFactory public immutable acoFactory;
	// Address of the WETH contract
	IWETH public immutable weth;

	// Mapping of sender address to a delegated sender address and bool
	mapping(address => mapping(address => bool)) public senderAuthorizations;

	// Mapping of signer address to a delegated signer and bool
	mapping(address => mapping(address => bool)) public signerAuthorizations;

	// Mapping of signers to nonces with value AVAILABLE (0x00) or UNAVAILABLE (0x01)
	mapping(address => mapping(uint256 => bytes1)) public signerNonceStatus;

	// Mapping of signer addresses to an optionally set minimum valid nonce
	mapping(address => uint256) public signerMinimumNonce;

	/**
	 * @notice Contract Constructor
	 * @dev Sets domain for signature validation (EIP-712) and the ACO Factory and WETH
	 * @param _acoFactory ACO Factory address
	 * @param _weth WETH address
	 */
	constructor(address _acoFactory, address _weth) public {
		_domainSeparator = OTCTypes.hashDomain(
			DOMAIN_NAME,
			DOMAIN_VERSION,
			address(this)
		);
		acoFactory = IACOFactory(_acoFactory);
		weth = IWETH(_weth);
	}

	/**
	 * @notice Receive ETH from WETH contract
	 */
	receive() external payable {
        require(msg.sender == address(weth), "ACOOTC:: Only WETH");
    }

	/**
	 * @notice Atomic Token Swap for an Ask Order
	 * @param order OTCTypes.AskOrder Order to settle
	 */
	function swapAskOrder(OTCTypes.AskOrder calldata order) external {
		// Ensure the order is valid.
		address finalSender = _baseSwapValidation(
			order.expiry,
			order.nonce,
			order.signer.responsible,
			order.sender.responsible,
			order.affiliate.responsible,
			order.signature.signatory,
			order.signature.v
		);
		// Ensure the signature is valid whether it is provided.
		require(order.signature.v == uint8(0) || isValidAskOrder(order), "ACOOTC:: Signature invalid");

		ACOAssetHelper._callTransferFromERC20(order.sender.token, finalSender, order.signer.responsible, order.sender.amount);

		address _aco = _transferAco(order.signer.responsible, finalSender, order.signer);

		// Transfer token from signer to affiliate if specified.
		if (order.affiliate.token != address(0)) {
			ACOAssetHelper._callTransferFromERC20(order.affiliate.token, order.signer.responsible, order.affiliate.responsible, order.affiliate.amount);
		}

		emit Swap(
			order.nonce,
			order.signer.responsible,
			finalSender,
			true,
			order.signer.amount,
			_aco,
			order.sender.amount,
			order.sender.token,
			order.affiliate.responsible,
			order.affiliate.amount,
			order.affiliate.token
		);
	}
	
	/**
	 * @notice Atomic Token Swap for a Bid Order
	 * @param order OTCTypes.BidOrder Order to settle
	 */
	function swapBidOrder(OTCTypes.BidOrder calldata order) external {
		// Ensure the order is valid.
		address finalSender = _baseSwapValidation(
			order.expiry,
			order.nonce,
			order.signer.responsible,
			order.sender.responsible,
			order.affiliate.responsible,
			order.signature.signatory,
			order.signature.v
		);
		// Ensure the signature is valid whether it is provided.
		require(order.signature.v == uint8(0) || isValidBidOrder(order), "ACOOTC:: Signature invalid");

		address _aco = _transferAco(finalSender, order.signer.responsible, order.sender);
		
		ACOAssetHelper._callTransferFromERC20(order.signer.token, order.signer.responsible, finalSender, order.signer.amount);

		// Transfer token from signer to affiliate if specified.
		if (order.affiliate.token != address(0)) {
			ACOAssetHelper._callTransferFromERC20(order.affiliate.token, order.signer.responsible, order.affiliate.responsible, order.affiliate.amount);
		}

		emit Swap(
			order.nonce,
			order.signer.responsible,
			finalSender,
			false,
			order.signer.amount,
			order.signer.token,
			order.sender.amount,
			_aco,
			order.affiliate.responsible,
			order.affiliate.amount,
			order.affiliate.token
		);
	}

	/**
	 * @notice Cancel one or more open orders by nonce
	 * @dev Cancelled nonces are marked UNAVAILABLE (0x01)
	 * @dev Emits a Cancel event
	 * @dev Out of gas may occur in arrays of length > 400
	 * @param nonces uint256[] List of nonces to cancel
	 */
	function cancel(uint256[] calldata nonces) external {
		for (uint256 i = 0; i < nonces.length; i++) {
			if (signerNonceStatus[msg.sender][nonces[i]] == AVAILABLE) {
				signerNonceStatus[msg.sender][nonces[i]] = UNAVAILABLE;
				emit Cancel(nonces[i], msg.sender);
			}
		}
	}

	/**
	 * @notice Cancels all orders below a nonce value
	 * @dev Emits a CancelUpTo event
	 * @param minimumNonce uint256 Minimum valid nonce
	 */
	function cancelUpTo(uint256 minimumNonce) external {
		signerMinimumNonce[msg.sender] = minimumNonce;
		emit CancelUpTo(minimumNonce, msg.sender);
	}

	/**
	 * @notice Authorize a delegated sender
	 * @dev Emits an AuthorizeSender event
	 * @param authorizedSender address Address to authorize
	 */
	function authorizeSender(address authorizedSender) external {
		require(msg.sender != authorizedSender, "ACOOTC:: Self authorization");
		if (!senderAuthorizations[msg.sender][authorizedSender]) {
			senderAuthorizations[msg.sender][authorizedSender] = true;
			emit AuthorizeSender(msg.sender, authorizedSender);
		}
	}

	/**
	 * @notice Authorize a delegated signer
	 * @dev Emits an AuthorizeSigner event
	 * @param authorizedSigner address Address to authorize
	 */
	function authorizeSigner(address authorizedSigner) external {
		require(msg.sender != authorizedSigner, "ACOOTC:: Self authorization");
		if (!signerAuthorizations[msg.sender][authorizedSigner]) {
			signerAuthorizations[msg.sender][authorizedSigner] = true;
			emit AuthorizeSigner(msg.sender, authorizedSigner);
		}
	}

	/**
	 * @notice Revoke an authorized sender
	 * @dev Emits a RevokeSender event
	 * @param authorizedSender address Address to revoke
	 */
	function revokeSender(address authorizedSender) external {
		if (senderAuthorizations[msg.sender][authorizedSender]) {
			delete senderAuthorizations[msg.sender][authorizedSender];
			emit RevokeSender(msg.sender, authorizedSender);
		}
	}

	/**
	 * @notice Revoke an authorized signer
	 * @dev Emits a RevokeSigner event
	 * @param authorizedSigner address Address to revoke
	 */
	function revokeSigner(address authorizedSigner) external {
		if (signerAuthorizations[msg.sender][authorizedSigner]) {
			delete signerAuthorizations[msg.sender][authorizedSigner];
			emit RevokeSigner(msg.sender, authorizedSigner);
		}
	}
	
    /**
     * @notice Validate signature using an EIP-712 typed data hash
     * @param order OTCTypes.AskOrder Order to validate
     * @return bool True if order has a valid signature
     */
	function isValidAskOrder(OTCTypes.AskOrder memory order) public view returns(bool) {
		bytes32 orderHash = OTCTypes.hashAskOrder(order, _domainSeparator);
		return _isValid(orderHash, order.signature);
	}

    /**
     * @notice Validate signature using an EIP-712 typed data hash
     * @param order OTCTypes.BidOrder Order to validate
     * @return bool True if order has a valid signature
     */
	function isValidBidOrder(OTCTypes.BidOrder memory order) public view returns(bool) {
		bytes32 orderHash = OTCTypes.hashBidOrder(order, _domainSeparator);
		return _isValid(orderHash, order.signature);
	}

	/**
	 * @notice Determine whether a sender delegate is authorized
	 * @param authorizer address Address doing the authorization
	 * @param delegate address Address being authorized
	 * @return bool True if a delegate is authorized to send
	 */
	function _isSenderAuthorized(address authorizer, address delegate) internal view returns(bool) {
		return ((authorizer == delegate) || senderAuthorizations[authorizer][delegate]);
	}

	/**
	 * @notice Determine whether a signer delegate is authorized
	 * @param authorizer address Address doing the authorization
	 * @param delegate address Address being authorized
	 * @return bool True if a delegate is authorized to sign
	 */
	function _isSignerAuthorized(address authorizer, address delegate) internal view returns(bool) {
		return ((authorizer == delegate) || signerAuthorizations[authorizer][delegate]);
	}

    /**
     * @notice Validate signature using an EIP-712 typed data hash
     * @param orderHash Hashed order to validate
	 * @param signature OTCTypes.Signature teh order signature
     * @return bool True if order has a valid signature
     */
	function _isValid(bytes32 orderHash, OTCTypes.Signature memory signature) internal pure returns(bool) {
		if (signature.version == bytes1(0x01)) {
			return signature.signatory ==
				ecrecover(
					orderHash,
					signature.v,
					signature.r,
					signature.s
				);
		}
		if (signature.version == bytes1(0x45)) {
			return signature.signatory ==
				ecrecover(
					keccak256(
						abi.encodePacked(
							"\x19Ethereum Signed Message:\n32",
							orderHash
						)
					),
					signature.v,
					signature.r,
					signature.s
				);
		}
		return false;
	}

	/**
     * @notice Validate all base data for a swap order
     * @param expiry Order expiry time
	 * @param nonce Order expiry time
	 * @param signer Order signer responsible address
	 * @param sender Order sender responsible address
	 * @param affiliate Order affiliate responsible address
	 * @param signatory Order signatory address
	 * @param v Order `v` parameter on the signature
     * @return The final sender address
     */
	function _baseSwapValidation(
		uint256 expiry,
		uint256 nonce,
		address signer,
		address sender,
		address affiliate,
		address signatory,
		uint8 v
	) internal returns(address) {
		// Ensure the order is not expired.
		require(expiry > block.timestamp, "ACOOTC:: Order expired");

		// Ensure the nonce is AVAILABLE (0x00).
		require(signerNonceStatus[signer][nonce] == AVAILABLE, "ACOOTC:: Order taken or cancelled");

		// Ensure the order nonce is above the minimum.
		require(nonce >= signerMinimumNonce[signer], "ACOOTC:: Nonce too low");
		
		// Ensure distinct addresses.
		require(signer != affiliate, "ACOOTC:: Self transfer");

		// Mark the nonce UNAVAILABLE (0x01).
		signerNonceStatus[signer][nonce] = UNAVAILABLE;

		// Validate the sender side of the trade.
		address finalSender;
		if (sender == address(0)) {
			// Sender is not specified. The msg.sender of the transaction becomes the sender of the order.
			finalSender = msg.sender;
		} else {
			// Sender is specified. If the msg.sender is not the specified sender, this determines whether the msg.sender is an authorized sender.
			require(_isSenderAuthorized(sender, msg.sender), "ACOOTC:: Sender unauthorized");
			
			// The msg.sender is authorized.
			finalSender = sender;
		}
		// Ensure distinct addresses.
		require(signer != finalSender, "ACOOTC:: Self transfer");

		// Validate the signer side of the trade.
		if (v == 0) {
			// Signature is not provided. The signer may have authorized the msg.sender to swap on its behalf, which does not require a signature.
			require(_isSignerAuthorized(signer, msg.sender), "ACOOTC:: Signer unauthorized");
		} else {
			// The signature is provided. Determine whether the signer is authorized.
			require(_isSignerAuthorized(signer, signatory), "ACOOTC:: Signer unauthorized");
		}
		
		return finalSender;
	}

	/**
     * @notice Transfer an ACO token
	 * With the order ACO party parameters a new ACO token will be created 
	 * The collateral is used to mint ACO and then those tokens are transferred
     * @param from The ACO creator responsible
	 * @param to The ACO token destination
	 * @param data OTCTypes.PartyAco Order party parameters to the ACO token
     * @return The created ACO address
     */
	function _transferAco(address from, address to, OTCTypes.PartyAco memory data) internal returns(address) {
		address collateral;
		uint256 collateralAmount;
		if (data.isCall) {
			collateral = data.underlying;
			collateralAmount = data.amount;
		} else {
			collateral = data.strikeAsset;
			
			uint256 decimals = uint256(ACOAssetHelper._getAssetDecimals(data.underlying));
			// Ensure the underlying decimals will not overflow.
			require(decimals < 78, "ACOOTC:: Invalid underlying");
			
			collateralAmount = data.amount.mul(data.strikePrice).div((10 ** decimals));
		}
		// Ensure the collateral amount is not zero.
		require(collateralAmount > 0, "ACOOTC:: Collateral amount is too low");

		if (ACOAssetHelper._isEther(collateral)) {
			IWETH _weth = weth;
			ACOAssetHelper._callTransferFromERC20(address(_weth), from, address(this), collateralAmount);
			_weth.withdraw(collateralAmount);
		} else {
			ACOAssetHelper._callTransferFromERC20(collateral, from, address(this), collateralAmount);
		}
		
		address aco = acoFactory.getAcoToken(
			data.underlying, 
			data.strikeAsset, 
			data.isCall, 
			data.strikePrice, 
			data.expiryTime
		);
		if (aco == address(0)) {
			aco = acoFactory.createAcoToken(
				data.underlying, 
				data.strikeAsset, 
				data.isCall, 
				data.strikePrice, 
				data.expiryTime, 
				uint256(100)
			);
		}
		
		if (ACOAssetHelper._isEther(collateral)) {
			IACOToken(aco).mintToPayable{value: collateralAmount}(from);
		} else {
			ACOAssetHelper._callApproveERC20(collateral, aco, collateralAmount);
			IACOToken(aco).mintTo(from, collateralAmount);
		}
		
		ACOAssetHelper._callTransferERC20(aco, to, data.amount);
		
		return aco;
	}
}