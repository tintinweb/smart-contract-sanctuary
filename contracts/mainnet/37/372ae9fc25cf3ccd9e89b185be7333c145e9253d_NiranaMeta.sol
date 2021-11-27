/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

pragma solidity >=0.6.0 <0.8.0;
 interface USDT20 {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value)external;
    function balanceOf(address receiver)external returns(uint256);
}
contract NiranaMeta{
    address public owner;
    address public USDTerc20;
    uint256 public uidUSDT;
    uint256 public uidETH;
    mapping(uint256=>uint256)public BridgesUSDT;
    mapping(uint256=>uint256)public BridgesETH;
    mapping(uint256=>address)public BridgesAddress;
    modifier onlyOwner() {
        require(owner==msg.sender, "Not an administrator");
        _;
    }
     constructor(address _USDTaddress)public{
         owner=msg.sender;
        //MNU=address(0x48fbff00e8ebc90c118b44b3d96b915e48656a73);
         //USDT=address(0xdac17f958d2ee523a2206206994597c13d831ec7);
         uidUSDT=1;
         uidETH=10000000000000000000000;
        USDTerc20=_USDTaddress;
     }
     receive() external payable {}
     function BridgeUSDT(uint256 _value)public{
         USDT20(USDTerc20).transferFrom(msg.sender,address(this),_value);
         BridgesUSDT[uidUSDT]=_value;
         BridgesAddress[uidUSDT]=msg.sender;
         uidUSDT++;
     }
     function BridgeETH()payable public{
         //USDT20(USDTerc20).transferFrom(msg.sender,address(this),_value);
        BridgesETH[uidETH]=msg.value;
        BridgesAddress[uidETH]=msg.sender;
         uidETH++;
     }
    function withdrawUSDT(address payable addr,uint256 amount) onlyOwner public {
        USDT20(USDTerc20).transfer(addr,amount);
    }
    function withdraw(address payable addr,uint256 amount) onlyOwner public {
         addr.transfer(amount);
    }
    function getUSDT(uint uid)public view returns(uint256,address,uint256){
        return (uidUSDT,BridgesAddress[uid],BridgesUSDT[uid]);
    }
    function getETH(uint uid)public view returns(uint256,address,uint256){
        return (uidETH,BridgesAddress[uid],BridgesETH[uid]);
    }
}