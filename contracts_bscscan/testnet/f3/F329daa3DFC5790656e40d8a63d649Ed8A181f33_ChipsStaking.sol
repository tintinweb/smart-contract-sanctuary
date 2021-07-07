/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-18
*/

/*
 * CookieFinance
 * App:             https://cookiebake.finance
 * Medium:          https://medium.com/@cookiefinance    
 * Twitter:         https://twitter.com/cookiedefi 
 * Telegram:        https://t.me/cookiedefi 
 * Announcements:   https://t.me/cookiefinance
 * GitHub:          https://github.com/cookiedefi
 */
pragma solidity 0.8.0;
// SPDX-License-Identifier: UNLICENSED

 contract ChipsStaking {
    using SafeMath for uint256;

    ERC20 chips ;//

    mapping(address => uint256) public balances;
    mapping(address => int256) payoutsTo;

    uint256 public totalDeposits;
    uint256 profitPerShare;
    uint256 constant internal magnitude = 2 ** 64;
    
    constructor(ERC20 _chips) {
        chips = _chips;
    }

    function receiveApproval(address player, uint256 amount, address, bytes calldata) external {
        require(msg.sender == address(chips),"ChipsStaking :: receiveApproval : invalid msg.sender, msg.sender must be a chips address" );
        chips.transferFrom(player, address(this), amount);
        totalDeposits += amount;
        balances[player] += amount;
        payoutsTo[player] += (int256) (profitPerShare * amount);
    }
    
    function depositFor(address player, uint256 amount) external {
        require(chips.balanceOf(msg.sender) >= amount, "ChipsStaking :: depositFor : insufficient balance to deposit");
        require(chips.allowance(msg.sender, address(this)) >= amount, "ChipsStaking :: depositFor : insufficient allowance to deposit");
        chips.transferFrom(msg.sender, address(this), amount);
        totalDeposits += amount;
        balances[player] += amount;
        payoutsTo[player] += (int256) (profitPerShare * amount);
    }

    function cashout(uint256 amount) external {
        require(amount > 0, "ChipsStaking :: cashout : amount must be greater than zero");
        address recipient = msg.sender;
        claimYield();
        balances[recipient] = balances[recipient].sub(amount);
        totalDeposits = totalDeposits.sub(amount);
        payoutsTo[recipient] -= (int256) (profitPerShare * amount);
        chips.transfer(recipient, amount);
    }

    function claimYield() public {
        address recipient = msg.sender;
        uint256 dividends = (uint256) ((int256)(profitPerShare * balances[recipient]) - payoutsTo[recipient]) / magnitude;
        if (dividends > 0) {
            payoutsTo[recipient] += (int256) (dividends * magnitude);
            chips.transfer(recipient, dividends);
        }
    }
    
    function depositYield() external {
        address recipient = msg.sender;
        uint256 dividends = (uint256) ((int256)(profitPerShare * balances[recipient]) - payoutsTo[recipient]) / magnitude;
        
        if (dividends > 0) {
            totalDeposits += dividends;
            balances[recipient] += dividends;
            payoutsTo[recipient] += ((int256) (dividends * magnitude) + (int256) (profitPerShare * dividends)); // Divs + Deposit
        }
    }

    function distributeDivs(uint256 amount) external {
        require(chips.transferFrom(msg.sender, address(this), amount));
        profitPerShare += (amount * magnitude) / totalDeposits;
    }
    

    function dividendsOf(address farmer) view public returns (uint256) {
        return (uint256) ((int256)(profitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
    }
}



interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function burn(uint256 amount) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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