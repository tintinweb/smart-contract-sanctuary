pragma solidity ^0.4.20;

interface Token {
    function totalSupply() constant external returns (uint256);
    
    function transfer(address receiver, uint amount) external returns (bool success);
    function burn(uint256 _value) external returns (bool success);
    function startTrading() external;
}

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


interface AquaPriceOracle {
  function getAudCentWeiPrice() external constant returns (uint);
  function getAquaTokenAudCentsPrice() external constant returns (uint);
  event NewPrice(uint _audCentWeiPrice, uint _aquaTokenAudCentsPrice);
}


///@title Aqua Sale Smart contract
contract AquaSale is Owned {
    using SafeMath for uint256;
    
    uint256 constant ONE_HUNDRED = 100;

    //Internal state
    mapping (address => uint) internal buyerBalances;
    
    //Public interface
    
    ///Team trust account address
    address public teamTrustAccount;
    
    ///Team share of total token supply after successful completion of the 
    ///crowdsale expressed as whole percentage number (0-100)
    uint public teamSharePercent;
    
    ///Low funding goal (Soft Cap) in number of tokens
    uint public lowTokensToSellGoal;
    
    ///High funding goal (Hard Cap) in number of tokens
    uint public highTokensToSellGoal;
    
    ///Number of tokens sold
    uint public soldTokens;
    
    ///Crowdsale start time (in seconds since unix epoch)
    uint public startTime;
    
    ///Crowdsale end time (in seconds since unix epoch)
    uint public deadline;

    ///Address of Aqua Token used as a reward for Ether contributions
    Token public tokenReward;
    
    ///Aqua Token price oracle contract address
    AquaPriceOracle public tokenPriceOracle;
    

    ///Indicates if funding goal is reached (crowdsale is successful)
    bool public fundingGoalReached = false;
    
    ///Indicates if high funding goal (Hard Cap) is reached.
    bool public highFundingGoalReached = false;

    ///Event is triggered when funding goal is reached
    ///@param amntRaisedWei Amount raised in Wei
    ///@param isHigherGoal True if Hard Cap is reached. False if Soft Cap is reached
    event GoalReached(uint amntRaisedWei, bool isHigherGoal);
    
    ///Event is triggered when crowdsale contract processes funds transfer
    ///(contribution or withdrawal)
    ///@param backer Account address that sends (in case of contribution) or receives (in case of refund or withdrawal) funds
    ///@param isContribution True in case funds transfer is a contribution. False in case funds transfer is a refund or a withdrawal.
    event FundsTransfer(address backer, uint amount, bool isContribution);

    ///Constructor initializes Aqua Sale contract
    ///@param ifSuccessfulSendTo Beneficiary address – account address that can withdraw raised funds in case crowdsale succeeds
    ///@param _lowTokensToSellGoal Low funding goal (Soft Cap) as number of tokens to sell
    ///@param _highTokensToSellGoal High funding goal (Hard Cap) as number of tokens to sell
    ///@param startAfterMinutes Crowdsale start time as the number of minutes since contract deployment time
    ///@param durationInMinutes Duration of the crowdsale in minutes
    ///@param addressOfTokenUsedAsReward Aqua Token smart contract address
    ///@param addressOfTokenPriceOracle Aqua Price oracle smart contract address
    ///@param addressOfTeamTrusAccount Account address that receives team share of tokens upon successful completion of crowdsale
    ///@param _teamSharePercent Team share of total token supply after successful completion of the crowdsale expressed as whole percentage number (0-100)
    function AquaSale(
        address ifSuccessfulSendTo,
        uint _lowTokensToSellGoal,
        uint _highTokensToSellGoal,
        uint startAfterMinutes,
        uint durationInMinutes,
        address addressOfTokenUsedAsReward,
        address addressOfTokenPriceOracle,
        address addressOfTeamTrusAccount,
        uint _teamSharePercent
    ) public {
        owner = ifSuccessfulSendTo;
        lowTokensToSellGoal = _lowTokensToSellGoal;
        highTokensToSellGoal = _highTokensToSellGoal;
        startTime = now.add(startAfterMinutes.mul(1 minutes));
        deadline = startTime.add(durationInMinutes.mul(1 minutes));
        tokenReward = Token(addressOfTokenUsedAsReward);
        tokenPriceOracle = AquaPriceOracle(addressOfTokenPriceOracle);
        teamTrustAccount = addressOfTeamTrusAccount;
        teamSharePercent = _teamSharePercent;
    }
    
    ///Returns balance of the buyer
    ///@param _buyer address of crowdsale participant
    ///@return Buyer balance in wei
    function buyerBalance(address _buyer) public constant returns(uint) {
        return buyerBalances[_buyer];
    }

    ///Fallback function expects that the sent amount is payment for tokens
    function () public payable {
        purchaseTokens();
    }
    
    ///function accepts Ether and allocates Aqua Tokens to the sender
    function purchaseTokens() public payable {
        require(!highFundingGoalReached && now >= startTime );
        uint amount = msg.value;
        uint noTokens = amount.div(
            tokenPriceOracle.getAquaTokenAudCentsPrice().mul(tokenPriceOracle.getAudCentWeiPrice())
            );
        buyerBalances[msg.sender] = buyerBalances[msg.sender].add(amount);
        soldTokens = soldTokens.add(noTokens);
        checkGoalsReached();

        tokenReward.transfer(msg.sender, noTokens);

        FundsTransfer(msg.sender, amount, true);
    }
    
    ///Investors should call this function in order to receive refund in 
    ///case crowdsale is not successful.
    ///The sending address should be the same address that was used to
    ///participate in crowdsale. The amount will be refunded to this address
    function refund() public {
        require(!fundingGoalReached && buyerBalances[msg.sender] > 0
                && now >= deadline);
        uint amount = buyerBalances[msg.sender];
        buyerBalances[msg.sender] = 0;
        msg.sender.transfer(amount);
        FundsTransfer(msg.sender, amount, false);
    }

    ///iAqua authorized sttaff will call this function to withdraw contributed 
    ///amount (only in case crowdsale is successful)
    function withdraw() onlyOwner public {
        require( (fundingGoalReached && now >= deadline) || highFundingGoalReached );
        uint raisedFunds = this.balance;
        uint teamTokens = soldTokens.mul(teamSharePercent).div(ONE_HUNDRED.sub(teamSharePercent));
        uint totalTokens = tokenReward.totalSupply();
        if (totalTokens < teamTokens.add(soldTokens)) {
            teamTokens = totalTokens.sub(soldTokens);
        }
        tokenReward.transfer(teamTrustAccount, teamTokens);
        uint distributedTokens = teamTokens.add(soldTokens);
        if (totalTokens > distributedTokens) {
            tokenReward.burn(totalTokens.sub(distributedTokens));
        }
        tokenReward.startTrading();
        Owned(address(tokenReward)).transferOwnership(owner);
        owner.transfer(raisedFunds);
        FundsTransfer(owner, raisedFunds, false);
    }
    
    //Internal functions
    
    function checkGoalsReached() internal {
        if (fundingGoalReached) {
            if (highFundingGoalReached) {
                return;
            }
            if (soldTokens >= highTokensToSellGoal) {
                highFundingGoalReached = true;
                GoalReached(this.balance, true);
                return;
            }
        }
        else {
            if (soldTokens >= lowTokensToSellGoal) {
                fundingGoalReached = true;
                GoalReached(this.balance, false);
            }
            if (soldTokens >= highTokensToSellGoal) {
                highFundingGoalReached = true;
                GoalReached(this.balance, true);
                return;
            }
        }
    }
    
}