/**
 *Submitted for verification at Etherscan.io on 2020-09-25
*/

/**
 *Submitted for verification at Etherscan.io on 2020-08-29
*/

// hevm: flattened sources of src/isw-farm.sol
pragma solidity >0.4.13 >=0.4.23 >=0.5.0 >=0.6.2 <0.7.0 >=0.6.7 <0.7.0;

////// lib/ds-auth/src/auth.sol
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

/* pragma solidity >=0.4.23; */

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
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
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
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

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
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

////// lib/ds-math/src/math.sol
/// math.sol -- mixin for inline numerical wizardry

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

/* pragma solidity >0.4.13; */

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

////// lib/ds-token/src/token.sol
/// token.sol -- ERC20 implementation with minting and burning

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

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

/* pragma solidity >=0.4.23; */

/* import "ds-math/math.sol"; */
/* import "ds-auth/auth.sol"; */


contract DSToken is DSMath, DSAuth {
    bool                                              public  stopped;
    uint256                                           public  totalSupply;
    mapping (address => uint256)                      public  balanceOf;
    mapping (address => mapping (address => uint256)) public  allowance;
    bytes32                                           public  symbol;
    uint256                                           public  decimals = 18; // standard token precision. override to customize
    bytes32                                           public  name = "";     // Optional token name

    constructor(bytes32 symbol_) public {
        symbol = symbol_;
    }

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);
    event Stop();
    event Start();

    modifier stoppable {
        require(!stopped, "ds-stop-is-stopped");
        _;
    }

    function approve(address guy) external returns (bool) {
        return approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        allowance[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }

        require(balanceOf[src] >= wad, "ds-token-insufficient-balance");
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint wad) external {
        transferFrom(msg.sender, dst, wad);
    }

    function pull(address src, uint wad) external {
        transferFrom(src, msg.sender, wad);
    }

    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }


    function mint(uint wad) external {
        mint(msg.sender, wad);
    }

    function burn(uint wad) external {
        burn(msg.sender, wad);
    }

    function mint(address guy, uint wad) public auth stoppable {
        balanceOf[guy] = add(balanceOf[guy], wad);
        totalSupply = add(totalSupply, wad);
        emit Mint(guy, wad);
    }

    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && allowance[guy][msg.sender] != uint(-1)) {
            require(allowance[guy][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[guy][msg.sender] = sub(allowance[guy][msg.sender], wad);
        }

        require(balanceOf[guy] >= wad, "ds-token-insufficient-balance");
        balanceOf[guy] = sub(balanceOf[guy], wad);
        totalSupply = sub(totalSupply, wad);
        emit Burn(guy, wad);
    }

    function stop() public auth {
        stopped = true;
        emit Stop();
    }

    function start() public auth {
        stopped = false;
        emit Start();
    }

    function setName(bytes32 name_) external auth {
        name = name_;
    }
}

////// src/constants.sol
/* pragma solidity ^0.6.7; */


library Constants {
    // Tokens
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant ISW = 0xfd30503375087d6De639bBa83DA9184e59F354A0;
    address constant UNIV2_ISW_ETH = 0xccfFE69A1997Eaa9D9F350d4FfF1564E32e7333f;

    // Uniswap
    address constant UNIV2_ROUTER2 = 0x1B7D628EEE764EB08d88ea2470B6351adf4681C0;

    // ISWswap
    address constant MASTERCHEF = 0xEc4fC6599c5e64F6e320d3C098Fb9CAFbA7B9273;
}
////// src/interfaces/masterchef.sol
/* pragma solidity ^0.6.2; */

interface Masterchef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);
}

////// src/interfaces/uniswap.sol
// SPDX-License-Identifier: MIT
/* pragma solidity ^0.6.2; */

interface UniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface UniswapPair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestamp
        );
}

////// src/isw-farm.sol
/* pragma solidity ^0.6.7; */

/* import "ds-math/math.sol"; */
/* import "ds-token/token.sol"; */

/* import "./interfaces/masterchef.sol"; */
/* import "./interfaces/uniswap.sol"; */

/* import "./constants.sol"; */

// ISW Farm in ISWSwap
// Used to farm isw. i.e. Deposit into this pool if you want to LONG isw.

// Based off https://github.com/iearn-finance/vaults/blob/master/contracts/yVault.sol
contract ISWFarm is DSMath {
    // Tokens
    DSToken public isw = DSToken(Constants.ISW);
    DSToken public univ2ISWEth = DSToken(Constants.UNIV2_ISW_ETH);
    DSToken public weth = DSToken(Constants.WETH);
    DSToken public gISW;

    // Uniswap Router and Pair
    UniswapRouterV2 public univ2 = UniswapRouterV2(Constants.UNIV2_ROUTER2);
    UniswapPair public univ2Pair = UniswapPair(address(univ2ISWEth));

    // Masterchef Contract
    Masterchef public masterchef = Masterchef(Constants.MASTERCHEF);
    uint256 public univ2ISWEthPoolId = 12;

    // 5% reward for anyone who calls HARVEST
    uint256 public callerRewards = 5 ether / 100;

    // Last harvest
    uint256 public lastHarvest = 0;

    constructor() public {
        gISW = new DSToken("gISW");
        gISW.setName("Grazing ISW");
    }

    // **** Harvest profits ****

    function harvest() public {
        // Only callable every hour or so
        if (lastHarvest > 0) {
            require(lastHarvest + 1 hours <= block.timestamp, "!harvest-time");
        }
        lastHarvest = block.timestamp;

        // Withdraw isw
        masterchef.withdraw(univ2ISWEthPoolId, 0);

        uint256 amount = isw.balanceOf(address(this));
        uint256 reward = div(mul(amount, callerRewards), 100 ether);

        // Sends 5% fee to caller
        isw.transfer(msg.sender, reward);

        // Remove amount from rewards
        amount = sub(amount, reward);

        // Add to UniV2 pool
        _iswToUniV2ISWEth(amount);

        // Deposit into masterchef contract
        uint256 balance = univ2ISWEth.balanceOf(address(this));
        univ2ISWEth.approve(address(masterchef), balance);
        masterchef.deposit(univ2ISWEthPoolId, balance);
    }

    // **** Withdraw / Deposit functions ****

    function withdrawAll() external {
        withdraw(gISW.balanceOf(msg.sender));
    }

    function withdraw(uint256 _shares) public {
        uint256 univ2Balance = univ2ISWEthBalance();

        uint256 amount = div(mul(_shares, univ2Balance), gISW.totalSupply());
        gISW.burn(msg.sender, _shares);

        // Withdraw from Masterchef contract
        masterchef.withdraw(univ2ISWEthPoolId, amount);

        // Retrive shares from Uniswap pool and converts to ISW
        uint256 _before = isw.balanceOf(address(this));
        _uniV2ISWEthToISW(amount);
        uint256 _after = isw.balanceOf(address(this));

        // Transfer back ISW difference
        isw.transfer(msg.sender, sub(_after, _before));
    }

    function depositAll() external {
        deposit(isw.balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public {
        isw.transferFrom(msg.sender, address(this), _amount);

        uint256 _pool = univ2ISWEthBalance();
        uint256 _before = univ2ISWEth.balanceOf(address(this));
        _iswToUniV2ISWEth(_amount);
        uint256 _after = univ2ISWEth.balanceOf(address(this));

        _amount = sub(_after, _before); // Additional check for deflationary tokens

        uint256 shares = 0;
        if (gISW.totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = div(mul(_amount, gISW.totalSupply()), _pool);
        }

        // Deposit into Masterchef contract to get rewards
        univ2ISWEth.approve(address(masterchef), _amount);
        masterchef.deposit(univ2ISWEthPoolId, _amount);

        gISW.mint(msg.sender, shares);
    }

    // Takes <x> amount of ISW
    // Converts half of it into ETH,
    // Supplies them into ISW/ETH pool
    function _iswToUniV2ISWEth(uint256 _amount) internal {
        uint256 half = div(_amount, 2);

        // Convert half of the isw to ETH
        address[] memory path = new address[](2);
        path[0] = address(isw);
        path[1] = address(weth);
        isw.approve(address(univ2), half);
        univ2.swapExactTokensForTokens(half, 0, path, address(this), now + 60);

        // Supply liquidity
        uint256 wethBal = weth.balanceOf(address(this));
        uint256 iswBal = isw.balanceOf(address(this));
        isw.approve(address(univ2), iswBal);
        weth.approve(address(univ2), wethBal);
        univ2.addLiquidity(
            address(isw),
            address(weth),
            iswBal,
            wethBal,
            0,
            0,
            address(this),
            now + 60
        );
    }

    // Takes <x> amount of gISW
    // And removes liquidity from ISW/ETH pool
    // Converts the ETH into ISW
    function _uniV2ISWEthToISW(uint256 _amount) internal {
        // Remove liquidity
        require(
            univ2ISWEth.balanceOf(address(this)) >= _amount,
            "not-enough-liquidity"
        );
        univ2ISWEth.approve(address(univ2), _amount);
        univ2.removeLiquidity(
            address(isw),
            address(weth),
            _amount,
            0,
            0,
            address(this),
            now + 60
        );

        // Convert ETH to ISW
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(isw);
        uint256 wethBal = weth.balanceOf(address(this));
        weth.approve(address(univ2), wethBal);
        univ2.swapExactTokensForTokens(
            wethBal,
            0,
            path,
            address(this),
            now + 60
        );
    }

    // 1 gISW = <x> ISW
    function getGISWOverISWRatio() public view returns (uint256) {
        // How much UniV2 do we have
        uint256 uniV2Balance = univ2ISWEthBalance();

        if (uniV2Balance == 0) {
            return 0;
        }

        // How many ISW and ETH can we get for this?
        (uint112 _poolISWReserve, uint112 _poolWETHReserve, ) = univ2Pair
            .getReserves(); // ISW and WETH in pool
        uint256 uniV2liquidity = univ2ISWEth.totalSupply(); // Univ2 total supply
        uint256 uniV2percentage = div(mul(uniV2Balance, 1e18), uniV2liquidity); // How much we own %-wise

        uint256 removableISW = uint256(
            div(mul(_poolISWReserve, uniV2percentage), 1e18)
        );
        uint256 removableWeth = uint256(
            div(mul(_poolWETHReserve, uniV2percentage), 1e18)
        );

        // How many ISW can we get for the ETH?
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(isw);
        uint256[] memory outs = univ2.getAmountsOut(removableWeth, path);

        // Get RATIO
        return div(mul(add(outs[1], removableISW), 1e18), gISW.totalSupply());
    }

    function univ2ISWEthBalance() public view returns (uint256) {
        (uint256 univ2Balance, ) = masterchef.userInfo(
            univ2ISWEthPoolId,
            address(this)
        );

        return univ2Balance;
    }

    // **** Internal functions ****
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "division by zero");
        uint256 c = a / b;
        return c;
    }
}