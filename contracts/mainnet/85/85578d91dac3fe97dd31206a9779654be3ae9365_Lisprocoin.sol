/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;
// Title Lisprocoin
contract Lisprocoin{
string  public symbol = "LSP20";
uint256 public totalSupply=200000000000000000000;
uint8 public decimal =18;
      
// Symbol : LSP20
// Name   : LISPROCOIN
// Total supply : 200000000000000000000;
// Decimals : 18
// Owner Account : 0XD0355200111C2B21AAbC1a31552eCCDc5d4E905d
// Email:[email protected]
// Website URL: https://lisprocoin.org
// Github : https://github.com/15Lippo/lisprocoin.org
// Coin Logo : https://ibb.co/wR1JGCY   



// This import is automatically injected by Remix import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin import "remix_accounts.sol";
// <import file to test>

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts contract testSuite {

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // <instantiate contract> Assert.equal(uint(1), uint(1), "1 should be equal to 1");
    }

    function checkSuccess() public {
        // Use 'Assert' methods: https://remix-ide.readthedocs.io/en/latest/assert_library.html Assert.ok(2 == 2, 'should be true'); Assert.greaterThan(uint(2), uint(1), "2 should be greater than to 1"); Assert.lesserThan(uint(2), uint(3), "2 should be lesser than to 3");
    }

    function checkSuccess2() public pure returns (bool) {
        // Use the return value (true or false) to test the contract
        return true;
    }
}