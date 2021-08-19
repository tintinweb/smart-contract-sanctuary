pragma solidity ^0.8.0;

import './ERC20.sol';
import './SafeMath.sol';

 contract GoHigher is ERC20 {
     using SafeMath for uint256;
     uint BURN_FEE = 5;
     uint TAX_FEE = 5;
     address public owner;
     mapping(address => bool) public exclidedFromTax;
     
     constructor() public ERC20('Go Higher', 'HIGHER') {
         _mint(msg.sender,220000000* 10 ** 18);
         owner = msg.sender;
         exclidedFromTax[msg.sender] = true;
     }
     
     function transfer (address recipient, uint256 amount) public override returns (bool) {
         if(exclidedFromTax[msg.sender] == true) {
             _transfer(_msgSender(), recipient, amount);
         } else {
             uint burnAmount = amount.mul(BURN_FEE) / 100;
             uint adminAmount = amount.mul(TAX_FEE) / 100;
             _burn(_msgSender(), burnAmount);
             _transfer(_msgSender(), owner, adminAmount);
             _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
         }
          return true;
     }
 }