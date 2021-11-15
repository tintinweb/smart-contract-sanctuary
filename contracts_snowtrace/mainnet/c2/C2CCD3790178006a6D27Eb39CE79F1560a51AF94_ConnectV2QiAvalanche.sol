/**
 *Submitted for verification at snowtrace.io on 2021-11-12
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File contracts/avalanche/common/interfaces.sol
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Reward.
 * @dev Claim Reward.
 */

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}


// File contracts/avalanche/common/stores.sol

abstract contract Stores {

  /**
   * @dev Return avax address
   */
  address constant internal avaxAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped AVAX address
   */
  address constant internal wavaxAddr = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x3254Ce8f5b1c82431B8f21Df01918342215825C2);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}


// File @openzeppelin/contracts/math/[email protected]

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}


abstract contract Basic is DSMath, Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == avaxAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == avaxAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == avaxAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function approve(TokenInterface token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeAvaxAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == avaxAddr ? TokenInterface(wavaxAddr) : TokenInterface(buy);
        _sell = sell == avaxAddr ? TokenInterface(wavaxAddr) : TokenInterface(sell);
    }

    function convertAvaxToWavax(bool isAvax, TokenInterface token, uint amount) internal {
        if(isAvax) token.deposit{value: amount}();
    }

    function convertWavaxToAvax(bool isAvax, TokenInterface token, uint amount) internal {
       if(isAvax) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}

interface ComptrollerInterface {
    function claimReward(uint8 rewardType, address holder) external;
    function claimReward(uint8 rewardType, address holder, address[] calldata) external;
    function claimReward(uint8 rewardType, address[] calldata holders, address[] calldata qiTokens, bool borrowers, bool suppliers) external;
}

interface QiInterface {
    function delegate(address delegatee) external;
    function delegates(address) external view returns(address);
}

interface BenqiMappingInterface {
    function qiTokenMapping(string calldata tokenId) external view returns (address);
    function getMapping(string calldata tokenId) external view returns (address, address);
}


abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Benqi Comptroller
     */
    ComptrollerInterface internal constant troller = ComptrollerInterface(0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4);

    /**
     * @dev Reward Token
     */
    QiInterface internal constant benqiToken = QiInterface(0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5);

    /**
     * @dev Benqi Mapping
     */
    BenqiMappingInterface internal constant qiMapping = BenqiMappingInterface(0xe19Fba29ac9BAACc1F584aEcD9C98B4F6fC58ba6);

    /**
     * @dev Benqi reward token type to show BENQI or AVAX
     */
    uint8 internal constant rewardQi = 0;
    uint8 internal constant rewardAvax = 1;

    function getMergedQiTokens(
        string[] calldata supplyIds,
        string[] calldata borrowIds
    ) internal view returns (address[] memory qitokens, bool isBorrow, bool isSupply) {
        uint _supplyLen = supplyIds.length;
        uint _borrowLen = borrowIds.length;
        uint _totalLen = add(_supplyLen, _borrowLen);
        qitokens = new address[](_totalLen);

        if(_supplyLen > 0) {
            isSupply = true;
            for (uint i = 0; i < _supplyLen; i++) {
                (address token, address qiToken) = qiMapping.getMapping(supplyIds[i]);
                require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

                qitokens[i] = qiToken;
            }
        }

        if(_borrowLen > 0) {
            isBorrow = true;
            for (uint i = 0; i < _borrowLen; i++) {
                (address token, address qiToken) = qiMapping.getMapping(borrowIds[i]);
                require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

                qitokens[_supplyLen + i] = qiToken;
            }
        }
    }
}


// File contracts/avalanche/connectors/Qi/events.sol

contract Events {
    event LogClaimedReward(uint256 rewardAmt, uint256 setId);
    event LogDelegate(address delegatee);
}


// File contracts/avalanche/connectors/Qi/main.sol


abstract contract BenqiResolver is Events, Helpers {

    /**
     * @dev Claim Accrued Qi Token.
     * @notice Claim Accrued Qi Token.
     * @param setId ID stores the amount of Reward claimed.
    */
    function ClaimReward(uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
        TokenInterface _benqiToken = TokenInterface(address(benqiToken));
        uint intialBal = _benqiToken.balanceOf(address(this));
        troller.claimReward(rewardQi, address(this));
        uint finalBal = _benqiToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        _eventName = "LogClaimedReward(uint256,uint256)";
        _eventParam = abi.encode(amt, setId);
    }

    /**
     * @dev Claim Accrued Qi Token.
     * @notice Claim Accrued Qi Token.
     * @param tokenIds Array of supplied and borrowed token IDs.
     * @param setId ID stores the amount of Reward claimed.
    */
    function ClaimRewardTwo(string[] calldata tokenIds, uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _len = tokenIds.length;
        address[] memory qitokens = new address[](_len);
        for (uint i = 0; i < _len; i++) {
            (address token, address qiToken) = qiMapping.getMapping(tokenIds[i]);
            require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

            qitokens[i] = qiToken;
        }

        TokenInterface _benqiToken = TokenInterface(address(benqiToken));
        uint intialBal = _benqiToken.balanceOf(address(this));
        troller.claimReward(rewardQi, address(this), qitokens);
        uint finalBal = _benqiToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        _eventName = "LogClaimedReward(uint256,uint256)";
        _eventParam = abi.encode(amt, setId);
    }

    /**
     * @dev Claim Accrued Qi Token.
     * @notice Claim Accrued Qi Token.
     * @param supplyTokenIds Array of supplied tokenIds.
     * @param borrowTokenIds Array of borrowed tokenIds.
     * @param setId ID stores the amount of Reward claimed.
    */
    function ClaimRewardThree(string[] calldata supplyTokenIds, string[] calldata borrowTokenIds, uint256 setId) external payable returns (string memory _eventName, bytes memory _eventParam) {
       (address[] memory qitokens, bool isBorrow, bool isSupply) = getMergedQiTokens(supplyTokenIds, borrowTokenIds);

        address[] memory holders = new address[](1);
        holders[0] = address(this);

        TokenInterface _benqiToken = TokenInterface(address(benqiToken));
        uint intialBal = _benqiToken.balanceOf(address(this));
        troller.claimReward(rewardQi, holders, qitokens, isBorrow, isSupply);
        uint finalBal = _benqiToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        _eventName = "LogClaimedReward(uint256,uint256)";
        _eventParam = abi.encode(amt, setId);
    }

    /**
     * @dev Delegate votes.
     * @notice Delegate votes.
     * @param delegatee The address to delegate the votes to.
    */
    function delegate(address delegatee) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(benqiToken.delegates(address(this)) != delegatee, "Already delegated to same delegatee.");

        benqiToken.delegate(delegatee);

        _eventName = "LogDelegate(address)";
        _eventParam = abi.encode(delegatee);
    }
}

contract ConnectV2QiAvalanche is BenqiResolver {
    string public constant name = "QI-v1";
}