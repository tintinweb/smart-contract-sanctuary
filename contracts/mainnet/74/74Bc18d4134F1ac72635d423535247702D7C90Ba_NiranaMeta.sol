/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

pragma solidity ^0.5.0;

 interface ERC20 {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value)external;
    function balanceOf(address receiver)external returns(uint256);
}
 interface USDT20 {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value)external;
    function balanceOf(address receiver)external returns(uint256);
}
contract NiranaMeta{
    address public owner;
    address public MNUerc20;
    address public USDTerc20;
    uint256 public pice;
    modifier onlyOwner() {
        require(owner==msg.sender, "Not an administrator");
        _;
    }
     constructor(address _MNUaddress,address _USDTaddress)public{
         owner=msg.sender;
        //MNU=address(0x48fbff00e8ebc90c118b44b3d96b915e48656a73);
         //USDT=address(0xdac17f958d2ee523a2206206994597c13d831ec7);
        MNUerc20=_MNUaddress;
        USDTerc20=_USDTaddress;
         pice=50000;
     }
     function buy(uint256 _value)public{
         require(_value>1000000);
         uint256 amount=_value/pice*1 ether;
         USDT20(USDTerc20).transferFrom(msg.sender,address(this),_value);
         ERC20(MNUerc20).transfer(msg.sender,amount);
     }
    function withdrawMNU(uint256 amount) onlyOwner public {
        ERC20(MNUerc20).transfer(msg.sender,amount);
    }
    function withdrawUSDT(uint256 amount) onlyOwner public {
        ERC20(USDTerc20).transfer(msg.sender,amount);
    }
}