// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

 enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

interface LBPFactory {
    function create(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        string[] memory weights,
        string memory swapFeePercentage,
        address owner,
        bool swapEnabledOnStart
    ) external returns (address);
}

contract TestProxy {
    address public constant VaultAddress = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    mapping(address => address) public poolOwner;

    address public immutable feeRecipient;
    address public immutable LBPFactoryAddress;

    constructor(address _feeRecipient, address _LBPFactoryAddress) {
        feeRecipient = _feeRecipient;
        LBPFactoryAddress = _LBPFactoryAddress;
    }

    struct PoolLBPFactoryConfig {
        string name;
        string symbol;
        address[] tokens;
        uint256[] amounts;
        string[] weights;
        string swapFeePercentage;
        address owner;
    }

    function noTransferCreateLBPFactoryFromProxy(PoolLBPFactoryConfig memory poolLBPFactoryConfig) external {
        // address pool = LBPFactory(LBPFactoryAddress).create(
        //     poolLBPFactoryConfig.name,
        //     poolLBPFactoryConfig.symbol,
        //     poolLBPFactoryConfig.tokens,
        //     poolLBPFactoryConfig.weights,
        //     poolLBPFactoryConfig.swapFeePercentage,
        //     address(this), // owner set to this proxy
        //     false // swaps disabled on start
        // );
        LBPFactory(LBPFactoryAddress).create(
            poolLBPFactoryConfig.name,
            poolLBPFactoryConfig.symbol,
            poolLBPFactoryConfig.tokens,
            poolLBPFactoryConfig.weights,
            poolLBPFactoryConfig.swapFeePercentage,
            address(this), // owner set to this proxy
            false // swaps disabled on start
        );
        poolOwner[0x6Dec8d0496590521C8F4f1deE7Cfe9c7A6B7a480] = poolLBPFactoryConfig.owner;
    }

    function testTransfer(PoolLBPFactoryConfig memory poolLBPFactoryConfig) external {
        for (uint256 index = 0; index < poolLBPFactoryConfig.tokens.length; index++) {
            TransferHelper.safeTransferFrom(
                poolLBPFactoryConfig.tokens[index],
                msg.sender,
                address(this),
                uint256(poolLBPFactoryConfig.amounts[index])
            );
            TransferHelper.safeApprove(
                poolLBPFactoryConfig.tokens[index],
                VaultAddress,
                uint256(poolLBPFactoryConfig.amounts[index])
            );
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}