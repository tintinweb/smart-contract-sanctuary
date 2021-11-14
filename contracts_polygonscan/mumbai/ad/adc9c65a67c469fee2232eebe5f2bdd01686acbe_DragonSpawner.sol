/**
 *Submitted for verification at polygonscan.com on 2021-11-13
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-Imported-License-Identifier: MIT

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


// File @openzeppelin/contracts/access/[email protected]

// SPDX-Imported-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/nft/DragonSpawner.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IINft {
    function mintNFT(address to, uint256 id) external;

    function mintNFTBatch(address to, uint256[] memory ids) external;
}

contract DragonSpawner is Ownable {
    // 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111
    // 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111110000000000000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000000000000000000000000000011111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    // 11111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

    // Metadata bitmap:

    // 0 to 63 (64 bits: 0 to 18446744073709551615) id
    uint256 constant ID_SHIFT = 0;
    uint256 constant ID_LENGTH = 64;
    // 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111
    uint256 constant ID_MASK = 0x000000000000000000000000000FFFFFFFFFFFFFFFF;

    // 64 to 71 (8 bits: 0 to 255) chain
    uint256 constant CHAIN_SHIFT = ID_SHIFT + ID_LENGTH;
    uint256 constant CHAIN_LENGTH = 8;
    // 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000000000000000
    uint256 constant CHAIN_MASK = 0x0000000000000000000000000FF0000000000000000;

    // 72 to 72 (1 bit: 0 to 1) fungible
    uint256 constant FUNGIBLE_SHIFT = CHAIN_SHIFT + CHAIN_LENGTH;
    uint256 constant FUNGIBLE_LENGTH = 1;
    // 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant FUNGIBLE_MASK =
        0x0000000000000000000000001000000000000000000;

    // 73 to 88 (16 bits: 0 to 65535) _type
    uint256 constant TYPE_SHIFT = FUNGIBLE_SHIFT + FUNGIBLE_LENGTH;
    uint256 constant TYPE_LENGTH = 16;
    // 00000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111110000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant TYPE_MASK = 0x000000000000000000001FFFE000000000000000000;

    // 89 to 96 (8 bits: 0 to 255) version
    uint256 constant VERSION_SHIFT = TYPE_SHIFT + TYPE_LENGTH;
    uint256 constant VERSION_LENGTH = 8;
    // 00000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant VERSION_MASK =
        0x0000000000000000001FE0000000000000000000000;

    // Dragon bitmap:

    // 97 to 112 (16 bits: 0 to 65535) card
    uint256 constant CARD_SHIFT = VERSION_SHIFT + VERSION_LENGTH;
    uint256 constant CARD_LENGTH = 16;
    // 00000000000000000000000000000000000000000000000000000000011111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant CARD_MASK = 0x000000000000001FFFE000000000000000000000000;

    // 113 to 120 (8 bits: 0 to 255) magic
    uint256 constant MAGIC_SHIFT = CARD_SHIFT + CARD_LENGTH;
    uint256 constant MAGIC_LENGTH = 8;
    // 00000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant MAGIC_MASK = 0x0000000000001FE0000000000000000000000000000;

    // 121 to 128 (8 bits: 0 to 255) rarity
    uint256 constant RARITY_SHIFT = MAGIC_SHIFT + MAGIC_LENGTH;
    uint256 constant RARITY_LENGTH = 8;
    // 00000000000000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant RARITY_MASK =
        0x00000000001FE000000000000000000000000000000;

    // 129 to 136 (8 bits: 0 to 255) species
    uint256 constant SPECIES_SHIFT = RARITY_SHIFT + RARITY_LENGTH;
    uint256 constant SPECIES_LENGTH = 8;
    // 00000000000000000000000000000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant SPECIES_MASK =
        0x000000001FE00000000000000000000000000000000;

    // 137 to 144 (8 bits: 0 to 255) lifestage
    uint256 constant LIFESTAGE_SHIFT = SPECIES_SHIFT + SPECIES_LENGTH;
    uint256 constant LIFESTAGE_LENGTH = 8;
    // 00000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant LIFESTAGE_MASK =
        0x0000001FE0000000000000000000000000000000000;

    // 145 to 145 (1 bit: 0 to 1) fly
    uint256 constant FLY_SHIFT = LIFESTAGE_SHIFT + LIFESTAGE_LENGTH;
    uint256 constant FLY_LENGTH = 1;
    // 00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant FLY_MASK = 0x0000002000000000000000000000000000000000000;

    // 146 to 153 (8 bits: 0 to 255) attack
    uint256 constant ATTACK_SHIFT = FLY_SHIFT + FLY_LENGTH;
    uint256 constant ATTACK_LENGTH = 8;
    // 00000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant ATTACK_MASK =
        0x00003FC000000000000000000000000000000000000;

    // 154 to 170 (16 bits: 0 to 65535) defence
    uint256 constant DEFENCE_SHIFT = ATTACK_SHIFT + ATTACK_LENGTH;
    uint256 constant DEFENCE_LENGTH = 16;
    // 11111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 constant DEFENCE_MASK =
        0x3FFFC00000000000000000000000000000000000000;

    uint256 constant BASE_CHANCE = 5000;
    uint256 constant LEGENDARY = 1; // 1/5,000
    uint256 constant ULTRARARE = LEGENDARY + 2; // 1/2,500 = 2/5,000
    uint256 constant RARE = ULTRARARE + 50; // 1/100 = 50/5,000
    uint256 constant UNCOMMON = RARE + 200; // 1/25 = 200/5,000

    IINft immutable _INft;
    uint256 private nonce;

    constructor(IINft INft_) {
        _INft = INft_;
    }

    function tokenToStats(uint256 token)
        public
        pure
        returns (
            uint16 card,
            uint8 magic,
            uint8 rarity,
            uint8 lifestage,
            uint8 species,
            uint8 fly,
            uint8 attack,
            uint16 defence,
            uint8 chain,
            uint8 fungible,
            uint16 type_,
            uint8 version,
            uint64 id
        )
    {
        card = uint16((token & CARD_MASK) >> CARD_SHIFT);
        magic = uint8((token & MAGIC_MASK) >> MAGIC_SHIFT);
        rarity = uint8((token & RARITY_MASK) >> RARITY_SHIFT);
        lifestage = uint8((token & LIFESTAGE_MASK) >> LIFESTAGE_SHIFT);
        species = uint8((token & SPECIES_MASK) >> SPECIES_SHIFT);
        fly = uint8((token & FLY_MASK) >> FLY_SHIFT);
        attack = uint8((token & ATTACK_MASK) >> ATTACK_SHIFT);
        defence = uint16((token & DEFENCE_MASK) >> DEFENCE_SHIFT);
        id = uint64(token & ID_MASK);
        chain = uint8((token & CHAIN_MASK) >> CHAIN_SHIFT);
        fungible = uint8((token & FUNGIBLE_MASK) >> FUNGIBLE_SHIFT);
        type_ = uint16((token & TYPE_MASK) >> TYPE_SHIFT);
        version = uint8((token & VERSION_MASK) >> VERSION_SHIFT);
        require(chain == 0, "Not a Polygon token");
        require(fungible == 1, "Not an NFT");
        require(type_ == 2, "Not a dragon");
        require(version == 0, "Unknown version");
        require(card >= 2 && card <= 301, "Invalid card number");
        require(magic >= 2 && magic <= 30, "Invalid magic");
        require(rarity >= 0 && rarity <= 4, "Invalid rarity");
        require(lifestage >= 0 && lifestage <= 2, "Invalid lifestage");
        require(species >= 0 && lifestage <= 9, "Invalid species");
        require(fly >= 0 && fly <= 1, "Invalid fly");
        require(attack >= 14 && attack <= 150, "Invalid attack");
        require(defence >= 15 && defence <= 300, "Invalid defence");
    }

    function cardToToken(uint256 card_) public pure returns (uint256 token) {
        require(card_ >= 2 && card_ <= 301, "Invalid card number");

        // Card is the zero-based equivalent of card_.
        uint256 card = card_;
        card_ -= 2;

        // Take advantage of integer math to get the rarity (60 in each category).
        uint256 rarity = card_ / 60;

        // Calculate the lifestage based on card number.
        uint256 lifestageIndex = card_;
        while (lifestageIndex >= 60) lifestageIndex -= 60;
        uint256 lifestage = lifestageIndex / 20;

        // Calculate the species based on lifestage index.
        uint256 speciesIndex = lifestageIndex;
        while (speciesIndex >= 20) speciesIndex -= 20;
        uint256 species = speciesIndex / 2;

        // Dragons don't fly unless they belong to certain species
        // or are a certain combination of lifestage and species.
        uint256 fly = 0;
        if (
            (species == 0 || species == 3 || species == 8) ||
            (species == 1 && lifestage == 2) ||
            (lifestage != 0 && (species == 9 || species == 7 || species == 6))
        ) fly = 1;

        // Attack depends on species.
        uint256 attack;
        if (0 == species) {
            attack = 14;
        } else if (1 == species) {
            attack = 19;
        } else if (2 == species) {
            attack = 29;
        } else if (3 == species || 5 == species) {
            attack = 34;
        } else if (4 == species) {
            attack = 39;
        } else if (6 == species) {
            attack = 49;
        } else if (7 == species) {
            attack = 44;
        } else if (8 == species) {
            attack = 54;
        } else if (9 == species) {
            attack = 59;
        }

        // Attack increases with rarity.
        if (rarity > 0) {
            attack += 10 * rarity;
            if (rarity == 4) attack += 20;
        }

        // Attack increases with lifestage.
        if (lifestage > 0) {
            attack += 15;
            if (lifestage > 1) attack += 15;
        }

        // Defence starts with a negative debuff except if dragons of certain species.
        int256 defence_ = -4;
        if (
            0 == species ||
            2 == species ||
            5 == species ||
            7 == species ||
            8 == species
        ) {
            defence_ = 6;
        }

        // Sense check attack value before converting to a signed integer.
        require(attack <= uint256(type(int256).max));

        // Final defence value depends on attack.
        uint256 defence = 2 * uint256(defence_ + int256(attack));

        // The 'perfect' form gets an extra attack point.
        if (card_ % 2 == 1) {
            ++attack;
        }

        // Magic starting value depends on lifestage and rarity.
        uint256 magic = 2 + lifestage + rarity * 3;

        // Rarer cards get additional magic, with perfect cards even more so.
        if (rarity >= 3) {
            magic += 3 + lifestage + (card_ % 2);
            if (rarity == 4) {
                magic += 3 + 2 * lifestage + (card_ % 2);
            }
        }

        token |= (uint256(card) << CARD_SHIFT);
        token |= (uint256(magic) << MAGIC_SHIFT);
        token |= (uint256(rarity) << RARITY_SHIFT);
        token |= (uint256(species) << SPECIES_SHIFT);
        token |= (uint256(lifestage) << LIFESTAGE_SHIFT);
        token |= (uint256(fly) << FLY_SHIFT);
        token |= (uint256(attack) << ATTACK_SHIFT);
        token |= (uint256(defence) << DEFENCE_SHIFT);
        /* No need to encode chain as Polygon is 0. Ensure to encode if deploying on other chain */
        token |= (uint256(1) << FUNGIBLE_SHIFT);
        token |= (uint256(2) << TYPE_SHIFT);
        /* No need to encode version as V1 is 0. Ensure to encode when reversioning */
    }

    function random() private returns (uint256 random_) {
        random_ = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number),
                    msg.sender,
                    ++nonce
                )
            )
        );
    }

    function getRandomCardNumber() private returns (uint256 card) {
        uint256 random_ = random();
        uint256 rarityRandom = (random_ & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) % BASE_CHANCE;
        
        uint256 rarity;

        if (rarityRandom < LEGENDARY) {
            rarity = 4;
        } else if (rarityRandom < ULTRARARE) {
            rarity = 3;
        } else if (rarityRandom < RARE) {
            rarity = 2;
        } else if (rarityRandom < UNCOMMON) {
            rarity = 1;
        } else {
            rarity = 0;
        }

        random_ >>= 128;

        card = (random_ % 60) + 2 + (rarity * 60);
    }

    function createRandomDragon() external {
        _INft.mintNFT(msg.sender, cardToToken(getRandomCardNumber()));
    }

    function createRandomDragons(uint256 count) external {
        uint256[] memory cards = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            cards[i] = cardToToken(getRandomCardNumber());
        }
        _INft.mintNFTBatch(msg.sender, cards);
    }

    function _createSpecificDragon(address to, uint16 card) internal {
        _INft.mintNFT(to, cardToToken(card));
    }

    function createSpecificDragon(address to, uint16 card) external onlyOwner {
        _createSpecificDragon(to, card);
    }

    function createSpecificDragon(uint16 card) external onlyOwner {
        _createSpecificDragon(_msgSender(), card);
    }

    function _createSpecificDragons(address to, uint16[] memory cards)
        internal
    {
        uint256[] memory tokens = new uint256[](cards.length);
        for (uint256 i = 0; i < cards.length; ++i) {
            tokens[i] = cardToToken(cards[i]);
        }
        _INft.mintNFTBatch(to, tokens);
    }

    function createSpecificDragons(address to, uint16[] memory cards)
        external
        onlyOwner
    {
        _createSpecificDragons(to, cards);
    }

    function createSpecificDragons(uint16[] memory cards) external onlyOwner {
        _createSpecificDragons(_msgSender(), cards);
    }
}