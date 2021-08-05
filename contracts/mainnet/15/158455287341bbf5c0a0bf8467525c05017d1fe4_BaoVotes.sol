/**
 *Submitted for verification at Etherscan.io on 2020-12-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-12
*/

pragma solidity ^0.6.12;

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function unlockedSupply() external view returns (uint256);
    function totalLock() external view returns (uint256);
    function lockOf(address account) external view returns (uint256);
}

interface IPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IMasterChef {
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pendingbao(uint256 nr, address who) external view returns (uint256);
}

contract BaoVotes {
  using SafeMath for uint256;
  
  function name() public pure returns(string memory) { return "BaoVotes"; }
  function symbol() public pure returns(string memory) { return "BaoVotes"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
    IPair pair = IPair(0x9973bb0fE5F8DF5dE730776dF09E946c74254fb3);
    IERC20 bao = IERC20(0x374CB8C27130E2c9E04F44303f3c8351B9De61C1);
    (uint256 lp_totalbao, , ) = pair.getReserves();
    (uint256 unlockedTotal) = bao.unlockedSupply();
    (uint256 lockedTotal) = bao.totalLock();

    return lp_totalbao.mul(2).add(unlockedTotal.div(4)).add(lockedTotal.div(5));
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0xBD530a1c060DC600b951f16dc656E4EA451d1A2D);
    IERC20 bao = IERC20(0x374CB8C27130E2c9E04F44303f3c8351B9De61C1);
    
    (uint256 lp_totalbao, ) = chef.userInfo(0, owner);
    uint256 locked_balance = bao.lockOf(owner);
    uint256 bao_balance = bao.balanceOf(owner).mul(25).div(100);

    // Add locked balance
    uint256 lp_balance = lp_totalbao.mul(2);
    lp_balance = lp_balance.add(locked_balance.mul(20).div(100));
    
    // Add user bao balance
    uint256 lp_powah = lp_balance.add(bao_balance);

    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}