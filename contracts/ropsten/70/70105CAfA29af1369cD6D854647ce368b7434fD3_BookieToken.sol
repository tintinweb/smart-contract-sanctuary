// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BEP20.sol";
import "./Ownable.sol";

contract BookieToken is BEP20, Ownable {
    uint256 private  _totalSupply = 50000000 * 10 ** 8;
    address private  minter ;

    constructor (string memory name, string memory symbol) BEP20(name, symbol) {
        _mint(msg.sender, _totalSupply);
    }
    
    function burn(uint256 amount) external  {
        _burn(msg.sender, amount);
    }

    function mint(address reciever, uint256 amount) external  {
        require(msg.sender == minter, "Unauthorized");
         _mint(reciever, amount);
    }

    function set_minter( address reciever) external onlyOwner {
        minter = reciever;
    }
      
}