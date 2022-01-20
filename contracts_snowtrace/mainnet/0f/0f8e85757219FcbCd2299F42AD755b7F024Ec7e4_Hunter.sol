import "./IHunter.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IBarn.sol";
import "./IGEM.sol";
import "./ITraits.sol";
import "./ISeed.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hunter is IHunter, ERC721Enumerable, Ownable, Pausable {
    // uint256 public constant MAX_PER_MINT = 10;
    // mint price 1.5AVAX
    uint256 public constant MINT_PRICE = 1.5 ether;

    //whitelist price  1.25 avax
    uint256 public constant WL_PRICE = 1.25 ether;
    // max number of tokens that can be minted - 50000 in production
    uint256 public MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public minted;
    uint16 public Adventurer_minted;
    uint16 public Hunter_minted;
    // Pre mint
    uint256 public startTimestamp;
    uint256 public endTimestamp;

    // payment wallets
    address payable AdminWallet;
    address payable Multisig;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => AvtHtr) public tokenTraits;

    // WhiteList
    mapping(address => bool) public WhiteList;

    mapping(address => uint256) public whiteListMintCounts;

    // list of probabilities for each trait type
    // 0 - 6 are associated with Adventurers, 7 - 12 are associated with hunters
    uint8[][12] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 6 are associated with Adventurers, 6 - 12 are associated with Hunters
    uint8[][12] public aliases;

    // reference to the Barn for choosing random Hunter thieves
    IBarn public barn;
    // reference to $GEM for burning on mint
    IGEM public gem;
    // reference to Traits
    ITraits public traits;
    // reference to Seed
    ISeed public randomSource;

    /**
     * instantiates contract and rarity tables
     */

    constructor(
        address _gem,
        address _traits,
        uint256 _maxTokens
    ) ERC721("Yield Hunt", "HGAME") {
        AdminWallet = payable(0x9F523A9d191704887Cf667b86d3B6Cd6eBE9D6e9);
        Multisig = payable(0x49208f9eEAD9416446cdE53435C6271A0235dDA4);
        gem = IGEM(_gem);
        traits = ITraits(_traits);
        MAX_TOKENS = _maxTokens;
        PAID_TOKENS = _maxTokens / 5;
    }

    function setTraits(address _traits) external onlyOwner {
        traits = ITraits(_traits);
    }

    /** EXTERNAL */
    function setTimeforPremint(uint256 _startTimestamp, uint256 _endTimestamp)
        external
        onlyOwner
    {
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }

    modifier onlyWhileOpen() {
        require(
            block.timestamp >= startTimestamp && block.timestamp <= endTimestamp
        );
        _;
    }

    modifier onlyWhileClose() {
        require(block.timestamp > endTimestamp);
        _;
    }

    function isOpened() public view returns (bool) {
        return
            block.timestamp >= startTimestamp &&
            block.timestamp <= endTimestamp;
    }

    function isClosed() public view returns (bool) {
        return block.timestamp > endTimestamp;
    }

    function setWhitelist(address[] memory _whitelist) external onlyOwner {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            WhiteList[_whitelist[i]] = true;
        }
    }

    /*
     * mint a token - 90% Adventurers, 10% Hunters
     * The first 20% are free to claim, the remaining cost $GEM
     */
    function mint(uint256 amount, bool stake) external payable whenNotPaused {
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0, "Invalid mint amount");
        if (isOpened()) {
            _premint(amount, stake);
        } else if (isClosed()) {
            _normal_mint(amount, stake);
        }
    }

    // after white list period
    function _normal_mint(uint256 amount, bool stake) private onlyWhileClose {
        //MAYBE WHITELISTED CAN MINT 1.25
        require(tx.origin == _msgSender(), "Only EOA");
        if (minted < PAID_TOKENS) {
            require(
                minted + amount <= PAID_TOKENS,
                "All tokens on-sale already sold"
            );

            require(
                amount * MINT_PRICE <= msg.value || _msgSender() == AdminWallet,
                "Invalid payment amount"
            );
        } else {
            require(
                msg.value == 0,
                "Do not send AVAX, minting is with GEM now"
            );
        }

        core_mint(amount, stake);
    }

    // during white list period
    function _premint(uint256 amount, bool stake) private onlyWhileOpen {
        require(tx.origin == _msgSender(), "Only EOA");
        require(WhiteList[_msgSender()], "You are not whitelisted");
        require(
            whiteListMintCounts[_msgSender()] + amount <= 5,
            "White list can only mint 5"
        );
        require(
            minted + amount <= PAID_TOKENS,
            "All tokens on-sale already sold"
        );

        require(
            amount * WL_PRICE <= msg.value || _msgSender() == AdminWallet,
            "Invalid payment amount"
        );
        whiteListMintCounts[_msgSender()] += amount;
        core_mint(amount, stake);
    }

    function core_mint(uint256 amount, bool stake) private {
        uint256 totalGemCost = 0;
        uint16[] memory tokenIds = stake
            ? new uint16[](amount)
            : new uint16[](0);
        uint256 seed;
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            generate(minted, seed);
            address recipient = selectRecipient(seed);
            if (!stake || recipient != _msgSender()) {
                _safeMint(recipient, minted);
            } else {
                _safeMint(address(barn), minted);
                tokenIds[i] = minted;
            }
            if (tokenTraits[minted].isAdventurer) {
                Adventurer_minted += 1;
            } else {
                Hunter_minted += 1;
            }
            totalGemCost += mintCost(minted); // 0 if we are before 10.000
        }

        //we may want to do that first but w/o reentrancy
        if (totalGemCost > 0) gem.burn(_msgSender(), totalGemCost);
        if (stake) barn.addManyToBarnAndPack(_msgSender(), tokenIds);
        withdrawMoneyTo(Multisig); //hihi
    }

    /**
     * the first 20% are paid in AVAX
     * the next 20% are 20000 $GEM
     * the next 40% are 40000 $GEM
     * the final 20% are 80000 $GEM
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
        returns (AvtHtr memory t)
    {
        t = selectTraits(seed);
        tokenTraits[tokenId] = t;

        return t;
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
        return traits.selectTrait(seed, traitType);
    }

    /**
     * the first 20% (AVAX purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked adventurer
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the adventurer thief's owner)
     */
    function selectRecipient(uint256 seed) internal view returns (address) {
        if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0)
            return _msgSender(); // top 10 bits haven't been used
        address thief = barn.randomHunterOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return _msgSender();
        return thief;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param _seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(uint256 _seed)
        internal
        view
        returns (AvtHtr memory t)
    {
        uint256 seed = _seed;
        t.isAdventurer = (seed & 0xFFFF) % 10 != 0;
        if (t.isAdventurer) {
            seed >>= 16;
            t.jacket = selectTrait(uint16(seed & 0xFFFF), 0);
            seed >>= 16;
            t.hair = selectTrait(uint16(seed & 0xFFFF), 1);
            seed >>= 16;
            t.backpack = selectTrait(uint16(seed & 0xFFFF), 2);
        } else {
            seed >>= 16;
            t.arm = selectTrait(uint16(seed & 0xFFFF), 3);
            seed >>= 16;
            t.clothes = selectTrait(uint16(seed & 0xFFFF), 4);
            seed >>= 16;
            t.mask = selectTrait(uint16(seed & 0xFFFF), 5);
            seed >>= 16;
            t.weapon = selectTrait(uint16(seed & 0xFFFF), 6);
            seed >>= 16;
            t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 7);
        }
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */

    // need to use seed contract
    function random(uint256 seed) internal returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            ) ^ randomSource.getRandomSeed(seed);
    }

    /** READ */

    function getTokenTraits(uint256 tokenId)
        external
        view
        override
        returns (AvtHtr memory)
    {
        return tokenTraits[tokenId];
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random adventurers thieves
     * @param _barn the address of the Barn
     */
    function setBarn(address _barn) external onlyOwner {
        barn = IBarn(_barn);
    }

    function setRandomSource(address _randomSource) external onlyOwner {
        randomSource = ISeed(_randomSource);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoneyTo(address payable _to) internal {
        _to.transfer(getBalance());
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * updates the number of tokens for sale
     */
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** RENDER */

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
}