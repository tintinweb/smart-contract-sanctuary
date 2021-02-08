// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import './ERC20.sol';

contract RPToken is ERC20 {

   
    address public caller;
    address public wallet;
    address public owner;

    constructor(address _wallet) public ERC20("Royale Protocol", "RPT") {
        wallet=_wallet;
        owner=msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner || msg.sender==caller, "not authorized");
        _;
    }
    
     modifier onlyWallet(){
      require(wallet==msg.sender, "Not Authorized");
      _;
  }


   function transferOwnership(address _wallet) external onlyWallet(){
        wallet =_wallet;
    }
    
    function setCaller(address addr) external  {
        caller = addr;
    }

    function mint(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }

    function burn(address sender, uint256 amount) external onlyOwner {
        _burn(sender, amount);
    }
}