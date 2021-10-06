/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/libs/TransferHelper.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/libs/StringHelper.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 字符串工具
library StringHelper {

    /// @dev 将字符串转为大写形式
    /// @param str 目标字符串
    /// @return 目标字符串的大写
    function toUpper(string memory str) internal pure returns (string memory) 
    {
        bytes memory bs = bytes(str);
        for (uint i = 0; i < bs.length; ++i) {
            uint b = uint(uint8(bytes1(bs[i])));
            if (b >= 97 && b <= 122) {
                bs[i] = bytes1(uint8(b - 32));
            }
        }
        return str;
    }

    /// @dev 将字符串转为小写形式
    /// @param str 目标字符串
    /// @return 目标字符串的小写
    function toLower(string memory str) internal pure returns (string memory) 
    {
        bytes memory bs = bytes(str);
        for (uint i = 0; i < bs.length; ++i) {
            uint b = uint(uint8(bytes1(bs[i])));
            if (b >= 65 && b <= 90) {
                bs[i] = bytes1(uint8(b + 32));
            }
        }
        return str;
    }

    /// @dev 截取字符串
    /// @param str 目标字符串
    /// @param start 截取开始索引
    /// @param count 截取长度（如果长度不够，则取剩余长度）
    /// @return 截取结果
    function substring(string memory str, uint start, uint count) internal pure returns (string memory) 
    {
        bytes memory bs = bytes(str);
        uint length = bs.length;
        if (start >= length) {
            count = 0;
        } else if (start + count > length) {
            count = length - start;
        }
        bytes memory buffer = new bytes(count);
        while (count > 0) {
            --count;
            buffer[count] = bs[start + count];
        }
        return string(buffer);
    }

    /// @dev 截取字符串
    /// @param str 目标字符串
    /// @param start 截取开始索引
    /// @return 截取结果
    function substring(string memory str, uint start) internal pure returns (string memory) 
    {
        bytes memory bs = bytes(str);
        uint length = bs.length;
        uint count = 0;
        if (start < length) {
            count = length - start;
        }
        bytes memory buffer = new bytes(count);
        while (count > 0) {
            --count;
            buffer[count] = bs[start + count];
        }
        return string(buffer);
    }

    /// @dev 将整形转化为十进制字符串并写入内存数组，如果长度小于指定长度，则在前面补0
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param iv 要转化的整形值
    /// @param minLength 最小长度
    /// @return 写入后的新的内存数组偏移位置
    function writeUIntDec(bytes memory buffer, uint index, uint iv, uint minLength) internal pure returns (uint) 
    {
        uint i = index;
        minLength += index;
        while (iv > 0 || index < minLength) {
            buffer[index++] = bytes1(uint8(iv % 10 + 48));
            iv /= 10;
        }

        for (uint j = index; j > i;) {
            bytes1 tmp = buffer[i];
            buffer[i++] = buffer[--j];
            buffer[j] = tmp;
        }

        return index;
    }

    /// @dev 将整形转化为十进制字符串并写入内存数组，如果长度小于指定长度，则在前面补0
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param fv 要转化的浮点值
    /// @param decimals 小数位数
    /// @return 写入后的新的内存数组偏移位置
    function writeFloat(bytes memory buffer, uint index, uint fv, uint decimals) internal pure returns (uint) 
    {
        uint base = 10 ** decimals;
        index = writeUIntDec(buffer, index, fv / base, 1);
        buffer[index++] = bytes1(uint8(46));
        index = writeUIntDec(buffer, index, fv % base, decimals);

        return index;
    }
    
    /// @dev 将整形转化为十六进制字符串并写入内存数组，如果长度小于指定长度，则在前面补0
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param iv 要转化的整形值
    /// @param minLength 最小长度
    /// @param upper 是否大写
    /// @return 写入后的新的内存数组偏移位置
    function writeUIntHex(
        bytes memory buffer, 
        uint index, 
        uint iv, 
        uint minLength, 
        bool upper
    ) internal pure returns (uint) 
    {
        uint i = index;
        uint B = upper ? 55 : 87;
        minLength += index;
        while (iv > 0 || index < minLength) {
            uint c = iv & 0xF;
            if (c > 9) {
                buffer[index++] = bytes1(uint8(c + B));
            } else {
                buffer[index++] = bytes1(uint8(c + 48));
            }
            iv >>= 4;
        }

        for (uint j = index; j > i;) {
            bytes1 tmp = buffer[i];
            buffer[i++] = buffer[--j];
            buffer[j] = tmp;
        }

        return index;
    }

    /// @dev 截取字符串并写入内存数组
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param str 目标字符串
    /// @param start 截取开始索引
    /// @param count 截取长度（如果长度不够，则取剩余长度）
    /// @return 写入后的新的内存数组偏移位置
    function writeString(
        bytes memory buffer, 
        uint index, 
        string memory str, 
        uint start, 
        uint count
    ) private pure returns (uint) 
    {
        bytes memory bs = bytes(str);
        uint i = 0;
        while (i < count && start + i < bs.length) {
            buffer[index + i] = bs[start + i];
            ++i;
        }
        return index + i;
    }

    /// @dev 从内存数组中截取一段
    /// @param buffer 目标内存数组
    /// @param start 截取开始索引
    /// @param count 截取长度（如果长度不够，则取剩余长度）
    /// @return 截取结果
    function segment(bytes memory buffer, uint start, uint count) internal pure returns (bytes memory) 
    {
        uint length = buffer.length;
        if (start >= length) {
            count = 0;
        } else if (start + count > length) {
            count = length - start;
        }
        bytes memory re = new bytes(count);
        while (count > 0) {
            --count;
            re[count] = buffer[start + count];
        }
        return re;
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param arg0 参数0（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint arg0) internal pure returns (string memory) {
        return sprintf(format, [arg0, 0, 0, 0, 0]);
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param arg0 参数0（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg1 参数1（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint arg0, uint arg1) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, 0, 0, 0]);
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param arg0 参数0（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg1 参数1（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg2 参数2（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, 0, 0]);
    }
    
    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param arg0 参数0（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg1 参数1（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg2 参数2（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg3 参数3（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2, uint arg3) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, arg3, 0]);
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param arg0 参数0（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg1 参数1（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg2 参数2（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg3 参数3（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg4 参数4（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2, uint arg3, uint arg4) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, arg3, arg4]);
    }
    
    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param args 参数表（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint[5] memory args) internal pure returns (string memory) {
        bytes memory buffer = new bytes(127);
        uint index = sprintf(buffer, 0, bytes(format), args);
        return string(segment(buffer, 0, index));
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出到内存数组的指定位置
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param format 格式化描述字符串
    /// @param args 参数表（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 写入后的新的内存数组偏移位置
    function sprintf(
        bytes memory buffer, 
        uint index, 
        bytes memory format, 
        uint[5] memory args
    ) internal pure returns (uint) {

        uint i = 0;
        uint pi = 0;
        uint ai = 0;
        uint state = 0;
        uint w = 0;

        while (i < format.length) {
            uint c = uint(uint8(format[i]));
			// 0. 正常                                             
            if (state == 0) {
                // %
                if (c == 37) {
                    while (pi < i) {
                        buffer[index++] = format[pi++];
                    }
                    state = 1;
                }
                ++i;
            }
			// 1. 确认是否有 -
            else if (state == 1) {
                // %
                if (c == 37) {
                    buffer[index++] = bytes1(uint8(37));
                    pi = ++i;
                    state = 0;
                } else {
                    state = 3;
                }
            }
			// 3. 找数据宽度
            else if (state == 3) {
                while (c >= 48 && c <= 57) {
                    w = w * 10 + c - 48;
                    c = uint(uint8(format[++i]));
                }
                state = 4;
            }
            // 4. 找格式类型   
			else if (state == 4) {
                uint arg = args[ai++];
                // d
                if (c == 100) {
                    if (arg >> 255 == 1) {
                        buffer[index++] = bytes1(uint8(45));
                        arg = uint(-int(arg));
                    } else {
                        buffer[index++] = bytes1(uint8(43));
                    }
                    c = 117;
                }
                // u
                if (c == 117) {
                    index = writeUIntDec(buffer, index, arg, w == 0 ? 1 : w);
                }
                // x/X
                else if (c == 120 || c == 88) {
                    index = writeUIntHex(buffer, index, arg, w == 0 ? 1 : w, c == 88);
                }
                // s/S
                else if (c == 115 || c == 83) {
                    index = writeEncString(buffer, index, arg, 0, w == 0 ? 31 : w, c == 83 ? 1 : 0);
                }
                // f
                else if (c == 102) {
                    if (arg >> 255 == 1) {
                        buffer[index++] = bytes1(uint8(45));
                        arg = uint(-int(arg));
                    }
                    index = writeFloat(buffer, index, arg, w == 0 ? 8 : w);
                }
                pi = ++i;
                state = 0;
                w = 0;
            }
        }

        while (pi < i) {
            buffer[index++] = format[pi++];
        }

        return index;
    }

    /// @dev 将字符串编码成uint（字符串长度不能超过31）
    /// @param str 目标字符串
    /// @return 编码结果
    function enc(string memory str) public pure returns (uint) {

        uint i = bytes(str).length;
        require(i < 32, "StringHelper:string too long");
        uint v = 0;
        while (i > 0) {
            v = (v << 8) | uint(uint8(bytes(str)[--i]));
        }

        return (v << 8) | bytes(str).length;
    }

    /// @dev 将使用enc编码的uint解码成字符串
    /// @param v 使用enc编码过的字符串
    /// @return 解码结果
    function dec(uint v) public pure returns (string memory) {
        uint length = v & 0xFF;
        v >>= 8;
        bytes memory buffer = new bytes(length);
        for (uint i = 0; i < length;) {
            buffer[i++] = bytes1(uint8(v & 0xFF));
            v >>= 8;
        }
        return string(buffer);
    }

    /// @dev 将使用enc编码的uint解码成字符串
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param v 使用enc编码过的字符串
    /// @param start 截取开始索引
    /// @param count 截取长度（如果长度不够，则取剩余长度）
    /// @param charCase 字符的大小写，0不改变，1大小，2小写
    /// @return 写入后的新的内存数组偏移位置
    function writeEncString(
        bytes memory buffer, 
        uint index, 
        uint v, 
        uint start, 
        uint count,
        uint charCase
    ) public pure returns (uint) {

        uint length = (v & 0xFF) - start;
        if (length > count) {
            length = count;
        }
        v >>= (start + 1) << 3;
        while (length > 0) {
            uint c = v & 0xFF;
            if (charCase == 1 && c >= 97 && c <= 122) {
                c -= 32;
            } else if (charCase == 2 && c >= 65 && c <= 90) {
                c -= 32;
            }
            buffer[index++] = bytes1(uint8(c));
            v >>= 8;
            --length;
        }

        return index;
    }

    // ******** 使用abi编码解决动态参数问题 ******** //

    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param abiArgs 使用abi.encode()编码的参数数组
    /// @return 格式化结果
    function sprintf(string memory format, bytes memory abiArgs) internal pure returns (string memory) {
        bytes memory buffer = new bytes(127);
        uint index = sprintf(buffer, 0, bytes(format), abiArgs);
        return string(segment(buffer, 0, index));
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出到内存数组的指定位置
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param format 格式化描述字符串
    /// @param abiArgs 使用abi.encode()编码的参数数组
    /// @return 写入后的新的内存数组偏移位置
    function sprintf(
        bytes memory buffer, 
        uint index, 
        bytes memory format, 
        bytes memory abiArgs
    ) internal pure returns (uint) {

        uint i = 0;
        uint pi = 0;
        uint ai = 0;
        uint state = 0;
        uint w = 0;

        while (i < format.length) {
            uint c = uint(uint8(format[i]));
			// 0. 正常                                             
            if (state == 0) {
                // %
                if (c == 37) {
                    while (pi < i) {
                        buffer[index++] = format[pi++];
                    }
                    state = 1;
                }
                ++i;
            }
			// 1. 确认是否有 -
            else if (state == 1) {
                // %
                if (c == 37) {
                    buffer[index++] = bytes1(uint8(37));
                    pi = ++i;
                    state = 0;
                } else {
                    state = 3;
                }
            }
			// 3. 找数据宽度
            else if (state == 3) {
                while (c >= 48 && c <= 57) {
                    w = w * 10 + c - 48;
                    c = uint(uint8(format[++i]));
                }
                state = 4;
            }
            // 4. 找格式类型   
			else if (state == 4) {
                uint arg = readAbiUInt(abiArgs, ai);
                // d
                if (c == 100) {
                    if (arg >> 255 == 1) {
                        buffer[index++] = bytes1(uint8(45));
                        arg = uint(-int(arg));
                    } else {
                        buffer[index++] = bytes1(uint8(43));
                    }
                    c = 117;
                }
                // u
                if (c == 117) {
                    index = writeUIntDec(buffer, index, arg, w == 0 ? 1 : w);
                }
                // x/X
                else if (c == 120 || c == 88) {
                    index = writeUIntHex(buffer, index, arg, w == 0 ? 1 : w, c == 88);
                }
                // s/S
                else if (c == 115 || c == 83) {
                    index = writeAbiString(buffer, index, abiArgs, arg, w == 0 ? 31 : w, c == 83 ? 1 : 0);
                }
                // f
                else if (c == 102) {
                    if (arg >> 255 == 1) {
                        buffer[index++] = bytes1(uint8(45));
                        arg = uint(-int(arg));
                    }
                    index = writeFloat(buffer, index, arg, w == 0 ? 8 : w);
                }
                pi = ++i;
                state = 0;
                w = 0;
                ai += 32;
            }
        }

        while (pi < i) {
            buffer[index++] = format[pi++];
        }

        return index;
    }

    /// @dev 从abi编码的数据中的指定位置解码uint
    /// @param data abi编码的数据
    /// @param index 目标字符串在abi编码中的起始位置
    /// @return v 解码结果
    function readAbiUInt(bytes memory data, uint index) internal pure returns (uint v) {
        // uint v = 0;
        // for (uint i = 0; i < 32; ++i) {
        //     v = (v << 8) | uint(uint8(data[index + i]));
        // }
        // return v;
        assembly {
            v := mload(add(add(data, 0x20), index))
        }
    }

    /// @dev 从abi编码的数据中的指定位置解码字符串
    /// @param data abi编码的数据
    /// @param index 目标字符串在abi编码中的起始位置
    /// @return 解码结果
    function readAbiString(bytes memory data, uint index) internal pure returns (string memory) {
        return string(segment(data, index + 32, readAbiUInt(data, index)));
    }

    /// @dev 从abi编码的数据中的指定位置解码字符串并写入内存数组
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param data 目标字符串
    /// @param start 字符串数据在data中的开始位置
    /// @param count 截取长度（如果长度不够，则取剩余长度）
    /// @param charCase 字符的大小写，0不改变，1大小，2小写
    /// @return 写入后的新的内存数组偏移位置
    function writeAbiString(
        bytes memory buffer, 
        uint index, 
        bytes memory data, 
        uint start, 
        uint count,
        uint charCase
    ) internal pure returns (uint) 
    {
        uint length = readAbiUInt(data, start);
        if (count > length) {
            count = length;
        }
        uint i = 0;
        start += 32;
        while (i < count) {
            uint c = uint(uint8(data[start + i]));
            if (charCase == 1 && c >= 97 && c <= 122) {
                c -= 32;
            } else if (charCase == 2 && c >= 65 && c <= 90) {
                c -= 32;
            }
            buffer[index + i] = bytes1(uint8(c));
            ++i;
        }
        return index + i;
    }
}


// File contracts/libs/ABDKMath64x64.sol

// BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
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
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
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
    unchecked {
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
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
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
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
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
    unchecked {
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
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
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
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
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
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
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
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
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

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
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
    unchecked {
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
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}


// File contracts/interfaces/IHedgeFutures.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 定义永续合约交易接口
interface IHedgeFutures {
    
    struct FutureView {
        uint index;
        address tokenAddress;
        uint lever;
        bool orientation;
        
        uint balance;
        // 基准价格
        uint basePrice;
        // 基准区块号
        uint baseBlock;
    }

    /// @dev 新永续合约事件
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param index 永续合约编号
    event New(
        address tokenAddress, 
        uint lever,
        bool orientation,
        uint index
    );

    /// @dev 买入永续合约事件
    /// @param index 永续合约编号
    /// @param dcuAmount 支付的dcu数量
    event Buy(
        uint index,
        uint dcuAmount,
        address owner
    );

    /// @dev 卖出永续合约事件
    /// @param index 永续合约编号
    /// @param amount 卖出数量
    /// @param owner 所有者
    /// @param value 获得的dcu数量
    event Sell(
        uint index,
        uint amount,
        address owner,
        uint value
    );

    /// @dev 清算事件
    /// @param index 永续合约编号
    /// @param addr 清算目标账号数组
    /// @param sender 清算发起账号
    /// @param reward 清算获得的dcu数量
    event Settle(
        uint index,
        address addr,
        address sender,
        uint reward
    );
    
    /// @dev 返回指定期权当前的价值
    /// @param index 目标期权索引号
    /// @param oraclePrice 预言机价格
    /// @param addr 目标地址
    function balanceOf(uint index, uint oraclePrice, address addr) external view returns (uint);

    /// @dev 查找目标账户的合约
    /// @param start 从给定的合约地址对应的索引向前查询（不包含start对应的记录）
    /// @param count 最多返回的记录条数
    /// @param maxFindCount 最多查找maxFindCount记录
    /// @param owner 目标账户地址
    /// @return futureArray 合约信息列表
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (FutureView[] memory futureArray);

    /// @dev 列出历史永续合约地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (FutureView[] memory futureArray);

    /// @dev 创建永续合约
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    function create(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external;

    /// @dev 获取已经开通的永续合约数量
    /// @return 已经开通的永续合约数量
    function getFutureCount() external view returns (uint);

    /// @dev 获取永续合约信息
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 永续合约地址
    function getFutureInfo(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view returns (FutureView memory);

    /// @dev 买入永续合约
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param dcuAmount 支付的dcu数量
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint dcuAmount
    ) external payable;

    /// @dev 买入永续合约
    /// @param index 永续合约编号
    /// @param dcuAmount 支付的dcu数量
    function buyDirect(uint index, uint dcuAmount) external payable;

    /// @dev 卖出永续合约
    /// @param index 永续合约编号
    /// @param amount 卖出数量
    function sell(uint index, uint amount) external payable;

    /// @dev 清算
    /// @param index 永续合约编号
    /// @param addresses 清算目标账号数组
    function settle(uint index, address[] calldata addresses) external payable;

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ The square of the volatility (18 decimal places).
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) external view returns (uint k);
}


// File contracts/interfaces/IHedgeMapping.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for Hedge builtin contract address mapping
interface IHedgeMapping {

    /// @dev Set the built-in contract address of the system
    /// @param dcuToken Address of dcu token contract
    /// @param hedgeDAO IHedgeDAO implementation contract address
    /// @param hedgeOptions IHedgeOptions implementation contract address
    /// @param hedgeFutures IHedgeFutures implementation contract address
    /// @param hedgeVaultForStaking IHedgeVaultForStaking implementation contract address
    /// @param nestPriceFacade INestPriceFacade implementation contract address
    function setBuiltinAddress(
        address dcuToken,
        address hedgeDAO,
        address hedgeOptions,
        address hedgeFutures,
        address hedgeVaultForStaking,
        address nestPriceFacade
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return dcuToken Address of dcu token contract
    /// @return hedgeDAO IHedgeDAO implementation contract address
    /// @return hedgeOptions IHedgeOptions implementation contract address
    /// @return hedgeFutures IHedgeFutures implementation contract address
    /// @return hedgeVaultForStaking IHedgeVaultForStaking implementation contract address
    /// @return nestPriceFacade INestPriceFacade implementation contract address
    function getBuiltinAddress() external view returns (
        address dcuToken,
        address hedgeDAO,
        address hedgeOptions,
        address hedgeFutures,
        address hedgeVaultForStaking,
        address nestPriceFacade
    );

    /// @dev Get address of dcu token contract
    /// @return Address of dcu token contract
    function getDCUTokenAddress() external view returns (address);

    /// @dev Get IHedgeDAO implementation contract address
    /// @return IHedgeDAO implementation contract address
    function getHedgeDAOAddress() external view returns (address);

    /// @dev Get IHedgeOptions implementation contract address
    /// @return IHedgeOptions implementation contract address
    function getHedgeOptionsAddress() external view returns (address);

    /// @dev Get IHedgeFutures implementation contract address
    /// @return IHedgeFutures implementation contract address
    function getHedgeFuturesAddress() external view returns (address);

    /// @dev Get IHedgeVaultForStaking implementation contract address
    /// @return IHedgeVaultForStaking implementation contract address
    function getHedgeVaultForStakingAddress() external view returns (address);

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacade() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by Hedge system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view returns (address);
}


// File contracts/interfaces/IHedgeGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This interface defines the governance methods
interface IHedgeGovernance is IHedgeMapping {

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight 
    /// to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}


// File contracts/interfaces/IHedgeDAO.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the DAO methods
interface IHedgeDAO {

    /// @dev Application Flag Changed event
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    event ApplicationChanged(address addr, uint flag);
    
    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);

    /// @dev Add reward
    /// @param pool Destination pool
    function addETHReward(address pool) external payable;

    /// @dev The function returns eth rewards of specified pool
    /// @param pool Destination pool
    function totalETHRewards(address pool) external view returns (uint);

    /// @dev Settlement
    /// @param pool Destination pool. Indicates which pool to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address pool, address tokenAddress, address to, uint value) external payable;
}


// File contracts/HedgeBase.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Base contract of Hedge
contract HedgeBase {

    /// @dev IHedgeGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IHedgeGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "Hedge:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IHedgeGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IHedgeGovernance(governance).checkGovernance(msg.sender, 0), "Hedge:!gov");
        _governance = newGovernance;
    }

    /// @dev Migrate funds from current contract to HedgeDAO
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = IHedgeGovernance(_governance).getHedgeDAOAddress();
        if (tokenAddress == address(0)) {
            IHedgeDAO(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IHedgeGovernance(_governance).checkGovernance(msg.sender, 0), "Hedge:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "Hedge:!contract");
        _;
    }
}


// File contracts/HedgeFrequentlyUsed.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Base contract of Hedge
contract HedgeFrequentlyUsed is HedgeBase {

    // TODO: 改为正确的地址
    // TODO: 先部署DCU，确定地址后，再修改
      
    // Address of DCU contract
    //address constant DCU_TOKEN_ADDRESS = ;
    address DCU_TOKEN_ADDRESS;

    // Address of NestPriceFacade contract
    address NEST_PRICE_FACADE_ADDRESS;
    
    // USDT代币地址
    //address constant USDT_TOKEN_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDT_TOKEN_ADDRESS;

    // USDT代币的基数
    uint constant USDT_BASE = 1000000;

    // Genesis block number of dcu
    // DCU contract is created at block height TODO: 11040156. However, because the mining algorithm of Hedge v1.0
    // is different from that at present, a new mining algorithm is adopted from Hedge v2.1. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the dcu begins to decay. According to the circulation when Hedge v1.0 is online, the new mining
    // algorithm is used to deduce and convert the dcu, and the new algorithm is used to mine the Hedge v2.1
    // on-line flow, the actual block is TODO: 11040688
    uint constant DCU_GENESIS_BLOCK = 0;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IHedgeGovernance implementation contract address
    function update(address newGovernance) public override {

        super.update(newGovernance);
        (
            DCU_TOKEN_ADDRESS,//address dcuToken,
            ,//address hedgeDAO,
            ,//address hedgeOptions,
            ,//address hedgeFutures,
            ,//address hedgeVaultForStaking,
            NEST_PRICE_FACADE_ADDRESS //address nestPriceFacade
        ) = IHedgeGovernance(newGovernance).getBuiltinAddress();
    }

    // TODO: 测试方法
    function setUsdtTokenAddress(address usdtTokenAddress) external {
        USDT_TOKEN_ADDRESS = usdtTokenAddress;
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]

// MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// MIT

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/interfaces/INestPriceFacade.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the methods for price call entry
interface INestPriceFacade {
    
    /// @dev Find the price at block number
    /// @param tokenAddress Destination token address
    /// @param height Destination block number
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        address tokenAddress, 
        uint height, 
        address paybackAddress
    ) external payable returns (uint blockNumber, uint price);

    /// @dev Get the latest trigger price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(
        address tokenAddress, 
        address paybackAddress
    ) external payable returns (uint blockNumber, uint price);

    // /// @dev Price call entry configuration structure
    // struct Config {

    //     // Single query fee（0.0001 ether, DIMI_ETHER). 100
    //     uint16 singleFee;

    //     // Double query fee（0.0001 ether, DIMI_ETHER). 100
    //     uint16 doubleFee;

    //     // The normal state flag of the call address. 0
    //     uint8 normalFlag;
    // }

    // /// @dev Modify configuration
    // /// @param config Configuration object
    // function setConfig(Config calldata config) external;

    // /// @dev Get configuration
    // /// @return Configuration object
    // function getConfig() external view returns (Config memory);

    // /// @dev Set the address flag. Only the address flag equals to config.normalFlag can the price be called
    // /// @param addr Destination address
    // /// @param flag Address flag
    // function setAddressFlag(address addr, uint flag) external;

    // /// @dev Get the flag. Only the address flag equals to config.normalFlag can the price be called
    // /// @param addr Destination address
    // /// @return Address flag
    // function getAddressFlag(address addr) external view returns(uint);

    // /// @dev Set INestQuery implementation contract address for token
    // /// @param tokenAddress Destination token address
    // /// @param nestQueryAddress INestQuery implementation contract address, 0 means delete
    // function setNestQuery(address tokenAddress, address nestQueryAddress) external;

    // /// @dev Get INestQuery implementation contract address for token
    // /// @param tokenAddress Destination token address
    // /// @return INestQuery implementation contract address, 0 means use default
    // function getNestQuery(address tokenAddress) external view returns (address);

    // /// @dev Get cached fee in fee channel
    // /// @param tokenAddress Destination token address
    // /// @return Cached fee in fee channel
    // function getTokenFee(address tokenAddress) external view returns (uint);

    // /// @dev Settle fee for charge fee channel
    // /// @param tokenAddress tokenAddress of charge fee channel
    // function settle(address tokenAddress) external;
    
    // /// @dev Get the latest trigger price
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function triggeredPrice(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (uint blockNumber, uint price);

    /// @dev Get the full information of latest trigger price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(
        address tokenAddress, 
        address paybackAddress
    ) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ);

    // /// @dev Find the price at block number
    // /// @param tokenAddress Destination token address
    // /// @param height Destination block number
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function findPrice(
    //     address tokenAddress, 
    //     uint height, 
    //     address paybackAddress
    // ) external payable returns (uint blockNumber, uint price);

    // /// @dev Get the latest effective price
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function latestPrice(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (uint blockNumber, uint price);

    // /// @dev Get the last (num) effective price
    // /// @param tokenAddress Destination token address
    // /// @param count The number of prices that want to return
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    // function lastPriceList(
    //     address tokenAddress, 
    //     uint count, 
    //     address paybackAddress
    // ) external payable returns (uint[] memory);

    // /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return latestPriceBlockNumber The block number of latest price
    // /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    // /// @return triggeredPriceBlockNumber The block number of triggered price
    // /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    // /// @return triggeredAvgPrice Average price
    // /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    // /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    // /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    // function latestPriceAndTriggeredPriceInfo(address tokenAddress, address paybackAddress) 
    // external 
    // payable 
    // returns (
    //     uint latestPriceBlockNumber, 
    //     uint latestPriceValue,
    //     uint triggeredPriceBlockNumber,
    //     uint triggeredPriceValue,
    //     uint triggeredAvgPrice,
    //     uint triggeredSigmaSQ
    // );

    /// @dev Returns lastPriceList and triggered price info
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(
        address tokenAddress, 
        uint count, 
        address paybackAddress
    ) external payable 
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    );

    // /// @dev Get the latest trigger price. (token and ntoken)
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // /// @return ntokenBlockNumber The block number of ntoken price
    // /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    // function triggeredPrice2(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (
    //     uint blockNumber, 
    //     uint price, 
    //     uint ntokenBlockNumber, 
    //     uint ntokenPrice
    // );

    // /// @dev Get the full information of latest trigger price. (token and ntoken)
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // /// @return avgPrice Average price
    // /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    // /// the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447, 
    // /// it means that the volatility has exceeded the range that can be expressed
    // /// @return ntokenBlockNumber The block number of ntoken price
    // /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    // /// @return ntokenAvgPrice Average price of ntoken
    // /// @return ntokenSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    // /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    // /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    // function triggeredPriceInfo2(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (
    //     uint blockNumber, 
    //     uint price, 
    //     uint avgPrice, 
    //     uint sigmaSQ, 
    //     uint ntokenBlockNumber, 
    //     uint ntokenPrice, 
    //     uint ntokenAvgPrice, 
    //     uint ntokenSigmaSQ
    // );

    // /// @dev Get the latest effective price. (token and ntoken)
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // /// @return ntokenBlockNumber The block number of ntoken price
    // /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    // function latestPrice2(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (
    //     uint blockNumber, 
    //     uint price, 
    //     uint ntokenBlockNumber, 
    //     uint ntokenPrice
    // );
}


// File contracts/DCU.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev DCU代币
contract DCU is HedgeBase, ERC20("Decentralized Currency Unit", "DCU") {

    // 保存挖矿权限地址
    mapping(address=>uint) _minters;

    constructor() {
    }

    modifier onlyMinter {
        require(_minters[msg.sender] == 1, "DCU:not minter");
        _;
    }

    /// @dev 设置挖矿权限
    /// @param account 目标账号
    /// @param flag 挖矿权限标记，只有1表示可以挖矿
    function setMinter(address account, uint flag) external onlyGovernance {
        _minters[account] = flag;
    }

    function checkMinter(address account) external view returns (uint) {
        return _minters[account];
    }

    /// @dev 铸币
    /// @param to 接受地址
    /// @param value 铸币数量
    function mint(address to, uint value) external onlyMinter {
        _mint(to, value);
    }

    /// @dev 销毁
    /// @param from 目标地址
    /// @param value 销毁数量
    function burn(address from, uint value) external onlyMinter {
        _burn(from, value);
    }
}


// File contracts/HedgeFutures.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev 永续合约交易
contract HedgeFutures is HedgeFrequentlyUsed, IHedgeFutures {

    /// @dev 用户账本
    struct Account {
        // 账本-余额
        uint128 balance;
        // 基准价格
        uint64 basePrice;
        // 基准区块号
        uint32 baseBlock;
    }

    /// @dev 永续合约信息
    struct FutureInfo {
        // 目标代币地址
        address tokenAddress; 
        // 杠杆倍数
        uint32 lever;
        // 看涨:true | 看跌:false
        bool orientation;
        
        // 账号信息
        mapping(address=>Account) accounts;
    }

    // 漂移系数，64位二进制小数。年华80%
    uint constant MIU = 467938556917;
    
    // 最小余额数量，余额小于此值会被清算
    uint constant MIN_VALUE = 10 ether;

    // 买入永续合约和其他交易之间最小的间隔区块数
    uint constant MIN_PERIOD = 100;

    // 区块时间
    uint constant BLOCK_TIME = 14 * 48;

    // 永续合约映射
    mapping(uint=>uint) _futureMapping;

    // 缓存代币的基数值
    mapping(address=>uint) _bases;

    // 永续合约数组
    FutureInfo[] _futures;

    constructor() {
    }

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IHedgeGovernance implementation contract address
    function initialize(address governance) public override {
        super.initialize(governance);
        _futures.push();
    }

    /// @dev 返回指定期权当前的价值
    /// @param index 目标期权索引号
    /// @param oraclePrice 预言机价格
    /// @param addr 目标地址
    function balanceOf(uint index, uint oraclePrice, address addr) external view override returns (uint) {
        FutureInfo storage fi = _futures[index];
        Account memory account = fi.accounts[addr];
        return _balanceOf(
            uint(account.balance), 
            _decodeFloat(account.basePrice), 
            uint(account.baseBlock),
            oraclePrice, 
            fi.orientation, 
            uint(fi.lever)
        );
    }

    /// @dev 查找目标账户的合约
    /// @param start 从给定的合约地址对应的索引向前查询（不包含start对应的记录）
    /// @param count 最多返回的记录条数
    /// @param maxFindCount 最多查找maxFindCount记录
    /// @param owner 目标账户地址
    /// @return futureArray 合约信息列表
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view override returns (FutureView[] memory futureArray) {
        
        futureArray = new FutureView[](count);
        
        // 计算查找区间i和end
        FutureInfo[] storage futures = _futures;
        uint i = futures.length;
        uint end = 0;
        if (start > 0) {
            i = start;
        }
        if (i > maxFindCount) {
            end = i - maxFindCount;
        }
        
        // 循环查找，将符合条件的记录写入缓冲区
        for (uint index = 0; index < count && i > end;) {
            FutureInfo storage fi = futures[--i];
            if (uint(fi.accounts[owner].balance) > 0) {
                futureArray[index++] = _toFutureView(fi, i);
            }
        }
    }

    /// @dev 列出历史永续合约地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of price sheets
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (FutureView[] memory futureArray) {

        // 加载代币数组
        FutureInfo[] storage futures = _futures;
        // 创建结果数组
        futureArray = new FutureView[](count);
        uint length = futures.length;
        uint i = 0;

        // 倒序
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                FutureInfo storage fi = futures[--index];
                futureArray[i++] = _toFutureView(fi, index);
            }
        } 
        // 正序
        else {
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                futureArray[i++] = _toFutureView(futures[index], index);
                ++index;
            }
        }
    }

    /// @dev 创建永续合约
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    function create(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external override onlyGovernance {

        // 检查永续合约是否已经存在
        uint key = _getKey(tokenAddress, lever, orientation);
        uint index = _futureMapping[key];
        require(index == 0, "HF:exists");

        // 创建永续合约
        index = _futures.length;
        FutureInfo storage fi = _futures.push();
        fi.tokenAddress = tokenAddress;
        fi.lever = uint32(lever);
        fi.orientation = orientation;
        _futureMapping[key] = index;

        // 创建永续合约事件
        emit New(tokenAddress, lever, orientation, index);
    }

    /// @dev 获取已经开通的永续合约数量
    /// @return 已经开通的永续合约数量
    function getFutureCount() external view override returns (uint) {
        return _futures.length;
    }

    /// @dev 获取永续合约信息
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 永续合约地址
    function getFutureInfo(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view override returns (FutureView memory) {
        uint index = _futureMapping[_getKey(tokenAddress, lever, orientation)];
        return _toFutureView(_futures[index], index);
    }

    /// @dev 买入永续合约
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param dcuAmount 支付的dcu数量
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint dcuAmount
    ) external payable override {
        uint index = _futureMapping[_getKey(tokenAddress, lever, orientation)];
        require(index != 0, "HF:not exist");
        _buy(_futures[index], index, dcuAmount, tokenAddress, orientation);
    }

    /// @dev 买入永续合约
    /// @param index 永续合约编号
    /// @param dcuAmount 支付的dcu数量
    function buyDirect(uint index, uint dcuAmount) public payable override {
        require(index != 0, "HF:not exist");
        FutureInfo storage fi = _futures[index];
        _buy(fi, index, dcuAmount, fi.tokenAddress, fi.orientation);
    }

    /// @dev 卖出永续合约
    /// @param index 永续合约编号
    /// @param amount 卖出数量
    function sell(uint index, uint amount) external payable override {

        // 1. 销毁用户的永续合约
        require(index != 0, "HF:not exist");
        FutureInfo storage fi = _futures[index];
        bool orientation = fi.orientation;

        // 看涨的时候，初始价格乘以(1+k)，卖出价格除以(1+k)
        // 看跌的时候，初始价格除以(1+k)，卖出价格乘以(1+k)
        // 合并的时候，s0用记录的价格，s1用k修正的
        uint oraclePrice = _queryPrice(fi.tokenAddress, !orientation, msg.sender);

        // 更新目标账号信息
        Account memory account = fi.accounts[msg.sender];

        account.balance -= _toUInt128(amount);
        fi.accounts[msg.sender] = account;

        // 2. 给用户分发dcu
        uint value = _balanceOf(
            amount, 
            _decodeFloat(account.basePrice), 
            uint(account.baseBlock),
            oraclePrice, 
            orientation, 
            uint(fi.lever)
        );
        DCU(DCU_TOKEN_ADDRESS).mint(msg.sender, value);

        // 卖出事件
        emit Sell(index, amount, msg.sender, value);
    }

    /// @dev 清算
    /// @param index 永续合约编号
    /// @param addresses 清算目标账号数组
    function settle(uint index, address[] calldata addresses) external payable override {

        // 1. 销毁用户的永续合约
        require(index != 0, "HF:not exist");
        FutureInfo storage fi = _futures[index];
        uint lever = uint(fi.lever);

        if (lever > 1) {

            bool orientation = fi.orientation;
            // 看涨的时候，初始价格乘以(1+k)，卖出价格除以(1+k)
            // 看跌的时候，初始价格除以(1+k)，卖出价格乘以(1+k)
            // 合并的时候，s0用记录的价格，s1用k修正的
            uint oraclePrice = _queryPrice(fi.tokenAddress, !orientation, msg.sender);

            uint reward = 0;
            mapping(address=>Account) storage accounts = fi.accounts;
            for (uint i = addresses.length; i > 0;) {
                address acc = addresses[--i];

                // 更新目标账号信息
                Account memory account = accounts[acc];
                uint balance = _balanceOf(
                    uint(account.balance), 
                    _decodeFloat(account.basePrice), 
                    uint(account.baseBlock),
                    oraclePrice, 
                    orientation, 
                    lever
                );

                // 杠杆倍数大于1，并且余额小于最小额度时，可以清算
                if (balance < MIN_VALUE) {
                    
                    accounts[acc] = Account(uint128(0), uint64(0), uint32(0));

                    //emit Transfer(acc, address(0), balance);

                    reward += balance;

                    emit Settle(index, acc, msg.sender, balance);
                }
            }

            // 2. 给用户分发dcu
            if (reward > 0) {
                DCU(DCU_TOKEN_ADDRESS).mint(msg.sender, reward);
            }
        } else {
            if (msg.value > 0) {
                payable(msg.sender).transfer(msg.value);
            }
        }
    }

    // 根据杠杆信息计算索引key
    function _getKey(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) private pure returns (uint) {
        //return keccak256(abi.encodePacked(tokenAddress, lever, orientation));
        require(lever < 0x100000000, "HF:lever to large");
        return (uint(uint160(tokenAddress)) << 96) | (lever << 8) | (orientation ? 1 : 0);
    }

    // 买入永续合约
    function _buy(FutureInfo storage fi, uint index, uint dcuAmount, address tokenAddress, bool orientation) private {

        require(dcuAmount >= 100 ether, "HF:at least 100 dcu");

        // 1. 销毁用户的dcu
        DCU(DCU_TOKEN_ADDRESS).burn(msg.sender, dcuAmount);

        // 2. 给用户分发永续合约
        // 看涨的时候，初始价格乘以(1+k)，卖出价格除以(1+k)
        // 看跌的时候，初始价格除以(1+k)，卖出价格乘以(1+k)
        // 合并的时候，s0用记录的价格，s1用k修正的
        uint oraclePrice = _queryPrice(tokenAddress, orientation, msg.sender);

        Account memory account = fi.accounts[msg.sender];
        uint basePrice = _decodeFloat(account.basePrice);
        uint balance = uint(account.balance);
        uint newPrice = oraclePrice;
        if (uint(account.baseBlock) > 0) {
            newPrice = (balance + dcuAmount) * oraclePrice * basePrice / (
                basePrice * dcuAmount + (oraclePrice * balance << 64) / _expMiuT(uint(account.baseBlock))
            );
        }
        
        // 更新接收账号信息
        account.balance = _toUInt128(balance + dcuAmount);
        account.basePrice = _encodeFloat(newPrice);
        account.baseBlock = uint32(block.number);
        
        fi.accounts[msg.sender] = account;

        // 买入事件
        emit Buy(index, dcuAmount, msg.sender);
    }

    // 查询预言机价格
    function _queryPrice(address tokenAddress, bool enlarge, address payback) private returns (uint oraclePrice) {
        require(tokenAddress == address(0), "HF:only support eth/usdt");

        // 获取usdt相对于eth的价格
        (
            uint[] memory prices,
            ,//uint triggeredPriceBlockNumber,
            ,//uint triggeredPriceValue,
            ,//uint triggeredAvgPrice,
            uint triggeredSigmaSQ
        ) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).lastPriceListAndTriggeredPriceInfo {
            value: msg.value
        } (USDT_TOKEN_ADDRESS, 2, payback);
        
        // 将token价格转化为以usdt为单位计算的价格
        oraclePrice = prices[1];
        uint k = calcRevisedK(triggeredSigmaSQ, prices[3], prices[2], oraclePrice, prices[0]);

        // 看涨的时候，初始价格乘以(1+k)，卖出价格除以(1+k)
        // 看跌的时候，初始价格除以(1+k)，卖出价格乘以(1+k)
        // 合并的时候，s0用记录的价格，s1用k修正的
        if (enlarge) {
            oraclePrice = oraclePrice * (1 ether + k) / 1 ether;
        } else {
            oraclePrice = oraclePrice * 1 ether / (1 ether + k);
        }
    }

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ The square of the volatility (18 decimal places).
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) public view override returns (uint k) {
        k = _calcK(_calcRevisedSigmaSQ(sigmaSQ, p0, bn0, p, bn), bn);
    }

    // Calculate the corrected volatility
    function _calcRevisedSigmaSQ(
        uint sigmaSQ,
        uint p0, 
        uint bn0, 
        uint p, 
        uint bn
    ) private pure returns (uint revisedSigmaSQ) {
        // sq2 = sq1 * 0.9 + rq2 * dt * 0.1
        // sq1 = (sq2 - rq2 * dt * 0.1) / 0.9
        // 1. 
        // rq2 <= 4 * dt * sq1
        // sqt = sq2
        // 2. rq2 > 4 * dt * sq1 && rq2 <= 9 * dt * sq1
        // sqt = (sq1 + rq2 * dt) / 2
        // 3. rq2 > 9 * dt * sq1
        // sqt = sq1 * 0.2 + rq2 * dt * 0.8

        uint rq2 = p * 1 ether / p0;
        if (rq2 > 1 ether) {
            rq2 -= 1 ether;
        } else {
            rq2 = 1 ether - rq2;
        }
        rq2 = rq2 * rq2 / 1 ether;

        uint dt = (bn - bn0) * BLOCK_TIME;
        uint sq1 = 0;
        uint rq2dt = rq2 / dt;
        if (sigmaSQ * 10 > rq2dt) {
            sq1 = (sigmaSQ * 10 - rq2dt) / 9;
        }

        uint dds = dt * dt * dt * sq1;
        if (rq2 <= (dds << 2)) {
            revisedSigmaSQ = sigmaSQ;
        } else if (rq2 <= 9 * dds) {
            revisedSigmaSQ = (sq1 + rq2dt) >> 1;
        } else {
            revisedSigmaSQ = (sq1 + (rq2dt << 2)) / 5;
        }
    }

    /// @dev Calc K value
    /// @param sigmaSQ The square of the volatility (18 decimal places).
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    /// @return k The K value
    function _calcK(uint sigmaSQ, uint bn) private view returns (uint k) {
        k = 0.002 ether + (_sqrt((block.number - bn) * BLOCK_TIME * sigmaSQ * 1 ether) >> 1);
    }

    function _sqrt(uint256 x) private pure returns (uint256) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
                if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
                if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
                if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
                if (xx >= 0x100) { xx >>= 8; r <<= 4; }
                if (xx >= 0x10) { xx >>= 4; r <<= 2; }
                if (xx >= 0x8) { r <<= 1; }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return (r < r1 ? r : r1);
            }
        }
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint64) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint64((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint64 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }

    // 将uint转化为uint128，有截断检查
    function _toUInt128(uint value) private pure returns (uint128) {
        require(value < 0x100000000000000000000000000000000);
        return uint128(value);
    }

    // 将uint转化为int128
    function _toInt128(uint v) private pure returns (int128) {
        require(v < 0x80000000000000000000000000000000, "FEO:can't convert to int128");
        return int128(int(v));
    }

    // 将int128转化为uint
    function _toUInt(int128 v) private pure returns (uint) {
        require(v >= 0, "FEO:can't convert to uint");
        return uint(int(v));
    }
    
    // 根据新价格计算账户余额
    function _balanceOf(
        uint balance,
        uint basePrice,
        uint baseBlock,
        uint oraclePrice, 
        bool ORIENTATION, 
        uint LEVER
    ) private view returns (uint) {

        if (balance > 0) {
            //uint price = _decodeFloat(account.price);

            uint left;
            uint right;
            // 看涨
            if (ORIENTATION) {
                left = balance + (balance * oraclePrice * LEVER << 64) / basePrice / _expMiuT(baseBlock);
                right = balance * LEVER;
            } 
            // 看跌
            else {
                left = balance * (1 + LEVER);
                right = (balance * oraclePrice * LEVER << 64) / basePrice / _expMiuT(baseBlock);
            }

            if (left > right) {
                balance = left - right;
            } else {
                balance = 0;
            }
        }

        return balance;
    }

    // 计算 e^μT
    function _expMiuT(uint baseBlock) private view returns (uint) {
        return _toUInt(ABDKMath64x64.exp(_toInt128(MIU * (block.number - baseBlock) * BLOCK_TIME)));
    }

    // 转换永续合约信息
    function _toFutureView(FutureInfo storage fi, uint index) private view returns (FutureView memory) {
        Account memory account = fi.accounts[msg.sender];
        return FutureView(
            index,
            fi.tokenAddress,
            uint(fi.lever),
            fi.orientation,
            uint(account.balance),
            _decodeFloat(account.basePrice),
            uint(account.baseBlock)
        );
    }
}