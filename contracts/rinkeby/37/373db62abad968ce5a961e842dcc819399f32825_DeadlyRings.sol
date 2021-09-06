pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: UNLICENSED

import "./ERC721.sol";

/*
	_____                       _   _             _____    _
	|  __ \                     | | | |           |  __ \  (_)
	| |  | |   ___    __ _    __| | | |  _   _    | |__) |  _   _ __     __ _   ___
	| |  | |  / _ \  / _` |  / _` | | | | | | |   |  _  /  | | | '_ \   / _` | / __|
	| |__| | |  __/ | (_| | | (_| | | | | |_| |   | | \ \  | | | | | | | (_| | \__ \
	|_____/   \___|  \__,_|  \__,_| |_|  \__, |   |_|  \_\ |_| |_| |_|  \__, | |___/
										  __/ |							 __/ |
										  |___/						 	 |___/
*/

contract DeadlyRings is ERC721, ReentrancyGuard, Ownable {
	mapping(uint256 => Ring) public Rings;
	constructor() ERC721("The Seven Deadly Rings", "Deadly Ring") {

	/*
	  _____  _           ___   _       _              ___  _
	 |_   _|| |_   ___  |   \ (_)__ __(_) _ _   ___  | _ \(_) _ _   __ _
	   | |  | ' \ / -_) | |) || |\ V /| || ' \ / -_) |   /| || ' \ / _` |
	   |_|  |_||_|\___| |___/ |_| \_/ |_||_||_|\___| |_|_\|_||_||_|\__, |
																   |___/
	*/
		Ring memory TheDivineRing;
		TheDivineRing.Name = "Divine Ring";
		TheDivineRing.Source = "https://sevendeadlyrings.io/wp-content/uploads/2021/09/Divine.gif";
		TheDivineRing.Lore = "The Seven Deadly Rings hold the power of the Great Kings. In my duty to preserve history, I have also resurrected their overwhelming might into this world. To keep those in check, I shall create the Divine Ring, the one to rule them all. This ring is not made out of Adventurer's Gold, but from the sacrifice of a Divine being. Only by burning a Divine Robe for eternity can The Divine Ring be created.";
		TheDivineRing.Active = true;
		TheDivineRing.Forged = false;
		TheDivineRing.Holder = "";
		Rings[0] = TheDivineRing;

	/*
	  _____  _           ___  _                     __   _              _
	 |_   _|| |_   ___  | _ \(_) _ _   __ _   ___  / _| | |   _  _  ___| |_
	   | |  | ' \ / -_) |   /| || ' \ / _` | / _ \|  _| | |__| || |(_-<|  _|
	   |_|  |_||_|\___| |_|_\|_||_||_|\__, | \___/|_|   |____|\_,_|/__/ \__|
									  |___/
	*/
		Ring memory TheRingOfLust;
		TheRingOfLust.Name = "Ring of Lust";
		TheRingOfLust.Source = "https://sevendeadlyrings.io/wp-content/uploads/2021/09/Lust.gif";
		TheRingOfLust.Lore = "Folks should all be aware of the legend of Demon Queen Virgith, Brooding Mother of all the demonkin. A unique being born with the ability to spawn swarms of powerful children by stealing the seeds of other species. It is said that nowadays, every single being in the Demon Realm come from her lineage. But the demons have not always lived secluded in their own plane of existence. Virgith used to wander around the world, gathering the life force of all different species. As she would use it to spawn more children, her army grew more powerful, up to the point where kingdoms could not ignore her anymore. Before she grew too strong, the Coalition banished her and her children to the Demon Realm, where there would be to males to seduce, thwarting her plan to overtake the Chain. Unable to live without sustenance, she withered to her death. Her horns I collected, and out of it, as a memento of her Sin, I shall forge the Ring of Lust.";
		TheRingOfLust.Active = true;
		TheRingOfLust.Forged = false;
		TheRingOfLust.Holder = "";
		Rings[1] = TheRingOfLust;

	/*
	  _____  _           ___  _                     __    ___  _        _    _
	 |_   _|| |_   ___  | _ \(_) _ _   __ _   ___  / _|  / __|| | _  _ | |_ | |_  ___  _ _  _  _
	   | |  | ' \ / -_) |   /| || ' \ / _` | / _ \|  _| | (_ || || || ||  _||  _|/ _ \| ' \| || |
	   |_|  |_||_|\___| |_|_\|_||_||_|\__, | \___/|_|    \___||_| \_,_| \__| \__|\___/|_||_|\_, |
									  |___/                                                 |__/
	*/
		Ring memory TheRingOfGluttony;
		TheRingOfGluttony.Name = "Ring of Gluttony";
		TheRingOfGluttony.Source = "https://sevendeadlyrings.io/wp-content/uploads/2021/09/Gluttony.gif";
		TheRingOfGluttony.Lore = "The Southern Canal, the Celestial Pillar, the Northen Wall.. as many iconic constructions led by Reinod the Builder, king of the dwarves. A ruler with all the quality of the dwarves: skilled, bold, hard worker, just. But like all dwarves, Reinod has always been incapable of magic. Upset that even mere humans were able to do what he never could, he crossed the Four Seas to put his hand on the forbidden Fruit of the Glyphes. Legends say that eating it would give its owner tremendous magic power, no matter what race they belong to. Little did he know that the fruit came with a terrible curse. At the price of his newly found power, Reinod became unable to swim. On his way back to his expedition, he dived off his ship to save a crewmate who fell overboard. They both drowned. The remains of his last meal I have collected, and out of it, as a memento of his Sin, I shall forge the Ring of Gluttony.";
		TheRingOfGluttony.Active = true;
		TheRingOfGluttony.Forged = false;
		TheRingOfGluttony.Holder = "";
		Rings[2] = TheRingOfGluttony;

	/*
	  _____  _           ___  _                     __    ___                    _
	 |_   _|| |_   ___  | _ \(_) _ _   __ _   ___  / _|  / __| _ _  ___  ___  __| |
	   | |  | ' \ / -_) |   /| || ' \ / _` | / _ \|  _| | (_ || '_|/ -_)/ -_)/ _` |
	   |_|  |_||_|\___| |_|_\|_||_||_|\__, | \___/|_|    \___||_|  \___|\___|\__,_|
									  |___/
	*/
		Ring memory TheRingOfGreed;
		TheRingOfGreed.Name = "Ring of Greed";
		TheRingOfGreed.Source = "https://sevendeadlyrings.io/wp-content/uploads/2021/09/Greed.gif";
		TheRingOfGreed.Lore = "From the other races' perspective, never has the human Kingdom thrived as much as under King Gallien, the Cunning's reign. Charisma, military power, and a brilliant mind, as many blessings that allowed him to do what no king ever achieved before: rallying under his banner all of humankind's settlements. After years of conquest, his novel a revolutionary monetary policy allowed the newly founded realm to experience economic growth never seen before. Reducing the adventurer's gold ratio of the national currency to zero ounces per coin, he found a way to supercharge activity at will: by emitting more coins, he realized that the population's response would be to consume and produce more goods almost instantly. After years of prosperity, Gallien would not stop emitting currency. But what he failed to realize was that the prosperity he was creating was, without fail, ultimately ending up in the hands of the long wealthy folks. The inevitable happened: struggling, the commoners lead the Great Revolution. The wealthy and the privileged were beheaded, and King Gallien could not escape his fate. His blood flowing in the gutter I collected, and out of it, as a memento of his Sin, I shall forge the Ring of Greed.";
		TheRingOfGreed.Active = true;
		TheRingOfGreed.Forged = false;
		TheRingOfGreed.Holder = "";
		Rings[3] = TheRingOfGreed;

	/*
	  _____  _           ___  _                     __   ___  _       _    _
	 |_   _|| |_   ___  | _ \(_) _ _   __ _   ___  / _| / __|| | ___ | |_ | |_
	   | |  | ' \ / -_) |   /| || ' \ / _` | / _ \|  _| \__ \| |/ _ \|  _|| ' \
	   |_|  |_||_|\___| |_|_\|_||_||_|\__, | \___/|_|   |___/|_|\___/ \__||_||_|
									  |___/
	*/
		Ring memory TheRingOfSloth;
		TheRingOfSloth.Name = "Ring of Sloth";
		TheRingOfSloth.Source = "https://sevendeadlyrings.io/wp-content/uploads/2021/09/Sloth.gif";
		TheRingOfSloth.Lore = "It is hard to date exactly the downfall of the elven kingdom of Elred the Gentle. Gifted with a natural talent for powerful time contraction magic, Elred had the power to freeze for eternity any of his enemies. Not a single race would dare trespass in the Elven Forest. But as his power grew stronger, his perception of the flow of the Chain became warped. Seconds, days, years: those concepts became obsolete to him. That is how one day, after waking up from his usual communion with nature, he realized that his entire nation was gone, wiped out by centuries of foreign invasions that he could have easily vanquished. In despair, used his powers to accelerate his own time and turn himself into ashes. From those ashes, as a memento of his Sin, I shall forge the Ring of Sloth.";
		TheRingOfSloth.Active = true;
		TheRingOfSloth.Forged = false;
		TheRingOfSloth.Holder = "";
		Rings[4] = TheRingOfSloth;

	/*
	  _____  _           ___  _                     __  __      __           _    _
	 |_   _|| |_   ___  | _ \(_) _ _   __ _   ___  / _| \ \    / /_ _  __ _ | |_ | |_
	   | |  | ' \ / -_) |   /| || ' \ / _` | / _ \|  _|  \ \/\/ /| '_|/ _` ||  _|| ' \
	   |_|  |_||_|\___| |_|_\|_||_||_|\__, | \___/|_|     \_/\_/ |_|  \__,_| \__||_||_|
									  |___/
	*/
		Ring memory TheRingOfWrath;
		TheRingOfWrath.Name = "Ring of Wrath";
		TheRingOfWrath.Source = "https://sevendeadlyrings.io/wp-content/uploads/2021/09/Wrath.gif";
		TheRingOfWrath.Lore = "The giants, while not forming a kingdom strictly speaking, were often considered as a nomad nation that brought devastation in its wake. At the top of their small pack, their leader, Xomohr the Colossus, was the incarnation on strength: his stomp would shake the earth and his first would break mountains. But few knew that the true source of his overwhelming power was in fact his caring heart. The love for his kin and his will to provide for them was what allowed Xomohr to unleash this might comparable to that of the Ancients. One day, after coming early from a hunting expedition, he discovered Calos, his wife, bedding Krobrog, his first lieutenant. As if to protect his own sanity, his consciouness instantly vanished. When he finally gained back clarity, all he found was desolation: his entire tribe stomped, smashed, torn to pieces, and in his hand the lifeless head of his beloved. From his tears were born the Tinted River, and after having cried the last tear out of his body, Xomohr smashed his own skull on the Grand Mountain. From this tear, as a memento of his Sin, I shall forge the Ring of Wrath.";
		TheRingOfWrath.Active = true;
		TheRingOfWrath.Forged = false;
		TheRingOfWrath.Holder = "";
		Rings[5] = TheRingOfWrath;

	/*
	  _____  _           ___  _                     __   ___
	 |_   _|| |_   ___  | _ \(_) _ _   __ _   ___  / _| | __| _ _ __ __ _  _
	   | |  | ' \ / -_) |   /| || ' \ / _` | / _ \|  _| | _| | ' \\ V /| || |
	   |_|  |_||_|\___| |_|_\|_||_||_|\__, | \___/|_|   |___||_||_|\_/  \_, |
									  |___/                             |__/
	*/
		Ring memory TheRingOfEnvy;
		TheRingOfEnvy.Name = "Ring of Envy";
		TheRingOfEnvy.Source = "https://sevendeadlyrings.io/wp-content/uploads/2021/09/Envy.gif";
		TheRingOfEnvy.Lore = "The Brillance. The forgotten deity. An ethereal presence that is said to descend of the Gods. Adored in a time from before the Genesis, there is not a single relic left in our world of its cult: as such, little is known about it. The only knowledge that we have about it come from the gibberish babbles of folks from all races, who seemingly without any connection all became crazy and started muttering incoherent words about The Brillance around the same time. Legends say that The Brillance, jealous of being forgotten in favor of the new idols, infected the minds of the inhabitants of the Chain. Accused of madness, all the people who got struck were burned, but surprisingly, they all left behind a shining substance that seemingly was impervious to fire. Not even one of these madmen remain today: it is said that if it ever was alive, The Brillance has now been killed. I have crystalized as much of its golden remain as I could, and out of it, as a memento of its sin, I shall forge the Ring of Envy.";
		TheRingOfEnvy.Active = true;
		TheRingOfEnvy.Forged = false;
		TheRingOfEnvy.Holder = "";
		Rings[6] = TheRingOfEnvy;

	/*
	  _____  _           ___  _                     __   ___       _     _
	 |_   _|| |_   ___  | _ \(_) _ _   __ _   ___  / _| | _ \ _ _ (_) __| | ___
	   | |  | ' \ / -_) |   /| || ' \ / _` | / _ \|  _| |  _/| '_|| |/ _` |/ -_)
	   |_|  |_||_|\___| |_|_\|_||_||_|\__, | \___/|_|   |_|  |_|  |_|\__,_|\___|
									  |___/
	*/
		Ring memory TheRingOfPride;
		TheRingOfPride.Name = "Ring of Pride";
		TheRingOfPride.Source = "https://sevendeadlyrings.io/wp-content/uploads/2021/09/Pride.gif";
		TheRingOfPride.Lore = "No one could have been more suited to claim the title of strongest creature on the Chain than Yrmas the Eternal, Queen of the dragonborn. She was last true Elder Dragon, and some tales claim that her birth precedes the Genesis itself. Her vitriol breath could melt entire cities in an instant, a single flap of her wings could send whirlwinds across entire realms. Unmatched in Heaven and Earth, it was only natural for her that she would attempt to defy the Rules of the Chain, and ascend Godhood. Alongside her people, she tried the taboo: using their extreme intellect, and humongous brute force, they attempted to re-organize the flow of the world itself. But there, she only met darkness. The immutable Rules of the Chain erased her and her kin's soul out of existence, leaving only empty carcasses on the physical realm, living but will-less. Her heart still beating I carved out, and out of it, as a memento of her Sin, I shall forge the Ring of Pride.";
		TheRingOfPride.Active = true;
		TheRingOfPride.Forged = false;
		TheRingOfPride.Holder = "";
		Rings[7] = TheRingOfPride;

		_safeMint(address(this), 0);
		_safeMint(address(this), 1);
		_safeMint(address(this), 2);
		_safeMint(address(this), 3);
		_safeMint(address(this), 4);
		_safeMint(address(this), 5);
		_safeMint(address(this), 6);
		_safeMint(address(this), 7);
	}

	struct Ring {
		string Name;
		string Lore;
		string Holder;
		string Source;
		bool Forged;
		bool Active;
	}

	uint256 public ForgeOpensAt = 1630944000;
	function IsForgeOpen() public view returns (bool) {
		if (block.timestamp >= ForgeOpensAt) {
			return true;
		}
		return false;
	}

	/*
		The Divine Ring
		A Divine Robe must be sacrificed to invoke The Divine Ring
	*/

	event TheDivineRingHasBeenForged(address Holder);
	function ForgeTheDivineRing(uint256 LootID) public {
		require(IsForgeOpen(), "The Forge is not yet open.");
		require(!IsForged(0), string(abi.encodePacked("The ", NameOf(0), " is already forged.")));
		require(IsDivineRobeOwner(LootID, msg.sender), "Requires a Divine Robe sacrifice.");
		LootContract.safeTransferFrom(msg.sender, BurnAddress, LootID);
		Rings[0].Forged = true;
		_transfer(address(this), msg.sender, 0);
		emit TheDivineRingHasBeenForged(msg.sender);
	}

	function TheDivineRingHolder() public view returns (string memory) {
		return HolderOf(0);
	}

	function TheDivineRingLore() public view returns (string memory) {
		return LoreOf(0);
	}

	function NewDivineRingHolderName(string memory Holder) public {
		require(ownerOf(0) == msg.sender, string(abi.encodePacked("You are not the owner of The ", NameOf(0), ".")));
		Rings[0].Holder = Holder;
	}

	/*
		The Seven Deadly Rings
		Gold must be melted to forge a Deadly Ring
	*/

	uint256 public GoldsForADeadlyRing = 7777000000000000000000; // 7777 AGLD
	address public GoldsAddress = 0x32353A6C91143bfd6C7d363B546e62a9A2489A20; // Adventure Gold

	function TheDeadlyRingHolder(uint256 RingID) public view returns (string memory) {
		return HolderOf(RingID);
	}

	function TheDeadlyRingLore(uint256 RingID) public view returns (string memory) {
		return LoreOf(RingID);
	}

	event ADeadlyRingHasBeenForged(address Holder, uint256 RingID);
	function ForgeTheDeadlyRing(uint256 RingID) public {
		require(IsForgeOpen(), "The Forge is not yet open.");
		require(!IsForged(RingID), string(abi.encodePacked("The ", NameOf(RingID), " is already forged.")));
		require(ERC20(GoldsAddress).transferFrom(msg.sender, address(this), GoldsForADeadlyRing), "Gold must be melted to forge a Deadly Ring.");
		require(ERC20(GoldsAddress).transfer(owner(), GoldsForADeadlyRing), "An error occured while transferring golds.");
		Rings[RingID].Forged = true;
		_transfer(address(this), msg.sender, RingID);
		emit ADeadlyRingHasBeenForged(msg.sender, RingID);
	}

	/*
		Loot (for Adventurers)
	*/

	address public LootContractAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
	address BurnAddress = 0x000000000000000000000000000000000000dEaD;
	LootInterface LootContract = LootInterface(LootContractAddress);

	function IsLootOwner(uint256 ID, address Caller) internal view returns (bool) {
		if (LootContract.ownerOf(ID) == Caller) {
			return true;
		}
		return false;
	}

	function IsDivineRobeOwner(uint256 ID, address Caller) internal view returns (bool) {
		if (!IsLootOwner(ID, Caller)) {
			return false;
		}
		return utils.contains(utils.toSlice(LootContract.getChest(ID)), utils.toSlice("Divine Robe"));
	}

	/*
		The Sin Forger
	*/

	function NewDeadlyRingHolderName(uint256 RingID, string memory Holder, uint256 LootID) public {
		require(ownerOf(RingID) == msg.sender, string(abi.encodePacked("You are not the owner of The ", NameOf(RingID), ".")));
		require(IsLootOwner(LootID, msg.sender), "You are not the owner of this Loot bag.");
		Rings[RingID].Holder = Holder;
	}

	function ActiveTheRing(uint256 RingID) public {
		require(IsForged(RingID), string(abi.encodePacked("The ", NameOf(RingID), " has not been forged yet.")));
		require(ownerOf(0) == msg.sender || ownerOf(RingID) == msg.sender, string(abi.encodePacked("You are not The ", NameOf(0), " or The ", NameOf(RingID), " owner.")));
		Rings[RingID].Active = true;
	}

	function HideTheRing(uint256 RingID) public {
		require(IsForged(RingID), string(abi.encodePacked("The ", NameOf(RingID), " has not been forged yet.")));
		require(ownerOf(0) == msg.sender || ownerOf(RingID) == msg.sender, string(abi.encodePacked("You are not The ", NameOf(0), " or The ", NameOf(RingID), " owner.")));
		Rings[RingID].Active = false;
	}

	function IsForged(uint256 RingID) public view returns (bool) {
		return Rings[RingID].Forged;
	}

	function NRHM(uint256 RingID) public {
		require(address(this) == msg.sender, string(abi.encodePacked("This can only happen if The ", NameOf(RingID) ," changes ownership.")));
		Rings[RingID].Holder = "";
	}

	function LoreOf(uint256 RingID) internal view returns (string memory) {
		return Rings[RingID].Lore;
	}

	function SourceOf(uint256 RingID) internal view returns (string memory) {
		return Rings[RingID].Source;
	}

	function HolderOf(uint256 RingID) internal view returns (string memory) {
		return Rings[RingID].Holder;
	}

	function IsActive(uint256 RingID) internal view returns (bool) {
		return Rings[RingID].Active;
	}

	function NameOf(uint256 RingID) internal view returns (string memory) {
		return Rings[RingID].Name;
	}

	function tokenURI(uint256 tokenId) override public view returns (string memory) {
		string memory Name;
		string memory Image;
		string memory Description = LoreOf(tokenId);
		if (!IsForged(tokenId)) {
			Name = string(abi.encodePacked("Unforged ", NameOf(tokenId)));
		} else if (!utils.compareStrings(HolderOf(tokenId), "")) {
			Name = string(abi.encodePacked(HolderOf(tokenId), "'s ", NameOf(tokenId)));
		} else {
			Name = string(abi.encodePacked("The ", NameOf(tokenId)));
		}
		if (IsActive(tokenId)) {
			Image = SourceOf(tokenId);
		} else {
			string memory SVG;
			if (utils.compareStrings(HolderOf(tokenId), "")) {
				string[3] memory SVGParts;
				SVGParts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
				SVGParts[1] = string(abi.encodePacked("The ", NameOf(tokenId)));
				SVGParts[2] = '</text></svg>';
				SVG = string(abi.encodePacked(SVGParts[0], SVGParts[1], SVGParts[2]));
			} else {
				string[5] memory SVGParts;
				SVGParts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
				SVGParts[1] = string(abi.encodePacked("The ", NameOf(tokenId)));
				SVGParts[2] = '</text><text x="10" y="40" class="base">';
				SVGParts[3] = string(abi.encodePacked("Holder : ", HolderOf(tokenId)));
				SVGParts[4] = '</text></svg>';
				SVG = string(abi.encodePacked(SVGParts[0], SVGParts[1], SVGParts[2], SVGParts[3], SVGParts[4]));
			}
			Image = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(SVG))));
		}
		string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', Name, '", "description": "', Description ,'", "image": "', Image,'"}'))));
		string memory output = string(abi.encodePacked('data:application/json;base64,', json));
		return output;
	}

	function ForgerSetSourceOf(uint256 RingID, string memory Source) public onlyOwner {
		Rings[RingID].Source = Source;
	}

	function ForgerSetLoreOf(uint256 RingID, string memory Lore) public onlyOwner {
		Rings[RingID].Lore = Lore;
	}

	function WD() public onlyOwner {
		msg.sender.transfer(address(this).balance);
	}

	function AT(address Contract, address Spender, uint256 Amount) public onlyOwner {
		ERC20(Contract).approve(Spender, Amount);
	}

	function GT(address Contract, uint Amount) public onlyOwner {
		ERC20(Contract).transfer(msg.sender, Amount);
	}
}

library utils {
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

	function compareStrings(string memory a, string memory b) internal pure returns (bool) {
		return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
	}

	function contains(slice memory self, slice memory needle) internal pure returns (bool) {
		return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
	}

	function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
		uint ptr;

		if (needlelen <= selflen) {
			if (needlelen <= 32) {
				bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

				bytes32 needledata;
				assembly { needledata := and(mload(needleptr), mask) }

				ptr = selfptr + selflen - needlelen;
				bytes32 ptrdata;
				assembly { ptrdata := and(mload(ptr), mask) }

				while (ptrdata != needledata) {
					if (ptr <= selfptr)
						return selfptr;
					ptr--;
					assembly { ptrdata := and(mload(ptr), mask) }
				}
				return ptr + needlelen;
			} else {
				// For long needles, use hashing
				bytes32 hash;
				assembly { hash := keccak256(needleptr, needlelen) }
				ptr = selfptr + (selflen - needlelen);
				while (ptr >= selfptr) {
					bytes32 testHash;
					assembly { testHash := keccak256(ptr, needlelen) }
					if (hash == testHash)
						return ptr + needlelen;
					ptr -= 1;
				}
			}
		}
		return selfptr;
	}

	function toSlice(string memory self) internal pure returns (slice memory) {
		uint ptr;
		assembly {
			ptr := add(self, 0x20)
		}
		return slice(bytes(self).length, ptr);
	}

	struct slice {
		uint _len;
		uint _ptr;
	}
}

interface LootInterface {
	function safeTransferFrom(address, address, uint256) external;
	function ownerOf(uint256) external view returns (address);
	function getChest(uint256) external view returns (string memory);
}

interface ERC20 {
	function transfer(address, uint256) external returns (bool);
	function approve(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
}