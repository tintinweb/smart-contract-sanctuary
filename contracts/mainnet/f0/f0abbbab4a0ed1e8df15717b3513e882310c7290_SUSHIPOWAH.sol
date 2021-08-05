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
}

interface IPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IBar {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IMasterChef {
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pendingSushi(uint256 nr, address who) external view returns (uint256);
}

contract SUSHIPOWAH {
  using SafeMath for uint256;
  
  function name() public pure returns(string memory) { return "SUSHIPOWAH"; }
  function symbol() public pure returns(string memory) { return "SUSHIPOWAH"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
    IPair pair = IPair(0x795065dCc9f64b5614C407a6EFDC400DA6221FB0);
    IBar bar = IBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IERC20 sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    (uint256 lp_totalSushi, , ) = pair.getReserves();
    uint256 xsushi_totalSushi = sushi.balanceOf(address(bar));

    return lp_totalSushi.mul(2).add(xsushi_totalSushi);
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    IPair pair = IPair(0x795065dCc9f64b5614C407a6EFDC400DA6221FB0);
    IBar bar = IBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IERC20 sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    
    (uint256 lp_totalSushi, , ) = pair.getReserves();
    uint256 lp_total = pair.totalSupply();
    uint256 lp_balance = pair.balanceOf(owner);

    // Add staked balance
    (uint256 lp_stakedBalance, ) = chef.userInfo(12, owner);
    lp_balance = lp_balance.add(lp_stakedBalance);
    
    // LP voting power is 2x the users SUSHI share in the pool.
    uint256 lp_powah = lp_totalSushi.mul(lp_balance).div(lp_total).mul(2);

    uint256 xsushi_balance = bar.balanceOf(owner);
    uint256 xsushi_total = bar.totalSupply();
    uint256 xsushi_totalSushi = sushi.balanceOf(address(bar));
    
    // xSUSHI voting power is the users SUSHI share in the bar
    uint256 xsushi_powah = xsushi_totalSushi.mul(xsushi_balance).div(xsushi_total);
    
    return lp_powah.add(xsushi_powah);
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}