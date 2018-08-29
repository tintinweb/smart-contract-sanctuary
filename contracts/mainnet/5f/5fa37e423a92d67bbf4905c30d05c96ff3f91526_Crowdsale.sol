pragma solidity ^0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

interface token {
  function mint(address _to, uint256 _amount) external;
  function balanceOf(address _owner) external returns (uint256);
}

contract Crowdsale is Ownable {
    
    using SafeMath for uint256;
    
    address multisig;
    address marketing;

    uint256 restrictedPercent;

    address restricted;

    uint256 minBuy;
    uint256 maxOwnerHas;

    token public tokenReward;

    uint256 rate;
    
    uint256 startPrivateSale;
    uint256 endPrivateSale;
    uint256 startPreICO;
    uint256 endPreICO;
    uint256 startICO;
    uint256 endICO;

    constructor() public {
      multisig = owner;
      marketing = 0x4000ED538DB994ae3d502b0CeF54ca6871550d12;
      restricted = owner;
      restrictedPercent = 25;
      rate = 2500;
      minBuy = 100 * 1 ether;
      maxOwnerHas = 30937500 * 1 ether;
      tokenReward = token(0x586effe896ec06f4a5b5bac7f04b84a6f737bad1);

      startPrivateSale = now;
      endPrivateSale = now + 25 * 1 minutes;  // 1536624000; // (2018-09-11 00:00:00)
      startPreICO = now + 30 * 1 minutes;     // 1539129600; // (2018-10-10 00:00:00)
      endPreICO = now + 55 * 1 minutes;       // 1541894400; // (2018-11-11 00:00:00)
      startICO = now + 60 * 1 minutes;        // 1543622400; // (2018-12-01 00:00:00)
      endICO = now + 90 * 1 minutes;          // 1545436800; // (2018-12-22 00:00:00)
    }

    modifier saleIsOn() {
      require(now > startPrivateSale && now < endICO);
      _;
    }
    
    function init() saleIsOn public {
        tokenReward.mint(owner, 1000000 * 1 ether);
    }

   function createTokens() saleIsOn public payable {
        uint256 tokens = rate.mul(msg.value);
        uint256 bonusTokens = 0;
        uint256 period = 0;

        require(tokens >= minBuy);
        uint256 tokensTotal = tokens.add(tokenReward.balanceOf(msg.sender));
        require(tokensTotal <= maxOwnerHas);

        multisig.transfer(msg.value.div(2));
        marketing.transfer(msg.value.div(2));
        
        // bonus for private sales
        if (now > startPrivateSale && now < endPrivateSale) {
            if (msg.value > 160 * 1 ether) {
                bonusTokens = tokens.div(100).mul(35); // 35/100 = 35%
            } else if (msg.value > 245 * 1 ether) {
                bonusTokens = tokens.div(10).mul(4); // 4/10 = 40/100 = 40%
            } else if (msg.value > 160 * 1 ether) {
                bonusTokens = tokens.div(2); // 1/2 = 50%
            }
        }
        // bonuses for pre-ICO
        if (now > startPreICO && now < endPreICO) {
            period = endPreICO - startPreICO;
            if (now < startPreICO + period.div(4)) {
              bonusTokens = tokens.div(10).mul(3); // 3/10 = 30/100 = 30%
            } else if(now >= startPreICO + period.div(4) && now < startPreICO + period.div(4).mul(2)) {
              bonusTokens = tokens.div(4); // 1/4 = 25/100 = 25%
            } else if(now >= startPreICO + period.div(4).mul(2) && now < startPreICO + period.div(4).mul(3)) {
              bonusTokens = tokens.div(5); // 1/5 = 20/100 = 20%
            } else if(now >= startPreICO + (period * 1 days).div(4).mul(3)) {
                bonusTokens = tokens.div(100).mul(15); // 15/100 = 15%
            }
        }
        // bonuses for ICO
        if (now > startICO && now < endICO) {
            period = endICO - startICO;
            if (now < startICO + (period * 1 days).div(3)) {
              bonusTokens = tokens.div(10); // 1/10 = 10/100 = 10%
            } else if(now >= startICO + (period * 1 days).div(3) && now < startICO + (period * 1 days).div(3).mul(2)) {
              bonusTokens = tokens.div(1000).mul(75); // 75/1000 = 7.5/100 =7.5%
            } else if(now >= startICO + (period * 1 days).div(3).mul(2)) {
              bonusTokens = tokens.div(20); // 1/20 = 5/100 = 5%
            }
        }
        tokens = tokens.add(bonusTokens);
        tokenReward.mint(msg.sender, tokens);

        uint256 restrictedTokens = tokens.mul(restrictedPercent).div(100 - restrictedPercent);
        tokenReward.mint(restricted, restrictedTokens);
    }

    function() external payable {
        createTokens();
    }
}