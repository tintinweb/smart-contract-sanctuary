/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

pragma solidity ^0.6.12;

library SafeMath {
  /**
  * Multiply two numbers, revert on overflow.
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
  * Integer division of two numbers truncating the quotient, revert on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  /**
  * Subtract two numbers, revert on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  /**
  * Add two numbers, revert on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  /**
  * Divides two numbers and return the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

contract ScaleDAO {
  using SafeMath for uint256;
  function name() public pure returns(string memory) { return "ScaleDAO"; }
  function symbol() public pure returns(string memory) { return "SCAD"; }
  function decimals() public pure returns(uint8) { return 18; }

  // Balance of SCAD
  function balanceOf(address owner) public view returns (uint256) {
    uint256 lp_power = PowerFromLiquidity(owner);
    uint256 token_power = PowerFromToken(owner);

    return lp_power.add(token_power);
  }

  // Total supply of SCAD
  function totalSupply() public view returns (uint256) {
    IERC20 sca = IERC20(0x11a819Beb0AA3327E39f52F90d65Cc9bCA499F33); // SCA token
    IERC20 cirus = IERC20(0x2a82437475A60BebD53e33997636fadE77604fc2); // Cirus token
    IERC20 torum = IERC20(0xE1C42BE9699Ff4E11674819c1885D43Bd92E9D15); // Torum token
    IERC20 ore = IERC20(0xD52f6CA48882Be8fbaa98ce390db18e1dbe1062d); // Ore token
    IERC20 niftsy = IERC20(0x432cdbC749FD96AA35e1dC27765b23fDCc8F5cf1); // Niftsy token
    uint256 sca_totalSca = sca.totalSupply(); // Total supply of SCA
    uint256 cirus_totalCirus = cirus.totalSupply(); // Total supply of Cirus
    uint256 torum_totalTorum = torum.totalSupply(); // Total supply of Torum
    uint256 ore_totalOre = ore.totalSupply(); // Total supply of Ore
    uint256 niftsy_totalNiftsy = niftsy.totalSupply(); // Total supply of Niftsy
    uint256 result = 0;
        {
            result = sca_totalSca.add(cirus_totalCirus).add(torum_totalTorum).add(ore_totalOre).add(niftsy_totalNiftsy);
        }
        return result;
  }

  // Voting power calculated based on the liquidity provision
  function PowerFromLiquidity(address owner) private view returns (uint256) {
    IPair pair = IPair(0x2922E104e1e81B5Ea5f6aC7b895f040ba2Be6a24); // SCA-WETH pair
    (uint256 lp_totalSCA, , ) = pair.getReserves(); // Total supply of SCA in the pair SCA-WETH
    uint256 lp_total = pair.totalSupply();
    uint256 lp_balance = pair.balanceOf(owner);

    return lp_totalSCA.mul(lp_balance).div(lp_total).mul(2);
  }

  // Voting power calculated based on the holding of SCA and external launched tokens
  // Each set will consist of 5 tokens launched on ScaleSwap
  function PowerFromTokenSet00001(address owner) private view returns (uint256) {
    IERC20 sca = IERC20(0x11a819Beb0AA3327E39f52F90d65Cc9bCA499F33); // SCA token
    IERC20 cirus = IERC20(0x2a82437475A60BebD53e33997636fadE77604fc2); // Cirus token
    IERC20 torum = IERC20(0xE1C42BE9699Ff4E11674819c1885D43Bd92E9D15); // Torum token
    IERC20 ore = IERC20(0xD52f6CA48882Be8fbaa98ce390db18e1dbe1062d); // Ore token
    IERC20 niftsy = IERC20(0x432cdbC749FD96AA35e1dC27765b23fDCc8F5cf1); // Niftsy token
    uint256 sca_balance = sca.balanceOf(owner); // The user's balance of SCA token
    uint256 cirus_balance = cirus.balanceOf(owner); // The user's balance of Cirus token
    uint256 torum_balance = torum.balanceOf(owner); // The user's balance of Torum token
    uint256 ore_balance = ore.balanceOf(owner); // The user's balance of Ore token
    uint256 niftsy_balance = niftsy.balanceOf(owner); // The user's balance of Niftsy token

    return sca_balance.add(cirus_balance).add(torum_balance).add(ore_balance).add(niftsy_balance);
  }

  function PowerFromToken(address owner) private view returns (uint256) {
    uint256 result = PowerFromTokenSet00001(owner);
    return result;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}