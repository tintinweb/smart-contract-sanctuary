/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// get the owner of NFT
interface ERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}


function isNftOwner(address nft, uint256 tokenid, address owner) view returns (bool) {
    address addr = ERC721(nft).ownerOf(tokenid);
    return addr == owner;
}

function min(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}


/** 
 * @title RedPacket
 * @dev put some money in NFT.
 * 
 * V3: add contract fee. min(0.001 eth, value*0.001)
 * V4: support secret packet
 */
contract RedPacket {
    address feeOwner;
    uint256 feeValue;
    
    struct Packet {
        bool seald;  // if true, the envelope can't modify.
        bool secret; // if true, hide the value  
        uint value;  // the money stored in.
    }
    
    // nft address => token-id  => envelope
    mapping(address => mapping(uint256 => Packet)) packets;
    
    // get owner 
    constructor()  {
        feeOwner = msg.sender;
    }

    // put money in NFT
    function send(address payable nft, uint256 tokenid, bool secret) public payable {
        // get owner of the 
        address owner = msg.sender;
        Packet memory env = packets[nft][tokenid];
        
        // validate
        require(!env.seald, "sealed envelope can't modify.");
        require(isNftOwner(nft, tokenid, owner), "only nft owner can store money.");
        
        // save state
        packets[nft][tokenid] = Packet(true, secret, msg.value);
    }
  
    // get money from NFT
    function open(address payable nft, uint256 tokenid) public {
        // get owner of the 
        address owner = msg.sender;
        Packet memory env = packets[nft][tokenid];
        
        // validate
        require(env.seald, "it's not a valid envelope.");
        require(isNftOwner(nft, tokenid, owner), "only nft owner can withdraw money.");
        
         // get fee
        uint256 fee = min(0.001 ether, env.value/1000);
        uint256 value = env.value - fee;
        
        // unpack envelope
        feeValue += fee;
        packets[nft][tokenid] = Packet(false, false, 0);
        
        // return money to the owner
        payable(owner).transfer(value);
        
        // assert 
        assert(env.value >= fee);
    }
    
    function peep(address nft, uint256 tokenid) public view returns(Packet memory) {
        Packet memory env = packets[nft][tokenid];
        if (env.secret && !isNftOwner(nft, tokenid, msg.sender))  {
            env.value = 0;
        }
        return env;
    }
    
    // withdraw owner fee
    function withdrawFee() public {
        require(feeOwner == msg.sender, "only contract owner can withdraw");
        require(feeValue > 0, "no fee no withdraw");
        
        require(address(this).balance >= feeValue);
        
        uint256 value = feeValue;
        
        // do withdraw
        feeValue = 0;
        payable(feeOwner).transfer(value);
        
        // assert
        assert(feeValue == 0);
    }
    
    // get fees 
    function getFeeValue() public view returns(uint256) {
        require(feeOwner == msg.sender, "only contract owner can see fee value");
        
        // return fees
        return feeValue;
    }
}