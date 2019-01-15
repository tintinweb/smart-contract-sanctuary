// Verified using https://dapp.tools

// hevm: flattened sources of src/EqualizerProxy.sol
pragma solidity ^0.4.24;

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

////// src/EqualizerProxy.sol
/* pragma solidity ^0.4.24; */

/* import "ds-math/math.sol"; */

contract TubInterface {
  function open() public returns (bytes32);
  function join(uint) public;
  function exit(uint) public;
  function lock(bytes32, uint) public;
  function free(bytes32, uint) public;
  function draw(bytes32, uint) public;
  function wipe(bytes32, uint) public;
  function give(bytes32, address) public;
  function shut(bytes32) public;
  function bite(bytes32) public;
  function cups(bytes32) public returns (address, uint, uint, uint);
  function gem() public returns (TokenInterface);
  function gov() public returns (TokenInterface);
  function skr() public returns (TokenInterface);
  function sai() public returns (TokenInterface);
  function vox() public returns (VoxInterface);
  function ask(uint) public returns (uint);
  function mat() public returns (uint);
  function chi() public returns (uint);
  function ink(bytes32) public returns (uint);
  function tab(bytes32) public returns (uint);
  function rap(bytes32) public returns (uint);
  function per() public returns (uint);
  function pip() public returns (PipInterface);
  function pep() public returns (PepInterface);
  function tag() public returns (uint);
  function drip() public;
}

contract TapInterface {
  function skr() public returns (TokenInterface);
  function sai() public returns (TokenInterface);
  function tub() public returns (TubInterface);
  function bust(uint) public;
  function boom(uint) public;
  function cash(uint) public;
  function mock(uint) public;
  function heal() public;
}

contract TokenInterface {
  function allowance(address, address) public returns (uint);
  function balanceOf(address) public returns (uint);
  function approve(address, uint) public;
  function transfer(address, uint) public returns (bool);
  function transferFrom(address, address, uint) public returns (bool);
  function deposit() public payable;
  function withdraw(uint) public;
}

contract VoxInterface {
  function par() public returns (uint);
}

contract PipInterface {
  function read() public returns (bytes32);
}

contract PepInterface {
  function peek() public returns (bytes32, bool);
}

contract OtcInterface {
  function sellAllAmount(address, uint, address, uint) public returns (uint);
  function buyAllAmount(address, uint, address, uint) public returns (uint);
  function getPayAmount(address, address, uint) public constant returns (uint);
}

contract EqualizerProxy is DSMath {

  function drawSellLock(TubInterface tub, OtcInterface otc, bytes32 cup, TokenInterface sai, uint drawAmt, TokenInterface weth, uint minLockAmt) public {
    // Borrow some SAI tokens
    tub.draw(cup, drawAmt);

    // Sell SAI tokens for WETH tokens
    if (sai.allowance(this, otc) < drawAmt) {
      sai.approve(otc, uint(-1));
    }
    uint buyAmt = otc.sellAllAmount(sai, drawAmt, weth, minLockAmt);
    require(buyAmt >= minLockAmt);

    // Convert WETH to PETH
    uint ink = rdiv(buyAmt, tub.per());
    if (tub.gem().allowance(this, tub) != uint(-1)) {
      tub.gem().approve(tub, uint(-1));
    }
    tub.join(ink);

    // LOCK PETH
    if (tub.skr().allowance(this, tub) != uint(-1)) {
      tub.skr().approve(tub, uint(-1));
    }
    tub.lock(cup, ink);
  }

  function freeSellWipe(TubInterface tub, OtcInterface otc, bytes32 cup, TokenInterface sai, uint freeAmt, TokenInterface weth, uint minWipeAmt) public {
    if (freeAmt > 0) {
      // Free some PETH tokens
      uint ink = rdiv(freeAmt, tub.per());
      tub.free(cup, ink);
      if (tub.skr().allowance(this, tub) != uint(-1)) {
        tub.skr().approve(tub, uint(-1));
      }

      // Convert PETH to WETH
      tub.exit(ink);

      // Sell WETH tokens for SAI tokens
      if (weth.allowance(this, otc) < freeAmt) {
        weth.approve(otc, uint(-1));
      }
      uint wipeAmt = otc.sellAllAmount(weth, freeAmt, sai, minWipeAmt);
      require(wipeAmt >= minWipeAmt);

      // Wipe SAI
      if (tub.sai().allowance(this, tub) != uint(-1)) {
        tub.sai().approve(tub, uint(-1));
      }
      if (tub.gov().allowance(this, tub) != uint(-1)) {
        tub.gov().approve(tub, uint(-1));
      }
      tub.wipe(cup, wipeAmt);
    }
  }

}