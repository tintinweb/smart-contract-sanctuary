// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ChubbiAuction.sol";

/**
 * @title ChubbiAuction
 * ChubbiFren - The main contract,
 */
contract ChubbiFren is ChubbiAuction {
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ChubbiAuction(_name, _symbol, _proxyRegistryAddress, 8888) {
        setBaseTokenURI("https://www.chubbiverse.com/api/meta/1/");

        reservations[0x0eC5c1691219ffDfC50B6d4E3Bfb1B60b7eD8D5E] = 10;
        reservations[0x7788238091052072d5969Ac7452E46e94B23f7A3] = 5;
        reservations[0x593aB4f8412575d4B2EA36d373C04956A8Fbd3cD] = 5;
        reservations[0xFA6e1eFeD2FcE1337c6b2c0C0E7bFAa3927E6F23] = 5;
        reservations[0xCAe400e06B6D7d1632538C730223e9c06eE69f12] = 5;
        reservations[0x14929281cb3dC7F7E47C95a977C05ed4B85489d0] = 50;
        reservations[0x1Ce99932fD278E00911814dC4bd403e1293d8ED2] = 5;
        reservations[0x387Af9Df1a190CfAF420a0470A55f5cE22C5D356] = 5;
        reservations[0xc55ba66cab0298B3A67e1D0bf6A1613907941B09] = 10;
        reservations[0xea7cEB44004Ce65DEaD925e6Ae12fEdc30c88267] = 10;
        reservations[0x91609451B6a5775608787f3Da9501104935D3b25] = 15;
        reservations[0x60EA59C40efc5b297d3b019FA26c217761d0c266] = 5;
        reservations[0x926d2562Cd25E2a8988449F61271c19fF65d2C04] = 10;
        reservations[0x90E1F595Abc8D731cf82031c974aDD334B84b29E] = 20;
        reservations[0x7F7b32c998083D66De56602D75bC820b768C721B] = 5;
        reservations[0xd8Bca4f14B89d7BE3a5fd5AD97AAA6775D11FC46] = 5;
        reservations[0xA98220f6dC5DFcA27ff19605a0a6D3E1dDE4CFE8] = 5;
        reservations[0xEF30fA2138A725523451688279b11216B0505E98] = 15;
        reservations[0x5D89737E854c860d25E106C498c6DCA0B516eD7a] = 5;
        reservations[0xEC080DbeE8F60c8E6d7c3F52e10832718d2b8D5A] = 5;
        reservations[0x3cf0aCd510F51506D10f28ABb4822238C405Ac61] = 40; // 10 from snapsot, 30 from team
        reservations[0xe86dad56eE5C8F344cCaF348158C6258A965C8aA] = 5;
        reservations[0xF13a69F85075972AbB8435c8bBa1f24D91EFB986] = 10;
        reservations[0x277e1546A1Be3BC1737d0EAb43E6c1c86c0f4207] = 10;
        reservations[0x0bA516f6142C1cC8B6A6443bEf748e244FeaC99E] = 5;
        reservations[0x6Ec30Fd91A504Aad948839B985C7263888B2Ad68] = 15;
        reservations[0x64e714344780B12384597F5bF9aE35F9ADf98863] = 5;
        reservations[0x26A49F3730e2984E9188E220fC3fa4B6A605EA21] = 10;
        reservations[0x77C979931AD12d2B55e5E997a440f43660A21ffa] = 10;
        reservations[0x59b836B2f15C89E1007e011af47607e01C365F71] = 25;
        reservations[0xFe5573C66273313034F7fF6050c54b5402553716] = 5;
        reservations[0x2a92280f7572Ee27b50eb81D8Bd644a5aCcf16F6] = 5;
        reservations[0x3329ca36d37b0DE4228795eFaA490a7763202172] = 5;
        reservations[0xbBDFDE2786afD8858807bDf617C10F9ad521fAb1] = 5;
        reservations[0x5BA17875Ea5F3BAA8E9A06aaf973Ba7c21994C40] = 10;
        reservations[0xd918252c46bf5D399Ce827151B422810388c79ec] = 5;
        reservations[0xb09548d2ea367b0b0dF0FE1AC0C079F7D5354a50] = 5;
        reservations[0xde923Df474661dDF3727C913EbFEe3df0b37BEB8] = 5;
        reservations[0x6A3B82f775D9eFE19518b1F68Fe86FAf0eAf2a90] = 10;
        reservations[0x80207B6ef45dcD6E2d2f5Bf692320C8b46b6bf09] = 5;
        reservations[0x1a330bF19B7865935cd675fD827c6cbC742fFE5a] = 35; // 30 from snapshot, 5 from team
        reservations[0x044DeeAe38e81be36Fe1F0245F4cb14Be0A19Cb0] = 5;
        reservations[0x06644f3054d2579e8b7425436bB6ab13e91999EB] = 10;
        reservations[0x606a90DF26ED6b2680aF64fc63E2887a726703d4] = 10;
        reservations[0xe1b5F0862dc5A2A4e6069C3e31232a34d21Ef2Fb] = 5;
        reservations[0x6e51817Aa02674FE6bA1a790E23AA720c4843804] = 5;
        reservations[0xf305F90B19CF66fC2D038f92a26440B66cF858F6] = 5;
        reservations[0x5D55a50e4A1d7ce19B108aD4a44C60D02fAd9637] = 5;
        reservations[0xE7f2A881a30a1b9D16BebdbE42B226253B4Ca489] = 5;
        reservations[0x45A7A6adA84207c11a29305b18E4DBb16Bd1dd7E] = 5;
        reservations[0x75c8E2dd57927eB0373E8e201ebF582406aDcf45] = 15;
        reservations[0x923de254c1E93D710CCa6115b63712EDc76CE816] = 25;
        reservations[0x9cBd60A51b54aB626cDE7861Afe43D2CD82dA327] = 10; // 5 from snapshot, 5 from team
        reservations[0x1ff13480f8CD08e778755987a648b9D80d78c966] = 5;
        reservations[0xBe27D73FCf696ECf9Febff0C90F7Ac9e05B0E41A] = 25;
        reservations[0x94abB1573c83f9a53cAD661514Ed7F0419EC594A] = 5;
        reservations[0xb71B13b85D2c094B0FDeC64ab891b5BF5f110a8e] = 5;
        reservations[0x25CD302E37a69D70a6Ef645dAea5A7de38c66E2a] = 10;
        reservations[0x88cc77f53A077775bcD8067822Ed02Bd12AC4131] = 10;
        reservations[0x182Eba9213c3A45aEc4a400350EacD2E683f5981] = 5;
        reservations[0x3082a2dd0028231423a5fB470407a89c024B308d] = 5;
        reservations[0x642452Bd55591CD954B2987c70e7f2ccC71dE313] = 5;
        reservations[0xF404Aa7d1eAB3fABA127E57A1E4aFA4D6c31abF8] = 10;
        reservations[0x6f4d8C05aC656cbb2Edc9aDC14743C123A0EB65b] = 10; // 5 from snapshot, 5 from team
        reservations[0x108B9595D1fA09A9a228e011D7768c55D8d989AD] = 5;
        reservations[0x1d69d3CDEbB5c3E2B8b73cC4D49Aa145ecb7950F] = 5;
        reservations[0x3677C1621D49611811BBca58d9b2ac753bE5b3b6] = 5;
        reservations[0x868b2BC9416bBd2E110ad99e4F55C1D51212271a] = 5;
        reservations[0x7FdCA0A469Ea8b50b92322aFc0215b67D56A5e9A] = 5;
        reservations[0x52e0f7339C1BEd710DBD4D84E78F791eBe2df6b9] = 10;
        reservations[0x3df6c1D54ad103233B3c74a12042f67239d69f70] = 45; // 15 from snapshot, 30 from team
        reservations[0xA4c8d9e4Ec5f2831701A81389465498B83f9457d] = 5;
        reservations[0x8DD6629B2272b4fb384c13E982f8e08Bc8EE001E] = 5;
        reservations[0x758f9112899834dB1d5dC1860c06900c3d3bd75a] = 10;
        reservations[0xDCbf721551A937768537458C61005F1CBECb043c] = 5;
        reservations[0x5Cb58a3fA9B02ae11f443b3Adc231172356EcCd7] = 5;
        reservations[0x774237c2a8Fd84c0D4D2C97cB03D3B6C87cB0431] = 5;
        reservations[0x60d727CBfd8Df0af32eFa764ebEc917c59FcEd4F] = 15;
        reservations[0xa11e95CA2bE0793C5AD0C4FF20bd6dab0992C6a2] = 5;
        reservations[0x0bd43F463074e731718f970C35b3fa7c8184c642] = 5;
        reservations[0x68EAbf8B000AbfF6d55Cfa918D2fe0638d4F98af] = 5;
        reservations[0xc6E999FCCF8bc1CD8BEfcfA10Cf2cC1f3b2612e2] = 5;
        reservations[0x3c2B4bDCD2F742C55186fc599Cb733a127E2b8ab] = 5;
        reservations[0x3Ba77787266aE8225805e4b4750fd4E9f800da33] = 20;
        reservations[0xCfCDd074DC974af94fA2b9d56b6A213c0D96EaF9] = 5;
        reservations[0xB135c7E7604A8D4723548d9a5F67D98c110E78A8] = 5;
        reservations[0xBE1e5A07c3Af9b648b2DeC7F193bc0835646725E] = 5;
        reservations[0xc7bc4Aa98eCe00E4F8feC8Fe7B0591F80aBbc855] = 5;
        reservations[0x42d3b1e30f39191F6dA2701E31cfc82574ea14D5] = 5;
        reservations[0x7f55Bd494bed4b4eED2064ECCC1aF75e9d76aD4b] = 5;
        reservations[0x5765bdEFb7EAD33f4Eb7935C5d5eb130f4299568] = 5;
        reservations[0x0c5A9cd5c97F716e2E9F3699Bd2905BCA0059867] = 10;
        reservations[0x5338035c008EA8c4b850052bc8Dad6A33dc2206c] = 15;
        reservations[0x518aE9dC06AF3A4d2DD1B75E2367C0D23257B320] = 8; // 5 from snapshot, 3 from team
        reservations[0xd102C5AD3c42bdFBB1762DB4d0e3707ffB7e1486] = 10;
        reservations[0x8067ea0006949CFF984083A83A56a8B0DEC2eab2] = 5;
        reservations[0x0f1025f754b3eb32ab3105127b563084BFa03A6F] = 10;
        reservations[0xbD912A2B4Aeb0BC7D3827d11D621F79D66eaF633] = 5;
        reservations[0x2d45D1259B4f136F5050CB9dbb3c02253f74c647] = 5;
        reservations[0xa2BFF706Dd94C8E8284314aAf243D8D99cf723DA] = 5;
        reservations[0x1D551AcE62be491Fc49E9A6B3d737e51e2c59E8c] = 5;
        reservations[0x5bEcE23dDf9BDe3e1F735b1b09b5958173D45014] = 10;
        reservations[0x243AE63fed8680067e16F63546d312AAC1f5d716] = 5;
        reservations[0x7CcaCab19ee2B7EC643Ef2d436c235A5c1E76Fa9] = 5;
        reservations[0xDDCCC8CBF91f31FF7639b4E458cF518219eFC7bd] = 5;
        reservations[0xFac137e6753B1C7b210cd1167F221B61D6Eb4638] = 10;
        reservations[0x45e2Aa1483A1C02f1E7D07FF904bb1dEd9350aB7] = 5;
        reservations[0x3b10f088D7a83E92E91D4A84FE2c656AF92a801D] = 5;
        reservations[0xA6D3a33a1C66083859765b9D6E407D095a908193] = 10;
        reservations[0xaf9E021FC76c0aFBf4a520152C5Cf792561503B5] = 5;
        reservations[0xd1B18dD9fCfd0cfaED13D0a107B98B47d3f67eF6] = 5;
        reservations[0x6514304C439565BC6bF5e60dC69dC355a034E6C3] = 5;
        reservations[0xA0Acc2aE14c814d97c766aE2582150c415cef1e6] = 5;
        reservations[0xA309e257Db5C325e4B83510fCc950449447E6BdA] = 5;
        reservations[0xa48AE1c287fa6DE4581Ca3E00f0a481a1AE80778] = 5;
        reservations[0xBaEa3Cf94aBd0D6E0F029ef5B0E54E9424A72985] = 10;
        reservations[0x716eb921F3B346d2C5749B5380dC740d359055D7] = 10;
        reservations[0x4c6FaaAf155AA05A0AF39Dd51ee9E47042d19C64] = 10;
        reservations[0x50F620A98f0514F5cA9ff7B44125F632EE7aC84a] = 5;
        reservations[0x81a4A0655A157B731D06fE0b597F67B5bDDdedf3] = 5;
        reservations[0xfCAD3475520fb54Fc95305A6549A79170DA8B7C0] = 5;
        reservations[0xD5b1BF6c5BA8416D699e016BB99646cA5DbAb8d7] = 5;
        reservations[0x7c7582643E67b443b0c3f82D0513ba3D25c09F92] = 5;
        reservations[0xcDae1Bab521E6aD0756f41166E1Ac68D4b5Ba55a] = 20;
        reservations[0x7D551B4Aa5938d18be5C5e9FdE7fECE9566611ba] = 10;
        reservations[0x6a8b990801daDe9077acB0eA8948D023C72D7060] = 5;
        reservations[0x0F0eAE91990140C560D4156DB4f00c854Dc8F09E] = 10;
        reservations[0x409abF69Bcf740a1cEe04f3f330610fd985BE0c3] = 5;
        reservations[0xb20f6f5F6D624571C000d75bb8081b488f1D9c9a] = 5;
        reservations[0xb51fBfdAc76132eB819c91b0Bfc5A72913B88329] = 5;
        reservations[0x392FA612154CCaDd6b3B34048D4De84A4E2e0d8f] = 5;
        reservations[0xab0e3fE8670583591810689b0a490D8226f0D79B] = 10;
        reservations[0x078ad2Aa3B4527e4996D087906B2a3DA51BbA122] = 10;
        reservations[0x34f6e236880D962726Fdb5996f6a0Bce42ea6Ca5] = 5;
        reservations[0x9874346057faA8C5638694e1c1959f1d4bb48149] = 5;
        reservations[0x000433708645EaaD9f65687CDbe4033d92f6A6d2] = 5;
        reservations[0xE85b14f37ed20f775BEeBf90e657d8A050640623] = 5;
        reservations[0x8104cd18e37f2634257a97338C32EC7BFbfb72bD] = 5;
        reservations[0x97C6f53B75D8243a7CBC1c3bc491c993842db3b3] = 5;
        reservations[0x750A31fA07184CAf87b6Cce251d2F0D7928BADde] = 5;
        reservations[0xfa50E8AE8E380fAd984850F9f2BA7Eb424502d6d] = 5;
        reservations[0x9631b82269c02a7616d990C0bf9Ba1dC1Bed1a73] = 5;
        reservations[0xD8CbcFFe51B0364C50d6a0Ac947A61e3118d10D6] = 5;
        reservations[0x1048fA01899a43821c7aE77Fe96aF45F19A2646B] = 5;
        reservations[0x9Cb737840CF5538942d1dA5576B50A7005382F13] = 5;
        reservations[0x96fc154e9f97541e0b9e76fdd162a8Ecd2F2eD7B] = 5;
        reservations[0xE54c447e47DC308Ff12C478E725C150e1586FfB0] = 10; // 5 from snapshot, 5 from team
        reservations[0x5101F854F670812f2eBca8f6669AfF324F192218] = 5;
        reservations[0xc2363b54f8842a4Da3Cd19D6F3b6F9988c72800D] = 5;
        reservations[0x64c420ABc818E9FCa4a94FF1aD78c5B7E237e44B] = 5;
        reservations[0x2f6e116E6E4BfF7c00402d6B321192BCc4d797FA] = 5;
        reservations[0x95B0D143ac845877DFdb7cE07Fc1549D88783d68] = 5;
        reservations[0x19Eb7FfDcD670Ca917110Bd032463120a5E58C8E] = 5;
        reservations[0x83E84CC194E595B43dCEDfBFfC3e0358366307f1] = 5;
        reservations[0x3916bcCF534a200467D546414Bf93A2BF47DD7CD] = 5;
        reservations[0xa920268fF7Ac82a63fF5070d32401900Ee5626C6] = 5;
        reservations[0xE62c522b0EeA657414faD0a1893223f54CCD5190] = 5;
        reservations[0xAE68B4Ec732c534F5d3D0B990af2E3FB7E25FbE3] = 5;
        reservations[0x8945911b7bd08a9fE75EdCFb94f1a8A4A741b443] = 10;
        reservations[0x88451FDbdb2d002008136D3626aafdA5e85d4dae] = 5;
        reservations[0x52713267FE99E268A3Ce0B1A84C3d3dbC7C47F21] = 5;
        reservations[0x6D938CbE86b4763691f702577d4046F656aCb3c8] = 5;
        reservations[0x6051BE619c976Bf24ff6053693f696C691cfCd24] = 5;
        reservations[0x98367D7B9bC02A5207859Ac11F2a9E504cA729E4] = 5;
        reservations[0xb7608C42C00c87Be4Db7A6D2AF128fd6f0FD74c8] = 5;
        reservations[0x99999990D598B918799f38163204Bbc30611B6b6] = 5;
        reservations[0x905f48CbAAAF881Dbee913cE040c3b26d3bbc6D9] = 5;
        reservations[0x020B899981FA12ad33d6c455d77fe8f53A121464] = 5;
        reservations[0x5c0E408F03709B89b7F5Fa91E4172425F57C75d2] = 5;
        reservations[0x51EDb6E986c31D13838f165737Fe3FbA9F689F38] = 300;
        reservations[0xd6b5E55dd4BEBe68D556EaB12C9916bD4a420406] = 30;
        reservations[0xd148C895462160a260318A7046f78a29F97F8235] = 30;
        reservations[0x7156403C0A30d458Bb4b4796e4412E6A22624b30] = 10;
        reservations[0x13E47EBD58dA3a23ed19d91067168896e6c683F1] = 10;
        reservations[0xC0f1C68f16363974FCaCE9f25DC76a18B5077a9A] = 5;
        reservations[0x749C34697bA3ECbbD80C0BD831F513DFD9E2D5a4] = 2;
        reservations[0xF61AC83177e310e82374f90D5dd00f62FDeA2FBD] = 1;
        reservations[0x1fC18f965F60625f895434FC536Fa50c705F860c] = 1;
        reservations[0x9191588a8F3fa3ffF4f7e4D1ca51034d664850FE] = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ChubbiReserve.sol";

/**
 * @title ChubbiAuction
 * ChubbiAuction - A contract that enables tokens to be distributed using a Dutch Auction.
 */
contract ChubbiAuction is ChubbiReserve {
    using SafeMath for uint256;

    bool internal _isAuctionActive;

    // Events
    event BidSuccessful(
        address indexed owner,
        uint256 amountOfTokens,
        uint256 totalPrice
    );

    // Auction parameters
    uint256 public startTime;
    uint256 public maxPrice;
    uint256 public minPrice;

    // The amount of time after price will decrease next.
    uint256 public constant timeDelta = 10 minutes;

    // The amount of eth to decrease price by every `timeDelta`
    uint256 public constant priceDelta = 0.05 ether;

    // The maximum amount of tokens per bid
    uint256 public maxTokensPerBid;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        uint256 _maxSupply
    ) ChubbiReserve(_name, _symbol, _proxyRegistryAddress, _maxSupply) {
        _isAuctionActive = false;
        maxTokensPerBid = 20;
        maxPrice = 0.69 ether;
        minPrice = 0.09 ether;
    }

    /**
     * @dev Set the parameters for the auction.
     * @param _maxPrice the maximum price of a token in the auction.
     * @param _minPrice the minimum price of a token in the auction.
     */
    function setAuctionParameters(uint256 _maxPrice, uint256 _minPrice)
        external
        onlyOwner
    {
        require(!_isAuctionActive, "Auction is active");
        require(_maxPrice > _minPrice, "Invalid max price");
        require(_minPrice > 0, "Invalid min price");
        maxPrice = _maxPrice;
        minPrice = _minPrice;
    }

    /**
     * @dev Set the maximum number of tokens a user is allowed to bid for in total throughout the whole auction.
     */
    function setMaxTokensPerBid(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        maxTokensPerBid = _amount;
    }

    // Start & Pause

    function startAuction() external onlyOwner whenNotPaused {
        require(!_isAuctionActive, "Auction is active");
        startTime = block.timestamp;
        _isAuctionActive = true;
        stopReservations();
    }

    function pauseAuction() external onlyOwner {
        require(_isAuctionActive, "Auction is not active");
        _isAuctionActive = false;
    }

    // Bidding

    /**
     * @dev Get the maximum amount of tokens that can be auctioned.
     */
    function maxAuctionSupply() public view returns (uint256) {
        return maxSupply - claimed;
    }

    /**
     * @dev Get the amount of tokens that have been auctioned.
     */
    function tokensAuctioned() public view returns (uint256) {
        return currentSupply() - claimed;
    }

    /**
     * @dev Check is the auction is currently active.
     */
    function isAuctionActive() external view returns (bool) {
        return _isAuctionActive && tokensAuctioned() < maxAuctionSupply();
    }

    /**
     * @dev Bid for tokens.
     * @param _tokenAmount the amount of tokens to bid.
     */
    function bid(uint256 _tokenAmount) external payable whenNotPaused {
        require(_isAuctionActive, "Auction is not active");
        require(tokensAuctioned() < maxAuctionSupply(), "Auction completed");
        require(_tokenAmount <= maxTokensPerBid, "Bid limit exceeded");

        // Ensure that user can always buy the tokens closer to the end of the auction
        uint256 tokensRemaining = maxAuctionSupply().sub(tokensAuctioned());
        uint256 amountToBuy = Math.min(_tokenAmount, tokensRemaining);
        assert(amountToBuy <= tokensRemaining);

        // Ensure user can afford the tokens
        uint256 totalPrice = getCurrentPrice().mul(amountToBuy);
        require(totalPrice <= msg.value, "Not enough ETH");

        // Give them the tokens!
        for (uint256 i = 0; i < amountToBuy; i++) {
            _mintTo(msg.sender);
        }

        // Let the world know!
        emit BidSuccessful(msg.sender, amountToBuy, totalPrice);

        // Return the change
        uint256 change = msg.value.sub(totalPrice);
        payable(msg.sender).transfer(change);
    }

    /**
     * @dev Get the current price of a token.
     */
    function getCurrentPrice() public view returns (uint256) {
        if (!_isAuctionActive) {
            return maxPrice;
        }
        return _getCurrentPrice(startTime, block.timestamp, maxPrice, minPrice);
    }

    /**
     * @dev Get the current price of a token.
     * We make this virtual so we can override it in tests.
     * @param _startTime the starting timestamp.
     * @param _currentTime the current timestamp.
     * @param _maxPrice the maximum price of the token.
     * @param _minPrice the minimum price of the token.
     */
    function _getCurrentPrice(
        uint256 _startTime,
        uint256 _currentTime,
        uint256 _maxPrice,
        uint256 _minPrice
    ) internal view virtual returns (uint256) {
        require(_maxPrice > _minPrice, "Invalid max price");
        if (_currentTime < _startTime) {
            return _maxPrice;
        }
        // Drop by 0.05 eth every 10 minutes
        uint256 priceDiff = _currentTime.sub(_startTime).div(timeDelta).mul(
            priceDelta
        );
        priceDiff = Math.min(priceDiff, _maxPrice);
        return Math.max(_minPrice, _maxPrice.sub(priceDiff));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ChubbiBase.sol";

/**
 * @title ChubbiReserve
 * ChubbiReserve - A contract that allows token reservations and claiming.
 */
contract ChubbiReserve is ChubbiBase {
    using SafeMath for uint256;

    // Events
    event Claimed(address indexed owner, uint256 amount);

    uint256 public claimed;

    // A mapping from addresses to the amount of allocations
    mapping(address => uint256) internal reservations;

    bool internal _isClaimingActive;
    bool private isReserveActive;

    uint256 public maxTokensPerClaim;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        uint256 _maxSupply
    ) ChubbiBase(_name, _symbol, _proxyRegistryAddress, _maxSupply) {
        _isClaimingActive = false;
        isReserveActive = true;
        maxTokensPerClaim = 50;
    }

    /**
     * @dev Get the reservations for a given address.
     * @param _for address of the owner of the tokens.
     */
    function getReservations(address _for) external view returns (uint256) {
        return isReserveActive ? reservations[_for] : 0;
    }

    /**
     * @dev Check if claiming is active.
     */
    function isClaimingActive() external view returns (bool) {
        return _isClaimingActive && isReserveActive;
    }

    function setMaxTokensPerClaim(uint256 _amount) external onlyOwner {
        maxTokensPerClaim = _amount;
    }

    /**
     * @dev Claim all reserved tokens.
     */
    function claim() external whenNotPaused {
        require(_isClaimingActive, "Claiming is not active");
        require(isReserveActive, "Reserve is not active");
        require(reservations[msg.sender] > 0, "No tokens to claim");

        uint256 numberOfTokens = reservations[msg.sender];
        uint256 numberToClaim = Math.min(numberOfTokens, maxTokensPerClaim);
        reservations[msg.sender] = numberOfTokens.sub(numberToClaim);
        claimed = claimed.add(numberToClaim);

        for (uint256 i = 0; i < numberToClaim; i++) {
            _mintTo(msg.sender);
        }

        emit Claimed(msg.sender, numberToClaim);
    }

    // Pause and unpause

    function pauseClaiming() external onlyOwner {
        require(_isClaimingActive, "Claiming is already paused");
        _isClaimingActive = false;
    }

    function unpauseClaiming() external onlyOwner {
        require(!_isClaimingActive, "Claiming is active");
        _isClaimingActive = true;
    }

    /**
     * @dev Stop all reservations permanently
     */
    function stopReservations() public onlyOwner whenNotPaused {
        _isClaimingActive = false;
        isReserveActive = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./opensea/ERC721Tradable.sol";

contract ChubbiBase is ERC721Tradable {
    uint256 public maxSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        uint256 _maxSupply
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        require(_maxSupply > 0, "Max supply must be set");
        maxSupply = _maxSupply;
    }

    // Override mint so that we cannot go over the maximum supply
    function _mint(address _to, uint256 _tokenId) internal override {
        // Ensure tokenId is in range [1, maxSupply]
        require(_tokenId > 0 && _tokenId <= maxSupply, "Invalid token id");
        super._mint(_to, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is
    ERC721Enumerable,
    Ownable,
    Pausable,
    ContextMixin,
    NativeMetaTransaction
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address internal proxyRegistryAddress;
    string public baseTokenURI;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    function setBaseTokenURI(string memory newBaseTokenURI) public onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Get the amount of tokens that have been minted.
     * NOTE: This is different from totalSupply() as this won't decrease the supply count on token burn.
     */
    function currentSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function _mintTo(address _to) internal virtual {
        _tokenIdCounter.increment();
        _safeMint(_to, _tokenIdCounter.current());
    }

    /**
     * Money functions
     */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Pausable
     */

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}