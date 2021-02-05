// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/SafeMath.sol";
import "../lib/SafeERC20.sol";
import '../lib/TransferHelper.sol';
import "../lib/ABDKMath64x64.sol";

import "../iface/INestPool.sol";
import "../iface/INestStaking.sol";
import "../iface/INToken.sol";
import "../iface/INNRewardPool.sol";
import "../libminingv1/MiningV1Data.sol";
//import "hardhat/console.sol";


/// @title  NestMiningV1/MiningV1Calc
/// @author Inf Loop - <[email protected]>
/// @author Paradox  - <[email protected]>
library MiningV1Calc {

    using SafeMath for uint256;
    
    /// @dev Average block mining interval, ~ 14s
    uint256 constant ETHEREUM_BLOCK_TIMESPAN = 14;

    function _calcVola(
            // uint256 ethA0, 
            uint256 tokenA0, 
            // uint256 ethA1, 
            uint256 tokenA1, 
            int128 _sigma_sq, 
            int128 _ut_sq,
            uint256 _interval
        )
        private
        pure
        // pure 
        returns (int128, int128)
    {
        int128 _ut_sq_2 = ABDKMath64x64.div(_ut_sq, 
            ABDKMath64x64.fromUInt(_interval.mul(ETHEREUM_BLOCK_TIMESPAN)));

        int128 _new_sigma_sq = ABDKMath64x64.add(
            ABDKMath64x64.mul(ABDKMath64x64.divu(95, 100), _sigma_sq),
            ABDKMath64x64.mul(ABDKMath64x64.divu(5,100), _ut_sq_2));

        int128 _new_ut_sq;
        _new_ut_sq = ABDKMath64x64.pow(ABDKMath64x64.sub(
                    ABDKMath64x64.divu(tokenA1, tokenA0), 
                    ABDKMath64x64.fromUInt(1)), 
                2);
        
        return (_new_sigma_sq, _new_ut_sq);
    }

    function _calcAvg(uint256 ethA, uint256 tokenA, uint256 _avg)
        private 
        pure
        returns(uint256)
    {
        uint256 _newP = tokenA.div(ethA);
        uint256 _newAvg;

        if (_avg == 0) {
            _newAvg = _newP;
        } else {
            _newAvg = (_avg.mul(95).div(100)).add(_newP.mul(5).div(100));
            // _newAvg = ABDKMath64x64.add(
            //     ABDKMath64x64.mul(ABDKMath64x64.divu(95, 100), _avg),
            //     ABDKMath64x64.mul(ABDKMath64x64.divu(5,100), _newP));
        }

        return _newAvg;
    }

    function _moveAndCalc(
            MiningV1Data.PriceInfo memory p0,
            MiningV1Data.PriceSheet[] storage pL,
            uint256 priceDurationBlock
        )
        private
        view
        returns (MiningV1Data.PriceInfo memory)
    {
        uint256 i = p0.index + 1;
        if (i >= pL.length) {
            return (MiningV1Data.PriceInfo(0,0,0,0,0,int128(0),int128(0), uint128(0), 0));
        }

        uint256 h = uint256(pL[i].height);
        if (h + priceDurationBlock >= block.number) {
            return (MiningV1Data.PriceInfo(0,0,0,0,0,int128(0),int128(0), uint128(0), 0));
        }

        uint256 ethA1 = 0;
        uint256 tokenA1 = 0;
        while (i < pL.length && pL[i].height == h) {
            uint256 _remain = uint256(pL[i].remainNum);
            if (_remain == 0) {
                i = i + 1;
                continue;  // jump over a bitten sheet
            }
            ethA1 = ethA1 + _remain;
            tokenA1 = tokenA1 + _remain.mul(pL[i].tokenAmountPerEth);
            i = i + 1;
        }
        i = i - 1;

        if (ethA1 == 0 || tokenA1 == 0) {
            return (MiningV1Data.PriceInfo(
                    uint32(i),  // index
                    uint32(0),  // height
                    uint32(0),  // ethNum
                    uint32(0),  // _reserved
                    uint32(0),  // tokenAmount
                    int128(0),  // volatility_sigma_sq
                    int128(0),  // volatility_ut_sq
                    uint128(0),  // avgTokenAmount
                    0           // _reserved2
            ));
        }
        int128 new_sigma_sq;
        int128 new_ut_sq;
        {
            if (uint256(p0.ethNum) != 0) {
                (new_sigma_sq, new_ut_sq) = _calcVola(
                    uint256(p0.tokenAmount).div(uint256(p0.ethNum)), 
                    uint256(tokenA1).div(uint256(ethA1)),
                p0.volatility_sigma_sq, p0.volatility_ut_sq,
                h - p0.height);
            }
        }
        uint256 _newAvg = _calcAvg(ethA1, tokenA1, p0.avgTokenAmount); 

        return(MiningV1Data.PriceInfo(
                uint32(i),          // index
                uint32(h),          // height
                uint32(ethA1),      // ethNum
                uint32(0),          // _reserved
                uint128(tokenA1),   // tokenAmount
                new_sigma_sq,       // volatility_sigma_sq
                new_ut_sq,          // volatility_ut_sq
                uint128(_newAvg),   // avgTokenAmount
                uint128(0)          // _reserved2
        ));
    }

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    ///     Different from `_statOneBlock()`, it may cross multiple blocks.
    function _stat(MiningV1Data.State storage state, address token)
        external 
    {
        MiningV1Data.PriceInfo memory p0 = state.priceInfo[token];
        MiningV1Data.PriceSheet[] storage pL = state.priceSheetList[token];

        if (pL.length < 2) {
            return;
        }

        if (p0.height == 0) {

            MiningV1Data.PriceSheet memory _sheet = pL[0];
            p0.ethNum = _sheet.ethNum;
            p0.tokenAmount = uint128(uint256(_sheet.tokenAmountPerEth).mul(_sheet.ethNum));
            p0.height = _sheet.height;
            p0.volatility_sigma_sq = 0;
            p0.volatility_ut_sq = 0;
            p0.avgTokenAmount = uint128(_sheet.tokenAmountPerEth);
            // write back
            state.priceInfo[token] = p0;
        }

        MiningV1Data.PriceInfo memory p1;

        // record the gas usage
        uint256 startGas = gasleft();
        uint256 gasUsed;

        while (uint256(p0.index) < pL.length && uint256(p0.height) + state.priceDurationBlock < block.number){
            gasUsed = startGas - gasleft();
            // NOTE: check gas usage to prevent DOS attacks
            if (gasUsed > 1_000_000) {
                break; 
            }
            p1 = _moveAndCalc(p0, pL, state.priceDurationBlock);
            if (p1.index <= p0.index) {    // bootstraping
                break;
            } else if (p1.ethNum == 0) {   // jump cross a block with bitten prices
                p0.index = p1.index;
                continue;
            } else {                       // calculate one more block
                p0 = p1;
            }
        }

        if (p0.index > state.priceInfo[token].index) {
            state.priceInfo[token] = p0;
        }

        return;
    }

    /// @dev The function updates the statistics of price sheets across only one block.
    function _statOneBlock(MiningV1Data.State storage state, address token) 
        external 
    {
        MiningV1Data.PriceInfo memory p0 = state.priceInfo[token];
        MiningV1Data.PriceSheet[] storage pL = state.priceSheetList[token];
        if (pL.length < 2) {
            return;
        }
        (MiningV1Data.PriceInfo memory p1) = _moveAndCalc(p0, state.priceSheetList[token], state.priceDurationBlock);
        if (p1.index > p0.index && p1.ethNum != 0) {
            state.priceInfo[token] = p1;
        } else if (p1.index > p0.index && p1.ethNum == 0) {
            p0.index = p1.index;
            state.priceInfo[token] = p1;
        }
        return;
    }

    /// @notice Return a consecutive price list for a token 
    /// @dev 
    /// @param token The address of token contract
    /// @param num   The length of price list
    function _priceListOfToken(
            MiningV1Data.State storage state, 
            address token, 
            uint8 num
        )
        external 
        view
        returns (uint128[] memory data, uint256 bn) 
    {
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token];
        uint256 len = _list.length;
        uint256 _index = 0;
        data = new uint128[](num * 3);
        MiningV1Data.PriceSheet memory _sheet;
        uint256 _ethNum;

        // loop
        uint256 _curr = 0;
        uint256 _prev = 0;
        for (uint i = 1; i <= len; i++) {
            _sheet = _list[len - i];
            _curr = uint256(_sheet.height);
            if (_prev == 0) {
                if (_curr + state.priceDurationBlock < block.number) {
                    _ethNum = uint256(_sheet.remainNum);
                    if(_ethNum > 0) {
                        data[_index] = uint128(_curr + state.priceDurationBlock); // safe math
                        data[_index + 1] = uint128(_ethNum.mul(1 ether));
                        data[_index + 2] = uint128(_ethNum.mul(_sheet.tokenAmountPerEth));
                        bn = _curr + state.priceDurationBlock;  // safe math
                        _prev = _curr;
                    }
                }
            } else if (_prev == _curr) {
                _ethNum = uint256(_sheet.remainNum);
                data[_index + 1] += uint128(_ethNum.mul(1 ether));
                data[_index + 2] += uint128(_ethNum.mul(_sheet.tokenAmountPerEth));
            } else if (_prev > _curr) {
                _ethNum = uint256(_sheet.remainNum);
                if(_ethNum > 0){
                    _index += 3;
                    if (_index >= uint256(num * 3)) {
                        break;
                    }
                    data[_index] = uint128(_curr + state.priceDurationBlock); // safe math
                    data[_index + 1] = uint128(_ethNum.mul(1 ether));
                    data[_index + 2] = uint128(_ethNum.mul(_sheet.tokenAmountPerEth));
                    _prev = _curr;
                }
            }
        } 
        // require (data.length == uint256(num * 3), "Incorrect price list length");
    }

    function _priceOfTokenAtHeight(
            MiningV1Data.State storage state, 
            address token, 
            uint64 atHeight
        )
        external 
        view 
        returns(uint256 ethAmount, uint256 tokenAmount, uint256 blockNum) 
    {
        require(atHeight <= block.number, "Nest:Mine:!height");

        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token];
        uint256 len = state.priceSheetList[token].length;
        MiningV1Data.PriceSheet memory _sheet;
        uint256 _ethNum;

        if (len == 0) {
            return (0, 0, 0);
        }

        uint256 _first = 0;
        uint256 _prev = 0;
        for (uint i = 1; i <= len; i++) {
            _sheet = _list[len - i];
            _first = uint256(_sheet.height);
            if (_prev == 0) {
                if (_first + state.priceDurationBlock < uint256(atHeight)) {
                    _ethNum = uint256(_sheet.remainNum);
                    if (_ethNum == 0) {
                        continue; // jump over a bitten sheet
                    }
                    ethAmount = _ethNum.mul(1 ether);
                    tokenAmount = _ethNum.mul(_sheet.tokenAmountPerEth);
                    blockNum = _first + state.priceDurationBlock;
                    _prev = _first;
                }
            } else if (_first == _prev) {
                _ethNum = uint256(_sheet.remainNum);
                ethAmount = ethAmount.add(_ethNum.mul(1 ether));
                tokenAmount = tokenAmount.add(_ethNum.mul(_sheet.tokenAmountPerEth));
            } else if (_prev > _first) {
                break;
            }
        }
    }

    function _priceSheet(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index
        ) 
        view external 
        returns (MiningV1Data.PriceSheetPub memory sheet) 
    {
        uint256 len = state.priceSheetList[token].length;
        require (index < len, "Nest:Mine:!index");
        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index];
        sheet.miner = _sheet.miner;
        sheet.height = _sheet.height;
        sheet.ethNum = _sheet.ethNum;
        sheet.typ = _sheet.typ;
        sheet.state = _sheet.state;
        sheet.ethNumBal = _sheet.ethNumBal;
        sheet.tokenNumBal = _sheet.tokenNumBal;
    }

    
    function unVerifiedSheetList(
            MiningV1Data.State storage state, 
            address token
        ) 
        view 
        public
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token]; 
        uint256 len = _list.length;
        uint256 num;
        for (uint i = 0; i < len; i++) {
            if (_list[len - 1 - i].height + state.priceDurationBlock < block.number) {
                break;
            }
            num += 1;
        }

        sheets = new MiningV1Data.PriceSheetPub2[](num);
        for (uint i = 0; i < num; i++) {
            MiningV1Data.PriceSheet memory _sheet = _list[len - 1 - i];
            if (uint256(_sheet.height) + state.priceDurationBlock < block.number) {
                break;
            }
            //sheets[i] = _sheet;
            sheets[i].miner = _sheet.miner;
            sheets[i].height = _sheet.height;
            sheets[i].ethNum = _sheet.ethNum;
            sheets[i].remainNum = _sheet.remainNum;
            sheets[i].level = _sheet.level;
            sheets[i].typ = _sheet.typ;
            sheets[i].state = _sheet.state;

            sheets[i].index = len - 1 - i;

            sheets[i].nestNum1k = _sheet.nestNum1k;
            sheets[i].tokenAmountPerEth = _sheet.tokenAmountPerEth;
        }
    }

    function unClosedSheetListOf(
            MiningV1Data.State storage state, 
            address miner, 
            address token, 
            uint256 fromIndex, 
            uint256 num) 
        view 
        external
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        sheets = new MiningV1Data.PriceSheetPub2[](num);
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token]; 
        uint256 len = _list.length;
        require(fromIndex < len, "Nest:Mine:!from");

        for (uint i = 0; i < num; i++) {
            if (fromIndex < i) {
                break;
            }

            MiningV1Data.PriceSheet memory _sheet = _list[fromIndex - i];
            if (uint256(_sheet.miner) == uint256(miner)
                && (_sheet.state == MiningV1Data.PRICESHEET_STATE_POSTED 
                    || _sheet.state == MiningV1Data.PRICESHEET_STATE_BITTEN)) {
            
                sheets[i].miner = _sheet.miner;
                sheets[i].height = _sheet.height;
                sheets[i].ethNum = _sheet.ethNum;
                sheets[i].remainNum = _sheet.remainNum;
                sheets[i].level = _sheet.level;
                sheets[i].typ = _sheet.typ;
                sheets[i].state = _sheet.state;

                sheets[i].index = fromIndex - i;

                sheets[i].nestNum1k = _sheet.nestNum1k;
                sheets[i].tokenAmountPerEth = _sheet.tokenAmountPerEth;

            }
        }
    }

    function sheetListOf(
           MiningV1Data.State storage state, 
           address miner, 
           address token, 
           uint256 fromIndex, 
           uint256 num
        ) 
        view 
        external
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        sheets = new MiningV1Data.PriceSheetPub2[](num);
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token]; 
        uint256 len = _list.length;
        require(fromIndex < len, "Nest:Mine:!from");

        for (uint i = 0; i < num; i++) {
            if (fromIndex < i) {
                break;
            }
            MiningV1Data.PriceSheet memory _sheet = _list[fromIndex - i];
            if (uint256(_sheet.miner) == uint256(miner)) {
            
                sheets[i].miner = _sheet.miner;
                sheets[i].height = _sheet.height;
                sheets[i].ethNum = _sheet.ethNum;
                sheets[i].remainNum = _sheet.remainNum;
                sheets[i].level = _sheet.level;
                sheets[i].typ = _sheet.typ;
                sheets[i].state = _sheet.state;

                sheets[i].index = fromIndex - i;
                sheets[i].nestNum1k = _sheet.nestNum1k;
                sheets[i].tokenAmountPerEth = _sheet.tokenAmountPerEth;

            }
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-zero");
        z = x / y;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

import "./Address.sol";
import "./SafeMath.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: Copyright © 2019 by ABDK Consulting

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.6.12;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /**
   * @dev Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /**
   * @dev Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m), uint256 (x) + uint256 (y) >> 1));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64, 0x10000000000000000));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << 127 - msb;
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= 63 - (x >> 64);
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= xe;
      else x <<= -xe;

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= re;
      else if (re < 0) result >>= -re;

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x, uint256 r) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      require (r > 0);
      while (true) {
        uint256 rr = x / r;
        if (r == rr || r + 1 == rr) return uint128 (r);
        else if (r == rr + 1) return uint128 (rr);
        r = r + rr + 1 >> 1;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "../lib/SafeERC20.sol";

interface INestPool {

    // function getNTokenFromToken(address token) view external returns (address);
    // function setNTokenToToken(address token, address ntoken) external; 

    function addNest(address miner, uint256 amount) external;
    function addNToken(address contributor, address ntoken, uint256 amount) external;

    function depositEth(address miner) external payable;
    function depositNToken(address miner,  address from, address ntoken, uint256 amount) external;

    function freezeEth(address miner, uint256 ethAmount) external; 
    function unfreezeEth(address miner, uint256 ethAmount) external;

    function freezeNest(address miner, uint256 nestAmount) external;
    function unfreezeNest(address miner, uint256 nestAmount) external;

    function freezeToken(address miner, address token, uint256 tokenAmount) external; 
    function unfreezeToken(address miner, address token, uint256 tokenAmount) external;

    function freezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;
    function unfreezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;

    function getNTokenFromToken(address token) external view returns (address); 
    function setNTokenToToken(address token, address ntoken) external; 

    function withdrawEth(address miner, uint256 ethAmount) external;
    function withdrawToken(address miner, address token, uint256 tokenAmount) external;

    function withdrawNest(address miner, uint256 amount) external;
    function withdrawEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;
    // function withdrawNToken(address miner, address ntoken, uint256 amount) external;
    function withdrawNTokenAndTransfer(address miner, address ntoken, uint256 amount, address to) external;


    function balanceOfNestInPool(address miner) external view returns (uint256);
    function balanceOfEthInPool(address miner) external view returns (uint256);
    function balanceOfTokenInPool(address miner, address token)  external view returns (uint256);

    function addrOfNestToken() external view returns (address);
    function addrOfNestMining() external view returns (address);
    function addrOfNTokenController() external view returns (address);
    function addrOfNNRewardPool() external view returns (address);
    function addrOfNNToken() external view returns (address);
    function addrOfNestStaking() external view returns (address);
    function addrOfNestQuery() external view returns (address);
    function addrOfNestDAO() external view returns (address);

    function addressOfBurnedNest() external view returns (address);

    function setGovernance(address _gov) external; 
    function governance() external view returns(address);
    function initNestLedger(uint256 amount) external;
    function drainNest(address to, uint256 amount, address gov) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;


interface INestStaking {
    // Views

    /// @dev How many stakingToken (XToken) deposited into to this reward pool (staking pool)
    /// @param  ntoken The address of NToken
    /// @return The total amount of XTokens deposited in this staking pool
    function totalStaked(address ntoken) external view returns (uint256);

    /// @dev How many stakingToken (XToken) deposited by the target account
    /// @param  ntoken The address of NToken
    /// @param  account The target account
    /// @return The total amount of XToken deposited in this staking pool
    function stakedBalanceOf(address ntoken, address account) external view returns (uint256);


    // Mutative
    /// @dev Stake/Deposit into the reward pool (staking pool)
    /// @param  ntoken The address of NToken
    /// @param  amount The target amount
    function stake(address ntoken, uint256 amount) external;

    function stakeFromNestPool(address ntoken, uint256 amount) external;

    /// @dev Withdraw from the reward pool (staking pool), get the original tokens back
    /// @param  ntoken The address of NToken
    /// @param  amount The target amount
    function unstake(address ntoken, uint256 amount) external;

    /// @dev Claim the reward the user earned
    /// @param ntoken The address of NToken
    /// @return The amount of ethers as rewards
    function claim(address ntoken) external returns (uint256);

    /// @dev Add ETH reward to the staking pool
    /// @param ntoken The address of NToken
    function addETHReward(address ntoken) external payable;

    /// @dev Only for governance
    function loadContracts() external; 

    /// @dev Only for governance
    function loadGovernance() external; 

    function pause() external;

    function resume() external;

    //function setParams(uint8 dividendShareRate) external;

    /* ========== EVENTS ========== */

    // Events
    event RewardAdded(address ntoken, address sender, uint256 reward);
    event NTokenStaked(address ntoken, address indexed user, uint256 amount);
    event NTokenUnstaked(address ntoken, address indexed user, uint256 amount);
    event SavingWithdrawn(address ntoken, address indexed to, uint256 amount);
    event RewardClaimed(address ntoken, address indexed user, uint256 reward);

    event FlagSet(address gov, uint256 flag);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface INToken {
    // mint ntoken for value
    function mint(uint256 amount, address account) external;

    // the block height where the ntoken was created
    function checkBlockInfo() external view returns(uint256 createBlock, uint256 recentlyUsedBlock);
    // the owner (auction winner) of the ntoken
    function checkBidder() external view returns(address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

/// @title NNRewardPool
/// @author Inf Loop - <[email protected]>
/// @author Paradox  - <[email protected]>

interface INNRewardPool {
    
    /* [DEPRECATED]
        uint256 constant DEV_REWARD_PERCENTAGE   = 5;
        uint256 constant NN_REWARD_PERCENTAGE    = 15;
        uint256 constant MINER_REWARD_PERCENTAGE = 80;
    */

    /// @notice Add rewards for Nest-Nodes, only governance or NestMining (contract) are allowed
    /// @dev  The rewards need to pull from NestPool
    /// @param _amount The amount of Nest token as the rewards to each nest-node
    function addNNReward(uint256 _amount) external;

    /// @notice Claim rewards by Nest-Nodes
    /// @dev The rewards need to pull from NestPool
    function claimNNReward() external ;  

    /// @dev The callback function called by NNToken.transfer()
    /// @param fromAdd The address of 'from' to transfer
    /// @param toAdd The address of 'to' to transfer
    function nodeCount(address fromAdd, address toAdd) external;

    /// @notice Show the amount of rewards unclaimed
    /// @return reward The reward of a NN holder
    function unclaimedNNReward() external view returns (uint256 reward);

    /// @dev Only for governance
    function loadContracts() external; 

    /// @dev Only for governance
    function loadGovernance() external; 

    /* ========== EVENTS ============== */

    /// @notice When rewards are added to the pool
    /// @param reward The amount of Nest Token
    /// @param allRewards The snapshot of all rewards accumulated
    event NNRewardAdded(uint256 reward, uint256 allRewards);

    /// @notice When rewards are claimed by nodes 
    /// @param nnode The address of the nest node
    /// @param share The amount of Nest Token claimed by the nest node
    event NNRewardClaimed(address nnode, uint256 share);

    /// @notice When flag of state is set by governance 
    /// @param gov The address of the governance
    /// @param flag The value of the new flag
    event FlagSet(address gov, uint256 flag);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;


import "../iface/INestPool.sol";
import "../iface/INestStaking.sol";
import "../iface/INToken.sol";
import "../iface/INNRewardPool.sol";

import "../lib/SafeERC20.sol";


/// @author Inf Loop - <[email protected]>
/// @author 0x00  - <[email protected]>
library MiningV1Data {

    /* ========== CONSTANTS ========== */

    uint256 constant MINING_NEST_YIELD_CUTBACK_PERIOD = 2400000; // ~ 1 years 
    uint256 constant MINING_NEST_YIELD_CUTBACK_RATE = 80;     // percentage = 80%

    // yield amount (per block) after the first ten years
    uint256 constant MINING_NEST_YIELD_OFF_PERIOD_AMOUNT = 40 ether;
    // yield amount (per block) in the first year, it drops to 80% in the following nine years
    uint256 constant MINING_NEST_YIELD_PER_BLOCK_BASE = 400 ether;

    uint256 constant MINING_NTOKEN_YIELD_CUTBACK_RATE = 80;
    uint256 constant MINING_NTOKEN_YIELD_OFF_PERIOD_AMOUNT = 0.4 ether;
    uint256 constant MINING_NTOKEN_YIELD_PER_BLOCK_BASE = 4 ether;

    uint256 constant MINING_FINAL_BLOCK_NUMBER = 173121488;


    uint256 constant MINING_NEST_FEE_DIVIDEND_RATE = 80;    // percentage = 80%
    uint256 constant MINING_NEST_FEE_DAO_RATE = 20;         // percentage = 20%

    uint256 constant MINING_NTOKEN_FEE_DIVIDEND_RATE        = 60;     // percentage = 60%
    uint256 constant MINING_NTOKEN_FEE_DAO_RATE             = 20;     // percentage = 20%
    uint256 constant MINING_NTOKEN_FEE_NEST_DAO_RATE        = 20;     // percentage = 20%

    uint256 constant MINING_NTOKEN_YIELD_BLOCK_LIMIT = 100;

    uint256 constant NN_NEST_REWARD_PERCENTAGE = 15;
    uint256 constant DAO_NEST_REWARD_PERCENTAGE = 5;
    uint256 constant MINER_NEST_REWARD_PERCENTAGE = 80;

    uint256 constant MINING_LEGACY_NTOKEN_MINER_REWARD_PERCENTAGE = 95;
    uint256 constant MINING_LEGACY_NTOKEN_BIDDER_REWARD_PERCENTAGE = 5;

    uint8 constant PRICESHEET_STATE_CLOSED = 0;
    uint8 constant PRICESHEET_STATE_POSTED = 1;
    uint8 constant PRICESHEET_STATE_BITTEN = 2;

    uint8 constant PRICESHEET_TYPE_USD     = 1;
    uint8 constant PRICESHEET_TYPE_NEST    = 2;
    uint8 constant PRICESHEET_TYPE_TOKEN   = 3;
    uint8 constant PRICESHEET_TYPE_NTOKEN  = 4;
    uint8 constant PRICESHEET_TYPE_BITTING = 8;


    uint8 constant STATE_FLAG_UNINITIALIZED    = 0;
    uint8 constant STATE_FLAG_SETUP_NEEDED     = 1;
    uint8 constant STATE_FLAG_ACTIVE           = 3;
    uint8 constant STATE_FLAG_MINING_STOPPED   = 4;
    uint8 constant STATE_FLAG_CLOSING_STOPPED  = 5;
    uint8 constant STATE_FLAG_WITHDRAW_STOPPED = 6;
    uint8 constant STATE_FLAG_PRICE_STOPPED    = 7;
    uint8 constant STATE_FLAG_SHUTDOWN         = 127;

    uint256 constant MINING_NTOKEN_NON_DUAL_POST_THRESHOLD = 5_000_000 ether;


    /// @dev size: (2 x 256 bit)
    struct PriceSheet {    
        uint160 miner;       //  miner who posted the price (most significant bits, or left-most)
        uint32  height;      //
        uint32  ethNum;   
        uint32  remainNum;    

        uint8   level;           // the level of bitting, 1-4: eth-doubling | 5 - 127: nest-doubling
        uint8   typ;             // 1: USD | 2: NEST | 3: TOKEN | 4: NTOKEN
        uint8   state;           // 0: closed | 1: posted | 2: bitten
        uint8   _reserved;       // for padding
        uint32  ethNumBal;
        uint32  tokenNumBal;
        uint32  nestNum1k;
        uint128 tokenAmountPerEth;
    }
    
    /// @dev size: (3 x 256 bit)
    struct PriceInfo {
        uint32  index;
        uint32  height;         // NOTE: the height of being posted
        uint32  ethNum;         //  the balance of eth
        uint32  _reserved;
        uint128 tokenAmount;    //  the balance of token 
        int128  volatility_sigma_sq;
        int128  volatility_ut_sq;
        uint128  avgTokenAmount;  // avg = (tokenAmount : perEth)
        uint128 _reserved2;     
    }


    /// @dev The struct is for public data in a price sheet, so as to protect prices from being read
    struct PriceSheetPub {
        uint160 miner;       //  miner who posted the price (most significant bits, or left-most)
        uint32  height;
        uint32  ethNum;   

        uint8   typ;             // 1: USD | 2: NEST | 3: TOKEN | 4: NTOKEN(Not Available)
        uint8   state;           // 0: closed | 1: posted | 2: bitten
        uint32  ethNumBal;
        uint32  tokenNumBal;
    }


    struct PriceSheetPub2 {
        uint160 miner;       //  miner who posted the price (most significant bits, or left-most)
        uint32  height;
        uint32  ethNum;   
        uint32  remainNum; 

        uint8   level;           // the level of bitting, 1-4: eth-doubling | 5 - 127: nest-doubling
        uint8   typ;             // 1: USD | 2: NEST | 3: TOKEN | 4: NTOKEN(Not Available)
        uint8   state;           // 0: closed | 1: posted | 2: bitten
        uint256 index;           // return to the quotation of index
        uint32  nestNum1k;
        uint128 tokenAmountPerEth;   
    }

    /* ========== EVENTS ========== */

    event PricePosted(address miner, address token, uint256 index, uint256 ethAmount, uint256 tokenAmount);
    event PriceClosed(address miner, address token, uint256 index);
    event Deposit(address miner, address token, uint256 amount);
    event Withdraw(address miner, address token, uint256 amount);
    event TokenBought(address miner, address token, uint256 index, uint256 biteEthAmount, uint256 biteTokenAmount);
    event TokenSold(address miner, address token, uint256 index, uint256 biteEthAmount, uint256 biteTokenAmount);

    event VolaComputed(uint32 h, uint32 pos, uint32 ethA, uint128 tokenA, int128 sigma_sq, int128 ut_sq);

    event SetParams(uint8 miningEthUnit, uint32 nestStakedNum1k, uint8 biteFeeRate,
                    uint8 miningFeeRate, uint8 priceDurationBlock, uint8 maxBiteNestedLevel,
                    uint8 biteInflateFactor, uint8 biteNestInflateFactor);

    // event GovSet(address oldGov, address newGov);

    /* ========== GIANT STATE VARIABLE ========== */

    struct State {
        // TODO: more comments

        uint8   miningEthUnit;      // = 30 on mainnet;
        uint32  nestStakedNum1k;    // = 100;
        uint8   biteFeeRate;        // 
        uint8   miningFeeRate;      // = 10;  
        uint8   priceDurationBlock; // = 25;
        uint8   maxBiteNestedLevel; // = 3;
        uint8   biteInflateFactor;  // = 2;
        uint8   biteNestInflateFactor; // = 2;

        uint32  genesisBlock;       // = 6236588;

        uint128  latestMiningHeight;  // latest block number of NEST mining
        uint128  minedNestAmount;     // the total amount of mined NEST
        
        address  _developer_address;  // WARNING: DO NOT delete this unused variable
        address  _NN_address;         // WARNING: DO NOT delete this unused variable

        address  C_NestPool;
        address  C_NestToken;
        address  C_NestStaking;
        address  C_NNRewardPool;
        address  C_NestQuery;
        address  C_NestDAO;

        uint256[10] _mining_nest_yield_per_block_amount;
        uint256[10] _mining_ntoken_yield_per_block_amount;

        // A mapping (from token(address) to an array of PriceSheet)
        mapping(address => PriceSheet[]) priceSheetList;

        // from token(address) to Price
        mapping(address => PriceInfo) priceInfo;

        // (token-address, block-number) => (ethFee-total, nest/ntoken-mined-total)
        mapping(address => mapping(uint256 => uint256)) minedAtHeight;

        // WARNING: DO NOT delete these variables, reserved for future use
        uint256  _reserved1;
        uint256  _reserved2;
        uint256  _reserved3;
        uint256  _reserved4;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}