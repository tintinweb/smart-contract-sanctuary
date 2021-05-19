/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/GebProxySaviourActions.sol
pragma solidity =0.6.7 >=0.6.7;

////// lib/geb-proxy-registry/lib/ds-proxy/lib/ds-auth/src/auth.sol
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

/* pragma solidity >=0.6.7; */

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

abstract contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        virtual
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        virtual
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) virtual internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

////// src/GebProxyActions.sol
/// GebProxyActions.sol

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

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

/* pragma solidity 0.6.7; */

/* import "ds-auth/auth.sol"; */

abstract contract CollateralLike_3 {
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public;
    function transferFrom(address, address, uint) virtual public;
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
}

abstract contract ManagerLike {
    function safeCan(address, uint, address) virtual public view returns (uint);
    function collateralTypes(uint) virtual public view returns (bytes32);
    function ownsSAFE(uint) virtual public view returns (address);
    function safes(uint) virtual public view returns (address);
    function safeEngine() virtual public view returns (address);
    function openSAFE(bytes32, address) virtual public returns (uint);
    function transferSAFEOwnership(uint, address) virtual public;
    function allowSAFE(uint, address, uint) virtual public;
    function allowHandler(address, uint) virtual public;
    function modifySAFECollateralization(uint, int, int) virtual public;
    function transferCollateral(uint, address, uint) virtual public;
    function transferInternalCoins(uint, address, uint) virtual public;
    function quitSystem(uint, address) virtual public;
    function enterSystem(address, uint) virtual public;
    function moveSAFE(uint, uint) virtual public;
    function protectSAFE(uint, address, address) virtual public;
}

abstract contract SAFEEngineLike_15 {
    function canModifySAFE(address, address) virtual public view returns (uint);
    function collateralTypes(bytes32) virtual public view returns (uint, uint, uint, uint, uint);
    function coinBalance(address) virtual public view returns (uint);
    function safes(bytes32, address) virtual public view returns (uint, uint);
    function modifySAFECollateralization(bytes32, address, address, address, int, int) virtual public;
    function approveSAFEModification(address) virtual public;
    function transferInternalCoins(address, address, uint) virtual public;
}

abstract contract CollateralJoinLike_2 {
    function decimals() virtual public returns (uint);
    function collateral() virtual public returns (CollateralLike_3);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract GNTJoinLike {
    function bags(address) virtual public view returns (address);
    function make(address) virtual public returns (address);
}

abstract contract DSTokenLike_3 {
    function balanceOf(address) virtual public view returns (uint);
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public returns (bool);
    function transferFrom(address, address, uint) virtual public returns (bool);
}

abstract contract WethLike {
    function balanceOf(address) virtual public view returns (uint);
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public;
    function transferFrom(address, address, uint) virtual public;
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
}

abstract contract CoinJoinLike_3 {
    function safeEngine() virtual public returns (SAFEEngineLike_15);
    function systemCoin() virtual public returns (DSTokenLike_3);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract ApproveSAFEModificationLike {
    function approveSAFEModification(address) virtual public;
    function denySAFEModification(address) virtual public;
}

abstract contract GlobalSettlementLike_3 {
    function collateralCashPrice(bytes32) virtual public view returns (uint);
    function redeemCollateral(bytes32, uint) virtual public;
    function freeCollateral(bytes32) virtual public;
    function prepareCoinsForRedeeming(uint) virtual public;
    function processSAFE(bytes32, address) virtual public;
}

abstract contract TaxCollectorLike {
    function taxSingle(bytes32) virtual public returns (uint);
}

abstract contract CoinSavingsAccountLike_2 {
    function savings(address) virtual public view returns (uint);
    function updateAccumulatedRate() virtual public returns (uint);
    function deposit(uint) virtual public;
    function withdraw(uint) virtual public;
}

abstract contract ProxyRegistryLike {
    function proxies(address) virtual public view returns (address);
    function build(address) virtual public returns (address);
}

abstract contract ProxyLike {
    function owner() virtual public view returns (address);
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract Common {
    uint256 constant RAY = 10 ** 27;

    // Internal functions
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    function _coinJoin_join(address apt, address safeHandler, uint wad) internal {
        // Approves adapter to take the COIN amount
        CoinJoinLike_3(apt).systemCoin().approve(apt, wad);
        // Joins COIN into the safeEngine
        CoinJoinLike_3(apt).join(safeHandler, wad);
    }

    // Public functions
    function coinJoin_join(address apt, address safeHandler, uint wad) public {
        // Gets COIN from the user's wallet
        CoinJoinLike_3(apt).systemCoin().transferFrom(msg.sender, address(this), wad);

        _coinJoin_join(apt, safeHandler, wad);
    }
}

contract BasicActions is Common {
    // Internal functions

    /// @notice Safe subtraction
    /// @dev Reverts on overflows
    function subtract(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    /// @notice Safe conversion uint -> int
    /// @dev Reverts on overflows
    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    /// @notice Converts a wad (18 decimal places) to rad (45 decimal places)
    function toRad(uint wad) internal pure returns (uint rad) {
        rad = multiply(wad, 10 ** 27);
    }

    function convertTo18(address collateralJoin, uint256 amt) internal returns (uint256 wad) {
        // For those collaterals that have other than 18 decimals precision we need to do the conversion before passing to modifySAFECollateralization function
        // Adapters will automatically handle the difference of precision
        uint decimals = CollateralJoinLike_2(collateralJoin).decimals();
        wad = amt;
        if (decimals < 18) {
          wad = multiply(
              amt,
              10 ** (18 - decimals)
          );
        } else if (decimals > 18) {
          wad = amt / 10 ** (decimals - 18);
        }
    }

    /// @notice Gets delta debt generated (Total Safe debt minus available safeHandler COIN balance)
    /// @param safeEngine address
    /// @param taxCollector address
    /// @param safeHandler address
    /// @param collateralType bytes32
    /// @return deltaDebt
    function _getGeneratedDeltaDebt(
        address safeEngine,
        address taxCollector,
        address safeHandler,
        bytes32 collateralType,
        uint wad
    ) internal returns (int deltaDebt) {
        // Updates stability fee rate
        uint rate = TaxCollectorLike(taxCollector).taxSingle(collateralType);
        require(rate > 0, "invalid-collateral-type");

        // Gets COIN balance of the handler in the safeEngine
        uint coin = SAFEEngineLike_15(safeEngine).coinBalance(safeHandler);

        // If there was already enough COIN in the safeEngine balance, just exits it without adding more debt
        if (coin < multiply(wad, RAY)) {
            // Calculates the needed deltaDebt so together with the existing coins in the safeEngine is enough to exit wad amount of COIN tokens
            deltaDebt = toInt(subtract(multiply(wad, RAY), coin) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra deltaDebt wei (for the given COIN wad amount)
            deltaDebt = multiply(uint(deltaDebt), rate) < multiply(wad, RAY) ? deltaDebt + 1 : deltaDebt;
        }
    }

    /// @notice Gets repaid delta debt generated (rate adjusted debt)
    /// @param safeEngine address
    /// @param coin uint amount
    /// @param safe uint - safeId
    /// @param collateralType bytes32
        /// @return deltaDebt
    function _getRepaidDeltaDebt(
        address safeEngine,
        uint coin,
        address safe,
        bytes32 collateralType
    ) internal view returns (int deltaDebt) {
        // Gets actual rate from the safeEngine
        (, uint rate,,,) = SAFEEngineLike_15(safeEngine).collateralTypes(collateralType);
        require(rate > 0, "invalid-collateral-type");

        // Gets actual generatedDebt value of the safe
        (, uint generatedDebt) = SAFEEngineLike_15(safeEngine).safes(collateralType, safe);

        // Uses the whole coin balance in the safeEngine to reduce the debt
        deltaDebt = toInt(coin / rate);
        // Checks the calculated deltaDebt is not higher than safe.generatedDebt (total debt), otherwise uses its value
        deltaDebt = uint(deltaDebt) <= generatedDebt ? - deltaDebt : - toInt(generatedDebt);
    }

    /// @notice Gets repaid debt (rate adjusted rate minus COIN balance available in usr's address)
    /// @param safeEngine address
    /// @param usr address
    /// @param safe uint
    /// @param collateralType address
    /// @return wad
    function _getRepaidAlDebt(
        address safeEngine,
        address usr,
        address safe,
        bytes32 collateralType
    ) internal view returns (uint wad) {
        // Gets actual rate from the safeEngine
        (, uint rate,,,) = SAFEEngineLike_15(safeEngine).collateralTypes(collateralType);
        // Gets actual generatedDebt value of the safe
        (, uint generatedDebt) = SAFEEngineLike_15(safeEngine).safes(collateralType, safe);
        // Gets actual coin amount in the safe
        uint coin = SAFEEngineLike_15(safeEngine).coinBalance(usr);

        uint rad = subtract(multiply(generatedDebt, rate), coin);
        wad = rad / RAY;

        // If the rad precision has some dust, it will need to request for 1 extra wad wei
        wad = multiply(wad, RAY) < rad ? wad + 1 : wad;
    }

    /// @notice Generates Debt (and sends coin balance to address to)
    /// @param manager address
    /// @param taxCollector address
    /// @param coinJoin address
    /// @param safe uint
    /// @param wad uint - amount of debt to be generated
    /// @param to address - receiver of the balance of generated COIN
    function _generateDebt(address manager, address taxCollector, address coinJoin, uint safe, uint wad, address to) internal {
        address safeHandler = ManagerLike(manager).safes(safe);
        address safeEngine = ManagerLike(manager).safeEngine();
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        // Generates debt in the SAFE
        modifySAFECollateralization(manager, safe, 0, _getGeneratedDeltaDebt(safeEngine, taxCollector, safeHandler, collateralType, wad));
        // Moves the COIN amount (balance in the safeEngine in rad) to proxy's address
        transferInternalCoins(manager, safe, address(this), toRad(wad));
        // Allows adapter to access to proxy's COIN balance in the safeEngine
        if (SAFEEngineLike_15(safeEngine).canModifySAFE(address(this), address(coinJoin)) == 0) {
            SAFEEngineLike_15(safeEngine).approveSAFEModification(coinJoin);
        }
        // Exits COIN to this contract
        CoinJoinLike_3(coinJoin).exit(to, wad);
    }

    /// @notice Generates Debt (and sends coin balance to address to)
    /// @param manager address
    /// @param ethJoin address
    /// @param safe uint
    /// @param value uint - amount of ETH to be locked in the Safe.
    /// @dev Proxy needs to have enough balance (> value), public functions should handle this.
    function _lockETH(
        address manager,
        address ethJoin,
        uint safe,
        uint value
    ) internal {
        // Receives ETH amount, converts it to WETH and joins it into the safeEngine
        ethJoin_join(ethJoin, address(this), value);
        // Locks WETH amount into the SAFE
        SAFEEngineLike_15(ManagerLike(manager).safeEngine()).modifySAFECollateralization(
            ManagerLike(manager).collateralTypes(safe),
            ManagerLike(manager).safes(safe),
            address(this),
            address(this),
            toInt(value),
            0
        );
    }

    /// @notice Repays debt
    /// @param manager address
    /// @param coinJoin address
    /// @param safe uint
    /// @param wad uint - amount of debt to be repayed
    function _repayDebt(
        address manager,
        address coinJoin,
        uint safe,
        uint wad,
        bool transferFromCaller
    ) internal {
        address safeEngine = ManagerLike(manager).safeEngine();
        address safeHandler = ManagerLike(manager).safes(safe);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);

        address own = ManagerLike(manager).ownsSAFE(safe);
        if (own == address(this) || ManagerLike(manager).safeCan(own, safe, address(this)) == 1) {
            // Joins COIN amount into the safeEngine
            if (transferFromCaller) coinJoin_join(coinJoin, safeHandler, wad);
            else _coinJoin_join(coinJoin, safeHandler, wad);
            // // Paybacks debt to the SAFE
            modifySAFECollateralization(manager, safe, 0, _getRepaidDeltaDebt(safeEngine, SAFEEngineLike_15(safeEngine).coinBalance(safeHandler), safeHandler, collateralType));
        } else {
             // Joins COIN amount into the safeEngine
            if (transferFromCaller) coinJoin_join(coinJoin, address(this), wad);
            else _coinJoin_join(coinJoin, address(this), wad);
            // Paybacks debt to the SAFE
            SAFEEngineLike_15(safeEngine).modifySAFECollateralization(
                collateralType,
                safeHandler,
                address(this),
                address(this),
                0,
                _getRepaidDeltaDebt(safeEngine, wad * RAY, safeHandler, collateralType)
            );
        }
    }

    /// @notice Repays debt and frees collateral ETH
    /// @param manager address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param safe uint
    /// @param collateralWad uint - amount of ETH to free
    /// @param deltaWad uint - amount of debt to be repayed
    /// @param transferFromCaller True if transferring coin from caller, false if balance in the proxy
    function _repayDebtAndFreeETH(
        address manager,
        address ethJoin,
        address coinJoin,
        uint safe,
        uint collateralWad,
        uint deltaWad,
        bool transferFromCaller
    ) internal {
        address safeHandler = ManagerLike(manager).safes(safe);
        // Joins COIN amount into the safeEngine
        if (transferFromCaller) coinJoin_join(coinJoin, safeHandler, deltaWad);
        else _coinJoin_join(coinJoin, safeHandler, deltaWad);
        // Paybacks debt to the SAFE and unlocks WETH amount from it
        modifySAFECollateralization(
            manager,
            safe,
            -toInt(collateralWad),
            _getRepaidDeltaDebt(ManagerLike(manager).safeEngine(), SAFEEngineLike_15(ManagerLike(manager).safeEngine()).coinBalance(safeHandler), safeHandler, ManagerLike(manager).collateralTypes(safe))
        );
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), collateralWad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike_2(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike_2(ethJoin).collateral().withdraw(collateralWad);
    }

    // Public functions

    /// @notice ERC20 transfer
    /// @param collateral address - address of ERC20 collateral
    /// @param dst address - Transfer destination
    /// @param amt address - Amount to transfer
    function transfer(address collateral, address dst, uint amt) external {
        CollateralLike_3(collateral).transfer(dst, amt);
    }

    /// @notice Joins the system with the full msg.value
    /// @param apt address - Address of the adapter
    /// @param safe uint - Safe Id
    function ethJoin_join(address apt, address safe) external payable {
        ethJoin_join(apt, safe, msg.value);
    }

    /// @notice Joins the system with the a specified value
    /// @param apt address - Address of the adapter
    /// @param safe uint - Safe Id
    /// @param value uint - Value to join
    function ethJoin_join(address apt, address safe, uint value) public payable {
        // Wraps ETH in WETH
        CollateralJoinLike_2(apt).collateral().deposit{value: value}();
        // Approves adapter to take the WETH amount
        CollateralJoinLike_2(apt).collateral().approve(address(apt), value);
        // Joins WETH collateral into the safeEngine
        CollateralJoinLike_2(apt).join(safe, value);
    }

    /// @notice Approves an address to modify the Safe
    /// @param safeEngine address
    /// @param usr address - Address allowed to modify Safe
    function approveSAFEModification(
        address safeEngine,
        address usr
    ) external {
        ApproveSAFEModificationLike(safeEngine).approveSAFEModification(usr);
    }

    /// @notice Denies an address to modify the Safe
    /// @param safeEngine address
    /// @param usr address - Address disallowed to modify Safe
    function denySAFEModification(
        address safeEngine,
        address usr
    ) external {
        ApproveSAFEModificationLike(safeEngine).denySAFEModification(usr);
    }

    /// @notice Opens a brand new Safe
    /// @param manager address - Safe Manager
    /// @param collateralType bytes32 - collateral type
    /// @param usr address - Owner of the safe
    function openSAFE(
        address manager,
        bytes32 collateralType,
        address usr
    ) public returns (uint safe) {
        safe = ManagerLike(manager).openSAFE(collateralType, usr);
    }

    /// @notice Transfer the ownership of a proxy owned Safe
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param usr address - Owner of the safe
    function transferSAFEOwnership(
        address manager,
        uint safe,
        address usr
    ) public {
        ManagerLike(manager).transferSAFEOwnership(safe, usr);
    }

    /// @notice Transfer the ownership to a new proxy owned by a different address
    /// @param proxyRegistry address - Safe Manager
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param dst address - Owner of the new proxy
    function transferSAFEOwnershipToProxy(
        address proxyRegistry,
        address manager,
        uint safe,
        address dst
    ) external {
        // Gets actual proxy address
        address proxy = ProxyRegistryLike(proxyRegistry).proxies(dst);
        // Checks if the proxy address already existed and dst address is still the owner
        if (proxy == address(0) || ProxyLike(proxy).owner() != dst) {
            uint csize;
            assembly {
                csize := extcodesize(dst)
            }
            // We want to avoid creating a proxy for a contract address that might not be able to handle proxies, then losing the SAFE
            require(csize == 0, "dst-is-a-contract");
            // Creates the proxy for the dst address
            proxy = ProxyRegistryLike(proxyRegistry).build(dst);
        }
        // Transfers SAFE to the dst proxy
        transferSAFEOwnership(manager, safe, proxy);
    }

    /// @notice Allow/disallow a usr address to manage the safe
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param usr address - usr address
    /// uint ok - 1 for allowed
    function allowSAFE(
        address manager,
        uint safe,
        address usr,
        uint ok
    ) external {
        ManagerLike(manager).allowSAFE(safe, usr, ok);
    }

    /// @notice Allow/disallow a usr address to quit to the sender handler
    /// @param manager address - Safe Manager
    /// @param usr address - usr address
    /// uint ok - 1 for allowed
    function allowHandler(
        address manager,
        address usr,
        uint ok
    ) external {
        ManagerLike(manager).allowHandler(usr, ok);
    }

    /// @notice Transfer wad amount of safe collateral from the safe address to a dst address.
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param dst address - destination address
    /// uint wad - amount
    function transferCollateral(
        address manager,
        uint safe,
        address dst,
        uint wad
    ) public {
        ManagerLike(manager).transferCollateral(safe, dst, wad);
    }

    /// @notice Transfer rad amount of COIN from the safe address to a dst address.
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param dst address - destination address
    /// uint rad - amount
    function transferInternalCoins(
        address manager,
        uint safe,
        address dst,
        uint rad
    ) public {
        ManagerLike(manager).transferInternalCoins(safe, dst, rad);
    }


    /// @notice Modify a SAFE's collateralization ratio while keeping the generated COIN or collateral freed in the SAFE handler address.
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param deltaCollateral - int
    /// @param deltaDebt - int
    function modifySAFECollateralization(
        address manager,
        uint safe,
        int deltaCollateral,
        int deltaDebt
    ) public {
        ManagerLike(manager).modifySAFECollateralization(safe, deltaCollateral, deltaDebt);
    }

    /// @notice Quit the system, migrating the safe (lockedCollateral, generatedDebt) to a different dst handler
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param dst - destination handler
    function quitSystem(
        address manager,
        uint safe,
        address dst
    ) external {
        ManagerLike(manager).quitSystem(safe, dst);
    }

    /// @notice Import a position from src handler to the handler owned by safe
    /// @param manager address - Safe Manager
    /// @param src - source handler
    /// @param safe uint - Safe Id
    function enterSystem(
        address manager,
        address src,
        uint safe
    ) external {
        ManagerLike(manager).enterSystem(src, safe);
    }

    /// @notice Move a position from safeSrc handler to the safeDst handler
    /// @param manager address - Safe Manager
    /// @param safeSrc uint - Source Safe Id
    /// @param safeDst uint - Destination Safe Id
    function moveSAFE(
        address manager,
        uint safeSrc,
        uint safeDst
    ) external {
        ManagerLike(manager).moveSAFE(safeSrc, safeDst);
    }

    /// @notice Lock ETH (msg.value) as collateral in safe
    /// @param manager address - Safe Manager
    /// @param ethJoin address
    /// @param safe uint - Safe Id
    function lockETH(
        address manager,
        address ethJoin,
        uint safe
    ) public payable {
        _lockETH(manager, ethJoin, safe, msg.value);
    }

    /// @notice Free ETH (wad) from safe and sends it to msg.sender
    /// @param manager address - Safe Manager
    /// @param ethJoin address
    /// @param safe uint - Safe Id
    /// @param wad uint - Amount
    function freeETH(
        address manager,
        address ethJoin,
        uint safe,
        uint wad
    ) public {
        // Unlocks WETH amount from the SAFE
        modifySAFECollateralization(manager, safe, -toInt(wad), 0);
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), wad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike_2(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike_2(ethJoin).collateral().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }


    /// @notice Exits ETH (wad) from balance available in the handler
    /// @param manager address - Safe Manager
    /// @param ethJoin address
    /// @param safe uint - Safe Id
    /// @param wad uint - Amount
    function exitETH(
        address manager,
        address ethJoin,
        uint safe,
        uint wad
    ) external {
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), wad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike_2(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike_2(ethJoin).collateral().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    /// @notice Generates debt and sends COIN amount to msg.sender
    /// @param manager address
    /// @param taxCollector address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param wad uint - Amount
    function generateDebt(
        address manager,
        address taxCollector,
        address coinJoin,
        uint safe,
        uint wad
    ) public {
        _generateDebt(manager, taxCollector, coinJoin, safe, wad, msg.sender);
    }

    /// @notice Repays debt
    /// @param manager address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param wad uint - Amount
    function repayDebt(
        address manager,
        address coinJoin,
        uint safe,
        uint wad
    ) public {
        _repayDebt(manager, coinJoin, safe, wad, true);
    }

    /// @notice Locks Eth, generates debt and sends COIN amount (deltaWad) to msg.sender
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param deltaWad uint - Amount
    function lockETHAndGenerateDebt(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        uint safe,
        uint deltaWad
    ) public payable {
        _lockETH(manager, ethJoin, safe, msg.value);
        _generateDebt(manager, taxCollector, coinJoin, safe, deltaWad, msg.sender);
    }

    /// @notice Opens Safe, locks Eth, generates debt and sends COIN amount (deltaWad) to msg.sender
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param deltaWad uint - Amount
    function openLockETHAndGenerateDebt(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        bytes32 collateralType,
        uint deltaWad
    ) external payable returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        lockETHAndGenerateDebt(manager, taxCollector, ethJoin, coinJoin, safe, deltaWad);
    }

    /// @notice Repays debt and frees ETH (sends it to msg.sender)
    /// @param manager address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param collateralWad uint - Amount of collateral to free
    /// @param deltaWad uint - Amount of debt to repay
    function repayDebtAndFreeETH(
        address manager,
        address ethJoin,
        address coinJoin,
        uint safe,
        uint collateralWad,
        uint deltaWad
    ) external {
        _repayDebtAndFreeETH(manager, ethJoin, coinJoin, safe, collateralWad, deltaWad, true);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(collateralWad);
    }    
}

contract GebProxyActions is BasicActions {

    function tokenCollateralJoin_join(address apt, address safe, uint amt, bool transferFrom) public {
        // Only executes for tokens that have approval/transferFrom implementation
        if (transferFrom) {
            // Gets token from the user's wallet
            CollateralJoinLike_2(apt).collateral().transferFrom(msg.sender, address(this), amt);
            // Approves adapter to take the token amount
            CollateralJoinLike_2(apt).collateral().approve(apt, amt);
        }
        // Joins token collateral into the safeEngine
        CollateralJoinLike_2(apt).join(safe, amt);
    }

    function protectSAFE(
        address manager,
        uint safe,
        address liquidationEngine,
        address saviour
    ) public {
        ManagerLike(manager).protectSAFE(safe, liquidationEngine, saviour);
    }

    function makeCollateralBag(
        address collateralJoin
    ) public returns (address bag) {
        bag = GNTJoinLike(collateralJoin).make(address(this));
    }

    function safeLockETH(
        address manager,
        address ethJoin,
        uint safe,
        address owner
    ) public payable {
        require(ManagerLike(manager).ownsSAFE(safe) == owner, "owner-missmatch");
        lockETH(manager, ethJoin, safe);
    }

    function lockTokenCollateral(
        address manager,
        address collateralJoin,
        uint safe,
        uint amt,
        bool transferFrom
    ) public {
        // Takes token amount from user's wallet and joins into the safeEngine
        tokenCollateralJoin_join(collateralJoin, address(this), amt, transferFrom);
        // Locks token amount into the SAFE
        SAFEEngineLike_15(ManagerLike(manager).safeEngine()).modifySAFECollateralization(
            ManagerLike(manager).collateralTypes(safe),
            ManagerLike(manager).safes(safe),
            address(this),
            address(this),
            toInt(convertTo18(collateralJoin, amt)),
            0
        );
    }

    function safeLockTokenCollateral(
        address manager,
        address collateralJoin,
        uint safe,
        uint amt,
        bool transferFrom,
        address owner
    ) public {
        require(ManagerLike(manager).ownsSAFE(safe) == owner, "owner-missmatch");
        lockTokenCollateral(manager, collateralJoin, safe, amt, transferFrom);
    }

    function freeTokenCollateral(
        address manager,
        address collateralJoin,
        uint safe,
        uint amt
    ) public {
        uint wad = convertTo18(collateralJoin, amt);
        // Unlocks token amount from the SAFE
        modifySAFECollateralization(manager, safe, -toInt(wad), 0);
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), wad);
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike_2(collateralJoin).exit(msg.sender, amt);
    }

    function exitTokenCollateral(
        address manager,
        address collateralJoin,
        uint safe,
        uint amt
    ) public {
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), convertTo18(collateralJoin, amt));

        // Exits token amount to the user's wallet as a token
        CollateralJoinLike_2(collateralJoin).exit(msg.sender, amt);
    }

    function generateDebtAndProtectSAFE(
        address manager,
        address taxCollector,
        address coinJoin,
        uint safe,
        uint wad,
        address liquidationEngine,
        address saviour
    ) external {
        generateDebt(manager, taxCollector, coinJoin, safe, wad);
        protectSAFE(manager, safe, liquidationEngine, saviour);
    }

    function safeRepayDebt(
        address manager,
        address coinJoin,
        uint safe,
        uint wad,
        address owner
    ) public {
        require(ManagerLike(manager).ownsSAFE(safe) == owner, "owner-missmatch");
        repayDebt(manager, coinJoin, safe, wad);
    }

    function repayAllDebt(
        address manager,
        address coinJoin,
        uint safe
    ) public {
        address safeEngine = ManagerLike(manager).safeEngine();
        address safeHandler = ManagerLike(manager).safes(safe);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        (, uint generatedDebt) = SAFEEngineLike_15(safeEngine).safes(collateralType, safeHandler);

        address own = ManagerLike(manager).ownsSAFE(safe);
        if (own == address(this) || ManagerLike(manager).safeCan(own, safe, address(this)) == 1) {
            // Joins COIN amount into the safeEngine
            coinJoin_join(coinJoin, safeHandler, _getRepaidAlDebt(safeEngine, safeHandler, safeHandler, collateralType));
            // Paybacks debt to the SAFE
            modifySAFECollateralization(manager, safe, 0, -int(generatedDebt));
        } else {
            // Joins COIN amount into the safeEngine
            coinJoin_join(coinJoin, address(this), _getRepaidAlDebt(safeEngine, address(this), safeHandler, collateralType));
            // Paybacks debt to the SAFE
            SAFEEngineLike_15(safeEngine).modifySAFECollateralization(
                collateralType,
                safeHandler,
                address(this),
                address(this),
                0,
                -int(generatedDebt)
            );
        }
    }

    function safeRepayAllDebt(
        address manager,
        address coinJoin,
        uint safe,
        address owner
    ) public {
        require(ManagerLike(manager).ownsSAFE(safe) == owner, "owner-missmatch");
        repayAllDebt(manager, coinJoin, safe);
    }

    function openLockETHGenerateDebtAndProtectSAFE(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        bytes32 collateralType,
        uint deltaWad,
        address liquidationEngine,
        address saviour
    ) public payable returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        lockETHAndGenerateDebt(manager, taxCollector, ethJoin, coinJoin, safe, deltaWad);
        protectSAFE(manager, safe, liquidationEngine, saviour);
    }

    function lockTokenCollateralAndGenerateDebt(
        address manager,
        address taxCollector,
        address collateralJoin,
        address coinJoin,
        uint safe,
        uint collateralAmount,
        uint deltaWad,
        bool transferFrom
    ) public {
        address safeHandler = ManagerLike(manager).safes(safe);
        address safeEngine = ManagerLike(manager).safeEngine();
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        // Takes token amount from user's wallet and joins into the safeEngine
        tokenCollateralJoin_join(collateralJoin, safeHandler, collateralAmount, transferFrom);
        // Locks token amount into the SAFE and generates debt
        modifySAFECollateralization(manager, safe, toInt(convertTo18(collateralJoin, collateralAmount)), _getGeneratedDeltaDebt(safeEngine, taxCollector, safeHandler, collateralType, deltaWad));
        // Moves the COIN amount (balance in the safeEngine in rad) to proxy's address
        transferInternalCoins(manager, safe, address(this), toRad(deltaWad));
        // Allows adapter to access to proxy's COIN balance in the safeEngine
        if (SAFEEngineLike_15(safeEngine).canModifySAFE(address(this), address(coinJoin)) == 0) {
            SAFEEngineLike_15(safeEngine).approveSAFEModification(coinJoin);
        }
        // Exits COIN to the user's wallet as a token
        CoinJoinLike_3(coinJoin).exit(msg.sender, deltaWad);
    }

    function lockTokenCollateralGenerateDebtAndProtectSAFE(
        address manager,
        address taxCollector,
        address collateralJoin,
        address coinJoin,
        uint safe,
        uint collateralAmount,
        uint deltaWad,
        bool transferFrom,
        address liquidationEngine,
        address saviour
    ) public {
        lockTokenCollateralAndGenerateDebt(
          manager,
          taxCollector,
          collateralJoin,
          coinJoin,
          safe,
          collateralAmount,
          deltaWad,
          transferFrom
        );
        protectSAFE(manager, safe, liquidationEngine, saviour);
    }

    function openLockTokenCollateralAndGenerateDebt(
        address manager,
        address taxCollector,
        address collateralJoin,
        address coinJoin,
        bytes32 collateralType,
        uint collateralAmount,
        uint deltaWad,
        bool transferFrom
    ) public returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        lockTokenCollateralAndGenerateDebt(manager, taxCollector, collateralJoin, coinJoin, safe, collateralAmount, deltaWad, transferFrom);
    }

    function openLockTokenCollateralGenerateDebtAndProtectSAFE(
        address manager,
        address taxCollector,
        address collateralJoin,
        address coinJoin,
        bytes32 collateralType,
        uint collateralAmount,
        uint deltaWad,
        bool transferFrom,
        address liquidationEngine,
        address saviour
    ) public returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        lockTokenCollateralAndGenerateDebt(manager, taxCollector, collateralJoin, coinJoin, safe, collateralAmount, deltaWad, transferFrom);
        protectSAFE(manager, safe, liquidationEngine, saviour);
    }

    function openLockGNTAndGenerateDebt(
        address manager,
        address taxCollector,
        address gntJoin,
        address coinJoin,
        bytes32 collateralType,
        uint collateralAmount,
        uint deltaWad
    ) public returns (address bag, uint safe) {
        // Creates bag (if doesn't exist) to hold GNT
        bag = GNTJoinLike(gntJoin).bags(address(this));
        if (bag == address(0)) {
            bag = makeCollateralBag(gntJoin);
        }
        // Transfer funds to the funds which previously were sent to the proxy
        CollateralLike_3(CollateralJoinLike_2(gntJoin).collateral()).transfer(bag, collateralAmount);
        safe = openLockTokenCollateralAndGenerateDebt(manager, taxCollector, gntJoin, coinJoin, collateralType, collateralAmount, deltaWad, false);
    }

    function openLockGNTGenerateDebtAndProtectSAFE(
        address manager,
        address taxCollector,
        address gntJoin,
        address coinJoin,
        bytes32 collateralType,
        uint collateralAmount,
        uint deltaWad,
        address liquidationEngine,
        address saviour
    ) public returns (address bag, uint safe) {
        (bag, safe) = openLockGNTAndGenerateDebt(
          manager,
          taxCollector,
          gntJoin,
          coinJoin,
          collateralType,
          collateralAmount,
          deltaWad
        );
        protectSAFE(manager, safe, liquidationEngine, saviour);
    }

    function repayAllDebtAndFreeETH(
        address manager,
        address ethJoin,
        address coinJoin,
        uint safe,
        uint collateralWad
    ) public {
        address safeEngine = ManagerLike(manager).safeEngine();
        address safeHandler = ManagerLike(manager).safes(safe);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        (, uint generatedDebt) = SAFEEngineLike_15(safeEngine).safes(collateralType, safeHandler);

        // Joins COIN amount into the safeEngine
        coinJoin_join(coinJoin, safeHandler, _getRepaidAlDebt(safeEngine, safeHandler, safeHandler, collateralType));
        // Paybacks debt to the SAFE and unlocks WETH amount from it
        modifySAFECollateralization(
            manager,
            safe,
            -toInt(collateralWad),
            -int(generatedDebt)
        );
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), collateralWad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike_2(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike_2(ethJoin).collateral().withdraw(collateralWad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(collateralWad);
    }

    function repayDebtAndFreeTokenCollateral(
        address manager,
        address collateralJoin,
        address coinJoin,
        uint safe,
        uint collateralAmount,
        uint deltaWad
    ) external {
        address safeHandler = ManagerLike(manager).safes(safe);
        // Joins COIN amount into the safeEngine
        coinJoin_join(coinJoin, safeHandler, deltaWad);
        uint collateralWad = convertTo18(collateralJoin, collateralAmount);
        // Paybacks debt to the SAFE and unlocks token amount from it
        modifySAFECollateralization(
            manager,
            safe,
            -toInt(collateralWad),
            _getRepaidDeltaDebt(ManagerLike(manager).safeEngine(), SAFEEngineLike_15(ManagerLike(manager).safeEngine()).coinBalance(safeHandler), safeHandler, ManagerLike(manager).collateralTypes(safe))
        );
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), collateralWad);
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike_2(collateralJoin).exit(msg.sender, collateralAmount);
    }

    function repayAllDebtAndFreeTokenCollateral(
        address manager,
        address collateralJoin,
        address coinJoin,
        uint safe,
        uint collateralAmount
    ) public {
        address safeEngine = ManagerLike(manager).safeEngine();
        address safeHandler = ManagerLike(manager).safes(safe);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        (, uint generatedDebt) = SAFEEngineLike_15(safeEngine).safes(collateralType, safeHandler);

        // Joins COIN amount into the safeEngine
        coinJoin_join(coinJoin, safeHandler, _getRepaidAlDebt(safeEngine, safeHandler, safeHandler, collateralType));
        uint collateralWad = convertTo18(collateralJoin, collateralAmount);
        // Paybacks debt to the SAFE and unlocks token amount from it
        modifySAFECollateralization(
            manager,
            safe,
            -toInt(collateralWad),
            -int(generatedDebt)
        );
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), collateralWad);
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike_2(collateralJoin).exit(msg.sender, collateralAmount);
    }
}

contract GebProxyActionsGlobalSettlement is Common {

    // Internal functions
    function _freeCollateral(
        address manager,
        address globalSettlement,
        uint safe
    ) internal returns (uint lockedCollateral) {
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        address safeHandler = ManagerLike(manager).safes(safe);
        SAFEEngineLike_15 safeEngine = SAFEEngineLike_15(ManagerLike(manager).safeEngine());
        uint generatedDebt;
        (lockedCollateral, generatedDebt) = safeEngine.safes(collateralType, safeHandler);

        // If SAFE still has debt, it needs to be paid
        if (generatedDebt > 0) {
            GlobalSettlementLike_3(globalSettlement).processSAFE(collateralType, safeHandler);
            (lockedCollateral,) = safeEngine.safes(collateralType, safeHandler);
        }
        // Approves the manager to transfer the position to proxy's address in the safeEngine
        if (safeEngine.canModifySAFE(address(this), address(manager)) == 0) {
            safeEngine.approveSAFEModification(manager);
        }
        // Transfers position from SAFE to the proxy address
        ManagerLike(manager).quitSystem(safe, address(this));
        // Frees the position and recovers the collateral in the safeEngine registry
        GlobalSettlementLike_3(globalSettlement).freeCollateral(collateralType);
    }

    // Public functions
    function freeETH(
        address manager,
        address ethJoin,
        address globalSettlement,
        uint safe
    ) external {
        uint wad = _freeCollateral(manager, globalSettlement, safe);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike_2(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike_2(ethJoin).collateral().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    function freeTokenCollateral(
        address manager,
        address collateralJoin,
        address globalSettlement,
        uint safe
    ) public {
        uint amt = _freeCollateral(manager, globalSettlement, safe) / 10 ** (18 - CollateralJoinLike_2(collateralJoin).decimals());
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike_2(collateralJoin).exit(msg.sender, amt);
    }

    function prepareCoinsForRedeeming(
        address coinJoin,
        address globalSettlement,
        uint wad
    ) public {
        coinJoin_join(coinJoin, address(this), wad);
        SAFEEngineLike_15 safeEngine = CoinJoinLike_3(coinJoin).safeEngine();
        // Approves the globalSettlement to take out COIN from the proxy's balance in the safeEngine
        if (safeEngine.canModifySAFE(address(this), address(globalSettlement)) == 0) {
            safeEngine.approveSAFEModification(globalSettlement);
        }
        GlobalSettlementLike_3(globalSettlement).prepareCoinsForRedeeming(wad);
    }

    function redeemETH(
        address ethJoin,
        address globalSettlement,
        bytes32 collateralType,
        uint wad
    ) public {
        GlobalSettlementLike_3(globalSettlement).redeemCollateral(collateralType, wad);
        uint collateralWad = multiply(wad, GlobalSettlementLike_3(globalSettlement).collateralCashPrice(collateralType)) / RAY;
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike_2(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike_2(ethJoin).collateral().withdraw(collateralWad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(collateralWad);
    }

    function redeemTokenCollateral(
        address collateralJoin,
        address globalSettlement,
        bytes32 collateralType,
        uint wad
    ) public {
        GlobalSettlementLike_3(globalSettlement).redeemCollateral(collateralType, wad);
        // Exits token amount to the user's wallet as a token
        uint amt = multiply(wad, GlobalSettlementLike_3(globalSettlement).collateralCashPrice(collateralType)) / RAY / 10 ** (18 - CollateralJoinLike_2(collateralJoin).decimals());
        CollateralJoinLike_2(collateralJoin).exit(msg.sender, amt);
    }
}

contract GebProxyActionsCoinSavingsAccount is Common {

    function deposit(
        address coinJoin,
        address coinSavingsAccount,
        uint wad
    ) public {
        SAFEEngineLike_15 safeEngine = CoinJoinLike_3(coinJoin).safeEngine();
        // Executes updateAccumulatedRate to get the accumulatedRates updated to latestUpdateTime == now, otherwise join will fail
        uint accumulatedRates = CoinSavingsAccountLike_2(coinSavingsAccount).updateAccumulatedRate();
        // Joins wad amount to the safeEngine balance
        coinJoin_join(coinJoin, address(this), wad);
        // Approves the coinSavingsAccount to take out COIN from the proxy's balance in the safeEngine
        if (safeEngine.canModifySAFE(address(this), address(coinSavingsAccount)) == 0) {
            safeEngine.approveSAFEModification(coinSavingsAccount);
        }
        // Joins the savings value (equivalent to the COIN wad amount) in the coinSavingsAccount
        CoinSavingsAccountLike_2(coinSavingsAccount).deposit(multiply(wad, RAY) / accumulatedRates);
    }

    function withdraw(
        address coinJoin,
        address coinSavingsAccount,
        uint wad
    ) public {
        SAFEEngineLike_15 safeEngine = CoinJoinLike_3(coinJoin).safeEngine();
        // Executes updateAccumulatedRate to count the savings accumulated until this moment
        uint accumulatedRates = CoinSavingsAccountLike_2(coinSavingsAccount).updateAccumulatedRate();
        // Calculates the savings value in the coinSavingsAccount equivalent to the COIN wad amount
        uint savings = multiply(wad, RAY) / accumulatedRates;
        // Exits COIN from the coinSavingsAccount
        CoinSavingsAccountLike_2(coinSavingsAccount).withdraw(savings);
        // Checks the actual balance of COIN in the safeEngine after the coinSavingsAccount exit
        uint bal = CoinJoinLike_3(coinJoin).safeEngine().coinBalance(address(this));
        // Allows adapter to access to proxy's COIN balance in the safeEngine
        if (safeEngine.canModifySAFE(address(this), address(coinJoin)) == 0) {
            safeEngine.approveSAFEModification(coinJoin);
        }
        // It is necessary to check if due rounding the exact wad amount can be exited by the adapter.
        // Otherwise it will do the minimum COIN balance in the safeEngine
        CoinJoinLike_3(coinJoin).exit(
            msg.sender,
            bal >= multiply(wad, RAY) ? wad : bal / RAY
        );
    }

    function withdrawAll(
        address coinJoin,
        address coinSavingsAccount
    ) public {
        SAFEEngineLike_15 safeEngine = CoinJoinLike_3(coinJoin).safeEngine();
        // Executes updateAccumulatedRate to count the savings accumulated until this moment
        uint accumulatedRates = CoinSavingsAccountLike_2(coinSavingsAccount).updateAccumulatedRate();
        // Gets the total savings belonging to the proxy address
        uint savings = CoinSavingsAccountLike_2(coinSavingsAccount).savings(address(this));
        // Exits COIN from the coinSavingsAccount
        CoinSavingsAccountLike_2(coinSavingsAccount).withdraw(savings);
        // Allows adapter to access to proxy's COIN balance in the safeEngine
        if (safeEngine.canModifySAFE(address(this), address(coinJoin)) == 0) {
            safeEngine.approveSAFEModification(coinJoin);
        }
        // Exits the COIN amount corresponding to the value of savings
        CoinJoinLike_3(coinJoin).exit(msg.sender, multiply(accumulatedRates, savings) / RAY);
    }
}


////// src/GebProxySaviourActions.sol
/// GebProxySaviourActions.sol

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

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

/* pragma solidity 0.6.7; */

/* import "./GebProxyActions.sol"; */

abstract contract GebSaviourLike {
    function deposit(uint256, uint256) virtual external;
    function deposit(bytes32, uint256, uint256) virtual external;
    function withdraw(uint256, uint256, address) virtual external;
    function withdraw(bytes32, uint256, uint256, address) virtual external;
    function getReserves(uint256, address) virtual external;
}
abstract contract SaviourCRatioSetterLike_2 {
    function setDesiredCollateralizationRatio(bytes32, uint256, uint256) virtual external;
}

/// @title Saviour proxy actions
/// @notice This contract is supposed to be used alongside a DSProxy contract
/// @dev These functions are meant to be used as a a library for a DSProxy
contract GebProxySaviourActions {
    // --- Internal Logic ---
    /*
    * @notice Transfer a token from the caller to the proxy and approve another address to pull the tokens from the proxy
    * @param token The token being transferred and approved
    * @param target The address that can pull tokens from the proxy
    * @param amount The amount of tokens being transferred and approved
    */
    function transferTokenFromAndApprove(address token, address target, uint256 amount) internal {
        DSTokenLike_3(token).transferFrom(msg.sender, address(this), amount);
        DSTokenLike_3(token).approve(target, 0);
        DSTokenLike_3(token).approve(target, amount);
    }

    // --- External Logic ---
    /*
    * @notice Transfer all tokens that the proxy has out of an array of tokens to the caller
    * @param tokens The array of tokens being transfered
    */
    function transferTokensToCaller(address[] memory tokens) public {
        for (uint i = 0; i < tokens.length; i++) {
            uint256 selfBalance = DSTokenLike_3(tokens[i]).balanceOf(address(this));
            if (selfBalance > 0) {
              DSTokenLike_3(tokens[i]).transfer(msg.sender, selfBalance);
            }
        }
    }
    /*
    * @notice Attach a saviour to a SAFE
    * @param saviour The saviour contract being attached
    * @param manager The SAFE manager contract
    * @param safe The ID of the SAFE being covered
    * @param liquidationEngine The LiquidationEngine contract
    */
    function protectSAFE(
        address saviour,
        address manager,
        uint safe,
        address liquidationEngine
    ) public {
        ManagerLike(manager).protectSAFE(safe, liquidationEngine, saviour);
    }
    /*
    * @notice Set a custom desired collateralization ratio for a specific SAFE
    * @param cRatioSetter The address of the saviour cRatio setter
    * @param collateralType The collateral type of the SAFE
    * @param safe The ID of the SAFE
    * @param cRatio The desired collateralization ratio for the SAFE
    */
    function setDesiredCollateralizationRatio(
        address cRatioSetter,
        bytes32 collateralType,
        uint256 safe,
        uint256 cRatio
    ) public {
        SaviourCRatioSetterLike_2(cRatioSetter).setDesiredCollateralizationRatio(collateralType, safe, cRatio);
    }
    /*
    * @notice Deposit cover in a saviour contract
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract being attached
    * @param manager The SAFE manager contract
    * @param token The token being used as cover
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being deposited as cover
    */
    function deposit(
        bool collateralSpecific,
        address saviour,
        address manager,
        address token,
        uint256 safe,
        uint256 tokenAmount
    ) public {
        transferTokenFromAndApprove(token, saviour, tokenAmount);

        if (collateralSpecific) {
          GebSaviourLike(saviour).deposit(ManagerLike(manager).collateralTypes(safe), safe, tokenAmount);
        } else {
          GebSaviourLike(saviour).deposit(safe, tokenAmount);
        }
    }
    /*
    * @notice Set a custom desired collateralization ratio for a specific SAFE and deposit cover in a saviour for the SAFE
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract being attached
    * @param cRatioSetter The address of the saviour cRatio setter
    * @param manager The SAFE manager contract
    * @param token The token being used as cover
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being deposited as cover
    * @param cRatio The desired collateralization ratio for the SAFE
    */
    function setDesiredCRatioDeposit(
        bool collateralSpecific,
        address saviour,
        address cRatioSetter,
        address manager,
        address token,
        uint256 safe,
        uint256 tokenAmount,
        uint256 cRatio
    ) public {
        setDesiredCollateralizationRatio(cRatioSetter, ManagerLike(manager).collateralTypes(safe), safe, cRatio);
        deposit(collateralSpecific, saviour, manager, token, safe, tokenAmount);
    }
    /*
    * @notice Withdraw cover from a saviour contract
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract from which to withdraw cover
    * @param manager The SAFE manager contract
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being withdrawn
    * @param dst The address that will receive the withdrawn tokens
    */
    function withdraw(
        bool collateralSpecific,
        address saviour,
        address manager,
        uint256 safe,
        uint256 tokenAmount,
        address dst
    ) public {
        if (collateralSpecific) {
          GebSaviourLike(saviour).withdraw(ManagerLike(manager).collateralTypes(safe), safe, tokenAmount, dst);
        } else {
          GebSaviourLike(saviour).withdraw(safe, tokenAmount, dst);
        }
    }
    /*
    * @notice Set a custom desired collateralization ratio for a specific SAFE and withdraw cover from a saviour protecting the SAFE
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract from which to withdraw cover
    * @param cRatioSetter The address of the saviour cRatio setter
    * @param manager The SAFE manager contract
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being withdrawn
    * @param cRatio The desired collateralization ratio for the SAFE
    * @param dst The address that will receive the withdrawn tokens
    */
    function setDesiredCRatioWithdraw(
        bool collateralSpecific,
        address saviour,
        address cRatioSetter,
        address manager,
        uint256 safe,
        uint256 tokenAmount,
        uint256 cRatio,
        address dst
    ) public {
        setDesiredCollateralizationRatio(cRatioSetter, ManagerLike(manager).collateralTypes(safe), safe, cRatio);
        withdraw(collateralSpecific, saviour, manager, safe, tokenAmount, dst);
    }
    /*
    * @notice Attach a saviour to a SAFE and deposit cover in it
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract being attached
    * @param manager The SAFE manager contract
    * @param token The token being used as cover
    * @param liquidationEngine The LiquidationEngine contract
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being deposited as cover
    */
    function protectSAFEDeposit(
        bool collateralSpecific,
        address saviour,
        address manager,
        address token,
        address liquidationEngine,
        uint256 safe,
        uint256 tokenAmount
    ) public {
        protectSAFE(saviour, manager, safe, liquidationEngine);
        deposit(collateralSpecific, saviour, manager, token, safe, tokenAmount);
    }
    /*
    * @notice Attach a saviour to a SAFE, set the SAFE's desired cRatio and deposit cover in the saviour
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract being attached
    * @param cRatioSetter The cRatio setter contract
    * @param manager The SAFE manager contract
    * @param token The token being used as cover
    * @param liquidationEngine The LiquidationEngine contract
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being deposited as cover
    * @param cRatio The desired collateralization ratio
    */
    function protectSAFESetDesiredCRatioDeposit(
        bool collateralSpecific,
        address saviour,
        address cRatioSetter,
        address manager,
        address token,
        address liquidationEngine,
        uint256 safe,
        uint256 tokenAmount,
        uint256 cRatio
    ) public {
        protectSAFE(saviour, manager, safe, liquidationEngine);
        setDesiredCollateralizationRatio(cRatioSetter, ManagerLike(manager).collateralTypes(safe), safe, cRatio);
        deposit(collateralSpecific, saviour, manager, token, safe, tokenAmount);
    }
    /*
    * @notice Withdraw cover from a saviour and uncover a SAFE
    * @param collateralSpecific Whether the collateral type of the SAFE needs to be passed to the saviour contract
    * @param saviour The saviour contract being detached
    * @param manager The SAFE manager contract
    * @param token The token being used as cover
    * @param liquidationEngine The LiquidationEngine contract
    * @param safe The ID of the SAFE being covered
    * @param tokenAmount The amount of tokens being withdrawn
    * @param dst The address that will receive the withdrawn tokens
    */
    function withdrawUncoverSAFE(
        bool collateralSpecific,
        address saviour,
        address manager,
        address token,
        address liquidationEngine,
        uint256 safe,
        uint256 tokenAmount,
        address dst
    ) public {
        withdraw(collateralSpecific, saviour, manager, safe, tokenAmount, dst);
        protectSAFE(address(0), manager, safe, liquidationEngine);
    }
    /*
    * @notice Withdraw cover from a saviour, cover a SAFE with a new saviour and deposit cover in the new saviour
    * @param withdrawCollateralSpecific Whether the collateral type of the SAFE needs to be passed to the withdraw saviour contract
    * @param depositCollateralSpecific Whether the collateral type of the SAFE needs to be passed to the deposit saviour contract
    * @param withdrawSaviour The saviour from which cover is being withdrawn
    * @param depositSaviour The new saviour that wil protect the SAFE
    * @param manager The SAFE manager contract
    * @param depositToken The token being deposited in the depositSaviour
    * @param liquidationEngine The LiquidationEngine contract
    * @param safe The SAFE being covered by the new saviour
    * @param withdrawTokenAmount The amount of tokens being withdrawn from the old saviour
    * @param depositTokenAmount The amount of tokens being deposited in the new saviour
    * @param withdrawDst The address that will receive the withdrawn tokens
    */
    function withdrawProtectSAFEDeposit(
        bool withdrawCollateralSpecific,
        bool depositCollateralSpecific,
        address withdrawSaviour,
        address depositSaviour,
        address manager,
        address depositToken,
        address liquidationEngine,
        uint256 safe,
        uint256 withdrawTokenAmount,
        uint256 depositTokenAmount,
        address withdrawDst
    ) public {
        withdraw(withdrawCollateralSpecific, withdrawSaviour, manager, safe, withdrawTokenAmount, withdrawDst);
        protectSAFE(depositSaviour, manager, safe, liquidationEngine);
        deposit(depositCollateralSpecific, depositSaviour, manager, depositToken, safe, depositTokenAmount);
    }
    /*
    * @notice Withdraw reserve tokens from a saviour without uncovering a SAFE
    * @param saviour The saviour from which to withdraw reserve assets
    * @param safe The ID of the SAFE that has tokens in reserves
    * @param The address that will receive the reserve tokens
    */
    function getReserves(address saviour, uint256 safe, address dst) public {
        GebSaviourLike(saviour).getReserves(safe, dst);
    }
    /*
    * @notice Withdraw reserve tokens from a saviour and uncover a SAFE
    * @param saviour The saviour from which to withdraw reserve assets
    * @param manager The SAFE manager contract
    * @param liquidationEngine The LiquidationEngine contract
    * @param safe The ID of the SAFE that has tokens in reserves
    * @param The address that will receive the reserve tokens
    */
    function getReservesAndUncover(address saviour, address manager, address liquidationEngine, uint256 safe, address dst) public {
        GebSaviourLike(saviour).getReserves(safe, dst);
        protectSAFE(address(0), manager, safe, liquidationEngine);
    }
}