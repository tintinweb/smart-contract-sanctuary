// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";


contract SakuraToken is ERC20, Ownable{
    
    address public deployer;
    constructor() ERC20("sakuratoken.finance", "SKR" ) {
        _mint(msg.sender, 1000000 * (10 ** uint256(18)));
        deployer = msg.sender;
    } 
    
    function mint(address recever, uint256 numberToMint) public onlyOwner{
        _mint(recever, numberToMint);
    }
}