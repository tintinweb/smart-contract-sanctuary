/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract swapping 
{
    address tokenv1;
    address tokenv2;
    address owner;
    bool continueswapping;
    constructor(address _tokenv1,address _tokenv2,address _owner)
    {
          tokenv1 =_tokenv1;
          tokenv2 =_tokenv2;
          owner = _owner;
          continueswapping = true;
    }
	
	function migratetoken(address token , uint256 amount) public
    {
        require(continueswapping,"Swapping closed");
        require(token==tokenv1,"Wrong address");
        require(IERC20(tokenv1).transferFrom(msg.sender,owner,amount),"error:not succes1");
        require(IERC20(tokenv2).transferFrom(owner,msg.sender,amount),"error:not succes2");
    }
    
    function changeSwappingState(bool _allowSwapping) external {
        require(msg.sender == owner,"Not Owner");
        continueswapping = _allowSwapping;
    }
    
    
}