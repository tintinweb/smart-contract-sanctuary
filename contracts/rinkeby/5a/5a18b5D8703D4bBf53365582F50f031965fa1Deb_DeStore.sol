/**
 *Submitted for verification at Etherscan.io on 2021-07-09
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
        string appId;
        string apkFile;
        string iosFile;
        string[] images;
    }
    
    mapping(address => string[]) private userApps;
    
    mapping(string => App) private idToApp;
    
    string[] private allApps;

    event NewApp(string appId, string apkFile, string iosFile, string[] images);
    
    function addApplication(string memory _appId, string memory _apkFile, string memory _iosFile, string[] memory _images) public {
        require(keccak256(abi.encodePacked(_appId)) != keccak256(abi.encodePacked("")), "Cannot have empty app ID");
        require(keccak256(abi.encodePacked(_apkFile)) != keccak256(abi.encodePacked("")) 
            || keccak256(abi.encodePacked(_iosFile)) != keccak256(abi.encodePacked("")), "Cannot have empty apk or ios file");
        require(_images.length > 0 && keccak256(abi.encodePacked(_images[0])) != keccak256(abi.encodePacked("")), "Cannot have empty image list");
        App memory _newApp = idToApp[_appId];
        require(keccak256(abi.encodePacked(_newApp.appId)) != keccak256(abi.encodePacked(_appId)), "App id already available");
        
        App memory newApp;
        newApp.appId = _appId;
        newApp.apkFile = _apkFile;
        newApp.iosFile = _iosFile;
        newApp.images = _images;
        
        idToApp[_appId] = newApp;
        userApps[msg.sender].push(_appId);
        allApps.push(_appId);
        emit NewApp(_appId, _apkFile, _iosFile, _images);
    }
    
    function getApplications() public view returns(string[] memory) {
        return allApps;
    }
    
    function getUserApplications() public view returns(string[] memory) {
        return userApps[msg.sender];
    }
    
    function getAppDetails(string memory _appId) public view returns(App memory) {
        return idToApp[_appId];
    }
    
    function getAppImages(string memory _appId) public view returns(string[] memory) {
        return idToApp[_appId].images;
    }
    
}