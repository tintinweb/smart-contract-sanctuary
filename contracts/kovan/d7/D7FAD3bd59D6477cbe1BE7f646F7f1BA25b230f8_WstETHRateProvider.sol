// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "./interfaces/IRateProvider.sol";
import "./interfaces/ICToken.sol";

/**
 * @title cToken Rate Provider
 * @notice Returns the value of a cToken in terms of its underlying
 */
contract CTokenRateProvider is IRateProvider {
    ICToken public immutable cToken;

    constructor(ICToken _cToken) {
        require(_cToken.isCToken(), "Provided address is not cToken");
        cToken = _cToken;
    }

    /**
     * @return the value of RateProvider's cToken in terms of its underlying
     */
    function getRate() external view override returns (uint256) {
        return cToken.exchangeRateStored();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

// TODO: pull this from the monorepo
interface IRateProvider {
    function getRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

interface ICToken {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    function isCToken() external view returns (bool);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     */
    function exchangeRateStored() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "./interfaces/IRateProvider.sol";
import "./interfaces/IwstETH.sol";

/**
 * @title Wrapped stETH Rate Provider
 * @notice Returns the value of wstETH in terms of stETH
 */
contract WstETHRateProvider is IRateProvider {
    IwstETH public immutable wstETH;

    constructor(IwstETH _wstETH) {
        wstETH = _wstETH;
    }

    /**
     * @return the value of wstETH in terms of stETH
     */
    function getRate() external view override returns (uint256) {
        return wstETH.stEthPerToken();
    }
}

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.1;

/**
 * @title StETH token wrapper with static balances.
 * @dev It's an ERC20 token that represents the account's share of the total
 * supply of stETH tokens. WstETH token's balance only changes on transfers,
 * unlike StETH that is also changed when oracles report staking rewards and
 * penalties. It's a "power user" token for DeFi protocols which don't
 * support rebasable tokens.
 *
 * The contract is also a trustless wrapper that accepts stETH tokens and mints
 * wstETH in return. Then the user unwraps, the contract burns user's wstETH
 * and sends user locked stETH in return.
 *
 * The contract provides the staking shortcut: user can send ETH with regular
 * transfer and get wstETH in return. The contract will send ETH to Lido submit
 * method, staking it and wrapping the received stETH.
 *
 */
interface IwstETH {
    /**
     * @notice Get amount of wstETH for a one stETH
     * @return Amount of stETH for 1 wstETH
     */
    function stEthPerToken() external view returns (uint256);
}

