/**
 *Submitted for verification at Etherscan.io on 2020-11-29
*/

// SPDX-License-Identifier: ISC

pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

abstract contract UniTarget {
    function symbol() public virtual view returns (string memory);

    function token0() public virtual view returns (address);

    function token1() public virtual view returns (address);
}

// target contract interface - selection of used ERC20
abstract contract Target {
    function name() public virtual view returns (string memory);

    function symbol() public virtual view returns (string memory);

    function decimals() public virtual view returns (uint8);

    function totalSupply() public virtual view returns (uint256);
}

contract UniTokenLoader {

    struct TokenInfo {
        address addr;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
    }

    function loadTokens(address[] calldata tokens) external view returns (TokenInfo[] memory tokenInfo) {
        tokenInfo = new TokenInfo[](2 * tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            UniTarget uniToken = UniTarget(tokens[i]);
            (bool success, bytes memory returnData) = tokens[i].staticcall(abi.encodeWithSelector(uniToken.symbol.selector));

            // keccak256(bytes("UNI-V2")) = 0x0c49a525f6758cfb27d0ada1467d2a2e99733995423d47ae30ae4ba2ba563255
            if (success && returnData.length != 0 && keccak256(abi.decode(returnData, (bytes))) == 0x0c49a525f6758cfb27d0ada1467d2a2e99733995423d47ae30ae4ba2ba563255) {
                address token0Address = uniToken.token0();
                address token1Address = uniToken.token1();
                Target token0 = Target(token0Address);
                Target token1 = Target(token1Address);

                tokenInfo[2 * i] = TokenInfo(token0Address, token0.name(), token0.symbol(), token0.decimals(), token0.totalSupply());
                tokenInfo[2 * i + 1] = TokenInfo(token1Address, token1.name(), token1.symbol(), token1.decimals(), token1.totalSupply());
            }
        }

        return tokenInfo;
    }

}