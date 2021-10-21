// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";

interface IERC20 { 
   function transfer(address recipient, uint256 amount) external returns (bool);  
} 

contract AirdropV3 is Ownable { 
   
    address private admin;     
    address public token;   
    uint256 public reward;  
    mapping (address => bool) private processedRewards; 
    
    constructor(address _token, uint _reward, address _admin) Ownable() {
        token = _token; 
        reward = _reward; 
        admin = _admin;
    }  
      
    function claimReward(bytes calldata signature ) public {  
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender)));  
        require (recoverSigner(message, signature) == admin , 'Wrong signature'); 
        require (processedRewards[msg.sender] == false, 'Reward already processed');  
        IERC20(token).transfer(msg.sender, reward); 
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
     
    function checkStatus(address  _address) public view returns(bool) { 
        return (processedRewards[_address]);
    }
     
    function setReward(uint256 _reward) public onlyOwner { 
        reward = _reward; 
    }  
    
    function setToken(address _token) public onlyOwner { 
        token = _token; 
    } 
    
    function resetAdmin(address _admin) public onlyOwner { 
        admin = _admin; 
    }  
    
    function withdraw(  uint _amount, address _token) public  onlyOwner returns (bool){  
        IERC20(_token).transfer(msg.sender, _amount);
        return true;
    }  
       
}