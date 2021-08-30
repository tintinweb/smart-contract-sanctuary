//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";

contract ERC20Accounting is ERC20 {
    address public owner;

    constructor() public ERC20('Dinar','DNR') {
        owner=msg.sender;
    }

    function setOwner(address newOwner) public{
        require(msg.sender== owner,'NOT ALLOWED');
        owner=newOwner;
    }

    function clearTokens(address[] memory users) public{
        require(msg.sender== owner,'NOT ALLOWED');
        //Burn bank tokens
        _burn(owner,balanceOf(owner));
        //Burn all tokens
        for(uint i=0;i< users.length;i++){
            _burn(users[i],balanceOf(users[i]));
        }
    }

    function mintTokens() public{
        require(msg.sender== owner,'NOT ALLOWED');
        //Mint for bank tokens
        _mint(owner,10000);
}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}