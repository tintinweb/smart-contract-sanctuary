// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

/**
 * Contract that will forward any incoming Ether to the creator of the contract
 *
*/
contract ForwarderCustom {
    /*
     * Data Structures and value
    */
    address public _parentAddress; // Address to which any funds sent to this contract will be forwarded

    /**
     * @dev Modifier that will execute internal code block only if the contract has not been initialized yet
    */
    modifier onlyUninitialized {
        require(_parentAddress == address(0x0), 'Already initialized');
        _;
    }

    /*
     * @dev Default function; Gets called when data is sent but does not match any other function
    */
    fallback() external payable {

    }

    /*
     * @dev Default function; Gets called when Ether is deposited with no data, and forwards it to the parent address
    */
    receive() external payable {

    }

    /*
     * @dev Initialize the contract, and sets the destination address to that of the creator
     * @param _parentAddress
    */
    function init(address parentAddress) external onlyUninitialized {
        _parentAddress = parentAddress;
    }

    /**
     * @dev Flush the entire balance of the contract to the parent address.
    */
    function flush() public {
        uint256 _value = address(this).balance;

        (bool _success, ) = _parentAddress.call{ value: _value }('');
        require(_success, 'Flush failed');
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

