// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import 'hardhat-deploy/solc_0.8/proxy/Proxied.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './libraries/VRFLibrary.sol';

import './interfaces/IEgg.sol';
import './interfaces/ITraits.sol';
import './interfaces/IChickenNoodle.sol';
import './interfaces/IFarm.sol';
import './interfaces/IRandomnessConsumer.sol';

contract ChickenNoodleSoup is
    IRandomnessConsumer,
    Proxied,
    PausableUpgradeable
{
    using VRFLibrary for VRFLibrary.VRFData;

    // number of tokens have been processed so far
    uint16 public processed;

    // mint price
    uint256 public constant MINT_PRICE = .069420 ether;

    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    // list of probabilities for each trait type
    // 0 - 5 are common, 6 is place holder for Chicken Tier, 7 is Noodles tier
    uint8[][10] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 5 are common, 6 is place holder for Chicken Tier, 7 is Noodles tier
    uint8[][10] public aliases;

    // reference to the Farm for choosing random Noodle thieves
    IFarm public farm;
    // reference to $EGG for burning on mint
    IEgg public egg;
    // reference to ChickenNoodle for minting
    IChickenNoodle public chickenNoodle;

    VRFLibrary.VRFData private vrf;

    mapping(uint256 => bytes32) internal mintBlockhash;

    uint256 randomnessInterval;
    uint256 randomnessMintsNeeded;
    uint256 randomnessMintsMinimum;

    // /**
    //  * initializes contract and rarity tables
    //  */
    // constructor(address _egg, address _chickenNoodle) {
    //     initialize(_egg, _chickenNoodle);
    // }

    /**
     * initializes contract and rarity tables
     */
    function initialize(address _egg, address _chickenNoodle) public proxied {
        __Pausable_init();

        egg = IEgg(_egg);
        chickenNoodle = IChickenNoodle(_chickenNoodle);

        randomnessInterval = 1 hours;
        randomnessMintsNeeded = 500;
        randomnessMintsMinimum = 0;

        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm

        // Common
        // backgrounds
        rarities[0] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            183,
            236,
            252,
            224,
            254,
            255
        ]; //[15, 50, 200, 250, 255];
        aliases[0] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            23,
            23,
            24,
            27,
            27,
            28,
            28,
            28
        ];
        // mouthAccessories
        rarities[1] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            170,
            183,
            236,
            252,
            224,
            250,
            254,
            255
        ];
        aliases[1] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            20,
            23,
            23,
            24,
            27,
            27,
            28,
            28,
            29,
            29
        ];

        // pupils
        rarities[2] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            90,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            180,
            200,
            183,
            236,
            252,
            224,
            254,
            255
        ];
        aliases[2] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            23,
            23,
            24,
            27,
            27,
            28,
            28,
            29,
            29,
            30,
            31
        ];

        // hats
        rarities[3] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            170,
            183,
            236,
            252,
            224,
            250,
            254,
            255,
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            154
        ];
        aliases[3] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            20,
            23,
            23,
            24,
            27,
            27,
            28,
            28,
            29,
            29,
            31,
            32,
            35,
            30,
            31,
            37,
            31,
            40,
            35,
            40,
            41,
            42,
            43,
            44,
            46,
            41,
            47
        ];

        // bodyAccessories
        rarities[4] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            170,
            183,
            236,
            252,
            224,
            250,
            254,
            255,
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            170,
            183,
            236,
            252,
            224,
            250,
            254,
            255,
            60,
            120,
            185,
            210,
            194,
            103,
            209,
            100,
            169,
            178
        ];
        aliases[4] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            20,
            23,
            23,
            24,
            27,
            27,
            28,
            28,
            29,
            29,
            31,
            32,
            35,
            30,
            31,
            37,
            31,
            40,
            35,
            40,
            41,
            42,
            43,
            44,
            46,
            41,
            47,
            53,
            43,
            44,
            47,
            50,
            53,
            53,
            54,
            57,
            57,
            58,
            58,
            59,
            59,
            60,
            69,
            64,
            61,
            70,
            67,
            66,
            68,
            65,
            71
        ];

        // tier
        rarities[5] = [8, 160, 73, 255];
        aliases[5] = [2, 3, 3, 3];

        // snakeBodies Tier 0:5-1:4
        rarities[6] = [185, 215, 240, 190];
        aliases[6] = [1, 2, 2, 0];

        // snakeBodies Tier 0:4-1:3
        rarities[7] = [135, 215, 240, 185];
        aliases[7] = [1, 2, 1, 0];

        // snakeBodies Tier 0:3-1:2
        rarities[8] = [190, 215, 240, 100, 110, 135, 160, 185];
        aliases[8] = [1, 2, 4, 0, 5, 6, 7, 7];

        // snakeBodies Tier 0:2-1:1
        rarities[9] = [190, 215, 240, 100, 110, 135, 160, 185];
        aliases[9] = [1, 2, 4, 0, 5, 6, 7, 7];
    }

    /** EXTERNAL */
    function processingStats()
        public
        view
        returns (
            bool requestPending,
            uint256 maxIdAvailableToProcess,
            uint256 readyForProcessing,
            uint256 waitingToBeProcessed,
            uint256 timeTellNextRandomnessRequest
        )
    {
        return
            vrf.processingStats(
                chickenNoodle.totalSupply(),
                processed,
                randomnessInterval
            );
    }

    /**
     * mint a token - 90% Chicken, 10% Noodles
     * The first 20% cost ETHER to claim, the remaining cost $EGG
     */
    function mint(uint256 amount) external payable whenNotPaused {
        uint16 supply = uint16(chickenNoodle.totalSupply());
        uint256 maxTokens = chickenNoodle.MAX_TOKENS();
        uint256 paidTokens = chickenNoodle.PAID_TOKENS();

        require(tx.origin == _msgSender(), 'Only EOA');
        require(supply + amount <= maxTokens, 'All tokens minted');
        require(amount > 0 && amount <= 10, 'Invalid mint amount');
        if (supply < paidTokens) {
            require(
                supply + amount <= paidTokens,
                'All tokens on-sale already sold'
            );
            require(amount * MINT_PRICE == msg.value, 'Invalid payment amount');
        } else {
            require(msg.value == 0, 'Egg needed not ETHER');
        }

        uint256 totalEggCost = 0;
        for (uint256 i = 0; i < amount; i++) {
            totalEggCost += mintCost(supply + 1 + i);
        }

        if (totalEggCost > 0) {
            egg.burn(_msgSender(), totalEggCost);
            egg.mint(address(this), totalEggCost / 100);
        }

        for (uint256 i = 0; i < amount; i++) {
            _processNext();

            supply++;
            mintBlockhash[supply] = blockhash(block.number - 1);
            chickenNoodle.mint(_msgSender(), supply);
        }

        checkRandomness(false);
    }

    /**
     * the first 20% are paid in ETH
     * the next 20% are 20000 $EGG
     * the next 40% are 40000 $EGG
     * the final 20% are 80000 $EGG
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= chickenNoodle.PAID_TOKENS()) return 0;
        if (tokenId <= (chickenNoodle.MAX_TOKENS() * 2) / 5) return 20000 ether;
        if (tokenId <= (chickenNoodle.MAX_TOKENS() * 4) / 5) return 40000 ether;
        return 80000 ether;
    }

    function checkRandomness(bool force) public {
        force = force && _msgSender() == _proxyAdmin();

        if (force) {
            vrf.newRequest();
        } else {
            vrf.checkRandomness(
                chickenNoodle.totalSupply(),
                processed,
                randomnessInterval,
                randomnessMintsNeeded,
                randomnessMintsMinimum
            );
        }
    }

    function process(uint256 amount) external override {
        for (uint256 i = 0; i < amount; i++) {
            if (!_processNext()) break;
        }
    }

    function setRandomnessResult(bytes32 requestId, uint256 randomness)
        external
        override
    {
        vrf.setRequestResults(
            requestId,
            randomness,
            chickenNoodle.totalSupply()
        );
    }

    function processNext() external override returns (bool) {
        return _processNext();
    }

    /** INTERNAL */

    function _processNext() internal returns (bool) {
        uint16 tokenId = processed + 1;

        (bool available, uint256 randomness) = vrf.randomnessForId(tokenId);

        if (available) {
            uint256 seed = random(tokenId, mintBlockhash[tokenId], randomness);
            IChickenNoodle.ChickenNoodleTraits memory t = generate(
                tokenId,
                seed
            );

            address recipient = selectRecipient(tokenId, seed);

            delete mintBlockhash[tokenId];
            processed++;

            chickenNoodle.finalize(tokenId, t, recipient);
            return true;
        }

        return false;
    }

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for the given token ID
     */
    function generate(uint16 tokenId, uint256 seed)
        internal
        returns (IChickenNoodle.ChickenNoodleTraits memory t)
    {
        t = selectTraits(tokenId, seed);

        if (existingCombinations[structToHash(t)] == 0) {
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }

        return generate(tokenId, random(tokenId, mintBlockhash[tokenId], seed));
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random values
     * @param _randomnessProvider the address of the new RandomnessProvider
     */
    function setRandomnessProvider(address _randomnessProvider)
        external
        override
        onlyProxyAdmin
    {
        vrf.setRandomnessProvider(_randomnessProvider);
    }

    /**
     * called to upoate fee to get randomness
     * @param _fee the fee required for getting randomness
     */
    function updateRandomnessFee(uint256 _fee)
        external
        override
        onlyProxyAdmin
    {
        vrf.updateFee(_fee);
    }

    /**
     * allows owner to rescue LINK tokens
     */
    function rescueLINK(uint256 amount) external override onlyProxyAdmin {
        vrf.rescueLINK(_proxyAdmin(), amount);
    }

    /**
     * called after deployment so that the contract can get random noodle thieves
     * @param _farm the address of the HenHouse
     */
    function setFarm(address _farm) external onlyProxyAdmin {
        farm = IFarm(_farm);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyProxyAdmin {
        payable(_proxyAdmin()).transfer(address(this).balance);
    }

    /**
     * allows owner to rescue tokens
     */
    function rescue(IERC20 token, uint256 amount) external onlyProxyAdmin {
        token.transfer(_proxyAdmin(), amount);
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyProxyAdmin {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(uint16 seed, uint8 traitType)
        internal
        view
        returns (uint8)
    {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);

        if (seed >> 8 < rarities[traitType][trait]) {
            return trait;
        }

        return aliases[traitType][trait];
    }

    /**
     * the first 20% (ETH purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked noodle
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the Noodle thief's owner)
     */
    function selectRecipient(uint256 tokenId, uint256 seed)
        internal
        view
        returns (address)
    {
        if (
            tokenId <= chickenNoodle.PAID_TOKENS() || ((seed >> 245) % 10) != 0
        ) {
            // top 10 bits haven't been used
            return chickenNoodle.ownerOf(tokenId);
        }
        address thief = farm.randomNoodleOwner(seed >> 144); // 144 bits reserved for trait selection

        if (thief == address(0x0)) {
            return chickenNoodle.ownerOf(tokenId);
        }

        return thief;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(uint256 tokenId, uint256 seed)
        internal
        view
        returns (IChickenNoodle.ChickenNoodleTraits memory t)
    {
        t.minted = true;

        t.isChicken = (seed & 0xFFFF) % 10 != 0;

        seed >>= 16;
        t.backgrounds = selectTrait(uint16(seed & 0xFFFF), 0);

        seed >>= 16;
        t.mouthAccessories = selectTrait(uint16(seed & 0xFFFF), 1);

        seed >>= 16;
        t.pupils = selectTrait(uint16(seed & 0xFFFF), 2);

        seed >>= 16;
        t.hats = selectTrait(uint16(seed & 0xFFFF), 3);

        seed >>= 16;
        t.bodyAccessories = t.isChicken
            ? 0
            : selectTrait(uint16(seed & 0xFFFF), 4);

        seed >>= 16;
        uint8 tier = selectTrait(uint16(seed & 0xFFFF), 5);

        uint8 snakeBodiesPlacement = 0;

        if (tier == 1) {
            snakeBodiesPlacement = 4;
        } else if (tier == 2) {
            snakeBodiesPlacement = 8;
        } else if (tier == 3) {
            snakeBodiesPlacement = 16;
        }

        seed >>= 16;
        t.snakeBodies =
            snakeBodiesPlacement +
            selectTrait(uint16(seed & 0xFFFF), 6 + t.tier);

        t.tier = t.isChicken
            ? 0
            : (tokenId <= chickenNoodle.PAID_TOKENS() ? 5 : 4) - tier;
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
     * @return the 256 bit hash of the struct
     */
    function structToHash(IChickenNoodle.ChickenNoodleTraits memory s)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        s.minted,
                        s.isChicken,
                        s.backgrounds,
                        s.snakeBodies,
                        s.mouthAccessories,
                        s.pupils,
                        s.bodyAccessories,
                        s.hats,
                        s.tier
                    )
                )
            );
    }

    /**
     * generates a pseudorandom number
     * @param tokenId a value ensure different outcomes for different sources in the same block
     * @param mintHash minthash stored at time of initial mint
     * @param seed vrf random value
     * @return a pseudorandom value
     */
    function random(
        uint16 tokenId,
        bytes32 mintHash,
        uint256 seed
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tokenId, mintHash, seed)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity ^0.8.0;

import '../interfaces/IRandomnessProvider.sol';

library VRFLibrary {
    struct VRFData {
        IRandomnessProvider randomnessProvider;
        bytes32 lastRequestId;
        mapping(uint256 => uint256) highestIdForRandomness;
        mapping(uint256 => uint256) randomResults;
        uint256 lastRequest;
        uint256 minResultIndex;
        uint256 resultsReceived;
    }

    modifier onlyRandomnessProvider(VRFData storage self) {
        require(
            msg.sender == address(self.randomnessProvider),
            'Required to be randomnessProvider'
        );
        _;
    }

    function processingStats(
        VRFData storage self,
        uint256 maxId,
        uint256 processedId,
        uint256 interval
    )
        public
        view
        returns (
            bool requestPending,
            uint256 maxIdAvailableToProcess,
            uint256 readyForProcessing,
            uint256 waitingToBeProcessed,
            uint256 timeTellNextRandomnessRequest
        )
    {
        timeTellNextRandomnessRequest = self.lastRequest + interval < block.timestamp
                ? 0
                : (self.lastRequest + interval) - block.timestamp;

        return (
            self.lastRequestId != '' && timeTellNextRandomnessRequest > interval / 2,
            self.highestIdForRandomness[self.resultsReceived],
            self.highestIdForRandomness[self.resultsReceived] - processedId,
            maxId - self.highestIdForRandomness[self.resultsReceived],
            timeTellNextRandomnessRequest
        );
    }

    function checkRandomness(
        VRFData storage self,
        uint256 maxId,
        uint256 processedId,
        uint256 interval,
        uint256 needed,
        uint256 minimum
    ) external {
        (
            bool requested,
            ,
            ,
            uint256 processingNeeded,
            uint256 timeTellNext
        ) = processingStats(self, maxId, processedId, interval);

        if (
            !requested &&
            (processingNeeded >= needed ||
                (timeTellNext == 0 && processingNeeded > minimum))
        ) {
            newRequest(self);
        }
    }

    function newRequest(VRFData storage self) public {
        bytes32 requestId = self.randomnessProvider.newRandomnessRequest();

        if (requestId != '') {
            self.lastRequest = block.timestamp;
            self.lastRequestId = requestId;
        }
    }

    function setRequestResults(
        VRFData storage self,
        bytes32 requestId,
        uint256 randomness,
        uint256 maxId
    ) public onlyRandomnessProvider(self) {
        if (self.lastRequestId == requestId) {
            self.resultsReceived++;
            self.randomResults[self.resultsReceived] = randomness;
            self.highestIdForRandomness[self.resultsReceived] = maxId;
            self.lastRequestId = '';
        }
    }

    function randomnessForId(VRFData storage self, uint256 id)
        public
        returns (bool available, uint256 randomness)
    {
        while (
            self.highestIdForRandomness[self.minResultIndex] < id &&
            self.minResultIndex < self.resultsReceived
        ) {
            delete self.randomResults[self.minResultIndex];
            delete self.highestIdForRandomness[self.minResultIndex];
            self.minResultIndex++;
        }

        if (self.highestIdForRandomness[self.minResultIndex] >= id) {
            return (true, self.randomResults[self.minResultIndex]);
        }

        return (false, 0);
    }

    function setRandomnessProvider(
        VRFData storage self,
        address randomnessProvider
    ) public {
        self.randomnessProvider = IRandomnessProvider(randomnessProvider);
    }

    function updateFee(VRFData storage self, uint256 fee) public {
        self.randomnessProvider.updateFee(fee);
    }

    function rescueLINK(
        VRFData storage self,
        address to,
        uint256 amount
    ) public {
        self.randomnessProvider.rescueLINK(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEgg {
    /**
     * mints $EGG to a recipient
     * @param to the recipient of the $EGG
     * @param amount the amount of $EGG to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * burns $EGG from a holder
     * @param from the holder of the $EGG
     * @param amount the amount of $EGG to burn
     */
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChickenNoodle {
    // struct to store each token's traits
    struct ChickenNoodleTraits {
        bool minted;
        bool isChicken;
        uint8 backgrounds;
        uint8 snakeBodies;
        uint8 mouthAccessories;
        uint8 pupils;
        uint8 bodyAccessories;
        uint8 hats;
        uint8 tier;
    }

    function MAX_TOKENS() external view returns (uint256);

    function PAID_TOKENS() external view returns (uint256);

    function tokenTraits(uint256 tokenId)
        external
        view
        returns (ChickenNoodleTraits memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(address to, uint16 tokenId) external;

    function finalize(
        uint16 tokenId,
        ChickenNoodleTraits memory traits,
        address thief
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IChickenNoodle.sol';

interface IFarm {
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    struct PagingData {
        address tokenOwner;
        uint16 limit;
        uint16 page;
    }

    function totalChickenStaked() external view returns (uint16);

    function MINIMUM_TO_EXIT() external view returns (uint256);

    function MAX_TIER_SCORE() external view returns (uint8);

    function MAXIMUM_GLOBAL_EGG() external view returns (uint256);

    function DAILY_GEN0_EGG_RATE() external view returns (uint256);

    function DAILY_GEN1_EGG_RATE() external view returns (uint256);

    function eggPerTierScore() external view returns (uint256);

    function totalEggEarned() external view returns (uint256);

    function lastClaimTimestamp() external view returns (uint256);

    function denIndices(uint16 tokenId) external view returns (uint16);

    function chickenNoodle() external view returns (IChickenNoodle);

    function isChicken(uint16 tokenId) external view returns (bool);

    function tierScoreForNoodle(uint16 tokenId) external view returns (uint8);

    function randomNoodleOwner(uint256 seed) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomnessConsumer {
    function setRandomnessResult(bytes32 requestId, uint256 randomness)
        external;

    function process(uint256 amount) external;

    function processNext() external returns (bool);

    function setRandomnessProvider(address _randomnessProvider) external;

    function updateRandomnessFee(uint256 _fee) external;

    function rescueLINK(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomnessProvider {
    function newRandomnessRequest() external returns (bytes32);

    function updateFee(uint256) external;

    function rescueLINK(address to, uint256 amount) external;
}