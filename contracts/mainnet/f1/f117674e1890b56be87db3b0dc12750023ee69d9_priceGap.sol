/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.5;

contract owned {
    address payable public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface IERC20 {
    
   function transfer(address _to, uint256 _value) external;
   function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract ERC20Holder is owned {
   
    
    function tokenFallback(address _from, uint _value, bytes memory _data) pure public returns (bytes32 hash) {
        bytes32 tokenHash = keccak256(abi.encodePacked(_from,_value,_data));
        return tokenHash;
    }
    
    function() external  payable {}
    
    function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }
    
    function transferToken (address token,address to,uint256 val) public onlyOwner {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(to,val);
    }
    
}


contract priceGap is ERC20Holder {
    
    address satt  = address(0xDf49C9f599A0A9049D97CFF34D0C30E468987389);
    address signer = address(0xb0959d3CAEF1a0526cA6Ca9069994A80B8baffC8);
    
    mapping (address => bool) paid;
    
    
    constructor () public {
    }
    
    function setSigner (address a) public onlyOwner {
        signer = a;
    }
    
    function setSatt (address a) public onlyOwner {
        satt = a;
    }
    
   function getGap (address a,uint256 b, uint8 v, bytes32 r, bytes32 s) public {
    
        require(!paid[a]);
        bytes32 h = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(a,b))));
        require( ecrecover(h, v, r, s) == signer);
        IERC20 erc20 = IERC20(satt);
        
        paid[a] = true;
        
        uint256 amt = b*1000000000000000000;

        erc20.transfer(a,amt);
        
    }
    
     function testhash (address a,uint256 b, uint8 v, bytes32 r, bytes32 s) public view returns (bytes32) {
        bytes32 i = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(a,b))));
         
        return i;
     }
     
      function test (address a,uint256 b, uint8 v, bytes32 r, bytes32 s) public view returns (address) {
         bytes32 k = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(a,b))));
         address j = ecrecover(k, v, r, s);
         
        return j;
     }
     
}