// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";

interface IERC20 { 
   function transfer(address recipient, uint256 amount) external returns (bool); 
   function balanceOf(address account) external view returns (uint256);
} 

contract AirdropV3 is Ownable { 
   
    address private admin;  
    uint public maxRewardAmount;
    bool public isPaused = false;
     
    address public tokenAddress;  
    address public token2Address;
    uint public rewardAmount1;
    uint public rewardAmount2;
    
    mapping (address => bool) private processedRewards; 
   
     
    constructor(address _tokenAddress, address _token2Address, uint _rewardAmount1, uint _rewardAmount2,  address _admin) Ownable() {
        tokenAddress = _tokenAddress;
        token2Address = _token2Address;
        rewardAmount1 = _rewardAmount1;
        rewardAmount2 =_rewardAmount2; 
        admin = _admin;
    }  
     
    function claimReward2( bytes calldata signature) public {  
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, rewardAmount1))); 
       
        require (recoverSigner(message, signature) == admin , 'Wrong signature'); 
        require (processedRewards[msg.sender] == false, 'Reward already processed');  
        IERC20(tokenAddress).transfer(msg.sender, rewardAmount1); 
        IERC20(token2Address).transfer(msg.sender, rewardAmount2); 
        processedRewards[msg.sender] = true;  
    } 
    
    function claimReward(bytes calldata signature ) public {  
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, rewardAmount1)));  
        require (recoverSigner(message, signature) == admin , 'Wrong signature'); 
        require (processedRewards[msg.sender] == false, 'Reward already processed');  
        IERC20(tokenAddress).transfer(msg.sender, rewardAmount1); 
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
     
    function setReward1(uint _reward) public onlyOwner { 
        rewardAmount1 = _reward; 
    } 
    
    function setReward2(uint _reward) public onlyOwner { 
        rewardAmount2 = _reward; 
    }  
    
    function setToken2(address _tokenAddress) public onlyOwner { 
        token2Address = _tokenAddress; 
    } 
    
    function resetAdmin(address _admin) public onlyOwner { 
        admin = _admin; 
    }  
    
    function withdraw(  uint _amount, address _token) public  onlyOwner returns (bool){  
        IERC20(_token).transfer(msg.sender, _amount);
        return true;
    }  
       
}