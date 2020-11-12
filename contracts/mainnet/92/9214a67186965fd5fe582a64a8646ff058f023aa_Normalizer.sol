pragma solidity 0.5.17;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        if(a % b != 0)
            c = c + 1;
        return c;
    }
}

interface Curve {
    function get_virtual_price() external view returns (uint);
}

interface Yearn {
    function getPricePerFullShare() external view returns (uint);
}

interface Dforce {
    function getExchangeRate() external view returns (uint);
}

interface Compound {
    function exchangeRateStored() external view returns (uint);
    function decimals() external view returns (uint);
}

interface Cream {
    function exchangeRateStored() external view returns (uint);
    function decimals() external view returns (uint);
}

contract Normalizer {
    
    mapping(address => bool) public yearn;
    mapping(address => bool) public curve;
    mapping(address => address) public curveSwap;
    mapping(address => bool) public vaults;
    mapping(address => bool) public dforce;
    mapping(address => bool) public compound;
    mapping(address => bool) public cream;
    
    constructor() public {
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
        
        dforce[0x868277d475E0e475E38EC5CdA2d9C83B5E1D9fc8] = true; // dUSDT
        dforce[0x02285AcaafEB533e03A7306C55EC031297df9224] = true; // dDAI
        dforce[0x16c9cF62d8daC4a38FB50Ae5fa5d51E9170F3179] = true; // dUSDC
        
        compound[0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643] = true; // cDAI
        compound[0x39AA39c021dfbaE8faC545936693aC917d5E7563] = true; // cUSDC
        compound[0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9] = true; // cUSDT
        
        cream[0x44fbeBd2F576670a6C33f6Fc0B00aA8c5753b322] = true; // crUSDC
        cream[0x797AAB1ce7c01eB727ab980762bA88e7133d2157] = true; // crUSDT
        cream[0x1FF8CDB51219a8838b52E9cAc09b71e591BC998e] = true; // crBUSD
    }
    
    function getPrice(address token) external view returns (uint, uint) {
        if (yearn[token]) {
            return (uint(18), Yearn(token).getPricePerFullShare());
        } else if (curve[token]) {
            return (uint(18), Curve(curveSwap[token]).get_virtual_price());
        } else if (dforce[token]) {
            return (uint(18), Dforce(token).getExchangeRate());
        } else if (compound[token]) {
            return (uint(18), Compound(token).exchangeRateStored());
        } else if (cream[token]) {
            return (uint(18), Cream(token).exchangeRateStored());
        }
    }
}