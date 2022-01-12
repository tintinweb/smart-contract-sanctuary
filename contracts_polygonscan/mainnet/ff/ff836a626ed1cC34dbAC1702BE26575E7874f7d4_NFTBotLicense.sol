pragma solidity ^0.8.0;

import './Ownable.sol';

contract NFTBotLicense is Ownable {

    

    


    struct User {
        uint256 timestamp;
        address delegate;
        bool licensed;
    }

    mapping(address => User) profiles;

    function collectRoyalty(uint256 amount) public onlyOwner {
        require(address(this).balance >=amount);
       (bool success, ) = msg.sender.call{value:amount}("");
       require(success,'Transfer Failed');
    }

    function renewLicense() external payable {
        
        User memory profile;
        profile = profiles[msg.sender];
        uint256 number_days = msg.value/(1 ether);
        if( profile.timestamp >= uint256(block.timestamp) ){
            uint256 newStamp = profile.timestamp + number_days*uint256(1 days);
            profile.timestamp = newStamp;
            profiles[msg.sender]=profile;
     
            return;
        }
        else {
            require(msg.value >= 2 ether, "Must purchase at least 20 days at once.");
            profile.timestamp = uint256(block.timestamp)+number_days*uint256(1 days);
            profile.licensed = true;
            profiles[msg.sender]=profile;
         
        }
    }
    
    function delegateAddress(address _delegate) external {
        require(_delegate!= address(0),"Cannot send to zero address");
        User memory profile;
        profile = profiles[msg.sender];
        require(profile.licensed,"Must hold a license to delegate");
        require(profile.timestamp > uint256(block.timestamp),"License has expired");
        profile.delegate = _delegate;
        profiles[msg.sender] = profile;
        return;
    }

    function isLicensed(address user) external view returns (bool) {
        User memory profile;
        profile = profiles[user];
        if (profile.licensed) {
            if (profile.timestamp >= uint256(block.timestamp)){
                return true;
            } else{
            return false;}
        }
        else{
            return false;
        }
    }

    function checkDelegation(address delegate,address licenseHolder) external view returns (bool) {
        User memory profile;
        profile = profiles[licenseHolder];
        if(profile.delegate==delegate){

            if(profile.timestamp < block.timestamp){
                return false;
            }else{
            return true;}
            }
        else{
            return false;
        }    
    }

    function getTimestamp(address account) external view returns (uint256) {
        User memory profile;
        profile = profiles[account];
        return profile.timestamp;
    }

    
}