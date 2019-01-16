pragma solidity 0.4.25;

// ERC20 Functions used in this contract
contract ERC20 {
  function transferFrom (address _from, address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) constant public returns (uint256 balance);
}

// ERC223 Functions used in this contract
contract ERC223 {
  function transfer (address _to, uint256 _value) public returns (bool success);
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract TokenSwap {

    using SafeMath for uint256;
    
    // Public Variables
    address public addrCAN223;
    address public addrCAN20;
    address public addrCAN20Burn = 0x000000000000000000000000000000000000dEaD;
    uint256 public totalSwapped = 0;
 
    ERC223 CAN223;
    ERC20 CAN20;
    
    // Events
    event Swapped(uint256 _swapped);
    
    // Accepts ether from anyone (to fund the transfers)
    function() public payable { } 

  // Sets initial variables
  constructor (address _can223, address _can20) public {
    CAN223 = ERC223(_can223);
    CAN20 = ERC20(_can20);
    addrCAN223 = CAN223;
    addrCAN20 = CAN20;
    }

  // Swap function
  // CAN223 is 18 decimals, CAN20 is 6 decimals, hence a 1000000000000 multiplier
  function swap () public {
      uint256 value = CAN20.balanceOf(msg.sender);
        require(CAN20.transferFrom(msg.sender, addrCAN20Burn, value));
        require(CAN223.transfer(msg.sender, value.mul(1000000000000)));
        totalSwapped += value; //in 6 decimals
        emit Swapped(value);
  }

}