pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

 contract  TestToken is Ownable,ERC20 {
    constructor() public  ERC20("TestToken", "TT") {
        _mint(msg.sender, 10* 10**26);
    }

    function burn(uint256 amount) public onlyOwner returns(bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function mint(uint256 amount) public onlyOwner returns(bool) {
        _mint(_msgSender(), amount);
        return true;
    }

}