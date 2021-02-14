/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

// SPDX-License-Identifier: 0BSD

pragma solidity ^0.8.0;

library ABDKMath {
    
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;
  
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    if (x == 0) return bytes16 (0);
    else {
      uint256 result = x;

      uint256 _msb = msb (result);
      if (_msb < 112) result <<= 112 - _msb;
      else if (_msb > 112) result >>= _msb - 112;

      result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + _msb << 112;

      return bytes16 (uint128 (result));
    }
  }
  
  function toUInt (bytes16 x) internal pure returns (uint256) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    if (exponent < 16383) return 0; // Underflow

    require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

    require (exponent <= 16638); // Overflow
    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16495) result >>= 16495 - exponent;
    else if (exponent > 16495) result <<= exponent - 16495;

    return result;
  }
  
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) { 
        if (x == y) return x;
        else return NaN;
      } else return x; 
    } else if (yExponent == 0x7FFF) return y;
    else {
      bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
      else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
      else {
        int256 delta = int256 (xExponent) - int256 (yExponent);
  
        if (xSign == ySign) {
          if (delta > 112) return x;
          else if (delta > 0) ySignifier >>= uint256 (delta);
          else if (delta < -112) return y;
          else if (delta < 0) {
            xSignifier >>= uint256 (-delta);
            xExponent = yExponent;
          }
  
          xSignifier += ySignifier;
  
          if (xSignifier >= 0x20000000000000000000000000000) {
            xSignifier >>= 1;
            xExponent += 1;
          }
  
          if (xExponent == 0x7FFF)
            return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
          else {
            if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
            else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
            return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier)); 
          }
        } else {
          if (delta > 0) {
            xSignifier <<= 1;
            xExponent -= 1;
          } else if (delta < 0) {
            ySignifier <<= 1;
            xExponent = yExponent - 1;
          }

          if (delta > 112) ySignifier = 1;
          else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
          else if (delta < -112) xSignifier = 1;
          else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

          if (xSignifier >= ySignifier) xSignifier -= ySignifier;
          else {
            xSignifier = ySignifier - xSignifier;
            xSign = ySign;
          }

          if (xSignifier == 0)
            return POSITIVE_ZERO;

          uint256 _msb = msb (xSignifier);

          if (_msb == 113) {
            xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            xExponent += 1;
          } else if (_msb < 112) {
            uint256 shift = 112 - _msb;
            if (xExponent > shift) {
              xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent -= shift;
            } else {
              xSignifier <<= xExponent - 1;
              xExponent = 0;
            }
          } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          if (xExponent == 0x7FFF)
            return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
          else return bytes16 (uint128 (
              (xSign ? 0x80000000000000000000000000000000 : 0) |
              (xExponent << 112) |
              xSignifier));
        }
      }
    }
  }
  
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    return add (x, y ^ 0x80000000000000000000000000000000);
  }
  
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) {
        if (x == y) return x ^ y & 0x80000000000000000000000000000000;
        else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
        else return NaN;
      } else {
        if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      }
    } else if (yExponent == 0x7FFF) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return y ^ x & 0x80000000000000000000000000000000;
    } else {
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      xSignifier *= ySignifier;
      if (xSignifier == 0)
        return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
            NEGATIVE_ZERO : POSITIVE_ZERO;

      xExponent += yExponent;

      uint256 _msb =
        xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
        xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
        msb (xSignifier);

      if (xExponent + _msb < 16496) { // Underflow
        xExponent = 0;
        xSignifier = 0;
      } else if (xExponent + _msb < 16608) { // Subnormal
        if (xExponent < 16496)
          xSignifier >>= 16496 - xExponent;
        else if (xExponent > 16496)
          xSignifier <<= xExponent - 16496;
        xExponent = 0;
      } else if (xExponent + _msb > 49373) {
        xExponent = 0x7FFF;
        xSignifier = 0;
      } else {
        if (_msb > 112)
          xSignifier >>= _msb - 112;
        else if (_msb < 112)
          xSignifier <<= 112 - _msb;

        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        xExponent = xExponent + _msb - 16607;
      }

      return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
          xExponent << 112 | xSignifier));
    }
  }
  
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) return NaN;
      else return x ^ y & 0x80000000000000000000000000000000;
    } else if (yExponent == 0x7FFF) {
      if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
      else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
    } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
      if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
      else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
    } else {
      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) {
        if (xSignifier != 0) {
          uint shift = 226 - msb (xSignifier);

          xSignifier <<= shift;

          xExponent = 1;
          yExponent += shift - 114;
        }
      }
      else {
        xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
      }

      xSignifier = xSignifier / ySignifier;
      if (xSignifier == 0)
        return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
            NEGATIVE_ZERO : POSITIVE_ZERO;

      assert (xSignifier >= 0x1000000000000000000000000000);

      uint256 _msb =
        xSignifier >= 0x80000000000000000000000000000 ? msb (xSignifier) :
        xSignifier >= 0x40000000000000000000000000000 ? 114 :
        xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

      if (xExponent + _msb > yExponent + 16497) { // Overflow
        xExponent = 0x7FFF;
        xSignifier = 0;
      } else if (xExponent + _msb + 16380  < yExponent) { // Underflow
        xExponent = 0;
        xSignifier = 0;
      } else if (xExponent + _msb + 16268  < yExponent) { // Subnormal
        if (xExponent + 16380 > yExponent)
          xSignifier <<= xExponent + 16380 - yExponent;
        else if (xExponent + 16380 < yExponent)
          xSignifier >>= yExponent - xExponent - 16380;

        xExponent = 0;
      } else { // Normal
        if (_msb > 112)
          xSignifier >>= _msb - 112;

        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        xExponent = xExponent + _msb + 16269 - yExponent;
      }

      return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
          xExponent << 112 | xSignifier));
    }
  }
  
  function msb (uint256 x) private pure returns (uint256) {
    require (x > 0);

    uint256 result = 0;

    if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
    if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
    if (x >= 0x100000000) { x >>= 32; result += 32; }
    if (x >= 0x10000) { x >>= 16; result += 16; }
    if (x >= 0x100) { x >>= 8; result += 8; }
    if (x >= 0x10) { x >>= 4; result += 4; }
    if (x >= 0x4) { x >>= 2; result += 2; }
    if (x >= 0x2) result += 1; // No need to shift x anymore

    return result;
  }
  
}

interface IERC20 {
    
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint256) external;
    function allowance(address, address) external;
    function approve(address, uint256) external;
    function transferFrom(address, address, uint256) external;

    event Transfer(address indexed, address indexed, uint256);
    event Approval(address indexed, address indexed, uint256);
    
}

abstract contract Rebaser {
    uint public orbiSupplyTotal;
}

contract Orbet {
    
    address public currencyToken;
    address public rebaser;
    address public liquidityToken;
    address public owner;
    address public badTotalSupplyTokenAddress;
    uint40 public teamMemberCount;
    uint24 public winnerPercentage;
    uint24 public callerPercentage;
    uint24 public initiatorPercentage;
    uint24 public burnPercentage;
    uint24 public vaultPercentage;
    bytes16 public winnerPercentageBytes;
    bytes16 public callerPercentageBytes;
    bytes16 public initiatorPercentageBytes;
    bytes16 public burnPercentageBytes;
    bytes16 public vaultPercentageBytes;
    bytes16 public totalVaultRewards;
    bytes16 public floatErrorOffsetMul;
    uint public totalVaultDeposits;
    uint public betCount;
    bool public frozen;
    uint public percentageDecimals;
    uint public totalOrbits = ~uint(0) - ~uint(0) % 1e17;
    
    struct VaultAccount {
        bytes16 T0TotalVaultRewards;
        uint StoredLiquidity;
    }
    
    struct Position {
        bool Position;
        uint BetAmountOrbits;
        bool RewardClaimed;
    }
    
    struct BetStruct {
        bool UnderThreshold;
        uint8 BetStatus;
        bytes16 ThresholdNoThresholdRatio;
        address ObservedToken;
        address ObservedWallet;
        address Initiator;
        uint Threshold;
        uint ExpiryDate;
        uint TotalThresholdBetAmountOrbits;
        uint TotalNoThresholdBetAmountOrbits;
        mapping(address => Position) Positions;
    }
    
    mapping(address => VaultAccount) public VaultAccounts;
    mapping(uint => BetStruct) public BetStructs;
    uint[] public teamPercentages;
    address[] public teamAddresses;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event BetDeposited(uint indexed, bool, uint, address);
    event BetWithdrew(uint indexed, address);
    event BetAdjusted(uint indexed, uint, address);
    event BetRewardClaimed(uint indexed, address);
    event BetEnded(uint indexed, address, bytes16);
    event BetCreated(uint indexed, address);
    
    constructor(address rebaserAddress) {
        owner = msg.sender;
        winnerPercentage = 950000;
        winnerPercentageBytes = ABDKMath.div(ABDKMath.fromUInt(winnerPercentage), 0x4012e848000000000000000000000000);
        callerPercentage = 20000;
        callerPercentageBytes = ABDKMath.div(ABDKMath.fromUInt(callerPercentage), 0x4012e848000000000000000000000000);
        initiatorPercentage = 20000;
        initiatorPercentageBytes = ABDKMath.div(ABDKMath.fromUInt(initiatorPercentage), 0x4012e848000000000000000000000000);
        vaultPercentage = 0;
        vaultPercentageBytes = ABDKMath.div(ABDKMath.fromUInt(vaultPercentage), 0x4012e848000000000000000000000000);
        burnPercentage = 0;
        burnPercentageBytes = ABDKMath.div(ABDKMath.fromUInt(burnPercentage), 0x4012e848000000000000000000000000);
        rebaser = rebaserAddress;
        teamAddresses.push(msg.sender);
        teamPercentages.push(10000);
        teamMemberCount += 1;
        floatErrorOffsetMul = 0x3fff0000000000000000000000000010;
    }
    
    function getOrbitsPerOrbi() internal view returns (uint) {
        if (badTotalSupplyTokenAddress == currencyToken) {
            return totalOrbits / Rebaser(rebaser).orbiSupplyTotal();
        } else {
            return totalOrbits / IERC20(currencyToken).totalSupply();   
        }
    }
    
    function betDeposit(uint betStructId, bool position, uint betAmount) public {
        require(!frozen, "Frozen!");
        BetStruct storage betStruct = BetStructs[betStructId];
        require(betStruct.BetStatus == 1, "Bet Not Active");
        require(betStruct.Positions[msg.sender].BetAmountOrbits == 0, "Position Already Exists");
        uint betAmountOrbits = betAmount * getOrbitsPerOrbi();
        if (!position)
            betStruct.TotalNoThresholdBetAmountOrbits += betAmountOrbits;
        if (position)
            betStruct.TotalThresholdBetAmountOrbits += betAmountOrbits;
        IERC20(currencyToken).transferFrom(msg.sender, address(this), betAmount);
        betStruct.Positions[msg.sender].Position = position;
        betStruct.Positions[msg.sender].BetAmountOrbits = betAmountOrbits;
        emit BetDeposited(betStructId, position, betAmount, msg.sender);
    }
    
    function betWithdraw(uint betStructId) public {
        require(!frozen, "Frozen!");
        BetStruct storage betStruct = BetStructs[betStructId];
        require(betStruct.BetStatus == 1, "Bet Not Active");
        require(betStruct.Positions[msg.sender].BetAmountOrbits > 0, "No Position");
        if (!betStruct.Positions[msg.sender].Position)
            betStruct.TotalNoThresholdBetAmountOrbits -= betStruct.Positions[msg.sender].BetAmountOrbits;
        if (betStruct.Positions[msg.sender].Position)
            betStruct.TotalThresholdBetAmountOrbits -= betStruct.Positions[msg.sender].BetAmountOrbits;
        uint betAmount = betStruct.Positions[msg.sender].BetAmountOrbits / getOrbitsPerOrbi();
        IERC20(currencyToken).transfer(msg.sender, betAmount);
        betStruct.Positions[msg.sender].Position = false;
        betStruct.Positions[msg.sender].BetAmountOrbits = 0;
        emit BetWithdrew(betStructId, msg.sender);
    }
    
    function betAdjust(uint betStructId, uint adjustToAmount) public {
        require(!frozen, "Frozen!");
        BetStruct storage betStruct = BetStructs[betStructId];
        require(betStruct.BetStatus == 1, "Bet Not Active");
        require(betStruct.Positions[msg.sender].BetAmountOrbits > 0, "No Position");
        require(betStruct.Positions[msg.sender].BetAmountOrbits != adjustToAmount, "No Change");
        uint betAmount = betStruct.Positions[msg.sender].BetAmountOrbits / (totalOrbits / Rebaser(rebaser).orbiSupplyTotal());
        if (betAmount > adjustToAmount) {
            uint betAmountDiff = betAmount - adjustToAmount;
            uint betAmountOrbitsDiff = betAmountDiff * getOrbitsPerOrbi();
            IERC20(currencyToken).transfer(msg.sender, betAmountDiff);
            if (!betStruct.Positions[msg.sender].Position)
                betStruct.TotalNoThresholdBetAmountOrbits -= betAmountOrbitsDiff;
            if (betStruct.Positions[msg.sender].Position)
                betStruct.TotalThresholdBetAmountOrbits -= betAmountOrbitsDiff;
        } else {
            uint betAmountDiff = adjustToAmount - betStruct.Positions[msg.sender].BetAmountOrbits;
            uint betAmountOrbitsDiff = betAmountDiff * getOrbitsPerOrbi();
            IERC20(currencyToken).transferFrom(msg.sender, address(this), betAmountDiff);
            if (!betStruct.Positions[msg.sender].Position)
                betStruct.TotalNoThresholdBetAmountOrbits += betAmountOrbitsDiff;
            if (betStruct.Positions[msg.sender].Position)
                betStruct.TotalThresholdBetAmountOrbits += betAmountOrbitsDiff;
        }
        betStruct.Positions[msg.sender].BetAmountOrbits = adjustToAmount * getOrbitsPerOrbi();
        emit BetAdjusted(betStructId, adjustToAmount, msg.sender);
    }
    
    function claimReward(uint betStructId) public {
        require(!frozen, "Frozen!");
        BetStruct storage betStruct = BetStructs[betStructId];
        require(betStruct.BetStatus == 2, "Bet Not Finalized");
        require(betStruct.Positions[msg.sender].RewardClaimed == false, "Reward Already Claimed");
        require(betStruct.Positions[msg.sender].Position == betStruct.UnderThreshold, "Incorrect Position");
        require(betStruct.Positions[msg.sender].BetAmountOrbits > 0, "No Bet Amount");
        bytes16 betAmountDouble = ABDKMath.fromUInt(betStruct.Positions[msg.sender].BetAmountOrbits);
        bytes16 baseCurrencyTokenReward;
        uint finalCurrencyTokenReward;
        if (betStruct.UnderThreshold) {
            if (betStruct.ThresholdNoThresholdRatio == bytes16(0)) {
                baseCurrencyTokenReward = betAmountDouble;
            } else {
                baseCurrencyTokenReward = ABDKMath.add(betAmountDouble, ABDKMath.div(betAmountDouble, betStruct.ThresholdNoThresholdRatio));
            }
        } else {
            if (betStruct.ThresholdNoThresholdRatio == bytes16(0)) {
                baseCurrencyTokenReward = betAmountDouble;
            } else {
                bytes16 thresholdNoThresholdRatioInverse = ABDKMath.div(ABDKMath.fromUInt(1), betStruct.ThresholdNoThresholdRatio);
                baseCurrencyTokenReward = ABDKMath.add(betAmountDouble, ABDKMath.div(betAmountDouble, thresholdNoThresholdRatioInverse));
            }
        }
        finalCurrencyTokenReward = ABDKMath.toUInt(ABDKMath.mul(floatErrorOffsetMul, ABDKMath.mul(baseCurrencyTokenReward, winnerPercentageBytes))) / getOrbitsPerOrbi();
        IERC20(currencyToken).transfer(msg.sender, finalCurrencyTokenReward);
        betStruct.Positions[msg.sender].RewardClaimed = true;
        emit BetRewardClaimed(betStructId, msg.sender);
    }
    
    function endBet(uint betStructId) public {
        require(!frozen, "Frozen!");
        BetStruct storage betStruct = BetStructs[betStructId];
        require(betStruct.BetStatus == 1, "Bet Not Active");
        require(IERC20(betStruct.ObservedToken).balanceOf(betStruct.ObservedWallet) < betStruct.Threshold || block.timestamp > betStruct.ExpiryDate, "No End Conditions Met");
        betStruct.BetStatus = 2;
        uint orbitsPerOrbi = getOrbitsPerOrbi();
        if (betStruct.TotalNoThresholdBetAmountOrbits == 0) {
            betStruct.ThresholdNoThresholdRatio = bytes16(0);
        } else {
            betStruct.ThresholdNoThresholdRatio = ABDKMath.div(ABDKMath.fromUInt(betStruct.TotalThresholdBetAmountOrbits), ABDKMath.fromUInt(betStruct.TotalNoThresholdBetAmountOrbits));
        }
        if (IERC20(betStruct.ObservedToken).balanceOf(betStruct.ObservedWallet) < betStruct.Threshold)
            betStruct.UnderThreshold = true;
        bytes16 combinedOrbitBetAmountBytes = ABDKMath.fromUInt(betStruct.TotalThresholdBetAmountOrbits + betStruct.TotalNoThresholdBetAmountOrbits);
        for (uint i = 0; i < teamAddresses.length; i++) {
            IERC20(currencyToken).transfer(teamAddresses[i], ABDKMath.toUInt(ABDKMath.mul(floatErrorOffsetMul, ABDKMath.mul(ABDKMath.div(ABDKMath.fromUInt(teamPercentages[i]), 0x4012e848000000000000000000000000), combinedOrbitBetAmountBytes))) / orbitsPerOrbi);
        }
        uint _totalVaultDeposits;
        if (totalVaultDeposits > 0) {
            _totalVaultDeposits = totalVaultDeposits;
        } else {
            _totalVaultDeposits = 1;
        }
        if (vaultPercentage > 0) {
            totalVaultRewards = ABDKMath.add(totalVaultRewards, ABDKMath.div(ABDKMath.mul(combinedOrbitBetAmountBytes, vaultPercentageBytes), ABDKMath.fromUInt(_totalVaultDeposits)));
        }
        IERC20(currencyToken).transfer(msg.sender, ABDKMath.toUInt(ABDKMath.mul(floatErrorOffsetMul, ABDKMath.mul(callerPercentageBytes, combinedOrbitBetAmountBytes))) / orbitsPerOrbi);
        IERC20(currencyToken).transfer(betStruct.Initiator, ABDKMath.toUInt(ABDKMath.mul(floatErrorOffsetMul, ABDKMath.mul(initiatorPercentageBytes, combinedOrbitBetAmountBytes))) / orbitsPerOrbi);
        if (burnPercentage > 0) {
            IERC20(currencyToken).transfer(address(0), ABDKMath.toUInt(ABDKMath.mul(floatErrorOffsetMul, ABDKMath.mul(burnPercentageBytes, combinedOrbitBetAmountBytes))) / orbitsPerOrbi);
        }
      emit BetEnded(betStructId, msg.sender, totalVaultRewards);
    }
    
    function createBet(address observedToken, address observedWallet, uint threshold, uint expiryDate) external returns (uint) {
        require(!frozen, "Frozen!");
        require(currencyToken != address(0), "Currency Token Not Set");
        require(observedToken != address(0) && observedWallet != address(0) && threshold > 0 && expiryDate > block.timestamp, 'Invalid Parameters');
        BetStructs[betCount].ObservedToken = observedToken;
        BetStructs[betCount].ObservedWallet = observedWallet;
        BetStructs[betCount].Threshold = threshold;
        BetStructs[betCount].ExpiryDate = expiryDate;
        BetStructs[betCount].Initiator = msg.sender;
        BetStructs[betCount].BetStatus = 1;
        emit BetCreated(betCount, msg.sender);
        betCount += 1;
        return betCount - 1;
    }

    function createBet2(address observedToken, address observedWallet, uint threshold, uint expiryDate, bool position, uint betAmount) external returns (uint) {
        require(!frozen, "Frozen!");
        require(currencyToken != address(0), "Currency Token Not Set");
        require(observedToken != address(0) && observedWallet != address(0) && threshold > 0 && expiryDate > block.timestamp, 'Invalid Parameters');
        BetStructs[betCount].ObservedToken = observedToken;
        BetStructs[betCount].ObservedWallet = observedWallet;
        BetStructs[betCount].Threshold = threshold;
        BetStructs[betCount].ExpiryDate = expiryDate;
        BetStructs[betCount].Initiator = msg.sender;
        BetStructs[betCount].BetStatus = 1;
        emit BetCreated(betCount, msg.sender);
        betCount += 1;
        Orbet.betDeposit(betCount, position, betAmount);
        return betCount - 1;
    }
    
    function vaultCheckRewards() external view returns (uint) {
        require(VaultAccounts[msg.sender].StoredLiquidity > 0, "No Vault Position Exists");
        return ABDKMath.toUInt(ABDKMath.div(ABDKMath.mul(ABDKMath.sub(totalVaultRewards, VaultAccounts[msg.sender].T0TotalVaultRewards), ABDKMath.fromUInt(VaultAccounts[msg.sender].StoredLiquidity)), ABDKMath.fromUInt(getOrbitsPerOrbi())));
    }
    
    function vaultWithdrawRewards() external {
        require(VaultAccounts[msg.sender].StoredLiquidity > 0, "No Vault Position Exists");
        require(!frozen, "Frozen!");
        IERC20(currencyToken).transfer(msg.sender, ABDKMath.toUInt(ABDKMath.div(ABDKMath.mul(ABDKMath.sub(totalVaultRewards, VaultAccounts[msg.sender].T0TotalVaultRewards), ABDKMath.fromUInt(VaultAccounts[msg.sender].StoredLiquidity)), ABDKMath.fromUInt(getOrbitsPerOrbi()))));
        VaultAccounts[msg.sender].T0TotalVaultRewards = totalVaultRewards;
    }
    
    function vaultWithdraw() external {
        require(!frozen, "Frozen!");
        require(VaultAccounts[msg.sender].StoredLiquidity > 0, "No Vault Position Exists");
        if (this.vaultCheckRewards() > 0) {
            IERC20(currencyToken).transfer(msg.sender, ABDKMath.toUInt(ABDKMath.mul(ABDKMath.sub(totalVaultRewards, VaultAccounts[msg.sender].T0TotalVaultRewards), ABDKMath.fromUInt(VaultAccounts[msg.sender].StoredLiquidity))));
        }
        IERC20(liquidityToken).transfer(msg.sender, VaultAccounts[msg.sender].StoredLiquidity);
        totalVaultDeposits -= VaultAccounts[msg.sender].StoredLiquidity;
        VaultAccounts[msg.sender].StoredLiquidity = 0;
    }
    
    function vaultDeposit(uint depositAmount) external {
        require(!frozen, "Frozen!");
        require(VaultAccounts[msg.sender].StoredLiquidity == 0, "Vault Position Already Exists");
        IERC20(liquidityToken).transferFrom(msg.sender, address(this), depositAmount);
        VaultAccounts[msg.sender].StoredLiquidity = depositAmount;
        VaultAccounts[msg.sender].T0TotalVaultRewards = totalVaultRewards;
        totalVaultDeposits += depositAmount;
    }

    function vaultAdjust(uint newDepositAmount) external {
        require(!frozen, "Frozen!");
        require(VaultAccounts[msg.sender].StoredLiquidity > 0, "No Stored Liquidity");
        require(newDepositAmount != VaultAccounts[msg.sender].StoredLiquidity, "No Change");
        if (newDepositAmount > VaultAccounts[msg.sender].StoredLiquidity) {
            IERC20(liquidityToken).transferFrom(msg.sender, address(this), newDepositAmount - VaultAccounts[msg.sender].StoredLiquidity);
        } else {
            IERC20(liquidityToken).transfer(msg.sender, VaultAccounts[msg.sender].StoredLiquidity - newDepositAmount);
        }
        VaultAccounts[msg.sender].StoredLiquidity = newDepositAmount;
        IERC20(currencyToken).transfer(msg.sender, ABDKMath.toUInt(ABDKMath.mul(ABDKMath.sub(totalVaultRewards, VaultAccounts[msg.sender].T0TotalVaultRewards), ABDKMath.fromUInt(VaultAccounts[msg.sender].StoredLiquidity))));
        VaultAccounts[msg.sender].T0TotalVaultRewards = totalVaultRewards;
    }
    
    function setCurrencyToken(address _currencyToken) external onlyOwner {
        require(!frozen, "Frozen!");
        currencyToken = _currencyToken;
    }
    
    function setLiquidityToken(address _liquidityToken) external onlyOwner {
        require(!frozen, "Frozen!");
        liquidityToken = _liquidityToken;
    }
    
    function changeOwner(address newOwner) external onlyOwner {
        require(!frozen, "Frozen!");
        owner = newOwner;
    }
    
    function setWinnerPercentage(uint24 newWinnerPercentage) external onlyOwner {
        require(!frozen, "Frozen!");
        winnerPercentage = newWinnerPercentage;
        winnerPercentageBytes = ABDKMath.div(ABDKMath.fromUInt(winnerPercentage), 0x4012e848000000000000000000000000);
    }
    
    function setCallerPercentage(uint24 newCallerPercentage) external onlyOwner {
        require(!frozen, "Frozen!");
        callerPercentage = newCallerPercentage;
        callerPercentageBytes = ABDKMath.div(ABDKMath.fromUInt(callerPercentage), 0x4012e848000000000000000000000000);
    }
    
    function setInitiatorPercentage(uint24 newInitiatorPercentage) external onlyOwner {
        require(!frozen, "Frozen!");
        initiatorPercentage = newInitiatorPercentage;
        initiatorPercentageBytes = ABDKMath.div(ABDKMath.fromUInt(initiatorPercentage), 0x4012e848000000000000000000000000);
    }
    
    function setBurnPercentage(uint24 newBurnPercentage) external onlyOwner {
        require(!frozen, "Frozen!");
        burnPercentage = newBurnPercentage;
        burnPercentageBytes = ABDKMath.div(ABDKMath.fromUInt(burnPercentage), 0x4012e848000000000000000000000000);
    }
    
    function setVaultPercentage(uint24 newVaultPercentage) external onlyOwner {
        require(!frozen, "Frozen!");
        vaultPercentage = newVaultPercentage;
        vaultPercentageBytes = ABDKMath.div(ABDKMath.fromUInt(vaultPercentage), 0x4012e848000000000000000000000000);
    }
    
    function addTeamContract(address teamMemberAddress, uint24 teamMemberPercent) external onlyOwner {
        require(!frozen, "Frozen!");
        require(teamMemberPercent > 0 && teamMemberPercent < 10000000, "Invalid Percent");
        teamAddresses.push(teamMemberAddress);
        teamPercentages.push(teamMemberPercent);
        teamMemberCount += 1;
    }
    
    function removeTeamContract(address teamMemberAddress) external onlyOwner {
        require(!frozen, "Frozen!");
        for (uint i = 0; i < teamAddresses.length; i++) {
            if (teamAddresses[i] == teamMemberAddress) {
                teamAddresses[i] = teamAddresses[teamAddresses.length - 1];
                teamPercentages[i] = teamPercentages[teamPercentages.length - 1];
                teamAddresses.pop();
                teamPercentages.pop();
                teamMemberCount -= 1;
            }
        }
    }
    
    function setBadTotalSupplyTokenAddress(address _badTotalSupplyTokenAddress) external onlyOwner {
        require(!frozen, "Frozen!");
        badTotalSupplyTokenAddress = _badTotalSupplyTokenAddress;
    }
    
    function changeTeamContract(address teamMemberAddress, uint newTeamMemberPercent) external onlyOwner {
        require(!frozen, "Frozen!");
        for (uint i = 0; i < teamAddresses.length; i++) {
            if (teamAddresses[i] == teamMemberAddress)
                teamPercentages[i] = newTeamMemberPercent;
        }
    }
    
    function freeze() external onlyOwner {
        frozen = true;
    } 
    
    function unfreeze() external onlyOwner {
        frozen = false;
    } 

    function getBetStructPosition(uint betId, address bettor) public view returns (bool, uint) {
        Position storage position = BetStructs[betId].Positions[bettor];
        return (position.Position, position.BetAmountOrbits / getOrbitsPerOrbi());
    }
    
    function setTotalOrbits(uint _totalOrbits) external onlyOwner {
        require(!frozen, "Frozen!");
        totalOrbits = _totalOrbits;
    }
    
}