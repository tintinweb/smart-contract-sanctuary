/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity 0.6.7;


pragma solidity 0.6.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



interface PauseLike {
    function delay() external returns (uint);
    function exec(address, bytes32, bytes calldata, uint256) external;
    function plot(address, bytes32, bytes calldata, uint256) external;
}

interface IlkRegistryAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function cat() external view returns (address);
    function spot() external view returns (address);
    function add(address) external;
}

interface ChainlogAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function keys() external view returns (bytes32[] memory);
    function version() external view returns (string memory);
    function ipfs() external view returns (string memory);
    function setVersion(string calldata) external;
    function setSha256sum(string calldata) external;
    function setIPFS(string calldata) external;
    function setAddress(bytes32,address) external;
    function removeAddress(bytes32) external;
    function count() external view returns (uint256);
    function get(uint256) external view returns (bytes32,address);
    function list() external view returns (bytes32[] memory);
    function getAddress(bytes32) external view returns (address);
}

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

interface FlipAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function bids(uint256) external view returns (uint256, uint256, address, uint48, uint48, address, address, uint256);
    function vat() external view returns (address);
    function cat() external view returns (address);
    function ilk() external view returns (bytes32);
    function beg() external view returns (uint256);
    function ttl() external view returns (uint48);
    function tau() external view returns (uint48);
    function kicks() external view returns (uint256);
    function file(bytes32, uint256) external;
    function kick(address, address, uint256, uint256, uint256) external returns (uint256);
    function tick(uint256) external;
    function tend(uint256, uint256, uint256) external;
    function dent(uint256, uint256, uint256) external;
    function deal(uint256) external;
    function yank(uint256) external;
}

interface OsmMomAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function osms(bytes32) external view returns (address);
    function setOsm(bytes32, address) external;
    function setOwner(address) external;
    function setAuthority(address) external;
    function stop(bytes32) external;
}

interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}


interface ConfigLike {
    function init(bytes32) external;
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint) external;
    function rely(address) external;
}


interface SpotAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (address, uint256);
    function vat() external view returns (address);
    function par() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function poke(bytes32) external;
    function cage() external;
}

library SharedStructs {

    // decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    uint256 constant ZERO_PERCENT_RATE            = 1000000000000000000000000000;


    struct IlkNetSpecific {   
        address gem;
        address join;
        address flip;
        address pip;
        ChainlogAbstract CHANGELOG;
    }

    struct IlkDesc {   
        bytes32 ilk;
        bytes32 joinName;
        bytes32 flipName;
        bytes32 pipName;
        bytes32 gemName;
        uint256 line;
        uint256 dust;
        uint256 dunk;
        uint256 chop;
        uint256 duty;
        uint256 beg;
        uint256 ttl;
        uint256 tau;
        uint256 mat;
    }
}

contract SpellAction {


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PERCENT_RATE            = 1000000000000000000000000000;
    uint256 constant ONE_PERCENT_RATE             = 1000000000315522921573372069;
    uint256 constant TWO_PERCENT_RATE             = 1000000000627937192491029810;
    uint256 constant TWO_POINT_FIVE_PERCENT_RATE  = 1000000000782997609082909351;
    uint256 constant THREE_PERCENT_RATE           = 1000000000937303470807876289;
    uint256 constant FOUR_POINT_FIVE_PERCENT_RATE = 1000000001395766281313196627;
    uint256 constant FIVE_PERCENT_RATE            = 1000000001547125957863212448;
    uint256 constant SIX_PERCENT_RATE             = 1000000001847694957439350562;
    uint256 constant EIGHT_PERCENT_RATE           = 1000000002440418608258400030;
    uint256 constant NINE_PERCENT_RATE            = 1000000002732676825177582095;
    uint256 constant TEN_PERCENT_RATE             = 1000000003022265980097387650;



    function execute(SharedStructs.IlkDesc memory desc, 
                     SharedStructs.IlkNetSpecific memory net) internal {

        ChainlogAbstract CHANGELOG = net.CHANGELOG;

        address MCD_VAT      = CHANGELOG.getAddress("MCD_VAT");
        address MCD_CAT      = CHANGELOG.getAddress("MCD_CAT");
        address MCD_JUG      = CHANGELOG.getAddress("MCD_JUG");
        address MCD_SPOT     = CHANGELOG.getAddress("MCD_SPOT");
        address MCD_END      = CHANGELOG.getAddress("MCD_END");
        address FLIPPER_MOM  = CHANGELOG.getAddress("FLIPPER_MOM");
        address OSM_MOM      = CHANGELOG.getAddress("OSM_MOM"); // Only if PIP_TOKEN = Osm
        address ILK_REGISTRY = CHANGELOG.getAddress("ILK_REGISTRY");


        // Set the global debt ceiling
        // +  100 M for gem-A
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() + desc.line * SharedStructs.MILLION * SharedStructs.RAD);

        // Sanity checks
        require(GemJoinAbstract(net.join).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(net.join).ilk() == desc.ilk, "join-ilk-not-match");
        require(GemJoinAbstract(net.join).gem() == net.gem, "join-gem-not-match");
        require(GemJoinAbstract(net.join).dec() == IERC20(net.gem).decimals(), "join-dec-not-match");
        require(FlipAbstract(net.flip).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(net.flip).cat() == MCD_CAT, "flip-cat-not-match");
        require(FlipAbstract(net.flip).ilk() == desc.ilk, "flip-ilk-not-match");

        // Set the gem PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(desc.ilk, "pip", net.pip);

        // Set the gem-A Flipper in the Cat
        ConfigLike(MCD_CAT).file(desc.ilk, "flip", net.flip);

        // Init gem-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(desc.ilk);
        ConfigLike(MCD_JUG).init(desc.ilk);

        // Allow gem-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(net.join);
        // Allow the gem-A Flipper to reduce the Cat litterbox on deal()
        ConfigLike(MCD_CAT).rely(net.flip);
        // Allow Cat to kick auctions in gem-A Flipper
        FlipAbstract(net.flip).rely(MCD_CAT);
        // Allow End to yank auctions in gem-A Flipper
        FlipAbstract(net.flip).rely(MCD_END);
        // Allow FlipperMom to access to the gem-A Flipper
        FlipAbstract(net.flip).rely(FLIPPER_MOM);
        // Disallow Cat to kick auctions in gem-A Flipper
        // !!!!!!!! Only for certain collaterals that do not trigger liquidations like USDC-A)
        //FlipperMomAbstract(FLIPPER_MOM).deny(net.flip);

        // Set gem Osm in the OsmMom for new ilk
        // !!!!!!!! Only if net.pip = Osm
        OsmMomAbstract(OSM_MOM).setOsm(desc.ilk, net.pip);

        // Set the gem-A debt ceiling
        VatAbstract(MCD_VAT).file(desc.ilk, "line", desc.line * SharedStructs.MILLION * SharedStructs.RAD);
        // Set the gem-A dust
        VatAbstract(MCD_VAT).file(desc.ilk, "dust", desc.dust * SharedStructs.RAD);
        // Set the Lot size
        ConfigLike(MCD_CAT).file(desc.ilk, "dunk", desc.dunk * SharedStructs.RAD);
        // Set the gem-A liquidation penalty (e.g. 13% => X = 113)
        ConfigLike(MCD_CAT).file(desc.ilk, "chop", desc.chop);
        // Set the gem-A stability fee (e.g. 1% = 1000000000315522921573372069)
        ConfigLike(MCD_JUG).file(desc.ilk, "duty", desc.duty);
        // Set the gem-A percentage between bids (e.g. 3% => X = 103)
        FlipAbstract(net.flip).file("beg", desc.beg);
        // Set the gem-A time max time between bids
        FlipAbstract(net.flip).file("ttl", desc.ttl);
        // Set the gem-A max auction duration to
        FlipAbstract(net.flip).file("tau", desc.tau);
        // Set the gem-A min collateralization ratio (e.g. 150% => X = 150)
        SpotAbstract(MCD_SPOT).file(desc.ilk, "mat", desc.mat);

        // Update gem-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(desc.ilk);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(net.join);

        // Update the changelog
        CHANGELOG.setAddress(desc.gemName, net.gem);
        CHANGELOG.setAddress(desc.joinName, net.join);
        CHANGELOG.setAddress(desc.flipName, net.flip);
        CHANGELOG.setAddress(desc.pipName, net.pip);
        // Bump version
    }
}


contract IlkCurveCfg {

    function getIlkCfg() internal pure returns (SharedStructs.IlkDesc memory desc) {

        desc.ilk = "CRV_3POOL-A";
        desc.joinName = "MCD_JOIN_CRV_3POOL_A";
        desc.flipName = "MCD_FLIP_CRV_3POOL_A";
        desc.pipName = "PIP_CRV_3POOL";
        desc.gemName = "CRV_3POOL";
        desc.line = 150;
        desc.dust = 100;
        desc.dunk = 50000;
        desc.chop = 113 * SharedStructs.WAD / 100;
        desc.duty = SharedStructs.ZERO_PERCENT_RATE;
        desc.beg = 101 * SharedStructs.WAD / 100;
        desc.ttl = 21600;
        desc.tau = 21600;
        desc.mat = 110 * SharedStructs.RAY / 100;
    }
}

contract SpellActionMainnet is SpellAction, IlkCurveCfg {
    function execute() external {

        SharedStructs.IlkNetSpecific memory net;

        net.gem  = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
        net.join = 0xDcd8cad273373DD52B23194EC9B4a207EfEC99CD;
        net.flip = 0xDA03DAD7D4B012214F353E15F5656c4dFF35ABC2;
        net.pip = 0x7BBa7664baaec1DB10b16E6cf712007BEA644dc0;
        net.CHANGELOG = ChainlogAbstract(0xE0fb0a1B0F1db37D803bad3F6d55158291Bb7bAc);

        execute(getIlkCfg(), net);

        net.CHANGELOG.setVersion("1.1.0");
    }
}

contract SpellActionKovan is SpellAction, IlkCurveCfg {
    function execute() external {

        SharedStructs.IlkNetSpecific memory net;

        net.gem  = 0x168a6114396aAB83Ba14b8Bd8E5B4D7CB3c2E82e;
        net.join = 0xcf68FB166293cDE638FA55451FdCC6F9E569fe15;
        net.flip = 0x0Fe624186e46EF16bc3c483eA0790d2694DD5Acc;
        net.pip = 0x0F5ad35285A9D4e27E932777494a77461A579Bd6;
        net.CHANGELOG = ChainlogAbstract(0x873396d69b017e3Ed499406892E1cd2f3EE1CFA7);


        execute(getIlkCfg(), net);

        net.CHANGELOG.setVersion("1.2.0");
    }
}


contract ActionSpell {
    bool      public done;
    address   public pause;
    uint256   public expiration;


    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;




    function setup(address deployer) internal {
        expiration = block.timestamp + 30 days;
        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag; assembly { _tag := extcodehash(deployer) }
        action = deployer;
        tag = _tag;
    }

    function schedule() external {
        require(block.timestamp <= expiration, "DSSSpell/spell-has-expired");
        require(eta == 0, "spell-already-scheduled");
        eta = now + PauseLike(pause).delay();
        PauseLike(pause).plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        PauseLike(pause).exec(action, tag, sig, eta);
    }
}


contract ActionSpellMainnet is ActionSpell {
    constructor() public {
        pause = 0x146921eF7A94C50b96cb53Eb9C2CA4EB25D4Bfa8;
        setup(address(new SpellActionMainnet()));
    }
}


contract ActionSpellKovan is ActionSpell {
    constructor() public {
        pause = 0x95D6fBdD8bE0FfBEB62b3B3eB2A7dFD19cFae8F5;
        setup(address(new SpellActionKovan()));
    }
}