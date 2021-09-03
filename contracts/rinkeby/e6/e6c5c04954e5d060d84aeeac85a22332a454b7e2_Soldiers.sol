pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: UNLICENSED

import "./ERC721.sol";

contract Soldiers is ERC721, ReentrancyGuard, Ownable {
	using SafeMath for uint256;

	constructor() ERC721("Soldier Loot", "Soldier") {}
	address public lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
	LootInterface lootContract = LootInterface(lootAddress);

	string public PROVENANCE = "";

	uint256 public maxSupply = 14000;
	uint256 public currentSupply = 0;

	uint256 public lootersPrice = 30000000000000000; // 0.03 ETH
	uint256 public publicPrice = 90000000000000000; // 0.09 ETH

	string[] private branch = [
		"Army", "Army", "Army",
		"Space Corp",
		"Air Force", "Air Force",
		"Marine Corp", "Marine Corp",
		"Navy", "Navy", "Navy",
		"Coast Guard", "Coast Guard", "Coast Guard"
	];
	string[] private country = [
		"German", "German",
		"British", "British", "British",
		"French", "French",
		"American", "American", "American",
		"Canadian", "Canadian",
		"Mexican", "Mexican",
		"Russian", "Russian",
		"Chinese", "Chinese", "Chinese",
		"Italian", "Italian",
		"Japanese", "Japanese", "Japanese",
		"Australian", "Australian", "Australian",
		"Taliban"
	          ];

	string[] private primary = [
		"M16 Assault Rifle", "M16 Assault Rifle", "M16 Assault Rifle", "M16 Assault Rifle", 
		"HK417 Battle Rifle", "HK417 Battle Rifle", 
		"M40 Sniper Rifle", "M40 Sniper Rifle", "M40 Sniper Rifle", 
		"M14 Rifle", "M14 Rifle", 
		"M82 .50 Cal", 
		"M249 Light Machine Gun", "M249 Light Machine Gun", "M249 Light Machine Gun", 
		"FN SCAR", 
		"RPG", "RPG", 
		"AK-47", "AK-47", "AK-47", "AK-47"
	];
	string[] private primaryPrefix = ["Rusty", "New", "Old", "Pristine", "Regular", "Regular", "Regular", "Scratched", "Disassembled", "Broken", "Worn"];

	string[] private secondary = [
		"Beretta M9", "Beretta M9", "Beretta M9",
		"SIG Sauer P228", "SIG Sauer P228",
		"Glock 17", "Glock 17", "Glock 17",
		"M1911"
	];
	string[] private secondaryPrefix = ["Rusty", "New", "Old", "Pristine", "Regular", "Regular", "Regular", "Scratched", "Disassembled", "Broken", "Worn"];

	string[] private equipment = [
		"Claymore", "Claymore", 
		"Frag Grenade", "Frag Grenade", "Frag Grenade",
		"Molotov Cocktail", 
		"C4", "C4", 
		"Flash Grenade", "Flash Grenade", 
		"Stun Grenade", "Stun Grenade", 
		"Smoke Grenade", "Smoke Grenade", "Smoke Grenade"
	];
	string[] private equipmentPrefix = [""];

	function getBranch(uint256 tokenId) public view returns (string memory) {
		return pluck(tokenId, "Branch", branch, country);
	}

	function getPrimary(uint256 tokenId) public view returns (string memory) {
		return pluck(tokenId, "Primary", primary, primaryPrefix);
	}

	function getSecondary(uint256 tokenId) public view returns (string memory) {
		return pluck(tokenId, "Secondary", secondary, secondaryPrefix);
	}

	function getEquipment(uint256 tokenId) public view returns (string memory) {
		return pluck(tokenId, "Equipment", equipment, equipmentPrefix);
	}

	function getFullDescription(uint256 tokenId) public view returns (string memory) {
		return string(abi.encodePacked(
			getBranch(tokenId), " + ",
			getPrimary(tokenId), " + ",
			getSecondary(tokenId), " + ",
			getEquipment(tokenId)
		));
	}

	function random(string memory input) public pure returns (uint256) {
		return uint256(keccak256(abi.encodePacked(input))) % 31;
	}

	function pluckRoll(uint256 tokenId, string memory keyPrefix) internal pure returns (string memory) {
		uint256 roll1 = random(string(abi.encodePacked(keyPrefix, toString(tokenId), "1")));
		uint256 min = roll1;
		uint256 roll2 = random(string(abi.encodePacked(keyPrefix, toString(tokenId), "2")));
		min = min > roll2 ? roll2 : min;
		uint256 roll3 = random(string(abi.encodePacked(keyPrefix, toString(tokenId), "3")));
		min = min > roll3 ? roll3 : min;
		uint256 roll4 = random(string(abi.encodePacked(keyPrefix, toString(tokenId), "4")));
		min = min > roll4 ? roll4 : min;

		// get 3 highest dice rolls
		uint256 stat = roll1 * roll2 * roll3 + roll4 + roll3 - min;

		string memory output = string(abi.encodePacked(toString(stat)));

		return output;
	}

	function pluck(
		uint256 tokenId,
		string memory keyPrefix,
		string[] memory sourceArray,
		string[] memory prefixes
	) internal view returns (string memory) {
		uint256 randA = random(
			string(abi.encodePacked(keyPrefix, toString(tokenId*7)))
		);
		uint256 randB = random(
			string(abi.encodePacked(keyPrefix, toString(tokenId*4)))
		);

		string memory output = sourceArray[randA % sourceArray.length];
		output = string(
			abi.encodePacked(prefixes[randB % prefixes.length], " ", output)
		);

		string memory actual = string(abi.encodePacked(output));
		return actual;
	}

	function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		msg.sender.transfer(balance);
	}

	function deposit() public payable onlyOwner {}


	function setLootersPrice(uint256 newPrice) public onlyOwner {
		lootersPrice = newPrice;
	}

	function setPublicPrice(uint256 newPrice) public onlyOwner {
		publicPrice = newPrice;
	}

	function setBaseURI(string memory baseURI) public onlyOwner {
		_setBaseURI(baseURI);
	}

	function setProvenance(string memory prov) public onlyOwner {
		PROVENANCE = prov;
	}

	// Loot owners minting
	function mintWithLoot(uint lootId) public payable nonReentrant {
		require(lootContract.ownerOf(lootId) == msg.sender, "This Loot is not owned by the minter");
		require(lootersPrice <= msg.value, "Not enough Ether sent");
		require(currentSupply < maxSupply, "All soldiers are minted");
		_safeMint(msg.sender, currentSupply);
		currentSupply += 1;
	}

	// Public minting
	function mint() public payable nonReentrant {
		require(publicPrice <= msg.value, "Not enough Ether sent");
		require(currentSupply < maxSupply, "All soldiers are minted");

		_safeMint(msg.sender, currentSupply);
		currentSupply += 1;
	}

	function toString(uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}

	function tokenURI(uint256 tokenId) override public view returns (string memory) {
		string[9] memory parts;
		parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

		parts[1] = getBranch(tokenId);

		parts[2] = '</text><text x="10" y="40" class="base">';

		parts[3] = getPrimary(tokenId);

		parts[4] = '</text><text x="10" y="60" class="base">';

		parts[5] = getSecondary(tokenId);

		parts[6] = '</text><text x="10" y="80" class="base">';

		parts[7] = getEquipment(tokenId);

		parts[8] = '</text></svg>';

		string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));

		string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Soldier #', toString(tokenId), '", "description": "Soldier Loot is randomized military gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Soldier Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
		output = string(abi.encodePacked('data:application/json;base64,', json));

		return output;
	}
}