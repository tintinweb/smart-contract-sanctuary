/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

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

pragma solidity 0.6.7;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

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

abstract contract CollateralLike {
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

abstract contract SAFEEngineLike {
    function canModifySAFE(address, address) virtual public view returns (uint);
    function collateralTypes(bytes32) virtual public view returns (uint, uint, uint, uint, uint);
    function coinBalance(address) virtual public view returns (uint);
    function safes(bytes32, address) virtual public view returns (uint, uint);
    function modifySAFECollateralization(bytes32, address, address, address, int, int) virtual public;
    function approveSAFEModification(address) virtual public;
    function transferInternalCoins(address, address, uint) virtual public;
}

abstract contract CollateralJoinLike {
    function decimals() virtual public returns (uint);
    function collateral() virtual public returns (CollateralLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract GNTJoinLike {
    function bags(address) virtual public view returns (address);
    function make(address) virtual public returns (address);
}

abstract contract DSTokenLike {
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

abstract contract CoinJoinLike {
    function safeEngine() virtual public returns (SAFEEngineLike);
    function systemCoin() virtual public returns (DSTokenLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract ApproveSAFEModificationLike {
    function approveSAFEModification(address) virtual public;
    function denySAFEModification(address) virtual public;
}

abstract contract GlobalSettlementLike {
    function collateralCashPrice(bytes32) virtual public view returns (uint);
    function redeemCollateral(bytes32, uint) virtual public;
    function freeCollateral(bytes32) virtual public;
    function prepareCoinsForRedeeming(uint) virtual public;
    function processSAFE(bytes32, address) virtual public;
}

abstract contract TaxCollectorLike {
    function taxSingle(bytes32) virtual public returns (uint);
}

abstract contract CoinSavingsAccountLike {
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
        CoinJoinLike(apt).systemCoin().approve(apt, wad);
        // Joins COIN into the safeEngine
        CoinJoinLike(apt).join(safeHandler, wad);
    }

    // Public functions
    function coinJoin_join(address apt, address safeHandler, uint wad) public {
        // Gets COIN from the user's wallet
        CoinJoinLike(apt).systemCoin().transferFrom(msg.sender, address(this), wad);

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
        uint decimals = CollateralJoinLike(collateralJoin).decimals();
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
        uint coin = SAFEEngineLike(safeEngine).coinBalance(safeHandler);

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
        (, uint rate,,,) = SAFEEngineLike(safeEngine).collateralTypes(collateralType);
        require(rate > 0, "invalid-collateral-type");

        // Gets actual generatedDebt value of the safe
        (, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralType, safe);

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
        (, uint rate,,,) = SAFEEngineLike(safeEngine).collateralTypes(collateralType);
        // Gets actual generatedDebt value of the safe
        (, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralType, safe);
        // Gets actual coin amount in the safe
        uint coin = SAFEEngineLike(safeEngine).coinBalance(usr);

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
        if (SAFEEngineLike(safeEngine).canModifySAFE(address(this), address(coinJoin)) == 0) {
            SAFEEngineLike(safeEngine).approveSAFEModification(coinJoin);
        }
        // Exits COIN to this contract
        CoinJoinLike(coinJoin).exit(to, wad);
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
        SAFEEngineLike(ManagerLike(manager).safeEngine()).modifySAFECollateralization(
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
            modifySAFECollateralization(manager, safe, 0, _getRepaidDeltaDebt(safeEngine, SAFEEngineLike(safeEngine).coinBalance(safeHandler), safeHandler, collateralType));
        } else {
             // Joins COIN amount into the safeEngine
            if (transferFromCaller) coinJoin_join(coinJoin, address(this), wad);
            else _coinJoin_join(coinJoin, address(this), wad);
            // Paybacks debt to the SAFE
            SAFEEngineLike(safeEngine).modifySAFECollateralization(
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
            _getRepaidDeltaDebt(ManagerLike(manager).safeEngine(), SAFEEngineLike(ManagerLike(manager).safeEngine()).coinBalance(safeHandler), safeHandler, ManagerLike(manager).collateralTypes(safe))
        );
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), collateralWad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(collateralWad);
    }

    // Public functions

    /// @notice ERC20 transfer
    /// @param collateral address - address of ERC20 collateral
    /// @param dst address - Transfer destination
    /// @param amt address - Amount to transfer
    function transfer(address collateral, address dst, uint amt) external {
        CollateralLike(collateral).transfer(dst, amt);
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
        CollateralJoinLike(apt).collateral().deposit{value: value}();
        // Approves adapter to take the WETH amount
        CollateralJoinLike(apt).collateral().approve(address(apt), value);
        // Joins WETH collateral into the safeEngine
        CollateralJoinLike(apt).join(safe, value);
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
        CollateralJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(wad);
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
        CollateralJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(wad);
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
            CollateralJoinLike(apt).collateral().transferFrom(msg.sender, address(this), amt);
            // Approves adapter to take the token amount
            CollateralJoinLike(apt).collateral().approve(apt, amt);
        }
        // Joins token collateral into the safeEngine
        CollateralJoinLike(apt).join(safe, amt);
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
        SAFEEngineLike(ManagerLike(manager).safeEngine()).modifySAFECollateralization(
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
        CollateralJoinLike(collateralJoin).exit(msg.sender, amt);
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
        CollateralJoinLike(collateralJoin).exit(msg.sender, amt);
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
        (, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralType, safeHandler);

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
            SAFEEngineLike(safeEngine).modifySAFECollateralization(
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
        if (SAFEEngineLike(safeEngine).canModifySAFE(address(this), address(coinJoin)) == 0) {
            SAFEEngineLike(safeEngine).approveSAFEModification(coinJoin);
        }
        // Exits COIN to the user's wallet as a token
        CoinJoinLike(coinJoin).exit(msg.sender, deltaWad);
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
        CollateralLike(CollateralJoinLike(gntJoin).collateral()).transfer(bag, collateralAmount);
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
        (, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralType, safeHandler);

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
        CollateralJoinLike(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(collateralWad);
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
            _getRepaidDeltaDebt(ManagerLike(manager).safeEngine(), SAFEEngineLike(ManagerLike(manager).safeEngine()).coinBalance(safeHandler), safeHandler, ManagerLike(manager).collateralTypes(safe))
        );
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), collateralWad);
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, collateralAmount);
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
        (, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralType, safeHandler);

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
        CollateralJoinLike(collateralJoin).exit(msg.sender, collateralAmount);
    }
}

abstract contract GebIncentivesLike {
    function stakingToken() virtual public returns (address);
    function rewardsToken() virtual public returns (address);
    function stake(uint256) virtual public;
    function withdraw(uint256) virtual public;
    function exit() virtual public;
    function balanceOf(address) virtual public view returns (uint256);
    function getReward() virtual public;
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title Incentives proxy actions
/// @notice This contract is supposed to be used alongside a DSProxy contract.
/// @dev These functions are meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
contract GebProxyIncentivesActions is BasicActions {
    // Internal functions

    /// @notice Provides liquidity on uniswap.
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap Router V2
    /// @param tokenWad uint - amount of tokens to provide liquidity with
    /// @param ethWad uint - amount of ETH to provide liquidity with
    /// @param to address - receiver of the balance of generated LP Tokens
    /// @param minTokenAmounts uint - Minimum amounts of both ETH and the token (user selected acceptable slippage)
    /// @dev Uniswap will return unused tokens (it provides liquidity with the best current ratio)
    /// @dev Public funcitons should account for change sent from Uniswap
    function _provideLiquidityUniswap(address coinJoin, address uniswapRouter, uint tokenWad, uint ethWad, address to, uint[2] memory minTokenAmounts) internal {
        CoinJoinLike(coinJoin).systemCoin().approve(uniswapRouter, tokenWad);
        IUniswapV2Router02(uniswapRouter).addLiquidityETH{value: ethWad}(
            address(CoinJoinLike(coinJoin).systemCoin()),
            tokenWad,
            minTokenAmounts[0],
            minTokenAmounts[1],
            to,
            block.timestamp
        );
    }

    /// @notice Stakes in Incentives Pool (geb-incentives)
    /// @param incentives address - Liquidity mining pool
    function _stakeInMine(address incentives) internal {
        DSTokenLike lpToken = DSTokenLike(GebIncentivesLike(incentives).stakingToken());
        lpToken.approve(incentives, uint(0 - 1));
        GebIncentivesLike(incentives).stake(lpToken.balanceOf(address(this)));
    }

    /// @notice Removes liquidity from Uniswap
    /// @param uniswapRouter address - Uniswap Router V2
    /// @param systemCoin address - Address of COIN
    /// @param value uint - amount of LP Tokens to remove liquidity with
    /// @param to address - receiver of the balances of generated ETH / COIN
    /// @param minTokenAmounts uint - Minimum amounts of both ETH and the token (user selected acceptable slippage)
    function _removeLiquidityUniswap(address uniswapRouter, address systemCoin, uint value, address to, uint[2] memory minTokenAmounts) internal returns (uint amountA, uint amountB) {
        DSTokenLike(getWethPair(uniswapRouter, systemCoin)).approve(uniswapRouter, value);
        return IUniswapV2Router02(uniswapRouter).removeLiquidityETH(
            systemCoin,
            value,
            minTokenAmounts[0],
            minTokenAmounts[1],
            to,
            block.timestamp
        );
    }

    /// @notice Opens Safe, locks Eth, generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param collateralType bytes32 - The ETH type used to generate debt
    /// @param deltaWad uint - Amount of debt to generate
    /// @param liquidityWad uint - Amount of ETH to be provided as liquidity (the remainder of msg.value will be used to collateralize the Safe)
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function openLockETHGenerateDebtProvideLiquidityUniswap(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        address uniswapRouter,
        bytes32 collateralType,
        uint deltaWad,
        uint liquidityWad,
        uint[2] calldata minTokenAmounts
    ) external payable returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());

        _lockETH(manager, ethJoin, safe, subtract(msg.value, liquidityWad));

        _generateDebt(manager, taxCollector, coinJoin, safe, deltaWad, address(this));

        _provideLiquidityUniswap(coinJoin, uniswapRouter, deltaWad, liquidityWad, msg.sender, minTokenAmounts);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Locks Eth, generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param safe uint - Safe Id
    /// @param deltaWad uint - Amount of debt to generate
    /// @param liquidityWad uint - Amount of ETH to be provided as liquidity (the remainder of msg.value will be used to collateralize the Safe)
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function lockETHGenerateDebtProvideLiquidityUniswap(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        address uniswapRouter,
        uint safe,
        uint deltaWad,
        uint liquidityWad,
        uint[2] calldata minTokenAmounts
    ) external payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());

        _lockETH(manager, ethJoin, safe, subtract(msg.value, liquidityWad));

        _generateDebt(manager, taxCollector, coinJoin, safe, deltaWad, address(this));

        _provideLiquidityUniswap(coinJoin, uniswapRouter, deltaWad, liquidityWad, msg.sender, minTokenAmounts);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Opens Safe, locks Eth, generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap and stakes LP tokens in Farm
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param incentives address - Liquidity mining pool
    /// @param collateralType bytes32 - The ETH type used to generate debt
    /// @param deltaWad uint256 - Amount of debt to generate
    /// @param liquidityWad uint256 - Amount of ETH to be provided as liquidity (the remainder of msg.value will be used to collateralize the Safe)
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function openLockETHGenerateDebtProvideLiquidityStake(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        address uniswapRouter,
        address incentives,
        bytes32 collateralType,
        uint256 deltaWad,
        uint256 liquidityWad,
        uint256[2] calldata minTokenAmounts
    ) external payable returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());

        _lockETH(manager, ethJoin, safe, subtract(msg.value, liquidityWad));

        _generateDebt(manager, taxCollector, coinJoin, safe, deltaWad, address(this));

        _provideLiquidityUniswap(coinJoin, uniswapRouter, deltaWad, liquidityWad, address(this), minTokenAmounts);

        _stakeInMine(incentives);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Locks Eth, generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap and stakes LP tokens in Farm
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param incentives address - Liquidity mining pool
    /// @param safe uint - Safe Id
    /// @param deltaWad uint - Amount of debt to generate
    /// @param liquidityWad uint - Amount of ETH to be provided as liquidity (the remainder of msg.value will be used to collateralize the Safe)
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function lockETHGenerateDebtProvideLiquidityStake(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        address uniswapRouter,
        address incentives,
        uint safe,
        uint deltaWad,
        uint liquidityWad,
        uint[2] memory minTokenAmounts
    ) public payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());

        _lockETH(manager, ethJoin, safe, subtract(msg.value, liquidityWad));

        _generateDebt(manager, taxCollector, coinJoin, safe, deltaWad, address(this));

        _provideLiquidityUniswap(coinJoin, uniswapRouter, deltaWad, liquidityWad, address(this), minTokenAmounts);

        _stakeInMine(incentives);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Provides liquidity to Uniswap
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param wad uint - Amount of coin to provide (msg.value for ETH)
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function provideLiquidityUniswap(address coinJoin, address uniswapRouter, uint wad, uint[2] calldata minTokenAmounts) external payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        systemCoin.transferFrom(msg.sender, address(this), wad);
        _provideLiquidityUniswap(coinJoin, uniswapRouter, wad, msg.value, msg.sender, minTokenAmounts);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap and stakes LP tokens in Farm
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param incentives address - Liquidity mining pool
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function provideLiquidityStake(
        address coinJoin,
        address uniswapRouter,
        address incentives,
        uint wad,
        uint[2] memory minTokenAmounts
    ) public payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        systemCoin.transferFrom(msg.sender, address(this), wad);
        _provideLiquidityUniswap(coinJoin, uniswapRouter, wad, msg.value, address(this), minTokenAmounts);

        _stakeInMine(incentives);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap
    /// @param manager address
    /// @param taxCollector address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param safe uint - Safe Id
    /// @param wad uint - Amount of debt to generate
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function generateDebtAndProvideLiquidityUniswap(
        address manager,
        address taxCollector,
        address coinJoin,
        address uniswapRouter,
        uint safe,
        uint wad,
        uint[2] calldata minTokenAmounts
    ) external payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        _generateDebt(manager, taxCollector, coinJoin, safe, wad, address(this));

        _provideLiquidityUniswap(coinJoin, uniswapRouter, wad, msg.value, msg.sender, minTokenAmounts);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Stakes in liquidity mining pool
    /// @param incentives address - pool address
    /// @param wad uint - amount
    function stakeInMine(address incentives, uint wad) external {
        DSTokenLike(GebIncentivesLike(incentives).stakingToken()).transferFrom(msg.sender, address(this), wad);
        _stakeInMine(incentives);
    }

    /// @notice Generates debt and sends COIN amount (deltaWad) and provides it as liquidity to Uniswap and stakes LP tokens in Farm
    /// @param manager address
    /// @param taxCollector address
    /// @param coinJoin address
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param incentives address - Liquidity mining pool
    /// @param safe uint - Safe Id
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function generateDebtAndProvideLiquidityStake(
        address manager,
        address taxCollector,
        address coinJoin,
        address uniswapRouter,
        address incentives,
        uint safe,
        uint wad,
        uint[2] calldata minTokenAmounts
    ) external payable {
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        _generateDebt(manager, taxCollector, coinJoin, safe, wad, address(this));
        _provideLiquidityUniswap(coinJoin, uniswapRouter, wad, msg.value, address(this), minTokenAmounts);
        _stakeInMine(incentives);

        // sending back any leftover tokens/eth, necessary to manage change from providing liquidity
        msg.sender.call{value: address(this).balance}("");
        systemCoin.transfer(msg.sender, systemCoin.balanceOf(address(this)));
    }

    /// @notice Harvests rewards available (both instant and staked) 
    /// @param incentives address - Liquidity mining pool
    function getRewards(address incentives) public {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        incentivesContract.getReward();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    /// @notice Exits liquidity mining pool (withdraw LP tokens and getRewards for current campaign)
    /// @param incentives address - Liquidity mining pool
    function exitMine(address incentives) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        incentivesContract.exit();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
    }

    /// @notice Migrates from one campaign to another, claiming rewards
    /// @param _oldIncentives Old liquidity mining pool
    /// @param _newIncentives New liquidity mining pool
    function migrateCampaign(address _oldIncentives, address _newIncentives) external {
        GebIncentivesLike incentives = GebIncentivesLike(_oldIncentives);
        GebIncentivesLike newIncentives = GebIncentivesLike(_newIncentives);
        require(incentives.stakingToken() == newIncentives.stakingToken(), "geb-incentives/mismatched-staking-tokens");
        DSTokenLike rewardToken = DSTokenLike(incentives.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentives.stakingToken());
        incentives.exit();

        _stakeInMine(_newIncentives);

        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    /// @notice Withdraw LP tokens from liquidity mining pool
    /// @param incentives address - Liquidity mining pool
    /// @param value uint - value to withdraw
    function withdrawFromMine(address incentives, uint value) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        incentivesContract.withdraw(value);
        lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
    }

    /// @notice Withdraw LP tokens from liquidity mining pool and harvests rewards
    /// @param incentives address - Liquidity mining pool
    /// @param value uint - value to withdraw
    function withdrawAndHarvest(address incentives, uint value) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        incentivesContract.withdraw(value);
        getRewards(incentives);
        lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
    }

    /// @notice Withdraw LP tokens from liquidity mining pool and harvests rewards
    /// @param incentives address - Liquidity mining pool
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param systemCoin address
    /// @param value uint - value to withdraw
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function withdrawHarvestRemoveLiquidity(address incentives, address uniswapRouter, address systemCoin, uint value, uint[2] memory minTokenAmounts) public returns (uint amountA, uint amountB) {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        incentivesContract.withdraw(value);
        getRewards(incentives);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        return _removeLiquidityUniswap(uniswapRouter, systemCoin, lpToken.balanceOf(address(this)), msg.sender, minTokenAmounts);
    }

    /// @notice Removes liquidity from Uniswap
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param systemCoin address
    /// @param value uint - Amount of LP tokens to remove
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function removeLiquidityUniswap(address uniswapRouter, address systemCoin, uint value, uint[2] calldata minTokenAmounts) external returns (uint amountA, uint amountB) {
        DSTokenLike(getWethPair(uniswapRouter, systemCoin)).transferFrom(msg.sender, address(this), value);
        return _removeLiquidityUniswap(uniswapRouter, systemCoin, value, msg.sender, minTokenAmounts);
    }

    /// @notice Withdraws from liquidity mining pool and removes liquidity from Uniswap
    /// @param coinJoin address
    /// @param incentives address - Liquidity mining pool
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function withdrawAndRemoveLiquidity(address coinJoin, address incentives, uint value, address uniswapRouter, uint[2] calldata minTokenAmounts) external returns (uint amountA, uint amountB) {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        incentivesContract.withdraw(value);
        return _removeLiquidityUniswap(uniswapRouter, address(CoinJoinLike(coinJoin).systemCoin()), value, msg.sender, minTokenAmounts);
    }

    /// @notice Withdraws from liquidity mining pool, removes liquidity from Uniswap and repays debt
    /// @param manager address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param incentives address - Liquidity mining pool
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function withdrawRemoveLiquidityRepayDebt(address manager, address coinJoin, uint safe, address incentives, uint value, address uniswapRouter, uint[2] calldata minTokenAmounts) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        incentivesContract.withdraw(value);

        _removeLiquidityUniswap(uniswapRouter, address(systemCoin), value, address(this), minTokenAmounts);
        _repayDebt(manager, coinJoin, safe, systemCoin.balanceOf(address(this)), false);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        msg.sender.call{value: address(this).balance}("");
    }

    /// @notice Exits from liquidity mining pool and removes liquidity from Uniswap
    /// @param coinJoin address
    /// @param incentives address - Liquidity mining pool
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function exitAndRemoveLiquidity(address coinJoin, address incentives, address uniswapRouter, uint[2] calldata minTokenAmounts) external returns (uint amountA, uint amountB) {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        incentivesContract.exit();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        return _removeLiquidityUniswap(uniswapRouter, address(CoinJoinLike(coinJoin).systemCoin()), lpToken.balanceOf(address(this)), msg.sender, minTokenAmounts);
    }

    /// @notice Exits from liquidity mining pool, removes liquidity from Uniswap and repays debt
    /// @param manager address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param incentives address - Liquidity mining pool
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param minTokenAmounts uint[2] - minimum ETH/Token amounts when providing liquidity to Uniswap (user set acceptable slippage)
    function exitRemoveLiquidityRepayDebt(address manager, address coinJoin, uint safe, address incentives, address uniswapRouter, uint[2] calldata minTokenAmounts) external {

        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = DSTokenLike(incentivesContract.rewardsToken());
        DSTokenLike lpToken = DSTokenLike(incentivesContract.stakingToken());
        DSTokenLike systemCoin = DSTokenLike(CoinJoinLike(coinJoin).systemCoin());
        incentivesContract.exit();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));

        _removeLiquidityUniswap(uniswapRouter, address(systemCoin), lpToken.balanceOf(address(this)), address(this), minTokenAmounts);

        _repayDebt(manager, coinJoin, safe, systemCoin.balanceOf(address(this)), false);
        msg.sender.call{value: address(this).balance}("");
    }

    /// @notice Returns the address of a token-weth pair
    /// @param uniswapRouter address - Uniswap V2 Router
    /// @param token address of the token
    function getWethPair(address uniswapRouter, address token) public view returns (address) {
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapRouter);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        return factory.getPair(token, router.WETH());
    }
}