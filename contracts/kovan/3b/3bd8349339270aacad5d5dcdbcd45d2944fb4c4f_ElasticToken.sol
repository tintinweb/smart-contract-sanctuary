/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// hevm: flattened sources of src/token.sol

pragma solidity >0.4.13 >=0.4.23;

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
        } else if (authority == DSAuthority(address(0))) {
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

////// src/token.sol
/// token.sol -- ERC20 implementation with minting and rebase

// Copyright (C) 2021 Secret

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

/* import "ds-auth/auth.sol"; */
/* import "ds-math/math.sol"; */

library Library {
    struct optional {
        uint256 value;
        bool    hasValue;
    }
}

contract ElasticToken is DSAuth, DSMath {
    using Library for Library.optional;

    bool                                            public  stopped;
    address                                         public  root;
    bytes32                                         public  symbol;
    uint256                                         public  constant decimals = 5;
    bytes32                                         public  name = "";
    uint256                                         public  constant totalSupply = 3 * 10**9 * 10**decimals; // 3 billion
    uint256                                         public  epoch;
    mapping(address => mapping(address => uint256)) public  allowance;
    uint256                                         private _totalGons;
    address[]                                       private _holders;
    mapping(address => Library.optional)            private _gonBalances;
    uint256                                         private _nextHolderIndex;

    constructor(bytes32 symbol_, address root_) public {
        root = root_;
        symbol = symbol_;

        _totalGons = mul(totalSupply, WAD);

        _gonBalances[root].hasValue = true;
        _gonBalances[root].value = _totalGons;
        _holders.push(root);

        emit Transfer(address(0), root, totalSupply);
    }

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Rebase(uint256 indexed epoch, uint256 percentage, uint256 totalGons);
    event Stop();
    event Start();

    modifier stoppable {
        require(!stopped, "is-stopped");
        _;
    }

    function balanceOf(address guy) public view returns (uint256) {
        require(_nextHolderIndex == 0, "upgrading");

        uint256 gonValue = _gonBalances[guy].value;
        if (gonValue == 0) {
            return 0;
        }
        uint256 ratio = rdiv(_totalGons, gonValue);
        return rdiv(totalSupply, ratio);
    }

    function approve(address guy) external returns (bool) {
        return approve(guy, uint256(-1));
    }

    function approve(address guy, uint256 wad) public stoppable returns (bool) {
        allowance[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public stoppable returns (bool) {
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad, "insufficient-approval");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }

        uint256 gonValue = mul(wad, _totalGons / totalSupply);
        require(_gonBalances[src].value >= gonValue, "insufficient-balance");
        _gonBalances[src].value = sub(_gonBalances[src].value, gonValue);
        _gonBalances[dst].value = add(_gonBalances[dst].value, gonValue);
        if (!_gonBalances[dst].hasValue) {
            _gonBalances[dst].hasValue = true;
            _holders.push(dst);
        }

        emit Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint256 wad) external {
        transferFrom(msg.sender, dst, wad);
    }

    function pull(address src, uint256 wad) external {
        transferFrom(src, msg.sender, wad);
    }

    function move(
        address src,
        address dst,
        uint256 wad
    ) external {
        transferFrom(src, dst, wad);
    }

    function rebase(uint256 percentage) external auth stoppable {
        require(percentage > 0 && percentage < 100, "0 < percentage < 100");

        uint256 ratio = 100 - percentage;
        uint256 oldTotalGons = _totalGons;
        uint256 totalGons = (_totalGons / ratio) * 100;
        require((totalGons * RAY) / RAY == totalGons, "need-to-upgrade");

        _totalGons = totalGons;
        _gonBalances[root].value = add(
            _gonBalances[root].value,
            sub(_totalGons, oldTotalGons)
        );

        epoch++;
        emit Rebase(epoch, percentage, _totalGons);
    }

    function upgrade() external auth returns (bool) {
        if (!stopped) {
            stop();
        }

        uint256 i = _nextHolderIndex;
        while (i < _holders.length && gasleft() > 50000) {
            uint256 balance = balanceOf(_holders[i]);
            _gonBalances[_holders[i]].value = mul(balance, WAD);
            i++;
        }

        if (i < _holders.length) {
            _nextHolderIndex = i;
            return false;
        }

        _nextHolderIndex = 0;
        _totalGons = mul(totalSupply, WAD);

        start();

        return true;
    }

    function stop() public auth {
        stopped = true;
        emit Stop();
    }

    function start() public auth {
        require(_nextHolderIndex == 0, "upgrading");

        stopped = false;
        emit Start();
    }

    function setName(bytes32 name_) external auth {
        name = name_;
    }
}