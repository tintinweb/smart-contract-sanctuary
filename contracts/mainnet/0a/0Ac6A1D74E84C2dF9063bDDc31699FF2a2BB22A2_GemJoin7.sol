/// join.sol -- Non-standard token adapters

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
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

pragma solidity >=0.5.12;

contract LibNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize()                       // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
                 shl(224, shr(224, calldataload(0))), // msg.sig
                 caller(),                            // msg.sender
                 calldataload(4),                     // arg1
                 calldataload(36)                     // arg2
                )
        }
    }
}

interface VatLike {
    function slip(bytes32,address,int) external;
}

// GemJoin7
// For an upgradable token (like USDT) which doesn't return bool on transfers and may charge fees
//  If the token is deprecated changing the implementation behind, this prevents joins
//   and exits until the implementation is reviewed and approved by governance.

interface GemLike7 {
    function decimals() external view returns (uint);
    function transfer(address,uint) external;
    function transferFrom(address,address,uint) external;
    function balanceOf(address) external view returns (uint);
    function upgradedAddress() external view returns (address);
    function setImplementation(address,uint) external;
    function adjustFee(uint) external;
}

contract GemJoin7 is LibNote {
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike  public vat;
    bytes32  public ilk;
    GemLike7 public gem;
    uint     public dec;
    uint     public live; // Access flag

    mapping (address => uint256) public implementations;

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        gem = GemLike7(gem_);
        dec = gem.decimals();
        require(dec < 18, "GemJoin7/decimals-18-or-higher");
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        setImplementation(address(gem.upgradedAddress()), 1);
    }

    function cage() external note auth {
        live = 0;
    }

    function setImplementation(address implementation, uint256 permitted) public auth note {
        implementations[implementation] = permitted; // 1 live, 0 disable
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "GemJoin7/overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "GemJoin7/underflow");
    }

    function join(address urn, uint wad) public note {
        require(live == 1, "GemJoin7/not-live");
        require(implementations[gem.upgradedAddress()] == 1, "GemJoin7/implementation-invalid");
        uint bal = gem.balanceOf(address(this));
        gem.transferFrom(msg.sender, address(this), wad);
        uint wadt = mul(sub(gem.balanceOf(address(this)), bal), 10 ** (18 - dec));
        require(int(wadt) >= 0, "GemJoin7/overflow");
        vat.slip(ilk, urn, int(wadt));
    }

    function exit(address guy, uint wad) public note {
        uint wad18 = mul(wad, 10 ** (18 - dec));
        require(int(wad18) >= 0, "GemJoin7/overflow");
        require(implementations[gem.upgradedAddress()] == 1, "GemJoin7/implementation-invalid");
        vat.slip(ilk, msg.sender, -int(wad18));
        gem.transfer(guy, wad);
    }
}