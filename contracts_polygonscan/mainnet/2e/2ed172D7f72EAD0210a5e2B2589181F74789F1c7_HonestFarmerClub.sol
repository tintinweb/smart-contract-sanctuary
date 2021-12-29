// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 *
 *  __    __   ______   __       __  _______   __      __
 * 	/  |  /  | /      \\ /  |  _  /  |/       \\ /  \\    /  |
 * 	$$ |  $$ |/$$$$$$  |$$ | / \\ $$ |$$$$$$$  |$$  \\  /$$/
 * 	$$ |__$$ |$$ |  $$ |$$ |/$  \\$$ |$$ |  $$ | $$  \\/$$/
 * 	$$    $$ |$$ |  $$ |$$ /$$$  $$ |$$ |  $$ |  $$  $$/
 * 	$$$$$$$$ |$$ |  $$ |$$ $$/$$ $$ |$$ |  $$ |   $$$$/
 * 	$$ |  $$ |$$ \\__$$ |$$$$/  $$$$ |$$ |__$$ |    $$ |
 * 	$$ |  $$ |$$    $$/ $$$/    $$$ |$$    $$/     $$ |
 * 	$$/   $$/  $$$$$$/  $$/      $$/ $$$$$$$/      $$/
 *
 * Just some honest farmers loving open source software. Checks CREDITS.md in our repository!
 *
 */

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./IWhitelist.sol";
import "./IHonestTraits.sol";

enum MintToken {
	MATIC
}

contract HonestFarmerClub is ERC1155, Ownable {
	/**
	 * State
	 */
	bool public _mintIsLive = false;
	bool public _whitelistMintIsLive = false;
	uint256 public MAX_FARMER_SUPPLY = 3000;
	uint8 public numberOfHonestFriends = 30;
	uint256 public numberOfHonestFriendsAllocationMinted = 0;
	uint256 public mintTxWhaleCap = 10;

	string public name = "Honest Farmer Club";
	string public symbol = "HFC";
	uint256 public tokenCount;
	string public baseUri;
	string public _contractURI;

	/**
	 * Onchain config
	 */
	using Counters for Counters.Counter;
	Counters.Counter public _tokenIds;
	IWhitelist public whitelist;
	IHonestTraits public traits;

	/**
	 * @dev Price of mint in respective token, with 10 ** 8 decimals
	 * e.g. 1 MATIC = 1 * 10 ** 18
	 */
	mapping(MintToken => uint256) public mintPriceByMintToken;
	mapping(MintToken => uint256) public mintPriceByMintTokenWhitelist;

	constructor(
		string memory _uri,
		string memory _initialContractURI,
		IWhitelist _whitelist,
		IHonestTraits _traits
	) ERC1155(_uri) {
		whitelist = _whitelist;
		_contractURI = _initialContractURI;
		traits = _traits;
		baseUri = _uri;
	}

	/**
	 * Access control
	 */
	modifier mintIsLive() {
		if (_mintIsLive) {
			_;
		}
	}

	modifier whiteListMintIsLive() {
		if (_whitelistMintIsLive) {
			_;
		}
	}

	modifier hasSetMintPrice() {
		if (mintPriceByMintToken[MintToken.MATIC] > 0) {
			_;
		}
	}

	/**
	 * Minting
	 */
	function mintFarmers(address to, uint256 numberOfHonestFarmers) private {
		require(
			((numberOfHonestFarmers + tokenCount) <= MAX_FARMER_SUPPLY),
			"Mint would exceed max farmer supply"
		);

		uint256[] memory ids = new uint256[](numberOfHonestFarmers);
		uint256[] memory amounts = new uint256[](numberOfHonestFarmers);

		for (uint256 i = 0; i < numberOfHonestFarmers; i++) {
			_tokenIds.increment();
			uint256 id = _tokenIds.current();

			ids[i] = id;
			amounts[i] = 1;
		}

		_mintBatch(to, ids, amounts, "");
		tokenCount += numberOfHonestFarmers;
	}

	/**
	 * Public mint
	 */
	function _mintPayable(
		uint256 numberOfHonestFarmers,
		uint256 paidMintTokenAmount,
		MintToken mintToken
	) private {
		require(
			paidMintTokenAmount >=
				getTotalTokenPayableAmount(
					mintToken,
					numberOfHonestFarmers,
					false
				),
			"Not enough tokens paid"
		);
		require(
			numberOfHonestFarmers <= mintTxWhaleCap,
			"No whales in here, sorry"
		);

		mintFarmers(msg.sender, numberOfHonestFarmers);
	}

	function mintMATIC(uint256 numberOfHonestFarmers)
		public
		payable
		mintIsLive
	{
		_mintPayable(numberOfHonestFarmers, msg.value, MintToken.MATIC);
	}

	/**
	 * Whitelist mint
	 */
	function _mintPayableWhitelist(
		uint256 numberOfHonestFarmers,
		uint256 paidMintTokenAmount,
		MintToken mintToken
	) private {
		require(
			paidMintTokenAmount >=
				getTotalTokenPayableAmount(
					mintToken,
					numberOfHonestFarmers,
					true
				),
			"Not enough tokens paid"
		);

		mintFarmers(msg.sender, numberOfHonestFarmers);
		whitelist.decreaseAllocation(msg.sender, numberOfHonestFarmers);
	}

	function mintMATICWhitelist(uint256 numberOfHonestFarmers)
		public
		payable
		whiteListMintIsLive
	{
		uint256 allocation = whitelist.getAllocation(msg.sender);
		require(
			allocation >= numberOfHonestFarmers,
			"Whitelist allocation exceeded"
		);

		_mintPayableWhitelist(
			numberOfHonestFarmers,
			msg.value,
			MintToken.MATIC
		);
	}

	/**
	 * Friends & family
	 */
	function mintFriendsAndFamilyAllocation() public onlyOwner {
		require(
			numberOfHonestFriendsAllocationMinted < numberOfHonestFriends,
			"Allocation already minted"
		);

		mintFarmers(msg.sender, numberOfHonestFriends);
		numberOfHonestFriendsAllocationMinted = numberOfHonestFriends;
	}

	/**
	 * Free farmers
	 */
	function mintFreeFarmers() public whiteListMintIsLive {
		uint256 freeFarmerAllocation = whitelist.getFreeFarmerAllocation(
			msg.sender
		);
		require(freeFarmerAllocation > 0, "Allocation already minted");

		mintFarmers(msg.sender, freeFarmerAllocation);
		whitelist.removeFreeFarmerAllocation(msg.sender);
	}

	function withdrawFunds() public onlyOwner {
		uint256 maticBalance = address(this).balance;
		payable(msg.sender).transfer(maticBalance);
	}

	/**
	 * Utilities
	 */
	function uri(uint256 tokenId) public view override returns (string memory) {
		return traits.uri(tokenId);
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function updateContractUri(string memory newContractUri) public onlyOwner {
		_contractURI = newContractUri;
	}

	function setMintPrices(
		uint256 mintPriceMATIC,
		uint256 mintPriceMATICWhitelist
	) public onlyOwner {
		// Public
		mintPriceByMintToken[MintToken.MATIC] = mintPriceMATIC;

		// Whitelist
		mintPriceByMintTokenWhitelist[
			MintToken.MATIC
		] = mintPriceMATICWhitelist;
	}

	function getTotalTokenPayableAmount(
		MintToken mintToken,
		uint256 numberOfHonestFarmers,
		bool isWhitelist
	) public view returns (uint256) {
		if (isWhitelist) {
			return
				mintPriceByMintTokenWhitelist[mintToken] *
				uint256(numberOfHonestFarmers);
		}

		return mintPriceByMintToken[mintToken] * uint256(numberOfHonestFarmers);
	}

	function getWhitelistAllocation(address _address)
		public
		view
		returns (uint256)
	{
		return whitelist.getAllocation(_address);
	}

	function getFreeFarmerAllocation(address _address)
		public
		view
		returns (uint256)
	{
		return whitelist.getFreeFarmerAllocation(_address);
	}

	function addToWhitelist(address _address) public onlyOwner {
		whitelist.addToWhitelist(_address);
	}

	function addToWhitelistBatch(address[] memory _addresses) public onlyOwner {
		whitelist.addToWhitelistBatch(_addresses);
	}

	function removeFromWhitelist(address _address) public onlyOwner {
		whitelist.removeFromWhitelist(_address);
	}

	function removeFromWhitelistBatch(address[] memory _addresses)
		public
		onlyOwner
	{
		whitelist.removeFromWhitelistBatch(_addresses);
	}

	function addFreeFarmerAllocation(address _address, uint256 amount)
		public
		onlyOwner
	{
		whitelist.addFreeFarmerAllocation(_address, amount);
	}

	function addFreeFarmerAllocationBatch(
		address[] memory _addresses,
		uint256[] memory amounts
	) public onlyOwner {
		whitelist.addFreeFarmerAllocationBatch(_addresses, amounts);
	}

	function removeFreeFarmerAllocation(address _address) public onlyOwner {
		whitelist.removeFreeFarmerAllocation(_address);
	}

	function removeFreeFarmerAllocationBatch(address[] memory _addresses)
		public
		onlyOwner
	{
		whitelist.removeFreeFarmerAllocationBatch(_addresses);
	}

	function toggleMintIsLive() public onlyOwner hasSetMintPrice {
		_mintIsLive = !_mintIsLive;
	}

	function toggleWhitelistMintIsLive() public onlyOwner hasSetMintPrice {
		_whitelistMintIsLive = !_whitelistMintIsLive;
	}
}