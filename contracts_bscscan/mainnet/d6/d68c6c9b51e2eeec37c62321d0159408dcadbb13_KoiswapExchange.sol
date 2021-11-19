/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
        address from,
        address to,
        uint256 value
    ) external returns (bool ok);
}

// Contract for purchase token from presale token
contract KoiswapExchange {
    using SafeMath for uint256;

    IBEP20 public TOKEN;
    IBEP20 public PRETOKEN;
    
    address payable public owner;

    uint256 public startDate = 1633222800;                
        
    uint256 public totalTokensToSell = 10000000 * 10**18;      // 10000000 tokens for sell
    uint256 public tokenPerPRE = 1 * 10**12;                // 1.000.000 PRE = 1 TOKEN
    uint256 public minPerTransaction = 0;                   // min amount per transaction
    uint256 public maxPerUser = 500000000000 * 10**18;       // 500 bil max amount per user
    uint256 public totalSold;

    bool public saleEnded;
    
    mapping(address => uint256) public tokenPerAddresses;

    event tokensBought(address indexed user, uint256 amountSpent, uint256 amountBought, string tokenName, uint256 date);
    event tokensClaimed(address indexed user, uint256 amount, uint256 date);

    modifier checkSaleRequirements(uint256 buyAmount) {
        require(now >= startDate, 'Presale time passed');
        require(saleEnded == false, 'Sale ended');
        require(
            buyAmount > minPerTransaction && buyAmount <= unsoldTokens(),
            'Insufficient buy amount'
        );
        _;
    }

    constructor(
        address _TOKEN,
        address _PRETOKEN   
    ) public {
        owner = msg.sender;
        TOKEN = IBEP20(_TOKEN);
        PRETOKEN = IBEP20(_PRETOKEN);
    }

    // Function to buy TOKEN using PRE token
    function buyWithPRE(uint256 buyAmount) public checkSaleRequirements(buyAmount) {
        uint256 amount = calculatePREAmount(buyAmount);
        require(PRETOKEN.balanceOf(msg.sender) >= amount, "Insufficient balance");

        uint256 sumSoFar = tokenPerAddresses[msg.sender].add(buyAmount);
        require(sumSoFar <= maxPerUser, 'Greater than the maximum purchase limit');

        tokenPerAddresses[msg.sender] = sumSoFar;
        totalSold = totalSold.add(buyAmount);
        
        PRETOKEN.transferFrom(msg.sender, address(this), amount);
        TOKEN.transfer(msg.sender, buyAmount);
        emit tokensBought(msg.sender, amount, buyAmount, 'PRE', now);
    }

    //function to change the owner
    //only owner can call this function
    function changeOwner(address payable _owner) public {
        require(msg.sender == owner, "Only owner allowed");
        owner = _owner;
    }

    // function to set the presale start date
    // only owner can call this function
    function setStartDate(uint256 _startDate) public {
        require(msg.sender == owner && saleEnded == false);
        startDate = _startDate;
    }

    // function to set the total tokens to sell
    // only owner can call this function
    function setTotalTokensToSell(uint256 _totalTokensToSell) public {
        require(msg.sender == owner, "Only owner allowed");
        totalTokensToSell = _totalTokensToSell;
    }

    // function to set the minimal transaction amount
    // only owner can call this function
    function setMinPerTransaction(uint256 _minPerTransaction) public {
        require(msg.sender == owner, "Only owner allowed");
        minPerTransaction = _minPerTransaction;
    }

    // function to set the maximum amount which a user can buy
    // only owner can call this function
    function setMaxPerUser(uint256 _maxPerUser) public {
        require(msg.sender == owner, "Only owner allowed");
        maxPerUser = _maxPerUser;
    }

    // function to set the total tokens to sell
    // only owner can call this function
    function setTokenPricePerPRE(uint256 _tokenPerPRE) public {
        require(msg.sender == owner, "Only owner allowed");
        require(_tokenPerPRE > 0, "Invalid TOKEN price per PRETOKEN");
        tokenPerPRE = _tokenPerPRE;
    }

    //function to end the sale
    //only owner can call this function
    function endSale() public {
        require(msg.sender == owner && saleEnded == false);
        saleEnded = true;
    }

    //function to withdraw collected pre tokens by sale.
    //only owner can call this function
    function withdrawCollectedPreTokens() public {
        require(msg.sender == owner, "Only owner allowed");
        uint256 collectedPreAmount = PRETOKEN.balanceOf(address(this));
        require(collectedPreAmount > 0, "Insufficient balance");
        PRETOKEN.transfer(owner, collectedPreAmount);
    }

    //function to withdraw remained tokens
    //only owner can call this function
    function withdrawRemainedTokens() public {
        require(msg.sender == owner, "Only owner allowed");
        uint256 remainedTokens = unsoldTokens();
        require(remainedTokens > 0, "No remained tokens");
        TOKEN.transfer(owner, remainedTokens);
    }

    //function to return the amount of unsold tokens
    function unsoldTokens() public view returns (uint256) {
        // return totalTokensToSell.sub(totalSold);
        return TOKEN.balanceOf(address(this));
    }

    //function to calculate the quantity of TOKEN based on the TOKEN price of preAmount
    function calculateTokenAmount(uint256 preAmount) public view returns (uint256) {
        uint256 tokenAmount = tokenPerPRE.mul(preAmount).div(10**18);
        return tokenAmount;
    }

    //function to calculate the quantity of pretoken needed using its TOKEN price to buy `buyAmount` of TOKEN
    function calculatePREAmount(uint256 tokenAmount) public view returns (uint256) {
        require(tokenPerPRE > 0, "TOKEN price per PRE should be greater than 0");
        uint256 preAmount = tokenAmount.mul(10**8).div(tokenPerPRE);
        return preAmount;
    }
}