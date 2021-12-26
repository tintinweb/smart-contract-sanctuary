pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
// SPDX-License-Identifier: CC0

contract NOGWEI is ERC20, ERC20Burnable {
    constructor() ERC20("$NOGWEI", "NOGWEI") {}

    address immutable private signer = 0xc0689D9B5d4BE02e99cC44030A31c92cb5C3C9CC;
    address immutable private nftMachine = 0xaa9772d31476E85FedD1099E40dD2Ff5DEE214ff; 

    mapping (address => bool) public claimed;

    function claim(uint amount, uint8 v, bytes32 r, bytes32 s) external {
        require(claimed[msg.sender] == false, "already claimed");
        claimed[msg.sender] = true;

        bytes32 messageSig = keccak256(abi.encode(msg.sender, amount));
        require(ecrecover(messageSig, v, r, s) == signer, "invalid signature");

        _mint(msg.sender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        // "I get 5% royalties for the sick fucking ticker."
        // - https://twitter.com/NFTmachine/status/1474863928035332096

        super._transfer(sender, nftMachine, amount * 5  / 100);
        super._transfer(sender, recipient,  amount * 95 / 100);
    }
        
}