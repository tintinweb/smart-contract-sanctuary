/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }
}

interface IExtendedAggregator {
    function getToken() external view returns (address);
    function getTokenType() external view returns (uint256);
    function getSubTokens() external view returns(address[] memory);
    function latestAnswer() external view returns (int256);
}

interface IERC2O {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract XSushiPriceAdapter is IExtendedAggregator {
    using SafeMath for uint256;
    address public immutable SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public immutable xSUSHI = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;
    address public immutable SUSHI_ORACLE = 0xe572CeF69f43c2E488b33924AF04BDacE19079cf;
    
    enum ProxyType {Invalid, Simple, Complex}
    
    function getToken() external view override returns(address) {
        return xSUSHI;
    }
    function getTokenType() external view override returns (uint256) {
        return uint256(ProxyType.Complex);
    }
 
    function getSubTokens() external view override returns(address[] memory) {
        address[] memory _subtTokens = new address[](1);
        _subtTokens[0] = SUSHI;
        return _subtTokens;
    }
    function latestAnswer() external view override returns (int256) {
        uint256 exchangeRate = (IERC2O(SUSHI).balanceOf(xSUSHI).mul(1 ether)).div(IERC2O(xSUSHI).totalSupply());
        uint256 sushiPrice = uint256(IExtendedAggregator(SUSHI_ORACLE).latestAnswer());
        return int256(sushiPrice.mul(exchangeRate).div(1 ether));
    }
}