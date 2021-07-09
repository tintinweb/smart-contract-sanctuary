/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

pragma solidity >=0.7.0 <0.9.0;


contract LendingRoute {
    ERC20 usdc = ERC20(0xe22da380ee6B445bb8273C81944ADEB6E8450422);
    ILendingPool lendingPool = ILendingPool(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    
    
    
    function approve(address spender, uint value) external returns (bool success){
       return  usdc.approve(spender, value);
    }
    
    function allowance(address owner, address spender) external returns (uint remaining){
       return  usdc.allowance(owner, spender);
    }
    
     function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
         lendingPool.deposit(asset, amount, onBehalfOf, referralCode);
     }
  
}


interface ERC20 {
    function totalSupply()  view external returns (uint supply);
    function balanceOf(address _owner)external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface ILendingPool {
    function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
  
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

}