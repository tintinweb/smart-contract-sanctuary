/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

pragma experimental ABIEncoderV2;





interface IAsset {
}

interface IVault{

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
        address[] memory tokens,
        uint256[] memory balances,
        uint256 lastChangeBlock
    );
}





contract BalancerV2Helper {
    IVault public constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    string public constant ADDR_MUST_NOT_BE_ZERO = "Address to which tokens will be sent to can't be burn address";

    function _getPoolAddress(bytes32 poolId) internal pure returns (address) {
        // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
        // since the logical shift already sets the upper bits to zero.
        return address(uint256(poolId) >> (12 * 8));
    }
}




interface IPool {
    function getPoolId() external view returns (bytes32);
}






contract BalancerView is BalancerV2Helper {
    function getPoolTokens(address _pool) external view returns (
        address[] memory tokens,
        uint256[] memory balances
    ) {
        bytes32 poolId = IPool(_pool).getPoolId();
        (tokens, balances, ) = vault.getPoolTokens(poolId); 
    }
}