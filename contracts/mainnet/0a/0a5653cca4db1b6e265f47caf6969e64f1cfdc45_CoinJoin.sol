/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

/// BasicTokenAdapters.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

abstract contract CollateralLike {
    function decimals() virtual public view returns (uint256);
    function transfer(address,uint256) virtual public returns (bool);
    function transferFrom(address,address,uint256) virtual public returns (bool);
}

abstract contract DSTokenLike {
    function mint(address,uint256) virtual external;
    function burn(address,uint256) virtual external;
}

abstract contract SAFEEngineLike {
    function modifyCollateralBalance(bytes32,address,int256) virtual external;
    function transferInternalCoins(address,address,uint256) virtual external;
}

contract CoinJoin {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CoinJoin/account-not-authorized");
        _;
    }

    // SAFE database
    SAFEEngineLike public safeEngine;
    // Coin created by the system; this is the external, ERC-20 representation, not the internal 'coinBalance'
    DSTokenLike    public systemCoin;
    // Whether this contract is enabled or not
    uint256        public contractEnabled;
    // Number of decimals the system coin has
    uint256        public decimals;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address account, uint256 wad);
    event Exit(address sender, address account, uint256 wad);

    constructor(address safeEngine_, address systemCoin_) public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled                = 1;
        safeEngine                     = SAFEEngineLike(safeEngine_);
        systemCoin                     = DSTokenLike(systemCoin_);
        decimals                       = 18;
        emit AddAuthorization(msg.sender);
    }
    /**
     * @notice Disable this contract
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }
    uint256 constant RAY = 10 ** 27;
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "CoinJoin/mul-overflow");
    }
    /**
    * @notice Join system coins in the system
    * @dev Exited coins have 18 decimals but inside the system they have 45 (rad) decimals.
           When we join, the amount (wad) is multiplied by 10**27 (ray)
    * @param account Account that will receive the joined coins
    * @param wad Amount of external coins to join (18 decimal number)
    **/
    function join(address account, uint256 wad) external {
        safeEngine.transferInternalCoins(address(this), account, multiply(RAY, wad));
        systemCoin.burn(msg.sender, wad);
        emit Join(msg.sender, account, wad);
    }
    /**
    * @notice Exit system coins from the system and inside 'Coin.sol'
    * @dev Inside the system, coins have 45 (rad) decimals but outside they have 18 decimals (wad).
           When we exit, we specify a wad amount of coins and then the contract automatically multiplies
           wad by 10**27 to move the correct 45 decimal coin amount to this adapter
    * @param account Account that will receive the exited coins
    * @param wad Amount of internal coins to join (18 decimal number that will be multiplied by ray)
    **/
    function exit(address account, uint256 wad) external {
        require(contractEnabled == 1, "CoinJoin/contract-not-enabled");
        safeEngine.transferInternalCoins(msg.sender, address(this), multiply(RAY, wad));
        systemCoin.mint(account, wad);
        emit Exit(msg.sender, account, wad);
    }
}