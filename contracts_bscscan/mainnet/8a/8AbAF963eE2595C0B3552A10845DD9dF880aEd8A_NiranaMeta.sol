/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-30
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
    address public MNUerc20;
    uint256 public uidUSDT;
    uint256 public uidETH;
    uint256 public uidMNU;
    uint256 public InuidUSDT;
    uint256 public InuidETH;
    uint256 public InuidMNU;
    mapping(uint256=>uint256)public BridgesUSDT;
    mapping(uint256=>uint256)public BridgesETH;
    mapping(uint256=>uint256)public BridgesMNU;
    mapping(uint256=>address)public BridgesAddressUSDT;
    mapping(uint256=>address)public BridgesAddressETH;
    mapping(uint256=>address)public BridgesAddressMNU;
    modifier onlyOwner() {
        require(owner==msg.sender, "Not an administrator");
        _;
    }
     constructor(address _MNUaddress,address _USDTaddress)public{
         owner=msg.sender;
        //MNU=address(0x48fbff00e8ebc90c118b44b3d96b915e48656a73);
         //USDT=address(0xdac17f958d2ee523a2206206994597c13d831ec7);
         uidUSDT=1;
         uidETH=1;
         uidMNU=1;
         InuidUSDT=1;
         InuidETH=1;
         InuidMNU=1;
        USDTerc20=_USDTaddress;
        MNUerc20=_MNUaddress;
     }
     receive() external payable {}
     function BridgeUSDT(address addr,uint256 _value)public{
         //uint256 value=_value*1000000000000;
         USDT20(USDTerc20).transferFrom(msg.sender,address(this),_value);
         BridgesUSDT[uidUSDT]=_value;
         BridgesAddressUSDT[uidUSDT]=addr;
         uidUSDT++;
     }
     function BridgeMNU(address addr,uint256 _value)public{
         USDT20(MNUerc20).transferFrom(msg.sender,address(this),_value);
         BridgesMNU[uidMNU]=_value;
         BridgesAddressMNU[uidMNU]=addr;
         uidMNU++;
     }
     function BridgeETH(address addr)payable public{
         //USDT20(USDTerc20).transferFrom(msg.sender,address(this),_value);
        BridgesETH[uidETH]=msg.value;
        BridgesAddressETH[uidETH]=addr;
         uidETH++;
     }
    function withdrawUSDT(address payable addr,uint256 amount) onlyOwner public {
        USDT20(USDTerc20).transfer(addr,amount);
        InuidUSDT++;
    }
    function withdrawMNU(address payable addr,uint256 amount) onlyOwner public {
        USDT20(MNUerc20).transfer(addr,amount);
        InuidMNU++;
    }
    function withdraw(address payable addr,uint256 amount) onlyOwner public {
         addr.transfer(amount);
         InuidETH++;
    }
    function getUSDT(uint uid)public view returns(uint256,address,uint256){
        return (uidUSDT,BridgesAddressUSDT[uid],BridgesUSDT[uid]);
    }
    function getETH(uint uid)public view returns(uint256,address,uint256){
        return (uidETH,BridgesAddressETH[uid],BridgesETH[uid]);
    }
    function getMNU(uint uid)public view returns(uint256,address,uint256){
        return (uidMNU,BridgesAddressMNU[uid],BridgesMNU[uid]);
    }
}