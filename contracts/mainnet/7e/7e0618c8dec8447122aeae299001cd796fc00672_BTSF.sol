// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;


import "./ERC20.sol";
/*  
               (      (                  
      (   *   ))\ )   )\ )               
    ( )\` )  /(()/(  (()/(   )           
    )((_)( )(_))(_))  /(_)| /(  (    (   
   ((_)_(_(_()|_))   (_))_)(_)) )\ ) )\  
    | _ )_   _/ __|  | |_((_)_ _(_/(((_) 
    | _ \ | | \__ \  | __/ _` | ' \)|_-< 
    |___/ |_| |___/  |_| \__,_|_||_|/__/ 
                                      
    BTS Fans is here.
    More informations at https://fans.finance
*/


contract Token is ERC20 {

    constructor () public ERC20("BTS Fans", "BTSF") {
        _mint(msg.sender, 3500000 * (10 ** uint256(decimals())));
    }
}