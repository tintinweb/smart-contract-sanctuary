/**
 *Submitted for verification at hecoinfo.com on 2022-05-21
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-01-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface Platform {

    function platformWithdraw(address _tokenContract) external;
}

address constant USDT = 0xa71EdC38d189767582C38A3145b5873052c3e47a;
address constant TT = 0x86040C76AAE5CBB322364CAF8820b0E8902e97E5;
address constant DOGE = 0x40280E26A572745B1152A54D1D44F365DaA51618;
address constant HFIL = 0xae3a768f9aB104c69A7CD6041fE16fFa235d1810;
address constant IPC = 0x39C78865cDE5656681d36404333AEf8Ab7556faB;
address constant HBTC = 0x66a79D23E58475D2738179Ca52cd0b41d73f0BEa;
address constant ETH = 0x64FF637fB478863B7468bc97D30a5bF3A428a1fD;
address constant AXS = 0x0BDe532913915cb6E2F0467b8E46E286cfCFB2bb;
address constant NFT = 0xD2dAF463cda501027CdF4A6D94749A72B8c7c72d;
address constant HDOT = 0xA2c49cEe16a5E5bDEFDe931107dc1fae9f7773E3;


address constant PlatformAddress = 0x5ec04C54Db16F2A7AF75d0939836E89E6DEAfbF3;

contract PlatformController {

    address[] _addresss;

    constructor () {
        _addresss.push(USDT);
        _addresss.push(TT);
        _addresss.push(DOGE);
        _addresss.push(HFIL);
        _addresss.push(IPC);
        _addresss.push(HBTC);
        _addresss.push(ETH);
        _addresss.push(AXS);
        _addresss.push(NFT);
        _addresss.push(HDOT);
    }

    function insert(address _tokenContract) external
    {
        _addresss.push(_tokenContract);
    }

    function platformWithdraw() external
    {
        for (uint i=0; i<_addresss.length; i++)
        {
            Platform(PlatformAddress).platformWithdraw(_addresss[i]);
        }
    }

}