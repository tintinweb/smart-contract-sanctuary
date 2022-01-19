// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ERC20.sol";
import "./IWoolf.sol";
import "./IForest.sol";
import "./ITraits.sol";
import "./MutantPeach.sol";

interface ISuperShibaBAMC {
	function balanceOf(address owner) external view returns (uint256);

	function ownerOf(uint256 index) external view returns (address);
}

interface ISuperShibaClub {
	function balanceOf(address owner) external view returns (uint256);

	function ownerOf(uint256 index) external view returns (address);
}

interface Pool {
	function balanceOf(address owner) external view returns (uint256);
}

interface RandomPick {
	function random(uint256 seed) external view returns (uint256);
}

contract Woolf is ERC721Enumerable, Ownable, Pausable {
	RandomPick private randomPick;
	ISuperShibaBAMC public bamc;
	ISuperShibaClub public club;
	Pool public pool;
	// reference to the Forest for choosing random Wolf thieves
	IForest public forest;
	// reference to $MutantPeach for burning on mint
	MutantPeach public mutantPeach;
	// reference to Traits
	ITraits public traits;

	// mint price
	// uint256 public MINT_PRICE = 0.06942 ether;
	uint256 public MINT_PRICE = 0.000001 ether;
	// max number of tokens that can be minted - 50000 in production
	uint256 public immutable MAX_TOKENS;
	// number of tokens that can be claimed for free - 20% of MAX_TOKENS
	uint256 public PAID_TOKENS;
	// number of tokens have been minted so far
	uint16 public minted = 0;

	bool public openFreeMint = false;
	bool public openPublicMint = false;

	uint256 public LP = 0.5 ether;

	// mapping from tokenId to a struct containing the token's traits
	mapping(uint256 => IWoolf.ApeWolf) public tokenTraits;
	// mapping from hashed(tokenTrait) to the tokenId it's associated with
	// used to ensure there are no duplicates
	mapping(uint256 => uint256) public existingCombinations;

	mapping(uint256 => address) public superShibaBAMCTokensMint;
	mapping(uint256 => address) public superShibaClubTokensMint;

	// list of probabilities for each trait type
	// 0 - 5 are associated with Ape, 6 - 11 are associated with Wolves
	uint8[][12] public rarities;
	// list of aliases for Walker's Alias algorithm
	// 0 - 5 are associated with Ape, 6 - 11 are associated with Wolves
	uint8[][12] public aliases;

	address private wolfGameTreasury;

	/**
	 * instantiates contract and rarity tables
	 */
	constructor(
		address _peach,
		address _traits,
		address _bamc,
		address _club,
		address _treasury,
		uint256 _maxTokens
	) ERC721("Mutant Forest", "MForest") {
		mutantPeach = MutantPeach(_peach);
		traits = ITraits(_traits);
		bamc = ISuperShibaBAMC(_bamc);
		club = ISuperShibaClub(_club);
		wolfGameTreasury = _treasury;
		MAX_TOKENS = _maxTokens;
		PAID_TOKENS = _maxTokens / 5;

		// I know this looks weird but it saves users gas by making lookup O(1)
		// A.J. Walker's Alias Algorithm
		// ape
		// skin 22
		rarities[0] = [50, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128];
		aliases[0] = [17, 17, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 21, 21, 21, 21, 21];
		// eyes 19
		rarities[1] = [50, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128];
		aliases[1] = [18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18];
		// mouth 22
		rarities[2] = [50, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128];
		aliases[2] = [21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21];
		// clothing 0
		rarities[3] = [255];
		aliases[3] = [0];

		// headwear 43
		rarities[4] = [
			50,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128
		];
		aliases[4] = [
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42,
			42
		];

		// alphaIndex
		rarities[5] = [255];
		aliases[5] = [0];

		// wolf
		// skin 4
		rarities[6] = [255];
		aliases[6] = [0];
		// eyes 11
		rarities[7] = [50, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128];
		aliases[7] = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10];
		// mouth 11
		rarities[8] = [50, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128];
		aliases[8] = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10];
		// clothing 26
		rarities[9] = [
			50,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128,
			128
		];
		aliases[9] = [25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25];

		// headwear 21
		rarities[10] = [50, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128];
		aliases[10] = [20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20];

		// alphaIndex 0
		rarities[11] = [9, 161, 74, 255];
		aliases[11] = [2, 3, 3, 3];
	}

	/** EXTERNAL */

	/**
	 * mint a token - 90% Ape, 10% Wolves
	 * The first 20% are free to claim, the remaining cost $MutantPeach
	 */
	function mint(uint256 amount) external payable whenNotPaused {
		require(tx.origin == _msgSender(), "Only EOA");
		require(openPublicMint, "not open free mint");
		require(minted + amount <= MAX_TOKENS, "All tokens minted");
		require(amount > 0 && amount <= 10, "Invalid mint amount");
		if (minted < PAID_TOKENS) {
			require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
			require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
		} else {
			require(msg.value == 0);
		}

		uint256 totalWoolCost = 0;

		uint256 seed;
		for (uint256 i = 0; i < amount; i++) {
			minted++;
			seed = randomPick.random(minted);
			address recipient = selectRecipient(seed);
			_safeMint(recipient, minted);
			generate(minted, seed);
			totalWoolCost += mintCost(minted);
		}

		if (totalWoolCost > 0) mutantPeach.burn(_msgSender(), totalWoolCost);
	}

	function freeMint(uint256[] memory bamcIds, uint256[] memory clubIds) external whenNotPaused {
		require(tx.origin == _msgSender(), "Only EOA");
		require(openFreeMint, "not open free mint");
		require((bamcIds.length + clubIds.length) <= 10, "Invalid mint amount");
		require((minted + bamcIds.length + clubIds.length) <= MAX_TOKENS, "All tokens minted");

		uint256 mintCount = 0;
		for (uint256 i = 0; i < bamcIds.length; i++) {
			uint256 tokenId = bamcIds[i];
			if (bamc.ownerOf(tokenId) == _msgSender()) {
				if (superShibaBAMCTokensMint[tokenId] == address(0)) {
					mintCount++;
					superShibaBAMCTokensMint[tokenId] = _msgSender();
				}
			}
		}

		for (uint256 i = 0; i < clubIds.length; i++) {
			uint256 tokenId = clubIds[i];
			if (club.ownerOf(tokenId) == _msgSender()) {
				if (superShibaClubTokensMint[tokenId] == address(0)) {
					mintCount++;
					superShibaClubTokensMint[tokenId] = _msgSender();
				}
			}
		}

		require(mintCount > 0, "The shiba in your wallet has been mint");

		_freeMint(mintCount);
	}

	function _freeMint(uint256 amount) private whenNotPaused {
		uint256 seed;
		for (uint256 i = 0; i < amount; i++) {
			minted++;
			seed = randomPick.random(minted);

			_safeMint(_msgSender(), minted);

			generate(minted, seed);
		}
	}

	/**
	 * the first 20% are paid in ETH
	 * the next 20% are 20000 $MutantPeach
	 * the next 40% are 40000 $MutantPeach
	 * the final 20% are 80000 $MutantPeach
	 * @param tokenId the ID to check the cost of to mint
	 * @return the cost of the given token ID
	 */
	function mintCost(uint256 tokenId) public view returns (uint256) {
		if (tokenId <= PAID_TOKENS) return 0;
		if (tokenId <= (MAX_TOKENS * 2) / 5) return 20000 ether;
		if (tokenId <= (MAX_TOKENS * 4) / 5) return 40000 ether;
		return 80000 ether;
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		// Hardcode the Forest's approval so that users don't have to waste gas approving
		if (_msgSender() != address(forest))
			require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
		_transfer(from, to, tokenId);
	}

	/** INTERNAL */

	/**
	 * generates traits for a specific token, checking to make sure it's unique
	 * @param tokenId the id of the token to generate traits for
	 * @param seed a pseudorandom 256 bit number to derive traits from
	 * @return t - a struct of traits for the given token ID
	 */
	function generate(uint256 tokenId, uint256 seed) internal returns (IWoolf.ApeWolf memory t) {
		t = selectTraits(seed);
		if (existingCombinations[structToHash(t)] == 0) {
			tokenTraits[tokenId] = t;
			existingCombinations[structToHash(t)] = tokenId;
			return t;
		}
		return generate(tokenId, randomPick.random(seed));
	}

	/**
	 * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
	 * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
	 * probability & alias tables are generated off-chain beforehand
	 * @param seed portion of the 256 bit seed to remove trait correlation
	 * @param traitType the trait type to select a trait for
	 * @return the ID of the randomly selected trait
	 */
	function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
		uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
		if (seed >> 8 < rarities[traitType][trait]) return trait;
		return aliases[traitType][trait];
	}

	/**
	 * the first 20% (ETH purchases) go to the minter
	 * the remaining 80% have a 10% chance to be given to a random staked wolf
	 * @param seed a random value to select a recipient from
	 * @return the address of the recipient (either the minter or the Wolf thief's owner)
	 */
	function selectRecipient(uint256 seed) internal view returns (address) {
		uint16 num = 10;
		uint256 count = pool.balanceOf(_msgSender());
		if (count >= LP) {
			num = 5;
		}
		if (minted <= PAID_TOKENS || ((seed >> 245) % 100) > num) return _msgSender(); // top 10 bits haven't been used
		address thief = forest.randomWolfOwner(seed >> 144); // 144 bits reserved for trait selection
		if (thief == address(0x0)) return _msgSender();
		return thief;
	}

	/**
	 * selects the species and all of its traits based on the seed value
	 * @param seed a pseudorandom 256 bit number to derive traits from
	 * @return t -  a struct of randomly selected traits
	 */
	function selectTraits(uint256 seed) internal view returns (IWoolf.ApeWolf memory t) {
		t.isApe = (seed & 0xFFFF) % 10 != 0;
		uint8 shift = t.isApe ? 0 : 6;
		seed >>= 16;
		t.skin = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
		seed >>= 16;
		t.eyes = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
		seed >>= 16;
		t.mouth = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
		seed >>= 16;
		t.clothing = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
		seed >>= 16;
		t.headwear = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
		seed >>= 16;
		t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
	}

	/**
	 * converts a struct to a 256 bit hash to check for uniqueness
	 * @param s the struct to pack into a hash
	 * @return the 256 bit hash of the struct
	 */
	function structToHash(IWoolf.ApeWolf memory s) internal pure returns (uint256) {
		return uint256(bytes32(abi.encodePacked(s.isApe, s.skin, s.eyes, s.mouth, s.clothing, s.headwear, s.alphaIndex)));
	}

	/** READ */

	function getTokenTraits(uint256 tokenId) external view returns (IWoolf.ApeWolf memory) {
		return tokenTraits[tokenId];
	}

	function getPaidTokens() external view returns (uint256) {
		return PAID_TOKENS;
	}

	/** ADMIN */

	/**
	 * called after deployment so that the contract can get random wolf thieves
	 * @param _forest the address of the Forest
	 */
	function setForest(address _forest) external onlyOwner {
		forest = IForest(_forest);
	}

	function setMPeach(address _MPeach) external onlyOwner {
		mutantPeach = MutantPeach(_MPeach);
	}

	function setPool(address _pool) external onlyOwner {
		pool = Pool(_pool);
	}

	function setRandomPick(address _address) external onlyOwner {
		randomPick = RandomPick(_address);
	}

	function setSuperShibaBAMCAddress(address _address) external onlyOwner {
		bamc = ISuperShibaBAMC(_address);
	}

	function setSuperShibaClubAddress(address _address) external onlyOwner {
		club = ISuperShibaClub(_address);
	}

	function setTraits(address _address) external onlyOwner {
		traits = ITraits(_address);
	}

	/**
	 * allows owner to withdraw funds from minting
	 */
	function withdraw() external onlyOwner {
		payable(wolfGameTreasury).transfer(address(this).balance);
	}

	function getTreasure() external view onlyOwner returns (address) {
		return wolfGameTreasury;
	}

	/**
	 * updates the number of tokens for sale
	 */
	function setPaidTokens(uint256 _paidTokens) external onlyOwner {
		PAID_TOKENS = _paidTokens;
	}

	function setLP(uint256 _lp) external onlyOwner {
		LP = _lp;
	}

	function setMint(bool _free, bool _public) external onlyOwner {
		openFreeMint = _free;
		openPublicMint = _public;
	}

	/**
	 * enables owner to pause / unpause minting
	 */
	function setPaused(bool _paused) external onlyOwner {
		if (_paused) _pause();
		else _unpause();
	}

	/** RENDER */

	function setMintPrice(uint256 _price) external onlyOwner {
		MINT_PRICE = _price;
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		return traits.tokenURI(tokenId);
	}

	function setTreasury(address _treasury) external onlyOwner {
		wolfGameTreasury = _treasury;
	}
}