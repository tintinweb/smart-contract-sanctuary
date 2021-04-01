/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol
pragma solidity =0.5.12 >=0.5.12;

////// lib/rwa-example/lib/dss-interfaces/src/dapp/DSPauseAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-pause
interface DSPauseAbstract {
    function setOwner(address) external;
    function setAuthority(address) external;
    function setDelay(uint256) external;
    function plans(bytes32) external view returns (bool);
    function proxy() external view returns (address);
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function drop(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

////// lib/rwa-example/lib/dss-interfaces/src/dapp/DSTokenAbstract.sol
/* pragma solidity >=0.5.12; */

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

////// lib/rwa-example/lib/dss-interfaces/src/dss/ChainlogAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-chain-log
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

// Helper function for returning address or abstract of Chainlog
//  Valid on Mainnet, Kovan, Rinkeby, Ropsten, and Goerli
contract ChainlogHelper {
    address          public constant ADDRESS  = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    ChainlogAbstract public constant ABSTRACT = ChainlogAbstract(ADDRESS);
}

////// lib/rwa-example/lib/dss-interfaces/src/dss/GemJoinAbstract.sol
/* pragma solidity >=0.5.12; */

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

////// lib/rwa-example/lib/dss-interfaces/src/dss/JugAbstract.sol
/* pragma solidity >=0.5.12; */

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

////// lib/rwa-example/lib/dss-interfaces/src/dss/SpotAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/spot.sol
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

////// lib/rwa-example/lib/dss-interfaces/src/dss/VatAbstract.sol
/* pragma solidity >=0.5.12; */

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

////// src/spell.sol
/* pragma solidity 0.5.12; */

/* import "dss-interfaces/dss/VatAbstract.sol"; */
/* import "dss-interfaces/dapp/DSPauseAbstract.sol"; */
/* import "dss-interfaces/dss/JugAbstract.sol"; */
/* import "dss-interfaces/dss/SpotAbstract.sol"; */
/* import "dss-interfaces/dss/GemJoinAbstract.sol"; */
/* import "dss-interfaces/dapp/DSTokenAbstract.sol"; */
/* import "dss-interfaces/dss/ChainlogAbstract.sol"; */

interface RwaLiquidationLike_1 {
    function wards(address) external returns (uint256);
    function ilks(bytes32) external returns (bytes32,address,uint48,uint48);
    function rely(address) external;
    function deny(address) external;
    function init(bytes32, uint256, string calldata, uint48) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32) external;
    function good(bytes32) external view;
}

interface RwaOutputConduitLike_1 {
    function wards(address) external returns (uint256);
    function can(address) external returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function hope(address) external;
    function nope(address) external;
    function bud(address) external returns (uint256);
    function kiss(address) external;
    function diss(address) external;
    function pick(address) external;
    function push() external;
}

interface RwaUrnLike_1 {
    function hope(address) external;
}

contract SpellAction {
    // KOVAN ADDRESSES
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/kovan/latest/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address constant NS2DRP_OPERATOR           = 0x8905C7066807793bf9c7cd1d236DEF0eE2692B9a;
    address constant NS2DRP_GEM                = 0x1C3765c94aF9b7eB3fdEC69Eddb7Ddf27f2BcFf4;
    address constant MCD_JOIN_NS2DRP_A         = 0x4B8C10da2B70dE45f7Ea106A961F2Fb79f5bC2bE;
    address constant NS2DRP_A_URN              = 0xdFb4E887D89Ac14b0337C9dC05d8f5e492B9847C;
    address constant NS2DRP_A_INPUT_CONDUIT    = 0x8905C7066807793bf9c7cd1d236DEF0eE2692B9a;
    address constant NS2DRP_A_OUTPUT_CONDUIT   = 0x8905C7066807793bf9c7cd1d236DEF0eE2692B9a;
    uint256 constant NS2DRP_THREEPOINTSIX_PERCENT_RATE = 1000000001121484774769253326;

    // precision
    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;

    uint256 constant NS2DRP_A_INITIAL_DC    = 5 * MILLION * RAD; 
    // CreditLine + 2 years of stability fee
    uint256 constant NS2DRP_A_INITIAL_PRICE = 5_366_480 * WAD; // 5,366,480
    // CreditLine + 1 years of stability fee
    // uint256 constant NS2DRP_A_INITIAL_PRICE = 5180000 * WAD; // 5,180,000

    // MIP13c3-SP4 Declaration of Intent & Commercial Points -
    // Off-Chain Asset Backed Lender to onboard Real World Assets
    // as Collateral for a DAI loan
    // https://ipfs.io/ipfs/QmSwZzhzFgsbduBxR4hqCavDWPjvAHbNiqarj1fbTwpevR
    string constant DOC = "QmSwZzhzFgsbduBxR4hqCavDWPjvAHbNiqarj1fbTwpevR";

    function execute() external {
        address MCD_VAT  = ChainlogAbstract(CHANGELOG).getAddress("MCD_VAT");
        address MCD_JUG  = ChainlogAbstract(CHANGELOG).getAddress("MCD_JUG");
        address MCD_SPOT = ChainlogAbstract(CHANGELOG).getAddress("MCD_SPOT");
        address MIP21_LIQUIDATION_ORACLE = ChainlogAbstract(CHANGELOG).getAddress("MIP21_LIQUIDATION_ORACLE");

        // NS2DRP-A collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilk = "NS2DRP-A";
        
        // add NS2DRP contract to the changelog
        CHANGELOG.setAddress("NS2DRP", NS2DRP_GEM);
        CHANGELOG.setAddress("MCD_JOIN_NS2DRP_A", MCD_JOIN_NS2DRP_A);
        CHANGELOG.setAddress("NS2DRP_A_URN", NS2DRP_A_URN);
        CHANGELOG.setAddress("NS2DRP_A_INPUT_CONDUIT", NS2DRP_A_INPUT_CONDUIT);
        CHANGELOG.setAddress("NS2DRP_A_OUTPUT_CONDUIT", NS2DRP_A_OUTPUT_CONDUIT);


        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_NS2DRP_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_NS2DRP_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_NS2DRP_A).gem() == NS2DRP_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_NS2DRP_A).dec() == DSTokenAbstract(NS2DRP_GEM).decimals(), "join-dec-not-match");

        // init the RwaLiquidationOracle
        // doc: "IPFS Hash"
        // tau: 5 minutes
        RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).init(
            ilk, NS2DRP_A_INITIAL_PRICE, DOC, 300
        );
        (,address pip,,) = RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        CHANGELOG.setAddress("PIP_NS2DRP", pip);

        // Set price feed for NS2DRP
        SpotAbstract(MCD_SPOT).file(ilk, "pip", pip);

        // Init NS2DRP in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // Init NS2DRP in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // Allow NS2DRP Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_NS2DRP_A);

        // Allow RwaLiquidationOracle to modify Vat registry
        // VatAbstract(MCD_VAT).rely(MIP21_LIQUIDATION_ORACLE);

        // 5 Million debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", NS2DRP_A_INITIAL_DC);
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() + NS2DRP_A_INITIAL_DC);

        // No dust
        // VatAbstract(MCD_VAT).file(ilk, "dust", 0)

        // 3.6% stability fee
        JugAbstract(MCD_JUG).file(ilk, "duty", NS2DRP_THREEPOINTSIX_PERCENT_RATE);

        // Set the NS2DRP-A min collateralization ratio (e.g. 105% => X = 105)
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 100 * RAY / 100);

        // poke the spotter to pull in a price
        SpotAbstract(MCD_SPOT).poke(ilk);

        // give the urn permissions on the join adapter
        GemJoinAbstract(MCD_JOIN_NS2DRP_A).rely(NS2DRP_A_URN);

        // set up the urn
        RwaUrnLike_1(NS2DRP_A_URN).hope(NS2DRP_OPERATOR);
    }
}

contract RwaSpell {

    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    DSPauseAbstract public pause =
        DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    string constant public description = "New Silver Spell Deploy";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = block.timestamp + 30 days;
    }

    function schedule() public {
        require(block.timestamp <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}