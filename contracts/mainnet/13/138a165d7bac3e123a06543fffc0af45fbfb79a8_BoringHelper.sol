/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
}

interface IPair is IERC20 {
    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);
}

interface IFactory {
    function allPairsLength() external view returns (uint256);
    function allPairs(uint256 i) external view returns (IPair);
    function getPair(IERC20 token0, IERC20 token1) external view returns (IPair);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
}
contract BoringHelper {
    struct Pair {
        IPair token;
        IERC20 token0;
        IERC20 token1;
        uint256 totalSupply;
    }

    function getPairs(
        IFactory factory,
        uint256 fromID,
        uint256 toID
    ) public view returns (Pair[] memory) {
        Pair[] memory pairs = new Pair[](toID - fromID);

        for (uint256 id = fromID; id < toID; id++) {
            IPair token = factory.allPairs(id);
            uint256 i = id - fromID;
            pairs[i].token = token;
            pairs[i].token0 = token.token0();
            pairs[i].token1 = token.token1();
            pairs[i].totalSupply = token.totalSupply();
        }
        return pairs;
    }
}