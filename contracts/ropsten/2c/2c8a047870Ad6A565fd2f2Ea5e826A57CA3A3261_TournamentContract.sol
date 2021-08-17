/// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IRegistry.sol";
import "./interface/IFactory.sol";


contract TournamentContract {

    /***************
    STRUCT
    ***************/
    struct Submission {
        address owner;
        address nftAddress;
        uint256 tokenId;
    }

    struct Match {
        uint8 submissionA;
        uint8 submissionB;
        uint256 votesA;
        uint256 votesB;
        bool winnerDetermined;
        mapping (address => uint256) playerVotesA;
        mapping (address => uint256) playerVotesB;
        mapping (address => bool) winningsClaimed;
    }

    struct AuctionItem {
        // whether or not NFT owner has withdrawn the winning bid
        bool winningsWithdrawn;
        address highestBidder;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
        uint256 latestBidTime;
        uint256 highestBid;
        // bidder => refunds from previous bids
        mapping (address => uint256) withdrawableRefund;
    }
    
    /***************
    GLOBAL VARIABLES
    ***************/

    uint32 constant public AUCTION_PERIOD = 86400; // 24 hours

    bool internal tournamentActive;
    bool internal adminFeeWithdrawn;
    uint8 internal bracketSize;
    uint8 internal nextSubmissionId;
    uint8 internal winningSubmissionId;
    
    uint256 internal tournamentStartTime;
    uint256 internal votingPeriod;
    
    address internal whitelistedNFT;
    
    address private _owner;
    address private _factory;
    
    uint256 private _minBid;
    
    IRegistry internal registry;

    mapping (uint8 => Submission) public submissions;
    // maps submissionId => auction details
    mapping (uint8 => AuctionItem) public auctionItems;
    mapping (uint256 => Match) public matches;

    /***************
    EVENTS
    ***************/
    event AdminFeeClaimed(uint256 indexed fee);
    event AuctionStarted(uint256 indexed submissionId, uint256 indexed auctionStartTime);
    event BidWithdrawn(uint8 indexed submissionId, address indexed bidder, uint256 indexed refund);
    event HighestBidIncreased(uint8 indexed submissionId, address indexed bidder, uint256 indexed newHighestBid);
    event MinimumBidUpdated(uint256 indexed oldMinBid, uint256 indexed newMinBid);
    event NFTSubmitted(address indexed submitter, address indexed nftAddress, uint256 indexed tokenId);
    event NFTWithdrawn(address indexed withdrawer, address indexed nftAddress, uint256 indexed tokenId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TournamentStarted(uint256 indexed tournamentStartTime, uint8 indexed bracketSize);
    event TournamentEnded(uint256 indexed winningSubmissionId, uint256 indexed auctionStartTime);
    event VoteCast(uint8 indexed matchId, uint8 indexed submissionId, address indexed voter, uint256 numVotes);
    event WinningsClaimed(uint8 indexed matchId, address indexed claimant, uint256 indexed winnings);
    event WinnerDetermined(uint8 indexed matchId, uint8 indexed winnerId);
    event WinningBidClaimed(uint256 indexed earnings);

    /***************
    MODIFIERS
    ***************/
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /***************
    FUNCTIONS
    ***************/
    /// @dev Creates a Tournament instance
    /// @param _tournamentStartTime Tournament start time
    /// @param _votingPeriod Voting period for each round
    /// @param _bracketSize Max. bracket size
    /// @param _whitelistedNFT Whitelisted NFT address
    /// @param _registry Address of registry contract
    /// @param _creator Address of Tournament creator (owner)
    function initialize(
        uint256 _tournamentStartTime,
        uint256 _votingPeriod,
        uint8 _bracketSize,
        address _whitelistedNFT,
        address _registry,
        address _creator)
        external 
    {
        
        registry = IRegistry(_registry);

        require(
            registry.tournamentFactory() == msg.sender,
            "Must be called by TournamentFactory"
        );

        tournamentStartTime = _tournamentStartTime;
        votingPeriod = _votingPeriod;
        bracketSize = _bracketSize;
        nextSubmissionId = 1; // make submissionIds 1-indexed
        if (_whitelistedNFT != address(0)) whitelistedNFT = _whitelistedNFT;
        _owner = _creator;
        _factory = msg.sender;
        _minBid = 0.05 ether;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * @param newOwner address to transfer ownership privileges to
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Modifies the minimum bid for auctions.
     * Can only be called by the current owner.
     * @param newMinBid the updated minimum bid.
     */
    function updateMinBid(uint256 newMinBid) external onlyOwner {
        uint256 oldMinBid = _minBid;

        _minBid = newMinBid;

        emit MinimumBidUpdated(oldMinBid, newMinBid);
    }

    /**
     * @dev Closes off NFT submission period and starts the Tournament.
     * Can only be called by the current owner.
     * If the originally stated `bracketSize` has been reached, all submissions participate.
     * If the originally stated `bracketSize` has NOT been reached, `bracketSize` gets
     * reduced to the next valid size (largest square number) and remaining NFTs can be
     * withdrawn by their submitters. This is determined by the order they came in (`submissionId`)
     */
    function startTournament() external onlyOwner {

        // If the original bracket size HAS NOT been reached:
        // Pool Owner can start the Tournament with a smaller bracket than originally stated
        if (nextSubmissionId <= bracketSize) {

            uint8 largestValidBracketSize;

            // determine the largest valid bracket size
            for (uint256 i = 1; i <= bracketSize; i++) {
                if (2**i < nextSubmissionId) {
                    largestValidBracketSize = uint8(2**i);
                }
            }

            // submissionIds between nextSubmissionId and new bracketSize becomes withdrawable
            // ... as they didn't make it into the contest
            bracketSize = largestValidBracketSize;
        }

        // Generate a `bracketSize`-sized shuffled array of `submissionIds`.
        uint8[] memory randomizedSubmissions = _shuffleSubmissions();

        uint8 j = 0;
        uint8 numMatches = bracketSize / 2;
        
        // Initialise Matches for the first round
        for (uint256 i = 1; i <= numMatches; i++) {
            matches[i].submissionA = randomizedSubmissions[j];
            matches[i].submissionB = randomizedSubmissions[j+1];
            j += 2;
        }
        
        tournamentActive = true;

        tournamentStartTime = block.timestamp;
        
        emit TournamentStarted(tournamentStartTime, bracketSize);
    }

    /**
     * @dev Allows the tournament owner to end the tournament, starting the auction period.
     * Can only be called by the current owner.
     * Reverts if final voting period has not yet elapsed
     * Sets the `winningSubmissionId`
     */
    function endTournament() external onlyOwner {
        
        // calculate # rounds in the tournament
        uint8[7] memory bracketSizes = [2, 4, 8, 16, 32, 64, 128];
        uint8 numRounds;
        for (uint256 i = 0; i < 7; i++) {
            if (bracketSize == bracketSizes[i]) {
                numRounds = uint8(i) + 1;
                break;
            }
        }
        // all the rounds must have elapsed
        require (getCurrentRound() > numRounds, "votingPeriod for final round has not elapsed");

        // determine winner for final matchId and store winning submission
        // the final matchId is `bracketSize - 1`
        Match storage _match = matches[bracketSize - 1];
        
        if (_match.votesA > _match.votesB) {
            winningSubmissionId = _match.submissionA;
        } else if (_match.votesA < _match.votesB) {
            winningSubmissionId = _match.submissionB;
        } else {
            (block.timestamp % 2 == 0) ? 
            winningSubmissionId = _match.submissionA : 
            winningSubmissionId = _match.submissionB;
        }
        
        tournamentActive = false;
        _match.winnerDetermined = true;

        // tournamentEndTime = auctionStartTime
        auctionItems[winningSubmissionId].auctionStartTime = block.timestamp;
        auctionItems[winningSubmissionId].auctionEndTime = block.timestamp + AUCTION_PERIOD;

        emit TournamentEnded(winningSubmissionId, block.timestamp + AUCTION_PERIOD);
    }

    /**
     * @dev Allows player to submit an NFT to the contract.
     * Reverts if number of submissions has already reached `bracketSize`
     * Reverts if called after `tournamentStartTime`
     * Reverts if `addr` does not match `whitelistedNFT` (if `whitelistedNFT` has been set)
     * @param _addr address of the NFT contract.
     * @param _tokenId tokenId of the submitted NFT.
     */
    function submitNFT(address _addr, uint256 _tokenId) external {
        require(nextSubmissionId <= bracketSize, "bracketSize: bracket full");
        require(block.timestamp < tournamentStartTime, "tournamentStartTime: tournament has started");
        if (whitelistedNFT != address(0)) require(_addr == whitelistedNFT, "must be whitelisted NFT address");
        
        // escrow the NFT
        IERC721(_addr).transferFrom(msg.sender, address(this), _tokenId);
        
        emit NFTSubmitted(msg.sender, _addr, _tokenId);
        
        // create Submission object and store it in the submissions mapping
        Submission memory submission = Submission({
            owner: msg.sender,
            nftAddress: _addr,
            tokenId: _tokenId
        });
        
        submissions[nextSubmissionId] = submission;
        
        // increment submissionId
        nextSubmissionId++;
    }

    /**
     * @dev Allows users to vote for an NFT.
     * Reverts if the NFT of `submissionId` is not in the active round (been knocked out).
     * @param submissionId the `submissionId` for the NFT they want to vote for.
     * @param matchId the `matchId` that the NFT they want to vote for is in.
     */
    function castVote(uint8 submissionId, uint8 matchId, uint256 numVotes) external {

        require(isMatchActive(matchId), "matchId not in this round");

        Match storage _match = matches[matchId];

        // Determine the match pair (happens only once per match at the beginning of the round)
        if (_match.submissionA == 0) _determineMatchPair(matchId, _match);

        _castVote(_match, submissionId, numVotes);
        
        // Transfer TRIBE from player to the contract
        address tribe = registry.tribeToken();
        IERC20(tribe).transferFrom(msg.sender, address(this), numVotes);

        emit VoteCast(matchId, submissionId, msg.sender, numVotes);

    }

    /**
     * @dev Allows NFT submitters to withdraw their submission
     * Can only be called by the submitter whose submission didn't make it into the tournament OR
     * NFT Owner who put up their NFTs for auction but received no bids and AUCTION_PERIOD has elapsed.
     * @param submissionId the `submissionId` for the NFT they want to withdraw.
     */
    function withdrawNFT(uint8 submissionId) external {

        // Create local variables to not have to keep reading from mapping.
        address _nftOwner = submissions[submissionId].owner;
        address _addr = submissions[submissionId].nftAddress;
        uint256 _tokenId = submissions[submissionId].tokenId;

        require(msg.sender == _nftOwner, "Can only be withdrawn by NFT submitter");

        if (auctionItems[submissionId].auctionStartTime > 0) {
            require(
                block.timestamp > auctionItems[submissionId].auctionEndTime &&
                auctionItems[submissionId].highestBidder == address(0),
                "Auction period must have elapsed with no bidders"
            );
        } else {
            require(submissionId > bracketSize, "Submission must not be active in the tournament");
        }

        IERC721(_addr).transferFrom(address(this), _nftOwner, _tokenId);
        
        emit NFTWithdrawn(msg.sender, _addr, _tokenId);
        
    }

    /**
     * @dev Allows auction winner to withdraw the winning NFT
     * Can only be called by the `highestBidder` after AUCTION_PERIOD has elapsed.
     * @param submissionId of NFT to claim
     */
    function claimAuctionNFT(uint8 submissionId) external {

        address _highestBidder = auctionItems[submissionId].highestBidder;
        uint256 _auctionStartTime = auctionItems[submissionId].auctionStartTime;
        uint256 _auctionEndTime = auctionItems[submissionId].auctionEndTime;

        require(_auctionStartTime > 0, "Auction not yet initiated for this submission");
        require(
            block.timestamp > _auctionEndTime, "Auction period must have elapsed"
        );
        require(msg.sender == _highestBidder, "Caller must be the highest bidder");

        address _addr = submissions[winningSubmissionId].nftAddress;
        uint256 _tokenId = submissions[winningSubmissionId].tokenId;

        IERC721(_addr).transferFrom(address(this), msg.sender, _tokenId);

        emit NFTWithdrawn(msg.sender, _addr, _tokenId);
    }

    /**
     * @dev Allows match winners to withdraw the loser's NFT
     * Can only be called by the rightful "withdrawer".
     * ... i.e. the winner of the a match (if their submission got more votes)
     * @param submissionId the `submissionId` for the NFT they want to withdraw.
     * @param matchId the `matchId` where the NFT to be withdrawn got eliminated from the contest (for Scenario D).
     */
    function claimMatchNFT(uint8 submissionId, uint8 matchId) external {

        // Create local variables to not have to keep reading from mapping.
        address _nftOwner = submissions[submissionId].owner;
        address _addr = submissions[submissionId].nftAddress;
        uint256 _tokenId = submissions[submissionId].tokenId;

        // nftOwner gets updated when match winner is determined
        require(msg.sender == _nftOwner, "Can only be withdrawn by match winner");
        if (submissionId != winningSubmissionId) {
            require(auctionItems[submissionId].auctionStartTime == 0, "Cannot claim if auction has been initiated");
        }
        
        // Scenario A: Tournament has ENDED, submitter of match-winning NFT wants to withdraw the loser’s NFT.
        if (!tournamentActive) { 

            require(auctionItems[winningSubmissionId].auctionStartTime > 0, "Tournament must have ended");
            require(submissionId != winningSubmissionId, "Winning NFT must enter auction");

        // Scenario B: Tournament is still ACTIVE, submitter of match-winning NFT wants to withdraw the loser’s NFT.
        } else {

            Match storage _match = matches[matchId];

            require(
                submissionId == _match.submissionA ||
                submissionId == _match.submissionB,
                "submissionId not in this match"
            );

            // need to determine winner first to avoid original owner of losing NFT withdrawing
            require(_match.winnerDetermined, "winner has not been determined");
        
            if (_match.submissionA == submissionId) {
                require(_match.votesA < _match.votesB, "tournamentActive: NFT still in the contest");
            } else {
                require(_match.votesB < _match.votesA, "tournamentActive: NFT still in the contest");
            }

        }

        IERC721(_addr).transferFrom(address(this), _nftOwner, _tokenId);

        emit NFTWithdrawn(msg.sender, _addr, _tokenId);
    }

    /**
     * @dev Allow voters to claim TRIBE winnings for multiple matches
     * Voters of winning NFTs get a ratable portion of 90% total votes in TRIBE
     * Submitters of winning NFTs get a 10% total votes in TRIBE
     * @param matchIds array of `matchIds` a voter wants to claim winnings for
     */
    function claimWinningsMultiple(uint8[] calldata matchIds) external {
        for (uint256 i; i < matchIds.length; i++) {
            claimWinnings(matchIds[i]);
        }
    }

    /**
     * @dev Allow voters to claim TRIBE winnings.
     * Voters of winning NFTs get a ratable portion of 90% total votes in TRIBE
     * Submitters of winning NFTs get a 10% total votes in TRIBE
     * @param matchId the match a voter wants to claim winnings for
     */
    function claimWinnings(uint8 matchId) public {
        
        Match storage _match = matches[matchId];
        
        address claimant = msg.sender;
        
        // Not claimable if:
        // 1. Match is still active or hasn't started yet
        // 2. Player already claimed winnings
        // 3. Player is not a voter or an NFT submitter in this match
        _claimabilityCheck(_match, claimant);
        
        uint256 winnings = calculateWinnings(claimant, matchId);

        _match.winningsClaimed[claimant] = true;

        emit WinningsClaimed(matchId, claimant, winnings);

        // Transfer TRIBE from contract to winner
        address tribe = registry.tribeToken();
        IERC20(tribe).transfer(claimant, winnings);

    }

    /**
     * @dev Allow voters/submitters to use claimable TRIBE winnings to vote for a submission in a current round.
     * Automatically converts the total winnings the player has earned for a set of `claimMatchIds`
     * ... and allocates it to `voteSubmissionId` in `voteMatchId`
     * @param claimMatchIds the matchIds a user wants to claim winnings for
     * @param voteSubmissionId the `submissionId` for the NFT they want to vote for.
     * @param voteMatchId the `matchId` that the NFT they want to vote for is in.
     */
    function claimAndVote(
        uint8[] calldata claimMatchIds,
        uint8 voteSubmissionId,
        uint8 voteMatchId)
        external
    {

        require(claimMatchIds.length > 0, "must provide at least 1 matchId to claim from");
        require(isMatchActive(voteMatchId), "voteMatchId not in this round");
        
        Match storage _claimMatch;
        Match storage _voteMatch = matches[voteMatchId];

        // Determine the match pair (happens only once per match at the beginning of the round)
        if (_voteMatch.submissionA == 0) _determineMatchPair(voteMatchId, _voteMatch);

        uint256 winnings;
        
        address claimant = msg.sender;

        for (uint256 i = 0; i < claimMatchIds.length; i++) {
            
            _claimMatch = matches[claimMatchIds[i]];
            
            // Not claimable if:
            // 1. Match is still active or hasn't started yet
            // 2. Player already claimed winnings
            // 3. Player is not a voter or an NFT submitter in this match
            _claimabilityCheck(_claimMatch, claimant);

            _claimMatch.winningsClaimed[claimant] = true;

            winnings += calculateWinnings(claimant, claimMatchIds[i]);
        }

        _castVote(_voteMatch, voteSubmissionId, winnings);

        emit VoteCast(voteMatchId, voteSubmissionId, claimant, winnings);

    }

    /**
     * @dev Allows a match winner to auction off their NFT instead of withdrawing it for themselves.
     * Must be called by the winner of that match.
     * Can be started at any time after the match winner of `matchId` has been decided.
     * @param submissionId of the NFT the winner wants to auction off.
     * @param matchId the match in which the caller won the NFT.
     */
    function startAuction(uint8 submissionId, uint8 matchId) external {
        require(matches[matchId].winnerDetermined, "winner has not been determined");
        require(submissions[submissionId].owner == msg.sender, "must be a winner of NFT to start auction");
        require(auctionItems[submissionId].auctionStartTime == 0, "auction already started for this submission");

        auctionItems[submissionId].auctionStartTime = block.timestamp;
        auctionItems[submissionId].auctionEndTime = block.timestamp + AUCTION_PERIOD;

        emit AuctionStarted(submissionId, block.timestamp);
    }

    /**
     * @dev Sets new owners for losing NFTs and determine contestants for the next round.
     * Can also be determined through the first time votes come in for that match.
     * This function is available in the event that no votes come in, NFTs can still be withdrawn by winners.
     * This only needs to happen once per match.
     * @param matchId to set contestants for.
     */
    function determineMatchPair(uint8 matchId) external {
        Match storage _match = matches[matchId];
        require(isMatchActive(matchId) && _match.submissionA == 0, "match not active or pair already set");
        _determineMatchPair(matchId, _match);
    }

    /**
     * @dev Bid on the auction with the `msg.value`
     * Can be withdrawn if auction is not won.
     * Must be called during the submission period and exceed the current `highestBid`
     * ... or if it's the first bid, must exceed `minBid`
     * @param submissionId of NFT to bid for
     */
    function bid(uint8 submissionId) external payable {

        require(auctionItems[submissionId].auctionStartTime > 0, "Auction not started for this submissionId.");
        address tournamentAdmin = IFactory(_factory).owner();

        address _highestBidder = auctionItems[submissionId].highestBidder;
        uint256 _highestBid = auctionItems[submissionId].highestBid;
        uint256 _auctionEndTime = auctionItems[submissionId].auctionEndTime;

        require(block.timestamp < _auctionEndTime, "Auction already ended.");

        mapping (address => uint256) storage _withdrawableRefund = auctionItems[submissionId].withdrawableRefund;

        uint256 _previousBid = _withdrawableRefund[msg.sender];
        
        if (_highestBid > 0) {
            // if bidder has a previous bid balance, add to total bid and reset `withdrawableRefund`
            if (_previousBid > 0) {

                require(msg.value + _previousBid > _highestBid, "Total bid must exceed current highestBid.");

                _withdrawableRefund[msg.sender] = 0;
                _withdrawableRefund[_highestBidder] += _highestBid;  

                auctionItems[submissionId].highestBid = msg.value + _previousBid;
            
            // bidder is already the highestBidder and want to increase their bid
            } else if (msg.sender == _highestBidder) {
                
                require(msg.value > 0, "Total bid must exceed current highestBid.");

                auctionItems[submissionId].highestBid += msg.value;
                        
            // there is already a highest bidder, add to withdrawableRefund since new bid is the new highestBid.
            } else {
                require(msg.value > _highestBid, "Incoming bid must be higher than current highestBid.");
                _withdrawableRefund[_highestBidder] += _highestBid;
                auctionItems[submissionId].highestBid = msg.value;
            }
            
        // if this is the first bid, require that it exceeds the `minBid`
        } else {
            require(msg.value >= _minBid, "Bid amount must be at least the minimum bid amount.");
            auctionItems[submissionId].highestBid = msg.value;
        }

        auctionItems[submissionId].highestBidder = msg.sender;
        auctionItems[submissionId].latestBidTime = block.timestamp;

        // highest bid has to stand for at least 10 minutes
        // extend auction by 10 minutes new bid comes in in that window after official auctionPeriod ends
        if (block.timestamp + 600 >= _auctionEndTime) auctionItems[submissionId].auctionEndTime = block.timestamp + 600;
            
        emit HighestBidIncreased(submissionId, msg.sender, auctionItems[submissionId].highestBid);
    }

    /**
     * @dev Allows bidders to withdraw funds if they lost the auction
     * Must have a non-zero `withdrawbleRefund` amount.
     * @param submissionId of NFT to withdraw bid refund for
     */
    function withdrawBid(uint8 submissionId) external {

        mapping (address => uint256) storage _withdrawableRefund = auctionItems[submissionId].withdrawableRefund;
        
        require(_withdrawableRefund[msg.sender] > 0, "Caller does not have a balance to withdraw.");
        
        uint256 refund = _withdrawableRefund[msg.sender];
        _withdrawableRefund[msg.sender] = 0;
        
        payable(msg.sender).transfer(refund);
        
        emit BidWithdrawn(submissionId, msg.sender, refund);
    }

    /**
     * @dev Allows submitter of winning NFT to withdraw their earnings (the highest bid).
     * Auction period must have elapsed.
     * Can only be called once by submitter of winning NFT.
     * @param submissionId of NFT to withdraw winnings for
     */
    function withdrawWinnings(uint8 submissionId) external {

        uint256 _highestBid = auctionItems[submissionId].highestBid;
        uint256 _auctionEndTime = auctionItems[submissionId].auctionEndTime;

        require(!auctionItems[submissionId].winningsWithdrawn, "Winnings already withdrawn");
        require(block.timestamp > _auctionEndTime, "Auction period must have elapsed");
        require(msg.sender == submissions[submissionId].owner, "Winnings can only be called by NFT submitter");
        
        auctionItems[submissionId].winningsWithdrawn = true;
        
        // winner gets 90% of final auction earnings, admin takes 10%
        uint256 earnings = _highestBid * 9 / 10;
        payable(msg.sender).transfer(earnings);

        emit WinningBidClaimed(earnings);
    }

        /**
     * @dev Allows tournament admin (`owner`) to withdraw admin fee from auction
     * Auction period must have elapsed.
     * Can only be called once by tournament admin
     */
    function withdrawAdminFee() external {

        uint256 _highestBid = auctionItems[winningSubmissionId].highestBid;
        uint256 _auctionEndTime = auctionItems[winningSubmissionId].auctionEndTime;

        require(!adminFeeWithdrawn, "AdminFee already withdrawn");
        require(block.timestamp > _auctionEndTime, "Auction period must have elapsed");
        
        address tournamentAdmin = IFactory(_factory).owner();
        require(msg.sender == tournamentAdmin, "Caller must be the tournament admin");
        
        adminFeeWithdrawn = true;
        
        // admin takes 10% of highestBid
        uint256 fee = _highestBid / 10;
        payable(tournamentAdmin).transfer(fee);
        
        emit AdminFeeClaimed(fee);
    }

    /***************
    VIEW FUNCTIONS
    ***************/

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the winning submission of the tournament.
     */
    function winner() external view returns (uint8, address, address, uint256) {
        return (
            winningSubmissionId,
            submissions[winningSubmissionId].owner,
            submissions[winningSubmissionId].nftAddress,
            submissions[winningSubmissionId].tokenId
        );
    }

    /**
     * @dev Returns number of total submissions to the Tournament.
     */
    function totalSubmissions() external view returns (uint8) {
        return nextSubmissionId - 1; // minus one because `nextSubmissionId` is 1-indexed
    }

    /**
     * @dev Returns the tournamentStartTime, bracketSize, votingPeriod, whitelistedNFT of the tournament.
     */
    function getTournamentInfo() external view returns (uint256, uint256, uint8, address) {
        return (tournamentStartTime, votingPeriod, bracketSize, whitelistedNFT);
    }

    /**
     * @dev Returns the highestBidder address, highestBid amount, and latestBidTime for a given submission.
     * @param submissionId of auction item to check.
     */
    function getAuctionInfo(uint8 submissionId) external view returns (address, uint256, uint256) {
        address _highestBidder = auctionItems[submissionId].highestBidder;
        uint256 _highestBid = auctionItems[submissionId].highestBid;
        uint256 _latestBidTime = auctionItems[submissionId].latestBidTime;
        return (_highestBidder, _highestBid, _latestBidTime);
    }

    /**
     * @dev Returns withdrawableRefund for `bidder` of on a NFT with `submissionId`
     * @param bidder withdrawable balance to check.
     * @param submissionId of auction item to check.
     */
    function getWithdrawableRefund(address bidder, uint8 submissionId) external view returns (uint256) {
        return auctionItems[submissionId].withdrawableRefund[bidder];
    }

    /**
     * @dev Returns the submissionIds and vote count for each match.
     * @param id of match to check.
     */
    function getMatchInfo(uint8 id) external view returns (uint8, uint8, uint256, uint256) {
        return (
            matches[id].submissionA,
            matches[id].submissionB,
            matches[id].votesA,
            matches[id].votesB
        );
    }

    /**
     * @dev Returns whether `matchId` is in the current round.
     * Determine the current round using the current `block.timestamp`, `tournamentStartTime` and `votingPeriod`.
     * Matches are numbered by round. For example for a `bracketSize` of 16, Round 1 contains matches 1-8
     * ... Round 2 contains matches 9-12, Round 3 contains matches 13-14 etc.
     * @param matchId of the match to check.
     * @return True if `matchId` is a part of the current round.
     */
    function isMatchActive(uint8 matchId) public view returns (bool) {
        // Return false if tournament has not yet started or has ended.
        if (
            block.timestamp < tournamentStartTime ||
            block.timestamp > tournamentStartTime &&
            !tournamentActive
        ) return false;
        
        // Calculate the current round and min/max `matchId`s that are active in that round.
        uint8 currentRound = getCurrentRound();
        uint8 minMatchInRound = 1;
        uint8 maxMatchInRound = bracketSize / 2;

        for (uint256 i = 1; i <= currentRound; i++) {
            if (
                i == currentRound &&
                matchId >= minMatchInRound && 
                matchId <= maxMatchInRound
            ) { return true; }
            minMatchInRound = maxMatchInRound + 1;
            // numMatchesInRound = bracketSize / 2**round
            // maxMatchId in a given round = numMatchesInRound / 2
            maxMatchInRound += uint8(bracketSize / 2**i) / 2;
        }
        return false;
    }

    /**
     * @dev Returns a players' winnings for a given match
     * @param player address of player to check
     * @param matchId match to check player winnings
     * @return Winnings earned by `player` in `matchId`.
     */
    function calculateWinnings(address player, uint8 matchId) public view returns (uint256) {

        uint256 winnings;

        Match storage _match = matches[matchId];

        if (_match.votesA == 0 && _match.votesB == 0) return 0;
        
        if (_match.votesA > _match.votesB) {
            // check that player actually voted for his match to avoid division by 0
            if (_match.playerVotesA[player] > 0) {
                // get original tokens back
                winnings += _match.playerVotesA[player];
                // get ratable amount of 90% of loser's votes
                // (amount voted by player / total winner's votes) * 100 / (loser's votes / 100 * 90) * 100
                // % of player's votes out of total: _match.playerVotesA[player] / _match.votesA * 100
                // 90% of loser's votes: _match.votesB * 9 / 10
                winnings += _match.playerVotesA[player] * _match.votesB * 9 / _match.votesA / 10;
            }
            if (player == submissions[_match.submissionA].owner) {
            // remaining 10% of loser's votes goes to NFT submitter
                winnings += _match.votesB / 10;
            }
        } else if (_match.votesA < _match.votesB) {
            if (_match.playerVotesB[player] > 0) {
                winnings += _match.playerVotesB[player];
                winnings += _match.playerVotesB[player] * _match.votesA * 9 / _match.votesB / 10;
            }
            if (player == submissions[_match.submissionB].owner) {
                winnings += _match.votesA / 10;
            }
        // If it's a tie, voters don't lose TRIBE tokens even though the winner is randomly selected
        } else {
            winnings += _match.playerVotesA[player];
            winnings += _match.playerVotesB[player];
        }

        return winnings;
    }

    /**
     * @dev Returns a number denoting what round we're in (rounds are 1-indexed).
     * Calculated by counting how many `votingPeriods` have elapsed since tournament `tournamentStartTime`.
     * @return The current round.
     */
    function getCurrentRound() public view returns (uint8) {
        // +1 to make rounds 1-indexed
        return uint8(((block.timestamp - tournamentStartTime) / votingPeriod) + 1);
    }

    /**
     * @dev Returns the min bid amount auction phase.
     */
    function minBid() external view returns (uint256) {
        return _minBid;
    }

    /***************
    PRIVATE FUNCTIONS
    ***************/

    /**
     * @dev Updates vote count for a given `submissionId` in a match.
     * Reverts if `submissionId` is not in the given match.
     * @param _match the Match object player wants to vote in.
     * @param _submissionId the `submissionId` for the NFT they want to vote for.
     * @param _numVotes number of votes to cast to a submission.
     */
    function _castVote(Match storage _match, uint8 _submissionId, uint256 _numVotes) private {
        if (_submissionId == _match.submissionA) {
            _match.votesA += _numVotes;
            _match.playerVotesA[msg.sender] += _numVotes;
        } else if (_submissionId == _match.submissionB) {
            _match.votesB += _numVotes;
            _match.playerVotesB[msg.sender] += _numVotes;
        } else {
            revert("submissionId not in this match");
        }
    }

    /**
     * @dev Sets new owners for losing NFTs and determine contestants for the next round.
     * Can be determined through the first time votes come in for that match, or extenally using `determineMatchPair`.
     * This only needs to happen once per match.
     */
    function _determineMatchPair(uint8 matchId, Match storage _match) private {
        uint8 currentRound = getCurrentRound();
        uint8 minMatchInRound = 1;
        uint8 maxMatchInRound = bracketSize / 2;
        uint8 offset = 1;
        uint8 prevMatchId;
        uint8 randomWinner; // in case of ties
        
        for (uint256 i = 1; i < currentRound; i++) {
            prevMatchId = minMatchInRound;
            minMatchInRound = maxMatchInRound + 1;
            maxMatchInRound += uint8(bracketSize / 2**i) / 2;
        }

        // Iterate through matches, and find previous round winners to determine contestants for the current round.
        for (uint256 j = minMatchInRound; j <= maxMatchInRound; j++) {
            // Determine winners and fill in current match up and set new owners of the losing NFTs (for withdrawal)
            if (j == matchId) {
                Match storage prevMatch1 = matches[prevMatchId];
                Match storage prevMatch2 = matches[prevMatchId + 1];
                
                if (prevMatch1.votesA == prevMatch1.votesB) {
                    (block.timestamp % 2 == 0) ? 
                        randomWinner = prevMatch1.submissionA : 
                        randomWinner = prevMatch1.submissionB;
                    _match.submissionA = randomWinner;
                    (randomWinner == prevMatch1.submissionA) ? 
                    submissions[prevMatch1.submissionB].owner = submissions[prevMatch1.submissionA].owner :
                    submissions[prevMatch1.submissionA].owner = submissions[prevMatch1.submissionB].owner;
                } else {
                    if (prevMatch1.votesA > prevMatch1.votesB) {
                        _match.submissionA = prevMatch1.submissionA;
                        submissions[prevMatch1.submissionB].owner = submissions[prevMatch1.submissionA].owner;
                    } else {
                        _match.submissionA = prevMatch1.submissionB;
                        submissions[prevMatch1.submissionA].owner = submissions[prevMatch1.submissionB].owner;
                    }
                }

                if (prevMatch2.votesA == prevMatch2.votesB) {
                    (block.timestamp % 2 == 0) ? 
                        randomWinner = prevMatch2.submissionA : 
                        randomWinner = prevMatch2.submissionB;
                    _match.submissionB = randomWinner;
                    (randomWinner == prevMatch2.submissionA) ? 
                    submissions[prevMatch2.submissionB].owner = submissions[prevMatch2.submissionA].owner :
                    submissions[prevMatch2.submissionA].owner = submissions[prevMatch2.submissionB].owner;
                } else {
                    if (prevMatch2.votesA > prevMatch2.votesB) {
                        _match.submissionB = prevMatch2.submissionA;
                        submissions[prevMatch2.submissionB].owner = submissions[prevMatch2.submissionA].owner;
                    } else {
                        _match.submissionB = prevMatch2.submissionB;
                        submissions[prevMatch2.submissionA].owner = submissions[prevMatch2.submissionB].owner;
                    }
                }
                prevMatch1.winnerDetermined = true;
                prevMatch2.winnerDetermined = true;
                
                emit WinnerDetermined(prevMatchId, _match.submissionA);
                emit WinnerDetermined(prevMatchId + 1, _match.submissionB);
                
                break;
            }
            // prevMatchId is the id of the "top" of the previous round bracket.
            prevMatchId = matchId - uint8((bracketSize / (2**(currentRound-1)))) + offset;
            offset++;
        }
    }

    /**
     * @dev Checks if winnings are claimable by `_claimant` for a given `_match`
     * Reverts if:
     * 1. Match is still active or hasn't started yet OR
     * 2. Player already claimed winnings OR
     * 3. Player is not a voter or an NFT submitter in this match
     * @param _match the Match object player wants to claim winnings from.
     * @param _claimant address of claimant.
     */
    function _claimabilityCheck(Match storage _match, address _claimant) private view {
        require(_match.winnerDetermined, "matchId: match not started or is still active");
        require(!_match.winningsClaimed[_claimant], "winnings already claimed for match");
        require(
            _match.playerVotesA[_claimant] > 0 ||
            _match.playerVotesB[_claimant] > 0 ||
            _claimant == submissions[_match.submissionA].owner ||
            _claimant == submissions[_match.submissionB].owner,
            "claimant must be a voter or NFT submitter in this match"
        );
    }

    /**
     * @dev Generate a randomised array of `submissionIds` for bracket initialisation.
     * Returns the shuffled array containing `submissionIds` up to `bracketSize - 1`.
     * We will treat the shuffled array as the starting bracket. For example, if it is [3, 0, 7, 4, 1, 6, 5, 2]
     * ... Match 1 will be a match between 3 and 0, Match 2 will be between 7 and 4 etc.
     * @return A shuffled array of size `bracketSize` that will be treated as the starting bracket state.
    */
    function _shuffleSubmissions() private view returns (uint8[] memory) {

        // Generate an array of `submissionIds`, up to `bracketSize`
        // i.e. [1, 2, ..., bracketSize]
        uint8[] memory submissionsArr = new uint8[](bracketSize);
        for (uint256 i = 0; i < bracketSize; i++) {
            submissionsArr[i] = uint8(i+1);
        }

        // Shuffle
        for (uint256 i = 0; i < bracketSize; i++) {
            uint8 n = uint8(i) + uint8((
                uint256(
                    keccak256(
                        abi.encodePacked(block.timestamp)
                ))
            ) % uint256(bracketSize - i));
            uint8 temp = submissionsArr[n];
            submissionsArr[n] = submissionsArr[i];
            submissionsArr[i] = temp;
        }

        return submissionsArr;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

/**
 * @title Interface for Registry
 */

interface IRegistry {
    function setTournamentAddress(address _addr) external;
    function setTournamentFactoryAddress(address _addr) external;
    function setTribeTokenAddress(address _addr) external;

    function tournament() external view returns (address);
    function tournamentFactory() external view returns (address);
    function tribeToken() external view returns (address);
}

/// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

/**
 * @title Interface for Tournament Factory
 */

interface IFactory {
    function owner() external view returns (address);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}