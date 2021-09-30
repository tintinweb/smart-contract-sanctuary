// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {IDCACore} from "./interfaces/IDCACore.sol";
import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";

contract DCACoreResolver {
    IDCACore public dcaCore;
    IUniswapV2Router public uniRouter;

    address public owner;

    constructor(address _dcaCore, address _uniRouter) {
        dcaCore = IDCACore(_dcaCore);
        uniRouter = IUniswapV2Router(_uniRouter);
        owner = msg.sender;
    }

    function getExecutablePositions()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256[] memory positionIds = dcaCore.getReadyPositionIds();
        IDCACore.Position[] memory positions = dcaCore.getPositions(
            positionIds
        );
        IDCACore.DCAExtraData[] memory extraDatas = new IDCACore.DCAExtraData[](
            positionIds.length
        );

        if (positions.length > 0) {
            canExec = true;
        }

        for (uint256 i = 0; i < positions.length; i++) {
            address[] memory path = new address[](2);
            path[0] = positions[i].tokenIn;
            path[1] = positions[i].tokenOut;

            uint256[] memory amounts = uniRouter.getAmountsOut(
                positions[i].amountDCA,
                path
            );

            extraDatas[i].swapAmountOutMin = amounts[1];
            extraDatas[i].swapPath = path;
        }

        execPayload = abi.encodeWithSelector(
            IDCACore.executeDCAs.selector,
            positionIds,
            extraDatas
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IDCACore {
    struct Position {
        uint256 id;
        address owner;
        address tokenIn;
        address tokenOut;
        uint256 balanceIn;
        uint256 balanceOut;
        uint256 amountDCA;
        uint256 intervalDCA;
        uint256 lastDCA; //timestamp
        uint256 maxSlippage;
    }

    struct DCAExtraData {
        // minimal swap output amount to prevent manipulation
        uint256 swapAmountOutMin;
        // swap path
        address[] swapPath;
    }

    event PositionCreated(
        uint256 indexed positionId,
        address indexed owner,
        address tokenIn,
        address tokenOut,
        uint256 amountDCA,
        uint256 intervalDCA,
        uint256 maxSlippage
    );
    event PositionUpdated(
        uint256 indexed positionId,
        uint256 indexed amountDCA,
        uint256 indexed intervalDCA
    );
    event Deposit(uint256 indexed positionId, uint256 indexed amount);
    event WithdrawTokenIn(uint256 indexed positionId, uint256 indexed amount);
    event WithdrawTokenOut(uint256 indexed positionId, uint256 indexed amount);
    event ExecuteDCA(uint256 indexed positionId);
    event AllowedTokenPairSet(
        address indexed tokenIn,
        address indexed tokenOut,
        bool indexed allowed
    );
    event MinSlippageSet(uint256 indexed minSlippage);
    event PausedSet(bool indexed paused);

    function executeDCA(uint256 _positionId, DCAExtraData calldata _extraData)
        external;

    function executeDCAs(
        uint256[] calldata _positionIds,
        DCAExtraData[] calldata _extraDatas
    ) external;

    function getReadyPositionIds() external view returns (uint256[] memory);

    function getPositions(uint256[] calldata positionIds)
        external
        view
        returns (Position[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}