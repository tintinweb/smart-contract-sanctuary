pragma solidity 0.5.17;

import './safeMath.sol';

interface Curve {
    function get_virtual_price() external view returns (uint);
}

interface Yearn {
    function getPricePerFullShare() external view returns (uint);
}

interface UnderlyingToken {
    function decimals() external view returns (uint8);
}

interface Compound {
    function exchangeRateStored() external view returns (uint);
    function underlying() external view returns (address);
}

interface Cream {
    function exchangeRateStored() external view returns (uint);
    function underlying() external view returns (address);
}

contract Normalizer {
    using SafeMath for uint;

    address public governance;
    address public creamY;
    mapping(address => bool) public native;
    mapping(address => bool) public yearn;
    mapping(address => bool) public curve;
    mapping(address => address) public curveSwap;
    mapping(address => bool) public vaults;
    mapping(address => bool) public compound;
    mapping(address => bool) public cream;
    mapping(address => uint) public underlyingDecimals;

    constructor() public {
        governance = msg.sender;

        native[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; // USDT
        native[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; // USDC
        native[0x4Fabb145d64652a948d72533023f6E7A623C7C53] = true; // BUSD
        native[0x0000000000085d4780B73119b644AE5ecd22b376] = true; // TUSD

        yearn[0xACd43E627e64355f1861cEC6d3a6688B31a6F952] = true; // vault yDAI
        yearn[0x37d19d1c4E1fa9DC47bD1eA12f742a0887eDa74a] = true; // vault yTUSD
        yearn[0x597aD1e0c13Bfe8025993D9e79C69E1c0233522e] = true; // vault yUSDC
        yearn[0x2f08119C6f07c006695E079AAFc638b8789FAf18] = true; // vault yUSDT

        yearn[0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01] = true; // yDAI
        yearn[0xd6aD7a6750A7593E092a9B218d66C0A814a3436e] = true; // yUSDC
        yearn[0x83f798e925BcD4017Eb265844FDDAbb448f1707D] = true; // yUSDT
        yearn[0x73a052500105205d34Daf004eAb301916DA8190f] = true; // yTUSD
        yearn[0xF61718057901F84C4eEC4339EF8f0D86D2B45600] = true; // ySUSD

        yearn[0xC2cB1040220768554cf699b0d863A3cd4324ce32] = true; // bDAI
        yearn[0x26EA744E5B887E5205727f55dFBE8685e3b21951] = true; // bUSDC
        yearn[0xE6354ed5bC4b393a5Aad09f21c46E101e692d447] = true; // bUSDT
        yearn[0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE] = true; // bBUSD

        curve[0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2] = true; // cCompound
        curveSwap[0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2] = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
        curve[0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8] = true; // cYearn
        curveSwap[0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8] = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
        curve[0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B] = true; // cBUSD
        curveSwap[0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B] = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
        curve[0xC25a3A3b969415c80451098fa907EC722572917F] = true; // cSUSD
        curveSwap[0xC25a3A3b969415c80451098fa907EC722572917F] = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
        curve[0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8] = true; // cPAX
        curveSwap[0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8] = 0x06364f10B501e868329afBc005b3492902d6C763;

        compound[0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643] = true; // cDAI
        underlyingDecimals[0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643] = 1e18;
        compound[0x39AA39c021dfbaE8faC545936693aC917d5E7563] = true; // cUSDC
        underlyingDecimals[0x39AA39c021dfbaE8faC545936693aC917d5E7563] = 1e6;
        compound[0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9] = true; // cUSDT
        underlyingDecimals[0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9] = 1e6;

        cream[0x44fbeBd2F576670a6C33f6Fc0B00aA8c5753b322] = true; // crUSDC
        underlyingDecimals[0x44fbeBd2F576670a6C33f6Fc0B00aA8c5753b322] = 1e6;
        cream[0x797AAB1ce7c01eB727ab980762bA88e7133d2157] = true; // crUSDT
        underlyingDecimals[0x797AAB1ce7c01eB727ab980762bA88e7133d2157] = 1e6;
        cream[0x1FF8CDB51219a8838b52E9cAc09b71e591BC998e] = true; // crBUSD
        underlyingDecimals[0x1FF8CDB51219a8838b52E9cAc09b71e591BC998e] = 1e18;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setCreamY(address _creamY) external {
        require(msg.sender == governance, "!governance");
        creamY = _creamY;
    }

    function getPrice(address token) external view returns (uint) {
        if (native[token] || token == creamY) {
            return 1e18;
        } else if (yearn[token]) {
            return Yearn(token).getPricePerFullShare();
        } else if (curve[token]) {
            return Curve(curveSwap[token]).get_virtual_price();
        } else if (compound[token]) {
            return getCompoundPrice(token);
        } else if (cream[token]) {
            return getCreamPrice(token);
        } else {
            return uint(0);
        }
    }

    function getCompoundPrice(address token) public view returns (uint) {
        address underlying = Compound(token).underlying();
        uint8 decimals = UnderlyingToken(underlying).decimals();
        return Compound(token).exchangeRateStored().mul(1e8).div(uint(10) ** decimals);
    }

    function getCreamPrice(address token) public view returns (uint) {
        address underlying = Cream(token).underlying();
        uint8 decimals = UnderlyingToken(underlying).decimals();
        return Cream(token).exchangeRateStored().mul(1e8).div(uint(10) ** decimals);
    }
}
