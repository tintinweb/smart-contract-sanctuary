pragma solidity ^0.8.0;

import "./PricingSession.sol";
import "./ABCTreasury.sol";
import "./helpers/ReentrancyGuard.sol";


///@author Medici
///@title Bounty auction contract for Abacus
contract BountyAuction is ReentrancyGuard {

    /// @notice store pricing session address 
    PricingSession public session;

    /// @notice store treasury address
    ABCTreasury public treasury;

    /* ======== ADDRESS ======== */

    /// @notice store contract admin address
    address public admin;

    /// @notice store ABC token contract
    address public ABCToken;

    /* ======== BOOL ======== */

    /// @notice track auction active status 
    bool public auctionStatus;

    /// @notice used for customizable first session timeline
    bool public firstSession;

    /* ======== UINT ======== */

    /// @notice used to map to current bounty auction
    uint public nonce;

    /* ======== MAPPINGS ======== */

    /*//////////////////////////////
    //     PER AUCTION STORAGE    //
    //////////////////////////////*/

    /// @notice maps the auction nonce to it's highest bid value
    mapping(uint => uint) public highestBid;
    
    /// @notice maps the auction nonce to it's highest bidder
    mapping(uint => address) public highestBidder;

    /// @notice maps the auction nonce to it's end timestamp
    mapping(uint => uint) public endTime;
    
    /// @notice maps the auction nonce to it's winner
    mapping(uint => address) public winners;
    
    /// @notice maps the action to all it's votes mapped to the voter
    mapping(uint => mapping(address => AuctionVote)) public userVote;

    /*//////////////////////////////
    //     PER ACCOUNT STORAGE    //
    //////////////////////////////*/

    mapping(address => uint) bidTime;

    mapping(address => uint) tvl;

    /* ======== STRUCTS ======== */

    /// @notice stores bidders core information
    struct AuctionVote {

        address nftAddress;
        uint tokenid;
        uint intitialAppraisal;
        uint bid;
    }

    /* ======== EVENTS ======== */
    event newBidSubmitted(address _bidder, uint _bidAmount, address _nftAddress, uint _tokenid, uint _initialAppraisal);
    event auctionEnded(address _highestBidder, uint _highestBid, address _nftAddress, uint _tokenid, uint _initialAppraisal);

    /* ======== Constructor ======== */

    constructor() {
        
        /// @notice set contract admin
        admin = msg.sender;

        /// @notice set session account status to signify auction is active
        auctionStatus = true;
    }

    /* ======== ADMIN ======== */
    
    ///@notice toggles active status of Auction contract
    function toggleAuction() external {
        require(msg.sender == admin);
        auctionStatus = !auctionStatus;
        nonce++;
    }

    /// @notice set session contract to be stored
    /// @param _session address of desired Pricing Session principle contract
    function setSessionContract(address _session) external {
        require(msg.sender == admin);
        session = PricingSession(payable(_session));
    }

    /// @notice set treasury contract to be stored
    /// @param _treasury address of desired ABC treasury address
    function setTreasury(address _treasury) external {
        require(msg.sender == admin);
        treasury = ABCTreasury(payable(_treasury));
    }

    /// @notice set token contract to be stored
    /// @param _token address of desired ABC token contract
    function setToken(address _token) external {
        require(msg.sender == admin);
        ABCToken = _token;
    }

    /// @notice change the state of first session once first auction is complete
    /// @param _state bool representative of whether or not we're currently in the first session
    function setFirst(bool _state) external {
        require(msg.sender == admin);
        firstSession = _state;
    }

    /* ======== AUCTION INTERACTION ======== */

    /// @notice allow user to submit new bid
    /// @param _nftAddress - address of the ERC721/ERC1155 token
    /// @param _tokenid - ID of the token
    /// @param _initialAppraisal - initial nft appraisal 
    function newBid(address _nftAddress, uint _tokenid, uint _initialAppraisal) nonReentrant payable external {
        require(
            msg.value > highestBid[nonce]
            && auctionStatus
            && (session.nftNonce(_nftAddress,_tokenid) == 0 || session.getStatus(_nftAddress, _tokenid) == 5)
        );
        bidTime[msg.sender] = block.timestamp;
        highestBidder[nonce] = msg.sender;
        highestBid[nonce] = msg.value;
        tvl[msg.sender] -= userVote[nonce][msg.sender].bid;
        (bool sent, ) = payable(msg.sender).call{value: userVote[nonce][msg.sender].bid}("");
        require(sent);
        userVote[nonce][msg.sender].nftAddress = _nftAddress;
        userVote[nonce][msg.sender].tokenid = _tokenid;
        userVote[nonce][msg.sender].intitialAppraisal = _initialAppraisal;
        userVote[nonce][msg.sender].bid = msg.value;
        tvl[msg.sender] += msg.value;
        emit newBidSubmitted(msg.sender, msg.value, _nftAddress, _tokenid, _initialAppraisal);
    }

    /// @notice allow add to past bid
    /// @param _nftAddress - address of the ERC721/ERC1155 token
    /// @param _tokenid - ID of the token
    function addToBid(address _nftAddress, uint _tokenid) nonReentrant payable external {
        require(
            userVote[nonce][msg.sender].bid + msg.value > highestBid[nonce] 
            && auctionStatus
            && (session.nftNonce(_nftAddress,_tokenid) == 0 || session.getStatus(_nftAddress, _tokenid) == 5)
        );
        userVote[nonce][msg.sender].bid += msg.value;
        highestBidder[nonce] = msg.sender;
        highestBid[nonce] = userVote[nonce][msg.sender].bid;
        tvl[msg.sender] += msg.value;
    }

    /// @notice allow user to change nft that they'd like appraised if they win
    /// @param _nftAddress users desired NFT address for session to be created
    /// @param _tokenid users desired tokenid for session to be created
    /// @param _initialAppraisal users desired initial appraisal value for session to be created
    function changeInfo(address _nftAddress, uint _tokenid, uint _initialAppraisal) external {
        require(userVote[nonce][msg.sender].nftAddress != address(0) && auctionStatus);
        userVote[nonce][msg.sender].nftAddress = _nftAddress;
        userVote[nonce][msg.sender].tokenid = _tokenid;
        userVote[nonce][msg.sender].intitialAppraisal = _initialAppraisal;
    }

    /// @notice triggered when auction ends, starts session for highest bidder
    function endAuction() nonReentrant external {
        if(firstSession) {
            require(msg.sender == admin);
        }
        require(endTime[nonce] < block.timestamp && auctionStatus);
        uint bountySend = userVote[nonce][highestBidder[nonce]].bid;
        tvl[highestBidder[nonce]] -= bountySend;
        session.createNewSession{value: bountySend}(
            userVote[nonce][highestBidder[nonce]].nftAddress, 
            userVote[nonce][highestBidder[nonce]].tokenid,
            userVote[nonce][highestBidder[nonce]].intitialAppraisal,
            86400
        );
        userVote[nonce][highestBidder[nonce]].bid = 0;
        endTime[++nonce] = block.timestamp + 86400;
        emit auctionEnded(
            highestBidder[nonce], 
            userVote[nonce][highestBidder[nonce]].bid, 
            userVote[nonce][highestBidder[nonce]].nftAddress, 
            userVote[nonce][highestBidder[nonce]].tokenid, 
            userVote[nonce][highestBidder[nonce]].intitialAppraisal
        );
    }

    /// @notice allows users to claim non-employed funds
    function claim() nonReentrant external {
        uint returnValue;
        if(highestBidder[nonce] != msg.sender) {
            returnValue = tvl[msg.sender];
            userVote[nonce][msg.sender].bid = 0;
        }
        else {
            returnValue = tvl[msg.sender] - userVote[nonce][msg.sender].bid;
        }
        tvl[msg.sender] -= returnValue;
        (bool sent, ) = payable(msg.sender).call{value: returnValue}("");
        require(sent);
    }
}

pragma solidity ^0.8.0;

import "./helpers/ReentrancyGuard.sol";
import "./interfaces/IABCTreasury.sol";
import "./libraries/SafeMath.sol";
import "./libraries/sqrtLibrary.sol";
import "./libraries/PostSessionLibrary.sol";
import "./interfaces/IERC20.sol";
import "./ABCTreasury.sol";

/// @author Medici
/// @title Pricing session contract for Abacus
contract PricingSession is ReentrancyGuard {

    using SafeMath for uint;

    /* ======== ADDRESS ======== */

    address public ABCToken;
    ABCTreasury public Treasury;
    address public admin;
    address auction;

    /* ======== BOOL ======== */

    bool auctionStatus;
    bool tokenStatus;
    
    /* ======== MAPPINGS ======== */

    /// @notice maps each user to their total points earned
    mapping(address => uint) public points;

    /// @notice maps each user to their total profit earned
    mapping(address => uint) public profitStored;

    /// @notice maps each user to their principal stored
    mapping(address => uint) public principalStored;

    /// @notice maps each NFT to its current nonce value
    mapping(address => mapping (uint => uint)) public nftNonce; 

    mapping(uint => mapping(address => mapping(uint => VotingSessionMapping))) NftSessionMap;

    /// @notice maps each NFT pricing session (nonce dependent) to its necessary session checks (i.e. checking session progression)
    /// @dev nonce => tokenAddress => tokenId => session metadata
    mapping(uint => mapping(address => mapping(uint => VotingSessionChecks))) public NftSessionCheck;

    /// @notice maps each NFT pricing session (nonce dependent) to its necessary session core values (i.e. total participants, total stake, etc...)
    mapping(uint => mapping(address => mapping(uint => VotingSessionCore))) public NftSessionCore;

    /// @notice maps each NFT pricing session (nonce dependent) to its final appraisal value output
    mapping(uint => mapping(address => mapping(uint => uint))) public finalAppraisalValue;
    
    /* ======== STRUCTS ======== */

    /// @notice tracks all of the mappings necessary to operate a session
    struct VotingSessionMapping {

        mapping (address => uint) voterCheck;
        mapping (address => uint) winnerPoints;
        mapping (address => uint) amountHarvested;
        mapping (address => Voter) nftVotes;
    }

    /// @notice track necessary session checks (i.e. whether its time to weigh votes or harvest)
    struct VotingSessionChecks {

        uint sessionProgression;
        uint calls;
        uint correct;
        uint incorrect;
        uint timeFinalAppraisalSet;
    }

    /// @notice track the core values of a session (max appraisal value, total session stake, etc...)
    struct VotingSessionCore {

        uint endTime;
        uint bounty;
        uint lowestStake;
        uint maxAppraisal;
        uint totalAppraisalValue;
        uint totalSessionStake;
        uint totalProfit;
        uint totalWinnerPoints;
        uint totalVotes;
        uint uniqueVoters;
        uint votingTime;
    }

    /// @notice track voter information
    struct Voter {

        bytes32 concealedAppraisal;
        uint base;
        uint appraisal;
        uint stake;
    }

    /* ======== EVENTS ======== */

    event PricingSessionCreated(address creator_, uint nonce, address nftAddress_, uint tokenid_, uint initialAppraisal_, uint bounty_);
    event newAppraisalAdded(address voter_, uint nonce, address nftAddress_, uint tokenid_, uint stake_, bytes32 userHash_);
    event bountyIncreased(address sender_, uint nonce, address nftAddress_, uint tokenid_, uint amount_);
    event appraisalIncreased(address sender_, uint nonce, address nftAddress_, uint tokenid_, uint amount_);
    event voteWeighed(address user_, uint nonce, address nftAddress_, uint tokenid_, uint appraisal);
    event finalAppraisalDetermined(uint nonce, address nftAddress_, uint tokenid_, uint finalAppraisal, uint amountOfParticipants, uint totalStake);
    event userHarvested(address user_, uint nonce, address nftAddress_, uint tokenid_, uint harvested);
    event ethClaimedByUser(address user_, uint ethClaimed);
    event ethToABCExchange(address user_, uint ethExchanged, uint ppSent);
    event sessionEnded(address nftAddress, uint tokenid, uint nonce);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _treasury, address _auction) {
        Treasury = ABCTreasury(payable(_treasury));
        auction = _auction;
        admin = msg.sender;
        auctionStatus = true;
        tokenStatus = false;
    }

    /// @notice set the auction address to be referenced throughout the contract
    /// @param _auction desired auction address to be stored and referenced in contract
    function setAuction(address _auction) external {
        require(msg.sender == admin);
        auction = _auction;
    }

    /// @notice set the auction status based on the active/inactive status of the bounty auction
    /// @param status desired auction status to be stored and referenced in contract
    function setAuctionStatus(bool status) external {
        require(msg.sender == admin); 
        auctionStatus = status;
    }

    function setABCToken(address _token) external {
        ABCToken = _token;
        tokenStatus = true;
    }

    /// @notice Allow user to create new session and attach initial bounty
    /**
    @dev NFT sessions are indexed using a nonce per specific nft.
    The mapping is done by mapping a nonce to an NFT address to the 
    NFT token id. 
    */ 
    /// @param nftAddress NFT contract address of desired NFT to be priced
    /// @param tokenid NFT token id of desired NFT to be priced 
    /// @param _initialAppraisal appraisal value for max value to be instantiated against
    /// @param _votingTime voting window duration
    function createNewSession(
        address nftAddress,
        uint tokenid,
        uint _initialAppraisal,
        uint _votingTime
    ) stopOverwrite(nftAddress, tokenid) external payable {
        require(_votingTime <= 1 days && (!auctionStatus || msg.sender == auction));
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        if(msg.sender == auction) {}
        else {
            uint abcCost = 0.005 ether *(ethToAbc());
            (bool abcSent) = IERC20(ABCToken).transferFrom(msg.sender, address(Treasury), abcCost);
            require(abcSent);
        }
        if(nftNonce[nftAddress][tokenid] == 0 || getStatus(nftAddress, tokenid) == 5) {}
        else if(block.timestamp > sessionCore.endTime + sessionCore.votingTime * 3) {
            _executeEnd(nftAddress, tokenid);
        }
        nftNonce[nftAddress][tokenid]++;
        VotingSessionCore storage sessionCoreNew = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        sessionCoreNew.votingTime = _votingTime;
        sessionCoreNew.maxAppraisal = 69420 * _initialAppraisal / 1000;
        sessionCoreNew.lowestStake = 100000 ether;
        sessionCoreNew.endTime = block.timestamp + _votingTime;
        sessionCoreNew.bounty = msg.value;
        emit PricingSessionCreated(msg.sender, nftNonce[nftAddress][tokenid], nftAddress, tokenid, _initialAppraisal, msg.value);
    }

    function depositPrincipal() nonReentrant payable external {
        principalStored[msg.sender] += msg.value;
    }

    /// @notice allows user to reclaim principalUsed in batches
    function claimPrincipalUsed(uint _amount) nonReentrant external {
        require(_amount <= principalStored[msg.sender]);
        principalStored[msg.sender] -= _amount;
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent);
    }

    /// @notice allows user to claim batched earnings
    /// @param trigger denotes whether the user desires it in ETH (1) or ABC (2)
    function claimProfitsEarned(uint trigger, uint _amount) nonReentrant external {
        require(trigger == 1 || trigger == 2);
        if(trigger == 2) {
            require(tokenStatus);
        }
        require(profitStored[msg.sender] >= _amount);
        if(trigger == 1) {
            (bool sent1, ) = msg.sender.call{value: _amount}("");
            require(sent1);
            profitStored[msg.sender] -= _amount;
            emit ethClaimedByUser(msg.sender, _amount);
        }
        else if(trigger == 2) {
            uint abcAmount = _amount / (0.00005 ether + 0.000015 ether * Treasury.tokensClaimed()/(1000000*1e18));
            uint abcPayout = ((_amount / (0.00005 ether + 0.000015 ether * Treasury.tokensClaimed()/(1000000*1e18))) + (_amount / (0.00005 ether + 0.000015 ether * Treasury.tokensClaimed() + abcAmount) / (1000000*1e18)) / 2);
            (bool sent3, ) = payable(Treasury).call{value: _amount}("");
            require(sent3);
            profitStored[msg.sender] -= _amount;
            Treasury.sendABCToken(msg.sender, abcPayout * 1e18);
            emit ethToABCExchange(msg.sender, _amount, abcPayout);
        }
    } 

    /* ======== USER VOTE FUNCTIONS ======== */
    
    /// @notice Allows user to set vote in party 
    /** 
    @dev Users appraisal is hashed so users can't track final appraisal and submit vote right before session ends.
    Therefore, users must remember their appraisal in order to reveal their appraisal in the next function.
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    /// @param concealedAppraisal concealed bid that is a hash of the appraisooooors appraisal value, wallet address, and seed number
    function setVote(
        address nftAddress,
        uint tokenid,
        uint stake,
        bytes32 concealedAppraisal
    ) properVote(nftAddress, tokenid, stake) external {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        require(sessionCore.endTime > block.timestamp && stake <= principalStored[msg.sender]);
        sessionMap.voterCheck[msg.sender] = 1;
        principalStored[msg.sender] -= stake;
        if (stake < sessionCore.lowestStake) {
            sessionCore.lowestStake = stake;
        }
        sessionCore.uniqueVoters++;
        sessionCore.totalSessionStake = sessionCore.totalSessionStake.add(stake);
        sessionMap.nftVotes[msg.sender].concealedAppraisal = concealedAppraisal;
        sessionMap.nftVotes[msg.sender].stake = stake;
        emit newAppraisalAdded(msg.sender, nonce, nftAddress, tokenid, stake, concealedAppraisal);
    }

    /// @notice allow user to update value inputs of their vote while voting is still active
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    /// @param concealedAppraisal concealed bid that is a hash of the appraisooooors new appraisal value, wallet address, and seed number
    function updateVote(
        address nftAddress,
        uint tokenid,
        bytes32 concealedAppraisal
    ) external {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        require(sessionMap.voterCheck[msg.sender] == 1);
        require(sessionCore.endTime > block.timestamp);
        sessionMap.nftVotes[msg.sender].concealedAppraisal = concealedAppraisal;
    }

    /// @notice Reveals user vote and weights based on the sessions lowest stake
    /**
    @dev calculation can be found in the weightVoteLibrary.sol file. 
    Votes are weighted as sqrt(userStake/lowestStake). Depending on a votes weight
    it is then added as multiple votes of that appraisal (i.e. if someoneone has
    voting weight of 8, 8 votes are submitted using their appraisal).
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    /// @param appraisal appraisooooor appraisal value used to unlock concealed appraisal
    /// @param seedNum appraisooooor seed number used to unlock concealed appraisal
    function weightVote(address nftAddress, uint tokenid, uint appraisal, uint seedNum) checkParticipation(nftAddress, tokenid) nonReentrant external {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        require(sessionCheck.sessionProgression < 2
                && sessionCore.endTime < block.timestamp
                && sessionMap.voterCheck[msg.sender] == 1
                && sessionMap.nftVotes[msg.sender].concealedAppraisal == keccak256(abi.encodePacked(appraisal, msg.sender, seedNum))
                && sessionCore.maxAppraisal >= appraisal
        );
        sessionMap.voterCheck[msg.sender] = 2;
        if(sessionCheck.sessionProgression == 0) {
            sessionCheck.sessionProgression = 1;
        }
        _weigh(nftAddress, tokenid, appraisal);
        emit voteWeighed(msg.sender, nonce, nftAddress, tokenid, appraisal);
        if(sessionCheck.calls == sessionCore.uniqueVoters || sessionCore.endTime + sessionCore.votingTime < block.timestamp) {
            sessionCheck.sessionProgression = 2;
            sessionCore.uniqueVoters = sessionCheck.calls;
            sessionCheck.calls = 0;
        }
    }
    
    /// @notice takes average of appraisals and outputs a final appraisal value.
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function setFinalAppraisal(address nftAddress, uint tokenid) public {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        require(
            (block.timestamp > sessionCore.endTime + sessionCore.votingTime || sessionCheck.sessionProgression == 2)
            && sessionCheck.sessionProgression <= 2
        );
        Treasury.updateNftPriced();
        if(sessionCheck.calls != 0) {
            sessionCore.uniqueVoters = sessionCheck.calls;
        }
        sessionCore.totalProfit += sessionCore.bounty;
        sessionCore.totalSessionStake += sessionCore.bounty;
        sessionCheck.calls = 0;
        sessionCheck.timeFinalAppraisalSet = block.timestamp;
        finalAppraisalValue[nonce][nftAddress][tokenid] = (sessionCore.totalAppraisalValue)/(sessionCore.totalVotes);
        sessionCheck.sessionProgression = 3;
        emit finalAppraisalDetermined(nftNonce[nftAddress][tokenid], nftAddress, tokenid, finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid], sessionCore.uniqueVoters, sessionCore.totalSessionStake);
    }

    /// @notice Calculates users base and harvests their loss before returning remaining stake
    /**
    @dev A couple notes:
    1. Base is calculated based on margin of error.
        > +/- 5% = 1
        > +/- 4% = 2
        > +/- 3% = 3
        > +/- 2% = 4
        > +/- 1% = 5
        > Exact = 6
    2. winnerPoints are calculated based on --> base * stake
    3. Losses are harvested based on --> (margin of error - 5%) * stake
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function harvest(address nftAddress, uint tokenid) checkParticipation(nftAddress, tokenid) nonReentrant external {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        require(
            sessionCheck.sessionProgression == 3
            && sessionMap.voterCheck[msg.sender] == 2
        );
        sessionCheck.calls++;
        sessionMap.voterCheck[msg.sender] = 3;
        
        _harvest(nftAddress, tokenid);

        sessionMap.nftVotes[msg.sender].stake -= sessionMap.amountHarvested[msg.sender];
        uint commission = PostSessionLibrary.setCommission(address(Treasury).balance).mul(sessionMap.amountHarvested[msg.sender]).div(10000);
        sessionCore.totalSessionStake -= commission;
        sessionMap.amountHarvested[msg.sender] -= commission;
        sessionCore.totalProfit += sessionMap.amountHarvested[msg.sender];
        Treasury.updateProfitGenerated(sessionMap.amountHarvested[msg.sender]);
        (bool sent, ) = payable(Treasury).call{value: commission}("");
        require(sent);
        emit userHarvested(msg.sender, nonce, nftAddress, tokenid, sessionMap.amountHarvested[msg.sender]);

        if(sessionCheck.calls == sessionCore.uniqueVoters) {
            sessionCheck.sessionProgression = 4;
            sessionCore.uniqueVoters = sessionCheck.calls;
            sessionCheck.calls = 0;
        }
    }

    /// @notice User claims principal stake along with any earned profits in ETH or ABC form
    /**
    @dev 
    1. Calculates user principal return value
    2. Enacts sybil defense mechanism
    3. Edits totalProfits and totalSessionStake to reflect claim
    5. Pays out principal
    6. Adds profit credit to profitStored
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function claim(address nftAddress, uint tokenid) checkParticipation(nftAddress, tokenid) nonReentrant external returns(uint) {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        if (sessionCheck.timeFinalAppraisalSet == 0) {
            require(
            sessionCheck.sessionProgression == 4
            || block.timestamp > (sessionCore.endTime + sessionCore.votingTime * 2)
            );
        }
        else{
            require(
            (block.timestamp > sessionCheck.timeFinalAppraisalSet + sessionCore.votingTime || sessionCheck.sessionProgression == 4)
            && sessionCheck.sessionProgression <= 4
            && sessionMap.voterCheck[msg.sender] == 3
            );
        }
        uint principalReturn;
        sessionMap.voterCheck[msg.sender] = 4;
        if(sessionCheck.sessionProgression == 3) {
            sessionCore.uniqueVoters = sessionCheck.calls;
            sessionCheck.calls = 0;
            sessionCheck.sessionProgression = 4;
        }
        if(sessionCheck.correct * 100 / (sessionCheck.correct + sessionCheck.incorrect) >= 90) {
            principalReturn += sessionMap.nftVotes[msg.sender].stake + sessionMap.amountHarvested[msg.sender];
        }
        else {
            principalReturn += sessionMap.nftVotes[msg.sender].stake;
        }
        sessionCheck.calls++;
        uint payout;
        if(sessionMap.winnerPoints[msg.sender] == 0) {
            payout = 0;
        }
        else {
            payout = sessionCore.totalProfit * sessionMap.winnerPoints[msg.sender] / sessionCore.totalWinnerPoints;
        }
        profitStored[msg.sender] += payout;
        sessionCore.totalProfit -= payout;
        sessionCore.totalSessionStake -= payout + principalReturn;
        principalStored[msg.sender] += principalReturn;
        sessionCore.totalWinnerPoints -= sessionMap.winnerPoints[msg.sender];
        sessionMap.winnerPoints[msg.sender] = 0;
        if(sessionCheck.calls == sessionCore.uniqueVoters || block.timestamp > sessionCheck.timeFinalAppraisalSet + sessionCore.votingTime*2) {
            sessionCheck.sessionProgression = 5;
            _executeEnd(nftAddress, tokenid);
            return 0;
        }

        return 1;
    }
    
    /// @notice Custodial function to clear funds and remove session as child
    /// @dev Caller receives 10% of the funds that are meant to be cleared
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function endSession(address nftAddress, uint tokenid) public {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        if (sessionCheck.timeFinalAppraisalSet == 0) {
            revert();
        }
        else{
            require(
                (block.timestamp > sessionCheck.timeFinalAppraisalSet + sessionCore.votingTime * 2 || sessionCheck.sessionProgression == 5)
            );
            _executeEnd(nftAddress, tokenid);
        }
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _weigh(address nftAddress, uint tokenid, uint appraisal) internal {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        sessionMap.nftVotes[msg.sender].appraisal = appraisal;
        uint weight = sqrtLibrary.sqrt(sessionMap.nftVotes[msg.sender].stake/sessionCore.lowestStake);
        sessionCore.totalVotes += weight;
        sessionCheck.calls++;
        
        sessionCore.totalAppraisalValue = sessionCore.totalAppraisalValue.add((weight) * appraisal);
    }

    function _harvest(address nftAddress, uint tokenid) internal {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        sessionMap.nftVotes[msg.sender].base = 
            PostSessionLibrary.calculateBase(
                finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid], 
                sessionMap.nftVotes[msg.sender].appraisal
            );
        uint weight = sqrtLibrary.sqrt(sessionMap.nftVotes[msg.sender].stake/sessionCore.lowestStake);
        if(sessionMap.nftVotes[msg.sender].base > 0) {
            sessionCore.totalWinnerPoints += sessionMap.nftVotes[msg.sender].base * weight;
            sessionMap.winnerPoints[msg.sender] = sessionMap.nftVotes[msg.sender].base * weight;
            sessionCheck.correct += weight;
        }
        else {
            sessionCheck.incorrect += weight;
        }
        
       sessionMap.amountHarvested[msg.sender] = PostSessionLibrary.harvest( 
            sessionMap.nftVotes[msg.sender].stake, 
            sessionMap.nftVotes[msg.sender].appraisal,
            finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid]
        );
    }

    /// @notice executes custodial actions to end a session
    /** @dev Clears session claims to funds, distributes 95% of residual funds
    to treasury and the other 5% to the caller. Then proceeds to set the total
    session stake to 0 and emit an end session event to signify session completion. 
     */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function _executeEnd(address nftAddress, uint tokenid) internal {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        sessionCheck.sessionProgression = 5;
        uint tPayout = 97*sessionCore.totalSessionStake/100;
        uint cPayout = sessionCore.totalSessionStake - tPayout;
        (bool sent, ) = payable(Treasury).call{value: tPayout}("");
        require(sent);
        (bool sent1, ) = msg.sender.call{value: cPayout}("");
        require(sent1);
        sessionCore.totalSessionStake = 0;
        emit sessionEnded(nftAddress, tokenid, nftNonce[nftAddress][tokenid]);
    }

    /* ======== FUND INCREASE ======== */

    /// @notice allow any user to add additional bounty on session of their choice
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function addToBounty(address nftAddress, uint tokenid) payable external {
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require(sessionCore.endTime > block.timestamp);
        sessionCore.bounty += msg.value;
        sessionCore.totalSessionStake += msg.value;
        emit bountyIncreased(msg.sender, nftNonce[nftAddress][tokenid], nftAddress, tokenid, msg.value);
    }

    /* ======== VIEW FUNCTIONS ======== */

    /// @notice returns the status of the session in question
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function getStatus(address nftAddress, uint tokenid) view public returns(uint) {
        return NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].sessionProgression;
    }

    /// @notice returns the current spot exchange rate of ETH to ABC
    function ethToAbc() view public returns(uint) {
        return 1e18 / (0.00005 ether + 0.000015 ether * Treasury.tokensClaimed() / (1000000*1e18));
    }

    /// @notice returns the payout earned from the current session
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function getEthPayout(address nftAddress, uint tokenid) view external returns(uint) {
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        if(sessionCore.totalWinnerPoints == 0) {
            return 0;
        }
        return sessionCore.totalSessionStake * NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].winnerPoints[msg.sender] / sessionCore.totalWinnerPoints;
    }

    /// @notice check the users status in terms of session interaction
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    /// @param _user appraisooooor who's session progress is of interest
    function getVoterCheck(address nftAddress, uint tokenid, address _user) view external returns(uint) {
        return NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[_user];
    }

    /* ======== FALLBACK FUNCTIONS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    /// @notice stop users from being able to create multiple sessions for the same NFT at the same time
    modifier stopOverwrite(
        address nftAddress, 
        uint tokenid
    ) {
        require(
            nftNonce[nftAddress][tokenid] == 0 
            || getStatus(nftAddress, tokenid) == 5
            || block.timestamp > NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].endTime + NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].votingTime * 3
        );
        _;
    }
    
    /// @notice makes sure that a user that submits a vote satisfies the proper voting parameters
    modifier properVote(
        address nftAddress,
        uint tokenid,
        uint stake
    ) {
        require(
            NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[msg.sender] == 0
            && stake >= 0.005 ether
        );
        _;
    }
    
    /// @notice checks the participation of the msg.sender 
    modifier checkParticipation(
        address nftAddress,
        uint tokenid
    ) {
        require(NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[msg.sender] > 0);
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";

/// @author Medici
/// @title Treasury contract for Abacus
contract ABCTreasury {
    
    /* ======== UINT ======== */

    uint public nftsPriced;
    uint public profitGenerated;
    uint public tokensClaimed;

    /* ======== ADDRESS ======== */

    address public auction;
    address public pricingSession;
    address public admin;
    address public ABCToken;
    address public multisig;

    /* ======== CONSTRUCTOR ======== */

    constructor() {
        admin = msg.sender;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    /// @notice set ABC token contract address 
    /// @param _ABCToken desired ABC token to be stored and referenced in contract
    function setABCTokenAddress(address _ABCToken) onlyAdmin external {
        require(ABCToken == address(0));
        ABCToken = _ABCToken;
    }

    function setMultisig(address _multisig) onlyAdmin external {
        multisig = _multisig;
    }

    /// @notice allow admin to withdraw funds to multisig in the case of emergency (ONLY USED IN THE CASE OF EMERGENCY)
    /// @param _amountAbc value of ABC to be withdrawn from the treasury to multisig (ONLY USED IN THE CASE OF EMERGENCY)
    /// @param _amountEth value of ETH to be withdrawn from the treasury to multisig (ONLY USED IN THE CASE OF EMERGENCY)
    function withdraw(uint _amountAbc, uint _amountEth) onlyAdmin external {
        IERC20(ABCToken).transfer(multisig, _amountAbc);
        (bool sent, ) = payable(multisig).call{value: _amountEth}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice set newAdmin (or burn admin when the time comes)
    /// @param _newAdmin desired admin address to be stored and referenced in contract
    function setAdmin(address _newAdmin) onlyAdmin external {
        admin = _newAdmin;
    }

    /// @notice set pricing factory address to allow for updates
    /// @param _pricingFactory desired pricing session principle address to be stored and referenced in contract
    function setPricingSession(address _pricingFactory) onlyAdmin external {
        pricingSession = _pricingFactory;
    }

    /// @notice set auction contract for bounty auction period
    /// @param _auction desired auction address to be stored and referenced in contract
    function setAuction(address _auction) onlyAdmin external {
        auction = _auction;
    }

    /* ======== CHILD FUNCTIONS ======== */
    
    /// @notice send ABC to users that earn 
    /// @param recipient the user that will be receiving ABC 
    /// @param _amount the amount of ABC to be transferred to the recipient
    function sendABCToken(address recipient, uint _amount) external {
        require(msg.sender == pricingSession || msg.sender == admin);
        IERC20(ABCToken).transfer(recipient, _amount);
        tokensClaimed += _amount;
    }

    /// @notice Allows Factory contract to update the profit generated value
    /// @param _amount the amount of profit to update profitGenerated count
    function updateProfitGenerated(uint _amount) isFactory external { 
        profitGenerated += _amount;
    }
    
    /// @notice Allows Factory contract to update the amount of NFTs that have been priced
    function updateNftPriced() isFactory external {
        nftsPriced++;
    }

    /* ======== FALLBACKS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    ///@notice check that msg.sender is admin
    modifier onlyAdmin() {
        require(admin == msg.sender, "not admin");
        _;
    }
    
    ///@notice check that msg.sender is factory
    modifier isFactory() {
        require(msg.sender == pricingSession, "not session contract");
        _;
    }
}

pragma solidity ^0.8.0;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter = 1;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

pragma solidity ^0.8.0;

interface IABCTreasury {
    function sendABCToken(address recipient, uint _amount) external;

    function getTokensClaimed() external view returns(uint);
    
    function updateNftPriced() external;
    
    function updateProfitGenerated(uint _amount) external;

}

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library sqrtLibrary {
    
    function sqrt(uint x) pure internal returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./sqrtLibrary.sol";

library PostSessionLibrary {

    using sqrtLibrary for *;

    /////////////////////
    ///      Base     ///
    /////////////////////

    function calculateBase(uint finalAppraisalValue, uint userAppraisalValue) pure internal returns(uint){
        uint base = 1;
        uint userVal = 100 * userAppraisalValue;
        for(uint i=5; i >= 1; i--) {
            uint lowerOver = (100 + (i - 1)) * finalAppraisalValue;
            uint upperOver = (100 + i) * finalAppraisalValue;
            uint lowerUnder = (100 - i) * finalAppraisalValue;
            uint upperUnder = (100 - i + 1) * finalAppraisalValue;
            if (lowerOver < userVal && userVal <= upperOver) {
                return base; 
            }
            if (lowerUnder < userVal && userVal <= upperUnder) {
                return base;
            }
            base += 1;
        }
        if(userVal == 100*finalAppraisalValue) {
            return 6;
        }
        return 0;
    }

    /////////////////////
    ///    Harvest    ///
    /////////////////////

    // function harvestUserOver(uint _stake, uint _userAppraisal, uint _finalAppraisal) pure internal returns(uint) {
    //     return _stake * (_userAppraisal*100 - 105*_finalAppraisal)/(_finalAppraisal*100);
    // }
    
    // function harvestUserUnder(uint _stake, uint _userAppraisal, uint _finalAppraisal) pure internal returns(uint) {
    //     return _stake * (95*_finalAppraisal - 100*_userAppraisal)/(_finalAppraisal*100);
    // }

    function harvest(uint _stake, uint _userAppraisal, uint _finalAppraisal) pure internal returns(uint) {
        if(_userAppraisal*100 > 105*_finalAppraisal) {
            return _stake * (_userAppraisal*100 - 105*_finalAppraisal)/(_finalAppraisal*100);
        }
        else if(_userAppraisal*100 < 95*_finalAppraisal) {
            return _stake * (95*_finalAppraisal - 100*_userAppraisal)/(_finalAppraisal*100);
        }
        else {
            return 0;
        }
    }

    /////////////////////
    ///   Commission  ///
    /////////////////////   
    function setCommission(uint _treasurySize) pure internal returns(uint) {
        if (_treasurySize < 25000 ether) {
            return 500;
        }
        else if(_treasurySize >= 25000 ether && _treasurySize < 50000 ether) {
            return 400;
        }
        else if(_treasurySize >= 50000 ether && _treasurySize < 100000 ether) {
            return 300;
        }
        else if(_treasurySize >= 100000 ether && _treasurySize < 2000000 ether) {
            return 200;
        }
        else if(_treasurySize >= 200000 ether && _treasurySize < 400000 ether) {
            return 100;
        }
        else if(_treasurySize >= 400000 ether && _treasurySize < 700000 ether) {
            return 50;
        }
        else {
            return 25;
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