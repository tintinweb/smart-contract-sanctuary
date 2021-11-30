// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ISwapStrategy01.sol";
import "./../RLib/StringUtilsLib.sol";



contract SwapStrategy01 is ISwapStrategy01 {    

    using StringUtilsLib for *;
    mapping(string => address) public coin;
    constructor() {
        coin["WMATIC"] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        coin["WETH"] = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        coin["DAI"] = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        coin["WBTC"] = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
        coin["USDC"] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    }



    function swapByIndex03( uint256 _amountIn, address _router, address[] memory path ) public override returns(uint256 amountOut) {
        IERC20 SToken = IERC20(path[0]);
        IUniswapV2Router02 router = IUniswapV2Router02(_router);

        require( SToken.allowance(msg.sender, address(this)) >= _amountIn, "allowance error" );

        if (SToken.allowance(address(this), address(router)) < _amountIn) {
            require(SToken.approve( address(router) , type(uint256).max), "approve error");
        }

        // SEND TO
        require(SToken.transferFrom(
            msg.sender,
            address(this),
            _amountIn
        ), "send error");

        /*
        uint256[] memory _amountOut = router.getAmountsOut(_amountIn, path);
        amountOut = _amountOut[_amountOut.length - 1];
        */

        router.swapExactTokensForTokens(
            _amountIn, 
            0, 
            path, 
            address(this),
            block.timestamp
        );

        amountOut = SToken.balanceOf(address(this));

        // SEND OUT
        SToken.transfer(msg.sender, amountOut);
    }



    function swapByIndex02( uint256 _amountIn, address _router, address[] memory path ) public override returns(uint256 amountOut) {
        IERC20 SToken = IERC20(path[0]);
        IUniswapV2Router02 router = IUniswapV2Router02(_router);

        require( SToken.allowance(msg.sender, address(this)) < _amountIn, "allowance error" );

        if (SToken.allowance(address(this), address(router)) < _amountIn) {
            require(SToken.approve( address(router) , type(uint256).max), "approve error");
        }

        // SEND TO
        require(SToken.transferFrom(
            msg.sender,
            address(this),
            _amountIn
        ), "send error");

        uint256[] memory _amountOut = router.getAmountsOut(_amountIn, path);
        amountOut = _amountOut[_amountOut.length - 1];
        router.swapExactTokensForTokens(
            _amountIn, 
            amountOut, 
            path, 
            address(this),
            block.timestamp
        );

        // SEND OUT
        SToken.transfer(msg.sender, amountOut);
    }

    function swapByIndex( uint256 _amountIn, address _router, address[] memory path ) public override returns(uint256 amountOut) {
        IERC20 SToken = IERC20(path[0]);
        IUniswapV2Router02 router = IUniswapV2Router02(_router);    
        if (SToken.allowance(address(this), address(router)) < _amountIn) {
            require(SToken.approve( address(router) , type(uint256).max), "approve error");
        }
        uint256[] memory _amountOut = router.getAmountsOut(_amountIn, path);
        amountOut = _amountOut[_amountOut.length - 1];
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn, 
            amountOut, 
            path, 
            address(this),
            block.timestamp
        );        
    }

    function swapTo( string memory Coin, uint256 _amountIn ) public override returns(uint256 amountOut) {
        address[] memory path;
        if (Coin.toSlice().equals("WBTC".toSlice())) {
            path[0] = coin["WMATIC"];
            path[1] = coin["WETH"];
            path[2] = coin["WBTC"];
        } else if (Coin.toSlice().equals("DAI".toSlice())) {
            path[0] = coin["WMATIC"];
            path[1] = coin["WETH"];
            path[2] = coin["DAI"];
        } else if (Coin.toSlice().equals("USDC".toSlice())) {
            path[0] = coin["WMATIC"];
            path[1] = coin["WETH"];
            path[2] = coin["USDC"];
        }
        // SUSHI SWAP
        address router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        ( amountOut ) = swapByIndex( _amountIn, router, path );
    }

    // swapETHForExactTokens
    // https://polygonscan.com/tx/0x15b1e8ee48d642f4c2f9767bfe1892f9270040e6b7304c938f98413640537179
    function swapToWBTC( uint256 _amountIn ) public override returns(uint256 amountOut) {
        // WMATIC -> WETH -> WBTC
        address[] memory path;
        path[0] = coin["WMATIC"];
        path[1] = coin["WETH"];
        path[2] = coin["WBTC"];

        address router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        ( amountOut ) = swapByIndex( _amountIn, router, path );
    }

    function swapToDAI( uint256 _amountIn ) public override returns(uint256 amountOut) {
        // WMATIC -> WETH -> WBTC
        address[] memory path;
        path[0] = coin["WMATIC"];
        path[1] = coin["WETH"];
        path[2] = coin["DAI"];

        address router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        ( amountOut ) = swapByIndex( _amountIn, router, path );
    }

    function swapToUSDC( uint256 _amountIn ) public override returns(uint256 amountOut) {
        // WMATIC -> WETH -> WBTC
        address[] memory path;
        path[0] = coin["WMATIC"];
        path[1] = coin["WETH"];
        path[2] = coin["USDC"];
    
        address router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        ( amountOut ) = swapByIndex( _amountIn, router, path );
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface ISwapStrategy01 {
    function swapToWBTC( uint256 _amountIn ) external returns(uint256 amountOut);
    function swapToDAI( uint256 _amountIn ) external returns(uint256 amountOut);
    function swapToUSDC( uint256 _amountIn ) external returns(uint256 amountOut);
    function swapByIndex( uint256 _amountIn, address _router, address[] memory path ) external returns(uint256 amountOut);
    
    function swapTo( string memory Coin, uint256 _amountIn ) external returns(uint256 amountOut);

    function swapByIndex02( uint256 _amountIn, address _router, address[] memory path ) external returns(uint256 amountOut);
    function swapByIndex03( uint256 _amountIn, address _router, address[] memory path ) external returns(uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 * @author Smart Insider <[email protected]>
 *
 * version 1.2.2
 * updated from 0.4.21 to version 0.8.4
 *
 * version 1.2.1
 * Copyright 2016 Nick Johnson
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * This utility library was forked from https://github.com/Arachnid/solidity-stringutils
 * into the Modular ethereum-libraries repo at https://github.com/Modular-Network/ethereum-libraries
 * with permission. It has been updated to be more compatible with solidity 0.4.18
 * coding patterns.
 *
 * Modular provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: modular.network
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

library StringUtilsLib {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint lenx) private pure {
        // Copy word-length chunks while possible
        for(; lenx >= 32; lenx -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - lenx) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & bytes32(uint(0xffffffffffffffffffffffffffffffff)) == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & bytes32(uint(0xffffffffffffffff)) == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & bytes32(uint(0xffffffff)) == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & bytes32(uint(0xffff)) == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & bytes32(uint(0xff)) == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-termintaed utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */

    function len(slice memory self) internal pure returns (uint) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint256 ptr = self._ptr - 31;
        uint256 end = ptr + self._len;
        uint Len0 = 0;
        for (uint Len = 0; ptr < end; Len++) {
            Len0 = Len;
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
        return Len0;
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint256 selfptr = self._ptr;
        uint256 otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `rune`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint Len;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            Len = 1;
        } else if(b < 0xE0) {
            Len = 2;
        } else if(b < 0xF0) {
            Len = 3;
        } else {
            Len = 4;
        }

        // Check for truncated codepoints
        if (Len > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += Len;
        self._len -= Len;
        rune._len = Len;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint Len;
        uint Div = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint256 b = word / Div;
        if (b < 0x80) {
            ret = b;
            Len = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            Len = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            Len = 3;
        } else {
            ret = b & 0x07;
            Len = 4;
        }

        // Check for truncated codepoints
        if (Len > self._len) {
            return 0;
        }

        for (uint i = 1; i < Len; i++) {
            Div = Div / 256;
            b = (word / Div) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let lenx := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, lenx), keccak256(needleptr, lenx))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let lenx := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, lenx), keccak256(needleptr, lenx))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let lenx := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, lenx), keccak256(needleptr, lenx))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let lenx := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, lenx), keccak256(needleptr, lenx))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr)
      private
      pure
      returns (uint)
    {
        uint ptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                // Optimized assembly for 68 gas per byte on short strings
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let end := add(selfptr, sub(selflen, needlelen))
                    let loop := selfptr

                    for { } lt(loop, end) { } {
                        switch eq(and(mload(loop), mask), needledata)
                        case 1 {
                            ptr := loop
                            loop := end
                        }
                        case 0 {
                            loop := add(loop,1)
                        }
                    }
                    switch eq(and(mload(ptr), mask), needledata)
                    case 0 {
                        ptr := add(selfptr, selflen)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr;
                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr)
      private
      pure
      returns (uint)
    {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                // Optimized assembly for 69 gas per byte on short strings
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let loop := add(selfptr, sub(selflen, needlelen))

                    for { } gt(loop, selfptr) { } {
                        switch eq(and(mload(loop), mask), needledata)
                        case 1 {
                            ptr := loop
                            loop := selfptr
                        }
                        case 0 {
                            loop := sub(loop,1)
                        }
                    }
                    switch eq(and(mload(ptr), mask), needledata)
                    case 1 {
                        ptr := add(ptr, needlelen)
                    }
                    case 0 {
                        ptr := selfptr
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint Count) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            Count++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint Len = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            Len += parts[i]._len;

        string memory ret = new string(Len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}