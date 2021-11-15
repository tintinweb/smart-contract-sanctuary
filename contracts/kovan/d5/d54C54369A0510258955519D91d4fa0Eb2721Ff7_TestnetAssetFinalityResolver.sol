// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IAssetFinalityResolver Interface
/// @author Enzyme Council <[email protected]>
interface IAssetFinalityResolver {
    function finalizeAssets(address, address[] calldata) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../release/infrastructure/asset-finality/IAssetFinalityResolver.sol";

contract TestnetAssetFinalityResolver is IAssetFinalityResolver {
    function finalizeAssets(address _target, address[] memory _assets) external override {}
}

