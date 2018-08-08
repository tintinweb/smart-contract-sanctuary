pragma solidity ^0.4.21;

// File: contracts/Oracle/DSAuth.sol

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

// File: contracts/Oracle/DSMath.sol

contract DSMath {
    
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

    /*
    uint128 functions (h is for half)
     */


    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }


    /*
    int256 functions
     */

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
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

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

// File: contracts/Oracle/DSNote.sol

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

// File: contracts/Oracle/DSThing.sol

contract DSThing is DSAuth, DSNote, DSMath {
}

// File: contracts/Oracle/DSValue.sol

contract DSValue is DSThing {
    bool    has;
    bytes32 val;
    function peek() constant returns (bytes32, bool) {
        return (val,has);
    }
    function read() constant returns (bytes32) {
        var (wut, has) = peek();
        assert(has);
        return wut;
    }
    function poke(bytes32 wut) note auth {
        val = wut;
        has = true;
    }
    function void() note auth { // unset the value
        has = false;
    }
}

// File: contracts/Oracle/Medianizer.sol

contract Medianizer is DSValue {
    mapping (bytes12 => address) public values;
    mapping (address => bytes12) public indexes;
    bytes12 public next = 0x1;

    uint96 public min = 0x1;

    function set(address wat) auth {
        bytes12 nextId = bytes12(uint96(next) + 1);
        assert(nextId != 0x0);
        set(next, wat);
        next = nextId;
    }

    function set(bytes12 pos, address wat) note auth {
        if (pos == 0x0) throw;

        if (wat != 0 && indexes[wat] != 0) throw;

        indexes[values[pos]] = 0; // Making sure to remove a possible existing address in that position

        if (wat != 0) {
            indexes[wat] = pos;
        }

        values[pos] = wat;
    }

    function setMin(uint96 min_) note auth {
        if (min_ == 0x0) throw;
        min = min_;
    }

    function setNext(bytes12 next_) note auth {
        if (next_ == 0x0) throw;
        next = next_;
    }

    function unset(bytes12 pos) {
        set(pos, 0);
    }

    function unset(address wat) {
        set(indexes[wat], 0);
    }

    function poke() {
        poke(0);
    }

    function poke(bytes32) note {
        (val, has) = compute();
    }

    function compute() constant returns (bytes32, bool) {
        bytes32[] memory wuts = new bytes32[](uint96(next) - 1);
        uint96 ctr = 0;
        for (uint96 i = 1; i < uint96(next); i++) {
            if (values[bytes12(i)] != 0) {
                var (wut, wuz) = DSValue(values[bytes12(i)]).peek();
                if (wuz) {
                    if (ctr == 0 || wut >= wuts[ctr - 1]) {
                        wuts[ctr] = wut;
                    } else {
                        uint96 j = 0;
                        while (wut >= wuts[j]) {
                            j++;
                        }
                        for (uint96 k = ctr; k > j; k--) {
                            wuts[k] = wuts[k - 1];
                        }
                        wuts[j] = wut;
                    }
                    ctr++;
                }
            }
        }

        if (ctr < min) return (val, false);

        bytes32 value;
        if (ctr % 2 == 0) {
            uint128 val1 = uint128(wuts[(ctr / 2) - 1]);
            uint128 val2 = uint128(wuts[ctr / 2]);
            value = bytes32(wdiv(hadd(val1, val2), 2 ether));
        } else {
            value = wuts[(ctr - 1) / 2];
        }

        return (value, true);
    }
}

// File: contracts/Oracle/PriceFeed.sol

/// price-feed.sol

// Copyright (C) 2017  DappHub, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).



contract PriceFeed is DSThing {

    uint128 val;
    uint32 public zzz;

    function peek() public view
        returns (bytes32, bool)
    {
        return (bytes32(val), now < zzz);
    }

    function read() public view
        returns (bytes32)
    {
        assert(now < zzz);
        return bytes32(val);
    }

    function post(uint128 val_, uint32 zzz_, address med_) public note auth
    {
        val = val_;
        zzz = zzz_;
        bool ret = med_.call(bytes4(keccak256("poke()")));
        ret;
    }

    function void() public note auth
    {
        zzz = 0;
    }

}

// File: contracts/Oracle/PriceOracleInterface.sol

/*
This contract is the interface between the MakerDAO priceFeed and our DX platform.
*/



contract PriceOracleInterface {

    address public priceFeedSource;
    address public owner;
    bool public emergencyMode;

    event NonValidPriceFeed(address priceFeedSource);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev constructor of the contract
    /// @param _priceFeedSource address of price Feed Source -> should be maker feeds Medianizer contract
    function PriceOracleInterface(
        address _owner,
        address _priceFeedSource
    )
        public
    {
        owner = _owner;
        priceFeedSource = _priceFeedSource;
    }
    /// @dev gives the owner the possibility to put the Interface into an emergencyMode, which will 
    /// output always a price of 600 USD. This gives everyone time to set up a new pricefeed.
    function raiseEmergency(bool _emergencyMode)
        public
        onlyOwner()
    {
        emergencyMode = _emergencyMode;
    }

    /// @dev updates the priceFeedSource
    /// @param _owner address of owner
    function updateCurator(
        address _owner
    )
        public
        onlyOwner()
    {
        owner = _owner;
    }

    /// @dev returns the USDETH price, ie gets the USD price from Maker feed with 18 digits, but last 18 digits are cut off
    function getUSDETHPrice() 
        public
        returns (uint256)
    {
        // if the contract is in the emergencyMode, because there is an issue with the oracle, we will simply return a price of 600 USD
        if(emergencyMode){
            return 600;
        }

        bytes32 price;
        bool valid=true;
        (price, valid) = Medianizer(priceFeedSource).peek();
        if (!valid) {
            NonValidPriceFeed(priceFeedSource);
        }
        // ensuring that there is no underflow or overflow possible,
        // even if the price is compromised
        uint priceUint = uint256(price)/(1 ether);
        if (priceUint == 0) return 1;
        if (priceUint > 1000000) return 1000000; 
        return priceUint;
    }  
}