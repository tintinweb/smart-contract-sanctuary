// extract logic into private functions and call those with public functions
//eth alarm clock
//x dai
//chainlink
// super fluid for incremental payments
// 

pragma solidity >=0.4.22 <0.8.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


// SPDX-License-Identifier: PRIVATE


contract Famepay is ReentrancyGuard {
    using SafeMath for uint256;
    
    address payable public influencer;
    address payable public business;
    address constant  platform = 0xD77F59412898F48353570f196aaa23B42DE6E16D;  //payable?<--

    uint256 public incrementalPayment;
    uint256 public jackpotPayment;
    
    uint256 public startDate;
    uint256 public deadline;
    uint256 public singlePostDuration;
    
    uint256 private campaignId;
    
    uint256 public incrementalTargetAmount;
    uint256 public jackpotTargetAmount;
    // uint256 public potentialPayoutAmount;
    
    bool public jackpotTargetReached;
    bool public incrementalTargetReached;
    
    bool public businessConfirmed = false;
    bool public influencerConfirmed = false;
    

    string public objective;
    
    
    mapping(address => uint256) public depositedFor;
    uint256[] public outstandingIncrementalPayments;
    
    
    event BusinessDeposited(address indexed _business, uint256  _amount, uint256  _campaignId);
    event BusinessRefunded(address indexed _business, uint256  _amount, uint256 _campaignId);
    
    event IncrementInfluencerPayment(uint256 _amount,  uint256 _amountOfIncrementalPayments, uint256 _campaignId);
    event JackpotInfluencerPayment(uint256 _amount, uint256 _campaignId);
    event AgreedAmountPayment(address indexed _influencer, uint256 _amount, uint256 _campaignId);
    

    event InvalidWithdrawal(uint256 _amount, uint256 _campaignId);
    
    event CampaignTerminationIncrementPayment(address indexed _influencer, bool _objectiveReached, uint256 _campaignId);
    event CampaignTerminationJackpotPayment(address indexed _influencer, bool _objectiveReached, uint256 _campaignId);
    event CampaignEnding(uint256 _refundableAmount,  bool _objectiveReached, uint256 _campaignId);
    event ExtendDeadline(uint256 _newDeadline, uint256 _campaignId);
    
    modifier onlyInfluencer() {
        require(influencer == msg.sender);
        _;
    }
    
    modifier onlyBusiness() { 
        require(business == msg.sender);
        _;
    }
    
    constructor ( 
        address payable _influencer, 
        address payable _business, 
        uint256 _campaignId, 
        uint256 _startDate, 
        uint256 _deadline,
        uint256 _singlePostDuration, 
        uint256 _jackpotPayment, 
        uint256 _incrementalPayment, 
        uint256 _jackpotTargetAmount, 
        uint256 _incrementalTargetAmount, 
        // uint256 _potentialPayoutAmount,  
        string memory _objective
    ) public payable { 
            influencer = _influencer;
            business = _business;
            campaignId = _campaignId;
            startDate = _startDate;
            deadline = _deadline;
            singlePostDuration = _singlePostDuration;
            jackpotPayment = _jackpotPayment;
            incrementalPayment = _incrementalPayment;
            jackpotTargetAmount = _jackpotTargetAmount;
            incrementalTargetAmount = _incrementalTargetAmount;
            // potentialPayoutAmount = _potentialPayoutAmount;
            objective = _objective;
            depositedFor[influencer] = depositedFor[influencer] + address(this).balance;
    }
    
    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
        
    //consider removing the public!<<
    function depositPayment() public payable  {
        require(deadline > block.timestamp, "The campaign deadline has passed"); 
        require(msg.value > 0, "You must deposit money into the contract");
        depositedFor[influencer] = depositedFor[influencer] + msg.value;
        emit BusinessDeposited(msg.sender, msg.value, campaignId);
    }

    function depositedForInfluencerBalance() public view returns (uint256) {
        return depositedFor[influencer];
    }
    
    function addressBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function outstandingPayments() public  view returns (uint256) {
        return outstandingIncrementalPayments.length;
    }
    
    function confirmBusinessInfluencer(bool _confirmedBusiness, bool _confirmedInfluencer) /*onlyBusiness onlyInfluencer*/ public {
        businessConfirmed = _confirmedBusiness;
        influencerConfirmed = _confirmedInfluencer;
    }
    
    function paymentTargetReached(bool _jackpotTargetReached, bool _incrementalTargetReached) public {
        jackpotTargetReached = _jackpotTargetReached;
        if(_incrementalTargetReached && keccak256(abi.encodePacked(objective)) != keccak256(abi.encodePacked("simplePost"))) {  //review this if logic
            incrementalTargetReached = _incrementalTargetReached;
            outstandingIncrementalPayments.push(incrementalPayment);
        } else {
            incrementalTargetReached = _incrementalTargetReached;
        }
    }

    
    function payInfluencer(bool _businessConfirmed, bool _influencerConfirmed, uint256 _confirmedPaymentAmount) public payable {
        require(jackpotTargetReached || incrementalTargetReached || (_businessConfirmed && _influencerConfirmed ), "conditions for payment were not met");
        require(deadline >= block.timestamp, "the campaign period is over");
        //jackpot payment
        if (jackpotTargetReached) {
            require(depositedFor[influencer] >= jackpotPayment);
            depositedFor[influencer] -= jackpotPayment;
            influencer.transfer(jackpotPayment);
            jackpotTargetReached = false;
            emit JackpotInfluencerPayment(jackpotPayment, campaignId);
        } 

        //incremental payment
        if (incrementalTargetReached) {
            require(depositedFor[influencer] >= incrementalPayment, "the attempted payout is more than is despoited in the campaign");
            // for multiple outstanding payments
            if(outstandingIncrementalPayments.length >= 1) {
                uint256 outstandingIncrementalPayment = outstandingIncrementalPayments.length.mul(incrementalPayment);
                depositedFor[influencer] -= outstandingIncrementalPayment;
                influencer.transfer(outstandingIncrementalPayment);
                delete outstandingIncrementalPayments;
                incrementalTargetReached = false;
                emit IncrementInfluencerPayment(outstandingIncrementalPayment, outstandingIncrementalPayments.length, campaignId);
            } else {
                depositedFor[influencer] -= incrementalPayment;
                influencer.transfer(incrementalPayment);
                incrementalTargetReached = false;
                emit IncrementInfluencerPayment(incrementalPayment, outstandingIncrementalPayments.length, campaignId);
            }
        }
        
        //agreed upon sum
        if(_businessConfirmed && _influencerConfirmed) {
            require(_confirmedPaymentAmount < depositedFor[influencer]);
            influencer.transfer(_confirmedPaymentAmount);
            emit AgreedAmountPayment(influencer, _confirmedPaymentAmount, campaignId);
        } 
    }
    
    function confirmRefund(bool _businessConfirmed, bool _influencerConfirmed) public {
        businessConfirmed = _businessConfirmed;
        influencerConfirmed = _influencerConfirmed;
    }
    
    function extendDeadline(uint256 _newDeadline) public {
        require (deadline < _newDeadline);
        deadline = _newDeadline;
            emit ExtendDeadline(_newDeadline, campaignId);
    }
    
    function campaignEnded(uint256 _agreedAmount) payable public {
        // require(deadline <= block.timestamp || businessConfirmed && influencerConfirmed); //check multiple require statements
        if(jackpotTargetReached) {
            payInfluencer(businessConfirmed, influencerConfirmed, _agreedAmount);
            emit CampaignTerminationJackpotPayment(business, true, campaignId);
        }
        else if(incrementalTargetReached) {
            payInfluencer(businessConfirmed, influencerConfirmed, _agreedAmount);
            emit CampaignTerminationIncrementPayment(business,  false, campaignId);
        }
        emit CampaignEnding(depositedFor[influencer], false, campaignId);
        selfdestruct(business);
    }
    

    
    
    // function adminCancelCampaign(uint256 _agreedAmount) onlyAdmin internal {
    //     if(incrementalTargetReached) {
    //         payInfluencer(true, true, _agreedAmount);
    //         emit CampaignTerminationIncrementPayment(business, "remaining incremental payments to be paid:", depositedFor[influencer], false);
    //     }
    //     if(jackpotTargetReached) {
    //         payInfluencer(true, true, _agreedAmount);
    //         emit CampaignTerminationJackpotPayment(business, "making the remaining jackpot payment before campagin termination", true);
    //     }
    //     emit CampaignEnding("Campaign is about to be terminated. Amount to be refunded:", depositedFor[influencer], false);
    //     selfdestruct;
    // }
    
    /*
    function pause() external onlyAdmin {
        super._pause();
    }

    function unpause() external onlyAdmin {
        super._unpause();
    }
    
    
    */

}

pragma solidity >=0.4.22 <0.8.0;
import './Famepay.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// SPDX-License-Identifier: PRIVATE

contract FamepayFactory is ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public campaignPointer;
    uint256 incrementalPaymentsTillJackpotValue;
    uint256 incrementalPaymentsTillJackpotAmount;
    address private platform; //payable?<-
    mapping(uint256 => address) public famepayCampaigns;
    event NewFamepayCampaignCreated(
        address indexed _influencer,
        address indexed _business,
        address indexed _campaignAddress,
        uint256 _campaignId,
        uint256 _startDate,
        uint256 _deadline,
        uint256 _singlePostDuration,
        uint256 _jackpotPayment,
        uint256 _incrementalPayment,
        uint256 _jackpotTargetAmount,
        uint256 _incrementalTargetAmount,
        uint256 _potentialPayoutAmount,
        string _objective
    );

    constructor() public {
        platform = msg.sender;
    }
    
    function newFamepayCampaign(
        address payable _business,
        address payable _influencer,
        uint256 _startDate,
        uint256 _deadline,
        uint256 _singlePostDuration,
        uint256 _jackpotPayment, //$1000 if we hit 1,000,000 views
        uint256 _incrementalPayment, //$50 for every 50,000 views    //0 for simple post
        uint256 _jackpotTargetAmount,
        uint256 _incrementalTargetAmount, //1 for simple post
        uint256 _potentialPayoutAmount, //total in contract $2000
        string memory _objective
    ) payable public {
        if(keccak256(abi.encodePacked(_objective)) != keccak256(abi.encodePacked("simplePost"))) {  //review this if logic
            incrementalPaymentsTillJackpotAmount = _jackpotTargetAmount.div(_incrementalTargetAmount);
            incrementalPaymentsTillJackpotValue = _incrementalPayment.mul(incrementalPaymentsTillJackpotAmount);
            require(_potentialPayoutAmount > _jackpotPayment.add(incrementalPaymentsTillJackpotValue), "Potential payout is invalid");
            // require(_potentialPayoutAmount > _jackpotPayment.add(_incrementalPayment.mul(_jackpotTargetAmount.div(_incrementalTargetAmount))));
        } else {
            require(_potentialPayoutAmount >= _jackpotPayment);
        }
        campaignPointer = campaignPointer.add(1);
        uint256 campaignId = campaignPointer;
        Famepay famepay = new Famepay{value: msg.value}(_influencer, _business, campaignId, _startDate, _deadline, _singlePostDuration, _jackpotPayment, _incrementalPayment, _jackpotTargetAmount, _incrementalTargetAmount,/* _potentialPayoutAmount,*/ _objective) ;
        famepayCampaigns[campaignId] = address(famepay);
        emit NewFamepayCampaignCreated(_influencer, _business, address(famepay), campaignId, _startDate, _deadline, _singlePostDuration, _jackpotPayment, _incrementalPayment, _jackpotTargetAmount, _incrementalTargetAmount, _potentialPayoutAmount, _objective);
    }

    function getCampaign(uint256 _campaignId) view public returns (address) {
         return famepayCampaigns[_campaignId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

