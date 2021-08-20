// SPDX-License-Identifier: No License
pragma solidity >=0.8.6;
import './IMerchant.sol';
import './CPMerchant.sol';
// File: /contracts/libraries/IMerchantFactory.sol
interface IMerchantFactory{
    function name()external returns(string memory);
    function version()external returns(string memory);
    function meta()external returns(string memory);
    function createMerchant(string calldata merchantName, address ownerAddress)external returns(IMerchant);
}

contract MerchantFactory is IMerchantFactory{
    string _name;
    string _version;
    string _meta;
    function name()public view override returns(string memory){
        return _meta;
    }
    function version()public view override returns(string memory){
        return _version;
    }
    function meta()public view override returns(string memory){
        return _meta;
    }
    function createMerchant(string calldata merchantName, address ownerAddress)external override returns(IMerchant){
       IMerchant merchant = new CPMerchant();
       merchant.init(merchantName, ownerAddress);
       return merchant;
    }
}