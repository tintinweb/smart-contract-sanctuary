/**
 *Submitted for verification at Etherscan.io on 2020-05-29
*/

pragma solidity >=0.4.22 <0.7.0;

contract Bofrost {
    
    struct MP {
        string id;
        string data;
    }
    
    struct PF {
        string id;
        string data;
    }
    
    address private owner;
    mapping(string => bool) private exist_MP;
    mapping(string => MP) private list_MP;
    mapping(string => bool) private exist_PF;
    mapping(string => PF) private list_PF;
    mapping(address => bool) private allowedMP;
    mapping(address => bool) private allowedPF;
    
    // event for EVM logging
    event MPSet(string, string);
    event PFSet(string, string);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier AllowedMP() {
        require(allowedMP[msg.sender] == true, "Caller is not allowed");
        _;
    }
    
    modifier AllowedPF() {
        require(allowedPF[msg.sender] == true, "Caller is not allowed");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    
    function setMP (string calldata _id, string calldata _data) external AllowedMP {
        require(bytes(_id).length > 0, 'ID is empty');
        require(exist_MP[_id] == false, 'MP already exist');
        require(bytes(_data).length > 0, 'DATA is empty');
        
        MP memory tmp;
        tmp.id = _id;
        tmp.data = _data;
        
        list_MP[_id] = tmp;
        exist_MP[_id] = true;
        
        emit MPSet('New MP was added with ID: ', _id);
    }
    
    
     function setPF (string calldata _id, string calldata _data) external AllowedPF {
        require(bytes(_id).length > 0, 'ID is empty');
        require(exist_PF[_id] == false, 'PF already exist');
        require(bytes(_data).length > 0, 'DATA is empty');
        
        PF memory tmp;
        tmp.id = _id;
        tmp.data = _data;
        
        list_PF[_id] = tmp;
        exist_PF[_id] = true;
        
        emit MPSet('New PF was added with ID: ', _id);
    }
    
    
    function getMP (string memory _id) public view returns (string memory) {
        require(bytes(_id).length > 0, 'ID is empty');
        require(exist_MP[_id] == true, 'MP does not exist');
        
        return list_MP[_id].data;
    }
    
    
    function getPF (string memory _id) public view returns (string memory) {
        require(bytes(_id).length > 0, 'ID is empty');
        require(exist_PF[_id] == true, 'PF does not exist');
        
        return list_PF[_id].data;
    }
    
    
    
    
    function allowedAddressMP(address _address) external isOwner {
        require(allowedMP[_address] == false, 'Address already enabled');
        
        allowedMP[_address] = true;
    }
    
    
    function allowedAddressPF(address _address) external isOwner {
        require(allowedPF[_address] == false, 'Address already enabled');
        
        allowedPF[_address] = true;
    }
    
    function removeAddressMP(address _address) external isOwner {
        require(allowedMP[_address] == true, 'Address does not exist');
        
        allowedMP[_address] = false;
    }
    
    function removeAddressFP(address _address) external isOwner {
        require(allowedPF[_address] == true, 'Address does not exist');
        
        allowedPF[_address] = false;
    }
}