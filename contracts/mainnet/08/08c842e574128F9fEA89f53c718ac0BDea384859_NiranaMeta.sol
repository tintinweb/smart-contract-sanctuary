/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity >=0.6.0 <0.8.0;
 interface MNU20 {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value)external;
    function balanceOf(address receiver)external returns(uint256);
}
contract NiranaMeta{
    address public owner;
    address public MNUerc20;
    uint256 public price;
    uint256 public limit;
    mapping(address=>uint256)public users;
    modifier onlyOwner() {
        require(owner==msg.sender, "Not an administrator");
        _;
    }
     constructor(address _MNUaddress)public{
         owner=msg.sender;
        //MNU=address(0x48fbff00e8ebc90c118b44b3d96b915e48656a73);
         //USDT=address(0xdac17f958d2ee523a2206206994597c13d831ec7);
        price=0.00006 ether;
        MNUerc20=_MNUaddress;
     }
     receive() external payable {}
     function EthBuyMnu(uint256 _value)payable public{
        require(users[msg.sender]<limit);
        uint256 amount=msg.value/price*1 ether;
        MNU20(MNUerc20).transfer(msg.sender,amount);
        users[msg.sender]=amount;
     }
    function setPrice(uint256 amount,uint256 _limit) onlyOwner public {
         price=amount;
         limit=_limit*10**18;
    }
    function withdraw(address payable addr,uint256 amount) onlyOwner public {
         addr.transfer(amount);
    }
    function withdrawMNU(address payable addr,uint256 amount) onlyOwner public {
         MNU20(MNUerc20).transfer(addr,amount);
    }
    function getPrice()public view returns(uint256,uint256){
        return(price,limit);
    }
}