/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.4.24;
//import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";



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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
    uint256 c = a + b; //200
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;
  address public coowner;
  uint256 public globalLimit = 3000000;
  address public token = 0xeaf61FC150CD5c3BeA75744e830D916E60EA5A9F;

  // How many tokens each user got distributed
  mapping(address => uint256) public distributedBalances;
  
  // Individual limit for special cases
  mapping(address => uint256) public personalLimit;
  
  constructor() public {
    owner = msg.sender;
    coowner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyTeam() {
    require(msg.sender == coowner || msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) onlyOwner public {
    coowner = _newOwner;
  }

  function changeToken(address _newToken) onlyOwner public {
    token = _newToken;
  }


  function changeGlobalLimit(uint _newGlobalLimit) onlyTeam public {
    globalLimit = _newGlobalLimit;
  }

  function setPersonalLimit(address wallet, uint256 _newPersonalLimit) onlyTeam public {
    personalLimit[wallet] = _newPersonalLimit;
  }

}

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract Airdropper2 is Ownable {
    using SafeMath for uint256;
    function multisend(address[] wallets, uint256[] values) external onlyTeam returns (uint256) {
        
        uint256 limit = globalLimit;
        uint256 tokensToIssue = 0;
        address wallet = address(0);
        
        for (uint i = 0; i < wallets.length; i++) {

            tokensToIssue = values[i];
            wallet = wallets[i];

           if(tokensToIssue > 0 && wallet != address(0)) { 
               
                if(personalLimit[wallet] > globalLimit) {
                    limit = personalLimit[wallet];
                }

                if(distributedBalances[wallet].add(tokensToIssue) > limit) {
                    tokensToIssue = limit.sub(distributedBalances[wallet]);
                }

                if(limit > distributedBalances[wallet]) {
                    distributedBalances[wallet] = distributedBalances[wallet].add(tokensToIssue);
                    ERC20(token).transfer(wallet, tokensToIssue);
                }
           }
        }
    }
    
    function simplesend(address[] wallets) external onlyTeam returns (uint256) {
        
        uint256 tokensToIssue = globalLimit;
        address wallet = address(0);
        
        for (uint i = 0; i < wallets.length; i++) {
            
            wallet = wallets[i];
           if(wallet != address(0)) {
               
                if(distributedBalances[wallet] == 0) {
                    distributedBalances[wallet] = distributedBalances[wallet].add(tokensToIssue);
                    ERC20(token).transfer(wallet, tokensToIssue);
                }
           }
        }
    }


    function evacuateTokens(ERC20 _tokenInstance, uint256 _tokens) external onlyOwner returns (bool success) {
        _tokenInstance.transfer(owner, _tokens);
        return true;
    }

    function _evacuateEther() onlyOwner external {
        owner.transfer(address(this).balance);
    }
}