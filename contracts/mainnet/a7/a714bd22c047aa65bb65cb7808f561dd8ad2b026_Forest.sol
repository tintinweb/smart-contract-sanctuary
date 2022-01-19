// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./IWoolf.sol";
import "./MutantPeach.sol";

contract Forest is Ownable, IERC721Receiver, Pausable {
	// maximum alpha score for a Wolf
	uint8 public constant MAX_ALPHA = 8;

	// struct to store a stake's token, owner, and earning values
	struct Stake {
		uint16 tokenId;
		uint80 value;
		address owner;
	}

	event TokenStaked(address owner, uint256 tokenId, uint256 value);
	event ApeClaimed(uint256 tokenId, uint256 earned, bool unstaked);
	event WolfClaimed(uint256 tokenId, uint256 earned, bool unstaked);

	// reference to the IWoolf NFT contract
	IWoolf woolf;
	// reference to the $MutantPeach contract for minting $MutantPeach earnings
	MutantPeach mutantPeach;

	// maps tokenId to stake
	mapping(uint256 => Stake) public forest;
	// maps alpha to all Wolf stakes with that alpha
	mapping(uint256 => Stake[]) public pack;
	// tracks location of each Wolf in Pack
	mapping(uint256 => uint256) public packIndices;

	// total alpha scores staked
	uint256 public totalAlphaStaked = 0;
	// any rewards distributed when no wolves are staked
	uint256 public unaccountedRewards = 0;
	// amount of $MutantPeach due for each alpha point staked
	uint256 public woolPerAlpha = 0;

	// ape earn 5000 $MutantPeach per day
	uint256 public constant DAILY_MP_RATE = 5000 ether;
	// ape must have 2 days worth of $MutantPeach to unstake or else it's too cold
	uint256 public constant MINIMUM_TO_EXIT = 4 days;
	// wolves take a 20% tax on all $MutantPeach claimed
	uint256 public constant MP_CLAIM_TAX_PERCENTAGE = 20;
	// there will only ever be (roughly) 2.4 billion $MutantPeach earned through staking
	uint256 public constant MAXIMUM_GLOBAL_MP = 2400000000 ether;

	// amount of $MutantPeach earned so far
	uint256 public totalWoolEarned;
	// number of Ape staked in the Forest
	uint256 public totalApeStaked;
	// the last time $MutantPeach was claimed
	uint256 public lastClaimTimestamp;

	// emergency rescue to allow unstaking without any checks but without $MutantPeach
	bool public rescueEnabled = false;

	/**
	 * @param _woolf reference to the IWoolf NFT contract
	 * @param _peach reference to the $MutantPeach token
	 */
	constructor(address _woolf, address _peach) {
		woolf = IWoolf(_woolf);
		mutantPeach = MutantPeach(_peach);
	}

	/** STAKING */

	/**
	 * adds Ape and Wolves to the Forest and Pack
	 * @param account the address of the staker
	 * @param tokenIds the IDs of the Ape and Wolves to stake
	 */
	function addManyToForestAndPack(address account, uint16[] calldata tokenIds) external {
		require(account == _msgSender() || _msgSender() == address(woolf), "DONT GIVE YOUR TOKENS AWAY");
		for (uint256 i = 0; i < tokenIds.length; i++) {
			if (_msgSender() != address(woolf)) {
				// dont do this step if its a mint + stake
				require(woolf.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
				woolf.transferFrom(_msgSender(), address(this), tokenIds[i]);
			} else if (tokenIds[i] == 0) {
				continue; // there may be gaps in the array for stolen tokens
			}
			if (isApe(tokenIds[i])) _addApeToForest(account, tokenIds[i]);
			else _addWolfToPack(account, tokenIds[i]);
		}
	}

	/**
	 * adds a single Ape to the Forest
	 * @param account the address of the staker
	 * @param tokenId the ID of the Ape to add to the Forest
	 */
	function _addApeToForest(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
		forest[tokenId] = Stake({ owner: account, tokenId: uint16(tokenId), value: uint80(block.timestamp) });
		totalApeStaked += 1;
		emit TokenStaked(account, tokenId, block.timestamp);
	}

	/**
	 * adds a single Wolf to the Pack
	 * @param account the address of the staker
	 * @param tokenId the ID of the Wolf to add to the Pack
	 */
	function _addWolfToPack(address account, uint256 tokenId) internal {
		uint256 alpha = _alphaForWolf(tokenId);
		totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
		packIndices[tokenId] = pack[alpha].length; // Store the location of the wolf in the Pack
		pack[alpha].push(Stake({ owner: account, tokenId: uint16(tokenId), value: uint80(woolPerAlpha) })); // Add the wolf to the Pack
		emit TokenStaked(account, tokenId, woolPerAlpha);
	}

	/** CLAIMING / UNSTAKING */

	/**
	 * realize $MutantPeach earnings and optionally unstake tokens from the Forest / Pack
	 * to unstake a Ape it will require it has 2 days worth of $MutantPeach unclaimed
	 * @param tokenIds the IDs of the tokens to claim earnings from
	 * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
	 */
	function claimManyFromForestAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
		uint256 owed = 0;
		for (uint256 i = 0; i < tokenIds.length; i++) {
			if (isApe(tokenIds[i])) owed += _claimApeFromForest(tokenIds[i], unstake);
			else owed += _claimWolfFromPack(tokenIds[i], unstake);
		}
		if (owed == 0) return;
		mutantPeach.mint(_msgSender(), owed);
	}

	/**
	 * realize $MutantPeach earnings for a single Ape and optionally unstake it
	 * if not unstaking, pay a 20% tax to the staked Wolves
	 * if unstaking, there is a 50% chance all $MutantPeach is stolen
	 * @param tokenId the ID of the Ape to claim earnings from
	 * @param unstake whether or not to unstake the Ape
	 * @return owed - the amount of $MutantPeach earned
	 */
	function _claimApeFromForest(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
		Stake memory stake = forest[tokenId];
		require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
		require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S MutantPeach");
		if (totalWoolEarned < MAXIMUM_GLOBAL_MP) {
			owed = ((block.timestamp - stake.value) * DAILY_MP_RATE) / 1 days;
		} else if (stake.value > lastClaimTimestamp) {
			owed = 0; // $MutantPeach production stopped already
		} else {
			owed = ((lastClaimTimestamp - stake.value) * DAILY_MP_RATE) / 1 days; // stop earning additional $MutantPeach if it's all been earned
		}
		if (unstake) {
			if (random(tokenId) & 1 == 1) {
				// 50% chance of all $MutantPeach stolen
				_payWolfTax(owed);
				owed = 0;
			}
			woolf.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Ape
			delete forest[tokenId];
			totalApeStaked -= 1;
		} else {
			_payWolfTax((owed * MP_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked wolves
			owed = (owed * (100 - MP_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Ape owner
			forest[tokenId] = Stake({ owner: _msgSender(), tokenId: uint16(tokenId), value: uint80(block.timestamp) }); // reset stake
		}
		emit ApeClaimed(tokenId, owed, unstake);
	}

	/**
	 * realize $MutantPeach earnings for a single Wolf and optionally unstake it
	 * Wolves earn $MutantPeach proportional to their Alpha rank
	 * @param tokenId the ID of the Wolf to claim earnings from
	 * @param unstake whether or not to unstake the Wolf
	 * @return owed - the amount of $MutantPeach earned
	 */
	function _claimWolfFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
		require(woolf.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
		uint256 alpha = _alphaForWolf(tokenId);
		Stake memory stake = pack[alpha][packIndices[tokenId]];
		require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
		owed = (alpha) * (woolPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
		if (unstake) {
			totalAlphaStaked -= alpha; // Remove Alpha from total staked
			woolf.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Wolf
			Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
			pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Wolf to current position
			packIndices[lastStake.tokenId] = packIndices[tokenId];
			pack[alpha].pop(); // Remove duplicate
			delete packIndices[tokenId]; // Delete old mapping
		} else {
			pack[alpha][packIndices[tokenId]] = Stake({ owner: _msgSender(), tokenId: uint16(tokenId), value: uint80(woolPerAlpha) }); // reset stake
		}
		emit WolfClaimed(tokenId, owed, unstake);
	}

	/**
	 * emergency unstake tokens
	 * @param tokenIds the IDs of the tokens to claim earnings from
	 */
	function rescue(uint256[] calldata tokenIds) external {
		require(rescueEnabled, "RESCUE DISABLED");
		uint256 tokenId;
		Stake memory stake;
		Stake memory lastStake;
		uint256 alpha;
		for (uint256 i = 0; i < tokenIds.length; i++) {
			tokenId = tokenIds[i];
			if (isApe(tokenId)) {
				stake = forest[tokenId];
				require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
				woolf.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Ape
				delete forest[tokenId];
				totalApeStaked -= 1;
				emit ApeClaimed(tokenId, 0, true);
			} else {
				alpha = _alphaForWolf(tokenId);
				stake = pack[alpha][packIndices[tokenId]];
				require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
				totalAlphaStaked -= alpha; // Remove Alpha from total staked
				woolf.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Wolf
				lastStake = pack[alpha][pack[alpha].length - 1];
				pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Wolf to current position
				packIndices[lastStake.tokenId] = packIndices[tokenId];
				pack[alpha].pop(); // Remove duplicate
				delete packIndices[tokenId]; // Delete old mapping
				emit WolfClaimed(tokenId, 0, true);
			}
		}
	}

	/** ACCOUNTING */

	/**
	 * add $MutantPeach to claimable pot for the Pack
	 * @param amount $MutantPeach to add to the pot
	 */
	function _payWolfTax(uint256 amount) internal {
		if (totalAlphaStaked == 0) {
			// if there's no staked wolves
			unaccountedRewards += amount; // keep track of $MutantPeach due to wolves
			return;
		}
		// makes sure to include any unaccounted $MutantPeach
		woolPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
		unaccountedRewards = 0;
	}

	/**
	 * tracks $MutantPeach earnings to ensure it stops once 2.4 billion is eclipsed
	 */
	modifier _updateEarnings() {
		if (totalWoolEarned < MAXIMUM_GLOBAL_MP) {
			totalWoolEarned += ((block.timestamp - lastClaimTimestamp) * totalApeStaked * DAILY_MP_RATE) / 1 days;
			lastClaimTimestamp = block.timestamp;
		}
		_;
	}

	/** ADMIN */

	/**
	 * allows owner to enable "rescue mode"
	 * simplifies accounting, prioritizes tokens out in emergency
	 */
	function setRescueEnabled(bool _enabled) external onlyOwner {
		rescueEnabled = _enabled;
	}

	/**
	 * enables owner to pause / unpause minting
	 */
	function setPaused(bool _paused) external onlyOwner {
		if (_paused) _pause();
		else _unpause();
	}

	function getPackByAlphaAndID(uint256 alpha, uint256 tokenId) public view returns (Stake memory) {
		return pack[alpha][packIndices[tokenId]];
	}

	function getForestStakeByID(uint256 id) public view returns (Stake memory) {
		return forest[id];
	}

	/** READ ONLY */

	/**
	 * checks if a token is a Ape
	 * @param tokenId the ID of the token to check
	 * @return ape - whether or not a token is a Ape
	 */
	function isApe(uint256 tokenId) public view returns (bool ape) {
		// (ape, , , , , , ) = woolf.getTokenTraits(tokenId);
		IWoolf.ApeWolf memory obj = woolf.getTokenTraits(tokenId);
		return obj.isApe;
	}

	/**
	 * gets the alpha score for a Wolf
	 * @param tokenId the ID of the Wolf to get the alpha score for
	 * @return the alpha score of the Wolf (5-8)
	 */
	function _alphaForWolf(uint256 tokenId) internal view returns (uint8) {
		IWoolf.ApeWolf memory obj = woolf.getTokenTraits(tokenId);
		return MAX_ALPHA - obj.alphaIndex; // alpha index is 0-3
	}

	/**
	 * chooses a random Wolf thief when a newly minted token is stolen
	 * @param seed a random value to choose a Wolf from
	 * @return the owner of the randomly selected Wolf thief
	 */
	function randomWolfOwner(uint256 seed) external view returns (address) {
		if (totalAlphaStaked == 0) return address(0x0);
		uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
		uint256 cumulative;
		seed >>= 32;
		// loop through each bucket of Wolves with the same alpha score
		for (uint256 i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
			cumulative += pack[i].length * i;
			// if the value is not inside of that bucket, keep going
			if (bucket >= cumulative) continue;
			// get the address of a random Wolf with that alpha score
			return pack[i][seed % pack[i].length].owner;
		}
		return address(0x0);
	}

	/**
	 * generates a pseudorandom number
	 * @param seed a value ensure different outcomes for different sources in the same block
	 * @return a pseudorandom value
	 */
	function random(uint256 seed) internal view returns (uint256) {
		return uint256(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, seed)));
	}

	function setWolfAddress(address _address) external onlyOwner {
		woolf = IWoolf(_address);
	}

	function setWoolAddress(address _address) external onlyOwner {
		mutantPeach = MutantPeach(_address);
	}

	function onERC721Received(
		address,
		address from,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		require(from == address(0x0), "Cannot send tokens to Forest directly");
		return IERC721Receiver.onERC721Received.selector;
	}
}