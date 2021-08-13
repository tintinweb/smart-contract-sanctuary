/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: WTFPL

pragma solidity 0.7.5;


contract ETHBondDeposits {
    
    // MAINET Wrapped Ethereum Contract: https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    // MAINET V1 ETH Bond Depository Contract: https://etherscan.io/address/0xE6295201CD1ff13CeD5f063a5421c39A1D236F1c
    IBonds public constant ethBondDepository = IBonds(0xE6295201CD1ff13CeD5f063a5421c39A1D236F1c);
    
    constructor() {
        WETH.approve(address(ethBondDepository), type(uint).max); // approve ethBondDepository to spend contract's wETH
    }

    
    /*
     *  @notice deposit using native Ethereum
     *  @param _maxPrice uint
     *  @param _depositor address
     */
    function deposit(
        uint _maxPrice, 
        address _depositor
    )
        external 
        payable 
        returns 
        (uint) 
    {
        WETH.deposit{value: msg.value}();
        return ethBondDepository.deposit(msg.value, _maxPrice, _depositor);
    }
}

interface IBonds {
    function deposit(uint _amount,uint _maxPrice, address _depositor) external returns ( uint );
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
    function approve(address to, uint value) external returns (bool);
    
}