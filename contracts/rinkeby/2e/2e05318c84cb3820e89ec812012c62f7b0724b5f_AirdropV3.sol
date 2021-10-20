// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";

interface IERC20 { 
   function transfer(address recipient, uint256 amount) external returns (bool); 
   function balanceOf(address account) external view returns (uint256);
} 

contract AirdropV3 is Ownable { 
   
    address private admin;
    address public tokenAddress;  
    uint public maxRewardAmount;
    bool public isPaused = false;
    mapping (address => bool) private processedRewards; 
   
     
    constructor(address _tokenAddress, uint _maxRewardAmount, address _admin) Ownable() {
        tokenAddress = _tokenAddress;
        maxRewardAmount = _maxRewardAmount; 
        admin = _admin;
    }  
     
    
    function claimReward( address recipient,  uint reward, bytes calldata signature ) public {  
        bytes32 message = prefixed(keccak256(abi.encodePacked(recipient, reward))); 
        require (msg.sender == recipient, 'Wrong caller');
        require (recoverSigner(message, signature) == admin , 'Wrong signature'); 
        require (processedRewards[msg.sender] == false, 'Reward already processed'); 
        require (reward <= maxRewardAmount, 'Exceeds the reward limit' );
        require (isPaused == false, 'Airdrop is paused' ); 
        IERC20(tokenAddress).transfer(msg.sender, reward); 
        processedRewards[msg.sender] = true;  
    } 
    
    
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked( '\x19Ethereum Signed Message:\n32',   hash  ));
    }
     
    
    function recoverSigner(bytes32 message, bytes memory sig)  internal pure returns (address)  {
        uint8 v;
        bytes32 r;
        bytes32 s;
  
        (v, r, s) = splitSignature(sig); 
        return ecrecover(message, v, r, s);
    }
    

    function splitSignature(bytes memory sig)  internal  pure  returns (uint8, bytes32, bytes32) {
        require(sig.length == 65); 
        bytes32 r;
        bytes32 s;
        uint8 v;
  
        assembly { 
            r := mload(add(sig, 32)) 
            s := mload(add(sig, 64)) 
            v := byte(0, mload(add(sig, 96)))
        } 
        return (v, r, s);
    }
    
    
    function pause() public onlyOwner { 
        isPaused = true; 
    }
    
    function unpause() public onlyOwner { 
        isPaused = false; 
    }
    
    function checkStatus(address  _address) public view returns(bool) { 
        return (processedRewards[_address]);
    }
    
    function setMaxReward(uint _amount) public onlyOwner { 
        maxRewardAmount = _amount; 
    }
    
    function setToken(address _tokenAddress) public onlyOwner { 
        tokenAddress = _tokenAddress; 
    }  
    
    function resetAdmin(address _admin) public onlyOwner { 
        admin = _admin; 
    }  
    
    function withdraw(  uint _amount) public  onlyOwner returns (bool){  
        IERC20(tokenAddress).transfer(msg.sender, _amount);
        return true;
    }  
       
}