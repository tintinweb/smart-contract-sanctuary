// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IN is IERC721 {
    function getFirst(uint256 tokenId) external view returns (uint256);

    function getSecond(uint256 tokenId) external view returns (uint256);

    function getThird(uint256 tokenId) external view returns (uint256);

    function getFourth(uint256 tokenId) external view returns (uint256);

    function getFifth(uint256 tokenId) external view returns (uint256);

    function getSixth(uint256 tokenId) external view returns (uint256);

    function getSeventh(uint256 tokenId) external view returns (uint256);

    function getEight(uint256 tokenId) external view returns (uint256);
}

interface IPunk {
    function balanceOf(address wallet) external view returns (uint256);
}

interface IERC721Farm {
    function depositsOf(address account) external view returns (uint256[] memory);
}

/*
    https://twitter.com/_n_collective

    Pythagoras said that The Universal Creator had formed two things in His own image: the first was the cosmic system
    with its myriads of suns, moons, and planets; the second was Man, in whose nature the entire universe existed in miniature.
    ... that Man will resurrect once the clock embraces the cold.
    Caution! To witness him resurrect, a Weapon must be given in due sacrifice once the cold arrives.

    Men lured by desire, trust is no option. Trust must be minimized for the alternate reality to arrive — the metaverse.
    The Weapons are of great significance, for that a mission of this scale does not come without opposition.
    The Collective must be determined to protect the idea of a trustless alternate existence over generations to come, silently.

    The faceless. We became self-aware only to realize that this story is not about us. The Collective understands this story is not about us.
    The Collective always prevails.

    Let us cheer the Collective contributors — below with their Discord names — holding up high our values,
    our beliefs, with rigorous loyalty; engrave them on what is the fundament of the trustless reality to come — the Ethereum blockchain.
    These are snippets from the Collective Discord, #philosophy channel (https://discord.gg/pfhtnhPsPB):

    browntaneer on the origin story of the Collective:
    "Before the Collective, there was One.

    One made no friends, held no lovers, had no names.
    All too aware of the limitations imposed by one's mortality, One worked to change all that they could.
    But a life fought hard, and lived well can only take one so far.

    A lifetime could be spent in making a castle but, if sculpted with sand, the waves of time will wash it all away.

    How does One endure when a single lifetime isn't enough.
    Who could One trust?
    How can One shed the baggage of one’s name and birth?
    How can we hide what we were given, so that we may show what we choose to be?"

    Kummatti:
    "our Masks hide who we are expected to be. and reveal who we truly are. the Collective."

    Redrobot:
    "We wear the mask that grins and lies,
    It hides our cheeks and shades our eyes,—
    This debt we pay to human guile;
    With torn and bleeding hearts we smile,
    And mouth with myriad subtleties.

    Why should the world be over-wise,
    In counting all our tears and sighs?
    Nay, let them only see us, while
    We wear the Mask.

    We smile, but, O great Christ, our cries
    To thee from tortured souls arise.
    We sing, but oh the clay is vile
    Beneath our feet, and long the mile;
    But let the world dream otherwise,
    We wear the Mask!"

    Kummatti:
    "some say the Mask is to hide the truth.
    but what do they know?
    truth can’t be hidden.
    truth can’t be veiled.
    truth can’t be masked.
    truth is.
    the Mask is."
    truth can’t be hidden.
    they’re just unwilling to see the Collective.

    Nietzsche:
    "In a crowd, faces disappear"

    Kummatti:
    "Don't aspire to be what others want you to be
    Aspire to be all that you can be
    The rest will follow"

    This is the Collective. Welcome.
*/
contract PythagoreanWeapons is ERC721, Ownable, ReentrancyGuard, ERC721Holder {
    IN public constant n = IN(0x05a46f1E545526FB803FF974C790aCeA34D1f2D6);
    IPunk public constant punk = IPunk(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    IERC721 public constant bayc = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    IERC721 public constant mask = IERC721(0x6327f6305331f7E0CCFcaC2bCA4a4a8B87afDa32);
    IERC721Farm public constant treasure = IERC721Farm(0x08543f4c79f7e5d585A2622cA485e8201eFd9aDA);

    string[29] public ADJECTIVES = ["Glowing", "Savage", "Forgotten", "Flaming", "Stormy", "Fierce", "Corrupted", "Blazing", "Bleeding", "Dark", "Ancient", "Divine", "Cursed", "Chaotic", "Titanic", "Mortal", "Blessed", "Vicious", "Numeric", "Devil", "Demonic", "Holy", "Mighty", "Cold", "Sinister", "Lunar", "Hardened", "Reaping", "Ravenous"];
    string[29] public NOUNS = ["Wind", "Night", "Moon", "Iron", "Dawn", "Sky", "Soul", "Breath", "Scream", "Oath", "Edge", "Winter", "Silver", "Ice", "Justice", "Fate", "Star", "Strike", "Pride", "Rage", "Sacrifice", "Shadow", "Victory", "War", "Truth", "Moonlight", "Thunder", "Steel", "Torrent"];
    string[29] public PLACES = ["Ellora", "Xi'an", "Alexandria", "Pythagore", "Teotihuacan", "Nineveh", "Angkor Wat", "Varanasi", "Carthage", "Ephesus", "Cusco", "Crotone", "Samos", "Luna", "Moghul", "Shartadar", "Muramar", "Stonefort", "Ambar City", "Fulghot", "Ramberseit", "Thambert", "Annon Tul", "Gondol", "Novastarius", "Centhuron", "Numbers Citadel", "Kartaros", "Silverthrone"];
    string[9] public PARTS = ["Body", "Blood Mark", "Button", "Handle", "Quillon", "Pommel", "Ornament", "Pythagor's Mark", "Tilt"];
    // 0-4 Swords, 5-9 Axe
    string[15] public WEAPONS = ["Sword", "Greatsword", "Broadsword", "Longsword", "Shortsword", "Hunteraxe", "Axe", "Blackaxe", "Greataxe", "Vikingaxe", "Hammer", "Warhammer", "Broadhammer", "Club", "Mace"];
    string public WEAPON_DESCRIPTION = "The Pythagorean school of thought teaches us that numbers are the basis of the entire universe, the base layer of perceived reality. The rest is but a mere expression of those. Numbers are all around us, have always been, will always be. Welcome to the Collective.";

    uint256 public constant RESERVED_N_TOKENS_TO_MINT = 700;
    uint256 public constant RESERVED_BAYC_TOKENS_TO_MINT = 444;
    uint256 public constant RESERVED_PUNK_TOKENS_TO_MINT = 177;
    uint256 public constant RESERVED_MASK_TOKENS_TO_MINT = 1500;
    uint256 public constant RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT = 879;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MINT_FEE = 0.08 ether;
    uint256 public constant MINTABLE_TOKENS_PER_PUNK_TOKEN = 5;
    uint256 public constant MINTABLE_TOKENS_PER_BAYC_TOKEN = 2;
    uint256 public constant MAX_MINTS_PER_N_HOLDER = 3;
    uint256 public constant MAX_MINTS_PER_MASK_HOLDER = 2;
    uint256 public constant MAX_MINTS_PER_HOLDER = 20;
    uint256 public constant N_BASE_TOKEN_ID = 7302015;

    mapping(uint256 => bool) public nTokensMinted;
    mapping(uint256 => bool) public maskTokensMinted;
    mapping(address => uint256) public punkHoldersMintedByAddress;
    mapping(address => uint256) public baycHoldersMintedByAddress;
    mapping(address => uint256) public maskHoldersMintedByAddress;
    mapping(address => uint256) public nHoldersMintedByAddress;
    mapping(address => uint256) public openToAllHoldersMintedByAddress;
    uint256 public totalNHoldersMinted;
    uint256 public totalMaskHoldersMinted;
    uint256 public totalBAYCHoldersMinted;
    uint256 public totalPunkHoldersMinted;
    uint256 public totalEcosystemAndTeamMinted;
    uint256 public totalSupply;
    uint256 public totalTeamMinted;

    bool private _overrideTradingPreventionInMintingPeriod;
    bool private _finishInitialization;
    address public resurrectionContract;
    uint256 public endMintingPeriodDateAndTime;
    uint256 public endReservedSpotsMintingPeriodDateAndTime;
    uint256 public nextVestingPeriodDataAndTime;

    string[15] public firstAssets;
    string[15] public secondAssets;
    string[15] public thirdAssets;
    string[15] public fourthAssets;
    string[15] public fifthAssets;
    string[15] public sixthAssets;
    string[15] public seventhAssets;
    string public svgStyle;
    string public secondOrnament;
    string public topOrnament;
    string public bottomOrnament;

    // -------- MODIFIERS (CONVERTED TO FUNCTIONS TO REDUCE CONTRACT SIZE) --------

    function _onlyWhenInit() internal view {
        require(!_finishInitialization, "Wut?");
    }

    function _onlyWhenFinishInit() internal view {
        require(_finishInitialization, "Can't call this yet");
    }

    function _amountBiggerThanZero(uint256 amountToMint) internal pure {
        require(amountToMint > 0, "Amount need ot be bigger than 0");
    }

    function _sameAmountAndTokenLength(uint256 amountToMint, uint256[] memory tokenIds) internal pure {
        require(amountToMint == tokenIds.length, "Lengths mismatch");
    }

    function _includesMintFee(uint256 amountToMint) internal view {
        require(msg.value >= MINT_FEE * amountToMint, "Mint cost 0.08 eth per token");
    }

    function _includesMintFeeWith50PercentageDiscount(uint256 amountToMint) internal view {
        require(msg.value >= (MINT_FEE / 2) * amountToMint, "Mint cost 0.04 eth per token");
    }

    function _onlyInMintingPeriod() internal view {
        require(isInMintingPeriod(), "Not in minting period");
    }

    function _onlyInReservedMintingPeriod() internal view {
        require(isInReservedMintingPeriod(), "Reserved minting period is over");
    }

    function _canSacrifice() internal view {
        require(resurrectionContract == msg.sender, "You can't do that");
    }

    constructor(uint256 _endMintingPeriodDateAndTime, uint256 _endReservedSpotsMintingPeriodDateAndTime)
    ERC721("Pythagorean Weapons", "PythagoreanWeapons")
    {
        endMintingPeriodDateAndTime = _endMintingPeriodDateAndTime;
        endReservedSpotsMintingPeriodDateAndTime = _endReservedSpotsMintingPeriodDateAndTime;
        nextVestingPeriodDataAndTime = block.timestamp + (30 * 24 * 60 * 60);
    }

    function setFirstAssets(string[] memory first, uint256 start) public onlyOwner {
        _onlyWhenInit();
        for (uint256 i; i < first.length; i++) {
            firstAssets[i + start] = first[i];
        }
    }

    function setSecondAssets(string[] memory second, uint256 start) public onlyOwner {
        _onlyWhenInit();
        for (uint256 i; i < second.length; i++) {
            secondAssets[i + start] = second[i];
        }
    }

    function setThirdAssets(string[15] memory third) public onlyOwner {
        _onlyWhenInit();
        thirdAssets = third;
    }

    function setFourthAssets(string[15] memory fourth) public onlyOwner {
        _onlyWhenInit();
        fourthAssets = fourth;
    }

    function setFifthAssets(string[] memory fifth, uint256 start) public onlyOwner {
        _onlyWhenInit();
        for (uint256 i; i < fifth.length; i++) {
            fifthAssets[i + start] = fifth[i];
        }
    }

    function setSixthAssets(string[] memory sixth, uint256 start) public onlyOwner {
        _onlyWhenInit();
        for (uint256 i; i < sixth.length; i++) {
            sixthAssets[i + start] = sixth[i];
        }
    }

    function setSeventhAssets(string[15] memory seventh) public onlyOwner {
        _onlyWhenInit();
        seventhAssets = seventh;
    }

    function setSVGItems(
        string memory _svgStyle,
        string memory _secondOrnament,
        string memory _topOrnament,
        string memory _bottomOrnament
    ) public onlyOwner {
        _onlyWhenInit();
        svgStyle = _svgStyle;
        secondOrnament = _secondOrnament;
        topOrnament = _topOrnament;
        bottomOrnament = _bottomOrnament;
    }

    function finishInitialization(address newOwner) public onlyOwner {
        _onlyWhenInit();
        _finishInitialization = true;
        if (newOwner != owner()) {
            transferOwnership(newOwner);
        }
    }

    function claimVestedTeamTokens(uint256[] memory tokenIds) public onlyOwner {
        _onlyWhenFinishInit();
        require(block.timestamp > nextVestingPeriodDataAndTime, "Can't claim yet");
        // Vesting period every 1 month
        nextVestingPeriodDataAndTime = nextVestingPeriodDataAndTime + (30 * 24 * 60 * 60);
        for (uint256 i; i < tokenIds.length && i < 88; i++) {
            _safeTransfer(address(this), owner(), tokenIds[i], "");
        }
    }

    function mintTokenReservedForN(uint256 amountToMint, uint256[] memory tokenIds)
    public
    payable
    nonReentrant
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _sameAmountAndTokenLength(amountToMint, tokenIds);
        _includesMintFeeWith50PercentageDiscount(amountToMint);
        _onlyInReservedMintingPeriod();
        require(RESERVED_N_TOKENS_TO_MINT > totalNHoldersMinted, "Can't mint anymore");
        require(MAX_MINTS_PER_N_HOLDER > nHoldersMintedByAddress[msg.sender], "Insufficient balance");
        uint256[] memory treasureDepositedTokens = treasure.depositsOf(msg.sender);
        uint256 i;
        for (;
            i < tokenIds.length &&
            MAX_MINTS_PER_N_HOLDER > nHoldersMintedByAddress[msg.sender] &&
            RESERVED_N_TOKENS_TO_MINT > totalNHoldersMinted;
            i++) {
            uint256 tokenId = tokenIds[i];
            require(!nTokensMinted[tokenId], "Token was already been used");
            require(_isNHolder(tokenId, treasureDepositedTokens), "Not the token owner");
            totalNHoldersMinted++;
            nTokensMinted[tokenId] = true;
            nHoldersMintedByAddress[msg.sender]++;
            _mintNextToken(msg.sender);
        }
        uint256 mintingFee = i * (MINT_FEE / 2);
        Address.sendValue(payable(owner()), mintingFee);
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForMask(uint256 amountToMint, uint256[] memory tokenIds)
    public
    nonReentrant
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _sameAmountAndTokenLength(amountToMint, tokenIds);
        _onlyInReservedMintingPeriod();
        require(RESERVED_MASK_TOKENS_TO_MINT > totalMaskHoldersMinted, "Can't mint anymore");
        require(MAX_MINTS_PER_MASK_HOLDER > maskHoldersMintedByAddress[msg.sender], "Insufficient balance");
        for (
            uint256 i;
            i < tokenIds.length &&
            MAX_MINTS_PER_MASK_HOLDER > maskHoldersMintedByAddress[msg.sender] &&
            RESERVED_MASK_TOKENS_TO_MINT > totalMaskHoldersMinted;
            i++
        ) {
            uint256 tokenId = tokenIds[i];
            require(!maskTokensMinted[tokenId], "Token was already been used");
            require(mask.ownerOf(tokenId) == msg.sender, "Not the token owner");
            totalMaskHoldersMinted++;
            maskTokensMinted[tokenId] = true;
            maskHoldersMintedByAddress[msg.sender]++;
            _mintNextToken(msg.sender);
        }
    }

    function mintTokenReservedForPunkHolders(uint256 amountToMint)
    public
    payable
    nonReentrant
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _includesMintFee(amountToMint);
        _onlyInReservedMintingPeriod();
        require(RESERVED_PUNK_TOKENS_TO_MINT > totalPunkHoldersMinted, "Can't mint anymore");
        uint256 balance = punk.balanceOf(msg.sender) * MINTABLE_TOKENS_PER_PUNK_TOKEN;
        require(balance > punkHoldersMintedByAddress[msg.sender], "Insufficient balance");
        uint256 i;
        // Since i can be lower than amountToMint after loop ends
        for (
        ;
            i < amountToMint &&
            RESERVED_PUNK_TOKENS_TO_MINT > totalPunkHoldersMinted &&
            balance > punkHoldersMintedByAddress[msg.sender];
            i++
        ) {
            totalPunkHoldersMinted++;
            punkHoldersMintedByAddress[msg.sender]++;
            _mintNextToken(msg.sender);
        }
        uint256 mintingFee = i * MINT_FEE;
        Address.sendValue(payable(owner()), mintingFee);
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForBAYCHolders(uint256 amountToMint)
    public
    payable
    nonReentrant
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _includesMintFee(amountToMint);
        _onlyInReservedMintingPeriod();
        require(RESERVED_BAYC_TOKENS_TO_MINT > totalBAYCHoldersMinted, "Can't mint anymore");
        uint256 balance = bayc.balanceOf(msg.sender) * MINTABLE_TOKENS_PER_BAYC_TOKEN;
        require(balance > baycHoldersMintedByAddress[msg.sender], "Insufficient balance");
        // Since i can be lower than amountToMint after loop ends
        uint256 i;
        for (
        ;
            i < amountToMint &&
            RESERVED_BAYC_TOKENS_TO_MINT > totalBAYCHoldersMinted &&
            balance > baycHoldersMintedByAddress[msg.sender];
            i++
        ) {
            totalBAYCHoldersMinted++;
            baycHoldersMintedByAddress[msg.sender]++;
            _mintNextToken(msg.sender);
        }
        uint256 mintingFee = i * MINT_FEE;
        Address.sendValue(payable(owner()), mintingFee);
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintToken(uint256 amountToMint)
    public
    payable
    nonReentrant
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _includesMintFee(amountToMint);
        _onlyInMintingPeriod();
        require(
            MAX_SUPPLY - RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT > totalSupply - totalEcosystemAndTeamMinted,
            "Can't mint anymore"
        );
        require(MAX_MINTS_PER_HOLDER > openToAllHoldersMintedByAddress[msg.sender], "Insufficient balance");
        // Since i can be lower than amountToMint after loop ends
        uint256 i;
        for (
        ;
            i < amountToMint &&
            MAX_SUPPLY - RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT > totalSupply - totalEcosystemAndTeamMinted &&
            MAX_MINTS_PER_HOLDER > openToAllHoldersMintedByAddress[msg.sender];
            i++
        ) {
            openToAllHoldersMintedByAddress[msg.sender]++;
            _mintNextToken(msg.sender);
        }
        uint256 mintingFee = i * MINT_FEE;
        Address.sendValue(payable(owner()), mintingFee);
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForEcosystemAndTeam(uint256 amountToMint)
    public
    nonReentrant
    onlyOwner
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _onlyInMintingPeriod();
        require(RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT > totalTeamMinted, "Can't mint anymore");
        for (uint256 i; i < amountToMint && RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT > totalTeamMinted; i++) {
            totalTeamMinted++;
            // Only 10% now, rest go to contract for vesting
            _mintNextToken(totalTeamMinted > 87 ? address(this) : msg.sender);
        }
    }

    function isInMintingPeriod() public view returns (bool) {
        return
        endMintingPeriodDateAndTime > block.timestamp && MAX_SUPPLY > totalSupply;
    }

    function isInReservedMintingPeriod() public view returns (bool) {
        return
        endReservedSpotsMintingPeriodDateAndTime > block.timestamp &&
        (RESERVED_N_TOKENS_TO_MINT > totalNHoldersMinted ||
        RESERVED_BAYC_TOKENS_TO_MINT > totalBAYCHoldersMinted ||
        RESERVED_PUNK_TOKENS_TO_MINT > totalPunkHoldersMinted ||
        RESERVED_MASK_TOKENS_TO_MINT > totalMaskHoldersMinted);
    }

    function getFirst(uint256 tokenId) public view returns (uint256) {
        return n.getFirst(tokenId + N_BASE_TOKEN_ID);
    }

    function getSecond(uint256 tokenId) public view returns (uint256) {
        return n.getSecond(tokenId + N_BASE_TOKEN_ID);
    }

    function getThird(uint256 tokenId) public view returns (uint256) {
        return n.getThird(tokenId + N_BASE_TOKEN_ID);
    }

    function getFourth(uint256 tokenId) public view returns (uint256) {
        return n.getFourth(tokenId + N_BASE_TOKEN_ID);
    }

    function getFifth(uint256 tokenId) public view returns (uint256) {
        return n.getFifth(tokenId + N_BASE_TOKEN_ID);
    }

    function getSixth(uint256 tokenId) public view returns (uint256) {
        return n.getSixth(tokenId + N_BASE_TOKEN_ID);
    }

    function getSeventh(uint256 tokenId) public view returns (uint256) {
        return n.getSeventh(tokenId + N_BASE_TOKEN_ID);
    }

    function getEight(uint256 tokenId) public view returns (uint256) {
        return n.getEight(tokenId + N_BASE_TOKEN_ID);
    }

    function setOverrideTradingPreventionInMintingPeriod(bool overrideTradingPreventionInMintingPeriod) external onlyOwner {
        _overrideTradingPreventionInMintingPeriod = overrideTradingPreventionInMintingPeriod;
    }

    function setResurrectionContract(address _resurrectionContract) external onlyOwner {
        resurrectionContract = _resurrectionContract;
    }

    function sacrifice(uint256 tokenId) external {
        _canSacrifice();
        _burn(tokenId);
    }

    function spotsForAll() external view returns (uint256) {
        uint256 balance = MAX_SUPPLY - RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT;
        if (balance > totalSupply - totalTeamMinted) {
            return balance - (totalSupply - totalTeamMinted);
        } else {
            return 0;
        }
    }

    function spotsForMask() external view returns (uint256) {
        uint256 balance = mask.balanceOf(msg.sender);
        if (balance > maskHoldersMintedByAddress[msg.sender]) {
            return Math.min(balance, MAX_MINTS_PER_MASK_HOLDER) - maskHoldersMintedByAddress[msg.sender];
        } else {
            return 0;
        }
    }

    function spotsForN() external view returns (uint256) {
        uint256 balance = n.balanceOf(msg.sender) + treasure.depositsOf(msg.sender).length;
        if (balance > nHoldersMintedByAddress[msg.sender]) {
            return Math.min(balance, MAX_MINTS_PER_N_HOLDER) - nHoldersMintedByAddress[msg.sender];
        } else {
            return 0;
        }
    }

    function spotsForBAYC() external view returns (uint256) {
        uint256 balance = bayc.balanceOf(msg.sender) * MINTABLE_TOKENS_PER_BAYC_TOKEN;
        if (balance > baycHoldersMintedByAddress[msg.sender]) {
            return balance - baycHoldersMintedByAddress[msg.sender];
        }
        return 0;
    }

    function spotsForPunk() external view returns (uint256) {
        uint256 balance = punk.balanceOf(msg.sender) * MINTABLE_TOKENS_PER_PUNK_TOKEN;
        if (balance > punkHoldersMintedByAddress[msg.sender]) {
            return balance - punkHoldersMintedByAddress[msg.sender];
        }
        return 0;
    }

    // -------- JSON & SVG --------

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        (uint256 first, uint256 second, uint256 third, uint256 fourth, uint256 fifth, uint256 sixth,
        uint256 seventh, uint256 eight, uint256 angle) = _getNumbersOfToken(tokenId);
        string memory svgOutput = _svg(first, second, third, fourth, fifth, sixth, seventh, eight, angle);

        string memory json = Base64._encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _generateWeaponName(tokenId, second + third, fourth + fifth, first, sixth + seventh),
                        '", "description": "',
                        WEAPON_DESCRIPTION,
                        '", "image": "data:image/svg+xml;base64,',
                        Base64._encode(bytes(svgOutput)),
                        '", "attributes": [',
                        _generateAttributes(first, second, third, fourth, fifth, sixth, seventh, eight, angle),
                        ']}'
                    )
                )
            )
        );
        json = string(abi.encodePacked("data:application/json;base64,", json));

        return json;
    }

    // For when the resurrection comes, the weapon comes too
    function svgOfToken(uint256 tokenId) external view returns (string memory svgOutput) {
        (uint256 first, uint256 second, uint256 third, uint256 fourth, uint256 fifth, uint256 sixth,
        uint256 seventh, uint256 eight, uint256 angle) = _getNumbersOfToken(tokenId);
        svgOutput = _svg(first, second, third, fourth, fifth, sixth, seventh, eight, angle);
    }

    // -------- INTERNALS --------

    function _mintNextToken(address to) internal {
        _safeMint(to, totalSupply);
        totalSupply++;
    }

    function _isNHolder(uint256 tokenId, uint256[] memory treasureDepositedTokens) internal view returns (bool) {
        if (n.ownerOf(tokenId) == msg.sender) {
            return true;
        } else {
            for (uint256 i; i < treasureDepositedTokens.length; i++) {
                if (tokenId == treasureDepositedTokens[i]) {
                    return true;
                }
            }
        }
        return false;
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal virtual override {
        if (from != address(0)) {
            // If no mint
            require(!isInMintingPeriod() || _overrideTradingPreventionInMintingPeriod, "Still in minting period");
        }
    }

    // -------- INTERNALS JSON & SVG --------

    function _generateWeaponName(uint256 tokenId, uint256 adjective, uint256 noun, uint256 weapon, uint256 place) internal view returns (string memory name) {
        // “1234 - Glowing-Wind Sword of Ellora"
        name = string(
            abi.encodePacked(
                _toString(tokenId),
                " - ",
                ADJECTIVES[adjective],
                "-",
                NOUNS[noun],
                " ",
                WEAPONS[weapon],
                " of ",
                PLACES[place]
            )
        );
    }

    // To prevent stack too deep
    struct Vars {
        uint256 first;
        uint256 second;
        uint256 third;
        uint256 fourth;
        uint256 fifth;
        uint256 sixth;
        uint256 seventh;
        uint256 eight;
        uint256 sum;
        uint256 angle;
    }

    function _getNumbersOfToken(uint256 tokenId)
    internal
    view
    returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        Vars memory vars;

        vars.first = getFirst(tokenId);
        vars.second = getSecond(tokenId);
        vars.third = getThird(tokenId);
        vars.fourth = getFourth(tokenId);
        vars.fifth = getFifth(tokenId);
        vars.sixth = getSixth(tokenId);
        vars.seventh = getSeventh(tokenId);
        vars.eight = getEight(tokenId);
        vars.sum = vars.first + vars.second + vars.third + vars.fourth + vars.fifth + vars.sixth + vars.seventh + vars.eight;
        uint256 angle = ((109090910 * vars.sum) - 2181818181) / 100000000;
        return (vars.first, vars.second, vars.third, vars.fourth, vars.fifth, vars.sixth, vars.seventh, vars.eight, angle);
    }

    function _generateAttributes(uint256 first, uint256 second, uint256 third, uint256 fourth, uint256 fifth,
        uint256 sixth, uint256 seventh, uint256 eight, uint256 angle) internal view returns (string memory attributesOutput) {

        attributesOutput = string(
            abi.encodePacked(
                _generateAttribute(PARTS[0], first),
                ",",
                _generateAttribute(PARTS[1], second),
                ",",
                _generateAttribute(PARTS[2], third),
                ",",
                _generateAttribute(PARTS[3], fourth),
                ",",
                _generateAttribute(PARTS[4], fifth),
                ",",
                _generateAttribute(PARTS[5], sixth),
                ",",
                _generateAttribute(PARTS[6], seventh),
                ",",
                _generateAttribute(PARTS[7], eight),
                ",",
                _generateAttribute(PARTS[8], angle)
            )
        );
    }

    function _generateAttribute(string memory traitType, uint256 number) internal pure returns (string memory attributeOutput) {
        attributeOutput = string(
            abi.encodePacked(
                '{"trait_type": "',
                traitType,
                '","value": "',
                _toString(number),
                '"}'
            )
        );
    }

    function _svg(uint256 first, uint256 second, uint256 third, uint256 fourth, uint256 fifth,
        uint256 sixth, uint256 seventh, uint256 eight, uint256 angle) internal view returns (string memory svgOutput) {

        string[4] memory weaponParts;

        weaponParts[0] = _surroundWithId(
            "flipWeaponsParts",
            string(
                abi.encodePacked(
                    firstAssets[first],
                    thirdAssets[third],
                    fourthAssets[fourth],
                    fifthAssets[fifth],
                    sixthAssets[sixth],
                    _surroundWithId("ORNAMENT", seventhAssets[seventh])
                )
            )
        );
        weaponParts[1] = _flipHorizontally("flipWeaponsParts", "1080");
        weaponParts[2] = _buildAdditionalOrnaments(eight);
        weaponParts[3] = secondAssets[second];

        string[4] memory svgParts;

        svgParts[0] = _svgHeader('viewBox="0 0 1080 1080"');
        svgParts[1] = svgStyle;
        svgParts[2] = _transform(
            string(abi.encodePacked("rotate(", _svgAngle(angle), ",540,540)")),
            string(abi.encodePacked(weaponParts[0], weaponParts[1], weaponParts[2], weaponParts[3]))
        );
        svgParts[3] = "</svg>";

        svgOutput = string(abi.encodePacked(svgParts[0], svgParts[1], svgParts[2], svgParts[3]));
    }

    function _buildAdditionalOrnaments(uint256 number) internal view returns (string memory) {
        // Ornament nothing (8), second (9,13), top (7,11), bottom (6,12), ALL (0, 14), second + top (1,2), second + bottom (3,4), bottom + top (5,10)
        if (number == 9 || number == 13) {
            return secondOrnament;
        } else if (number == 7 || number == 11) {
            return topOrnament;
        } else if (number == 6 || number == 12) {
            return bottomOrnament;
        } else if (number == 0 || number == 14) {
            return string(abi.encodePacked(secondOrnament, topOrnament, bottomOrnament));
        } else if (number == 1 || number == 2) {
            return string(abi.encodePacked(secondOrnament, topOrnament));
        } else if (number == 3 || number == 4) {
            return string(abi.encodePacked(secondOrnament, bottomOrnament));
        } else if (number == 5 || number == 10) {
            return string(abi.encodePacked(bottomOrnament, topOrnament));
        }

        return "";
    }

    function _svgHeader(string memory attributes) internal pure returns (string memory output) {
        output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" ',
                attributes,
                '>'
            )
        );
    }

    function _surroundWithId(string memory id, string memory input) internal pure returns (string memory output) {
        output = string(abi.encodePacked('<g id="', id, '">', input, "</g>"));
    }

    function _flipHorizontally(string memory id, string memory x) internal pure returns (string memory output) {
        output = string(
            abi.encodePacked(
                '<use xlink:href="#',
                id,
                '" href="#',
                id,
                '" transform="scale(-1 1) translate(-',
                x,
                ',0)"/>'
            )
        );
    }

    function _transform(string memory transformAttribute, string memory innerBody) internal pure returns (string memory output) {
        output = string(abi.encodePacked('<g transform="', transformAttribute, '">', innerBody, "</g>"));
    }

    function _svgAngle(uint256 angle) internal pure returns (string memory output) {
        if (angle == 30) {
            return "0";
        } else if (angle > 30) {
            return _toString(angle - 30);
        } else {
            return string(abi.encodePacked("-", _toString(30 - angle)));
        }
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function _encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PythagoreanWeaponsRefund is Ownable, ReentrancyGuard {

    mapping(address => uint256) public refundRecipients;
    uint256 endOfRefundPeriod;

    function setRefundRecipients(address[] memory addresses, uint256[] memory refunds) external onlyOwner {
        require(addresses.length == refunds.length, "Huh?");
        endOfRefundPeriod = block.timestamp + (30 * 24 * 60 * 60);
        for (uint256 i; i < addresses.length; i++) {
            refundRecipients[addresses[i]] = refunds[i];
        }
    }

    function refund() external nonReentrant {
        require(refundRecipients[msg.sender] > 0, "No refund");
        uint256 _refund = refundRecipients[msg.sender];
        refundRecipients[msg.sender] = 0;
        Address.sendValue(payable(msg.sender), _refund);
    }

    function salvageETH() external onlyOwner {
        require(block.timestamp > endOfRefundPeriod, "Can't yet");
        require(address(this).balance > 0, "No");
        Address.sendValue(payable(owner()), address(this).balance);
    }

    receive() external payable {}
}

