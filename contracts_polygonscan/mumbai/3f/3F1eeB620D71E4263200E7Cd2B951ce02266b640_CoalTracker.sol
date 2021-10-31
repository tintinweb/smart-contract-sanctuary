/**
 *Submitted for verification at polygonscan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
contract CoalTracker
{
    event exported(string id,string ipfshash);
    event verified(string id,string importinglicense);
    mapping(string=>string) hashes;
    mapping(string=>string) verificationstatus;
    
    
    function exporter(string memory id,string memory ipfshash) public
    {
        hashes[id] = ipfshash;
        emit exported(id,ipfshash);
    }
    
    function importer(string memory id)public view returns(string memory)
    {
        return hashes[id];
    }
    
    function verify(string memory id,string memory importinglicense) public
    {
        verificationstatus[id]="true";
        emit verified(id,importinglicense);
    }
    
    function checkverification(string memory id)public view returns(string memory)
    {
        return verificationstatus[id];
    }
}