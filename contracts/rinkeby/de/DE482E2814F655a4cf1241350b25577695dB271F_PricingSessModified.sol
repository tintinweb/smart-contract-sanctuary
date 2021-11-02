/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File contracts/helpers/ReentrancyGuard.sol

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


// File contracts/interfaces/IABCTreasury.sol

pragma solidity ^0.8.0;

interface IABCTreasury {
    function sendABCToken(address recipient, uint _amount) external;

    function updateUserPoints(address _user, uint _amountGained, uint _amountLost) external;

    function tokensClaimed() external view returns(uint);
    
    function updateNftPriced() external;
    
    function updateProfitGenerated(uint _amount) external;

    function getAuction() view external returns(address);
}


// File contracts/libraries/SafeMath.sol

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


// File contracts/libraries/sqrtLibrary.sol

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


// File contracts/libraries/PostSessionLibrary.sol

pragma solidity ^0.8.0;

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


// File contracts/interfaces/IERC20.sol

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


// File contracts/PricingSession.sol

pragma solidity ^0.8.0;






/// @author Medici
/// @title Pricing session contract for Abacus
contract PricingSessModified is ReentrancyGuard {

    using SafeMath for uint;

    address immutable public ABCToken;
    address immutable public Treasury;
    address auction;
    address admin;
    bool auctionStatus;
    
    /* ======== MAPPINGS ======== */

    mapping(address => mapping (uint => uint)) public nftNonce; 
    mapping(uint => mapping(address => mapping(uint => VotingSessionMapping))) NftSessionMap;
    mapping(uint => mapping(address => mapping(uint => VotingSessionChecks))) public NftSessionCheck;
    mapping(uint => mapping(address => mapping(uint => VotingSessionCore))) public NftSessionCore;
    mapping(uint => mapping(address => mapping(uint => uint))) public finalAppraisalValue;
    
    /* ======== STRUCTS ======== */

    struct VotingSessionMapping {
        mapping (address => uint) voterCheck;
        mapping (address => uint) winnerPoints;
        mapping (address => uint) amountHarvested;
        mapping (address => Voter) nftVotes;
    }

    struct VotingSessionChecks {
        bool claimsComplete;
        bool finalAppraisalSet;
        bool harvestLossComplete;
        bool sessionOver;
        bool votesWeighted;

        uint calls;
        uint correct;
        uint incorrect;
        uint timeFinalAppraisalSet;
    }

    struct VotingSessionCore {
        address Dao;

        uint endTime;
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

    struct Voter {
        bytes32 concealedBid;
        uint base;
        uint appraisal;
        uint stake;
    }

    /* ======== EVENTS ======== */

    event PricingSessionCreated(address DaoTokenContract, address creator_, address nftAddress_, uint tokenid_, uint initialAppraisal_, uint bounty_);
    event newAppraisalAdded(address voter_, uint stake_, uint appraisal, uint weight);
    event finalAppraisalDetermined(uint finalAppraisal, uint amountOfParticipants, uint totalStake);
    event lossHarvestedFromUser(address user_, uint harvested);
    event ethClaimedByUser(address user_, uint ethClaimed);
    event ethToPPExchange(address user_, uint ethExchanged, uint ppSent);
    event sessionEnded(address nftAddress, uint tokenid, uint nonce);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _ABCToken, address _treasury, address _auction) {
        ABCToken = _ABCToken;
        Treasury = _treasury;
        auction = _auction;
        admin = msg.sender;
        auctionStatus = true;
    }

    function setAuction(address _auction) external {
        require(msg.sender == admin);
        auction = _auction;
    }

    function setAuctionStatus(bool status) external {
        auctionStatus = status;
    }

    /// @notice Allow user to create new session and attach initial bounty
    /**
    @dev NFT sessions are indexed using a nonce per specific nft.
    The mapping is done by mapping a nonce to an NFT address to the 
    NFT token id. 
    */ 
    function createNewSession(
        address nftAddress,
        uint tokenid,
        uint _initialAppraisal,
        uint _votingTime,
        address _dao
    ) stopOverwrite(nftAddress, tokenid) external payable {
        require(_votingTime <= 1 days && (auctionStatus || msg.sender == auction));
        uint abcCost = 0.005 ether;
        (bool abcSent) = IERC20(ABCToken).transferFrom(msg.sender, Treasury, abcCost);
        require(abcSent);
        if(getStatus(nftAddress, tokenid) == 6) {
            _executeEnd(nftAddress, tokenid);
        }
        nftNonce[nftAddress][tokenid]++;
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        sessionCore.votingTime = _votingTime;
        sessionCore.maxAppraisal = 69420 * _initialAppraisal / 1000;
        sessionCore.lowestStake = 100000 ether;
        sessionCore.endTime = block.timestamp + _votingTime;
        sessionCore.totalSessionStake = msg.value;
        sessionCore.Dao = _dao;
        emit PricingSessionCreated(_dao, msg.sender, nftAddress, tokenid, _initialAppraisal, msg.value);
    }

    /* ======== USER VOTE FUNCTIONS ======== */
    
    function modifyUserStatus(
        address nftAddress,
        uint tokenid,
        address userAddress,
        uint stateChange
    ) external {
        uint currentNonce = nftNonce[nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[currentNonce][nftAddress][tokenid];
        sessionMap.voterCheck[userAddress] = stateChange;
    }
    
    function modifySessionStatus(
        address nftAddress,
        uint tokenid,
        uint newStatus
    ) external {
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        sessionCheck.sessionOver = true;
        sessionCheck.claimsComplete = true;
        sessionCheck.harvestLossComplete = true;
        sessionCheck.finalAppraisalSet = true;
        sessionCheck.votesWeighted = true;
        if(newStatus <= 6) {
            sessionCheck.sessionOver = false;
        }
        if(newStatus <= 5) {
            sessionCheck.claimsComplete = false;
        }
        if(newStatus <= 4) {
            sessionCheck.harvestLossComplete = false;
        }
        if(newStatus <= 3){
            sessionCheck.finalAppraisalSet = false;
        }
        if(newStatus <= 2){
            sessionCheck.votesWeighted = false;
        }
    }
    
    /// @notice Allows user to set vote in party 
    /** 
    @dev Users appraisal is hashed so users can't track final appraisal and submit vote right before session ends.
    Therefore, users must remember their appraisal in order to reveal their appraisal in the next function.
    */
    function setVote(
        address nftAddress,
        uint tokenid,
        bytes32 concealedBid
    ) properVote(nftAddress, tokenid) payable external {
        uint currentNonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[currentNonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[currentNonce][nftAddress][tokenid];
        require(sessionCore.endTime > block.timestamp);
        // if(sessionCore.Dao != address(0)) {
        //     require(IERC20(sessionCore.Dao).balanceOf(msg.sender) > 0);
        // }
        sessionMap.voterCheck[msg.sender] = 1;
        if (msg.value < sessionCore.lowestStake) {
            sessionCore.lowestStake = msg.value;
        }
        sessionCore.uniqueVoters++;
        sessionCore.totalSessionStake = sessionCore.totalSessionStake.add(msg.value);
        sessionMap.nftVotes[msg.sender].concealedBid = concealedBid;
        sessionMap.nftVotes[msg.sender].stake = msg.value;
    }

    function updateVote(
        address nftAddress,
        uint tokenid,
        bytes32 concealedBid
    ) external {
        require(!(NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[msg.sender] == 1));
        uint currentNonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[currentNonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[currentNonce][nftAddress][tokenid];
        require(sessionCore.endTime > block.timestamp);

        // if(sessionCore.Dao != address(0)) {
        //     require(IERC20(sessionCore.Dao).balanceOf(msg.sender) > 0);
        // }
        sessionCore.uniqueVoters++;
        sessionMap.nftVotes[msg.sender].concealedBid = concealedBid;
    }

    /// @notice Reveals user vote and weights based on the sessions lowest stake
    /**
    @dev calculation can be found in the weightVoteLibrary.sol file. 
    Votes are weighted as sqrt(userStake/lowestStake). Depending on a votes weight
    it is then added as multiple votes of that appraisal (i.e. if someoneone has
    voting weight of 8, 8 votes are submitted using their appraisal).
    */
    function weightVote(address nftAddress, uint tokenid, uint appraisal, uint seedNum) checkParticipation(nftAddress, tokenid) nonReentrant external {
        uint currentNonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[currentNonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[currentNonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require(!sessionCheck.votesWeighted
                // && sessionCore.endTime < block.timestamp
                && !(sessionMap.voterCheck[msg.sender] < 2)
                && sessionMap.nftVotes[msg.sender].concealedBid == keccak256(abi.encodePacked(appraisal, msg.sender, seedNum))
                && sessionCore.maxAppraisal >= appraisal
        );
        sessionMap.voterCheck[msg.sender] = 2;
        sessionMap.nftVotes[msg.sender].appraisal = appraisal;
        uint weight = sqrtLibrary.sqrt(sessionMap.nftVotes[msg.sender].stake/sessionCore.lowestStake);
        sessionCore.totalVotes += weight;
        sessionCheck.calls++;
        
        sessionCore.totalAppraisalValue = sessionCore.totalAppraisalValue.add((weight) * sessionMap.nftVotes[msg.sender].appraisal);
        emit newAppraisalAdded(msg.sender, sessionMap.nftVotes[msg.sender].stake, sessionMap.nftVotes[msg.sender].appraisal, weight);
        if(sessionCheck.calls == sessionCore.uniqueVoters) {
            sessionCheck.votesWeighted = true;
            sessionCheck.calls = 0;
        }
    }
    
    /// @notice takes average of appraisals and outputs a final appraisal value.
    function setFinalAppraisal(address nftAddress, uint tokenid) nonReentrant external {
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require(
            !sessionCheck.finalAppraisalSet
            && (block.timestamp > sessionCore.endTime + sessionCore.votingTime || sessionCheck.votesWeighted)
        );

        IABCTreasury(Treasury).updateNftPriced();
        sessionCheck.votesWeighted = true;
        sessionCheck.calls = 0;
        sessionCheck.timeFinalAppraisalSet = block.timestamp;
        finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid] = (sessionCore.totalAppraisalValue)/(sessionCore.totalVotes);
        sessionCheck.finalAppraisalSet = true;
        emit finalAppraisalDetermined(finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid], sessionCore.uniqueVoters, sessionCore.totalSessionStake);
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
    function harvest(address nftAddress, uint tokenid) checkParticipation(nftAddress, tokenid) nonReentrant external {
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require(
            !sessionCheck.harvestLossComplete
            && sessionCheck.finalAppraisalSet
        );
        sessionCheck.calls++;
        sessionMap.voterCheck[msg.sender] = 3;
        sessionMap.nftVotes[msg.sender].base = 
            PostSessionLibrary.calculateBase(
                finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid], 
                sessionMap.nftVotes[msg.sender].appraisal
            );
        
        if(NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].nftVotes[msg.sender].base > 0) {
            sessionCore.totalWinnerPoints += sessionMap.nftVotes[msg.sender].base * sessionMap.nftVotes[msg.sender].stake;
            sessionMap.winnerPoints[msg.sender] = sessionMap.nftVotes[msg.sender].base * sessionMap.nftVotes[msg.sender].stake;
            sessionCheck.correct++;
        }
        else {
            sessionCheck.incorrect++;
        }
        
       sessionMap.amountHarvested[msg.sender] = PostSessionLibrary.harvest( 
            sessionMap.nftVotes[msg.sender].stake, 
            sessionMap.nftVotes[msg.sender].appraisal,
            finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid]
        );

        sessionMap.nftVotes[msg.sender].stake -= sessionMap.amountHarvested[msg.sender];
        uint commission = PostSessionLibrary.setCommission(Treasury.balance).mul(sessionMap.amountHarvested[msg.sender]).div(10000);
        sessionCore.totalSessionStake -= commission;
        sessionMap.amountHarvested[msg.sender] -= commission;
        sessionCore.totalProfit += sessionMap.amountHarvested[msg.sender];
        IABCTreasury(Treasury).updateProfitGenerated(sessionMap.amountHarvested[msg.sender]);
        (bool sent, ) = payable(Treasury).call{value: commission}("");
        require(sent);
        emit lossHarvestedFromUser(msg.sender, sessionMap.amountHarvested[msg.sender]);

        if(sessionCheck.calls == sessionCore.uniqueVoters) {
            sessionCheck.harvestLossComplete = true;
            sessionCheck.calls = 0;
        }
    }

    /// @notice User claims principal stake along with any earned profits in ETH or ABC form
    /**
    @dev 
    1. Calculates user principal return value
    2. Enacts sybil defense mechanism
    3. Edits totalProfits and totalSessionStake to reflect claim
    4. Checks trigger choice
    5. Executes desired payout of principal and profit
    */
    /// @param trigger trigger should be set to 1 if the user wants reward in ETH or 2 if user wants reward in ABC
    function claim(address nftAddress, uint tokenid, uint trigger) checkHarvestLoss(nftAddress, tokenid) checkParticipation(nftAddress, tokenid) nonReentrant external returns(uint){
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require(!sessionCheck.claimsComplete);
        require(trigger == 1 || trigger == 2);
        uint principalReturn;
        sessionMap.voterCheck[msg.sender] = 4;
        if(!sessionCheck.harvestLossComplete) {
            sessionCheck.calls = 0;
        }
        if(sessionCheck.correct * 100 / (sessionCheck.correct + sessionCheck.incorrect) >= 90) {
            principalReturn = sessionMap.nftVotes[msg.sender].stake + sessionMap.amountHarvested[msg.sender];
        }
        else {
            principalReturn = sessionMap.nftVotes[msg.sender].stake;
        }
        sessionCheck.harvestLossComplete = true;
        sessionCheck.calls++;
        uint payout = sessionCore.totalProfit * sessionMap.winnerPoints[msg.sender] / sessionCore.totalWinnerPoints;
        sessionCore.totalProfit -= payout;
        sessionCore.totalSessionStake -= payout + principalReturn;
        sessionCore.totalWinnerPoints -= sessionMap.winnerPoints[msg.sender];
        sessionMap.winnerPoints[msg.sender] = 0;
        if(sessionMap.winnerPoints[msg.sender] == 0) {
            trigger = 1;
        }
        if(trigger == 1) {
            (bool sent1, ) = payable(msg.sender).call{value: principalReturn + payout}("");
            require(sent1);
            emit ethClaimedByUser(msg.sender, payout);
        }
        else if(trigger == 2) {
            uint abcAmount = payout * 1e18 / (0.00005 ether + 0.000015 ether * IABCTreasury(Treasury).tokensClaimed() / 1000000);
            uint abcPayout = payout/2 * (1e18 / (0.00005 ether + 0.000015 ether * IABCTreasury(Treasury).tokensClaimed() / 1000000) + 1e18 / (0.00005 ether + 0.000015 ether * (IABCTreasury(Treasury).tokensClaimed() + abcAmount) / 1000000));
            (bool sent2, ) = payable(msg.sender).call{value: principalReturn}("");
            require(sent2);
            (bool sent3, ) = payable(Treasury).call{value: payout}("");
            require(sent3);
            IABCTreasury(Treasury).sendABCToken(msg.sender,abcPayout);
            emit ethToPPExchange(msg.sender, payout, abcPayout);
        }
        if(sessionCore.totalWinnerPoints == 0) {
            _executeEnd(nftAddress, tokenid);
            return 0;
        }
        if(sessionCheck.calls == sessionCore.uniqueVoters || block.timestamp > sessionCheck.timeFinalAppraisalSet + sessionCore.votingTime*2) {
            _executeEnd(nftAddress, tokenid);
            return 0;
        }

        return 1;
    }
    
    /// @notice Custodial function to clear funds and remove session as child
    /// @dev Caller receives 10% of the funds that are meant to be cleared
    function endSession(address nftAddress, uint tokenid) public {
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require(!sessionCheck.sessionOver && (block.timestamp > sessionCheck.timeFinalAppraisalSet + sessionCore.votingTime * 4 || sessionCheck.claimsComplete));
        _executeEnd(nftAddress, tokenid);
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _executeEnd(address nftAddress, uint tokenid) internal {
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        sessionCheck.sessionOver = true;
        sessionCheck.claimsComplete = true;
        uint tPayout = 90*sessionCore.totalSessionStake/100;
        uint cPayout = sessionCore.totalSessionStake - tPayout;
        (bool sent, ) = payable(Treasury).call{value: tPayout}("");
        require(sent);
        (bool sent1, ) = payable(msg.sender).call{value: cPayout}("");
        require(sent1);
        sessionCore.totalSessionStake = 0;
        emit sessionEnded(nftAddress, tokenid, nftNonce[nftAddress][tokenid]);
    }

    /* ======== FUND INCREASE ======== */

    /// @notice allow any user to add additional bounty on session of their choice
    function addToBounty(address nftAddress, uint tokenid) payable external {
        require(NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].endTime > block.timestamp);
        NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].totalSessionStake += msg.value;
    }
    
    /// @notice allow any user to support any user of their choice
    function addToAppraisal(address nftAddress, uint tokenid, address user) payable external {
        require(
            NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[user] == 1
            && NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].endTime > block.timestamp
        );
        NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].nftVotes[user].stake += msg.value;
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getStatus(address nftAddress, uint tokenid) view public returns(uint) {
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        if(sessionCheck.sessionOver) {
            return 7;
        }
        else if(sessionCheck.claimsComplete) {
            return 6;
        }
        else if(sessionCheck.harvestLossComplete) {
            return 5;
        }
        else if(sessionCheck.finalAppraisalSet) {
            return 4;
        }
        else if(sessionCheck.votesWeighted){
            return 3;
        }
        else if(NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].endTime < block.timestamp){
            return 2;
        }
        else{
            return 1;
        }    
    }

    function getVoterCheck(address nftAddress, uint tokenid, address _user) view external returns(uint) {
        return NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[_user];
    }

    /* ======== FALLBACK FUNCTIONS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    modifier stopOverwrite(
        address nftAddress, 
        uint tokenid
    ) {
        require(
            nftNonce[nftAddress][tokenid] == 0 
            || getStatus(nftAddress, tokenid) == 6
        );
        _;
    }
    
    modifier properVote(
        address nftAddress,
        uint tokenid
    ) {
        require(
            NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[msg.sender] == 0
            && msg.value >= 0.005 ether
        );
        _;
    }
    
    modifier checkParticipation(
        address nftAddress,
        uint tokenid
    ) {
        require(NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[msg.sender] > 0);
        _;
    }
    
    modifier checkHarvestLoss(
        address nftAddress,
        uint tokenid
    ) {
        require(
            NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].harvestLossComplete
            || block.timestamp > (NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].timeFinalAppraisalSet + NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].votingTime)
        );
        _;
    }
}