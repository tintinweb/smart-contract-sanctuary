pragma solidity 0.4.24;

contract ERC20TokenInterface {

    function totalSupply () external constant returns (uint);
    function balanceOf (address tokenOwner) external constant returns (uint balance);
    function transfer (address to, uint tokens) external returns (bool success);
    function transferFrom (address from, address to, uint tokens) external returns (bool success);

}

/**
 * Math operations with safety checks that throw on overflows.
 */
library SafeMath {

    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div (uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

}

/**
 * DreamTeam tokens vesting contract. 
 *
 * According to the DreamTeam token distribution structure, there are two parties that should
 * be provided with corresponding token amounts during the 2 years after TGE:
 *      Teams and Tournament Organizers: 15%
 *      Team and Early Investors: 10%
 *
 * The DreamTeam "Vesting" smart contract should be in place to ensure meeting the token sale commitments.
 *
 * Two instances of the contract will be deployed for holding tokens. 
 * First instance for "Teams and Tournament Organizers" tokens and second for "Team and Early Investors".
 */
contract OneYearDreamTokensVesting {

    using SafeMath for uint256;

    /**
     * Address of DreamToken.
     */
    ERC20TokenInterface public dreamToken;

    /**
     * Address for receiving tokens.
     */
    address public withdrawAddress;

    /**
     * Tokens vesting stage structure with vesting date and tokens allowed to unlock.
     */
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

    /**
     * Array for storing all vesting stages with structure defined above.
     */
    VestingStage[2] public stages;

    /**
     * Total amount of tokens sent.
     */
    uint256 public initialTokensBalance;

    /**
     * Amount of tokens already sent.
     */
    uint256 public tokensSent;

    /**
     * Unix timestamp at when the vesting has begin. See getVestingStageAttributes(0) attributes for vesting
     * stages info.
     */
    uint256 public vestingStartUnixTimestamp;

    /**
     * Account that deployed this smart contract, which is authorized to initialize vesting.
     */
    address public deployer;

    modifier deployerOnly { require(msg.sender == deployer); _; }

    /**
     * Event raised on each successful withdraw.
     */
    event Withdraw(uint256 amount, uint256 timestamp);

    /**
     * Dedicate vesting smart contract for a particular token during deployment.
     * @param token Address of DreamToken that will be locked on contract.
     */
    constructor (ERC20TokenInterface token) public {
        dreamToken = token;
        deployer = msg.sender;
    }

    /**
     * Fallback: function that releases locked tokens within schedule. Send an empty transaction to this
     * smart contract to receive tokens.
     */
    function () external {
        withdrawTokens();
    }

    /**
     * Vesting initialization function. Contract deployer has to trigger this function after vesting amount
     * was sent to this smart contract.
     * @param account Account to initialize vesting for.
     */
    function initializeVestingFor (address account) external deployerOnly {
        initialTokensBalance = dreamToken.balanceOf(this);
        if (initialTokensBalance == 0) {
            revert();
        }
        withdrawAddress = account;
        vestingStartUnixTimestamp = block.timestamp;
        vestingRules();
        deployer = 0x0;
    }

    /**
     * Calculate tokens amount that is sent to withdrawAddress.
     * @return Amount of tokens that can be sent.
     */
    function getAvailableTokensToWithdraw () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();
        // withdrawAddress will only be able to get all additional tokens sent to this smart contract
        // at the end of the vesting period
        if (tokensUnlockedPercentage >= 100) {
            tokensToSend = dreamToken.balanceOf(this);
        } else {
            tokensToSend = getTokensAmountAllowedToWithdraw(tokensUnlockedPercentage);
        }
    }

    /**
     * Get detailed info about stage. 
     * Provides ability to get attributes of every stage from external callers, ie Web3, truffle tests, etc.
     * @param index Vesting stage number. Ordered by ascending date and starting from zero.
     * @return {
     *    "date": "Date of stage in unix timestamp format.",
     *    "tokensUnlockedPercentage": "Percent of tokens allowed to be withdrawn."
     * }
     */
    function getVestingStageAttributes (uint8 index) public view returns (
        uint256 date, uint256 tokensUnlockedPercentage
    ) {
        return (stages[index].date, stages[index].tokensUnlockedPercentage);
    }

    /**
     * Setup array with vesting stages dates and percents.
     */
    function vestingRules () internal {

        uint256 halfOfYear = 183 days;
        uint256 year = halfOfYear * 2;

        stages[0].date = vestingStartUnixTimestamp + halfOfYear;
        stages[1].date = vestingStartUnixTimestamp + year;

        stages[0].tokensUnlockedPercentage = 50;
        stages[1].tokensUnlockedPercentage = 100;

    }

    /**
     * Main method for tokens withdrawal from the vesting smart contract. Triggered from the fallback function.
     */
    function withdrawTokens () private {
        uint256 tokensToSend = getAvailableTokensToWithdraw();
        sendTokens(tokensToSend);
    }

    /**
     * Send tokens to withdrawAddress.
     * @param tokensToSend Amount of tokens will be sent.
     */
    function sendTokens (uint256 tokensToSend) private {
        if (tokensToSend == 0) {
            return;
        }
        tokensSent = tokensSent.add(tokensToSend); // Update tokensSent variable to send correct amount later
        dreamToken.transfer(withdrawAddress, tokensToSend); // Send allowed number of tokens
        emit Withdraw(tokensToSend, now); // Emitting a notification that tokens were withdrawn
    }

    /**
     * Calculate tokens available for withdrawal.
     * @param tokensUnlockedPercentage Percent of tokens that are allowed to be sent.
     * @return Amount of tokens that can be sent according to provided percentage.
     */
    function getTokensAmountAllowedToWithdraw (uint256 tokensUnlockedPercentage) private view returns (uint256) {
        uint256 totalTokensAllowedToWithdraw = initialTokensBalance.mul(tokensUnlockedPercentage).div(100);
        uint256 unsentTokensAmount = totalTokensAllowedToWithdraw.sub(tokensSent);
        return unsentTokensAmount;
    }

    /**
     * Get tokens unlocked percentage on current stage.
     * @return Percent of tokens allowed to be sent.
     */
    function getTokensUnlockedPercentage () private view returns (uint256) {

        uint256 allowedPercent;
        
        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }
        
        return allowedPercent;

    }

}

contract OneYearDreamTokensVestingTest is OneYearDreamTokensVesting {

    constructor (ERC20TokenInterface token) OneYearDreamTokensVesting(token) public {}

    function vestingRules () internal {

        uint256 halfOfYear = 15 minutes;
        uint256 year = halfOfYear * 2;

        stages[0].date = vestingStartUnixTimestamp + halfOfYear;
        stages[1].date = vestingStartUnixTimestamp + year;

        stages[0].tokensUnlockedPercentage = 50;
        stages[1].tokensUnlockedPercentage = 100;

    }

}