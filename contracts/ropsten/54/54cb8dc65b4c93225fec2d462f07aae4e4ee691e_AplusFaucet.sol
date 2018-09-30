pragma solidity ^0.4.24;

// File: contracts/faucetContracts/AplusFaucet.sol

////
contract ERC20 {
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract AplusEscrows {

    function tokensAlreadyClaimed(bytes32 dataHash, address buyer) public view returns(bool);
}

contract AplusFaucet {
    event withdrawlEvent(address indexed _sender, uint256 _value, bytes32 hash);
    
    mapping (bytes32 => mapping (address => bool)) alreadyClaimed;
    
    function withdrawl(address addr, address addrDdex, bytes32 hash) public {
         ERC20 token = ERC20(addr);
         require(!alreadyClaimed[hash][msg.sender]);
         require(hash != 0x0);
         AplusEscrows ae = AplusEscrows(addrDdex);
         require(!ae.tokensAlreadyClaimed(hash, msg.sender));
         
         alreadyClaimed[hash][msg.sender] = true;
         uint256 reward = 10 ether;
         token.transfer(msg.sender, reward);
         emit withdrawlEvent(msg.sender, reward, hash);
    }
}