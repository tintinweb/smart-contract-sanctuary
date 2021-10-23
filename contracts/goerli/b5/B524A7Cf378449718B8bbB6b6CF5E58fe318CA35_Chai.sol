// SPDX-License-Identifier: AGPL-3.0-or-later
// chai.sol -- a dai savings token
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico, lucasvo, livnev

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

pragma solidity ^0.6.2;

interface VatLike {
    function hope(address) external;
}

interface PotLike {
    function chi() external returns (uint256);
    function rho() external returns (uint256);
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}

interface JoinLike {
    function join(address, uint) external;
    function exit(address, uint) external;
}

interface GemLike {
    function transferFrom(address,address,uint) external returns (bool);
    function approve(address,uint) external returns (bool);
}

contract Chai {
    // --- Data ---
    VatLike  public vat;
    PotLike  public pot;
    JoinLike public daiJoin;
    GemLike  public daiToken;

    // --- ERC20 Data ---
    string  public constant name     = "Chai";
    string  public constant symbol   = "CHAI";
    string  public constant version  = "1";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- Math ---
    uint constant RAY = 10 ** 27;
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        // always rounds down
        z = mul(x, y) / RAY;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        // always rounds down
        z = mul(x, RAY) / y;
    }
    function rdivup(uint x, uint y) internal pure returns (uint z) {
        // always rounds up
        z = add(mul(x, RAY), sub(y, 1)) / y;
    }

    // --- EIP712 niceties ---
    bytes32 public constant DOMAIN_SEPARATOR = 0x0b50407de9fa158c2cba01a99633329490dfd22989a150c20e8c7b4c1fb0fcc3;
    // keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)"));
    bytes32 public constant PERMIT_TYPEHASH  = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(address vat_, address pot_, address daiJoin_, address weth_) public {
        /* assert (DOMAIN_SEPARATOR ==
          keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)), keccak256(bytes(version)), 1, address(this)))
        ); */

        vat = VatLike(vat_);
        pot = PotLike(pot_);
        daiJoin = JoinLike(daiJoin_);
        daiToken = GemLike(weth_);

        vat.hope(address(daiJoin));
        vat.hope(address(pot));

        daiToken.approve(address(daiJoin), uint(-1));
    }

    // --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    // like transferFrom but dai-denominated
    function move(address src, address dst, uint wad) external returns (bool) {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        // rounding up ensures dst gets at least wad dai
        return transferFrom(src, dst, rdivup(wad, chi));
    }
    function transferFrom(address src, address dst, uint wad)
        public returns (bool)
    {
        require(balanceOf[src] >= wad, "chai/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "chai/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_TYPEHASH,
                                 holder,
                                 spender,
                                 nonce,
                                 expiry,
                                 allowed))));
        require(holder != address(0), "chai/invalid holder");
        require(holder == ecrecover(digest, v, r, s), "chai/invalid-permit");
        require(expiry == 0 || now <= expiry, "chai/permit-expired");
        require(nonce == nonces[holder]++, "chai/invalid-nonce");

        uint can = allowed ? uint(-1) : 0;
        allowance[holder][spender] = can;
        emit Approval(holder, spender, can);
    }

    function dai(address usr) external returns (uint wad) {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        wad = rmul(chi, balanceOf[usr]);
    }
    // wad is denominated in dai
    function join(address dst, uint wad) external {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        uint pie = rdiv(wad, chi);
        balanceOf[dst] = add(balanceOf[dst], pie);
        totalSupply    = add(totalSupply, pie);

        daiToken.transferFrom(msg.sender, address(this), wad);
        daiJoin.join(address(this), wad);
        pot.join(pie);
        emit Transfer(address(0), dst, pie);
    }

    // wad is denominated in (1/chi) * dai
    function exit(address src, uint wad) public {
        require(balanceOf[src] >= wad, "chai/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "chai/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        totalSupply    = sub(totalSupply, wad);

        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        pot.exit(wad);
        daiJoin.exit(msg.sender, rmul(chi, wad));
        emit Transfer(src, address(0), wad);
    }

    // wad is denominated in dai
    function draw(address src, uint wad) external {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        // rounding up ensures usr gets at least wad dai
        exit(src, rdivup(wad, chi));
    }
}