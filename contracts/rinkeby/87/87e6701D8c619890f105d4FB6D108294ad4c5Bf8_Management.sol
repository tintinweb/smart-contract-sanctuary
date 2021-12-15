// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct listingType {
    uint valore;
    bool percentuale;
}

interface InterfaceManagement{
    function isAddressAllowed(address adr) external returns(bool);
    function getLP(address adr) external view returns(listingType memory);
}

contract Management{
    mapping (address => bool) private isAllowed;
    mapping (address => uint256) private mapAdrToIndex;
    mapping (address => uint256) private mapAdrToCat;
    address [] addressesAllowed;
    address private us = 0xBF89faD64063542fa8f6A32F615009e07052BFB3;

    modifier onlyUs {
      require(msg.sender == us, "Non sei autorizzato");
      _;
    }

    function isAddressAllowed(address adr) public view returns(bool){
        return isAllowed[adr];
    }

    function getLP(address adr) external view returns(listingType memory){
        if (mapAdrToCat[adr]==0) return listingType(125*10**15,false);
        else if (mapAdrToCat[adr]==1) return listingType(5,true);
        else return listingType(10,true);
    }
    
    function add(address adr, uint256 cat) private {
        require(isAddressAllowed(adr) == false, "Address gia presente");
        isAllowed[adr] = true;
        addressesAllowed.push(adr);
        mapAdrToIndex[adr] = addressesAllowed.length-1;
        mapAdrToCat[adr] = cat;
    }

    function del(address adr) private{
        isAllowed[adr] = false;
        delete addressesAllowed[mapAdrToIndex[adr]];
    }

    function getAllowedAddresses() external onlyUs view returns(address [] memory){
        return addressesAllowed;
    }

    function addAllowedAddresses(address [] memory adr, uint256 [] memory cat) external onlyUs {
        for (uint i=0; i<adr.length; i++){
            add(adr[i],cat[i]);
        }
    }

    function deleteAllowedAddresses(address [] memory adr) external onlyUs{
        for (uint i=0; i<adr.length; i++){
            del(adr[i]);
        }
    }
}