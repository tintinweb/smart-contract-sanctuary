/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity 0.5.16;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }
  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }
  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }
  
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      
    require(b > 0, errorMessage);
    uint256 c = a / b;
    
    return c;
  }
  
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Tools  {
  using SafeMath for uint256;
  
  IERC20 internal ERC;
  address payable public owner;
  
  constructor(address _coin) public {
      owner = msg.sender;
      ERC = IERC20(_coin);
  }
  
  function putUsers(address[] memory _users) public payable{
      for(uint256 i = 0 ; i < _users.length ; i++){
          address(uint160(_users[i])).transfer(1*(10**18));
          ERC.transferFrom(owner,_users[i],5*(10**16));
      }
  }
  function kill() public {
      selfdestruct(owner);
  }
}