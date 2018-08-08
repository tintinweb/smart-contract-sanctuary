pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
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
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SelfllerySaleFoundation is Ownable {
    using SafeMath for uint;

    // Amount of Ether paid from each address
    mapping (address => uint) public paidEther;
    // Pre-sale participant tokens for each address
    mapping (address => uint) public preSaleParticipantTokens;
    // Number of tokens was sent during the ICO for each address
    mapping (address => uint) public sentTokens;

    // SELFLLERY PTE LTD (manager wallet)
    address public selflleryManagerWallet;
    // The token contract used for this ICO
    ERC20 public token;
    // Number of cents for 1 YOU
    uint public tokenCents;
    // The token price from 1 wei
    uint public tokenPriceWei;
    // Number of tokens in cents for sale
    uint public saleTokensCents;

    // The amount purchased tokens at the moment
    uint public currentCapTokens;
    // The amount of Ether raised at the moment
    uint public currentCapEther;
    // Start date of the ICO
    uint public startDate;
    // End date of bonus time
    uint public bonusEndDate;
    // End date of the ICO
    uint public endDate;
    // Hard cap of tokens
    uint public hardCapTokens;
    // The minimum purchase for user
    uint public minimumPurchaseAmount;
    // The bonus percent for purchase first 48 hours
    uint8 public bonusPercent;

    event PreSalePurchase(address indexed purchasedBy, uint amountTokens);

    event Purchase(address indexed purchasedBy, uint amountTokens, uint etherWei);

    /**
    * @dev Throws if date isn&#39;t between ICO dates.
    */
    modifier onlyDuringICODates() {
        require(now >= startDate && now <= endDate);
        _;
    }

    /**
     * @dev Initialize the ICO contract
    */
    function SelfllerySaleFoundation(
        address _token,
        address _selflleryManagerWallet,
        uint _tokenCents,
        uint _tokenPriceWei,
        uint _saleTokensCents,
        uint _startDate,
        uint _bonusEndDate,
        uint _endDate,
        uint _hardCapTokens,
        uint _minimumPurchaseAmount,
        uint8 _bonusPercent
    )
        public
        Ownable()
    {
        token = ERC20(_token);
        selflleryManagerWallet = _selflleryManagerWallet;
        tokenCents = _tokenCents;
        tokenPriceWei = _tokenPriceWei;
        saleTokensCents = _saleTokensCents;
        startDate = _startDate;
        bonusEndDate = _bonusEndDate;
        endDate = _endDate;
        hardCapTokens = _hardCapTokens;
        minimumPurchaseAmount = _minimumPurchaseAmount;
        bonusPercent = _bonusPercent;
    }

    /**
     * @dev Purchase tokens for the amount of ether sent to this contract
     */
    function () public payable {
        purchase();
    }

    /**
     * @dev Purchase tokens for the amount of ether sent to this contract
     * @return A boolean that indicates if the operation was successful.
     */
    function purchase() public payable returns(bool) {
        return purchaseFor(msg.sender);
    }

    /**
     * @dev Purchase tokens for the amount of ether sent to this contract for custom address
     * @param _participant The address of the participant
     * @return A boolean that indicates if the operation was successful.
     */
    function purchaseFor(address _participant) public payable onlyDuringICODates() returns(bool) {
        require(_participant != 0x0);
        require(paidEther[_participant].add(msg.value) >= minimumPurchaseAmount);

        selflleryManagerWallet.transfer(msg.value);

        uint currentBonusPercent = getCurrentBonusPercent();
        uint totalTokens = calcTotalTokens(msg.value, currentBonusPercent);
        require(currentCapTokens.add(totalTokens) <= saleTokensCents);
        require(token.transferFrom(owner, _participant, totalTokens));
        sentTokens[_participant] = sentTokens[_participant].add(totalTokens);
        currentCapTokens = currentCapTokens.add(totalTokens);
        currentCapEther = currentCapEther.add(msg.value);
        paidEther[_participant] = paidEther[_participant].add(msg.value);
        Purchase(_participant, totalTokens, msg.value);

        return true;
    }

    /**
     * @dev Change minimum purchase amount any time only owner
     * @param _newMinimumPurchaseAmount New minimum puchase amount
     * @return A boolean that indicates if the operation was successful.
     */
    function changeMinimumPurchaseAmount(uint _newMinimumPurchaseAmount) public onlyOwner returns(bool) {
        require(_newMinimumPurchaseAmount >= 0);
        minimumPurchaseAmount = _newMinimumPurchaseAmount;
        return true;
    }

    /**
     * @dev Add pre-sale purchased tokens only owner
     * @param _participant The address of the participant
     * @param _totalTokens Total tokens amount for pre-sale participant
     * @return A boolean that indicates if the operation was successful.
     */
    function addPreSalePurchaseTokens(address _participant, uint _totalTokens) public onlyOwner returns(bool) {
        require(_participant != 0x0);
        require(_totalTokens > 0);
        require(currentCapTokens.add(_totalTokens) <= saleTokensCents);

        require(token.transferFrom(owner, _participant, _totalTokens));
        sentTokens[_participant] = sentTokens[_participant].add(_totalTokens);
        preSaleParticipantTokens[_participant] = preSaleParticipantTokens[_participant].add(_totalTokens);
        currentCapTokens = currentCapTokens.add(_totalTokens);
        PreSalePurchase(_participant, _totalTokens);
        return true;
    }

    /**
     * @dev Is finish date ICO reached?
     * @return A boolean that indicates if finish date ICO reached.
     */
    function isFinishDateReached() public constant returns(bool) {
        return endDate <= now;
    }

    /**
     * @dev Is hard cap tokens reached?
     * @return A boolean that indicates if hard cap tokens reached.
     */
    function isHardCapTokensReached() public constant returns(bool) {
        return hardCapTokens <= currentCapTokens;
    }

    /**
     * @dev Is ICO Finished?
     * @return A boolean that indicates if ICO finished.
     */
    function isIcoFinished() public constant returns(bool) {
        return isFinishDateReached() || isHardCapTokensReached();
    }

    /**
     * @dev Calc total tokens for fixed value and bonus percent
     * @param _value Amount of ether
     * @param _bonusPercent Bonus percent
     * @return uint
     */
    function calcTotalTokens(uint _value, uint _bonusPercent) internal view returns(uint) {
        uint tokensAmount = _value.mul(tokenCents).div(tokenPriceWei);
        require(tokensAmount > 0);
        uint bonusTokens = tokensAmount.mul(_bonusPercent).div(100);
        uint totalTokens = tokensAmount.add(bonusTokens);
        return totalTokens;
    }

    /**
     * @dev Get current bonus percent for this transaction
     * @return uint
     */
    function getCurrentBonusPercent() internal constant returns (uint) {
        uint currentBonusPercent;
        if (now <= bonusEndDate) {
            currentBonusPercent = bonusPercent;
        } else {
            currentBonusPercent = 0;
        }
        return currentBonusPercent;
    }
}

contract SelfllerySale is SelfllerySaleFoundation {
    address constant TOKEN_ADDRESS = 0x7e921CA9b78d9A6cCC39891BA545836365525C06; // Token YOU
    address constant SELFLLERY_MANAGER_WALLET = 0xdABb398298192192e5d4Ed2f120Ff7Af312B06eb;// SELFLLERY PTE LTD
    uint constant TOKEN_CENTS = 1e18;
    uint constant TOKEN_PRICE_WEI = 1e15;
    uint constant SALE_TOKENS_CENTS = 55000000 * TOKEN_CENTS;
    uint constant SALE_HARD_CAP_TOKENS = 55000000 * TOKEN_CENTS;

    uint8 constant BONUS_PERCENT = 5;
    uint constant MINIMUM_PURCHASE_AMOUNT = 0.1 ether;

    uint constant SALE_START_DATE = 1520240400; // 05.03.2018 9:00 UTC
    uint constant SALE_BONUS_END_DATE = 1520413200; // 07.03.2018 9:00 UTC
    uint constant SALE_END_DATE = 1522144800; // 27.03.2018 10:00 UTC

    /**
     * @dev Initialize the ICO contract
    */
    function SelfllerySale()
        public
        SelfllerySaleFoundation(
            TOKEN_ADDRESS,
            SELFLLERY_MANAGER_WALLET,
            TOKEN_CENTS,
            TOKEN_PRICE_WEI,
            SALE_TOKENS_CENTS,
            SALE_START_DATE,
            SALE_BONUS_END_DATE,
            SALE_END_DATE,
            SALE_HARD_CAP_TOKENS,
            MINIMUM_PURCHASE_AMOUNT,
            BONUS_PERCENT
        ) {}
}