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
 * DreamTeam tokens vesting smart contract. 
 * This vesting smart contracts unlocks 50% of the tokens for `withdrawalAddress` on December 25, 2018.
 * Other 50% are unlocked on 30 June, 2019.
 * The withdrawal address is set during the initialization (initializeVestingFor function).
 * To withdraw tokens, send an empty transaction to this smart contract address (just like you send Ether, but set
 * amount to transfer to 0 instead).
 * Once vesting period (1 year) ends and after all DREAM tokens are withdrawn, this smart contract self-destructs.
 */
contract OneYearDreamTokensVestingAdvisors {

    using SafeMath for uint256;

    /**
     * Address of DREAM token.
     */
    ERC20TokenInterface public dreamToken;

    /**
     * Address which will receive tokens. This address is set during initialization.
     */
    address public withdrawalAddress = 0x0;

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
     * Total amount of tokens to send.
     */
    uint256 public initialTokensBalance;

    /**
     * Amount of tokens already sent.
     */
    uint256 public tokensSent;

    /**
     * Account that deployed this smart contract, which is authorized to initialize vesting.
     */
    address public deployer;

    modifier deployerOnly { require(msg.sender == deployer); _; }
    modifier whenInitialized { require(withdrawalAddress != 0x0); _; }
    modifier whenNotInitialized { require(withdrawalAddress == 0x0); _; }

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
     * smart contract for withdrawalAddress to receive tokens.
     */
    function () external {
        withdrawTokens();
    }

    /**
     * Vesting initialization function. Contract deployer has to trigger this function after vesting amount
     * was sent to this smart contract.
     * @param account Account to initialize vesting for.
     */
    function initializeVestingFor (address account) external deployerOnly whenNotInitialized {
        initialTokensBalance = dreamToken.balanceOf(this);
        require(initialTokensBalance != 0);
        withdrawalAddress = account;
        vestingRules();
    }

    /**
     * Calculate tokens amount that is sent to withdrawalAddress.
     * @return Amount of tokens that can be sent.
     */
    function getAvailableTokensToWithdraw () public view returns (uint256) {
        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();
        // withdrawalAddress will only be able to get all additional tokens sent to this smart contract
        // at the end of the vesting period
        if (tokensUnlockedPercentage >= 100) {
            return dreamToken.balanceOf(this);
        } else {
            return getTokensAmountAllowedToWithdraw(tokensUnlockedPercentage);
        }
    }

    /**
     * Setup array with vesting stages dates and percentages.
     */
    function vestingRules () internal {

        stages[0].date = 1545696000; // December 25, 2018
        stages[1].date = 1561852800; // June 30, 2018

        stages[0].tokensUnlockedPercentage = 50;
        stages[1].tokensUnlockedPercentage = 100;

    }

    /**
     * Function for tokens withdrawal from the vesting smart contract. Triggered from the fallback function.
     */
    function withdrawTokens () private whenInitialized {
        uint256 tokensToSend = getAvailableTokensToWithdraw();
        sendTokens(tokensToSend);
        if (dreamToken.balanceOf(this) == 0) { // When all tokens were sent, destroy this smart contract
            selfdestruct(withdrawalAddress);
        }
    }

    /**
     * Send tokens to withdrawalAddress.
     * @param tokensToSend Amount of tokens will be sent.
     */
    function sendTokens (uint256 tokensToSend) private {
        if (tokensToSend == 0) {
            return;
        }
        tokensSent = tokensSent.add(tokensToSend); // Update tokensSent variable to send correct amount later
        dreamToken.transfer(withdrawalAddress, tokensToSend); // Send allowed number of tokens
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