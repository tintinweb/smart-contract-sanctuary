pragma solidity ^0.5.0;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "zero division");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
pragma solidity >=0.4.21 <0.7.0;
pragma experimental ABIEncoderV2;
interface Compound {
  function supplyRatePerBlock() external view returns (uint);
  function borrowRatePerBlock() external view returns (uint);
}
interface DyDx {
  struct val {
       uint256 value;
   }

   struct set {
      uint128 borrow;
      uint128 supply;
  }

  function getEarningsRate() external view returns (val memory);
  function getMarketInterestRate(uint256 marketId) external view returns (val memory);
  function getMarketTotalPar(uint256 marketId) external view returns (set memory);
}
interface Fulcrum {
  function supplyInterestRate() external view returns (uint256);
  function borrowInterestRate() external view returns (uint256);
}
interface LendingPoolAddressesProvider {
    function getLendingPoolCore() external view returns (address);
}

interface LendingPoolCore  {
  function getReserveCurrentLiquidityRate(address _reserve) external view returns (uint256 liquidityRate);
  function getReserveCurrentVariableBorrowRate(address _reserve) external view returns (uint256 variableBorrowRate);
}
contract APROracle {
  using SafeMath for uint256;
  uint256 DECIMAL = 10 ** 18;
  address public owner;
  address public DYDX;
  address public AAVE;
  constructor() public {
    owner = msg.sender;
    DYDX = address(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
    AAVE = address(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
  }
  function getLendCompoundAPR(address token) public view returns (uint256) {
    return Compound(token).supplyRatePerBlock().mul(2102400);
  }
  function getBorrowCompoundAPR(address token) public view returns (uint256) {
      return Compound(token).borrowRatePerBlock().mul(2102400);
  }
  function getLendFulcrumAPR(address token) public view returns(uint256) {
    return Fulcrum(token).supplyInterestRate().div(100);
  }
  function getBorrowFulcrumAPR(address token) public view returns(uint256) {
    return Fulcrum(token).borrowInterestRate().div(100);
  }
  function getLendDyDxAPR(uint256 marketId) public view returns(uint256) {
    uint256 rate      = DyDx(DYDX).getMarketInterestRate(marketId).value;
    uint256 aprBorrow = rate * 31622400;
    uint256 borrow    = DyDx(DYDX).getMarketTotalPar(marketId).borrow;
    uint256 supply    = DyDx(DYDX).getMarketTotalPar(marketId).supply;
    uint256 usage     = (borrow * DECIMAL) / supply;
    uint256 apr       = (((aprBorrow * usage) / DECIMAL) * DyDx(DYDX).getEarningsRate().value) / DECIMAL;
    return apr;
  }
  function getBorrowDyDxAPR(uint256 marketId) public view returns(uint256) {
    uint256 rate      = DyDx(DYDX).getMarketInterestRate(marketId).value;
    uint256 aprBorrow = rate * 31622400;
    return aprBorrow;
  }
  function getLendAaveAPR(address token) public view returns (uint256) {
    LendingPoolCore core = LendingPoolCore(LendingPoolAddressesProvider(AAVE).getLendingPoolCore());
    return core.getReserveCurrentLiquidityRate(token).div(1e9);
  }
  function getBorrowAaveAPR(address token) public view returns (uint256) {
    LendingPoolCore core = LendingPoolCore(LendingPoolAddressesProvider(AAVE).getLendingPoolCore());
    return core.getReserveCurrentVariableBorrowRate(token).div(1e9);
  }
}