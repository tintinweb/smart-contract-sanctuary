/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

pragma solidity ^0.8.7;

contract AccessControl {

    address private owner;
    mapping(address => bool) private allowed;

    constructor()  {
        owner = msg.sender;

        allowed[msg.sender] = true;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Sender must be 'owner' to perform this operation!");
        _;
    }

    modifier isAllowed() {
        require(allowed[msg.sender] == true, "Sender not allowed access to this operation!");
        _;
    }

    //Transfer ownsership of contract to another address; new owner is also added to allowed access list
    function transferOwnership(address newOwner) public isOwner {
        require(newOwner != address(0), "Zero address is invalid owner!");
        require(newOwner != owner, "Owner is the same as previous!");

        //Revoke access to preivous owner
        allowed[owner] = false;

        //Allow access to new owner
        allowed[newOwner] = true;

        //Set new owner
        owner = newOwner;
    }

    //Add @_cli to allowed access list
    function allowAccess(address _cli) public isOwner {
        allowed[_cli] = true;
    }

    //Remove @_cli from allowed access list
    function revokeAccess(address _cli) public isOwner {
        require(_cli != owner, "Can not revoke owner access!");

        allowed[_cli] = false;
    }

    //Check if @_cli is on allowed access list
    function hasAccess(address _cli) public view returns (bool) {
        return allowed[_cli];
    }

}


contract WalliDTSPStorageV2 is AccessControl {

    mapping (bytes => bytes) private sessions;

    constructor() public {}

    function addSession(bytes memory index, bytes memory session)
        public isAllowed
    {
        sessions[index] = session;
    }

    function getSession(bytes memory index) public view returns (bytes memory)
    {
        return sessions[index];
    }
}