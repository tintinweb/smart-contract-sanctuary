pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

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
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IToken {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function setTokenLock (uint256 lockedTokens, address purchaser) external;
}


contract EarlyBirds is Owned {
    using SafeMath for uint256;
    address public tokenAddress;
    bool public saleOpen;
    uint256 public perUserLimit = 10 ether;
    
    struct USER{
        uint256 amount;
        bool whiteListed;
    }
    mapping (address => USER) users;

    constructor() public {
        owner = msg.sender;
    }
    
    function setTokenAddress(address _tokenAddress) external onlyOwner{
        require(_tokenAddress == address(0), "Already connected to a token address");
        tokenAddress = _tokenAddress;
    }
    
    function startSale() external onlyOwner{
        require(!saleOpen, "Sale is already open");
        saleOpen = true;
    }
    
    function closeSale() external onlyOwner{
        require(saleOpen, "Sale is not open");
        saleOpen = false;
    }

    receive() external payable{
        require(saleOpen, "Sale is not open");
        require(users[msg.sender].whiteListed, "User is not whitelisted");
        require(msg.value >= 0.1 ether, "Min investment allowed is 0.1 ether");
        require(users[msg.sender].amount.add(msg.value) <= perUserLimit, "Only max 10 ethers are allowed per user");
        
        users[msg.sender].amount = users[msg.sender].amount.add(msg.value);
        
        uint256 tokens = getTokenAmount(msg.value);
        
        require(IToken(tokenAddress).transfer(msg.sender, tokens), "Sale Ended!");
        
        // update the locking for this account
        IToken(tokenAddress).setTokenLock(tokens, msg.sender);
        
        // send received funds to the owner
        owner.transfer(msg.value);
    }
    
    function getTokenAmount(uint256 amount) internal pure returns(uint256){
        return amount.mul(200000); // 1 ether = 200.000 tokens approx
    }
    
    function addToWhitelist(address user) external onlyOwner{
        require(!users[user].whiteListed, "already whitelisted");
        users[user].whiteListed = true;
    }
    
    function whitelistMultipleUsers(address[] calldata _users) external onlyOwner{
        require(_users.length > 0, "Must send valid amount of users");
        require(_users.length <= 100, "Can whitelist max 100 users at once");
        
        for(uint256 i=0; i < _users.length; i++){
            users[_users[i]].whiteListed = true;
        }
    }
    

}