/**
 *Submitted for verification at Etherscan.io on 2020-09-19
*/

pragma solidity ^0.6.6;

interface IPoolProxy { 
    function apply_new_parameters(address pool) external;
    function apply_new_fee(address pool) external;
}

contract ApplyFee {
    
    constructor() public {
        IPoolProxy PoolProxy = IPoolProxy(0x6e8f6D1DA6232d5E40b0B8758A0145D6C5123eB7);
        
        address compound = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
        address iearn = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
        address busd = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
        address susdv2 = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
        
        address pax = 0x06364f10B501e868329afBc005b3492902d6C763;
        address ren = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
        address sbtc = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
        address hbtc = 0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F;
        
        PoolProxy.apply_new_parameters(compound);
        PoolProxy.apply_new_parameters(iearn);
        PoolProxy.apply_new_parameters(busd);
        PoolProxy.apply_new_parameters(susdv2);
        
        PoolProxy.apply_new_fee(pax);
        PoolProxy.apply_new_fee(ren);
        PoolProxy.apply_new_fee(sbtc);
        PoolProxy.apply_new_fee(hbtc);
    }
}