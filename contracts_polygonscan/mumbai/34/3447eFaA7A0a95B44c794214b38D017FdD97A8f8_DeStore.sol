/**
 *Submitted for verification at polygonscan.com on 2021-07-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DeStore {
    
    constructor() {}
    
    /*
    * appId is ipfs hash for unique metadata
    * name, tagline, description, icon
    */
    struct App {
        bytes32 appId;
        string name;
        string tagLine;
        string description;
        string icon;
        string apkFile;
        string iosFile;
        string[] images;
    }
    
    mapping(address => bytes32[]) private userApps;
    
    mapping(bytes32 => App) private idToApp;
    
    bytes32[] private allApps;

    event NewApp(App RegisteredApp);
    
    function addApplication(string memory _name, string memory _tagLine, string memory _description, string memory _icon, string memory _apkFile, string memory _iosFile, string[] memory _images) public {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Cannot have empty app name");
        require(keccak256(abi.encodePacked(_tagLine)) != keccak256(abi.encodePacked("")), "Cannot have empty app tagline");
        require(keccak256(abi.encodePacked(_description)) != keccak256(abi.encodePacked("")), "Cannot have empty app description");
        require(keccak256(abi.encodePacked(_icon)) != keccak256(abi.encodePacked("")), "Cannot have empty app icon");
        bytes32 _appId = keccak256(abi.encodePacked(_name, _tagLine,_description,_icon));
        require(keccak256(abi.encodePacked(_apkFile)) != keccak256(abi.encodePacked("")) 
            || keccak256(abi.encodePacked(_iosFile)) != keccak256(abi.encodePacked("")), "Cannot have empty apk or ios file");
        require(_images.length > 0 && keccak256(abi.encodePacked(_images[0])) != keccak256(abi.encodePacked("")), "Cannot have empty image list");
        App memory _newApp = idToApp[_appId];
        require(keccak256(abi.encodePacked(_newApp.appId)) != keccak256(abi.encodePacked(_appId)), "App id already available");
        
        App memory newApp;
        newApp.appId = _appId;
        newApp.name = _name;
        newApp.tagLine = _tagLine;
        newApp.description = _description;
        newApp.icon = _icon;
        newApp.apkFile = _apkFile;
        newApp.iosFile = _iosFile;
        newApp.images = _images;
        
        idToApp[_appId] = newApp;
        userApps[msg.sender].push(_appId);
        allApps.push(_appId);
        emit NewApp(newApp);
    }
    
    function getApplications() public view returns(bytes32[] memory) {
        return allApps;
    }
    
    function getUserApplications() public view returns(bytes32[] memory) {
        return userApps[msg.sender];
    }
    
    function getAppDetails(bytes32 _appId) public view returns(App memory) {
        return idToApp[_appId];
    }
    
    function getAppImages(bytes32 _appId) public view returns(string[] memory) {
        return idToApp[_appId].images;
    }
    
}