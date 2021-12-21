/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAUSD {
	function addCoin(address coin) external;

	function blockCoin(uint16 index, bool blocked) external;

	function updateMintFee(uint16 _mintFeePercent) external;

	function updateRedeemFee(uint16 _redeemFeePercent) external;

	function updateTreasury(address _treasury) external;

	function transferOwnership(address newOwner) external;
}

/// @notice The AUSDSafeOwner owns AUSD and locks down its functionality.
/// @notice It prevents the owner from ever increasing the redemption fee beyond reasonable amounts.
/// @notice It requires the owner to announce that they are adding a new token at least 24 hours in advance.
/// @notice It moves us one step closer to decentralisation.
contract AUSDSafeOwner {
	uint16 public maxMintFee = 1000;
	uint16 public maxRedemptionFee = 1000;

	uint256 public constant ownershipReclaimDelay = 7 * 24 hours;
	uint256 public ownershipReclaimTimestamp;
	address public pendingOwner;

	uint256 public delay = 24 hours;
	mapping(address => uint256) public addCoinAllowedAt;

	event DelayUpdated(uint256 delay);
	event MaxMintFeeUpdated(uint16 maxMintFee);
	event MaxRedemptionFeeUpdated(uint16 maxRedemptionFee);
	event CoinQueued(address indexed coin, bool indexed cancelled);
	event OwnershipTransferQueued(address indexed owner, bool indexed cancelled);

	event CoinAdded(address indexed coin);
	event CoinBlocked(uint16 indexed coin, bool indexed blocked);
	event MintFeeUpdated(uint16 mintFee);
	event RedemptionFeeUpdated(uint16 redemptionFee);
	event TreasuryUpdated(address indexed treasury);
	event UnderlyingOwnershipTransferred(address indexed newOwner);

  address public owner;
	IAUSD public immutable ausd;

	constructor(address _ausd) {
		ausd = IAUSD(_ausd);
    owner = msg.sender;
	}

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

	//** GOVERNANCE FUNCTIONS **//

	/// @notice Increases the timelock delay which is initially set at 24 hours. Makes the contract even safer but cannot be undone.
	function increaseDelayTo(uint256 newDelay) external onlyOwner {
		require(newDelay > delay, "Cannot decrease timelock delay");
		delay = newDelay;

		emit DelayUpdated(newDelay);
	}

	/// @notice Decreases the max mint fee which is initially set at 10%. Makes the contract even safer but cannot be undone.
	function decreaseMaxMintFee(uint16 newMaxMintFee) external onlyOwner {
		require(newMaxMintFee < maxMintFee, "Cannot decrease timelock delay");
		maxMintFee = newMaxMintFee;

		emit MaxMintFeeUpdated(newMaxMintFee);
	}

	/// @notice Decreases the max redemption fee which is initially set at 10%. Makes the contract even safer but cannot be undone.
	function decreaseMaxRedemptionFee(uint16 newMaxRedemptionFee) external onlyOwner {
		require(newMaxRedemptionFee < maxRedemptionFee, "Cannot decrease timelock delay");
		maxRedemptionFee = newMaxRedemptionFee;

		emit MaxRedemptionFeeUpdated(newMaxRedemptionFee);
	}

	/// @notice queues an addCoin call, addCoin can be called 24 hours later.
	function queueAddCoin(address coin) external onlyOwner {
		require(addCoinAllowedAt[coin] == 0, "!already queued");
		addCoinAllowedAt[coin] = block.timestamp + delay;

		emit CoinQueued(coin, false);
	}

	/// @notice cancel the addCoin queue.
	function cancelAddCoin(address coin) external onlyOwner {
		require(addCoinAllowedAt[coin] != 0, "!not queued");
		addCoinAllowedAt[coin] = 0;

		emit CoinQueued(coin, true);
	}

	/// @notice queues an transferOwnership, allows for ownership to be reclaimed 7 days later.
	function queueOwnershipTransfer(address _pendingOwner) external onlyOwner {
		require(ownershipReclaimTimestamp == 0, "!already queued");
		pendingOwner = _pendingOwner;
		ownershipReclaimTimestamp = block.timestamp + ownershipReclaimDelay;

		emit OwnershipTransferQueued(_pendingOwner, false);
	}

	/// @notice cancels the ownershipTransfer queue.
	function cancelOwnershipReclaim() external onlyOwner {
		require(ownershipReclaimTimestamp != 0, "!not queued");
		pendingOwner = address(0);
		ownershipReclaimTimestamp = 0;
	}

	//** SAFEGUARDED FUNCTIONS **//

	/// @notice Calls addcoin on ausd, requires this to be announced at least 24 hours beforehand.
	function addCoin(address coin) external onlyOwner {
		require(addCoinAllowedAt[coin] != 0, "!not queued");
		require(block.timestamp >= addCoinAllowedAt[coin], "!not ready");
		addCoinAllowedAt[coin] = 0;

		ausd.addCoin(coin);

		emit CoinAdded(coin);
	}

	/// @notice Blocks minting using the specified stablecoin, can be called at any time to prevent exploits if a stable loses peg.
	function blockCoin(uint16 index, bool blocked) external onlyOwner {
		ausd.blockCoin(index, blocked);

		emit CoinBlocked(index, blocked);
	}

	/// @notice updates the mintFee, adds the requirement that it can be at most 10%.
	function updateMintFee(uint16 _mintFeePercent) external onlyOwner {
		require(_mintFeePercent <= maxMintFee, "!too high");
		ausd.updateMintFee(_mintFeePercent);

		emit MintFeeUpdated(_mintFeePercent);
	}

	/// @notice updates the redeemFee, adds the requirement that it can be at most 10%.
	function updateRedeemFee(uint16 _redeemFeePercent) external onlyOwner {
		require(_redeemFeePercent <= maxRedemptionFee, "!too high");
		ausd.updateRedeemFee(_redeemFeePercent);

		emit RedemptionFeeUpdated(_redeemFeePercent);
	}

	/// @notice sets the treasury, adds the requirement that it must be non-zero.
	function updateTreasury(address _treasury) external onlyOwner {
		require(_treasury != address(0), "!zero address");
		ausd.updateTreasury(_treasury);

		emit TreasuryUpdated(_treasury);
	}

	/// @notice transfers ownership away from the safeOwner, adds the requirement that this must be announced 7 days in advance.
	function transferUnderlyingOwnership() external onlyOwner {
		require(pendingOwner != address(0), "!zero address");
		require(ownershipReclaimTimestamp != 0, "!not queued");
		require(block.timestamp >= ownershipReclaimTimestamp, "!not ready");
		ausd.transferOwnership(pendingOwner);

		emit UnderlyingOwnershipTransferred(pendingOwner);
	}

	function transferOwnership(address newOwner) external onlyOwner {
		require(newOwner != address(0), "!zero address");
    owner = newOwner;
	}
}