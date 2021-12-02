/**
 *Submitted for verification at polygonscan.com on 2021-12-02
*/

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma abicoder v2;
pragma solidity ^0.8.7;

contract DefiTokenTracker {
    struct slice {
        uint _len;
        uint _ptr;
    }

    struct TokenInfo {
        address token;
        uint256 balance;
    }

    struct LPTokenInfo {
        address lpToken;
        uint256 balance;
        TokenInfo tokenInfo;
    }

    struct StakedInfo {
        address chefAddress;
        uint256 index;
        address token;
        uint256 balance;
        LPTokenInfo lpTokenInfo;
    }

    struct PoolInfo {
        address chefAddress;
        string poolInfoSignature;
        string userInfoSignature;
        uint256 index;
    }

    address public manager;
    
    modifier onlyManager() {
        require (msg.sender == manager);
        _;
    }
    
    constructor() {
        manager = msg.sender;
    }

    function getUserTokenInfo(
        address user,
        address token
    )
        public
        view
        returns (TokenInfo memory tokenInfo)
    {
        tokenInfo.token = token;
        tokenInfo.balance = ERC20(token).balanceOf(user);
    }
    
    function getUserLPTokenInfo(
        address user,
        address token,
        address lpToken
    )
        public
        view
        returns (LPTokenInfo memory lpTokenInfo)
    {
        lpTokenInfo.lpToken = lpToken;
        lpTokenInfo.balance = Pair(lpToken).balanceOf(user);
        lpTokenInfo.tokenInfo.token = token;

        (uint256 reserve0, uint256 reserve1, ) = Pair(lpToken).getReserves();
        if (Pair(lpToken).token0() == lpToken) {
            lpTokenInfo.tokenInfo.balance = 
                lpTokenInfo.balance * reserve0 / Pair(lpToken).totalSupply();
        } else if (Pair(lpToken).token1() == lpToken) {
            lpTokenInfo.tokenInfo.balance =
                lpTokenInfo.balance * reserve1 / Pair(lpToken).totalSupply();
        }
    }

    function getUserLPTokenInfos(
        address user,
        address token,
        address[] memory lpTokens
    )
        public
        view
        returns (LPTokenInfo[] memory lpTokenInfos)
    {
        lpTokenInfos = new LPTokenInfo[](lpTokens.length);
        uint256 lpTokenLength = lpTokens.length;
        for (uint256 i = 0; i < lpTokenLength; i++) {
            lpTokenInfos[i] = getUserLPTokenInfo(
                user,
                token,
                lpTokens[i]
            );
        }
    }

    function getUserStakedInfo(
        address user,
        address token,
        address chefAddress,
        string memory poolInfoSignature,
        string memory userInfoSignature,
        uint256 index
    )
        public
        view
        returns (StakedInfo memory stakedInfo)
    {
        bytes memory poolInfoCallData;
        poolInfoCallData =abi.encodeWithSignature(
            concat(toSlice(poolInfoSignature), toSlice("(uint256")),
            index
        );

        (
            bool success,
            bytes memory returnData
        ) = address(chefAddress).staticcall(poolInfoCallData);

        address poolToken;
        if (success) {
            (poolToken) = abi.decode(returnData, (address));
        }

        bytes memory callData;
        callData = abi.encodeWithSignature(
            concat(toSlice(userInfoSignature), toSlice("(uint256,address)")),
            index,
            user
        );

        (
            success,
            returnData
        ) = address(chefAddress).staticcall(callData);

        stakedInfo.chefAddress = chefAddress;
        stakedInfo.index = index;
        stakedInfo.token = poolToken;
        if (success) {
            (stakedInfo.balance) = abi.decode(returnData, (uint256));
        }

        try Pair(token).getReserves() returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32
        ) {
            stakedInfo.lpTokenInfo.lpToken = poolToken;
            stakedInfo.lpTokenInfo.balance = stakedInfo.balance;
            if (Pair(poolToken).token0() == poolToken) {
                stakedInfo.lpTokenInfo.tokenInfo.balance = 
                    stakedInfo.balance * reserve0 / Pair(poolToken).totalSupply();
            } else if (Pair(poolToken).token1() == poolToken) {
                stakedInfo.lpTokenInfo.tokenInfo.balance =
                    stakedInfo.balance * reserve1 / Pair(poolToken).totalSupply();
            }
        } catch Error(string memory /*reason*/) {
        } catch (bytes memory /*lowLevelData*/) {
        }
    }
    
    function getUserStakedInfos(
        address user,
        address token,
        PoolInfo[] memory poolInfos
    )
        public
        view
        returns (StakedInfo[]memory stakedInfos)
    {
        stakedInfos = new StakedInfo[](poolInfos.length);
        uint256 poolLength = poolInfos.length;
        for (uint256 i = 0; i < poolLength; i++) {
            stakedInfos[i] = getUserStakedInfo(
                user,
                token,
                poolInfos[i].chefAddress,
                poolInfos[i].poolInfoSignature,
                poolInfos[i].userInfoSignature,
                poolInfos[i].index
            );
        }
    }

    function getUserInfos(
        address user,
        address token,
        address[] memory lpTokens,
        PoolInfo[] memory poolInfos
    )
        public
        view
        returns
    (
        TokenInfo memory tokenInfo,
        LPTokenInfo[] memory lpTokenInfos,
        StakedInfo[] memory stakedInfos
    )
    {
        tokenInfo = getUserTokenInfo(user, token);

        lpTokenInfos = new LPTokenInfo[](lpTokens.length);
        lpTokenInfos = getUserLPTokenInfos(user, token, lpTokens);

        stakedInfos = new StakedInfo[](poolInfos.length);
        stakedInfos = getUserStakedInfos(user, token, poolInfos);
    }

    function changeManager(address newManager) external onlyManager {
        require(newManager != address(0));
        manager = newManager;
    }

    function concat(
        slice memory self,
        slice memory other
    )
        internal
        pure
        returns (string memory)
    {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }
    
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
}

interface Pair {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}