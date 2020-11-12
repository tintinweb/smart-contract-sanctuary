// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
  
  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address payable to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address payable to, uint256 tokens) external returns (bool success);
}

contract lpEvent{
    
    using SafeMath for uint256;
    
    address payable public fundsReceiver = 0x9F2742e7427E26DeC6beD359F0B4b5bff6A41bB3;
    
    uint256 public totalFundsReceived; 
    uint256 public lpEventEndDate;
    bool public claimOpen = false;
    
    uint256 pointMultiplier = 1e18;
    uint256 public unitShare = 0;
    uint256 public unclaimedLps = 0;
    uint256 public totalLpTokens = 0;
    address public lpTokenAddress;
    
    struct Investor{
        uint256 investment;
        uint256 lpTokensGained;
    }
    mapping(address => Investor) public investors;
    
    modifier onlyFundsReceiver{
        require(msg.sender == fundsReceiver);
        _;
    }
    
    constructor() public{
        lpEventEndDate = block.timestamp.add(3 days); 
    }

    receive() external payable{
        deposit();
    }
    
    function deposit() public payable{
        require(block.timestamp <= lpEventEndDate, "Lp Event is closed");
        totalFundsReceived = totalFundsReceived.add(msg.value);
        investors[msg.sender].investment = investors[msg.sender].investment.add(msg.value);
        fundsReceiver.transfer(msg.value);
    }
    
    function addLpTokens(address _lpTokenAddress, uint256 lpTokens) external onlyFundsReceiver{
        require(block.timestamp > lpEventEndDate, "Lp event is running");
        require(_lpTokenAddress != address(0), "Invalid token address");
        require(!claimOpen, "Cannot add more, claim is already open");
        require(IERC20(_lpTokenAddress).transferFrom(msg.sender, address(this), lpTokens), "Could not transfer lp tokens from sender");
        totalLpTokens = lpTokens;
        unclaimedLps = lpTokens;
        lpTokenAddress = _lpTokenAddress;
        disburse(lpTokens);
        claimOpen = true;
    }
    
    function disburse(uint256 amount) internal{
        uint256 unnormalized = amount.mul(pointMultiplier);
        unitShare = unitShare.add(unnormalized.div(totalFundsReceived)); // un-normalized
    }
    
    function lpShare(address _user) public view returns(uint256){
        uint256 owing = unitShare.mul(investors[_user].investment);
        owing = owing.div(pointMultiplier);
        owing = owing.sub(investors[_user].lpTokensGained);
        return owing;
    }
    
    function claimLpTokens() external {
        require(claimOpen, "Claim is not opened yet");
        uint256 owing = lpShare(msg.sender);
        require(owing > 0, "No pending lp tokens");
        require(IERC20(lpTokenAddress).transfer(msg.sender, owing));
        unclaimedLps = unclaimedLps.sub(owing);
        investors[msg.sender].lpTokensGained = investors[msg.sender].lpTokensGained.add(owing);
    }
}