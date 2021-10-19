//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IPolygonSand {
    /// @notice update the ChildChainManager Proxy address
    /// @param newChildChainManagerProxy address of the new childChainManagerProxy
    function updateChildChainManager(address newChildChainManagerProxy) external;

    /// @notice called when tokens are deposited on root chain
    /// @param user user address for whom deposit is being done
    /// @param depositData abi encoded amount
    function deposit(address user, bytes calldata depositData) external;

    /// @notice called when user wants to withdraw tokens back to root chain
    /// @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
    /// @param amount amount to withdraw
    function withdraw(uint256 amount) external;

    function setTrustedForwarder(address trustedForwarder) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../common/interfaces/polygon/IPolygonSand.sol";

contract PolygonSandBatchDeposit {
    IPolygonSand internal immutable _polygonSand;
    address internal immutable _childChainManagerProxyAddress;
    address internal _owner;

    event ChildChainManagerProxyReset(address _childChainManagerProxy);

    modifier onlyOwner() {
        require(msg.sender == _owner, "You are not authorized to perform this action");
        _;
    }

    constructor(IPolygonSand polygonSand, address childChainManagerProxyAddress) {
        _polygonSand = polygonSand;
        _childChainManagerProxyAddress = childChainManagerProxyAddress;
        _owner = msg.sender;
    }

    function batchMint(address[] calldata holders, uint256[] calldata values) external onlyOwner {
        require(holders.length == values.length, "Number of holders should be equal to number of values");
        for (uint256 i = 0; i < holders.length; i++) {
            _polygonSand.deposit(holders[i], abi.encode(values[i]));
        }
    }

    function resetChildChainManagerProxy() external onlyOwner {
        _polygonSand.updateChildChainManager(_childChainManagerProxyAddress);
        emit ChildChainManagerProxyReset(_childChainManagerProxyAddress);
    }
}