// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

contract Cryptomons is ERC1155Holder {
    ERC20Burnable private _token;
    IERC1155 private _items;

    // 149 different Cryptomon species implemented and saved in the following enum variable.
    enum Species {
        DRYAD,
        HAMADRYAD,
        LESHY,
        SANTELMO,
        CERBERUS,
        EFREET,
        FASTITOCALON,
        ASPIDOCHELONE,
        ZARATAN,
        ARACHNE,
        JOROGUMO,
        TSUCHIGUMO,
        PABILSAG,
        GIRTABLILU,
        SELKET,
        TSIKAVATS,
        MUNNIN,
        HUGINN,
        AZEBAN,
        RATATOSKR,
        STRATIM,
        NAVKA,
        APEP,
        NIDHOGGR,
        RAIJU,
        RAIJIN,
        AMPHIVENA,
        BASILISK,
        WOLPERTINGER,
        RAMIDREJU,
        ECHINEMON,
        MUJINA,
        KAMAITACHI,
        LAVELLAN,
        VILA,
        HULDRA,
        CHIMERA,
        KYUUBI,
        NIXIE,
        TUATHAN,
        MINYADES,
        CAMAZOTZ,
        CURUPIRA,
        PENGHOU,
        GHILLIE_DHU,
        MYRMECOLEON,
        MYRMIDON,
        MOTHMAN,
        MOTH_KING,
        GROOTSLANG,
        YAOGUAI,
        CAIT_SIDHE,
        CATH_BALUG,
        NAKKI,
        KAPPA,
        SATORI,
        SHOJO,
        SKOHL,
        HAET,
        VODYANOY,
        UNDINE,
        MELUSINE,
        VUKODLAK,
        CHERNOBOG,
        DJINN,
        BAUK,
        TROLL,
        JOTUN,
        SPRIGGAN,
        JUBOKKO,
        KODAMA,
        BUKAVAK,
        KRAKEN,
        CLAYBOY,
        MET,
        EMET,
        SLEIPNIR,
        TODORATS,
        SCYLLA,
        CHARYBDIS,
        BRONTES,
        ARGES,
        HRAESVELGR,
        BERUNDA,
        COCKATRICE,
        SELKIE,
        RUSALKA,
        TARASQUE,
        MERETSEGER,
        CARBUNCLE,
        SHEN,
        BOOGEYMAN,
        BANSHEE,
        MARE,
        DILONG,
        INCUBUS,
        SUCCUBUS,
        CANCER,
        KARKINOS,
        DRUK,
        SHENLONG,
        GAN_CEANN,
        ONI,
        TAIRANOHONE,
        GASHADOKURO,
        YEREN,
        YETI,
        YOWIE,
        NEZHIT,
        CHUMA,
        SIGBIN,
        GARGOYLE,
        CALADRIUS,
        UMIBOZU,
        CALLISTO,
        KELPIE,
        MAKARA,
        MORGEN,
        MERROW,
        NAIAD,
        NEREID,
        PIXIU,
        KHEPRI,
        LIKHO,
        KITSUNE,
        CAORTHANNACH,
        KAGGEN,
        AUDUMBLA,
        LOCHNESS,
        JORMUNGANDR,
        LEVIATHAN,
        DOPPELGANGER,
        SKVADER,
        FOSSEGRIM,
        VALKYRIE,
        BASAN,
        TSUKUMOGAMI,
        LUSKA,
        HYDRA,
        AFANC,
        CETUS,
        VEDFOLNIR,
        BAKU,
        ALKONOST,
        QUETZALCOATL,
        ANZU,
        ZMEY,
        AZHDAYA,
        FAFNIR,
        BABA_YAGA,
        BABA_ROGA
    }

    // All 151 species types. Numbering follows this convention:
    //0(plant), 1(fire), 2(water), 3(bug), 4(normal), 5(poison), 6(thunder), 7(earth), 8(psychic), 9(ditto), 10(eevee)
    uint8[151] private monTypes = [
        0,
        0,
        0,
        1,
        1,
        1,
        2,
        2,
        2,
        3,
        3,
        3,
        3,
        3,
        3,
        4,
        4,
        4,
        4,
        4,
        4,
        4,
        5,
        5,
        6,
        6,
        7,
        7,
        4,
        4,
        4,
        4,
        4,
        4,
        4,
        4,
        1,
        1,
        4,
        4,
        5,
        5,
        0,
        0,
        0,
        3,
        3,
        3,
        3,
        7,
        7,
        4,
        4,
        2,
        2,
        4,
        4,
        1,
        1,
        2,
        2,
        2,
        8,
        8,
        8,
        4,
        4,
        4,
        0,
        0,
        0,
        2,
        2,
        7,
        7,
        7,
        1,
        1,
        2,
        2,
        6,
        6,
        4,
        4,
        4,
        2,
        2,
        5,
        5,
        2,
        2,
        8,
        8,
        8,
        7,
        8,
        8,
        2,
        2,
        6,
        6,
        8,
        8,
        7,
        7,
        4,
        4,
        4,
        5,
        5,
        7,
        7,
        4,
        0,
        4,
        2,
        2,
        2,
        2,
        2,
        2,
        4,
        3,
        8,
        6,
        1,
        3,
        4,
        2,
        2,
        2,
        9,
        10,
        2,
        6,
        1,
        4,
        2,
        2,
        2,
        2,
        4,
        4,
        2,
        6,
        1,
        8,
        8,
        8,
        8,
        8
    ];

    // Array keeping which Cryptomon species can evolve to the next one through breeding.
    bool[151] evolves = [
        true,
        true,
        false,
        true,
        true,
        false,
        true,
        true,
        false,
        true,
        true,
        false,
        true,
        true,
        false,
        true,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        true,
        false,
        true,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        true,
        false,
        true,
        true,
        false,
        true,
        true,
        false,
        true,
        true,
        false,
        true,
        false,
        true,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        true,
        false,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        false,
        true,
        false,
        true,
        false,
        false,
        false,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        true,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        true,
        true,
        false,
        true,
        false
    ];

    // events
    event FightResults(uint256 _winnerId, uint256 _round);
    event Rewards(uint256 _winnerId, uint256 _rewards);

    // Structure of 1 Cryptomon
    struct Mon {
        uint256 id;
        address payable owner;
        Species species;
        uint256 price;
        bool forSale;
        uint8 monType; // Used for breeding
        bool evolve; // Used for breeding
        uint8 hp; // Used for fighting
        uint8 atk; // Used for fighting
        uint8 def; // Used for fighting
        uint8 speed; // Used for fighting
        address sharedTo; // Used for sharing
    }

    address public manager; // Manager of the contract
    mapping(uint256 => Mon) public mons; // Holds all created Cryptomons
    uint256 public totalMons = 0; // Number of created Cryptomons
    uint256 private max = 2**256 - 1; // Max number of Cryptomons
    uint256 private nonce = 0; // Number used for guessable pseudo-random generated number.
    uint128 public potionsPrice = 50000000000000000000; // 50
    uint128 public equipmentsPrice = 500000000000000000000; // 500

    constructor(ERC20Burnable token, IERC1155 items) {
        manager = msg.sender;
        _token = token;
        _items = items;

        // Add initial cryptomons on contract deployment to start game
        createMon(Species(0), 0, false);
        createMon(Species(1), 0, false);
        createMon(Species(2), 0, false);
        createMon(Species(3), 0, false);
    }

    modifier onlyManager() {
        // Modifier
        require(msg.sender == manager, 'Only manager can call this.');
        _;
    }

    function deposit(uint256 amount) public onlyManager {
        uint256 allowance = _token.allowance(msg.sender, address(this));
        require(allowance >= amount, 'Check your token allowance');
        _token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public onlyManager {
        uint256 balance = _token.balanceOf(address(this));
        require(amount <= balance, 'Not enough tokens in the reserve');
        _token.transfer(msg.sender, amount);
    }

    function burn(uint256 amount) public {
        uint256 allowance = _token.allowance(msg.sender, address(this));
        require(allowance >= amount, 'Check your token allowance');
        uint256 balance = _token.balanceOf(msg.sender);
        require(amount <= balance, 'Not enough tokens');
        _token.burnFrom(msg.sender, amount);
    }

    function setItemPrices(uint128 _potionsPrice, uint128 _equipmentsPrice) public onlyManager {
        potionsPrice = _potionsPrice;
        equipmentsPrice = _equipmentsPrice;
    }

    function buyItem(
        uint256 units,
        uint256 price,
        uint8 itemNumber,
        bytes memory data
    ) public {
        uint256 itemBalance = _items.balanceOf(address(this), itemNumber);
        require(itemBalance >= units, 'Out of stock');

        // hp
        if (itemNumber == 0 || itemNumber == 1 || itemNumber == 2) {
            require(price >= potionsPrice, 'Wrong price for potions');
        } else {
            require(price >= equipmentsPrice, 'Wrong price for equipments');
        }

        uint256 payment = units * price;
        burn(payment);

        _items.safeTransferFrom(address(this), msg.sender, itemNumber, units, data);
    }

    function createMon(
        Species species,
        uint256 price,
        bool forSale
    ) public onlyManager {
        assert(totalMons < max);

        Mon storage mon = mons[totalMons];
        mon.id = totalMons;
        mon.owner = payable(msg.sender);
        mon.species = species;
        mon.price = price;
        mon.forSale = forSale;

        mon.monType = monTypes[uint8(species)]; // Assign the type of the cryptomon
        mon.evolve = evolves[uint8(species)]; // Keep whether this cryptomon can evolve

        // Assign stats of the cryptomon
        mon.hp = 100 + randomGen(41);
        mon.atk = 100 + randomGen(41);
        mon.def = 100 + randomGen(41);
        mon.speed = 100 + randomGen(41);

        mon.sharedTo = msg.sender;

        totalMons++;
    }

    function buyMon(uint256 id) public payable {
        assert(id < totalMons);
        require(msg.value >= mons[id].price, 'Must send enough money to buy');
        require(mons[id].forSale == true, 'Mon must be for sale');
        address payable seller = mons[id].owner;
        mons[id].owner = payable(msg.sender);
        mons[id].sharedTo = msg.sender; // Stop sharing since owner changed
        mons[id].forSale = false;
        seller.transfer(msg.value);
    }

    function addForSale(uint256 id, uint256 price) public {
        assert(id < totalMons);
        require(mons[id].owner == msg.sender, 'Only owner can add it to sale');
        mons[id].forSale = true;
        mons[id].sharedTo = msg.sender; // Stop sharing since you sell this
        mons[id].price = price;
    }

    function removeFromSale(uint256 id) public {
        assert(id < totalMons);
        require(mons[id].owner == msg.sender, 'Only owner can remove it from sale');
        mons[id].forSale = false;
    }

    // Function that defines the resulting egg species from breeding
    function findEggSpecies(uint256 id1, uint256 id2) private returns (Species) {
        // Seperation of some Cryptomon species by types. These arrays are used for
        // breeding into random unevolved Cryptomon of the same type
        uint8[5] memory plant = [0, 42, 59, 68, 113];
        uint8[6] memory fire = [3, 36, 57, 76, 125, 145];
        uint8[16] memory water = [6, 53, 59, 71, 78, 85, 89, 97, 115, 117, 119, 128, 130, 137, 139, 143];
        uint8[6] memory bug = [9, 12, 45, 47, 122, 126];
        uint8[19] memory normal = [15, 18, 20, 28, 31, 34, 38, 51, 55, 65, 82, 83, 105, 107, 112, 127, 136, 141, 142];
        uint8[4] memory poison = [22, 40, 87, 108];
        uint8[5] memory thunder = [24, 80, 99, 124, 144];
        uint8[7] memory earth = [26, 49, 73, 94, 103, 110, 114];
        uint8[8] memory psychic = [62, 91, 95, 101, 121, 123, 146, 149];

        Species s;

        if (mons[id2].monType == 9) {
            // If species 2 is DITTO
            s = mons[id1].species; // Replicate species 1
        } else if (mons[id1].monType == 9) {
            // If species 1 is DITTO
            s = mons[id2].species; // Replicate species 2
        } else if (mons[id1].monType == 10) {
            // If species 1 is EEVEE
            if (mons[id2].monType == 1) {
                // Breed with fire
                s = Species(135); // result FLAREON
            } else if (mons[id2].monType == 2) {
                // Breed with water
                s = Species(133); // result VAPOREON
            } else if (mons[id2].monType == 6) {
                // Breed with thunder
                s = Species(134); // result JOLTEON
            } else {
                // Breed with other type
                s = Species(132); // result EEVEE
            }
        } else if (mons[id2].monType == 10) {
            // If species 2 is EEVEE
            if (mons[id1].monType == 1) {
                // Breed with fire
                s = Species(135); // result FLAREON
            } else if (mons[id1].monType == 2) {
                // Breed with water
                s = Species(133); // result VAPOREON
            } else if (mons[id1].monType == 6) {
                // Breed with thunder
                s = Species(134); // result JOLTEON
            } else {
                // Breed with other type
                s = Species(132); // result EEVEE
            }
        } else if (mons[id1].monType == mons[id2].monType) {
            // Only Cryptomons of the same type can breed into evolved type
            if (mons[id1].species == mons[id2].species) {
                // If they are the same species
                if (mons[id1].evolve) {
                    // If they are able to evolve
                    s = Species(uint256(mons[id1].species) + 1); // Produce evolution species
                } else {
                    // If they are not able to evolve
                    s = mons[id1].species; // Produce the same species
                }
            } else {
                // If Cryptomons of the same type but different species then
                // produce a random unevolved Mon of the same type
                if (mons[id1].monType == 0) s = Species(plant[randomGen(5)]);
                else if (mons[id1].monType == 1) s = Species(fire[randomGen(6)]);
                else if (mons[id1].monType == 2) s = Species(water[randomGen(16)]);
                else if (mons[id1].monType == 3) s = Species(bug[randomGen(6)]);
                else if (mons[id1].monType == 4) s = Species(normal[randomGen(19)]);
                else if (mons[id1].monType == 5) s = Species(poison[randomGen(4)]);
                else if (mons[id1].monType == 6) s = Species(thunder[randomGen(5)]);
                else if (mons[id1].monType == 7) s = Species(earth[randomGen(7)]);
                else if (mons[id1].monType == 8) s = Species(psychic[randomGen(8)]);
            }
        } else {
            s = Species(128); // result MAGIKARP/lochness in every other case
        }

        return s;
    }

    function breedMons(uint256 id1, uint256 id2) public {
        assert(id1 < totalMons);
        assert(id2 < totalMons);
        assert(totalMons < max); // Not reached maximum number of mons allowed

        require(mons[id1].owner == msg.sender, 'Only owner can breed a monster');
        require(
            mons[id1].owner == mons[id2].owner && id1 != id2,
            'Must both belong to the same person and be distinct mons'
        );
        require(!(mons[id1].forSale || mons[id1].forSale), "Breeding mons can't be for sale");

        Mon storage mon = mons[totalMons];
        mon.id = totalMons;
        mon.owner = payable(msg.sender);
        mon.species = findEggSpecies(id1, id2);
        mon.price = 0;
        mon.forSale = false;

        mon.monType = monTypes[uint8(mon.species)]; // Assign the type of the cryptomon
        mon.evolve = evolves[uint8(mon.species)]; // Keep whether this cryptomon can evolve

        mon.hp = 110 + randomGen(41);
        mon.atk = 110 + randomGen(41);
        mon.def = 110 + randomGen(41);
        mon.speed = 110 + randomGen(41);

        mon.sharedTo = msg.sender;

        totalMons++;
    }

    function damage(uint256 id1, uint256 id2) private view returns (uint8) {
        return (mons[id1].atk > mons[id2].def) ? 10 : 5;
    }

    function fight(uint256 id1, uint256 id2) public {
        assert(id1 < totalMons);
        assert(id2 < totalMons);
        require(
            mons[id1].owner == msg.sender || mons[id1].sharedTo == msg.sender,
            'Only owner can fight with a mon or if the mon is shared to sender'
        );
        require(!(mons[id1].forSale || mons[id2].forSale), "Fighting mons can't be for sale");
        uint8 hp1 = mons[id1].hp;
        uint8 hp2 = mons[id2].hp;

        uint256 winnerId = 0;
        uint8 round = 0;

        do {
            round++;
            if (mons[id1].speed > mons[id2].speed) {
                if (hp2 < damage(id1, id2)) {
                    winnerId = id1;
                    hp2 = 0;
                    break;
                }
                hp2 = hp2 - damage(id1, id2);

                if (hp1 < damage(id2, id1)) {
                    winnerId = id2;
                    hp1 = 0;
                    break;
                }
                hp1 = hp1 - damage(id2, id1);
            } else {
                if (hp1 < damage(id2, id1)) {
                    winnerId = id2;
                    hp1 = 0;
                    break;
                }
                hp1 = hp1 - damage(id2, id1);
                if (hp2 < damage(id1, id2)) {
                    winnerId = id1;
                    hp2 = 0;
                    break;
                }
                hp2 = hp2 - damage(id1, id2);
            }
        } while (hp1 > 0 && hp2 > 0);

        // check hp's
        if (hp1 == 0) winnerId = id2;
        if (hp2 == 0) winnerId = id1;
        if (hp1 == hp2) winnerId = 12345678910; // it's a tie
        if ((id1 != 0 && id2 != 0) && winnerId == 0) winnerId = 12345678911; // unknown winner

        // reward winning sender with rounds won
        if (mons[winnerId].owner == msg.sender) {
            uint256 rewardAmount = round * 1000000000000000000;
            reward(rewardAmount, msg.sender);
            emit Rewards(winnerId, round);
        }

        emit FightResults(winnerId, round);
    }

    function startSharing(uint256 id, address addr) public {
        assert(id < totalMons);
        require(!mons[id].forSale, "Sharing mon can't be for sale");
        require(mons[id].owner == msg.sender, 'Only owner can share a mon');
        mons[id].sharedTo = addr;
    }

    function stopSharing(uint256 id) public {
        assert(id < totalMons);
        require(
            mons[id].owner == msg.sender || mons[id].sharedTo == msg.sender,
            'Only owner or the address that it is shared to can terminate the sharing of a mon'
        );
        mons[id].sharedTo = mons[id].owner;
    }

    // function that generates pseudorandom numbers
    function randomGen(uint256 i) private returns (uint8) {
        uint8 x = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % i);
        nonce++;
        return x;
    }

    function reward(uint256 _amount, address _sender) private {
        uint256 tokenBalance = _token.balanceOf(address(this));
        require(_amount > 0, 'You need to send reward amount');
        require(_amount <= tokenBalance, 'Not enough tokens in the reserve');
        _token.increaseAllowance(address(this), _amount);
        _token.transfer(_sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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