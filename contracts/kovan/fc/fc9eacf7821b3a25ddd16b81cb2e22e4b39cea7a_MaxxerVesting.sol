/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

pragma solidity ^0.5.3;

/**
* @title ERC223Interface
* @dev ERC223 Contract Interface
*/
contract ERC223Interface {
    function balanceOf(address who)public view returns (uint);
    function transfer(address to, uint value)public returns (bool success);
    function transfer(address to, uint value, bytes memory data)public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
}

/// @title Interface for the contract that will work with ERC223 tokens.
interface ERC223ReceivingContract { 
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction data.
     */
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

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
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

contract MaxxerVesting is ERC223ReceivingContract {
    using SafeMath for uint256;

    /**
     * Address of MaxxerToken.
     */
    address public maxxerToken;

    /**
     * Founder receiving wallet address.
     */
    address public FOUNDERS_ADDRESS;

    /**
     * Advisors receiving wallet address.
     */
    address public ADVISORS_ADDRESS;

    /**
     * Team receiving wallet address.
     */
    address public TEAM_ADDRESS;

    /**
     * Totle Amount of token for Founder.
     */
    uint256 public FOUNDERS_TOTALE_TOKEN = 120000000 * 10**18;

    /**
     * Totle Amount of token for Advisors.
     */
    uint256 public ADVISORS_TOTALE_TOKEN = 16000000 * 10**18;

    /**
     * Totle Amount of token for Team.
     */
    uint256 public TEAM_TOTALE_TOKEN = 24000000 * 10**18;

    /**
     * Amount of tokens already sent on Founder receiving wallet.
     */
    uint256 public FOUNDERS_TOKEN_SENT;

    /**
     * Amount of tokens already sent on Advisors receiving wallet.
     */
    uint256 public ADVISORS_TOKEN_SENT;

    /**
     * Amount of tokens already sent on Team receiving wallet.
     */
    uint256 public TEAM_TOKEN_SENT;

    /**
     * Starting timestamp of the first stage of vesting (Monday, October 18, 2021 1:16:59 PM).
     * Will be used as a starting point for all dates calculations.
     */
    uint256 public VESTING_START_TIMESTAMP;

    /**
     * Tokens vesting stage structure with vesting date and tokens allowed to unlock.
     */
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
        uint256 foundersTokensUnlocked;
        uint256 advisorsTokensUnlocked;
        uint256 teamTokensUnlocked;
    }
    /**
     * Array for storing all vesting stages with structure defined above.
     */
    VestingStage[36] public stages;

    event Withdraw(address _to, uint256 _value);

    
    constructor (address _maxxerToken,uint256 _vestingStartTimestamp, address _foundersAddress,address _advisorsAddress,address _teamAddress) public {
        maxxerToken = _maxxerToken;
        VESTING_START_TIMESTAMP=_vestingStartTimestamp;
        FOUNDERS_ADDRESS=_foundersAddress;
        ADVISORS_ADDRESS=_advisorsAddress;
        TEAM_ADDRESS=_teamAddress;
        initVestingStages();
    }

    /**
     * Setup array with vesting stages dates and token amounts.
     */
    function initVestingStages () internal {
        uint256 month = 2 minutes;

        // assert(1 seconds == 1);
        // assert(1 minutes == 60 seconds);    
        // assert(1 hours == 60 minutes);
        // assert(1 day == 24 hours);
        // assert(1 week == 7 days);

        stages[0].date = VESTING_START_TIMESTAMP;
        stages[0].foundersTokensUnlocked = 3333345 * 10**18;
        stages[0].advisorsTokensUnlocked = 444460 * 10**18;
        stages[0].teamTokensUnlocked = 666690 * 10**18;

        for (uint8 i = 1; i < 36; i++) {
                stages[i].date = stages[i-1].date + month;
                stages[i].foundersTokensUnlocked = stages[i-1].foundersTokensUnlocked.add(3333333 * 10**18);
                stages[i].advisorsTokensUnlocked = stages[i-1].advisorsTokensUnlocked.add(444444 * 10**18);
                stages[i].teamTokensUnlocked = stages[i-1].teamTokensUnlocked.add(666666 * 10**18);
        }
    }
    
    function tokenFallback(address, uint _value, bytes calldata) external {
        require(msg.sender == maxxerToken);
        uint256 TOTAL_TOKENS = FOUNDERS_TOTALE_TOKEN.add(ADVISORS_TOTALE_TOKEN).add(TEAM_TOTALE_TOKEN);
        require(_value == TOTAL_TOKENS);
    }

    /**
     * Method for Founders withdraw tokens from vesting.
     */
    function withdrawFoundersToken () public {
        uint256 tokensToSend = getAvailableTokensOfFounders();
        sendTokens(FOUNDERS_ADDRESS,tokensToSend);
    }

    /**
     * Method for Advisors withdraw tokens from vesting.
     */
    function withdrawAdvisorsToken () public {
        uint256 tokensToSend = getAvailableTokensOfAdvisors();
        sendTokens(ADVISORS_ADDRESS,tokensToSend);
    }

    /**
     * Method for Team withdraw tokens from vesting.
     */
    function withdrawTeamToken () public {
        uint256 tokensToSend = getAvailableTokensOfTeam();
        sendTokens(TEAM_ADDRESS,tokensToSend);
    }

    /**
     * Calculate tokens amount that is sent to Founder wallet Address.
     * 
     * @return Amount of tokens that can be sent.
     */
    function getAvailableTokensOfFounders () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlocked = getTokensUnlocked(FOUNDERS_ADDRESS);
        tokensToSend = getTokensAmountAllowedToWithdraw(FOUNDERS_ADDRESS,tokensUnlocked);
    }

    /**
     * Calculate tokens amount that is sent to Advisor wallet Address.
     * 
     * @return Amount of tokens that can be sent.
     */
    function getAvailableTokensOfAdvisors () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlocked = getTokensUnlocked(ADVISORS_ADDRESS);
        tokensToSend = getTokensAmountAllowedToWithdraw(ADVISORS_ADDRESS,tokensUnlocked);
    }

    /**
     * Calculate tokens amount that is sent to Team wallet Address.
     * 
     * @return Amount of tokens that can be sent.
     */
    function getAvailableTokensOfTeam () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlocked = getTokensUnlocked(TEAM_ADDRESS);
        tokensToSend = getTokensAmountAllowedToWithdraw(TEAM_ADDRESS,tokensUnlocked);
    }

    /**
     * Get tokens unlocked on current stage.
     * 
     * @return Tokens allowed to be sent.
     */
    function getTokensUnlocked (address role) private view returns (uint256) {
        uint256 allowedTokens;
        
        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                if(role == FOUNDERS_ADDRESS){
                    allowedTokens = stages[i].foundersTokensUnlocked;
                } else if(role == ADVISORS_ADDRESS){
                    allowedTokens = stages[i].advisorsTokensUnlocked;
                } else if(role == TEAM_ADDRESS){
                    allowedTokens = stages[i].teamTokensUnlocked;
                }
            }
        }
        
        return allowedTokens;
    }

    /**
     * Calculate tokens available for withdrawal.
     *
     * @param role Role addres for which you want the amount of tokens.
     *
     * @param tokensUnlocked Percent of tokens that are allowed to be sent.
     *
     * @return Amount of tokens that can be sent according to provided role and tokensUnlocked.
     */
    function getTokensAmountAllowedToWithdraw (address role,uint256 tokensUnlocked) private view returns (uint256) {
        uint256 unsentTokensAmount;
        if(role == FOUNDERS_ADDRESS){
            unsentTokensAmount = tokensUnlocked.sub(FOUNDERS_TOKEN_SENT);
        } else if(role == ADVISORS_ADDRESS){
            unsentTokensAmount = tokensUnlocked.sub(ADVISORS_TOKEN_SENT);
        } else if(role == TEAM_ADDRESS){
            unsentTokensAmount = tokensUnlocked.sub(TEAM_TOKEN_SENT);
        }
        return unsentTokensAmount;
    }

    /**
     * Send tokens to given address.
     */
    function sendTokens (address role,uint256 tokensToSend) private {
        if (tokensToSend > 0) {
            if(role == FOUNDERS_ADDRESS){
                // Updating tokens sent counter
                FOUNDERS_TOKEN_SENT = FOUNDERS_TOKEN_SENT.add(tokensToSend);
                // Sending allowed tokens amount
                ERC223Interface(maxxerToken).transfer(FOUNDERS_ADDRESS, tokensToSend);
                emit Withdraw(FOUNDERS_ADDRESS,tokensToSend);
            } else if(role == ADVISORS_ADDRESS){
                // Updating tokens sent counter
                ADVISORS_TOKEN_SENT = ADVISORS_TOKEN_SENT.add(tokensToSend);
                // Sending allowed tokens amount
                ERC223Interface(maxxerToken).transfer(ADVISORS_ADDRESS, tokensToSend);
                emit Withdraw(ADVISORS_ADDRESS,tokensToSend);
            } else if(role == TEAM_ADDRESS){
                // Updating tokens sent counter
                TEAM_TOKEN_SENT = TEAM_TOKEN_SENT.add(tokensToSend);
                // Sending allowed tokens amount
                ERC223Interface(maxxerToken).transfer(TEAM_ADDRESS, tokensToSend);
                emit Withdraw(TEAM_ADDRESS,tokensToSend);
            }
        }
    }
}