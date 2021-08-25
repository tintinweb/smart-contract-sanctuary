/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

pragma solidity >=0.7.0 <0.9.0;
 
//SPDX-License-Identifier: UNLICENSED
 
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
}
 
contract HashupNicknames {
    mapping(address => string) addressToNick;
    mapping(string => address) nickToAddress;
    mapping(string => bool) isNicknameTaken;
    
    mapping(address => bool) isAddressLogin;
    mapping(address => bool) isAddressEarlyAdopter;
    
    address Hash = 0xecE74A8ca5c1eA2037a36EA54B69A256803FD6ea;
    uint256 gamers;
    
    uint256 earlyAdopters = 10000;
    uint256 earlyAdoptersReward = 2137; //213.7 #
    
    uint256 midAdopters = 100000;
    uint256 midAdoptersReward = 100; //10 #
    
    uint256 lateAdopters = 1000000;
    uint256 lateAdoptersReward = 10; //1 #
    
    function getHashForLogin() public view returns (uint256) {
        if(gamers < earlyAdopters) {
            //send 213.7 # to earlyAdopters
            return earlyAdoptersReward;
        } else if (gamers < midAdopters) {
            //send 10# to midAdopters
            return midAdoptersReward;
        } else if (gamers < lateAdopters) {
            //send 1# to lateAdopters
            return lateAdoptersReward;
        }
        
        //no reward
        return 0;
    }
    
    function reserveNickname(string memory nickname) public {
        //Check if new username is taken
        require(isNicknameTaken[nickname] == false, 'Nickname is already taken');
        
        //Free up current nickname if present
        isNicknameTaken[addressToNick[msg.sender]] = false;
 
        //Lock up new nickname
        isNicknameTaken[nickname] = true;
        
        //Bond address to nickname and nickname to address
        addressToNick[msg.sender] = nickname;
        nickToAddress[nickname] = msg.sender;
    }
    
    function loginToTheHashUp(string memory nickname) public {
        //Check if new username is taken
        require(isNicknameTaken[nickname] == false, 'Nickname is already taken');
        require(isAddressLogin[msg.sender] == false, "One Address one airdrop");
        
        //Lock up new nickname
        isNicknameTaken[nickname] = true;
        
        //Lock address as HashUp early adopter 
        isAddressLogin[msg.sender] = true;
        
        //Bond address to nickname and vice versa
        addressToNick[msg.sender] = nickname;
        nickToAddress[nickname] = msg.sender;
        
        gamers = gamers + 1;
        
        uint256 reward = getHashForLogin();
        if(reward != 0) {
            
            if(gamers < 10000) {
                //The first 10000 people are early adopters of free game and software market
                isAddressEarlyAdopter[msg.sender] = true;
            }
            
            //send reward to 
            IERC20(Hash).transfer(msg.sender, reward * (10 ** uint256(17)));
        } 
    }
    
    function loginToTheHashUpWithReflink(string memory nickname, address reflinkAddress) public {
        //Check if new username is taken
        require(isNicknameTaken[nickname] == false, 'Nickname is already taken');
        require(isAddressLogin[msg.sender] == false, "One Address one airdrop");
        
        //Lock up new nickname
        isNicknameTaken[nickname] = true;
        
        //Lock address as HashUp early adopter 
        isAddressLogin[msg.sender] = true;
        
        //Bond address to nickname and vice versa
        addressToNick[msg.sender] = nickname;
        nickToAddress[nickname] = msg.sender;
        
        gamers = gamers + 1;
        
        uint256 reward = getHashForLogin();
        if(reward != 0) {
            
            if(reward > 2136) {
                //The first 10000 people are early adopters of free game and software market
                isAddressEarlyAdopter[msg.sender] = true;
            }
            
            //send reward to user and reflinkAddress
            IERC20(Hash).transfer(msg.sender, reward * (10 ** uint256(17)));
            IERC20(Hash).transfer(reflinkAddress, reward * (10 ** uint256(17)));
        } 
    }
    
    function gamersCount() public view returns (uint256) {
        return gamers;
    }
    
    function HashLeft() public view returns (uint256) {
        return IERC20(Hash).balanceOf(address(this));
    }
    
    function getNickname(address user) public view returns (string memory) {
        return addressToNick[user];
    }
    
    function getAddress(string memory nickname) public view returns (address) {
        return nickToAddress[nickname];
    }
    
    function getIsAddressEarlyAdopter(address user) public view returns (bool) {
        return isAddressEarlyAdopter[user];
    }
}