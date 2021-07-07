/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Vouchers {
    
    mapping (address => uint) public saldi;
    
    constructor () {
        saldi[0x279d96666E9bcdE6aA935Add43c8c4ee590a4cd7] = 10;
        saldi[0xdd0CE6169Ed07cA6140F4DFc1970Cf1a704289c2] = 10;
        saldi[0x37c967A5416001761797A157225298519003f7AF] = 10;
        saldi[0x902e9432D8A95C6f5df272c0EAc6DA1Eeaf15F14] = 10;
        saldi[0x83061C807D287F569373A1b3161803609b92A259] = 10;
        saldi[0x57feF4Fa16BF9F38E0131C09a9C369935Cd7d710] = 10;
        saldi[0x8Cfb76a97d2C77E386A5204770915a3f2D4f8B94] = 10;
        saldi[0x9ac55d8Fe2F094889f699B1CbefbBCa696c70cB6] = 10;
        saldi[0x767E8916B87dACC52086751E835B47389e4B8298] = 10;
        saldi[0x24302248DE268f821DEb1D61b5Cf08c1dD3ac5fe] = 10;
        saldi[0xE59249eCBd33fEe54AeE0844093cF841269E1e84] = 10;
        saldi[0x5BD1fafBa2b4c1aE83c6Be38a8418D69f27115D3] = 10;
        saldi[0x35e24ead1A1cE678B31cEf7Bc90CD649848f2d96] = 10;
        saldi[0xBC67DC06aA435Dced0e3396e27Bb11227b6B274F] = 10;
        saldi[0x2bB8DeFB8894a9474381Ba09e7721CCbc12D135C] = 10;
        saldi[0x9f1C0ce6D6a5806c4e4877365a6E215001b6fD59] = 10;
        saldi[0x986Ba931832bA11C13D5E5Df64618502c506DB3B] = 10;
        saldi[0xccC42b6Ff115e9aa61e5D9582Ed65b2eCDF766dD] = 10;
        saldi[0x03DAcD91d3F2a4eE9999e0E339496056FA1b0456] = 10;
        saldi[0xeC278450595efeA5c1813D467fF759B709E6C1f2] = 10;
        saldi[0x252DA2106689f73c5979f27f3E6ED856ac36b69E] = 10;
        saldi[0x9ac55d8Fe2F094889f699B1CbefbBCa696c70cB6] = 10;
    }
        
    function transfer (address destinatario, uint quanti) public {
        // aumenta il saldo del destinatario di "quanti"
        saldi[destinatario] += quanti;
        // diminuisci il saldo del mittente di "quanti"
        saldi[msg.sender] -= quanti;
    } 
    
}