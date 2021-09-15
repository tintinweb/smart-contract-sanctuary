/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// Sources flattened with hardhat v2.6.2 https://hardhat.org

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


// File contracts/interfaces/IPPTreasury.sol

pragma solidity ^0.8.0;

interface IPPTreasury {
    function sendPP(address recipient, uint _amount) external;

    function updateUserPoints(address _user, uint _amountGained, uint _amountLost) external;

    function tokensClaimed() external view returns(uint);

    function checkWhitelist(address user) external view returns(bool);

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

contract PostSessionLibrary {

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
        if (_treasurySize < 5000 ether) {
            return 500;
        }
        else if(_treasurySize >= 5000 ether && _treasurySize < 10000 ether) {
            return 400;
        }
        else if(_treasurySize >= 10000 ether && _treasurySize < 20000 ether) {
            return 300;
        }
        else if(_treasurySize >= 20000 ether && _treasurySize < 40000 ether) {
            return 200;
        }
        else if(_treasurySize >= 40000 ether && _treasurySize < 80000 ether) {
            return 100;
        }
        else if(_treasurySize >= 80000 ether && _treasurySize < 160000 ether) {
            return 50;
        }
        else {
            return 25;
        }
    }


}


// File contracts/interfaces/IPricingSessionFactory.sol

pragma solidity ^0.8.0;

/// @author Medici
/// @title Used to interface with parent contract
interface IPricingSessionFactory {
    function updateProfitGenerated(uint _amount) external;
    function updateNftPriced() external;
    function updateUserSessions(address _recipient, address _contract) external;
    function setChildState(address _contract) external;
    function checkIsChild() external returns (bool);
    function sendPP(address recipient, uint _amount) external;
    function updateUserPoints(address _user, uint _amountGained, uint _amountLost) external;
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


// File contracts/PPTreasury.sol

pragma solidity ^0.8.0;


/// @author Medici
/// @title Treasury contract for Pricing Protocol
contract PpTreasury{
    
    uint public tokensClaimed;
    address public pricingSessionFactory;
    address public admin;
    address public ppToken;
    //For testnet
    bool public checkMaxValue;

    /* ======== MAPPINGS ======== */
    //For testnet
    mapping(address => uint) public pointsLost;
    mapping(address => uint) public pointsGained;
    mapping(address => bool) public whitelist;

    /* ======== CONSTRUCTOR ======== */

    constructor() {
        admin = msg.sender;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function setPPTokenAddress(address _ppToken) onlyAdmin external {
        require(ppToken == address(0));
        ppToken = _ppToken;
    }

    function withdraw(uint _amount) onlyAdmin external {
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function setAdmin(address _newAdmin) onlyAdmin external {
        admin = _newAdmin;
    }

    function setPricingFactory(address _pricingFactory) onlyAdmin external {
        pricingSessionFactory = _pricingFactory;
    }

    //For testnet
    function toggleMaxValue() onlyAdmin external {
        checkMaxValue = !checkMaxValue;
    }

    //For testnet
    function addToWhitelist(address user) onlyAdmin external {
        whitelist[user] = true;
    }

    //For testnet
    function removeFromWhiteList(address user) onlyAdmin external {
        whitelist[user] = false;
    }

    /* ======== VIEW FUNCTIONS ======== */
    
    function checkWhitelist(address user) view external returns (bool){
        return whitelist[user];
    }

    /* ======== CHILD FUNCTIONS ======== */
    
    function sendPP(address recipient, uint _amount) isFactory external {
        IERC20(ppToken).transfer(recipient, _amount);
        tokensClaimed += _amount;
    }

    //For testnet
    function updateUserPoints(address _user, uint _amountGained, uint _amountLost) isFactory external {
        require(!checkMaxValue);
        if(_amountGained > _amountLost) {
            pointsGained[_user] += _amountGained;
        }
        else {
            pointsLost[_user] += _amountLost;
        }
    }

    /* ======== FALLBACKS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    modifier onlyAdmin() {
        require(admin == msg.sender);
        _;
    }
    
    modifier isFactory() {
        require(msg.sender == pricingSessionFactory);
        _;
    }
}


// File contracts/interfaces/IMaskVote.sol

pragma solidity ^0.8.0;

interface IMaskVote {
    function verifyTrueAppraisal(
        bytes32 concealedBid, 
        uint a, 
        uint b, 
        uint c, 
        uint d, 
        uint e,
        address _user
    ) view external returns (bool);
    
    function verifyWithinLimit(
        uint _maxAppraisal, 
        uint a, 
        uint b, 
        uint c, 
        uint d, 
        uint e
    ) pure external returns (bool);
}


// File contracts/interfaces/IHasher.sol

pragma solidity ^0.8.0;

interface IHasher {
    function getUserRandomValue(address _user) view external returns (uint);
}


// File contracts/PrinciplePricingSession.sol

pragma solidity ^0.8.0;











/// @author Medici
/// @title Individual session contract for Pricing Protocol
contract PricingSession is ReentrancyGuard, PostSessionLibrary {

    /* ======== DEPENDINCIES ======== */
    
    using SafeMath for uint;

    /* ======== STRUCTS ======== */

    struct Voter {
        uint base;
        uint appraisal;
        uint stake;
    }

    /* ======== STATE VARIABLES ======== */

    bool claimsComplete;
    bool finalAppraisalSet;
    bool harvestLossComplete;
    bool sessionOver;
    bool votesWeighted;
    bool votingActive;

    address public immutable HASHER;
    address public immutable VOTEMASK;
    address public immutable NFTADDRESS;
    address public immutable PARENTCONTRACT;
    address public immutable MULTISIG;
    address public immutable TREASURY;
    address public immutable DAO;

    uint public immutable TOKENID;

    uint amountOfClaims;
    uint amountVotesWeighted;
    uint public bounty;
    uint endTime;
    uint public finalAppraisal;
    uint harvestLossesCalled;
    uint lowestStake;
    uint maxAppraisal;
    uint timeFinalAppraisalSet;
    uint totalAppraisalValue;
    uint public totalSessionStake;
    uint public totalSessionStake_;
    uint totalWinnerPoints;
    uint totalVotes;
    uint public uniqueVoters;
    uint votingTime;
    uint weighTime;
    uint harvestTime;
    uint claimTime;

    /* ======== MAPPINGS ======== */

    mapping (address => bool) oneClaim;
    mapping (address => bool) oneHarvestLoss;
    mapping (address => bool) oneWeight;
    mapping (address => bool) voterCheck;
    mapping (address => uint) amountHarvested;
    mapping (address => uint) ethPayout;
    mapping (address => uint) winnerPoints;
    mapping (address => Voter) nftVotes;

    /* ======== EVENTS ======== */

    event newAppraisalAdded(address voter_, uint stake_, uint appraisal, uint weight);
    event finalAppraisalDetermined(uint finalAppraisal, uint amountOfParticipants, uint totalStake);
    event lossHarvestedFromUser(address user_, uint harvested);
    event ethClaimedByUser(address user_, uint ethClaimed);
    event ethToPPExchange(address user_, uint ethExchanged, uint ppSent);
    event sessionEnded(address contract_);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _dao, address _multisig, address voteMask_, address _hasher, address _treasury, 
        address _nftAddress, uint _tokenid, uint _initialAppraisal, uint _bounty, uint _votingTime) {
        TREASURY = _treasury;
        PARENTCONTRACT = msg.sender;
        NFTADDRESS = _nftAddress;
        TOKENID = _tokenid;
        HASHER = _hasher;
        VOTEMASK = voteMask_;
        MULTISIG = _multisig;
        maxAppraisal = _initialAppraisal;
        endTime = block.timestamp + _votingTime;
        lowestStake = 10000000 ether;
        votingActive = true;
        bounty = _bounty;
        DAO = _dao;
        votingTime = _votingTime;
        weighTime = _votingTime;
        harvestTime = 1 days;
        claimTime = 1 days;
    }

    /* ======== USER VOTE FUNCTIONS ======== */
    
    /// @notice Allows user to set vote in party 
    /** 
    @dev Users appraisal is hashed so users can't track final appraisal and submit vote right before session ends.
    Therefore, users must remember their appraisal in order to reveal their appraisal in the next function.
    */
    function setVote(
        bytes32 concealedBid, 
        uint a,
        uint b, 
        uint c, 
        uint d, 
        uint e
    ) checkStake oneVoteEach payable external {
        require(
            //For testnet
            IPPTreasury(TREASURY).checkWhitelist(msg.sender)
            && endTime > block.timestamp
            && IMaskVote(VOTEMASK).verifyWithinLimit(maxAppraisal, a, b, c, d, e)
            && IMaskVote(VOTEMASK).verifyTrueAppraisal(concealedBid, a, b, c, d, e, msg.sender),
            "Set vote condition not met"
        );
        if(DAO != address(0)) {
            require(IERC20(DAO).balanceOf(msg.sender) > 0);
        }
        voterCheck[msg.sender] = true;
        uint _appraisal;
        uint[5] memory valueList = [a,b,c,d,e];
        for(uint x = 0; x < valueList.length; x++) {
            if(concealedBid == keccak256(abi.encodePacked(valueList[x], msg.sender, IHasher(HASHER).getUserRandomValue(msg.sender)))) {
                _appraisal = valueList[x];
            }
        }
        if(_appraisal > maxAppraisal) {
            maxAppraisal = _appraisal;
        }
        if (msg.value < lowestStake) {
            lowestStake = msg.value;
        }
        uniqueVoters++;
        totalSessionStake = totalSessionStake.add(msg.value);
        nftVotes[msg.sender] = Voter(0, _appraisal, msg.value);
        IPricingSessionFactory(PARENTCONTRACT).updateUserSessions(msg.sender, address(this));
    }

    /// @notice Allow a user to update their vote within the voting window
    function updateMyVote(
        bytes32 concealedBid, 
        uint a,
        uint b, 
        uint c, 
        uint d, 
        uint e
    ) checkParticipation payable external {
        require(
            endTime > block.timestamp
            && IMaskVote(VOTEMASK).verifyWithinLimit(maxAppraisal, a, b, c, d, e)
            && msg.value >= nftVotes[msg.sender].stake
        );
        uint _appraisal;
        uint[5] memory valueList = [a,b,c,d,e];
        for(uint x = 0; x < valueList.length; x++) {
            if(concealedBid == keccak256(abi.encodePacked(valueList[x], msg.sender, IHasher(HASHER).getUserRandomValue(msg.sender)))) {
                _appraisal = valueList[x];
            }
        }
        if(_appraisal > maxAppraisal) {
            maxAppraisal = _appraisal;
        }
        uint oldStake = nftVotes[msg.sender].stake;
        nftVotes[msg.sender].stake = msg.value;
        nftVotes[msg.sender].appraisal = _appraisal;
        (bool sent, ) = payable(msg.sender).call{value: oldStake}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice Reveals user vote and weights based on the sessions lowest stake
    /**
    @dev calculation can be found in the weightVoteLibrary.sol file. 
    Votes are weighted as sqrt(userStake/lowestStake). Depending on a votes weight
    it is then added as multiple votes of that appraisal (i.e. if someoneone has
    voting weight of 8, 8 votes are submitted using their appraisal).
    */
    function weightVote() nonReentrant checkParticipation external {
        require(endTime < block.timestamp
                && !oneWeight[msg.sender],
                "time not over"
        );

        // require(!oneWeight[msg.sender], "time not over");

        votingActive = false;
        oneWeight[msg.sender] = true;
                
        uint weight = weightUserVote(nftVotes[msg.sender].stake, lowestStake);
        totalVotes += weight;
        
        totalAppraisalValue = totalAppraisalValue.add((weight) * nftVotes[msg.sender].appraisal);
        emit newAppraisalAdded(msg.sender, nftVotes[msg.sender].stake, nftVotes[msg.sender].appraisal, weight);
        if(amountVotesWeighted == uniqueVoters) {
            votesWeighted = true;
        }
    }
    
    /// @notice takes average of appraisals and outputs a final appraisal value.
    function setFinalAppraisal() nonReentrant checkParticipation external {
        require(
            !finalAppraisalSet
            && (block.timestamp > endTime + weighTime || votesWeighted)
        );

        IPricingSessionFactory(PARENTCONTRACT).updateNftPriced();
        votesWeighted = true;
        timeFinalAppraisalSet = block.timestamp;
        totalSessionStake += bounty;
        totalSessionStake_ = totalSessionStake;
        finalAppraisal = (totalAppraisalValue)/(totalVotes);
        finalAppraisalSet = true;
        emit finalAppraisalDetermined(finalAppraisal, uniqueVoters, totalSessionStake_);
    }

    /// @notice Calculates users base and harvests their loss before returning remaining stake
    /**
    @dev A couple notes:
    1. Tracks totalWinnerStake for calculating "in the money" users share of harvested profit
    2. Base is calculated based on margin of error.
        > +/- 5% = 1
        > +/- 4% = 2
        > +/- 3% = 3
        > +/- 2% = 4
        > +/- 1% = 5
        > Exact = 6
    3. Losses are harvested based on --> (margin of error - 5%) * stake
    */
    function harvestLoss() nonReentrant checkParticipation external {
        require(
            !harvestLossComplete
            && !oneHarvestLoss[msg.sender]
            && finalAppraisalSet
        );
        oneHarvestLoss[msg.sender] = true;
        harvestLossesCalled++;
        nftVotes[msg.sender].base = 
            calculateBase(
                finalAppraisal, 
                nftVotes[msg.sender].appraisal
            );

        if (nftVotes[msg.sender].base > 0) {
            totalWinnerPoints += nftVotes[msg.sender].base * nftVotes[msg.sender].stake;
            winnerPoints[msg.sender] = nftVotes[msg.sender].base * nftVotes[msg.sender].stake;
        }

        amountHarvested[msg.sender] = harvest( 
            nftVotes[msg.sender].stake, 
            nftVotes[msg.sender].appraisal,
            finalAppraisal
        );

        //For testnet
        IPricingSessionFactory(PARENTCONTRACT).updateUserPoints(msg.sender, winnerPoints[msg.sender], amountHarvested[msg.sender]);

        nftVotes[msg.sender].stake -= amountHarvested[msg.sender];
        uint totalCommission = setCommission(TREASURY.balance).mul(amountHarvested[msg.sender]).div(10000);
        totalSessionStake -= totalCommission; 
        IPricingSessionFactory(PARENTCONTRACT).updateProfitGenerated(amountHarvested[msg.sender]);
        uint _payout = totalCommission/2;
        payout(TREASURY, _payout);
        payout(MULTISIG, totalCommission - _payout);

        emit lossHarvestedFromUser(msg.sender, amountHarvested[msg.sender]);

        (bool sent, ) = payable(msg.sender).call{value: nftVotes[msg.sender].stake}("");
        require(sent, "Failed to send Ether");
        totalSessionStake -= nftVotes[msg.sender].stake;
        nftVotes[msg.sender].stake = 0;

        if(harvestLossesCalled == uniqueVoters) {
            harvestLossComplete = true;
        }
    }

    /// @notice Allow user to claim profit from session profit pool in ETH
    function claimProfit() checkHarvestLoss nonReentrant checkParticipation external {
        require(!oneClaim[msg.sender] && !claimsComplete);
        harvestLossComplete = true;
        oneClaim[msg.sender] = true;
        amountOfClaims++;
        ethPayout[msg.sender] = totalSessionStake * winnerPoints[msg.sender] / totalWinnerPoints;
        totalSessionStake -= ethPayout[msg.sender];
        totalWinnerPoints -= winnerPoints[msg.sender];
        winnerPoints[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: ethPayout[msg.sender]}("");
        require(sent, "Failed to send Ether");
        emit ethClaimedByUser(msg.sender, ethPayout[msg.sender]);
        if(amountOfClaims == uniqueVoters || block.timestamp > timeFinalAppraisalSet + 2 hours) {
            _executeEnd();
        }
    }

    /// @notice Allow user to enact primary purchase of PP by sending profit earned to treasury in exchange for PP
    /**
    @dev the v1 ETH to PP exchange rate will be (0.0001 ether + 0.0001 ether * parentLookup.tokensClaimed() / 1000000)
    */
    function exchangeForPP() checkHarvestLoss nonReentrant checkParticipation external {
        require(!oneClaim[msg.sender] && !claimsComplete);
        oneClaim[msg.sender] = true;
        amountOfClaims++;
        uint ppPayout = (totalSessionStake * winnerPoints[msg.sender] * 1e18 / totalWinnerPoints) / (0.0001 ether + 0.0001 ether * IPPTreasury(TREASURY).tokensClaimed() / 1000000);
        totalSessionStake -= totalSessionStake * winnerPoints[msg.sender] / totalWinnerPoints;
        (bool sent, ) = payable(MULTISIG).call{value: totalSessionStake * winnerPoints[msg.sender] / totalWinnerPoints}("");
        require(sent, "Failed to send Ether");
        totalWinnerPoints -= winnerPoints[msg.sender];
        IPricingSessionFactory(PARENTCONTRACT).sendPP(msg.sender, ppPayout);
        emit ethToPPExchange(msg.sender, ethPayout[msg.sender], ppPayout);
        if(amountOfClaims == uniqueVoters || block.timestamp > timeFinalAppraisalSet + 2 hours) {
            _executeEnd();
        }
    }
    
    /// @notice Custodial function to clear funds and remove session as child
    /// @dev Caller receives 25% of the funds that are meant to be cleared
    function endSession() checkParticipation public {
        require(!sessionOver && block.timestamp > timeFinalAppraisalSet + claimTime + harvestTime);
        _executeEnd();
    }

    /* ======== INTERNAL FUNCTIONS ======== */
    
    /// @notice Send payment to general treasury
    function payout(address recipient, uint _amount) internal {
        (bool sent, ) = payable(recipient).call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function _executeEnd() internal {
        sessionOver = true;
        claimsComplete = true;
        IPricingSessionFactory(PARENTCONTRACT).setChildState(address(this));
        uint tPayout = 75*address(this).balance/100;
        uint cPayout = address(this).balance - tPayout;
        payout(TREASURY, tPayout);
        (bool sent, ) = payable(msg.sender).call{value: cPayout}("");
        require(sent, "Failed to send Ether");
        totalSessionStake = 0;
        emit sessionEnded(address(this));
    }

    /* ======== VIEW FUNCTIONS ======== */
    
    function getMaxAppraisal() view external returns(uint){
        return maxAppraisal; 
    }

    function weightUserVote(uint stake, uint _lowestStake) pure internal returns(uint) {
        return sqrtLibrary.sqrt(stake/_lowestStake);
    }

    function getStatus() view external returns(uint) {
        if(sessionOver) {
            return 7;
        }
        else if(claimsComplete) {
            return 6;
        }
        else if(harvestLossComplete) {
            return 5;
        }
        else if(finalAppraisalSet) {
            return 4;
        }
        else if(votesWeighted){
            return 3;
        }
        else if(!votingActive){
            return 2;
        }
        else{
            return 1;
        }    
    }

    function getPpPayout() view external returns(uint) {
        return (totalSessionStake * winnerPoints[msg.sender] * 1e18 / totalWinnerPoints) / (0.0001 ether + 0.0001 ether * IPPTreasury(TREASURY).tokensClaimed() / 1000000);
    }

    function getEthPayout() view external returns(uint) {
        return totalSessionStake * winnerPoints[msg.sender] / totalWinnerPoints;
    }

    function getVotingEndTime() view external returns(uint) {
        return endTime;
    }

    function getWeightingEndTime() view external returns(uint) {
        return endTime + weighTime;
    }

    function getHarvestLossEndTime() view external returns(uint) {
        return timeFinalAppraisalSet + harvestTime;
    }

    function getClaimEndTime() view external returns(uint) {
        return timeFinalAppraisalSet + claimTime + harvestTime;
    }

    /* ======== FALLBACK FUNCTIONS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    modifier oneVoteEach {
        require(!voterCheck[msg.sender]);
        _;
    }
    
    modifier checkStake {
        require(msg.value >= 0.001 ether);
        _;
    }

    modifier checkParticipation() {
        require(voterCheck[msg.sender]);
        _;
    }

    modifier checkHarvestLoss() {
        require(harvestLossComplete || block.timestamp > timeFinalAppraisalSet + harvestTime);
        _;
    }
}


// File contracts/PricingSessionFactory.sol

pragma solidity ^0.8.0;



/// @author Medici
/// @title Factory contract for Pricing Protocol
contract PricingSessionFactory is ReentrancyGuard {

    /* ======== EVENTS ======== */

    event PricingSessionCreated(address DaoTokenContract, address creator_, address nftAddress_, uint tokenid_, uint initialAppraisal_, uint bounty_);

    /* ======== STATE VARIABLES ======== */

    address immutable public Treasury;
    address immutable HASHER;
    address immutable VOTEMASK;
    address immutable public MULTISIG;
    address[] public listOfNfts;

    uint public nftsPriced;
    uint public profitGenerated;

    /* ======== MAPPINGS ======== */
    
    mapping(address => bool) public isChild;
    mapping(address => address[]) public userSessionsParticipated;
    mapping(address => mapping(uint => address)) public currentSessionAddress;
    mapping(address => mapping(uint => address[])) public listOfNftSpecificSessions;
    mapping(address => mapping(uint => uint)) checkStartTime;

    /* ======== CONSTRUCTOR ======== */
    
    constructor(address _multisig, address voteMask_, address _hasher, address _treasury) {
        MULTISIG = _multisig;
        Treasury = _treasury;
        HASHER = _hasher;
        VOTEMASK = voteMask_;
    }

    /* ======== CREATION ======== */

    /// @notice Instantiate public pricing session 
    /// @dev Bounty is set by msg.value sent and immediately sent to child contract
    function createNewSession(
        address nftAddress, 
        uint tokenid, 
        uint initialAppraisal,
        uint votingTime,
        address DaoTokenContract
    ) stopOverwrite(nftAddress, tokenid) public payable {
        require(votingTime <= 1 days && IPPTreasury(Treasury).checkWhitelist(msg.sender));
        PricingSession session = new PricingSession(DaoTokenContract, MULTISIG, VOTEMASK, HASHER, Treasury, 
            nftAddress, tokenid, initialAppraisal, msg.value, votingTime);
        (bool sent, ) = payable(address(session)).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        currentSessionAddress[nftAddress][tokenid] = address(session);
        isChild[address(session)] = true;
        checkStartTime[nftAddress][tokenid] = block.timestamp; 
        listOfNftSpecificSessions[nftAddress][tokenid].push(address(session));
        listOfNfts.push(address(session));
        emit PricingSessionCreated(DaoTokenContract, msg.sender, nftAddress, tokenid, initialAppraisal, msg.value);
    }

    /* ======== CHILD FUNCTIONS ======== */
    
    /// @notice Allows validated child contract to update the profit generated value
    function updateProfitGenerated(
        uint _amount 
    ) isCallerChild() external {
        profitGenerated += _amount;
    }
    
    /// @notice Allows validated child contract to update the amount of NFTs that have been priced
    function updateNftPriced() isCallerChild() external {
        nftsPriced++;
    }
    
    /// @notice Allows validated child contract to update the sessions a user has participated in
    function updateUserSessions(
        address _user, 
        address _contract
    ) isCallerChild() external {
        userSessionsParticipated[_user].push(_contract);
    }

    /// @notice Allows validated child contract to remove a completed contract from child status
    function setChildState(address _contract) isCallerChild() external {
        isChild[_contract] = false;
    }

    function sendPP(address recipient, uint _amount) isCallerChild() external {
        IPPTreasury(Treasury).sendPP(recipient, _amount);
    }

    //For testnet
    function updateUserPoints(address _user, uint _amountGained, uint _amountLost) isCallerChild() external {
        IPPTreasury(Treasury).updateUserPoints(_user, _amountGained, _amountLost);
    }

    /* ======== VIEW FUNCTIONS ======== */
    
    function checkIsChild() view external returns (bool){
        return isChild[msg.sender] == true; 
    }

    /* ======== MODIFIERS ======== */

    /// @notice Creates cool down buffer between sessions for the same NFT
    modifier stopOverwrite(
        address nftAddress, 
        uint tokenid
    ) {
        require(checkStartTime[nftAddress][tokenid] + 4 days < block.timestamp);
        _;
    }
    
    /// @notice Make sure state changing calls are made from factory produced contract
    modifier isCallerChild() {
        require(isChild[msg.sender]);
        _;
    }
    
}