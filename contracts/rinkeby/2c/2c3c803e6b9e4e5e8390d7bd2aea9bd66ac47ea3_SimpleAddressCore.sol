/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleAddressCore {
    struct connection{
        address theOther;
        uint selfActionTime;
    }
    struct set{
        connection[] connections;
        mapping(address=>bool) exists;
    }
    mapping(string => address) nameToMeta;
    mapping(address => string) metaToName;
    mapping(address => uint) countMeta;
    mapping(address => bool) isMeta;
    mapping(address => set) metaToSub;
    mapping(address => set) subToMeta;

    event Registered(address meta, string name);
    event Requested(address meta, address sub, address sender);
    event Approved(address meta, address sub, address sender);

    function registerAddress(string memory name) public {
        //Address should not be an already registered meta address 
        require(isMeta[msg.sender]==false, "Address already registered");
        //Address should not be an already registered sub-address
        require(countMeta[msg.sender]==0, "Address already within Meta address(es)");
        //Name should be valid
        require(_isValidName(name)==true, "Invalid Name");
        //Name should be unused
        require(nameToMeta[name]==address(0), "Name not available");


        nameToMeta[name] = msg.sender;
        metaToName[msg.sender] = name;
        isMeta[msg.sender] = true;
        emit Registered(msg.sender, name);
    }

    function findByName(string memory name) public view returns(address meta){
        meta = nameToMeta[name];
    }
    function findByMeta(address meta) public view returns(string memory name){
        name = metaToName[meta];
    }
    function associate(address meta, address sub)public returns(bool truth) {
        //No 3rd Parties
        require(msg.sender==meta || msg.sender==sub, "Insufficient access for approval");
        //Address should be registered with a Simple Name to be called a Meta address
        require(isMeta[meta]==true, "Invalid Meta address");
        //An existing Meta address cannot be passed as a Sub address
        require(isMeta[sub]==false, "Invalid Sub address. A Meta address cannot be a Sub address");
        //Approved connections or connections awaitig approval cannot use this function
        require(metaToSub[meta].exists[sub]==false && subToMeta[sub].exists[meta]==false, 
                "Association exists. Use approve() to approve if not approved");
        if(msg.sender==meta){
            metaToSub[meta].exists[sub]=true;
            connection memory conn = connection(sub, block.timestamp);
            metaToSub[meta].connections.push(conn);
        }
        else if (msg.sender==sub){
            subToMeta[sub].exists[meta]=true;
            countMeta[sub]+=1;
            connection memory conn = connection(meta, block.timestamp);
            subToMeta[sub].connections.push(conn);
        }

        emit Requested(meta, sub, msg.sender);
        truth = true;
    }

    function approve(address meta, address sub) public returns(bool truth){
        //No 3rd Parties
        require(msg.sender==meta || msg.sender==sub, "Insufficient access for approval");
        //Address should be registered with a Simple Name to be called a Meta address
        require(isMeta[meta]==true, "Invalid Meta address");
        //An existing Meta address cannot be passed as a Sub address
        require(isMeta[sub]==false, "Invalid Sub address. A Meta address cannot be a Sub address");
        //Approved connections or connections without associate() call are invalid
        if(metaToSub[meta].exists[sub]==false && subToMeta[sub].exists[meta]==false){
            revert("No association available to approve");
        }
        else if(metaToSub[meta].exists[sub]==true && subToMeta[sub].exists[meta]==true){
            revert("Association already exists");
        }
        else if(metaToSub[meta].exists[sub]==false){
            require(msg.sender==meta, "Association and Approval cannot be made from the same account");
            metaToSub[meta].exists[sub]=true;
            connection memory conn = connection(sub, block.timestamp);
            metaToSub[meta].connections.push(conn);
        }
        else if(subToMeta[sub].exists[meta]==false){
            require(msg.sender==sub, "Association and Approval cannot be made from the same account");
            subToMeta[sub].exists[meta]=true;
            countMeta[sub]+=1;
            connection memory conn = connection(meta, block.timestamp);
            subToMeta[sub].connections.push(conn);
        }
        emit Approved(meta, sub, msg.sender);
        truth = true;
    }

    function viewConnections(address addr, bool verified) public view returns (connection[] memory conns){
        if(isMeta[addr]==true){
            //If only verified accounts have been asked, this deletes the unverified associations
            conns = metaToSub[addr].connections;
            for(uint i = 0; i<conns.length; i++){
                if(verified==true && subToMeta[conns[i].theOther].exists[addr]==false){
                    delete conns[i];
                    continue;
                }
            }
        }
        else{
            //If only verified accounts have been asked, this deletes the unverified associations
            conns = subToMeta[addr].connections;
            for(uint i = 0; i<conns.length; i++){
                if(verified==true && metaToSub[conns[i].theOther].exists[addr]==false){
                    delete conns[i];
                    continue;
                }
            }
        }
    }

//Helper Functions

    function _isValidName(string memory name) internal pure returns(bool validity){
        //Pre-Process name (a-z, 0-9, [.], [-], [_]), Not starting with special characters
        //WIP

        //Simple Test
        validity = bytes(name).length>0;
    }
}