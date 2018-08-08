pragma solidity ^0.4.21;

// File: contracts/ISimpleCrowdsale.sol

interface ISimpleCrowdsale {
    function getSoftCap() external view returns(uint256);
    function isContributorInLists(address contributorAddress) external view returns(bool);
    function processReservationFundContribution(
        address contributor,
        uint256 tokenAmount,
        uint256 tokenBonusAmount
    ) external payable;
}

// File: contracts/fund/ICrowdsaleReservationFund.sol

/**
 * @title ICrowdsaleReservationFund
 * @dev ReservationFund methods used by crowdsale contract
 */
interface ICrowdsaleReservationFund {
    /**
     * @dev Check if contributor has transactions
     */
    function canCompleteContribution(address contributor) external returns(bool);
    /**
     * @dev Complete contribution
     * @param contributor Contributor`s address
     */
    function completeContribution(address contributor) external;
    /**
     * @dev Function accepts user`s contributed ether and amount of tokens to issue
     * @param contributor Contributor wallet address.
     * @param _tokensToIssue Token amount to issue
     * @param _bonusTokensToIssue Bonus token amount to issue
     */
    function processContribution(address contributor, uint256 _tokensToIssue, uint256 _bonusTokensToIssue) external payable;

    /**
     * @dev Function returns current user`s contributed ether amount
     */
    function contributionsOf(address contributor) external returns(uint256);

    /**
     * @dev Function is called on the end of successful crowdsale
     */
    function onCrowdsaleEnd() external;
}

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
    /**
    * @dev constructor
    */
    function SafeMath() public {
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract.
    */
    function Ownable(address _owner) public {
        owner = _owner == address(0) ? msg.sender : _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
    * @dev confirm ownership by a new owner
    */
    function confirmOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

// File: contracts/ReservationFund.sol

contract ReservationFund is ICrowdsaleReservationFund, Ownable, SafeMath {
    bool public crowdsaleFinished = false;

    mapping(address => uint256) contributions;
    mapping(address => uint256) tokensToIssue;
    mapping(address => uint256) bonusTokensToIssue;

    ISimpleCrowdsale public crowdsale;

    event RefundPayment(address contributor, uint256 etherAmount);
    event TransferToFund(address contributor, uint256 etherAmount);
    event FinishCrowdsale();

    function ReservationFund(address _owner) public Ownable(_owner) {
    }

    modifier onlyCrowdsale() {
        require(msg.sender == address(crowdsale));
        _;
    }

    function setCrowdsaleAddress(address crowdsaleAddress) public onlyOwner {
        require(crowdsale == address(0));
        crowdsale = ISimpleCrowdsale(crowdsaleAddress);
    }

    function contributionsOf(address contributor) external returns(uint256) {
        return contributions[contributor];
    }

    /**
     * @dev Process crowdsale contribution without whitelist
     */
    function processContribution(
        address contributor,
        uint256 _tokensToIssue,
        uint256 _bonusTokensToIssue
    ) external payable onlyCrowdsale {
        contributions[contributor] = safeAdd(contributions[contributor], msg.value);
        tokensToIssue[contributor] = safeAdd(tokensToIssue[contributor], _tokensToIssue);
        bonusTokensToIssue[contributor] = safeAdd(bonusTokensToIssue[contributor], _bonusTokensToIssue);
    }

    function canCompleteContribution(address contributor) external returns(bool) {
        if(crowdsaleFinished) {
            return false;
        }
        if(!crowdsale.isContributorInLists(contributor)) {
            return false;
        }
        if(contributions[contributor] == 0) {
            return false;
        }
        return true;
    }

    function completeContribution(address contributor) external {
        require(!crowdsaleFinished);
        require(crowdsale.isContributorInLists(contributor));
        require(contributions[contributor] > 0);

        uint256 etherAmount = contributions[contributor];
        uint256 tokenAmount = tokensToIssue[contributor];
        uint256 tokenBonusAmount = bonusTokensToIssue[contributor];

        contributions[contributor] = 0;
        tokensToIssue[contributor] = 0;
        bonusTokensToIssue[contributor] = 0;

        crowdsale.processReservationFundContribution.value(etherAmount)(contributor, tokenAmount, tokenBonusAmount);
        TransferToFund(contributor, etherAmount);
    }

    function onCrowdsaleEnd() external {
        crowdsaleFinished = true;
        FinishCrowdsale();
    }

    function refundPayment(address contributor) public {
        require(crowdsaleFinished);
        require(contributions[contributor] > 0 || tokensToIssue[contributor] > 0);
        uint256 amountToRefund = contributions[contributor];

        contributions[contributor] = 0;
        tokensToIssue[contributor] = 0;
        bonusTokensToIssue[contributor] = 0;

        contributor.transfer(amountToRefund);
        RefundPayment(contributor, amountToRefund);
    }
}