/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

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
        virtual
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        virtual
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

contract DSRoles is DSAuth, DSAuthority
{
    mapping(address=>bool) _root_users;
    mapping(address=>bytes32) _user_roles;
    mapping(address=>mapping(bytes4=>bytes32)) _capability_roles;
    mapping(address=>mapping(bytes4=>bool)) _public_capabilities;

    function getUserRoles(address who)
        public
        view
        returns (bytes32)
    {
        return _user_roles[who];
    }

    function getCapabilityRoles(address code, bytes4 sig)
        public
        view
        returns (bytes32)
    {
        return _capability_roles[code][sig];
    }

    function isUserRoot(address who)
        public
        view virtual
        returns (bool)
    {
        return _root_users[who];
    }

    function isCapabilityPublic(address code, bytes4 sig)
        public
        view
        returns (bool)
    {
        return _public_capabilities[code][sig];
    }

    function hasUserRole(address who, uint8 role)
        public
        view
        returns (bool)
    {
        bytes32 roles = getUserRoles(who);
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        return bytes32(0) != roles & shifted;
    }

    function canCall(address caller, address code, bytes4 sig)
        public override
        view
        returns (bool)
    {
        if( isUserRoot(caller) || isCapabilityPublic(code, sig) ) {
            return true;
        } else {
            bytes32 has_roles = getUserRoles(caller);
            bytes32 needs_one_of = getCapabilityRoles(code, sig);
            return bytes32(0) != has_roles & needs_one_of;
        }
    }

    function BITNOT(bytes32 input) internal pure returns (bytes32 output) {
        return (input ^ bytes32(uint(-1)));
    }

    function setRootUser(address who, bool enabled)
        public virtual
        auth
    {
        _root_users[who] = enabled;
    }

    function setUserRole(address who, uint8 role, bool enabled)
        public
        auth
    {
        bytes32 last_roles = _user_roles[who];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if( enabled ) {
            _user_roles[who] = last_roles | shifted;
        } else {
            _user_roles[who] = last_roles & BITNOT(shifted);
        }
    }

    function setPublicCapability(address code, bytes4 sig, bool enabled)
        public
        auth
    {
        _public_capabilities[code][sig] = enabled;
    }

    function setRoleCapability(uint8 role, address code, bytes4 sig, bool enabled)
        public
        auth
    {
        bytes32 last_roles = _capability_roles[code][sig];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if( enabled ) {
            _capability_roles[code][sig] = last_roles | shifted;
        } else {
            _capability_roles[code][sig] = last_roles & BITNOT(shifted);
        }

    }

}

// DSProxy
// Allows code execution using a persistant identity This can be very
// useful to execute a sequence of atomic actions. Since the owner of
// the proxy can be changed, this allows for dynamic ownership models
// i.e. a multisig
contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache;  // global cache for contracts

    constructor(address _cacheAddr) public {
        setCache(_cacheAddr);
    }

    receive() external payable {
    }

    // use the proxy to execute calldata _data on contract _code
    function execute(bytes memory _code, bytes memory _data)
        public
        payable
        returns (address target, bytes memory response)
    {
        target = cache.read(_code);
        if (target == address(0)) {
            // deploy contract & store its address in cache
            target = cache.write(_code);
        }

        response = execute(target, _data);
    }

    function execute(address _target, bytes memory _data)
        public
        auth
        note
        payable
        returns (bytes memory response)
    {
        require(_target != address(0), "ds-proxy-target-address-required");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas(), 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    //set new cache
    function setCache(address _cacheAddr)
        public
        auth
        note
        returns (bool)
    {
        require(_cacheAddr != address(0), "ds-proxy-cache-address-required");
        cache = DSProxyCache(_cacheAddr);  // overwrite cache
        return true;
    }
}

// DSProxyFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
contract DSProxyFactory {
    event Created(address indexed sender, address indexed owner, address proxy, address cache);
    mapping(address=>bool) public isProxy;
    DSProxyCache public cache;

    constructor() public {
        cache = new DSProxyCache();
    }

    // deploys a new proxy instance
    // sets owner of proxy to caller
    function build() public returns (address payable proxy) {
        proxy = build(msg.sender);
    }

    // deploys a new proxy instance
    // sets custom owner of proxy
    function build(address owner) public returns (address payable proxy) {
        proxy = address(new DSProxy(address(cache)));
        emit Created(msg.sender, owner, address(proxy), address(cache));
        DSProxy(proxy).setOwner(owner);
        isProxy[proxy] = true;
    }
}

// DSProxyCache
// This global cache stores addresses of contracts previously deployed
// by a proxy. This saves gas from repeat deployment of the same
// contracts and eliminates blockchain bloat.

// By default, all proxies deployed from the same factory store
// contracts in the same cache. The cache a proxy instance uses can be
// changed.  The cache uses the sha3 hash of a contract's bytecode to
// lookup the address
contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes memory _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
            case 1 {
                // throw if contract failed to deploy
                revert(0, 0)
            }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
}

interface DenyLike {
    function deny(address) external;
}

contract MultisigTransfer
{
	address constant DEPLOYER = 0x0B640b3E91420B495a33d11Ee96AFb19bE2Db693;
	address constant MULTICALL = 0x0b78ad358dDa2887285eaD72e84b47242360b872;
	address constant PROXY_FACTORY = 0xb05b13496A6451A1Eb2fB18393232368b345C577;
	address constant PROXY_REGISTRY = 0x4939C03546FEAeC270507e8D4a819BeB40A2BD59;
	address constant VAT_FAB = 0x741C6E1ef20f3932148468b97d18267520D94994;
	address constant JUG_FAB = 0x8A1F8ce3De0F3d54F8D3218b42390637eF6037E0;
	address constant VOW_FAB = 0xe090fbA275a39A66f37487801D86EE099F75148a;
	address constant CAT_FAB = 0x2eb0DCb9eDfCA6DcC944Aa541B9f075Cb54D4576;
	address constant DOG_FAB = 0x2a276BB021426EA89536e918e0105D3243FD3b86;
	address constant DAI_FAB = 0x0B9D71FecE78E8F93Ab6C35A12A02513Eb0D8e79;
	address constant MCD_JOIN_FAB = 0x45777E44d2d59b4d3bADB198CC5ece59524c7cce;
	address constant FLAP_FAB = 0xB319297a68E6b3d25D6d3C34b773614186EdB0C5;
	address constant FLOP_FAB = 0x17dC3B78E2eCb298187B8d0c2929B00C8A154746;
	address constant FLIP_FAB = 0x30623E39aed9483c033FEd109f5fd009ff7F0bAf;
	address constant CLIP_FAB = 0xC1A9385d9953d4C0552db4Ad321b71B97309b1b1;
	address constant SPOT_FAB = 0xc652b9c2aB4Fe6E17EBA677dcc7Bb0b7F6e76770;
	address constant POT_FAB = 0x7E98Da8124baa6d800f9c021643996595485BA80;
	address constant END_FAB = 0x1e674E1D2B8a1bF8431AD099B94a3B6E49847ED6;
	address constant ESM_FAB = 0xA7E3ef1BCE9f894d9f8205AAbD478a8e461e0610;
	address constant PAUSE_FAB = 0xa5e94e7BB58df6471FcFFdeaE14F3e4b16a48420;
	address constant MCD_DEPLOY = 0xa10d039d4AD03f15FFF3e49916F62D35923238f6;
	address constant MCD_ADM_TEMP = 0xDacf9095314275E65b9aF40c0e6b0BB8969ad684;
	address constant MCD_VAT = 0x713C28b2Ef6F89750BDf97f7Bbf307f6F949b3fF;
	address constant MCD_SPOT = 0x7C4925D62d24A826F8d945130E620fdC510d0f68;
	address constant MCD_DAI = 0x87BAde473ea0513D4aA7085484aEAA6cB6EBE7e3;
	address constant MCD_JOIN_DAI = 0x9438760f1ac27F7cFE638D686d889C56eb42F4D0;
	address constant MCD_JUG = 0xb2d474EAAB89DD0134B8A98a9AB38aC41a537c6C;
	address constant MCD_POT = 0x6e22DA49b28dc5aB70aC7527CC0cc04bD35eB615;
	address constant MCD_FLAP = 0x3Bf3C5146c5b1259f8886d3B2480aD53A835F795;
	address constant MCD_FLOP = 0x1DC6298DCa4A433581802144Da9bA1640d90FEFc;
	address constant MCD_VOW = 0xbb37ccb8eFd844abD260AfC68025F5491570AC9d;
	address constant MCD_CAT = 0x22db688102b2Fa5bD0456252Fc4a9EA6ca70F9dE;
	address constant MCD_DOG = 0xDea7563440195eA7Ea83900DE38F603C25a37594;
	address constant MCD_END = 0x7f70639F3aC04b2919d5bA1b397aDe484D87be4e;
	address constant MCD_PAUSE = 0xb93949F3b910A6cfAc8d76B1677BA331183498A4;
	address constant MCD_PAUSE_PROXY = 0x8Ab3Ce4138fA46C2E0FcaA89e8A721A6252e5Fae;
	address constant MCD_ESM = 0x9C482597dA255549F53406b2D57498d2959F2EA7;
	address constant VAL_BUSD = 0x08F39c96E6A954894252171a5300dECD350d3fA8;
	address constant VAL_USDC = 0xd4d7BCF6c7b54349C91f39cAd89B228C53FE6BD7;
	address constant VAL_BNB = 0x63c2E42758EF8776BF7b70afb00E0e2748Ad3F05;
	address constant VAL_ETH = 0x7622ce6588116c1C7F1a4E61A153C1efC7226f78;
	address constant VAL_BTCB = 0x585707c57413e09a4BE58e89798f5074b2B89De1;
	address constant VAL_CAKE = 0x447FE0cc2145F27127Cf60C6FD6D9025A4208b8B;
	address constant VAL_BANANA = 0x6Ee2E2d648698357Cc518D1D5E8170586dca5348;
	address constant VAL_PCSBNBCAKE = 0x326Db2b9640e51077fD9B70767855f5c2128e91A;
	address constant VAL_PCSBNBBUSD = 0x1a06452B84456728Ee4054AE6157d3feDF56C295;
	address constant VAL_PCSBNBETH = 0x8BBcd7E4da4395E391Fbfc2A11775debe3ca0D58;
	address constant VAL_PCSBNBBTCB = 0xcf55226EE56F174B3cB3F75a5182d2300e788e91;
	address constant VAL_PCSBUSDUSDC = 0xC5065b47A133071fe8cD94f46950fCfBA53864C6;
	address constant VAL_PCSBUSDBTCB = 0x3d4604395595Bb30A8B7754b5dDBF0B3F680564b;
	address constant VAL_PCSBUSDCAKE = 0x1e1ee1AcD4B7ad405A0D701884F093d54DF7fba4;
	address constant VAL_PCSETHBTCB = 0x58849cE72b4E4338C00f0760Ca6AfCe11b5ee370;
	address constant VAL_PCSETHUSDC = 0xc690F38430Db2057C992c3d3190D9902CD7E0294;
	address constant VAL_STKCAKE = 0xeE991787C4ffE1de8c8c7c45e3EF14bFc47A2735;
	address constant VAL_STKBANANA = 0xE4d5a6E0581646f5a5806F9c171E96879ae8b385;
	address constant VAL_STKPCSBNBCAKE = 0x5Df1B3212EB26f506af448cE25cd4E315BEdf630;
	address constant VAL_STKPCSBNBBUSD = 0x8a8eA20937BBC38c0952b206892e9A273E7180E1;
	address constant VAL_STKPCSBNBETH = 0x0Ca167778392473E0868503522a11f1e749bbF82;
	address constant VAL_STKPCSBNBBTCB = 0x7e7C92D432307218b94052488B2CD54D8b826546;
	address constant VAL_STKPCSBUSDUSDC = 0x7bA715959A52ef046BE76c4E32f1de1d161E2888;
	address constant VAL_STKPCSBUSDBTCB = 0x8652883985B39D85B6432e3Ec5D9bea77edc31b0;
	address constant VAL_STKPCSBUSDCAKE = 0xeBcb52E5696A2a90D684C76cDf7095534F265370;
	address constant VAL_STKPCSETHBTCB = 0x70AF6F516f9E167620a5bdd970c671c69C81E92F;
	address constant VAL_STKPCSETHUSDC = 0x68697fF7Ec17F528E3E4862A1dbE6d7D9cBBd5C6;
	address constant MCD_JOIN_STKCAKE_A = 0xf72f07b96D4Ee64d1065951cAfac032B63C767bb;
	address constant MCD_CLIP_CALC_STKCAKE_A = 0xeeF286Af1d7601EA5E40473741D79e55770498d8;
	address constant MCD_CLIP_STKCAKE_A = 0x61C8CF1e4E1DBdF88fceDd55e2956345b4df6B21;
	address constant MCD_JOIN_STKBANANA_A = 0x3728Bd61F582dA0b22cFe7EDC59aC33f7402c4e0;
	address constant MCD_CLIP_CALC_STKBANANA_A = 0xca70528209917F4D0443Dd3e90C863b19584CCAF;
	address constant MCD_CLIP_STKBANANA_A = 0xFFAee04Db99530DeCAe1133DbEc5fD7Cc3BcC4aD;
	address constant MCD_JOIN_STKPCSBNBCAKE_A = 0x9605863bf02E983861C0a4ac28a7527Fcf36732b;
	address constant MCD_CLIP_CALC_STKPCSBNBCAKE_A = 0x2117C852417B008d18E292D18ab196f49AA896cf;
	address constant MCD_CLIP_STKPCSBNBCAKE_A = 0x62711202EF9368e5401eCeaFD90E71A411286Edd;
	address constant MCD_JOIN_STKPCSBNBBUSD_A = 0x842B07b7D9C77A6bE833a660FB628C6d28Bda0a8;
	address constant MCD_CLIP_CALC_STKPCSBNBBUSD_A = 0x7253bC2Ca443807391451a54cAF1bC1915A8b584;
	address constant MCD_CLIP_STKPCSBNBBUSD_A = 0x0c6eEaE3a36ec66B30A58917166D526f499e431B;
	address constant MCD_JOIN_STKPCSBNBETH_A = 0x65764167EC4B38D611F961515B51a40628614018;
	address constant MCD_CLIP_CALC_STKPCSBNBETH_A = 0x74a08d8D88Aaf7d83087aa159B5e17F017cd1cFD;
	address constant MCD_CLIP_STKPCSBNBETH_A = 0x6f77799B3D36a61FdF8eb82E0DdEDcF4BA041042;
	address constant MCD_JOIN_STKPCSBNBBTCB_A = 0x7ae7E7D2efCBB0289E451Fc167DF91b996390d7C;
	address constant MCD_CLIP_CALC_STKPCSBNBBTCB_A = 0x3a6a2d813Bc8C51E72d3348311c62EB2D1D9dEe2;
	address constant MCD_CLIP_STKPCSBNBBTCB_A = 0x940aA35E47d54a5EE4dc3C6Ff6Eb1bdec065c2A5;
	address constant MCD_JOIN_STKPCSBUSDUSDC_A = 0xd312EC88F0CE9512804db1e08b1EB6901c278d0f;
	address constant MCD_CLIP_CALC_STKPCSBUSDUSDC_A = 0x6ef32c6cF03B83Ab3A0DcA92f03E67A40CC45f7D;
	address constant MCD_CLIP_STKPCSBUSDUSDC_A = 0x8641BdBECE44c3f05b1991922f721C4585f22456;
	address constant MCD_JOIN_STKPCSBUSDBTCB_A = 0x6ADeB113EbD9a6a9B7CaB380Ba0A204DC08456b5;
	address constant MCD_CLIP_CALC_STKPCSBUSDBTCB_A = 0xDD8E350052537bE8A621c8431117969E9B96343d;
	address constant MCD_CLIP_STKPCSBUSDBTCB_A = 0x226d0e1AC4C8b6253caf5CEda067fb5a6EDCDF6F;
	address constant MCD_JOIN_STKPCSBUSDCAKE_A = 0x77a5E69955E1837B0c3f50159577ccb7468d6a4d;
	address constant MCD_CLIP_CALC_STKPCSBUSDCAKE_A = 0xD9241689BBcaa6BF11854Af5f9c18AA642a98C23;
	address constant MCD_CLIP_STKPCSBUSDCAKE_A = 0x435D4017b6A4C21f25077ccd5849F083F3e20452;
	address constant MCD_JOIN_STKPCSETHBTCB_A = 0x781E44923fb912b1d0aa892BBf62dD1b4dfC9cd5;
	address constant MCD_CLIP_CALC_STKPCSETHBTCB_A = 0xd6e80B0ae1f84A37AB145084a80893854c27ecc0;
	address constant MCD_CLIP_STKPCSETHBTCB_A = 0x754e4D6fbbDdE2e77c390E4BAC54C7e0E48901Ab;
	address constant MCD_JOIN_STKPCSETHUSDC_A = 0x754B2f8704A3D453151eE69875ECde4C610F2BEa;
	address constant MCD_CLIP_CALC_STKPCSETHUSDC_A = 0x972F78558B4F8D677d84c8d1d4A73836c8DE4900;
	address constant MCD_CLIP_STKPCSETHUSDC_A = 0xbCa0650FF329211D3784C82196421A885FDB0451;
	address constant PROXY_ACTIONS = 0x1Cd756Ac1D442a2D725c5F6312Fb8244104c2850;
	address constant PROXY_ACTIONS_END = 0xB651Ec511675925ebCa7B035baf5B77190FD3440;
	address constant PROXY_ACTIONS_DSR = 0x136EF4EbB71c147969AFB9666D4b900756C64b27;
	address constant CDP_MANAGER = 0x563d13664023a7d63463b8cdc443552c047642Cb;
	address constant GET_CDPS = 0x62705B32e873e939738064c9a1009a037Df7615e;
	address constant DSR_MANAGER = 0xbB0613d967411394626Ecc48e019960c4724364E;
	address constant OSM_MOM = 0x6d6e37f4fFC13ebA4B6e0158cE8753549152BF35;
	address constant FLIPPER_MOM = 0x7dB700723a20511Beb367694e8c33b8dc23418bB;
	address constant CLIPPER_MOM = 0xD56d12F8afaE2bf9CfcF1201F00a3c4560B93276;
	address constant ILK_REGISTRY = 0x32Ea492a11450B5292A5E6EFc059c851cB096d04;
	address constant MCD_GOV_ACTIONS = 0xbD69CD541E7676222d4003aB0dB6ecff59E9503c;
	address constant PROXY_PAUSE_ACTIONS = 0x689c75aF6272409f8C9cD904DAE1945EBa2129BF;
	address constant PROXY_DEPLOYER = 0xC68776AC66De86B4DEB240E9619054C90A758d7c;
	address constant MCD_IOU = 0x00793e8D7ccE68D3C196Fa40ba96494311274Ed2;
	address constant MCD_ADM = 0x790AE603e560457D3aFab286A2E27C0502AE17E5;
	address constant VOTE_PROXY_FACTORY = 0x926E0b08522B6bA732551E548e9d85d5c982Cf0A;
	address constant MCD_POLLING_EMITTER = 0x2ff2cf32cB3a6F1f7b7Dc22e54A336EFd6ff86Db;
	address constant VOTE_DELEGATE_PROXY_FACTORY = 0x66Fd8cFf13815D7b333f1205023C7af6Aa4020FB;
	address constant MCD_IAM_AUTO_LINE = 0x25B92928363E591D1b6f02bFe3c8dBdDEf5e0BD5;
	address constant MCD_FLASH = 0xb0947C3aeCC1C0FEA1F25e1cFadD4087102943Bf;
	address constant CHANGELOG = 0xc1E1d478296F3b0F2CA9Cc88F620de0b791aBf27;
	address constant LERP_FAB = 0x8a54d489B2B21E9FE5f762f73b8e7e929345C994;
	address constant VAL_PSM_BUSD = 0x4C4119f8438CC66CE21414dC7d09437954433C78;
	address constant MCD_JOIN_PSM_BUSD_A = 0xE02CE329281664A5d2BC0006342DC84f6c384663;
	address constant MCD_CLIP_CALC_PSM_BUSD_A = 0xA751810B9654cc7B59c6C48da93E102eBAB2f8c3;
	address constant MCD_CLIP_PSM_BUSD_A = 0x9E4D1b626a39065142420d518adA0654606e9AEa;
	address constant MCD_PSM_BUSD_A = 0x90F3Fb97a56b83bAE3d26A47f250760CD8FF8cB1;
	address constant VAL_MOR = 0x3Ac5DF5d1a97E66d9a20c90961daaBcf9EC34B06;
	address constant VAL_APEMORBUSD = 0x2987bC4DD60A0bC8801ADCE4EdFB1efB6781A984;
	address constant VAL_STKAPEMORBUSD = 0x627A13421df5Ff3FdF8f56AF2911c287ad8CbE9f;
	address constant MCD_JOIN_STKAPEMORBUSD_A = 0xF755dA11576A9C3355a854F79e4F80E00e251358;
	address constant MCD_CLIP_CALC_STKAPEMORBUSD_A = 0xd7Ee11db2155679C68e7e412ADFbC342cBb7F6C0;
	address constant MCD_CLIP_STKAPEMORBUSD_A = 0xa4f9600534190d96bc60D33A3594E0b0869cAdaB;

	// to be executed as a delegateCall on the GrowthDeFi Gnosis multisig
	function runTest() external
	{
		adjustDuty();
	}

	// to be executed as a delegateCall on the GrowthDeFi Gnosis multisig
	function run() external
	{
		// restore final deploy state and transfer admin rights to the shared multisig
		restoreState();
		renounceAuth();
		transferOwnership(0xe8E59b65E2BeC9F5c4AB6263F6D07A9aFFa406f5);
	}

	// to be executed as a delegateCall on the GrowthDeFi/ApeSwap shared Gnosis multisig
	function runShared() external
	{
		// transfer governance to DAO
		bytes memory _data = abi.encodeWithSignature("setAuthorityAndDelay(address,address,address,uint256)", MCD_PAUSE, MCD_GOV_ACTIONS, MCD_ADM, 0);
		DSProxy(payable(PROXY_DEPLOYER)).execute(PROXY_PAUSE_ACTIONS, _data);
	}

	function adjustDuty() internal
	{
		uint256 _duty = 1000000004431822020478648483; // 15%/year
		bytes memory _data = abi.encodeWithSignature("dripAndFile(address,address,address,bytes32,bytes32,uint256)", MCD_PAUSE, MCD_GOV_ACTIONS, MCD_JUG, "STKAPEMORBUSD-A", "duty", _duty);
		DSProxy(payable(PROXY_DEPLOYER)).execute(PROXY_PAUSE_ACTIONS, _data);
	}

	function restoreState() internal
	{
		DSAuth(MCD_DEPLOY).setOwner(MCD_PAUSE_PROXY);
		DSAuth(CLIPPER_MOM).setOwner(MCD_PAUSE_PROXY);
	}

	function transferOwnership(address _newOwner) internal
	{
		DSAuth(MCD_ADM_TEMP).setOwner(_newOwner);
		DSAuth(PROXY_DEPLOYER).setOwner(_newOwner);
	}

	function renounceAuth() internal
	{
		address _this = address(this);
		DenyLike(MCD_VAT).deny(_this);
		DenyLike(MCD_SPOT).deny(_this);
		DenyLike(MCD_DAI).deny(_this);
		DenyLike(MCD_JOIN_DAI).deny(_this);
		DenyLike(MCD_JUG).deny(_this);
		DenyLike(MCD_POT).deny(_this);
		DenyLike(MCD_FLAP).deny(_this);
		DenyLike(MCD_FLOP).deny(_this);
		DenyLike(MCD_VOW).deny(_this);
		DenyLike(MCD_CAT).deny(_this);
		DenyLike(MCD_DOG).deny(_this);
		DenyLike(MCD_END).deny(_this);
		DenyLike(VAL_BUSD).deny(_this);
		DenyLike(VAL_USDC).deny(_this);
		DenyLike(VAL_BNB).deny(_this);
		DenyLike(VAL_ETH).deny(_this);
		DenyLike(VAL_BTCB).deny(_this);
		DenyLike(VAL_CAKE).deny(_this);
		DenyLike(VAL_BANANA).deny(_this);
		DenyLike(VAL_PCSBNBCAKE).deny(_this);
		DenyLike(VAL_PCSBNBBUSD).deny(_this);
		DenyLike(VAL_PCSBNBETH).deny(_this);
		DenyLike(VAL_PCSBNBBTCB).deny(_this);
		DenyLike(VAL_PCSBUSDUSDC).deny(_this);
		DenyLike(VAL_PCSBUSDBTCB).deny(_this);
		DenyLike(VAL_PCSBUSDCAKE).deny(_this);
		DenyLike(VAL_PCSETHBTCB).deny(_this);
		DenyLike(VAL_PCSETHUSDC).deny(_this);
		DenyLike(VAL_STKCAKE).deny(_this);
		DenyLike(VAL_STKBANANA).deny(_this);
		DenyLike(VAL_STKPCSBNBCAKE).deny(_this);
		DenyLike(VAL_STKPCSBNBBUSD).deny(_this);
		DenyLike(VAL_STKPCSBNBETH).deny(_this);
		DenyLike(VAL_STKPCSBNBBTCB).deny(_this);
		DenyLike(VAL_STKPCSBUSDUSDC).deny(_this);
		DenyLike(VAL_STKPCSBUSDBTCB).deny(_this);
		DenyLike(VAL_STKPCSBUSDCAKE).deny(_this);
		DenyLike(VAL_STKPCSETHBTCB).deny(_this);
		DenyLike(VAL_STKPCSETHUSDC).deny(_this);
		DenyLike(MCD_JOIN_STKCAKE_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKCAKE_A).deny(_this);
		DenyLike(MCD_JOIN_STKBANANA_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKBANANA_A).deny(_this);
		DenyLike(MCD_JOIN_STKPCSBNBCAKE_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKPCSBNBCAKE_A).deny(_this);
		DenyLike(MCD_JOIN_STKPCSBNBBUSD_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKPCSBNBBUSD_A).deny(_this);
		DenyLike(MCD_JOIN_STKPCSBNBETH_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKPCSBNBETH_A).deny(_this);
		DenyLike(MCD_JOIN_STKPCSBNBBTCB_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKPCSBNBBTCB_A).deny(_this);
		DenyLike(MCD_JOIN_STKPCSBUSDUSDC_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKPCSBUSDUSDC_A).deny(_this);
		DenyLike(MCD_JOIN_STKPCSBUSDBTCB_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKPCSBUSDBTCB_A).deny(_this);
		DenyLike(MCD_JOIN_STKPCSBUSDCAKE_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKPCSBUSDCAKE_A).deny(_this);
		DenyLike(MCD_JOIN_STKPCSETHBTCB_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKPCSETHBTCB_A).deny(_this);
		DenyLike(MCD_JOIN_STKPCSETHUSDC_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKPCSETHUSDC_A).deny(_this);
		DenyLike(ILK_REGISTRY).deny(_this);
		DenyLike(MCD_IAM_AUTO_LINE).deny(_this);
		DenyLike(MCD_FLASH).deny(_this);
		DenyLike(CHANGELOG).deny(_this);
		DenyLike(LERP_FAB).deny(_this);
		DenyLike(MCD_JOIN_PSM_BUSD_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_PSM_BUSD_A).deny(_this);
		DenyLike(MCD_PSM_BUSD_A).deny(_this);
		DenyLike(VAL_MOR).deny(_this);
		DenyLike(VAL_APEMORBUSD).deny(_this);
		DenyLike(VAL_STKAPEMORBUSD).deny(_this);
		DenyLike(MCD_JOIN_STKAPEMORBUSD_A).deny(_this);
		DenyLike(MCD_CLIP_CALC_STKAPEMORBUSD_A).deny(_this);
		DSRoles(MCD_ADM_TEMP).setRootUser(_this, false);
	}
}