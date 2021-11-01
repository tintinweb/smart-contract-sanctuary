// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 /$$   /$$ /$$$$$$$$ /$$$$$$$$       /$$$$$$$                                /$$                 /$$$$$$$$ /$$       /$$                    
| $$$ | $$| $$_____/|__  $$__/      | $$__  $$                              | $$                |__  $$__/| $$      |__/                    
| $$$$| $$| $$         | $$         | $$  \ $$ /$$   /$$ /$$$$$$$$ /$$$$$$$$| $$  /$$$$$$          | $$   | $$$$$$$  /$$ /$$$$$$$   /$$$$$$ 
| $$ $$ $$| $$$$$      | $$         | $$$$$$$/| $$  | $$|____ /$$/|____ /$$/| $$ /$$__  $$         | $$   | $$__  $$| $$| $$__  $$ /$$__  $$
| $$  $$$$| $$__/      | $$         | $$____/ | $$  | $$   /$$$$/    /$$$$/ | $$| $$$$$$$$         | $$   | $$  \ $$| $$| $$  \ $$| $$  \ $$
| $$\  $$$| $$         | $$         | $$      | $$  | $$  /$$__/    /$$__/  | $$| $$_____/         | $$   | $$  | $$| $$| $$  | $$| $$  | $$
| $$ \  $$| $$         | $$         | $$      |  $$$$$$/ /$$$$$$$$ /$$$$$$$$| $$|  $$$$$$$         | $$   | $$  | $$| $$| $$  | $$|  $$$$$$$
|__/  \__/|__/         |__/         |__/       \______/ |________/|________/|__/ \_______/         |__/   |__/  |__/|__/|__/  |__/ \____  $$
                                                                                                                                   /$$  \ $$
                                                                                                                                  |  $$$$$$/
                                                                                                                                   \______/ 
                                                                                                                                   */

import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./PrizeFactory.sol";
import "./PieceFactory.sol";

contract NPT_NFTNYC is VRFConsumerBase, Pausable, Ownable {
    enum PackTier {
        GOLD
    }

    // Structs
    struct Pack {
        address owner;
        uint256 puzzleGroupId;
        uint256 randomness;
        PackTier tier;
    }

    struct Puzzle {
        uint256 puzzleGroupId;
        uint256 puzzleId;
        string[] pieces;
        string[] prizes;
        uint256 winnerIndex;
        uint256 maxWinners;
    }

    struct Prize {
        string uri;
        bool claimed;
    }

    // Variables
    bool public slowMode;
    uint256 public slowModeTime;
    // address public owner;
    mapping(address => bool) public whitelistedAddress;

    // Pack Management
    mapping(PackTier => uint256) public packPrices;
    mapping(PackTier => uint256) public packContents;
    mapping(bytes32 => Pack) public packs;

    // Puzzle Management
    uint256[] public activePuzzleGroups;
    mapping(uint256 => Puzzle[]) public puzzleGroupToOngoingPuzzles;

    // Prize Management
    // winner's address -> (PuzzleId -> Prize)
    mapping(address => mapping(uint256 => Prize)) public winningsForUser;

    // Listings Management
    // Seller -> TokenID -> CID -> Boolean
    mapping(address => mapping(uint256 => mapping(string => bool)))
        public listingsForOwner;

    // pack purchase bool for group ID
    mapping(uint256 => bool) public packPurchaseStatusForGroup;

    // timings for pack purrchase
    mapping(address => uint256) public usersTimers;

    // Chainlink Variables
    bytes32 public keyHash;
    uint256 public fee;

    // Children Contracts
    PrizeFactory public prizeFactory;
    PieceFactory public pieceFactory;

    // Other Contracts
    IERC20 DAI;

    // Events
    event PuzzleStarted(
        uint256 puzzleGroupId,
        uint256 puzzleId,
        uint256 maxWinners
    );
    event PuzzleEnded(uint256 puzzleGroupId, uint256 puzzleId);
    event PuzzleSolved(
        uint256 puzzleGroupId,
        uint256 puzzleId,
        address winner,
        string prize
    );
    event PackPurchaseRequested(
        uint256 puzzleGroupId,
        address buyer,
        bytes32 requestId,
        PackTier tier
    );
    event PackPurchaseCompleted(bytes32 requestId);

    event PackUnboxed(bytes32 requestId, uint256[] tokenIds);

    event PieceMinted(address owner, uint256 tokenId, string piece);
    event PrizeClaimed(address winner, uint256 tokenId, string prize);

    event ListingCreated(address seller, uint256 sellerTokenId, string wants);
    event ListingSwapped(
        address seller,
        uint256 sellerTokenId,
        address buyer,
        uint256 buyerTokenId,
        string wanted
    );
    event ListingDeleted(address seller, uint256 sellerTokenId, string wanted);

    modifier onlyWhitelisted() {
        require(
            whitelistedAddress[msg.sender] || owner() == _msgSender(),
            "PuzzleManager: must be owner to call this function"
        );
        _;
    }

    modifier onlyPieceFactory() {
        require(
            address(pieceFactory) == msg.sender,
            "PuzzleManager: Only Piece Factory can call this function"
        );
        _;
    }

    // Constructor
    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 vrfKeyhash,
        uint256 vrfFee,
        address daiToken
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        keyHash = vrfKeyhash;
        fee = vrfFee;

        whitelistedAddress[owner()] = true;

        prizeFactory = new PrizeFactory(
            "NPT x IYK Puzzle Prizes",
            "NPTxAnimetasPrizes"
        );
        prizeFactory.transferOwnership(owner());

        pieceFactory = new PieceFactory(
            "NPT x IYK Puzzle Pieces",
            "NPTxIYKPieces"
        );
        pieceFactory.transferOwnership(owner());

        DAI = IERC20(daiToken);
    }

    // Core Logic
    /**
     * @dev Starts a new puzzle
     * @param puzzleGroupId for the puzzle where it will be created
     * @param puzzleId uniquely identifying the puzzle
     * @param pieces string array of IPFS CIDs with piece metadata
     * @param maxWinners uint256 number of winners allowed for a puzzle
     * @param prizes string[] prizes that would be won by the winners
     * Requirements:
     *  - caller must be owner
     */
    function startNewPuzzle(
        uint256 puzzleGroupId,
        uint256 puzzleId,
        string[] memory pieces,
        uint256 maxWinners,
        string[] memory prizes
    ) public onlyWhitelisted whenNotPaused {
        require(pieces.length > 0, "PuzzleManager: empty pieces array passed");
        require(prizes.length > 0, "PuzzleManager: empty prizes array passed");

        // Start new puzzle group if does not exist
        if (puzzleGroupToOngoingPuzzles[puzzleGroupId].length == 0) {
            activePuzzleGroups.push(puzzleGroupId);
        }

        Puzzle memory newPuzzle = Puzzle({
            puzzleGroupId: puzzleGroupId,
            puzzleId: puzzleId,
            pieces: pieces,
            winnerIndex: 0,
            maxWinners: maxWinners,
            prizes: prizes
        });

        puzzleGroupToOngoingPuzzles[puzzleGroupId].push(newPuzzle);

        emit PuzzleStarted(puzzleGroupId, newPuzzle.puzzleId, maxWinners);
    }

    /**
     * @dev Starts a batch of new puzzles in the same group ID
     * @param puzzleGroupId for the puzzles where they will be created
     * @param puzzleIds array of unique ID's for the puzzles
     * @param pieces array of string arrays of IPFS CIDs with piece metadata
     *
     * Requirements:
     *  - caller must be owner
     */
    function batchStartNewPuzzles(
        uint256 puzzleGroupId,
        uint256[] memory puzzleIds,
        string[][] memory pieces,
        uint256[] memory maxWinners,
        string[][] memory prizes
    ) public onlyWhitelisted whenNotPaused {
        uint256 length = puzzleIds.length;
        require(
            length == pieces.length,
            "PuzzleManager: unequal length of puzzle ids and pieces passed"
        );
        require(
            length == prizes.length,
            "PuzzleManager: unequal length of puzzle ids and prizes passed"
        );

        for (uint256 i = 0; i < length; i++) {
            startNewPuzzle(
                puzzleGroupId,
                puzzleIds[i],
                pieces[i],
                maxWinners[i],
                prizes[i]
            );
        }
    }

    /**
     * @dev Allows user to purchase a pack of a specific tier for a group
     * @param puzzleGroupId to purchase the pack for
     * @param recipient address for the pack
     * @param tier of pack to purchase
     */
    function buyPackForTier(
        uint256 puzzleGroupId,
        address recipient,
        PackTier tier
    ) public whenNotPaused returns (bytes32) {
        require(
            packPurchaseStatusForGroup[puzzleGroupId],
            "PuzzleManager: Pack purchase is currently disabled for this puzzle group ID"
        );
        // When user's time is less than block's time, allow the user to purchase a pack
        if (slowMode) {
            require(
                usersTimers[recipient] < block.timestamp,
                "PuzzleManager: SlowMode is activated please wait for required time"
            );
            usersTimers[recipient] = block.timestamp + slowModeTime;
        }

        // If the msg.sender is not whitelisted then the sender and recipient should be the same
        if (!whitelistedAddress[msg.sender]) {
            require(
                msg.sender == recipient,
                "PuzzleManager: non owners must purchase pack for themselves"
            );
            require(
                DAI.transferFrom(recipient, address(this), packPrices[tier]),
                "PuzzleManager: user has not approved contract to transfer DAI"
            );
        }

        require(
            activePuzzleGroups.length > 0,
            "PuzzleManager: no active puzzle groups"
        );
        require(
            puzzleGroupToOngoingPuzzles[puzzleGroupId].length > 0,
            "PuzzleManager: no ongoing puzzles"
        );

        return _requestPackPurchase(puzzleGroupId, tier, recipient);
    }

    /**
     * @dev Callback function for Chainlink VRF to complete a pack purchase
     * @param requestId of the VRF request
     * @param randomness provided by VRF
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual
        override
    {
        packs[requestId].randomness = randomness;
        emit PackPurchaseCompleted(requestId);
    }

    /**
     * @dev Allows user to unbox a specific pack, or owner to unbox on their behalf
     * @param requestId of the VRF request
     */
    function unboxPack(bytes32 requestId)
        public
        whenNotPaused
        returns (uint256[] memory)
    {
        Pack memory pack = packs[requestId];
        require(
            pack.randomness > 0,
            "PuzzleManager: pack does not have randomness yet or does not exist"
        );
        if (!whitelistedAddress[msg.sender]) {
            require(
                msg.sender == pack.owner,
                "PuzzleManager: non owners must unbox packs they own"
            );
        }

        uint256[] memory tokenIds = generateRandomPieces(requestId);
        emit PackUnboxed(requestId, tokenIds);
        delete packs[requestId];
        return tokenIds;
    }

    /**
     * @dev Helper function to send the VRF request
     *
     * Requirements:
     *  - Contract must have LINK balance >= fee
     */
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "PuzzleManager: insufficient LINK to pay for randomness request"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * @dev Helper function to generate random pieces for recipient given a puzzle group and requestId
     * @param requestId of the VRF request
     * Requirements:
     *  - VRF request must have been fulfilled
     *  - There must be an active puzzle group
     *  - The provided puzzleGroupId must have active puzzles
     */
    function generateRandomPieces(bytes32 requestId)
        internal
        returns (uint256[] memory)
    {
        Pack memory pack = packs[requestId];
        require(
            pack.randomness > 0,
            "PuzzleManager: pack does not have randomness assigned yet"
        );
        require(
            activePuzzleGroups.length > 0,
            "PuzzleManager: there are no active puzzle groups to unbox packs for"
        );

        Puzzle[] memory randomPuzzles = puzzleGroupToOngoingPuzzles[
            pack.puzzleGroupId
        ];
        require(
            randomPuzzles.length > 0,
            "PuzzleManager: there are no active puzzles in puzzle group"
        );

        uint256 randomness = pack.randomness;
        uint256 numPieces = packContents[pack.tier];

        uint256[] memory tokenIds = new uint256[](numPieces);

        for (uint256 i = 0; i < numPieces; i++) {
            uint256 random = uint256(keccak256(abi.encode(randomness, i)));

            // Pick random puzzle in puzzle group
            uint256 randomPuzzleIndex = random % randomPuzzles.length;
            Puzzle memory randomPuzzle = randomPuzzles[randomPuzzleIndex];

            // Pick random piece in puzzle pieces
            string[] memory randomPuzzlePieces = randomPuzzle.pieces;
            uint256 randomPieceIndex = random % randomPuzzlePieces.length;
            string memory randomPiece = randomPuzzlePieces[randomPieceIndex];

            // Mint the piece
            uint256 pieceTokenId = _mintPiece(pack.owner, randomPiece);
            tokenIds[i] = pieceTokenId;
        }

        return tokenIds;
    }

    /**
     * @dev Creates a listing on the marketplace
     * @param sellerTokenIds array of token IDs the seller is willing to swap
     * @param wants IPFS CID of the token the seller wants
     * @param seller address
     */
    function createListing(
        uint256[] memory sellerTokenIds,
        string memory wants,
        address seller
    ) public whenNotPaused {
        if (!whitelistedAddress[msg.sender]) {
            require(
                msg.sender == seller,
                "PuzzleManager: non owners can only create listings for themselves"
            );
        }
        uint256 length = sellerTokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 currSellerTokenId = sellerTokenIds[i];
            require(
                pieceFactory.ownerOf(currSellerTokenId) == seller,
                "PuzzleManager: seller is not the owner of provided tokenId"
            );
            listingsForOwner[seller][currSellerTokenId][wants] = true;
            emit ListingCreated(seller, currSellerTokenId, wants);
        }
    }

    /**
     * @dev Function to transfer piece from sender to reciever
     * @param from address of the sender
     * @param to address of the reciever
     * @param tokenId tokenId for the piece to be transfered
     */
    function transferPiece(
        address from,
        address to,
        uint256 tokenId
    ) public whenNotPaused onlyWhitelisted {
        require(
            pieceFactory.ownerOf(tokenId) == from,
            "PuzzleManager: passed sender address does not own the piece ID"
        );
        pieceFactory.transferPiece(from, to, tokenId);
    }

    /**
     * @dev Fulfills an existing listing and swaps two pieces
     * @param sellerTokenId being swapped
     * @param buyerTokenId being swapped
     * @param seller address
     * @param buyer address
     */
    function fulfillListing(
        uint256 sellerTokenId,
        uint256 buyerTokenId,
        address seller,
        address buyer
    ) public whenNotPaused {
        if (!whitelistedAddress[msg.sender]) {
            require(
                msg.sender == buyer,
                "PuzzleManager: non owners can only fulfill listings for themselves"
            );
        }
        require(
            pieceFactory.ownerOf(sellerTokenId) == seller,
            "PuzzleManager: seller does not own the sellerTokenId"
        );
        require(
            pieceFactory.ownerOf(buyerTokenId) == buyer,
            "PuzzleManager: buyer does not own the buyerTokenId"
        );
        string memory buyerTokenIdTokenURI = pieceFactory.tokenURIWithoutPrefix(
            buyerTokenId
        );
        require(
            listingsForOwner[seller][sellerTokenId][buyerTokenIdTokenURI] ==
                true,
            "PuzzleManager: seller has not put up this listing"
        );

        pieceFactory.swap(sellerTokenId, buyerTokenId, seller, buyer);

        emit ListingSwapped(
            seller,
            sellerTokenId,
            buyer,
            buyerTokenId,
            buyerTokenIdTokenURI
        );
    }

    function deleteListings(
        uint256[][] memory tokenIds,
        string[] memory wanted,
        address seller
    ) public whenNotPaused {
        if (!whitelistedAddress[msg.sender]) {
            require(
                msg.sender == seller,
                "PuzzleManager: non owners can only delete their own listings"
            );
        }

        require(
            tokenIds.length == wanted.length,
            "PuzzleManager: unequal lengths of tokenIds and wanted passed"
        );

        for (uint256 i = 0; i < wanted.length; i++) {
            uint256 tokensLength = tokenIds[i].length;
            string memory cid = wanted[i];
            for (uint256 j = 0; j < tokensLength; j++) {
                uint256 tokenId = tokenIds[i][j];
                require(
                    pieceFactory.ownerOf(tokenId) == seller,
                    "PuzzleManager: seller does not own the tokenId"
                );
                listingsForOwner[seller][tokenId][cid] = false;
                emit ListingDeleted(seller, tokenId, cid);
            }
        }
    }

    /**
     * @dev Ends a given puzzle and assigns the winner, and starts a new one if a replacement is provided
     * @param puzzleGroupId for group to end (and possibly replace) the puzzle in
     * @param oldPuzzleId the puzzle id to stop
     * @param oldPuzzleWinner the address of the winner of the old puzzle
     * @param oldPuzzlePieces the IPFS CIDs array of pieces for the old puzzle
     * @param newPuzzleId the new puzzle id to start
     * @param newPuzzlePieces the IPFS CIDs array of pieces for the new puzzle
     * @param newPuzzleMaxWinners the number of winners for the new puzzle
     * @param newPuzzlePrizes Prizes for new puzzle
     */
    function replaceOrEndPuzzle(
        uint256 puzzleGroupId,
        uint256 oldPuzzleId,
        address oldPuzzleWinner,
        uint256[] memory oldPuzzlePieces,
        uint256 newPuzzleId,
        string[] memory newPuzzlePieces,
        uint256 newPuzzleMaxWinners,
        string[] memory newPuzzlePrizes
    ) public whenNotPaused onlyWhitelisted {
        Puzzle[] storage puzzles = puzzleGroupToOngoingPuzzles[puzzleGroupId];
        require(
            puzzles.length > 0,
            "PuzzleManager: puzzle group has no active puzzles"
        );

        string memory oldPuzzlePrize;

        // Ensure this puzzle is currently ongoing
        bool isOngoing = false;
        for (uint8 i = 0; i < puzzles.length; i++) {
            uint256 currPuzzleId = puzzles[i].puzzleId;
            // If found
            if (currPuzzleId == oldPuzzleId) {
                Puzzle storage puzzle = puzzles[i];
                // Require the winner hasn't already won this puzzle in the past
                require(
                    bytes(winningsForUser[oldPuzzleWinner][currPuzzleId].uri)
                        .length == 0,
                    "PuzzleManager: you have already won this puzzle"
                );

                uint256 winnerIndex = puzzle.winnerIndex;

                require(
                    winnerIndex < puzzle.maxWinners,
                    "PuzzleManager: this puzzle already has been won the max amount of times"
                );
                // Assign oldPuzzlePrize to prize at index oldPuzzleWinnersLength
                oldPuzzlePrize = puzzle.prizes[winnerIndex];

                // Assign prize to user
                winningsForUser[oldPuzzleWinner][currPuzzleId] = Prize({
                    uri: oldPuzzlePrize,
                    claimed: false
                });
                // Increment winnerIndex
                puzzle.winnerIndex = winnerIndex + 1;
                emit PuzzleSolved(
                    puzzleGroupId,
                    oldPuzzleId,
                    oldPuzzleWinner,
                    oldPuzzlePrize
                );
                // Puzzle has reached the maxWinner, end the puzzle
                if (puzzle.winnerIndex == puzzle.maxWinners) {
                    _endPuzzle(puzzleGroupId, puzzles.length, i);

                    emit PuzzleEnded(puzzleGroupId, oldPuzzleId);

                    // Start a new puzzle and replace the old puzzle
                    if (
                        newPuzzleId > 0 &&
                        newPuzzlePieces.length > 0 &&
                        newPuzzleMaxWinners > 0 &&
                        newPuzzlePrizes.length > 0
                    ) {
                        // Start new puzzle if provided
                        startNewPuzzle(
                            puzzleGroupId,
                            newPuzzleId,
                            newPuzzlePieces,
                            newPuzzleMaxWinners,
                            newPuzzlePrizes
                        );
                    }
                }
                isOngoing = true;
                break;
            }
        }
        require(isOngoing == true, "PuzzleManager: oldPuzzleId is not ongoing");

        //burn the used pieces
        _burnPieces(oldPuzzlePieces, oldPuzzleWinner);
    }

    /**
     * @dev Helper to ends a given puzzle
     * @param puzzleGroupId for group to end (and possibly replace) the puzzle in
     * @param puzzlesLength length of array of ongoing puzzles for a given group id
     */

    function _endPuzzle(
        uint256 puzzleGroupId,
        uint256 puzzlesLength,
        uint8 index
    ) private onlyWhitelisted whenNotPaused {
        // Delete the puzzle from ongoing puzzle in this group
        puzzleGroupToOngoingPuzzles[puzzleGroupId][
            index
        ] = puzzleGroupToOngoingPuzzles[puzzleGroupId][puzzlesLength - 1];
        puzzleGroupToOngoingPuzzles[puzzleGroupId].pop();

        // Delete the group, if no more puzzles left
        if (puzzleGroupToOngoingPuzzles[puzzleGroupId].length == 0) {
            for (uint256 j = 0; j < activePuzzleGroups.length; j++) {
                if (activePuzzleGroups[j] == puzzleGroupId) {
                    activePuzzleGroups[j] = activePuzzleGroups[
                        activePuzzleGroups.length - 1
                    ];
                    activePuzzleGroups.pop();
                }
            }
        }
    }

    /**
     * @dev Allows user to claim a prize
     * @param recipient address for prize winner
     * @param puzzleId Id for the puzzle
     */
    function claimPrize(address recipient, uint256 puzzleId)
        public
        whenNotPaused
    {
        if (!whitelistedAddress[msg.sender]) {
            require(
                msg.sender == recipient,
                "PuzzleManager: user can only claim prizes for themselves"
            );
        }
        Prize storage prize = winningsForUser[recipient][puzzleId];
        require(
            !prize.claimed && bytes(prize.uri).length > 0,
            "PuzzleManager: the winning does not exist or has already been claimed"
        );
        prize.claimed = true;
        uint256 tokenId = _mintPrize(recipient, prize.uri);
        emit PrizeClaimed(recipient, tokenId, prize.uri);
    }

    /**
     * @dev Helper hook to run before a piece is transfered
     * @param from address of sender
     * @param tokenId of the piece being transfered
     */
    function _beforePieceTransfer(address from, uint256 tokenId)
        external
        onlyPieceFactory
    {
        emit ListingDeleted(from, tokenId, "all");
    }

    /**
     * @dev Helper function to mint puzzle pieces
     * @param recipient address for minted piece
     * @param piece IPFS CID of piece
     */
    function _mintPiece(address recipient, string memory piece)
        internal
        returns (uint256)
    {
        uint256 tokenId = pieceFactory.mint(recipient, piece);
        emit PieceMinted(
            recipient,
            tokenId,
            pieceFactory.tokenURIWithoutPrefix(tokenId)
        );
        return tokenId;
    }

    /**
     * @dev burns the piece passed in piece IDs
     * @param pieceIds array of piece token IDs that are to be burnt
     * @param owner address for the owner of piece IDs to be burnt
     */
    function _burnPieces(uint256[] memory pieceIds, address owner)
        internal
        whenNotPaused
    {
        uint256 length = pieceIds.length;

        for (uint256 i = 0; i < length; i++) {
            require(
                pieceFactory.ownerOf(pieceIds[i]) == owner,
                "PuzzleManager: passed owner does not own the piece ID"
            );
            pieceFactory.burn(pieceIds[i]);
        }
    }

    /**
     * @param recipient address for minted piece
     * @param pieces array of piece IPFS CIDs
     */
    function airdropPieces(address recipient, string[] memory pieces)
        public
        onlyWhitelisted
        returns (uint256[] memory)
    {
        uint256 length = pieces.length;
        require(
            length > 0,
            "PuzzleManager: pieces length must be greater than 0"
        );

        uint256[] memory tokens = new uint256[](length);

        for (uint8 i = 0; i < length; i++) {
            tokens[i] = _mintPiece(recipient, pieces[i]);
        }

        return tokens;
    }

    function _requestPackPurchase(
        uint256 puzzleGroupId,
        PackTier tier,
        address recipient
    ) internal returns (bytes32) {
        bytes32 requestId = getRandomNumber();
        Pack memory pack = Pack({
            owner: recipient,
            randomness: 0,
            puzzleGroupId: puzzleGroupId,
            tier: tier
        });
        packs[requestId] = pack;
        emit PackPurchaseRequested(puzzleGroupId, recipient, requestId, tier);
        return requestId;
    }

    /**
     * @dev Helper function to whitelist address
     * @param whitelist Address to be added in whitelist
     *
     * Requirements:
     *  - caller must be owner
     */

    function whitelistAddress(address whitelist) public onlyWhitelisted {
        whitelistedAddress[whitelist] = true;
    }

    /**
     * @dev Helper function to remove a whitelisted address
     * @param whitelist adress
     *
     * Requirements:
     *  - caller must be owner
     */

    function removeWhitelistedAddress(address whitelist)
        public
        onlyWhitelisted
    {
        delete whitelistedAddress[whitelist];
    }

    /**
     * @dev Helper function to mint puzzle prizes
     * @param recipient address for minted prize
     */

    function _mintPrize(address recipient, string memory prize)
        internal
        returns (uint256)
    {
        uint256 tokenId = prizeFactory.mint(recipient, prize);
        return tokenId;
    }

    // Setters

    /**
     * @dev sets the pack purchase optionality on a puzzle group ID to true/false
     * @param puzzleGroupId to set the pack purchase status on
     * @param packPurchaseStatus boolean value to set for pack purchasing
     *
     * Requirements:
     *  - caller must be owner
     */
    function setPackPurchaseStatusForGroup(
        uint256 puzzleGroupId,
        bool packPurchaseStatus
    ) public onlyWhitelisted whenNotPaused {
        packPurchaseStatusForGroup[puzzleGroupId] = packPurchaseStatus;
    }

    function setSlowMode(bool setMode) public onlyWhitelisted {
        slowMode = setMode;
    }

    function setSlowModeTime(uint256 time) public onlyWhitelisted {
        slowModeTime = time;
    }

    function setPackTierPriceInWei(uint256 _packTierPriceInWei, PackTier _tier)
        public
        onlyWhitelisted
    {
        packPrices[_tier] = _packTierPriceInWei;
    }

    function setPackTierContentsSize(uint256 _size, PackTier _tier)
        public
        onlyWhitelisted
    {
        packContents[_tier] = _size;
    }

    // Pausable
    function pause() public virtual whenNotPaused onlyWhitelisted {
        _pause();
        prizeFactory.pause();
        pieceFactory.pause();
    }

    function unpause() public virtual whenPaused onlyWhitelisted {
        _unpause();
        prizeFactory.unpause();
        pieceFactory.unpause();
    }

    // Withdraw Functions
    function withdraw() public onlyWhitelisted {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawDai() public onlyWhitelisted {
        require(
            DAI.transfer(owner(), DAI.balanceOf(address(this))),
            "PuzzleManager: unable to transfer DAI"
        );
    }

    function withdrawLink() public onlyWhitelisted {
        require(
            LINK.transfer(owner(), LINK.balanceOf(address(this))),
            "PuzzleManager: unable to transfer LINK"
        );
    }

    // Fallback function
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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

pragma solidity ^0.8.4;

/*
 /$$   /$$ /$$$$$$$$ /$$$$$$$$       /$$$$$$$                                /$$                 /$$$$$$$$ /$$       /$$                    
| $$$ | $$| $$_____/|__  $$__/      | $$__  $$                              | $$                |__  $$__/| $$      |__/                    
| $$$$| $$| $$         | $$         | $$  \ $$ /$$   /$$ /$$$$$$$$ /$$$$$$$$| $$  /$$$$$$          | $$   | $$$$$$$  /$$ /$$$$$$$   /$$$$$$ 
| $$ $$ $$| $$$$$      | $$         | $$$$$$$/| $$  | $$|____ /$$/|____ /$$/| $$ /$$__  $$         | $$   | $$__  $$| $$| $$__  $$ /$$__  $$
| $$  $$$$| $$__/      | $$         | $$____/ | $$  | $$   /$$$$/    /$$$$/ | $$| $$$$$$$$         | $$   | $$  \ $$| $$| $$  \ $$| $$  \ $$
| $$\  $$$| $$         | $$         | $$      | $$  | $$  /$$__/    /$$__/  | $$| $$_____/         | $$   | $$  | $$| $$| $$  | $$| $$  | $$
| $$ \  $$| $$         | $$         | $$      |  $$$$$$/ /$$$$$$$$ /$$$$$$$$| $$|  $$$$$$$         | $$   | $$  | $$| $$| $$  | $$|  $$$$$$$
|__/  \__/|__/         |__/         |__/       \______/ |________/|________/|__/ \_______/         |__/   |__/  |__/|__/|__/  |__/ \____  $$
                                                                                                                                   /$$  \ $$
                                                                                                                                  |  $$$$$$/
                                                                                                                                   \______/ 
                                                                                                                                   */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PrizeFactory is
    Context,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    Ownable
{
    using Counters for Counters.Counter;

    string public constant IPFS_TOKEN_BASE_URI = "ipfs://";
    address managerContract;

    Counters.Counter private _tokenIdTracker;
    mapping(uint256 => string) private _tokenURIs;

    modifier onlyAdmin() {
        require(
            msg.sender == managerContract || owner() == _msgSender(),
            "PrizeFactory: only the owner or manager can call this"
        );
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        managerContract = msg.sender;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event)
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, string memory _tokenURI)
        external
        virtual
        whenNotPaused
        onlyAdmin
        returns (uint256)
    {
        uint256 tokenId = _tokenIdTracker.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        _tokenIdTracker.increment();
        return tokenId;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual whenNotPaused onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual whenPaused onlyAdmin {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURIWithoutPrefix(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "PrizeFactory: URI without prefix query for nonexistent token"
        );
        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        }

        return super.tokenURI(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "PrizeFactory: URI query for nonexistent token"
        );
        string memory _tokenURI = string(
            abi.encodePacked(IPFS_TOKEN_BASE_URI, _tokenURIs[tokenId])
        );
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
        whenNotPaused
    {
        require(
            _exists(tokenId),
            "PrizeFactory: URI set for nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function updateManager(address newManagerContract)
        public
        whenNotPaused
        onlyAdmin
    {
        managerContract = newManagerContract;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
 /$$   /$$ /$$$$$$$$ /$$$$$$$$       /$$$$$$$                                /$$                 /$$$$$$$$ /$$       /$$                    
| $$$ | $$| $$_____/|__  $$__/      | $$__  $$                              | $$                |__  $$__/| $$      |__/                    
| $$$$| $$| $$         | $$         | $$  \ $$ /$$   /$$ /$$$$$$$$ /$$$$$$$$| $$  /$$$$$$          | $$   | $$$$$$$  /$$ /$$$$$$$   /$$$$$$ 
| $$ $$ $$| $$$$$      | $$         | $$$$$$$/| $$  | $$|____ /$$/|____ /$$/| $$ /$$__  $$         | $$   | $$__  $$| $$| $$__  $$ /$$__  $$
| $$  $$$$| $$__/      | $$         | $$____/ | $$  | $$   /$$$$/    /$$$$/ | $$| $$$$$$$$         | $$   | $$  \ $$| $$| $$  \ $$| $$  \ $$
| $$\  $$$| $$         | $$         | $$      | $$  | $$  /$$__/    /$$__/  | $$| $$_____/         | $$   | $$  | $$| $$| $$  | $$| $$  | $$
| $$ \  $$| $$         | $$         | $$      |  $$$$$$/ /$$$$$$$$ /$$$$$$$$| $$|  $$$$$$$         | $$   | $$  | $$| $$| $$  | $$|  $$$$$$$
|__/  \__/|__/         |__/         |__/       \______/ |________/|________/|__/ \_______/         |__/   |__/  |__/|__/|__/  |__/ \____  $$
                                                                                                                                   /$$  \ $$
                                                                                                                                  |  $$$$$$/
                                                                                                                                   \______/ 
                                                                                                                                   */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PieceFactory is
    Context,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    Ownable
{
    using Counters for Counters.Counter;

    string public constant IPFS_TOKEN_BASE_URI = "ipfs://";
    address managerContract;

    Counters.Counter private _tokenIdTracker;
    mapping(uint256 => string) private _tokenURIs;

    modifier onlyAdmin() {
        require(
            msg.sender == managerContract || owner() == _msgSender(),
            "PieceFactory: only the owner or manager can call this"
        );
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        managerContract = msg.sender;
    }

    function swap(
        uint256 firstTokenId,
        uint256 secondTokenId,
        address firstOwner,
        address secondOwner
    ) external whenNotPaused onlyAdmin {
        _transfer(firstOwner, secondOwner, firstTokenId);
        _transfer(secondOwner, firstOwner, secondTokenId);
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event)
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, string memory _tokenURI)
        external
        virtual
        whenNotPaused
        onlyAdmin
        returns (uint256)
    {
        uint256 tokenId = _tokenIdTracker.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        _tokenIdTracker.increment();
        return tokenId;
    }

    function burn(uint256 tokenId)
        public
        virtual
        override
        whenNotPaused
        onlyAdmin
    {
        _burn(tokenId);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual whenNotPaused onlyAdmin {
        _pause();
    }

    /**
     * @dev Transfers token from one sender to reciever
     */

    function transferPiece(
        address from,
        address to,
        uint256 tokenId
    ) external whenNotPaused onlyAdmin {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual whenPaused onlyAdmin {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);

        managerContract.call(
            abi.encodeWithSignature(
                "_beforePieceTransfer(address,uint256)",
                from,
                tokenId
            )
        );
    }

    function tokenURIWithoutPrefix(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "PieceFactory: URI without prefix query for nonexistent token"
        );
        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        }

        return super.tokenURI(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "PieceFactory: URI query for nonexistent token"
        );
        string memory _tokenURI = string(
            abi.encodePacked(IPFS_TOKEN_BASE_URI, _tokenURIs[tokenId])
        );
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
        whenNotPaused
    {
        require(
            _exists(tokenId),
            "PrizeFactory: URI set for nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function updateManager(address newManagerContract)
        public
        whenNotPaused
        onlyAdmin
    {
        managerContract = newManagerContract;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
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

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}