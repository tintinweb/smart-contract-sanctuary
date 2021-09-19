pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
//BUTTPOOP was created in the stalls
//Adapted from original code written by Cheyenne Atapour
//Birthed by Steve Gartman
//Goals of BUTTPOOP below
//Get someone on TV to say “Buttpoop?” 
//Destroy FIAT
//Take control of government sanitary systems once they inevitably fail
//Redistribution of the guns to everyone under the age of 18, along with a horse, but only 50% of the guns and horses collectively work
//Free pot and/or weed for everybody 
////Make killing bees a felony
//BUTTPOOP.COM
//a Raptor Planet Production
//FLUSHED & GLEEBORKED

import "./ERC20.sol";

contract BUTTPOOP is ERC20 {

    uint FLUSH_FEE = 69;
    uint LOTTERY_FEE = 420;
    uint counter = 0;
    address public owner;

    //mapping of all holders 
    mapping(address => bool) public holders; //people's balances
    mapping(uint => address) public indexes;
    uint public topindex;

    
function gleebork() public view returns (uint256) 
{
        uint256 sum =0;
        for(uint i = 1; i <= 100; i++)
        {
            sum += uint256(blockhash(block.number - i)) % topindex;
        }
        return sum;
}
    
constructor() ERC20 ('BUTTPOOP','BTPP') {
    _mint(msg.sender, 91166642069* 10 ** 18);
    owner = msg.sender;
    holders[msg.sender] = true;
    indexes[topindex] = msg.sender;
    topindex += 1;
    }
    

    
    
function transfer(address recipient, uint256 amount) public override returns (bool){

            
            uint burnAmount = amount*(FLUSH_FEE) / 10000;
            uint lotteryAmount = amount*(LOTTERY_FEE) / 10000;
            _transfer(_msgSender(), address(this), lotteryAmount);
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(lotteryAmount));
            
            

        
      if (!holders[recipient]) 
        {
            holders[recipient] = true;
            indexes[topindex] = recipient;
            topindex += 1;
        }
        
        counter += 1;
        if (counter == 10) 
        {
        counter = 0;
        address payable winner = payable(indexes[gleebork() % topindex]);
        _transfer(address(this), winner, balanceOf(address(this)));
        }
      
      return true;
    }    


 
}