// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {Options} from "./structs/SOption.sol";

interface IOptionPool {
    function optionsByReceiver(address) external view returns(Options memory);

    function expiryTime() external view returns (uint256);

    function timeBeforeDeadLine() external view returns (uint256);

    function settle(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {OptionCanSettle} from "./structs/SOptionResolver.sol";
import {Option} from "./structs/SOption.sol";
import {IOptionPool} from "./IOptionPool.sol";


contract PokeMeResolver {
    function checker(OptionCanSettle memory optionCanSettle)
        public
        view
        returns (bool, bytes memory data)
    {
        IOptionPool pool = IOptionPool(optionCanSettle.pool);

        Option memory option = pool.optionsByReceiver(optionCanSettle.receiver
        ).opts[optionCanSettle.id];

        if (
            option.startTime + pool.expiryTime() + pool.timeBeforeDeadLine() >
            block.timestamp &&
            option.settled
        )
            return (
                false,
                abi.encodeWithSelector(
                    IOptionPool.settle.selector,
                    optionCanSettle.receiver,
                    optionCanSettle.id
                )
            );

        return (
            true,
            abi.encodeWithSelector(
                IOptionPool.settle.selector,
                optionCanSettle.receiver,
                optionCanSettle.id
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct Options {
    uint256 nextID;
    Option[] opts;
}

struct Option {
    uint256 notional;
    address receiver;
    uint256 price;
    uint256 startTime;
    bytes32 pokeMe;
    bool settled;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct OptionCanSettle {
    address pool;
    address receiver;
    uint256 id;
}