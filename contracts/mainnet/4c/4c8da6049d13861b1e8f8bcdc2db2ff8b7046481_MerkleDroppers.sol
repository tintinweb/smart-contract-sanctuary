/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

//SPDX-License-Identifier: 0BSD

pragma solidity ^0.8.1;

interface IERC20 {
    
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function approve(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    
}

contract MerkleDroppers {
    
    mapping(uint => uint) redeemed;
    mapping(uint => uint) redeemed2;
    bytes32 rootHash = 0x9bc1f94f838eba372fa3057e1e62c1ca9d5b41a097ae6fb60ca4517a0be70c23;
    bytes32 rootHash2 = 0x0;
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function changeOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
    
    function changeRootHash(bytes32 newRootHash) public {
        require(msg.sender == owner);
        rootHash2 = newRootHash;
    }
    
    function redeem(uint256 index, address recipient, uint256 amount, bytes32[] memory merkleProof) public {
        require(redeemed[index] == 0, "already redeemed");
        redeemed[index] = 1;
        bytes32 node = keccak256(abi.encode(index, recipient, amount));
        uint256 path = index;
        for (uint16 i = 0; i < merkleProof.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(abi.encode(merkleProof[i], node));
            } else {
                node = keccak256(abi.encode(node, merkleProof[i]));
            }
            path /= 2;
        }
        require(node == rootHash, "invalid parameters");
        IERC20(0x2De27D3432d3188b53B02137E07B47896D347D45).transferFrom(0x6CBE9E9e7A4FBbB0AafB065dAE308633c19D1c6D, recipient, amount);
    }
    
    function redeem2(uint256 index, address recipient, uint256 amount, bytes32[] memory merkleProof) public {
        require(redeemed2[index] == 0, "already redeemed");
        redeemed2[index] = 1;
        bytes32 node = keccak256(abi.encode(index, recipient, amount));
        uint256 path = index;
        for (uint16 i = 0; i < merkleProof.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(abi.encode(merkleProof[i], node));
            } else {
                node = keccak256(abi.encode(node, merkleProof[i]));
            }
            path /= 2;
        }
        require(node == rootHash2, "invalid parameters");
        IERC20(0x2De27D3432d3188b53B02137E07B47896D347D45).transferFrom(0xcc984caE87bC0F744c65ddB579e73F76256F89B2, recipient, amount);
    }
    
}