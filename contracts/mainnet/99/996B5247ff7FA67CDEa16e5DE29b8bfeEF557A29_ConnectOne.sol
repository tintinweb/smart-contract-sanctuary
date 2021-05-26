pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// import files from common directory
import { TokenInterface , MemoryInterface } from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface OneInchInterace {
    function swap(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        uint256 guaranteedAmount,
        address payable referrer,
        address[] calldata callAddresses,
        bytes calldata callDataConcat,
        uint256[] calldata starts,
        uint256[] calldata gasLimitsAndValues
    )
    external
    payable
    returns (uint256 returnAmount);
}

interface OneProtoInterface {
    function swap(
        TokenInterface fromToken,
        TokenInterface destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags // See contants in IOneSplit.sol
    ) external payable returns(uint256);

    function swapMulti(
        TokenInterface[] calldata tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256[] calldata flags
    ) external payable returns(uint256 returnAmount);

    function getExpectedReturn(
        TokenInterface fromToken,
        TokenInterface destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
    external
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    );
}

interface OneProtoMappingInterface {
    function oneProtoAddress() external view returns(address);
}


abstract contract OneHelpers is Stores, DSMath {

    /**
     * @dev Return 1proto mapping Address
     */
    function getOneProtoMappingAddress() internal pure returns (address payable) {
        return 0x8d0287AFa7755BB5f2eFe686AA8d4F0A7BC4AE7F;
    }

    /**
     * @dev Return 1proto Address
     */
    function getOneProtoAddress() internal virtual view returns (address payable) {
        return payable(OneProtoMappingInterface(getOneProtoMappingAddress()).oneProtoAddress());
    }

    /**
     * @dev Return  1Inch Address
     */
    function getOneInchAddress() internal pure returns (address) {
        return 0x11111112542D85B3EF69AE05771c2dCCff4fAa26;
    }

    /**
     * @dev Return 1inch swap function sig
     */
    function getOneInchSwapSig() internal pure returns (bytes4) {
        return 0x7c025200;
    }

     /**
     * @dev Return 1inch swap function sig
     */
    function getOneInchUnoswapSig() internal pure returns (bytes4) {
        return 0x2e95b6c8;
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == ethAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ?  18 : sellAddr.decimals();
    }

    function getSlippageAmt(
        TokenInterface _buyAddr,
        TokenInterface _sellAddr,
        uint _sellAmt,
        uint unitAmt
    ) internal view returns(uint _slippageAmt) {
        (uint _buyDec, uint _sellDec) = getTokensDec(_buyAddr, _sellAddr);
        uint _sellAmt18 = convertTo18(_sellDec, _sellAmt);
        _slippageAmt = convert18ToDec(_buyDec, wmul(unitAmt, _sellAmt18));
    }

    function convertToTokenInterface(address[] memory tokens) internal pure returns(TokenInterface[] memory) {
        TokenInterface[] memory _tokens = new TokenInterface[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            _tokens[i] = TokenInterface(tokens[i]);
        }
        return _tokens;
    }
}


abstract contract OneProtoResolver is OneHelpers {
    struct OneProtoData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint _sellAmt;
        uint _buyAmt;
        uint unitAmt;
        uint[] distribution;
        uint disableDexes;
    }

    function oneProtoSwap(
        OneProtoInterface oneProtoContract,
        OneProtoData memory oneProtoData
    ) internal returns (uint buyAmt) {
        TokenInterface _sellAddr = oneProtoData.sellToken;
        TokenInterface _buyAddr = oneProtoData.buyToken;
        uint _sellAmt = oneProtoData._sellAmt;

        uint _slippageAmt = getSlippageAmt(_buyAddr, _sellAddr, _sellAmt, oneProtoData.unitAmt);

        uint ethAmt;
        if (address(_sellAddr) == ethAddr) {
            ethAmt = _sellAmt;
        } else {
            _sellAddr.approve(address(oneProtoContract), _sellAmt);
        }


        uint initalBal = getTokenBal(_buyAddr);
        oneProtoContract.swap{value: ethAmt}(
            _sellAddr,
            _buyAddr,
            _sellAmt,
            _slippageAmt,
            oneProtoData.distribution,
            oneProtoData.disableDexes
        );
        uint finalBal = getTokenBal(_buyAddr);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    struct OneProtoMultiData {
        address[] tokens;
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint _sellAmt;
        uint _buyAmt;
        uint unitAmt;
        uint[] distribution;
        uint[] disableDexes;
    }

    function oneProtoSwapMulti(OneProtoMultiData memory oneProtoData) internal returns (uint buyAmt) {
        TokenInterface _sellAddr = oneProtoData.sellToken;
        TokenInterface _buyAddr = oneProtoData.buyToken;
        uint _sellAmt = oneProtoData._sellAmt;
        uint _slippageAmt = getSlippageAmt(_buyAddr, _sellAddr, _sellAmt, oneProtoData.unitAmt);

        OneProtoInterface oneSplitContract = OneProtoInterface(getOneProtoAddress());
        uint ethAmt;
        if (address(_sellAddr) == ethAddr) {
            ethAmt = _sellAmt;
        } else {
            _sellAddr.approve(address(oneSplitContract), _sellAmt);
        }

        uint initalBal = getTokenBal(_buyAddr);
        oneSplitContract.swapMulti{value: ethAmt}(
            convertToTokenInterface(oneProtoData.tokens),
            _sellAmt,
            _slippageAmt,
            oneProtoData.distribution,
            oneProtoData.disableDexes
        );
        uint finalBal = getTokenBal(_buyAddr);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }
}

abstract contract OneInchResolver is OneProtoResolver {
    function checkOneInchSig(bytes memory callData) internal pure returns(bool isOk) {
        bytes memory _data = callData;
        bytes4 sig;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            sig := mload(add(_data, 32))
        }
        isOk = sig == getOneInchSwapSig() || sig == getOneInchUnoswapSig();
    }

    struct OneInchData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint _sellAmt;
        uint _buyAmt;
        uint unitAmt;
        bytes callData;
    }

    function oneInchSwap(
        OneInchData memory oneInchData,
        uint ethAmt
    ) internal returns (uint buyAmt) {
        TokenInterface buyToken = oneInchData.buyToken;
        (uint _buyDec, uint _sellDec) = getTokensDec(buyToken, oneInchData.sellToken);
        uint _sellAmt18 = convertTo18(_sellDec, oneInchData._sellAmt);
        uint _slippageAmt = convert18ToDec(_buyDec, wmul(oneInchData.unitAmt, _sellAmt18));

        uint initalBal = getTokenBal(buyToken);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = address(getOneInchAddress()).call{value: ethAmt}(oneInchData.callData);
        if (!success) revert("1Inch-swap-failed");

        uint finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

}

abstract contract OneProtoEventResolver is OneInchResolver {
    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function emitLogSell(
        OneProtoData memory oneProtoData,
        uint256 getId,
        uint256 setId
    ) internal {
        emit LogSell(
            address(oneProtoData.buyToken),
            address(oneProtoData.sellToken),
            oneProtoData._buyAmt,
            oneProtoData._sellAmt,
            getId,
            setId
        );
    }

    event LogSellTwo(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function emitLogSellTwo(
        OneProtoData memory oneProtoData,
        uint256 getId,
        uint256 setId
    ) internal {
        emit LogSellTwo(
            address(oneProtoData.buyToken),
            address(oneProtoData.sellToken),
            oneProtoData._buyAmt,
            oneProtoData._sellAmt,
            getId,
            setId
        );
    }

    event LogSellMulti(
        address[] tokens,
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function emitLogSellMulti(
        OneProtoMultiData memory oneProtoData,
        uint256 getId,
        uint256 setId
    ) internal {
        emit LogSellMulti(
            oneProtoData.tokens,
            address(oneProtoData.buyToken),
            address(oneProtoData.sellToken),
            oneProtoData._buyAmt,
            oneProtoData._sellAmt,
            getId,
            setId
        );
    }
}

abstract contract OneInchEventResolver is OneProtoEventResolver {
    event LogSellThree(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function emitLogSellThree(
        OneInchData memory oneInchData,
        uint256 setId
    ) internal {
        emit LogSellThree(
            address(oneInchData.buyToken),
            address(oneInchData.sellToken),
            oneInchData._buyAmt,
            oneInchData._sellAmt,
            0,
            setId
        );
    }
}

abstract contract OneProtoResolverHelpers is OneInchEventResolver {
    function _sell(
        OneProtoData memory oneProtoData,
        uint256 getId,
        uint256 setId
    ) internal {
        uint _sellAmt = getUint(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            getTokenBal(oneProtoData.sellToken) :
            _sellAmt;

        OneProtoInterface oneProtoContract = OneProtoInterface(getOneProtoAddress());

        (, oneProtoData.distribution) = oneProtoContract.getExpectedReturn(
                oneProtoData.sellToken,
                oneProtoData.buyToken,
                oneProtoData._sellAmt,
                5,
                0
            );

        oneProtoData._buyAmt = oneProtoSwap(
            oneProtoContract,
            oneProtoData
        );

        setUint(setId, oneProtoData._buyAmt);

        emitLogSell(oneProtoData, getId, setId);
    }

    function _sellTwo(
        OneProtoData memory oneProtoData,
        uint getId,
        uint setId
    ) internal {
        uint _sellAmt = getUint(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            getTokenBal(oneProtoData.sellToken) :
            _sellAmt;

        oneProtoData._buyAmt = oneProtoSwap(
            OneProtoInterface(getOneProtoAddress()),
            oneProtoData
        );

        setUint(setId, oneProtoData._buyAmt);
        emitLogSellTwo(oneProtoData, getId, setId);
    }

    function _sellMulti(
        OneProtoMultiData memory oneProtoData,
        uint getId,
        uint setId
    ) internal {
        uint _sellAmt = getUint(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            getTokenBal(oneProtoData.sellToken) :
            _sellAmt;

        oneProtoData._buyAmt = oneProtoSwapMulti(oneProtoData);
        setUint(setId, oneProtoData._buyAmt);

        emitLogSellMulti(oneProtoData, getId, setId);
    }
}

abstract contract OneInchResolverHelpers is OneProtoResolverHelpers {
    function _sellThree(
        OneInchData memory oneInchData,
        uint setId
    ) internal {
        TokenInterface _sellAddr = oneInchData.sellToken;

        uint ethAmt;
        if (address(_sellAddr) == ethAddr) {
            ethAmt = oneInchData._sellAmt;
        } else {
            TokenInterface(_sellAddr).approve(getOneInchAddress(), oneInchData._sellAmt);
        }

        require(checkOneInchSig(oneInchData.callData), "Not-swap-function");

        oneInchData._buyAmt = oneInchSwap(oneInchData, ethAmt);
        setUint(setId, oneInchData._buyAmt);

        emitLogSellThree(oneInchData, setId);
    }
}

abstract contract OneProto is OneInchResolverHelpers {
    /**
     * @dev Sell ETH/ERC20_Token using 1proto.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable {
        OneProtoData memory oneProtoData = OneProtoData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            _sellAmt: sellAmt,
            unitAmt: unitAmt,
            distribution: new uint[](0),
            _buyAmt: 0,
            disableDexes: 0
        });

        _sell(oneProtoData, getId, setId);
    }

    /**
     * @dev Sell ETH/ERC20_Token using 1proto using off-chain calculation.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param distribution distribution of swap across different dex.
     * @param disableDexes disable a dex. (To disable none: 0)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sellTwo(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint[] calldata distribution,
        uint disableDexes,
        uint getId,
        uint setId
    ) external payable {
        OneProtoData memory oneProtoData = OneProtoData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            _sellAmt: sellAmt,
            unitAmt: unitAmt,
            distribution: distribution,
            disableDexes: disableDexes,
            _buyAmt: 0
        });

        _sellTwo(oneProtoData, getId, setId);
    }

    /**
     * @dev Sell ETH/ERC20_Token using 1proto using muliple token.
     * @param tokens array of tokens.
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param distribution distribution of swap across different dex.
     * @param disableDexes disable a dex. (To disable none: 0)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sellMulti(
        address[] calldata tokens,
        uint sellAmt,
        uint unitAmt,
        uint[] calldata distribution,
        uint[] calldata disableDexes,
        uint getId,
        uint setId
    ) external payable {
        OneProtoMultiData memory oneProtoData = OneProtoMultiData({
            tokens: tokens,
            buyToken: TokenInterface(address(tokens[tokens.length - 1])),
            sellToken: TokenInterface(address(tokens[0])),
            unitAmt: unitAmt,
            distribution: distribution,
            disableDexes: disableDexes,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        _sellMulti(oneProtoData, getId, setId);
    }
}

abstract contract OneInch is OneProto {
    /**
     * @dev Sell ETH/ERC20_Token using 1inch.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 1inch API.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sellThree(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        bytes calldata callData,
        uint setId
    ) external payable {
        OneInchData memory oneInchData = OneInchData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        _sellThree(oneInchData, setId);
    }
}

contract ConnectOne is OneInch {
    string public name = "1inch-1proto-v1.2";

        /**
     * @dev Connector Details
    */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 98);
    }
}

pragma solidity ^0.7.0;

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

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}

pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

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

pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}