/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract ZakaX {
    
    address[] admins;
    
    uint fee;
    uint assetsCount;
    uint holdingsCount;
    
    struct asset {
        string name;
        string symbol;
        string[] pairs;
        uint issued;
        uint burnt;
        uint holders;
    }
    mapping(uint => asset) assets;
    
    struct holding {
        uint asset;
        address holder;
        uint quantity;
        uint stamp;
    }
    mapping(uint => holding) holdings;
    mapping(address => uint[]) holders;
    
    constructor() {
        admins.push(msg.sender);
        assetsCount = 0;
        holdingsCount = 0;
        fee = 3;
    }
    
    function addAsset(string memory _name, string memory _symbol, string[] memory _pairs) public returns(bool) {
        require(_isAdmin(msg.sender) == true, "Not admin");
        
        assetsCount++;
        uint _index = assetsCount;
        assets[_index] = asset(_name, _symbol, _pairs, 0, 0, 0);
        
        return true;
    }
    
    function getNumAssets() public view returns(uint) {
        return assetsCount;
    }
    
    function getAsset(uint _index) public view returns(string memory _name, string memory _symbol, string[] memory _pairs, uint _issued, uint _holders) {
        _name = assets[_index].name;
        _symbol = assets[_index].symbol;
        _pairs = assets[_index].pairs;
        _issued = assets[_index].issued;
        _holders = assets[_index].holders;
    }
    
    function issueAsset(uint _asset, uint _qty, address _holder) public returns(bool) {
        require(_isAdmin(msg.sender) == true, "Not admin");
        
        holdingsCount++;
        uint _index = holdingsCount;
        holdings[_index] = holding(_asset, _holder, _qty, block.timestamp);
        holders[_holder].push(_index);
        
        return true;
    }
    
    function burnIssue(uint _holdingIndex, uint _assetIndex) public returns(bool) {
        require(_isAdmin(msg.sender) == true, "Not admin");
        
        holdings[_holdingIndex].quantity = 0;
        assets[_assetIndex].burnt++;
        
        return true;
    }
    
    function getFee() public view returns(uint) {
        return fee;
    }
    
    function changeFee(uint _fee) public returns(bool) {
        require(_isAdmin(msg.sender) == true, "Not admin");
        
        fee = _fee;
        
        return true;
    }
    
    function isAdmin() public view returns(bool) {
        return _isAdmin(msg.sender);
    }
    
    function _isAdmin(address _address) internal view returns(bool) {
        bool isAdmn = false;
        
        uint len = admins.length;
        
        for(uint i = 0; i < len; i++) {
            if(admins[i] == _address) {
                isAdmn = true;
            }
        }
        
        return isAdmn;
    }
    
}