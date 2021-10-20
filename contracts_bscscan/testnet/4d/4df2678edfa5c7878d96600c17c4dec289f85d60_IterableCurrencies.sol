/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
 * @dev 
 * This library is required to manage available currencies on ToshiGame
 *
 * The declaration of the variable is on "GameManager.sol"
 * Only BabyToshi owner can execute functions to create, update and delete
 * Everybody can execute readable functions.
 */
library IterableCurrencies {
    struct Currencies{
        address[] keys;
        mapping(address => bool) available;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }
    function get(Currencies storage currencies, address key) external view returns(address currency, bool available) {
        if( !currencies.inserted[key] ){
            return ( address(0), false );
        }
        return ( key, currencies.available[key] );
    }
    function getAll(Currencies storage currencies) external view returns(address[] memory currency, bool[] memory available) {
        uint _nTokens = currencies.keys.length;
        (address[] memory _currency, bool[] memory _available) = (new address[](_nTokens), new bool[](_nTokens));
        for(uint i=0; i < _nTokens; i++ ){
            address key = currencies.keys[i];
            _currency[i] = key;
            _available[i] = currencies.available[key];
        }
        return (_currency, _available);
    }
    
    function getAvailables(Currencies storage currencies) external view returns(address[] memory currency){
        uint _nTokens = currencies.keys.length;
        address[] memory _currency = new address[](_nTokens);
        for(uint i=0; i < _nTokens; i++ ){
            address key = currencies.keys[i];
            if( currencies.available[key] ){
                _currency[i] = key;
            }
        }
        return (_currency);
    }
    function isCurrency(Currencies storage currencies, address key) external view returns(bool _isCurrency){
        return currencies.inserted[key];
    }
    function add(Currencies storage currencies, address key) external returns(bool added){
        if( currencies.inserted[key] ){
            return false;
        }
        currencies.keys.push(key);
        currencies.available[key] = true;
        currencies.indexOf[key] = currencies.keys.length - 1;
        currencies.inserted[key] = true;
        
        return true;
    }

    function remove(Currencies storage currencies, address key) external returns (bool removed){
        if ( !currencies.inserted[key] ){
            return false;
        }
        delete currencies.available[key];
        delete currencies.inserted[key];
        uint index = currencies.indexOf[key];
        uint lastIndex = currencies.keys.length - 1;
        address lastKey = currencies.keys[lastIndex];
        currencies.indexOf[lastKey] = index;
        currencies.keys[index] = lastKey;
        delete currencies.indexOf[key];
        currencies.keys.pop();
        return true;
    }
    
    
    function getIndexOfKey(Currencies storage currencies, address key) external view returns (int index) {
        if(!currencies.inserted[key]) {
            return -1;
        }
        return int(currencies.indexOf[key]);
    }

    function getKeyAtIndex(Currencies storage currencies, uint index) external view returns (address key) {
        return currencies.keys[index];
    }
    
    function updateAddress(Currencies storage currencies, address key, address newKey) external returns(bool updated) {
        if( !currencies.inserted[key] ){
            return false;
        }
        uint index = currencies.indexOf[key];
        if( currencies.keys[index] == newKey ){
            return false;
        }
        currencies.keys[index] = newKey;
        return true;
    }
    
    function updateAvailable(Currencies storage currencies, address key, bool available) external returns(bool updated){
        if( !currencies.inserted[key]){
            return false;
        }
        if( currencies.available[key] == available ){
            return false;
        }
        currencies.available[key] = available;
        return true;
    }
    function size(Currencies storage currencies) external view returns (uint length) {
        return currencies.keys.length;
    }
}