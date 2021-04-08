/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// Copyright (C) 2020, 2021 Lev Livnev <[email protected]>
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

pragma solidity 0.5.12;

// https://github.com/makerdao/dss/blob/master/src/vat.sol
interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function slip(bytes32, address, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function fork(bytes32, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function heal(uint256) external;
    function suck(address, address, uint256) external;
    function fold(bytes32, address, int256) external;
}

// https://github.com/makerdao/dss/blob/master/src/jug.sol
interface JugAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (uint256, uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function base() external view returns (address);
    function init(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function drip(bytes32) external returns (uint256);
}

// https://github.com/dapphub/ds-token/blob/master/src/token.sol
interface DSTokenAbstract {
    function name() external view returns (bytes32);
    function symbol() external view returns (bytes32);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function approve(address) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function mint(uint256) external;
    function mint(address,uint) external;
    function burn(uint256) external;
    function burn(address,uint) external;
    function setName(bytes32) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface GemJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface DaiJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function dai() external view returns (address);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface DaiAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}

contract RwaUrn {
    // --- auth ---
    mapping (address => uint256) public wards;
    mapping (address => uint256) public can;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaUrn/not-authorized");
        _;
    }
    function hope(address usr) external auth {
        can[usr] = 1;
        emit Hope(usr);
    }
    function nope(address usr) external auth {
        can[usr] = 0;
        emit Nope(usr);
    }
    modifier operator {
        require(can[msg.sender] == 1, "RwaUrn/not-operator");
        _;
    }

    VatAbstract  public vat;
    JugAbstract  public jug;
    GemJoinAbstract public gemJoin;
    DaiJoinAbstract public daiJoin;
    address public outputConduit;

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Hope(address indexed usr);
    event Nope(address indexed usr);
    event File(bytes32 indexed what, address data);
    event Lock(address indexed usr, uint256 wad);
    event Free(address indexed usr, uint256 wad);
    event Draw(address indexed usr, uint256 wad);
    event Wipe(address indexed usr, uint256 wad);
    event Quit(address indexed usr, uint256 wad);

    // --- math ---
    uint256 constant RAY = 10 ** 27;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(x, sub(y, 1)) / y;
    }

    // --- init ---
    constructor(
        address vat_, address jug_, address gemJoin_, address daiJoin_, address outputConduit_
    ) public {
        // requires in urn that outputConduit isn't address(0)
        vat = VatAbstract(vat_);
        jug = JugAbstract(jug_);
        gemJoin = GemJoinAbstract(gemJoin_);
        daiJoin = DaiJoinAbstract(daiJoin_);
        outputConduit = outputConduit_;
        wards[msg.sender] = 1;
        DSTokenAbstract(gemJoin.gem()).approve(address(gemJoin), uint256(-1));
        DaiAbstract(daiJoin.dai()).approve(address(daiJoin), uint256(-1));
        VatAbstract(vat_).hope(address(daiJoin));
        emit Rely(msg.sender);
        emit File("outputConduit", outputConduit_);
        emit File("jug", jug_);
    }

    // --- administration ---
    function file(bytes32 what, address data) external auth {
        if (what == "outputConduit") { outputConduit = data; }
        else if (what == "jug") { jug = JugAbstract(data); }
        else revert("RwaUrn/unrecognised-param");
        emit File(what, data);
    }

    // --- cdp operation ---
    // n.b. that the operator must bring the gem
    function lock(uint256 wad) external operator {
        require(wad <= 2**255 - 1, "RwaUrn/overflow");
        DSTokenAbstract(gemJoin.gem()).transferFrom(msg.sender, address(this), wad);
        // join with address this
        gemJoin.join(address(this), wad);
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), int(wad), 0);
        emit Lock(msg.sender, wad);
    }
    // n.b. that the operator takes the gem
    // and might not be the same operator who brought the gem
    function free(uint256 wad) external operator {
        require(wad <= 2**255, "RwaUrn/overflow");
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), -int(wad), 0);
        gemJoin.exit(msg.sender, wad);
        emit Free(msg.sender, wad);
    }
    // n.b. DAI can only go to the output conduit
    function draw(uint256 wad) external operator {
        require(outputConduit != address(0));
        bytes32 ilk = gemJoin.ilk();
        jug.drip(ilk);
        (,uint256 rate,,,) = vat.ilks(ilk);
        uint256 dart = divup(mul(RAY, wad), rate);
        require(dart <= 2**255 - 1, "RwaUrn/overflow");
        vat.frob(ilk, address(this), address(this), address(this), 0, int(dart));
        daiJoin.exit(outputConduit, wad);
        emit Draw(msg.sender, wad);
    }
    // n.b. anyone can wipe
    function wipe(uint256 wad) external {
        daiJoin.join(address(this), wad);
        bytes32 ilk = gemJoin.ilk();
        jug.drip(ilk);
        (,uint256 rate,,,) = vat.ilks(ilk);
        uint256 dart = mul(RAY, wad) / rate;
        require(dart <= 2 ** 255, "RwaUrn/overflow");
        vat.frob(ilk, address(this), address(this), address(this), 0, -int(dart));
        emit Wipe(msg.sender, wad);
    }

    // If Dai is sitting here after ES that should be sent back
    function quit() external {
        require(outputConduit != address(0));
        require(vat.live() == 0, "RwaUrn/vat-still-live");
        DSTokenAbstract dai = DSTokenAbstract(daiJoin.dai());
        uint256 wad = dai.balanceOf(address(this));
        dai.transfer(outputConduit, wad);
        emit Quit(msg.sender, wad);
    }
}