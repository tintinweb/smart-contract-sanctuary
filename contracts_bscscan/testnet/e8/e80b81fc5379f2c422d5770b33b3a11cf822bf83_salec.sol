/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

//SPDX-License-Identifier: unidentified
     
    pragma solidity 0.8.6;
    
    interface IBEP20 {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}
    
    contract salec {
      IBEP20 public tokenContract;
     uint price;
       address private owner;
       constructor () {
           owner = msg.sender;
           
                         }
        
       
        function TokenSale( IBEP20 _tokenContract, uint256 _price) public {
       
        tokenContract = _tokenContract;
        price = _price;
    }

    
        
        
      event Transfer(address indexed from, address indexed to, uint tokens);
      function transfer( address to, uint tokens) public returns(bool success){
          tokens += tokens;
                        emit Transfer(owner, to, tokens);
                        require (tokenContract.transfer(to,tokens));
            
            return true;
          
      }
            
        }