// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./libraries/TransferHelper.sol";
contract NGReservations {
    INGNFT private _nft;

    bool private _canReserve;
    mapping (address => bool) private _admins;

    address[] private _allAllocated;
    mapping (address => uint) private _reservations;
    mapping (address => uint) private _allocations;

    uint256 public _pricePerAllocation;

    modifier onlyAdmin() {
        require(_admins[msg.sender], "No admin.");
        _;
    }

    constructor(uint256 pricePer) {
        _admins[msg.sender] = true;

        _pricePerAllocation = pricePer;

        seedAllocations();
    }

    function seedAllocations() private {
        _addAllocation(0xF8D371421790d718B0Fb37F2D3e26d4bD4BB30CE, 15);
        _addAllocation(0x3D2F37e5fE0114F5F34549Bc0CE7A93C0A1b9AC2, 15);
        _addAllocation(0xD62B1C3E8B1265383520eD4f996Aa7B367C48EaC, 1);
        _addAllocation(0xDb63821949F870a36b321876AD9c69a482D582C5, 1);
        _addAllocation(0xD62B1C3E8B1265383520eD4f996Aa7B367C48EaC, 1);
        _addAllocation(0xa862eB147C8a23FeFC4601dF14947023db43d806, 0);
        _addAllocation(0xA29afF2132102492CCE1B52002638295B15FE099, 10);
        _addAllocation(0xFa32310C344203acAf39bA559dE809f5881D152b, 0);
        _addAllocation(0xF93c620132A67E2DC62D72b02cb6aBf7f44697d2, 0);
        _addAllocation(0x30F8b9F0D81A0fD5d26937379C648c8AE8986A35, 5);
        _addAllocation(0xf975D2e393761dCEE8AaB1116FbDfAD405f7cabB, 1);
        _addAllocation(0x003f4CcaDd6E5f05345321115f658BfefAFe9198, 5);
        _addAllocation(0x890C6539b368518FE14a4Ba50219266f0aB715C5, 5);
        _addAllocation(0x4446c3394aD8cfD83ea9CF7B42BF177F218B518E, 0);
        _addAllocation(0x6b4D8F3e385eF39b08859b8c50b31093c5387884, 5);
        _addAllocation(0x7A2bcC3F8BB28390b7fb2f7A5575cb09a89be5c1, 10);
        _addAllocation(0xBcBe9b878543b9d4098497C67f1E95BC44A0B34C, 15);
        _addAllocation(0x3CbdE5f149afb83DB3A24a62Ef940ADBB53A62c4, 0);
        _addAllocation(0xdfF67Cd3C019eeA1787f8c5B83d73b98270CE9e7, 3);
        _addAllocation(0xF7DD364c5ce505a48A32D0AF2AA62251174d403A, 1);
        _addAllocation(0x560F43cCB42E4fc31c505EDd998a443DcfE44789, 5);
        _addAllocation(0x558BC05E6aaCAC3Dda96C43FcD242a11AFd3865C, 0);
        _addAllocation(0x4B5b63D09D3Fa8b5Ee56125Ee0992897b27c98fe, 15);
        _addAllocation(0x767b2DD92e616CA0473250Ecb78AB2651d9862A7, 3);
        _addAllocation(0x76356274276CC917c3C5fA16D3FAbD4c5B498fCa, 10);
        _addAllocation(0xAc10d0F5Dd56dafcbD854229245aEBEd3d6d4587, 15);
        _addAllocation(0x76227CE8b0DF14254398BFB85B8819E8Bf22f08d, 10);
        _addAllocation(0xd71f6f92720D3b0291Fd0775a18A84DD9270a4d1, 0);
        _addAllocation(0xf4aEC459a622CF565De6a5446625E6a7A4f4C490, 0);
        _addAllocation(0x0806372B4088cbab4D869A2A182E6FfE56de5690, 5);
        _addAllocation(0x3251a5f525d3475fa509A081230AaeC52A518e8D, 1);
        _addAllocation(0x0cE5c9504D966dB0656EcFbB29d01178f094548F, 1);
        _addAllocation(0x8DF6a2DadfaC1009442430CA40F8479d206f7673, 0);
        _addAllocation(0x7d17b418665F65247F8F477a0B73A0C3504fa99F, 0);
        _addAllocation(0x7060c5D6C6E25A4c1d7fEDC8D7DCA1d6524546eB, 0);
        _addAllocation(0x7FACd18a9925f9E3405d190a9557b87a31C01c70, 5);
        _addAllocation(0x99506dBAf215c9CBa97E1219845c6a59B58c5C3a, 5);
        _addAllocation(0x10afaa4Ddc7Ca47C193EF68f6c9b1373Dd2A2053, 3);
        _addAllocation(0x88d13f2B1DdA2358c17426781AfFE45Dc33484e7, 1);
        _addAllocation(0x70cFEc09F9dFef2d0093f16f73E17B4066f0d3B9, 0);
        _addAllocation(0x943fbbC1F2D8806966482cE5D93623C4FF1Aca76, 15);
        _addAllocation(0x56868e255834782581677b195eb79573fE62fd87, 10);
        _addAllocation(0x516263A5b78E843992B70F8aa0fA25938e371Af5, 5);
        _addAllocation(0xb436141073EFE6C21aC6BE9A5Bb0D1D74F0ce87C, 0);
        _addAllocation(0xef2105779858794A9919C615bd2E018414e71d26, 0);
        _addAllocation(0xc6001C424D7fB4F02fF33eC351BD9E8CB313990E, 5);
        _addAllocation(0x82bAd0f6508d5453735f9A0ddB2421F7b8BD4618, 5);
        _addAllocation(0x57fc571B8683B73a7eAE96Be64Ee9F205fb8a0E8, 10);
        _addAllocation(0xB6f9856E780Df21A2aDEd4EA8CF8551aD0CDf582, 10);
        _addAllocation(0xECb5926b3E4f5d9abe137deb6c07Fc71E5aA2F3c, 0);
        _addAllocation(0x0c93f4ff1BBae2f385C2e32bDa432f4fc57b82c1, 10);
        _addAllocation(0xB4B1F87A6C2C95726ca3aaF9E3a06142D78E3Ac4, 5);
        _addAllocation(0xa16258c7A06Fda9a727B16d1E32Cac912C7E35C8, 0);
        _addAllocation(0x418cD222c36ec82787A436116d562Db728641c07, 0);
        _addAllocation(0xc1Fd322e66C2Be977AfE17b548BB0d2C6fC42d93, 0);
        _addAllocation(0x0FcA1f016115791212919A67A3d611f13299eDB9, 5);
        _addAllocation(0xffEf3BE05ce9964769d56f50A79D98F882BcfD67, 3);
        _addAllocation(0xbcc6BFb94a8A78637626599512871715E3044755, 0);
        _addAllocation(0xE4E6fe3d54863cda33e0ad5319E4EC6Bc0A61269, 10);
        _addAllocation(0x8A9816193E1C84eC67Db92324d7084192bf9d711, 15);
        _addAllocation(0xa055eda6fA138a1ee3603319661f8E719827f70F, 5);
        _addAllocation(0xe03785C1308C8934d9C016426c4887aA223C3fB5, 5);
        _addAllocation(0xAA11FE3675F1C80395D1d02382cA859251536230, 1);
        _addAllocation(0xDB3700928DF4124F2F9bCC7A2630570dB0EF30Cf, 0);
        _addAllocation(0x2e680bc0Bf3e0CE0c2605a20a60737458E5a63D6, 5);
        _addAllocation(0x3428b5731Cc5142cB63A60A8D10D74a6AFe736A8, 1);
        _addAllocation(0xdA73A08437D99bF3CB847b70B883752d3517F03a, 1);
        _addAllocation(0xee85BB8490c67Bb3C469B4F45bA8F3b90d7d3FAc, 1);
        _addAllocation(0x26655f85f0F3dfaB53ac5C48F35c75bF13e48700, 3);
        _addAllocation(0x8d88357eAeF9ece7bDc478E69D6a489DBb7F2B84, 0);
        _addAllocation(0x2D9446aEd152F935106F982B72D4E26b75Ac692f, 5);
        _addAllocation(0xD5D916F80efBEFeA48Ac66e2622bbB25C5Cd1676, 10);
        _addAllocation(0x3732b2CEf248E06e79F8FeA69cEC97730d55dCa7, 1);
        _addAllocation(0x5a3815A38Ae2E1E30Aed006bcd7807c47a04e63e, 1);
        _addAllocation(0xEDBB91ce250E2bA016cAC7c5Df5d9ADD355296bc, 10);
        _addAllocation(0x0DDdd212050bDE4536270C6f239F1e2e74340CE8, 5);
        _addAllocation(0xF6B3415E8698BFBB31Fd59Cf8E941940F3dfa3C2, 1);
        _addAllocation(0xAe3D882268C982CA925bf01a31E64CCaF432A613, 0);
        _addAllocation(0x661fDff5fAd150764D44cB3361b8000258D9B39B, 10);
        _addAllocation(0xd5A06AC60905636f8c66f8EA1c662a1bfa2AF9D1, 5);
        _addAllocation(0x1358c385c347dDBD01E12F1D6dB5ee58Bb8F3119, 3);
        _addAllocation(0x47e2fDe9d4A4693C1af8C96dE6F8B32E1f9aEc91, 3);
        _addAllocation(0x291853e94Ad837Abc3fd0435F3b2ddA18a20F8C7, 15);
        _addAllocation(0x793650e3a4e74c17618deaad211F4ef151fD332e, 1);
        _addAllocation(0xDf1A60b1ceB9d6E4BD8Dc17D212F6C28f8BC2D37, 1);
        _addAllocation(0x106F4E7D2D1922Fe5542A2d182143c48A0e5d43c, 10);
        _addAllocation(0x65b35Daa359e28d5708a1B5Cfba614999409E9a5, 10);
        _addAllocation(0x9610C14C86C20ac8FA4D5306Aa93AE5E4E0abDdF, 1);
        _addAllocation(0x4A0E36022845C52467d955D8645ceD7997027a20, 5);
        _addAllocation(0x38D1a7e8E0ECD80d4248C047971780F62bef6A85, 10);
        _addAllocation(0x3B6416084088678f3ca4A3a2Af94adC6fA0638A3, 5);
        _addAllocation(0xDAb2c15bF9dcF12734B8FF9396ed70EFD3F947a0, 0);
        _addAllocation(0xB33A01AA6022A624DE8a8dEc20ad63fE429A7cB1, 10);
        _addAllocation(0x27eE8FA6a70a8F156008EDe28C7B8ea5F72fFdF3, 5);
        _addAllocation(0xf81a835982290400c713a470756428790C9813B4, 0);
        _addAllocation(0x41009b7eaCD96B01687EC633962256ED1C433229, 0);
        _addAllocation(0x58FC0b0e64c207A01ABb887179753347Cbb1a322, 0);
        _addAllocation(0xec2018321913a1AF4834D21790A18a87fDaa643C, 15);
        _addAllocation(0xc819940eA40111CDa4c439c7e92c2114d9117043, 0);
        _addAllocation(0x95ACd613e8979C2c246EB4b2C19CF00ce7bbD91D, 0);
        _addAllocation(0x67e156Fc2C8A69A5a0fdcda9ab3342607b948A48, 0);
        _addAllocation(0xf230Fb070f6D47754cB25B16f1eC3A4B2E82a580, 1);
        _addAllocation(0xA3A0508cBC1dAA43345E4Ff02107764443eD26ad, 0);
        _addAllocation(0x55d49b3B75bA19Ae9138C4e2Dc6D81325eD28637, 0);
        _addAllocation(0xeaD2BF7FB860CD8e35ce09a31324CfC97e1708DD, 0);
        _addAllocation(0x82d3d1108ACff667B28b58Baf3def4aB50709E40, 1);
        _addAllocation(0x3fFFd320ea6768De35842bd54180A65b1740c0C6, 5);
        _addAllocation(0x1201eC786586788c0F69B00B598DE9699123381A, 0);
        _addAllocation(0x684604847CcbE6d2bEdf87e44515c4cD64C0B8C4, 0);
        _addAllocation(0x35b5EC20a27754721C303417e806BdF32d9f0c6A, 0);
        _addAllocation(0xE1Bffd083348fD3c60CB11D8B112315E1eec8b96, 0);
        _addAllocation(0xdad5b3eCf8a189Db087773c512a64506F019541E, 0);
        _addAllocation(0xc0cEae55e2Ba88174fdac5fe4EE6F6B95DE0fDf9, 0);
        _addAllocation(0x6e44c0efeCA886b546bc2aa85118094b83B87297, 0);
        _addAllocation(0x8873883F4f93e5B9Fd6403e1f3438B193b694465, 0);
        _addAllocation(0x824737F53826c23C0Ac00f79C4Fb785b6AFbba01, 0);
        _addAllocation(0x1c47f98a00c724b9d94A045E083d9d43dDcf1632, 0);
        _addAllocation(0xca17e37f80e9ca278CEfb38752dD35f206a08fB7, 0);
        _addAllocation(0x9AC4CE946Ae5b5f28eDcB856E678a63206fe92E3, 0);
        _addAllocation(0x8e5c4cC109F2a88783f02C64cA355cEB4306B5df, 0);
        _addAllocation(0x058959a972b90aFB5ce7d820303117d154bDdFEf, 0);
        _addAllocation(0x1f04cBFA47271D1d8Fb6fDBDcC56ddda29414a6D, 0);
        _addAllocation(0x83B82618C305292011899F140d9B0195f48ce989, 1);
        _addAllocation(0x8d94F501EacaA42f96d896378e5545EFD9b58c8b, 0);
        _addAllocation(0xDAb908D61106DE983C7Fa1C1C243cF12bd18Bc5e, 0);
        _addAllocation(0x7DF39F23EFEc86607B3E732de49932EaF77Ee135, 1);
        _addAllocation(0x5A584b6c242d921A464Afa9ae0D25d7cb8D510f5, 1);
        _addAllocation(0x94eF50aFAc9c04572813F36Fb8D676EB400de278, 0);
        _addAllocation(0xBdc4791ad078b104DCEa4e597f21Fbb5F713c181, 0);
        _addAllocation(0x85c2519eE47C7fe84c7CaF1F5bdd0adF05Ca63fe, 1);
        _addAllocation(0x53Ae707382d1231a4414aD1e982d775842f6A934, 0);
        _addAllocation(0xb5909905fC5aA86813Ff5AeAaEA3B9952beE55d0, 3);
        _addAllocation(0xD9Cb9cDeA420e7B241F8D0998F0f883aD54391d9, 0);
        _addAllocation(0xa24BaeC4a3DB9DdA0A11AC0d2c07186e80e5a18F, 0);
        _addAllocation(0xd4BfF8AD1B5c630Ce2FE510F0182cc7EA0D14d0F, 0);
        _addAllocation(0xD21872Daf984C74024Fa823Abdad9928EDc1995a, 0);
        _addAllocation(0xf6eD7a1049885Ac53bA6196226B7115cc792aC90, 5);
        _addAllocation(0x9B4aF49C1846F3dD0f70730AE90aa0F93Cc0266e, 1);
        _addAllocation(0xf052a7b1EaA89165a1b82B6CA7506628113A0D19, 0);
        _addAllocation(0xcc7922350481C670cE192E71E588cE5EEBC4CaD9, 0);
        _addAllocation(0x85086AF2e6Fd33656E7Dd6d65FebD8ab35b49B71, 0);
        _addAllocation(0x3fA34577df6ed9c62Fa215E66CF88Bb22f508646, 0);
        _addAllocation(0x280724cBd41c0940CE4b40e82b4DAF3CCe1ea325, 0);
        _addAllocation(0x4b70C2b8D9984CEcA9541a7B915b60Bed61278DB, 0);
        _addAllocation(0xD4014233DCA7690CB78144Ed43cf52CF0301fF4A, 0);
        _addAllocation(0xbdCBAB7d33563378215E4972B4aE0D87DB942Cd4, 0);
        _addAllocation(0x556af34F7b633e9eFA4D0CB79e632da710b5493e, 0);
        _addAllocation(0x1e1a720A88805e47158C6B2dac3BB808a081B6af, 0);
        _addAllocation(0x545885cfaF1696601cDD715187bAA2721A1a98CA, 0);
        _addAllocation(0x7ABaFF47770CE9A36BE848d3E0968eeBE887A9Cf, 0);
        _addAllocation(0xc090A68c2468dCBa155D593C9209251ca5858ed4, 0);
        _addAllocation(0xBE46D26c7efA383E40E28238b5Fdea8Dde7c2220, 1);
        _addAllocation(0x4Af2CDf1dd99067Bc00a33f24b251Bd029077A1E, 0);
        _addAllocation(0x482430EF7F291dCdA02CAbAfE867B5bc5754A7d5, 5);
        _addAllocation(0x18AC165861392bEd2b58f4B9f2934B2DcF6240Ea, 15);
        _addAllocation(0x715bfdD98eB7D0ff02d046e0d534b6Ed8dC60868, 0);
        _addAllocation(0x3d675Fb30E1C8Ed2Fc24569C7c6B32cD470325a5, 0);
        _addAllocation(0x704BF0e5C2009D784DaCf2C9dd9A3d958282B89b, 3);
        _addAllocation(0x7d1AF53ea9b696a0c920EA59Fb2196194D73389D, 15);
        _addAllocation(0x44F4D478cB1d4225B83fDA680CbcdA2784438746, 0);
        _addAllocation(0xCc4deD8137EB8d7D031e30b3e4aF49c9F56D55Dc, 5);
        _addAllocation(0x08fdD5eD1F9a424779e0a62e67065045c260Ef8f, 0);
        _addAllocation(0x3d27E146D414BBa6B7f8bd69c7063Ea6e2700F60, 15);
        _addAllocation(0x05ef8cc6E4987549606755a501cbfd9c526c2635, 0);
        _addAllocation(0x2035A46aEa776f39B02338ECd13115790804533c, 0);
        _addAllocation(0x8E0568dE58919886EAa4023Df13BB5E3D9ace1ac, 1);
        _addAllocation(0x4EFD7bF79813b3523918838eFc6DBD40a0597D67, 0);
        _addAllocation(0xEb1051B523Bb017fF98076Dfb632B1129AE3D8E7, 1);
        _addAllocation(0x2d4eB91CdDeA03a2A55CcCa343147ECA764076e2, 15);
        _addAllocation(0x99a3B922AD6AdA6695FF72d3fF24dA7541255EF5, 5);
        _addAllocation(0x6aAB52834C178454aC4Ec4660299143824bfAeC8, 0);
        _addAllocation(0x040325b8bbAF8e894D4dC34B28415cD48C34Cb83, 10);
        _addAllocation(0xcd68e340C0F9Ff782686fDB63b9978743968A2F6, 3);
        _addAllocation(0xB7E64cb5B81cc275024B056DBDb8eB4afd84b4EA, 5);
        _addAllocation(0x23Cf8AB359e16929944F1Aa8De0D3c5dCD3A520e, 0);
        _addAllocation(0xaD0870D7B0744c75dfa5Cc0285Bf744434d1Bc31, 0);
        _addAllocation(0x954e182331015415B195793e9Cc6f42a34bFE090, 0);
        _addAllocation(0x9506028925fBDf8FeDB0c9bfD668F57Cc62F0010, 1);
        _addAllocation(0x0123b52897a0DAA7AB4A2D727014b78b3091c99a, 0);
        _addAllocation(0xDf6e87287c96498320EC42a02C57A59C78c5133F, 0);
        _addAllocation(0xb06297a3F3D3EC29A9829eD59b9fa25bF6fC23c7, 0);
        _addAllocation(0xBcC224605383Cb72dc603B1e3b4f4678B371C4DC, 0);
        _addAllocation(0xd6A9e4785d4F2C49eF60Ba9b8f98F01C6b3c53Fe, 0);
        _addAllocation(0x250e7A4943beE210894dCf448a343b3C05C0e27B, 10);
        _addAllocation(0x39E3Bb553e641F5cB5f7471C50AAFfFF00f9F1C0, 0);
        _addAllocation(0xc69ca16Ac81A7299E7293ED910fBB6883A5dF3FD, 0);
        _addAllocation(0x73b05a1eCF267B8F28c02fD7eaDF7Fcb174C579C, 0);
        _addAllocation(0xD27bcfA98689D11E8f67a32f543DC77d5162Ff20, 0);
        _addAllocation(0x1345305793396dcA2EacD98aE9dA07EAE99137Ce, 10);
        _addAllocation(0x1504914451205F67cC434Bb521bF605672284ECc, 0);
        _addAllocation(0x6817BfD0A0326f6215aae73613bd57E1C40647A2, 0);
        _addAllocation(0x4484f01Ce9F400ec3eb35A441fA6475ac220e06E, 0);
        _addAllocation(0x52E701DD73339f598c35987a044Ea2865746a701, 0);
        _addAllocation(0x89d5Ac566d4d0BF14daD8B0531dd4B3de47F9424, 5);
        _addAllocation(0xb751C3d2Ca2FE23C1d87cb5ca65559111AFbBFD1, 15);
        _addAllocation(0x598f6f5f4082CC347653216a00572f49c6C2A600, 10);
        _addAllocation(0x844dBfC4Cc9ED5354f19f8c11B06402CeF728F9F, 1);
        _addAllocation(0x1374c422f89A5844A2A9e12A73cD9efB157bA5e7, 0);
        _addAllocation(0xAfE5B0813e1725389b5B3e47b44C3E201456cFEc, 0);
        _addAllocation(0x63d6F868d6c2b020a85ffF1d793393B092C4BE41, 1);
        _addAllocation(0xA8a308eaff92640a33c6a075e6869e0588BE5128, 0);
        _addAllocation(0xd0bdBB05a3933e3c6C2840061A4118635CB5B418, 5);
        _addAllocation(0x52f5520a03548042B64c3008A03Bdb8e39A64960, 0);
        _addAllocation(0xD6D8903F2E900b176c5915A68144E4bd664aA153, 3);
        _addAllocation(0xea4c527F8dE34816C97DD059aFC514a39CAdEBFB, 1);
        _addAllocation(0xa288A75AE2b78B454fc198550c0224E97EEc09Dd, 0);
        _addAllocation(0x7692ef84daDED4eE7CC501dEDDf6F5F43edC7Df1, 15);
        _addAllocation(0x63e9a97f21E8bB9424376e74c2cfDd3D822C4446, 0);
        _addAllocation(0x542f7246E7AbeaAD5aeB15913fDc704CbfEb6BE4, 0);
        _addAllocation(0x013bbCfF38F4E875B0218E4eB460e0E7c8FFaFc2, 15);
        _addAllocation(0x4073faa46835497eEb11fE80C444B805e6e7F589, 0);
        _addAllocation(0x13317023Bf6FE079eC1B4F2200e7b0A131bE74D4, 0);
        _addAllocation(0x3c9eCA0e41f0E1C5Fcb341E5F5Dab5a212c9E327, 0);
        _addAllocation(0x741F466918AAdb399d8F9c0ffED170A06AA58297, 0);
        _addAllocation(0xf073fb885C72021cED8eD74eB4579b0cFa685c64, 5);
        _addAllocation(0x3EAC6a0F1646f158A99b837341954b4cBeFc0F40, 5);
        _addAllocation(0x29babb3aacd5352176575Dd77d118dC604B1ad00, 0);
        _addAllocation(0x8fCe8A2a5D6143103031A3AFADD3A70e0BBCE09B, 0);
        _addAllocation(0x6f603d9bB86717762bBa1859E9FC16B675f91012, 3);
        _addAllocation(0x32f8dD495C7Da7c59780a4fc381E45b90a2f891A, 1);
        _addAllocation(0x4613b558fec524e4fC0FE2CCfC57BDEfc8B340c9, 15);
        _addAllocation(0xDC85cBA2910Be19E34ef5F263A8a080386104C7c, 0);
        _addAllocation(0x2Ebd3d7Cf6fecF1aaAAEF6851C2a7c8393C99e26, 1);
        _addAllocation(0x1673f0243f1DAB9F6278C61243D158f574670199, 1);
        _addAllocation(0x9aCB8310beD6012005C4Bf7950335881582551eF, 0);
        _addAllocation(0x07df6726fCCCfADC4dC5a18b33de479ea8825002, 15);
        _addAllocation(0xA2B44F5D86E8bD2Ae8D930AB77Ed64a56304E996, 5);
        _addAllocation(0x3858509cf90029E5d68C66F8B0183AB2269711Ec, 10);
        _addAllocation(0xd850aF6B064f973F8281ad98e7624a51867f67F4, 15);
        _addAllocation(0xE86A04591a9fCe13313Dc5B273D430BD428820d5, 0);
        _addAllocation(0x681255C655400CFd298D889a282f3B7170cAed9d, 15);
        _addAllocation(0x7817E259AE0824C3A65718176833718F7f834558, 0);
        _addAllocation(0xd1F4572Fb537d1dE3722F263844Ce2aec6dA472e, 0);
        _addAllocation(0x87601e6F66d82A77caBfD189D48C6D50Fa43D395, 0);
        _addAllocation(0x7d165b94C45B1ef1B6cB1697fD5261a72E18418f, 15);
        _addAllocation(0xd850aF6B064f973F8281ad98e7624a51867f67F4, 0);
        _addAllocation(0x8B4C28c7804137c4AaA43b23285DBc97A1daE945, 3);
        _addAllocation(0x75b6fF841fcA5467272d1F4769f9EE5685A4ef20, 15);
        _addAllocation(0x383F95A0c543079Aad6d20288eB999Eb4B94A592, 15);
        _addAllocation(0xdB869ec912BBd37d322f05D3EBd845AbE19ef42F, 5);
        _addAllocation(0x4AC901E03bE71F424648989997e24eC1c7d6274a, 0);
        _addAllocation(0xc7d4e77a8a6F7bC7181A6bD042a55eF38e9dec16, 1);
        _addAllocation(0x7C51fAe9E420fb68c6aE4A022276Eb113586C51C, 1);
    }

    function addAllocation(address addy, uint amount) external onlyAdmin {
        _addAllocation(addy, amount);
    }

    function _addAllocation(address addy, uint amount) private {
        _allAllocated.push(addy);
        _allocations[addy] = amount;
    }

    function editAllocation(address addy, uint amount) external onlyAdmin {
        require(_allocations[addy] > 0, "Cannot edit because this user has no allocation");

        _allocations[addy] = amount;
    }

    function getReservations(address addy) external view onlyAdmin returns (uint) {
        return _reservations[addy];
    }

    function getAllocations(address addy) external view onlyAdmin returns (uint) {
        return _allocations[addy];
    }

    function setPrice(uint256 price) external onlyAdmin {
        _pricePerAllocation = price;
    }

    function setCanReserve(bool can) external onlyAdmin {
        _canReserve = can;
    }

    function reserve(uint amount) external payable {
        require(address(_nft) != address(0), "NGReservations::reserve: NFT address not set.");
        require(_canReserve, "NGReservations::reserve: Reservations currently closed.");
        require(_allocations[msg.sender] > 0, "NGReservations::reserve: You have no allocation.");
        uint available = _allocations[msg.sender] - _reservations[msg.sender];
        require(available > 0, "NGReservations::reserve: You have already reserved your entire allocation.");
        require(amount <= available, "NGReservations::reserve: You cannot mint more then your allocation.");
        require(msg.value >= amount*_pricePerAllocation, "NGReservations::reserve: Insufficient funds sent for allocation");

        _reservations[msg.sender] += amount;
        _nft.freeMint(msg.sender, amount);
    }

    function getAllAllocated() external view onlyAdmin returns (address[] memory) {
        return _allAllocated;
    }

    receive() external payable {}

    function withdrawErc(address token, address recipient, uint256 amount) external onlyAdmin {
        TransferHelper.safeApprove(token, recipient, amount);
        TransferHelper.safeTransfer(token, recipient, amount);
    }

    function withdrawETH(address recipient, uint256 amount) external onlyAdmin {
        TransferHelper.safeTransferETH(recipient, amount);
    }

    function setNFT(address nft_) external onlyAdmin {
        _nft = INGNFT(nft_);
    }
}

interface INGNFT {
    function freeMint(address to, uint amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}