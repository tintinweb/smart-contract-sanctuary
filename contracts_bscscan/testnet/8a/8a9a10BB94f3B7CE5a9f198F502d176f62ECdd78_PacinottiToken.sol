pragma solidity >=0.8.0 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";
//SPDX-License-Identifier: UNLICENSED
/**
* @title PacinottiToken is an amazing ERC20 Token
*/

    struct antiwhale {
      uint256 selling_treshold;
      uint256 extra_tax;
    }
    
contract PacinottiToken is ERC20, Ownable{

antiwhale[3] public antiwhale_measures;


    /**
    * @dev assign totalSupply to account creating this contract
    */
    constructor()  ERC20("PacinottiToken","PAC"){
        _mint(msg.sender, 10**9 * 10**18);
        
        antiwhale_measures[0] = antiwhale({selling_treshold: 25, extra_tax: 25});
        antiwhale_measures[1] = antiwhale({selling_treshold: 50, extra_tax: 50});
        antiwhale_measures[2] = antiwhale({selling_treshold: 100, extra_tax: 75});
    }
    
}