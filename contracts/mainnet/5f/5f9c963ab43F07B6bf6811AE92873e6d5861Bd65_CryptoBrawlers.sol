/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// File: contracts/lib/RandomNumber.sol

pragma solidity 0.8.2;

library RandomNumber {
    function randomNum(uint256 seed) internal returns (uint256) {
        uint256 _number =
            (uint256(
                keccak256(abi.encodePacked(blockhash(block.number - 1), seed))
            ) % 100);
        if (_number <= 0) {
            _number = 1;
        }

        return _number;
    }

    function rand1To10(uint256 seed) internal returns (uint256) {
        uint256 _number =
            (uint256(
                keccak256(abi.encodePacked(blockhash(block.number - 1), seed))
            ) % 10);
        if (_number <= 0) {
            _number = 10;
        }

        return _number;
    }

    function randDecimal(uint256 seed) internal returns (uint256) {
        return (rand1To10(seed) / 10);
    }

    function randomNumberToMax(uint256 seed, uint256 max)
        internal
        returns (uint256)
    {
        return (uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), seed))
        ) % max);
    }

    function randomNumber1ToMax(uint256 seed, uint256 max)
        internal
        returns (uint256)
    {
        uint256 _number =
            (uint256(
                keccak256(abi.encodePacked(blockhash(block.number - 1), seed))
            ) % max);
        if (_number <= 0) {
            _number = max;
        }

        return _number;
    }
}

// File: contracts/base/Ownable.sol

pragma solidity 0.8.2;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

// File: contracts/fighter/FighterConfig.sol

pragma solidity 0.8.2;


contract FighterConfig is Ownable {
    uint256 public currentFighterCost = 50000000000000000 wei;

    string public constant LEGENDARY = "legendary";
    string public constant EPIC = "epic";
    string public constant RARE = "rare";
    string public constant UNCOMMON = "uncommon";
    string public constant COMMON = "common";

    // actually 1 higher than real life because of the issue with a 0 index fighter
    uint256 public maxFighters = 6561;
    uint256 public maxLegendaryFighters = 1;
    uint256 public maxEpicFighters = 5;
    uint256 public maxRareFighters = 25;
    uint256 public maxUncommonFighters = 125;
    uint256 public maxCommonFighters = 500;
    uint256 public maxFightersPerChar = 656;
    string public tokenMetadataEndpoint =
        "https://cryptobrawle.rs/api/getFighterInfo/";
    bool public isTrainingEnabled = false;

    uint256 public trainingFactor = 3;
    uint256 public trainingCost = 5000000000000000 wei; // cost of training in wei

    function setTrainingFactor(uint256 newFactor) external onlyOwner {
        trainingFactor = newFactor;
    }

    function setNewTrainingCost(uint256 newCost) external onlyOwner {
        trainingCost = newCost;
    }

    function enableTraining() external onlyOwner {
        isTrainingEnabled = true;
    }
}

// File: contracts/fighter/FighterBase.sol

pragma solidity 0.8.2;


contract FighterBase is FighterConfig {
    /*** EVENTS ***/
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Creation(
        address owner,
        uint256 fighterId,
        uint256 maxHealth,
        uint256 speed,
        uint256 strength,
        string rarity,
        string name,
        string imageHash,
        uint256 mintNum
    );
    event AttributeIncrease(
        address owner,
        uint256 fighterId,
        string attribute,
        uint256 increaseValue
    );
    event Healed(address owner, uint256 fighterId, uint256 maxHealth);

    struct Fighter {
        uint256 maxHealth;
        uint256 health;
        uint256 speed;
        uint256 strength;
        string name;
        string rarity;
        string image;
        uint256 mintNum;
    }

    /*** STORAGE ***/

    Fighter[] fighters;
    mapping(uint256 => address) public fighterIdToOwner; // lookup for owner of a specific fighter
    mapping(uint256 => address) public fighterIdToApproved; // Shows appoved address for sending of fighters, Needed for ERC721
    mapping(address => address[]) public ownerToOperators;
    mapping(address => uint256) internal ownedFightersCount;

    string[] public availableFighterNames;
    mapping(string => uint256) public indexOfAvailableFighterName;

    mapping(string => uint256) public rarityToSkillBuff;
    mapping(string => uint256) public fighterNameToMintedCount;
    mapping(string => mapping(string => string))
        public fighterNameToRarityImageHashes;
    mapping(string => mapping(string => uint256))
        public fighterNameToRarityCounts;

    function getMintedCountForFighterRarity(
        string memory _fighterName,
        string memory _fighterRarity
    ) external view returns (uint256 mintedCount) {
        return fighterNameToRarityCounts[_fighterName][_fighterRarity];
    }

    function addFighterCharacter(
        string memory newName,
        string memory legendaryImageHash,
        string memory epicImageHash,
        string memory rareImageHash,
        string memory uncommonImageHash,
        string memory commonImageHash
    ) external onlyOwner {
        indexOfAvailableFighterName[newName] = availableFighterNames.length;
        availableFighterNames.push(newName);
        fighterNameToMintedCount[newName] = 0;

        fighterNameToRarityImageHashes[newName][LEGENDARY] = legendaryImageHash;
        fighterNameToRarityImageHashes[newName][EPIC] = epicImageHash;
        fighterNameToRarityImageHashes[newName][RARE] = rareImageHash;
        fighterNameToRarityImageHashes[newName][UNCOMMON] = uncommonImageHash;
        fighterNameToRarityImageHashes[newName][COMMON] = commonImageHash;

        fighterNameToRarityCounts[newName][LEGENDARY] = 0;
        fighterNameToRarityCounts[newName][EPIC] = 0;
        fighterNameToRarityCounts[newName][RARE] = 0;
        fighterNameToRarityCounts[newName][UNCOMMON] = 0;
        fighterNameToRarityCounts[newName][COMMON] = 0;
    }

    /// @dev Checks if a given address is the current owner of a particular fighter.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId fighter id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return fighterIdToOwner[_tokenId] == _claimant;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _fighterId
    ) internal {
        fighterIdToOwner[_fighterId] = _to;
        ownedFightersCount[_to]++;

        // Check that it isn't a newly created fighter before messing with ownership values
        if (_from != address(0)) {
            // Remove any existing approvals for the token
            fighterIdToApproved[_fighterId] = address(0);
            ownedFightersCount[_from]--;
        }
        // Emit the transfer event.
        emit Transfer(_from, _to, _fighterId);
    }

    function _createFighter(
        uint256 _maxHealth,
        uint256 _speed,
        uint256 _strength,
        address _owner,
        string memory _rarity,
        string memory _name,
        uint256 _mintNum
    ) internal returns (uint256) {
        string memory _fighterImage =
            fighterNameToRarityImageHashes[_name][_rarity];
        Fighter memory _fighter =
            Fighter({
                maxHealth: _maxHealth,
                health: _maxHealth, // Fighters are always created with maximum health
                speed: _speed,
                strength: _strength,
                name: _name,
                rarity: _rarity,
                image: _fighterImage,
                mintNum: _mintNum
            });

        uint256 newFighterId = fighters.length;
        fighters.push(_fighter);

        emit Creation(
            _owner,
            newFighterId,
            _maxHealth,
            _speed,
            _strength,
            _rarity,
            _name,
            _fighterImage,
            _mintNum
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(address(0), _owner, newFighterId);

        return newFighterId;
    }

    function _updateFighterInStorage(
        Fighter memory _updatedFighter,
        uint256 _fighterId
    ) internal {
        fighters[_fighterId] = _updatedFighter;
    }

    function _trainSpeed(
        uint256 _fighterId,
        uint256 _attributeIncrease,
        address _owner
    ) internal {
        Fighter memory _fighter = fighters[_fighterId];
        _fighter.speed += _attributeIncrease;
        _updateFighterInStorage(_fighter, _fighterId);

        emit AttributeIncrease(_owner, _fighterId, "speed", _attributeIncrease);
    }

    function _trainStrength(
        uint256 _fighterId,
        uint256 _attributeIncrease,
        address _owner
    ) internal {
        Fighter memory _fighter = fighters[_fighterId];
        _fighter.strength += _attributeIncrease;
        _updateFighterInStorage(_fighter, _fighterId);

        emit AttributeIncrease(
            _owner,
            _fighterId,
            "strength",
            _attributeIncrease
        );
    }
}

// File: contracts/marketplace/MarketplaceConfig.sol

pragma solidity 0.8.2;



contract MarketplaceConfig is Ownable, FighterBase {
    uint256 public marketplaceCut = 5;
    struct Combatant {
        uint256 fighterId;
        Fighter fighter;
        uint256 damageModifier;
    }

    struct Sale {
        uint256 fighterId;
        uint256 price;
    }

    mapping(uint256 => Sale) public fighterIdToSale; // Storing of figher Ids against their sale Struct
    mapping(uint256 => uint256) public fighterIdToBrawl; // Map of fighter Ids to their max health

    event PurchaseSuccess(
        address buyer,
        uint256 price,
        uint256 fighterId,
        address seller
    );
    event FightComplete(
        address winner,
        uint256 winnerId,
        address loser,
        uint256 loserId
    );

    event MarketplaceRemoval(address owner, uint256 fighterId);
    event ArenaRemoval(address owner, uint256 fighterId);

    event MarketplaceAdd(address owner, uint256 fighterId, uint256 price);
    event ArenaAdd(address owner, uint256 fighterId);

    function setNewMarketplaceCut(uint256 _newCut) external onlyOwner {
        marketplaceCut = _newCut;
    }

    function withdrawBalance() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawBalanceToAddress(address _recipient) external onlyOwner {
        payable(_recipient).transfer(address(this).balance);
    }

    function killContract() external onlyOwner {
        selfdestruct(payable(owner));
    }

    function _calculateCut(uint256 _totalPrice) internal returns (uint256) {
        return ((_totalPrice / 100) * marketplaceCut);
    }

    function _fighterIsForSale(uint256 _fighterId) internal returns (bool) {
        return (fighterIdToSale[_fighterId].price > 0);
    }

    function _fighterIsForBrawl(uint256 _fighterId) internal returns (bool) {
        return (fighterIdToBrawl[_fighterId] > 0);
    }

    function _removeFighterFromSale(uint256 _fighterId) internal {
        delete fighterIdToSale[_fighterId];
    }

    function _removeFighterFromArena(uint256 _fighterId) internal {
        delete fighterIdToBrawl[_fighterId];
    }
}

// File: contracts/marketplace/Marketplace.sol

pragma solidity 0.8.2;



contract Marketplace is MarketplaceConfig {
    function getPriceForFighter(uint256 _fighterId) external returns (uint256) {
        return fighterIdToSale[_fighterId].price;
    }

    function removeFighterFromSale(uint256 _fighterId) external {
        require(_owns(msg.sender, _fighterId));
        // Just double check we can actually remove a fighter before we go any further
        require(_fighterIsForSale(_fighterId));

        _removeFighterFromSale(_fighterId);
        emit MarketplaceRemoval(msg.sender, _fighterId);
    }

    function removeFighterFromArena(uint256 _fighterId) external {
        require(_owns(msg.sender, _fighterId));
        // Just double check we can actually remove a fighter before we go any further
        require(_fighterIsForBrawl(_fighterId));

        _removeFighterFromArena(_fighterId);
        emit ArenaRemoval(msg.sender, _fighterId);
    }

    function makeFighterAvailableForSale(uint256 _fighterId, uint256 _price)
        external
    {
        require(_owns(msg.sender, _fighterId));
        // Fighters can't be both for sale and open for brawling
        require(!_fighterIsForBrawl(_fighterId));
        require(_price > 0);

        // Double check there is not an existing third party transfer approval
        require(fighterIdToApproved[_fighterId] == address(0));

        fighterIdToSale[_fighterId] = Sale({
            fighterId: _fighterId,
            price: _price
        });
        emit MarketplaceAdd(msg.sender, _fighterId, _price);
    }

    function makeFighterAvailableForBrawl(uint256 _fighterId) external {
        require(_owns(msg.sender, _fighterId));
        // Fighters can't be both for sale and open for brawling
        require(!_fighterIsForSale(_fighterId));
        // We don't want fighters being added twice
        require(!_fighterIsForBrawl(_fighterId));

        // Double check there is not an existing third party transfer approval
        require(fighterIdToApproved[_fighterId] == address(0));

        fighterIdToBrawl[_fighterId] = _fighterId;
        emit ArenaAdd(msg.sender, _fighterId);
    }

    function buyFighter(uint256 _fighterId) external payable {
        address _seller = fighterIdToOwner[_fighterId];
        _makePurchase(_fighterId, msg.value);
        _transfer(_seller, msg.sender, _fighterId);

        emit PurchaseSuccess(msg.sender, msg.value, _fighterId, _seller);
    }

    function _strike(
        uint256 _attackerId,
        uint256 _defenderId,
        uint256 _attackerStrength,
        uint256 _defenderStrength,
        uint256 _seed
    ) internal returns (bool) {
        uint256 _attackerAttackRoll =
            RandomNumber.randomNumber1ToMax(_seed, 20) + _attackerStrength;
        uint256 _defenderDefenseRoll =
            RandomNumber.randomNumber1ToMax(_seed * 3, 20) + _defenderStrength;

        if (_attackerAttackRoll >= _defenderDefenseRoll) {
            return true;
        }

        return false;
    }

    function _performFight(
        uint256 _attackerId,
        uint256 _defenderId,
        Fighter memory _attacker,
        Fighter memory _defender,
        uint256 _seed
    ) internal returns (uint256 winnerId, uint256 loserId) {
        uint256 _generatedSeed =
            RandomNumber.randomNumber1ToMax(_seed, 99999999);
        uint256 _totalSpeed = _attacker.speed + _defender.speed;
        uint256 _attackerSpeedRoll =
            RandomNumber.randomNumber1ToMax(_seed, 20) + _attacker.speed;
        uint256 _defenderSpeedRoll =
            RandomNumber.randomNumber1ToMax(_generatedSeed, 20) +
                _defender.speed;

        bool _attackerIsStrikingFirst =
            _attackerSpeedRoll >= _defenderSpeedRoll;

        if (_attackerIsStrikingFirst) {
            if (
                _strike(
                    _attackerId,
                    _defenderId,
                    _attacker.strength,
                    _defender.strength,
                    _seed * 2
                )
            ) {
                return (_attackerId, _defenderId);
            }
        } else {
            if (
                _strike(
                    _defenderId,
                    _attackerId,
                    _defender.strength,
                    _attacker.strength,
                    _generatedSeed * 2
                )
            ) {
                return (_defenderId, _attackerId);
            }
        }

        if (_attackerIsStrikingFirst) {
            if (
                _strike(
                    _defenderId,
                    _attackerId,
                    _defender.strength,
                    _attacker.strength,
                    _generatedSeed * 3
                )
            ) {
                return (_defenderId, _attackerId);
            }
        } else {
            if (
                _strike(
                    _attackerId,
                    _defenderId,
                    _attacker.strength,
                    _defender.strength,
                    _seed * 3
                )
            ) {
                return (_attackerId, _defenderId);
            }
        }

        uint256 _defenderEndCheck =
            _defender.speed +
                _defender.strength +
                RandomNumber.randomNumber1ToMax(_generatedSeed, 20);
        uint256 _attackerEndCheck =
            _attacker.speed +
                _attacker.strength +
                RandomNumber.randomNumber1ToMax(_seed, 20);

        if (_defenderEndCheck >= _attackerEndCheck) {
            return (_defenderId, _attackerId);
        }
        return (_attackerId, _defenderId);
    }

    function fight(
        uint256 _attackerId,
        uint256 _defenderId,
        uint256 _seed
    ) external {
        Fighter memory _attacker = fighters[_attackerId];
        Fighter memory _defender = fighters[_defenderId];
        // fighter actually in the arena is always the defender
        require(_fighterIsForBrawl(_defenderId));
        // Make sure the challenger is actually sending the transaction
        require(_owns(msg.sender, _attackerId));
        // Also make sure that the challenger is not attacking his own fighter
        require(!_owns(msg.sender, _defenderId));
        // Ensure that a 'stronger' fighter is not attacking a 'weaker' fighter
        require(
            (_attacker.speed + _attacker.strength) <=
                (_defender.speed + _defender.strength)
        );

        (uint256 _winnerId, uint256 _loserId) =
            _performFight(
                _attackerId,
                _defenderId,
                _attacker,
                _defender,
                _seed
            );

        if (_fighterIsForBrawl(_winnerId)) {
            _removeFighterFromArena(_winnerId);
        } else {
            _removeFighterFromArena(_loserId);
        }
        address _winnerAddress = fighterIdToOwner[_winnerId];
        address _loserAddress = fighterIdToOwner[_loserId];

        _transfer(_loserAddress, _winnerAddress, _loserId);
        emit FightComplete(_winnerAddress, _winnerId, _loserAddress, _loserId);
    }

    function _makePurchase(uint256 _fighterId, uint256 _price) internal {
        require(!_owns(msg.sender, _fighterId));
        require(_fighterIsForSale(_fighterId));
        require(_price >= fighterIdToSale[_fighterId].price);

        address sellerAddress = fighterIdToOwner[_fighterId];
        _removeFighterFromSale(_fighterId);

        uint256 saleCut = _calculateCut(_price);
        uint256 totalSale = _price - saleCut;
        payable(sellerAddress).transfer(totalSale);
    }
}

// File: contracts/lib/Integers.sol

pragma solidity 0.8.2;

library Integers {
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
}

// File: contracts/base/ERC721.sol

pragma solidity 0.8.2;

abstract contract ERC721 {
    // Required methods
    function totalSupply() public view virtual returns (uint256 total) {}

    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 balance)
    {}

    function ownerOf(uint256 _tokenId)
        external
        view
        virtual
        returns (address owner)
    {}

    function approve(address _to, uint256 _tokenId) external virtual {}

    function transfer(address _to, uint256 _tokenId) external virtual {}

    function tokenURI(uint256 _tokenId)
        external
        view
        virtual
        returns (string memory _tokenURI)
    {}

    function baseURI() external view virtual returns (string memory _baseURI) {}

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external virtual {}

    function getApproved(uint256 _tokenId)
        external
        virtual
        returns (address _approvedAddress)
    {}

    function setApprovalForAll(address _to, bool approved) external virtual {}

    function isApprovedForAll(address _owner, address _operator)
        external
        virtual
        returns (bool isApproved)
    {}

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external virtual {}

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external virtual {}

    // Events
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function _isContract(address _addr)
        internal
        view
        returns (bool isContract)
    {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        virtual
        returns (bool)
    {}

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the
    /// recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
    /// of other than the magic value MUST result in the transaction being reverted.
    /// @notice The contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    /// unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external virtual returns (bytes4) {}
}

// File: contracts/base/Priced.sol

pragma solidity 0.8.2;

contract Priced {
    modifier costs(uint256 price) {
        if (msg.value >= price) {
            _;
        }
    }
}

// File: contracts/base/Pausable.sol

pragma solidity 0.8.2;


contract Pausable is Ownable {
    bool public isPaused = false;

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    function pause() external onlyOwner {
        isPaused = true;
    }

    function unPause() external onlyOwner {
        isPaused = false;
    }
}

// File: contracts/base/IERC721Receiver.sol

pragma solidity ^0.8.2;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/fighter/FighterTraining.sol

pragma solidity 0.8.2;


contract FighterTraining is FighterBase {
    function _train(
        uint256 _fighterId,
        string memory _attribute,
        uint256 _attributeIncrease
    ) internal {
        if (
            keccak256(abi.encodePacked(_attribute)) ==
            keccak256(abi.encodePacked("strength"))
        ) {
            _trainStrength(_fighterId, _attributeIncrease, msg.sender);
        } else if (
            keccak256(abi.encodePacked(_attribute)) ==
            keccak256(abi.encodePacked("speed"))
        ) {
            _trainSpeed(_fighterId, _attributeIncrease, msg.sender);
        }
    }
}

// File: contracts/fighter/FighterOwnership.sol

pragma solidity 0.8.2;











contract FighterOwnership is
    FighterConfig,
    FighterBase,
    FighterTraining,
    ERC721,
    Priced,
    Pausable,
    MarketplaceConfig
{
    using Integers for uint256;
    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "CryptoBrawlers";
    string public constant symbol = "BRAWLER";
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));
    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        override
        returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) ||
            (_interfaceID == _INTERFACE_ID_ERC721) ||
            (_interfaceID == _INTERFACE_ID_ERC721_METADATA));
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external pure override returns (bytes4) {
        revert();
    }

    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address currently has transferApproval for a particular fighter.
    /// @param _claimant the address we are confirming brawler is approved for.
    /// @param _tokenId fighter id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        if (fighterIdToApproved[_tokenId] == _claimant) {
            return true;
        }

        bool _senderIsOperator = false;
        address _owner = fighterIdToOwner[_tokenId];
        address[] memory _validOperators = ownerToOperators[_owner];

        uint256 _operatorIndex;
        for (
            _operatorIndex = 0;
            _operatorIndex < _validOperators.length;
            _operatorIndex++
        ) {
            if (_validOperators[_operatorIndex] == _claimant) {
                _senderIsOperator = true;
                break;
            }
        }

        return _senderIsOperator;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event.
    function _approve(uint256 _tokenId, address _approved) internal {
        fighterIdToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of Fighters owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 count)
    {
        require(_owner != address(0));
        return ownedFightersCount[_owner];
    }

    /// @notice Transfers a Fighter to another address. If transferring to a smart
    /// contract be VERY CAREFUL to ensure that it is aware of ERC-721.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the fighter to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId) external override {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));
        // You can only send your own fighter.
        require(_owns(msg.sender, _tokenId));
        // If transferring we can't keep a fighter in the arena...
        if (_fighterIsForBrawl(_tokenId)) {
            _removeFighterFromArena(_tokenId);
            emit ArenaRemoval(msg.sender, _tokenId);
        }

        // ...nor can they be in our marketplace.
        if (_fighterIsForSale(_tokenId)) {
            _removeFighterFromSale(_tokenId);
            emit MarketplaceRemoval(msg.sender, _tokenId);
        }

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific fighter via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the fighter that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _tokenId) external override {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // If selling on an external marketplace we can't keep a fighter in the arena...
        if (_fighterIsForBrawl(_tokenId)) {
            _removeFighterFromArena(_tokenId);
            emit ArenaRemoval(msg.sender, _tokenId);
        }

        // ...nor can they be in our marketplace.
        if (_fighterIsForSale(_tokenId)) {
            _removeFighterFromSale(_tokenId);
            emit MarketplaceRemoval(msg.sender, _tokenId);
        }
        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a fighter owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the fighter to be transfered.
    /// @param _to The address that should take ownership of the fighter. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the fighter to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // This should never be the case, but might as well check
        if (_fighterIsForBrawl(_tokenId)) {
            _removeFighterFromArena(_tokenId);
            emit ArenaRemoval(msg.sender, _tokenId);
        }

        // ...nor can they be in our marketplace.
        if (_fighterIsForSale(_tokenId)) {
            _removeFighterFromSale(_tokenId);
            emit MarketplaceRemoval(msg.sender, _tokenId);
        }

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
        // Remove an existing external approval to move the fighter.
        _approve(_tokenId, address(0));
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        // This should never be the case, but might as well check
        if (_fighterIsForBrawl(_tokenId)) {
            _removeFighterFromArena(_tokenId);
            emit ArenaRemoval(msg.sender, _tokenId);
        }

        // ...nor can they be in our marketplace.
        if (_fighterIsForSale(_tokenId)) {
            _removeFighterFromSale(_tokenId);
            emit MarketplaceRemoval(msg.sender, _tokenId);
        }

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
        // Remove an existing external approval to move the fighter.
        _approve(_tokenId, address(0));
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _safeTransferFrom(_from, _to, _tokenId);

        if (_isContract(_to)) {
            bytes4 retval =
                IERC721Receiver(_to).onERC721Received(_from, _to, _tokenId, "");
            require(ERC721_RECEIVED == retval);
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external override {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _safeTransferFrom(_from, _to, _tokenId);

        if (_isContract(_to)) {
            bytes4 retval =
                IERC721Receiver(_to).onERC721Received(
                    _from,
                    _to,
                    _tokenId,
                    _data
                );
            require(ERC721_RECEIVED == retval);
        }
    }

    function getApproved(uint256 _tokenId)
        external
        view
        override
        returns (address _approvedAddress)
    {
        return fighterIdToApproved[_tokenId];
    }

    function setApprovalForAll(address _to, bool _approved) external override {
        address[] memory _operatorsForSender = ownerToOperators[msg.sender];
        if (_approved) {
            ownerToOperators[msg.sender].push(_to);
        }

        if (!_approved) {
            if (ownerToOperators[msg.sender].length == 0) {
                emit ApprovalForAll(msg.sender, _to, false);
                return;
            }

            uint256 _operatorIndex;
            for (
                _operatorIndex = 0;
                _operatorIndex < _operatorsForSender.length;
                _operatorIndex++
            ) {
                if (ownerToOperators[msg.sender][_operatorIndex] == _to) {
                    ownerToOperators[msg.sender][
                        _operatorIndex
                    ] = ownerToOperators[msg.sender][
                        ownerToOperators[msg.sender].length - 1
                    ];
                    ownerToOperators[msg.sender].pop();
                    break;
                }
            }
        }

        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool isApproved)
    {
        address[] memory _operatorsForSender = ownerToOperators[_owner];

        if (_operatorsForSender.length == 0) {
            return false;
        }
        bool _isApproved = true;
        uint256 _operatorIndex;
        for (
            _operatorIndex = 0;
            _operatorIndex < _operatorsForSender.length;
            _operatorIndex++
        ) {
            if (_operatorsForSender[_operatorIndex] != _operator) {
                _isApproved = false;
                break;
            }
        }

        return _isApproved;
    }

    /// @notice Returns the total number of fighters currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view override returns (uint256) {
        return fighters.length - 1; // -1 because of the phantom 0 index fighter that doesn't play nicely
    }

    /// @notice Returns the address currently assigned ownership of a given fighter.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address owner)
    {
        owner = fighterIdToOwner[_tokenId];
        require(owner != address(0));

        return owner;
    }

    function tokenURI(uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(tokenMetadataEndpoint, _tokenId.toString())
            );
    }

    function baseURI() external view override returns (string memory) {
        return tokenMetadataEndpoint;
    }

    modifier currentFighterPrice() {
        require(msg.value >= currentFighterCost);
        _;
    }

    function trainFighter(
        uint256 _fighterId,
        string memory _attribute,
        uint256 _seed
    ) external payable costs(trainingCost) returns (uint256 _increaseValue) {
        require(isTrainingEnabled);
        require(_owns(msg.sender, _fighterId));
        uint256 _attributeIncrease =
            (RandomNumber.rand1To10(_seed) / trainingFactor);
        if (_attributeIncrease == 0) {
            _attributeIncrease = 1;
        }

        _train(_fighterId, _attribute, _attributeIncrease);
        return _attributeIncrease;
    }

    function _getFighterRarity(uint256 _seed, string memory _fighterName)
        internal
        returns (string memory)
    {
        uint256 _rarityRoll =
            RandomNumber.randomNumber1ToMax(_seed, maxFightersPerChar);
        uint256 _minEpicRoll =
            maxFightersPerChar - (maxEpicFighters + maxLegendaryFighters);
        uint256 _minRareRoll =
            maxFightersPerChar -
                (maxRareFighters + maxEpicFighters + maxLegendaryFighters);
        uint256 _minUncommonRoll =
            maxFightersPerChar -
                (maxUncommonFighters +
                    maxRareFighters +
                    maxEpicFighters +
                    maxLegendaryFighters);

        if (
            fighterNameToRarityCounts[_fighterName][LEGENDARY] <
            maxLegendaryFighters &&
            _rarityRoll == maxFightersPerChar
        ) {
            return LEGENDARY;
        }
        if (
            fighterNameToRarityCounts[_fighterName][EPIC] < maxEpicFighters &&
            _rarityRoll >= _minEpicRoll
        ) {
            return EPIC;
        }
        if (
            fighterNameToRarityCounts[_fighterName][RARE] < maxRareFighters &&
            _rarityRoll >= _minRareRoll
        ) {
            return RARE;
        }
        if (
            fighterNameToRarityCounts[_fighterName][UNCOMMON] <
            maxUncommonFighters &&
            _rarityRoll >= _minUncommonRoll
        ) {
            return UNCOMMON;
        }
        if (
            fighterNameToRarityCounts[_fighterName][COMMON] <
            maxCommonFighters &&
            _rarityRoll >= 1
        ) {
            return COMMON;
        }

        string[] memory _leftoverRarities;
        if (
            fighterNameToRarityCounts[_fighterName][LEGENDARY] <
            maxLegendaryFighters
        ) {
            _leftoverRarities[_leftoverRarities.length] = LEGENDARY;
        }
        if (fighterNameToRarityCounts[_fighterName][EPIC] < maxEpicFighters) {
            _leftoverRarities[_leftoverRarities.length] = EPIC;
        }
        if (fighterNameToRarityCounts[_fighterName][RARE] < maxRareFighters) {
            _leftoverRarities[_leftoverRarities.length] = RARE;
        }
        if (
            fighterNameToRarityCounts[_fighterName][UNCOMMON] <
            maxUncommonFighters
        ) {
            _leftoverRarities[_leftoverRarities.length] = UNCOMMON;
        }
        if (
            fighterNameToRarityCounts[_fighterName][COMMON] < maxCommonFighters
        ) {
            _leftoverRarities[_leftoverRarities.length] = COMMON;
        }

        if (_leftoverRarities.length == 1) {
            return _leftoverRarities[0];
        }

        uint256 _leftoverRoll =
            RandomNumber.randomNumberToMax(_seed, _leftoverRarities.length);
        return _leftoverRarities[_leftoverRoll];
    }

    function _getFighterName(uint256 _seed)
        internal
        returns (string memory _fighterName)
    {
        uint256 _nameIndex =
            RandomNumber.randomNumberToMax(_seed, availableFighterNames.length); // Use the whole array length because the random max number does not include the top end
        return availableFighterNames[_nameIndex];
    }

    function _removeNameFromAvailableNamesArray(string memory _fighterName)
        internal
    {
        uint256 _nameIndex = indexOfAvailableFighterName[_fighterName];
        require(
            keccak256(abi.encodePacked(availableFighterNames[_nameIndex])) ==
                keccak256(abi.encodePacked(_fighterName))
        ); // double check something wiggly hasn't happened

        if (availableFighterNames.length > 1) {
            availableFighterNames[_nameIndex] = availableFighterNames[
                availableFighterNames.length - 1
            ];
        }
        availableFighterNames.pop();
    }

    function searchForFighter(uint256 _seed)
        external
        payable
        currentFighterPrice
        whenNotPaused()
        returns (uint256 newFighterId)
    {
        require(fighters.length < maxFighters);
        string memory _fighterName = _getFighterName(_seed);
        string memory _fighterRarity = _getFighterRarity(_seed, _fighterName);
        uint256 _speed =
            RandomNumber.rand1To10(_seed) + rarityToSkillBuff[_fighterRarity];
        uint256 _strength =
            RandomNumber.rand1To10(_speed + _seed) +
                rarityToSkillBuff[_fighterRarity];

        fighterNameToMintedCount[_fighterName] += 1;
        fighterNameToRarityCounts[_fighterName][_fighterRarity] += 1;

        uint256 _fighterId =
            _createFighter(
                10,
                _speed,
                _strength,
                msg.sender,
                _fighterRarity,
                _fighterName,
                fighterNameToRarityCounts[_fighterName][_fighterRarity]
            );

        if (fighterNameToMintedCount[_fighterName] >= maxFightersPerChar) {
            _removeNameFromAvailableNamesArray(_fighterName);
        }

        uint256 _fighterCost = _getFighterCost();
        if (_fighterCost > currentFighterCost) {
            currentFighterCost = _fighterCost;
        }

        return _fighterId;
    }

    function _getFighterCost() internal returns (uint256 _cost) {
        uint256 currentTotalFighters = fighters.length - 1;

        if (currentTotalFighters < 500) {
            return 50000000000000000 wei;
        }
        if (currentTotalFighters >= 500 && currentTotalFighters < 1000) {
            return 100000000000000000 wei;
        }
        if (currentTotalFighters >= 1000 && currentTotalFighters < 1500) {
            return 150000000000000000 wei;
        }
        if (currentTotalFighters >= 1500 && currentTotalFighters < 2000) {
            return 200000000000000000 wei;
        }
        if (currentTotalFighters >= 2000 && currentTotalFighters < 2500) {
            return 250000000000000000 wei;
        }
        if (currentTotalFighters >= 2500 && currentTotalFighters < 3000) {
            return 300000000000000000 wei;
        }
        if (currentTotalFighters >= 3000 && currentTotalFighters < 3500) {
            return 350000000000000000 wei;
        }
        if (currentTotalFighters >= 3500 && currentTotalFighters < 4000) {
            return 400000000000000000 wei;
        }
        if (currentTotalFighters >= 4000 && currentTotalFighters < 4500) {
            return 450000000000000000 wei;
        }
        if (currentTotalFighters >= 4500 && currentTotalFighters < 5000) {
            return 500000000000000000 wei;
        }
        if (currentTotalFighters >= 5000 && currentTotalFighters < 5500) {
            return 550000000000000000 wei;
        }
        if (currentTotalFighters >= 5500 && currentTotalFighters < 6000) {
            return 600000000000000000 wei;
        }
        if (currentTotalFighters >= 6000) {
            return 650000000000000000 wei;
        }
        return 650000000000000000 wei;
    }
}

// File: contracts/CryptoBrawlers.sol

pragma solidity 0.8.2;



contract CryptoBrawlers is Marketplace, FighterOwnership {
    constructor() {
        rarityToSkillBuff[LEGENDARY] = 10;
        rarityToSkillBuff[EPIC] = 5;
        rarityToSkillBuff[RARE] = 3;
        rarityToSkillBuff[UNCOMMON] = 1;
        rarityToSkillBuff[COMMON] = 0;

        fighters.push(); // phantom 0 index element in the fighters array to begin
    }

    function getInfoForFighter(uint256 _fighterId)
        external
        returns (
            uint256 health,
            uint256 speed,
            uint256 strength,
            string memory fighterName,
            string memory image,
            string memory rarity,
            uint256 mintNum
        )
    {
        Fighter memory _fighter = fighters[_fighterId];
        return (
            _fighter.health,
            _fighter.speed,
            _fighter.strength,
            _fighter.name,
            _fighter.image,
            _fighter.rarity,
            _fighter.mintNum
        );
    }
}