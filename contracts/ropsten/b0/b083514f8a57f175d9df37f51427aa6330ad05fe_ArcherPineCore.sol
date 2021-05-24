// SPDX-License-Identifier: GPL-3.0

//
// Original work by Pine.Finance
//  - https://github.com/pine-finance
//

pragma solidity 0.6.12;

import {PineCore, IModule, IERC20} from "./PineCore.sol";

contract ArcherPineCore is PineCore {
    modifier onlyArcher {
        require(
            address(0x3CACa7b48D0573D793d3b0279b5F0029180E83b6) == msg.sender, //Archer contract address
            "ArcherPineCore: onlyArcher"
        );
        _;
    }

    function executeOrder(
        IModule _module,
        IERC20 _inputToken,
        address payable _owner,
        bytes calldata _data,
        bytes calldata _signature,
        bytes calldata _auxData
    ) public override onlyArcher {
        super.executeOrder(
            _module,
            _inputToken,
            _owner,
            _data,
            _signature,
            _auxData
        );
    }
}