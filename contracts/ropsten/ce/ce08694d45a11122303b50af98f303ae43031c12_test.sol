/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

contract test{
    address public dev_address;
    address public SASH_contract;
    address public SGM_contract;
    address public governance_contract;
    address public bank_contract;
    address public bond_contract;
    
    bool public contract_is_active;
    
    struct DATA  {
    address  dev_address1;
    address  SASH_contract1;
    address  SGM_contract1;
    address  governance_contract1;
    address  bank_contract1;
    address  bond_contract1;
    }
    
    DATA public testData;
    
    function write_seperate(   
    address  _dev_address1,
    address  _SASH_contract1,
    address  _SGM_contract1,
    address  _governance_contract1,
    address  _bank_contract1,
    address  _bond_contract1
    ) public{
    
    dev_address=_dev_address1;
    SASH_contract=_SASH_contract1;
    SGM_contract=_SGM_contract1;
    governance_contract=_governance_contract1;
    bank_contract=_bank_contract1;
    bond_contract=_bond_contract1;
    }
    
    
    function write_structure1(   
    address  _dev_address1,
    address  _SASH_contract1,
    address  _SGM_contract1,
    address  _governance_contract1,
    address  _bank_contract1,
    address  _bond_contract1
    ) public{
    
    DATA memory new_testData;
    
    new_testData.dev_address1=_dev_address1;
    new_testData.SASH_contract1=_SASH_contract1;
    new_testData.SGM_contract1=_SGM_contract1;
    new_testData.governance_contract1=_governance_contract1;
    new_testData.bank_contract1=_bank_contract1;
    new_testData.bond_contract1=_bond_contract1;
    testData=new_testData;
    }
    
    function write_structure2(   
    DATA memory new_testData
    ) public{
    testData=new_testData;
    }
    
    
        
}