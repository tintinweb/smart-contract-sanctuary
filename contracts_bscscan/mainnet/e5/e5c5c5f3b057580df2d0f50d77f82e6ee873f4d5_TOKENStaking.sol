/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

pragma solidity 0.5.8;

 contract TOKENStaking {
    using SafeMath for uint256;

    IERC20 constant TOKEN = IERC20(0x83956a6ceD7e6877AB38f6661Ada5A11F4d4dbc1); // testnet INSDR = 0x0A796f363Db8CBDD25F4332583A3AEEE11666Ddf
    //IERC20 constant VOTETOKEN = IERC20(0xB84Bc31211fF31E5ba6508bcCF169646A69C6234); // TODO

    mapping(address => uint256) public balances;
    mapping(address => uint256) public StakingTime;
    uint256 public totalDeposits;

    function() payable external { /* Payable */ }

    function receiveApproval(address player, uint256 amount, address, bytes calldata) external {
        require(msg.sender == address(TOKEN));
        TOKEN.transferFrom(player, address(this), amount);
        depositInternal(player, (amount * 100) / 100);  // Account for 10% burn;
    }
    
    function depositFor(address player, uint256 amount) external {
        TOKEN.transferFrom(msg.sender, address(this), amount);
        depositInternal(player, (amount * 100) / 100);  // Account for 10% burn;
    }

    function depositInternal(address player, uint256 amount) internal {
        totalDeposits += amount;
        balances[player] += amount;
        StakingTime[player] = now;
    }

    function withdraw(uint256 amount) external {
        address recipient = msg.sender;
        require( now >= StakingTime[recipient], "Staking is not complete yet.");
        // require( now >= StakingTime[recipient] + 7 days, "Staking is not complete yet."); // TODO
        balances[recipient] = balances[recipient].sub(amount);
        totalDeposits = totalDeposits.sub(amount);
        TOKEN.transfer(recipient, amount);
    }
    
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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