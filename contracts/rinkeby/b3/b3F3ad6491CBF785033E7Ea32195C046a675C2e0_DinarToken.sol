//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";

contract DinarToken is ERC20 {
    address bank;

    constructor() ERC20('Dinar','DNR')public{
        bank=msg.sender;
    }

    function setBank(address _bank) public{
        require(msg.sender==bank,'NOT ALLOWED');
        bank=_bank;
    }

    function reset(address[] memory holders) public{
        require(msg.sender==bank,'NOT ALLOWED');
        //Burn bank tokens
        _burn(bank,balanceOf(bank));
        //Burn other holder of the token
        for(uint i=0;i<holders.length;i++){
            _burn(holders[i],balanceOf(holders[i]));
        }
        //Mint new tokens for the bank
        _mint(bank,10000);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}