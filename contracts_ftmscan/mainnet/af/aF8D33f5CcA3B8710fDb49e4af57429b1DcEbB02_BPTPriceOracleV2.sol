/**
 *Submitted for verification at FtmScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface ChainlinkOracle is IERC20 {
    function latestAnswer() external view returns (int256);
}

interface IVault {
    function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
        IERC20[] memory tokens,
        uint256[] memory balances,
        uint256 lastChangeBlock
    );

    function getPool(bytes32 poolId) external view returns (address, uint8);

    function getPoolTokenInfo(bytes32 poolId, address token) external view returns (uint256, uint256, uint256, address);
}

interface IBPTPool {
    function getNormalizedWeights() external view returns (uint256[] memory);
}

contract BPTPriceOracleV2 {
    address vault;
    bytes32 poolId;
    mapping(address => address) oracles;

    constructor (address _vault, bytes32 _poolId) {
        vault = _vault;
        poolId = _poolId;
    }

    function setOracle(address token, address oracle) public {
        oracles[token] = oracle;
    }

    function getPrice() public view returns (int256) {
        // (address poolAddress,) = IVault(vault).getPool(poolId);

        (IERC20[] memory tokens, uint256[] memory balances,) = IVault(vault).getPoolTokens(poolId);

        // uint256[] memory weights = IBPTPool(poolAddress).getNormalizedWeights();

        uint256 totalValue = 0;

        for (uint8 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];

            // if there is no oracle
            if (oracles[address(token)] != address(0)) {
                
            } else { // if there is an oracle
                int256 tokenPrice = ChainlinkOracle(oracles[address(token)]).latestAnswer();

                uint256 tokenValue = (uint256(tokenPrice) * balances[i]) / (10 ** token.decimals());

                totalValue += tokenValue;
            }
        }

        return int256(totalValue);
    }
}