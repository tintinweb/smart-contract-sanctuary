// hevm: flattened sources of src/LightPoolWrapper.sol
pragma solidity ^0.4.21;

////// lib/ds-roles/lib/ds-auth/src/auth.sol
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

/* pragma solidity ^0.4.13; */

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
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
            return authority.canCall(src, this, sig);
        }
    }
}

////// lib/lightpool-contracts/src/interfaces/ERC20.sol
/* pragma solidity ^0.4.21; */

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function decimals() public view returns (uint);
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(address src, address dst, uint wad) public returns (bool);
}

////// lib/lightpool-contracts/src/interfaces/PriceSanityInterface.sol
/* pragma solidity ^0.4.21; */

contract PriceSanityInterface {
    function checkPrice(address base, address quote, bool buy, uint256 baseAmount, uint256 quoteAmount) external view returns (bool result);
}

////// lib/lightpool-contracts/src/interfaces/WETHInterface.sol
/* pragma solidity ^0.4.21; */

/* import "./ERC20.sol"; */

contract WETHInterface is ERC20 {
  function() external payable;
  function deposit() external payable;
  function withdraw(uint wad) external;
}

////// lib/lightpool-contracts/src/LightPool.sol
/* pragma solidity ^0.4.21; */

/* import "./interfaces/WETHInterface.sol"; */
/* import "./interfaces/PriceSanityInterface.sol"; */
/* import "./interfaces/ERC20.sol"; */

contract LightPool {
    uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 4999;    // Changes to state require at least 5000 gas

    struct TokenData {
        address walletAddress;
        PriceSanityInterface priceSanityContract;
    }

    // key = keccak256(token, base, walletAddress)
    mapping(bytes32 => TokenData)       public markets;
    mapping(address => bool)            public traders;
    address                             public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWalletAddress(address base, address quote) {
        bytes32 key = keccak256(base, quote, msg.sender);
        require(markets[key].walletAddress == msg.sender);
        _;
    }

    modifier onlyTrader() {
        require(traders[msg.sender]);
        _;
    }

    function LightPool() public {
        owner = msg.sender;
    }

    function setTrader(address trader, bool enabled) onlyOwner external {
        traders[trader] = enabled;
    }

    function setOwner(address _owner) onlyOwner external {
        require(_owner != address(0));
        owner = _owner;
    }

    event AddMarket(address indexed base, address indexed quote, address indexed walletAddress, address priceSanityContract);
    function addMarket(ERC20 base, ERC20 quote, PriceSanityInterface priceSanityContract) external {
        require(base != address(0));
        require(quote != address(0));

        // Make sure there&#39;s no such configured token
        bytes32 tokenHash = keccak256(base, quote, msg.sender);
        require(markets[tokenHash].walletAddress == address(0));

        // Initialize token pool data
        markets[tokenHash] = TokenData(msg.sender, priceSanityContract);
        emit AddMarket(base, quote, msg.sender, priceSanityContract);
    }

    event RemoveMarket(address indexed base, address indexed quote, address indexed walletAddress);
    function removeMarket(ERC20 base, ERC20 quote) onlyWalletAddress(base, quote) external {
        bytes32 tokenHash = keccak256(base, quote, msg.sender);
        TokenData storage tokenData = markets[tokenHash];

        emit RemoveMarket(base, quote, tokenData.walletAddress);
        delete markets[tokenHash];
    }

    event ChangePriceSanityContract(address indexed base, address indexed quote, address indexed walletAddress, address priceSanityContract);
    function changePriceSanityContract(ERC20 base, ERC20 quote, PriceSanityInterface _priceSanityContract) onlyWalletAddress(base, quote) external {
        bytes32 tokenHash = keccak256(base, quote, msg.sender);
        TokenData storage tokenData = markets[tokenHash];
        tokenData.priceSanityContract = _priceSanityContract;
        emit ChangePriceSanityContract(base, quote, msg.sender, _priceSanityContract);
    }

    event Trade(address indexed trader, address indexed baseToken, address indexed quoteToken, address walletAddress, bool buy, uint256 baseAmount, uint256 quoteAmount);
    function trade(ERC20 base, ERC20 quote, address walletAddress, bool buy, uint256 baseAmount, uint256 quoteAmount) onlyTrader external {
        bytes32 tokenHash = keccak256(base, quote, walletAddress);
        TokenData storage tokenData = markets[tokenHash];
        require(tokenData.walletAddress != address(0));
        if (tokenData.priceSanityContract != address(0)) {
            require(tokenData.priceSanityContract.checkPrice.gas(EXTERNAL_QUERY_GAS_LIMIT)(base, quote, buy, baseAmount, quoteAmount)); // Limit gas to prevent reentrancy
        }
        ERC20 takenToken;
        ERC20 givenToken;
        uint256 takenTokenAmount;
        uint256 givenTokenAmount;
        if (buy) {
            takenToken = quote;
            givenToken = base;
            takenTokenAmount = quoteAmount;
            givenTokenAmount = baseAmount;
        } else {
            takenToken = base;
            givenToken = quote;
            takenTokenAmount = baseAmount;
            givenTokenAmount = quoteAmount;
        }
        require(takenTokenAmount != 0 && givenTokenAmount != 0);

        // Swap!
        require(takenToken.transferFrom(msg.sender, tokenData.walletAddress, takenTokenAmount));
        require(givenToken.transferFrom(tokenData.walletAddress, msg.sender, givenTokenAmount));
        emit Trade(msg.sender, base, quote, walletAddress, buy, baseAmount, quoteAmount);
    }
}

////// lib/lpc/lib/ds-token/lib/ds-math/src/math.sol
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

/* pragma solidity ^0.4.13; */

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
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

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
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

////// lib/lpc/lib/ds-token/lib/ds-stop/lib/ds-note/src/note.sol
/// note.sol -- the `note&#39; modifier, for logging calls as events

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

/* pragma solidity ^0.4.13; */

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

////// lib/lpc/lib/ds-value/lib/ds-thing/src/thing.sol
// thing.sol - `auth` with handy mixins. your things should be DSThings

// Copyright (C) 2017  DappHub, LLC

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

/* pragma solidity ^0.4.13; */

/* import &#39;ds-auth/auth.sol&#39;; */
/* import &#39;ds-note/note.sol&#39;; */
/* import &#39;ds-math/math.sol&#39;; */

contract DSThing is DSAuth, DSNote, DSMath {

    function S(string s) internal pure returns (bytes4) {
        return bytes4(keccak256(s));
    }

}

////// src/LightPoolWrapper.sol
/* pragma solidity ^0.4.21; */

/* import "ds-thing/thing.sol"; */
/* import "lightpool-contracts/LightPool.sol"; */

contract WETH is WETHInterface { }

contract LightPoolWrapper is DSThing {
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    address public reserve;
    LightPool public lightpool;
    mapping(address => bool) public whitelistedWallets;

    function LightPoolWrapper(address reserve_, LightPool lightpool_) public {
        assert(address(reserve_) != 0);
        assert(address(lightpool_) != 0);

        reserve = reserve_;
        lightpool = lightpool_;
    }

    function switchLightPool(LightPool lightpool_) public note auth {
        assert(address(lightpool_) != 0);
        lightpool = lightpool_;
    }

    function switchReserve(address reserve_) public note auth {
        assert(address(reserve_) != 0);
        reserve = reserve_;
    }

    function approveToken(ERC20 token, address spender, uint amount) public note auth {
        require(token.approve(spender, amount));
    }

    function setWhitelistedWallet(address walletAddress_, bool whitelisted) public note auth {
        whitelistedWallets[walletAddress_] = whitelisted;
    }

    event Trade(
        address indexed origin,
        address indexed srcToken,
        uint srcAmount,
        address indexed destToken,
        uint destAmount,
        address destAddress
    );

    function trade(ERC20 base, ERC20 quote, address walletAddress, bool buy, uint256 baseAmount, uint256 quoteAmount) public auth {
        require(whitelistedWallets[walletAddress]);

        ERC20 takenToken;
        uint takenAmount;
        ERC20 givenToken;
        uint givenAmount;

        if (buy) {
            takenToken = base;
            takenAmount = baseAmount;
            givenToken = quote;
            givenAmount = quoteAmount;
        } else {
            takenToken = quote;
            takenAmount = quoteAmount;
            givenToken = base;
            givenAmount = baseAmount;
        }

        require(givenToken.transferFrom(reserve, this, givenAmount));
        lightpool.trade(base, quote, walletAddress, buy, baseAmount, quoteAmount);
        require(takenToken.transfer(reserve, takenAmount));

        emit Trade(reserve, givenToken, givenAmount, takenToken, takenAmount, walletAddress);
    }

    function withdraw(ERC20 token, uint amount, address destination) public note auth {
        if (token == ETH_TOKEN_ADDRESS) {
            destination.transfer(amount);
        } else {
            require(token.transfer(destination, amount));
        }
    }
}