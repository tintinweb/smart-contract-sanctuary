/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT-License
pragma abicoder v2;
pragma solidity >=0.7.0 <0.8.0;

contract ModelsLedger {
    address private Owner;
    
    struct ModelRecord {
        string Title;
        string Link;
        string Hash;
    }
    
    ModelRecord[] private Models;
    uint private ModelsCount;
    
    mapping (address => bool) private Permissions;
    
    constructor() {
        Owner = msg.sender;
        Permissions[Owner] = true;
    }
    
    function SetPermission(address _User, bool _Access) public {
        if (msg.sender == Owner && _User != Owner) {
            Permissions[_User] = _Access;
        }
    }
    
    function GivePermission(address _User) public {
        SetPermission(_User, true);
    }
    
    function RevokePermission(address _User) public {
        SetPermission(_User, false);
    }
    
    function CheckPermission(address _User) public view returns (bool) {
        return Permissions[_User];
    }
    
    function CheckMyPermission() public view returns (bool) {
        return Permissions[msg.sender];
    }
    
    function AddModel(string memory _Title, string memory _Link, string memory _Hash) public {
        if (msg.sender == Owner) {
            ModelRecord memory _Model = ModelRecord(_Title, _Link, _Hash);
            Models.push(_Model);
            ModelsCount++;
        }
    }
    
    function RemoveModel(uint index) public {
        if (msg.sender == Owner) {
            if (index >= ModelsCount) return;
    
            for (uint i = index; i < ModelsCount - 1; i++) {
                Models[i] = Models[i + 1];
            }
            
            ModelsCount--;
        }
    }
    
    function ReadModels() public view returns (ModelRecord[] memory) {
        if (Permissions[msg.sender]) {
            return Models;
        }
        
        ModelRecord[] memory _Empty;
        return _Empty;
    }
    
    function GetModelsCount() public view returns (uint) {
        return ModelsCount;
    }
}