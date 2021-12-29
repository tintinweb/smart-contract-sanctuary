pragma solidity ^0.8.11;

// SPDX-License-Identifier: CC0

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./MerkleProof.sol";


contract Gas is ERC20, ERC20Burnable {
    constructor() ERC20("GAS", "GAS") {}

    bytes32 immutable private root = 0xcd5a6623d1a623acc60b89cfc166dddcce9b4bec4537177b6a34528b8e285251;
    mapping (address => bool) public claimed;
    uint maxSupply = 5496912050268730768228352;

    function claim(bytes32[] memory proof, uint amount) external {
        require(amount + totalSupply() <= maxSupply, "claim exceeds max supply");
        require(claimed[msg.sender] == false, "claimed already");
        claimed[msg.sender] = true;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, root, leaf), "invalid proof");
        _mint(msg.sender, amount);
    }

}