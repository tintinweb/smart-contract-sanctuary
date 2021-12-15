// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ERC20.sol";
import "./IWoolf.sol";
import "./IBarn.sol";
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

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Woolf is IWoolf, ERC721Enumerable, Ownable, Pausable {
    ISuperShibaBAMC public bamc;
    ISuperShibaClub public club;
    Pool public pool;

    // mint price
    uint256 public MINT_PRICE = 0.002 ether;
    // max number of tokens that can be minted - 50000 in production
    uint256 public immutable MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public minted = 0;

    uint256 public LP = 5000000000000000000;
    uint256 public LPAmount = 0;

    uint256 public apeCount = 0;
    uint256 public wolfCount = 0;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => ApeWolf) public tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    mapping(uint256 => address) public superShibaBAMCTokensMint;
    mapping(uint256 => address) public superShibaClubTokensMint;

    struct StakeLP {
        uint256 value;
        uint256 time;
    }
    mapping(address => StakeLP) public LPMap;

    // list of probabilities for each trait type
    // 0 - 9 are associated with Ape, 10 - 18 are associated with Wolves
    uint8[][18] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 9 are associated with Ape, 10 - 18 are associated with Wolves
    uint8[][18] public aliases;

    // reference to the Barn for choosing random Wolf thieves
    IBarn public barn;
    // reference to $MutantPeach for burning on mint
    MutantPeach public mutantPeach;
    // reference to Traits
    ITraits public traits;

    address private wolfGameTreasury;

    /**
     * instantiates contract and rarity tables
     */
    constructor(
        address _peach,
        address _traits,
        uint256 _maxTokens,
        address _superShibaBAMC,
        address _superShibaClub
    ) ERC721("Wolf Game", "WGAME") {
        // 桃子币合约
        mutantPeach = MutantPeach(_peach);
        // nft合约
        traits = ITraits(_traits);
        // 最大数量
        MAX_TOKENS = _maxTokens;
        // eth能购买的最大数量
        PAID_TOKENS = _maxTokens / 5;
        // superShibaBAMC合约
        bamc = ISuperShibaBAMC(_superShibaBAMC);
        // superShibaClub合约
        club = ISuperShibaClub(_superShibaClub);

        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // ape
        // fur
        rarities[0] = [15, 50, 200, 250, 255];
        aliases[0] = [4, 4, 4, 4, 4];
        // head
        rarities[1] = [
            190,
            215,
            240,
            100,
            110,
            135,
            160,
            185,
            80,
            210,
            235,
            240,
            80,
            80,
            100,
            100,
            100,
            245,
            250,
            255
        ];
        aliases[1] = [
            1,
            2,
            4,
            0,
            5,
            6,
            7,
            9,
            0,
            10,
            11,
            17,
            0,
            0,
            0,
            0,
            4,
            18,
            19,
            19
        ];
        // ears
        rarities[2] = [255, 30, 60, 60, 150, 156];
        aliases[2] = [0, 0, 0, 0, 0, 0];
        // eyes
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
            183,
            236,
            252,
            224,
            255
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
            23,
            23,
            24,
            27,
            27,
            27,
            27
        ];
        // nose
        rarities[4] = [175, 100, 40, 250, 115, 100, 185, 175, 180, 255];
        aliases[4] = [3, 0, 4, 6, 6, 7, 8, 8, 9, 9];
        // mouth
        rarities[5] = [
            80,
            225,
            227,
            228,
            112,
            240,
            64,
            160,
            167,
            217,
            171,
            64,
            240,
            126,
            80,
            255
        ];
        aliases[5] = [1, 2, 3, 8, 2, 8, 8, 9, 9, 10, 13, 10, 13, 15, 13, 15];
        // neck
        rarities[6] = [255];
        aliases[6] = [0];
        // feet
        rarities[7] = [
            243,
            189,
            133,
            133,
            57,
            95,
            152,
            135,
            133,
            57,
            222,
            168,
            57,
            57,
            38,
            114,
            114,
            114,
            255
        ];
        aliases[7] = [
            1,
            7,
            0,
            0,
            0,
            0,
            0,
            10,
            0,
            0,
            11,
            18,
            0,
            0,
            0,
            1,
            7,
            11,
            18
        ];
        // alphaIndex
        rarities[8] = [255];
        aliases[8] = [0];

        // wolves
        // fur
        rarities[9] = [210, 90, 9, 9, 9, 150, 9, 255, 9];
        aliases[9] = [5, 0, 0, 5, 5, 7, 5, 7, 5];
        // head
        rarities[10] = [255];
        aliases[10] = [0];
        // ears
        rarities[11] = [255];
        aliases[11] = [0];
        // eyes
        rarities[12] = [
            135,
            177,
            219,
            141,
            183,
            225,
            147,
            189,
            231,
            135,
            135,
            135,
            135,
            246,
            150,
            150,
            156,
            165,
            171,
            180,
            186,
            195,
            201,
            210,
            243,
            252,
            255
        ];
        aliases[12] = [
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            13,
            3,
            6,
            14,
            15,
            16,
            16,
            17,
            18,
            19,
            20,
            21,
            22,
            23,
            24,
            25,
            26,
            26,
            26
        ];
        // nose
        rarities[13] = [255];
        aliases[13] = [0];
        // mouth
        rarities[14] = [
            239,
            244,
            249,
            234,
            234,
            234,
            234,
            234,
            234,
            234,
            130,
            255,
            247
        ];
        aliases[14] = [1, 2, 11, 0, 11, 11, 11, 11, 11, 11, 11, 11, 11];
        // neck
        rarities[15] = [
            75,
            180,
            165,
            120,
            60,
            150,
            105,
            195,
            45,
            225,
            75,
            45,
            195,
            120,
            255
        ];
        aliases[15] = [1, 9, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 14, 12, 14];
        // feet
        rarities[16] = [255];
        aliases[16] = [0];
        // alphaIndex
        rarities[17] = [8, 160, 73, 255];
        aliases[17] = [2, 3, 3, 3];
    }

    /** EXTERNAL */

    /**
     * mint a token - 90% Ape, 10% Wolves
     * The first 20% are free to claim, the remaining cost $MutantPeach
     */
    function mint(uint256 amount, bool stake) external payable whenNotPaused {
        // 验证合约调用人是否是本人
        require(tx.origin == _msgSender(), "Only EOA");
        // 验证mint数量是否达到上限
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        // 一次最多mint 10个
        require(amount > 0 && amount <= 10, "Invalid mint amount");
        // 验证购买限制是否上限
        if (minted < PAID_TOKENS) {
            require(
                minted + amount <= PAID_TOKENS,
                "All tokens on-sale already sold"
            );
            require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
        } else {
            require(msg.value == 0);
        }

        // 总共桃子花费
        uint256 totalWoolCost = 0;

        uint16[] memory tokenIds = stake
            ? new uint16[](amount)
            : new uint16[](0);
        uint256 seed;
        for (uint256 i = 0; i < amount; i++) {
            // 已被mint数量自增
            minted++;
            // 获得随机数
            seed = random(minted);
            // 校验nft是否被偷走
            address recipient = selectRecipient(seed);
            // 如果stake为false或者nft被偷走 stake => 是否把mint的nft直接质押
            if (!stake || recipient != _msgSender()) {
                _safeMint(recipient, minted);
            } else {
                _safeMint(address(barn), minted);
                tokenIds[i] = minted;
            }
            generate(minted, seed);
            totalWoolCost += mintCost(minted);
        }

        if (totalWoolCost > 0) mutantPeach.burn(_msgSender(), totalWoolCost);
        if (stake) barn.addManyToBarnAndPack(_msgSender(), tokenIds);
    }

    // function freeMint(bool stake) external whenNotPaused {
    //   // 验证合约调用人是否是本人
    //   require(tx.origin == _msgSender(), "Only EOA");

    //   uint256 bamcCount = bamc.balanceOf(msg.sender);
    //   uint256 clubCount = club.balanceOf(msg.sender);
    //   // 抱歉，您没有shiba
    //   require(bamcCount > 0 || clubCount > 0, "Sorry, you don't have shiba");
    //   uint256 mintCount = 0;
    //   for (uint256 i = 0; i < bamcCount; i++) {
    //     uint256 bamcTokenId = bamc.tokenOfOwnerByIndex(msg.sender, i);
    //     if (superShibaBAMCTokensMint[bamcTokenId] == address(0)) {
    //       mintCount++;
    //       superShibaBAMCTokensMint[bamcTokenId] = msg.sender;
    //     }
    //   }

    //   for (uint256 i = 0; i < clubCount; i++) {
    //     uint256 clubTokenId = club.tokenOfOwnerByIndex(msg.sender, i);
    //     if (superShibaClubTokensMint[clubTokenId] == address(0)) {
    //       mintCount++;
    //       superShibaClubTokensMint[clubTokenId] = msg.sender;
    //     }
    //   }

    //   // 验证mint数量是否达到上限
    //   require(minted + mintCount <= MAX_TOKENS, "All tokens minted");

    //   // 您钱包里的shiba已经mint过了
    //   require(mintCount > 0, "The shiba in your wallet has been mint");

    //   _freeMint(mintCount, stake);

    // }

    function freeMint(uint256[] memory bamcIds, uint256[] memory clubIds)
        external
        whenNotPaused
    {
        // 验证合约调用人是否是本人
        require(tx.origin == _msgSender(), "Only EOA");

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
            if (bamc.ownerOf(tokenId) == _msgSender()) {
                if (superShibaClubTokensMint[tokenId] == address(0)) {
                    mintCount++;
                    superShibaClubTokensMint[tokenId] = _msgSender();
                }
            }
        }

        // 验证mint数量是否达到上限
        require(minted + mintCount <= MAX_TOKENS, "All tokens minted");

        // 您钱包里的shiba已经mint过了
        require(mintCount > 0, "The shiba in your wallet has been mint");

        _freeMint(mintCount);
    }

    function _freeMint(uint256 amount) private whenNotPaused {
        uint256 seed;
        for (uint256 i = 0; i < amount; i++) {
            // 已被mint数量自增
            minted++;
            // 获得随机数
            seed = random(minted);

            _safeMint(msg.sender, minted);

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
        // Hardcode the Barn's approval so that users don't have to waste gas approving
        if (_msgSender() != address(barn))
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    /** INTERNAL */

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for the given token ID
     */
    function generate(uint256 tokenId, uint256 seed)
        internal
        returns (ApeWolf memory t)
    {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            if (t.isApe) {
                apeCount++;
            } else {
                wolfCount++;
            }
            return t;
        }
        return generate(tokenId, random(seed));
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
        uint16 num = 0;
        if (LPMap[_msgSender()].value >= LP) {
            num = 4;
        }
        if (minted <= PAID_TOKENS || ((seed >> 245) % 10) <= num)
            return _msgSender(); // top 10 bits haven't been used
        address thief = barn.randomWolfOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return _msgSender();
        return thief;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(uint256 seed)
        internal
        view
        returns (ApeWolf memory t)
    {
        t.isApe = (seed & 0xFFFF) % 10 != 0;
        uint8 shift = t.isApe ? 0 : 9;
        seed >>= 16;
        t.fur = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.head = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.ears = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.nose = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.mouth = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.neck = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        seed >>= 16;
        t.feet = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        seed >>= 16;
        t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
     * @return the 256 bit hash of the struct
     */
    function structToHash(ApeWolf memory s) internal pure returns (uint256) {
        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        s.isApe,
                        s.fur,
                        s.head,
                        s.eyes,
                        s.mouth,
                        s.neck,
                        s.ears,
                        s.feet,
                        s.alphaIndex
                    )
                )
            );
    }

    /** READ */

    function sendLP(uint256 amount) external {
        pool.transferFrom(_msgSender(), address(this), amount);
        StakeLP memory stake = LPMap[_msgSender()];
        stake.value += amount;
        stake.time = uint256(block.timestamp);
        LPMap[_msgSender()] = stake;
    }

    function getLP() external {
        StakeLP memory stake = LPMap[_msgSender()];
        require(
            uint256(block.timestamp) - stake.time > uint256(30 days),
            "stop"
        );
        pool.transferFrom(address(this), _msgSender(), stake.value);
        stake.value = 0;
        LPMap[_msgSender()] = stake;
        LPAmount -= stake.value;
    }

    function getTokenTraits(uint256 tokenId)
        external
        view
        override
        returns (ApeWolf memory)
    {
        return tokenTraits[tokenId];
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random wolf thieves
     * @param _barn the address of the Barn
     */
    function setBarn(address _barn) external onlyOwner {
        barn = IBarn(_barn);
    }

    function setMPeach(address _MPeach) external onlyOwner {
        mutantPeach = MutantPeach(_MPeach);
    }

    function setPool(address _pool) external onlyOwner {
        pool = Pool(_pool);
    }

    function setSuperShibaBAMCAddress(address _address) external onlyOwner {
        bamc = ISuperShibaBAMC(_address);
    }

    function setSuperShibaClubAddress(address _address) external onlyOwner {
        club = ISuperShibaClub(_address);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(wolfGameTreasury).transfer(address(this).balance);
    }

    function withdrawByLP(address to, uint256 amount) external onlyOwner {
        pool.transferFrom(address(this), to, amount);
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

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return traits.tokenURI(tokenId);
    }

    function setTreasury(address _treasury) external onlyOwner {
        wolfGameTreasury = _treasury;
    }
}