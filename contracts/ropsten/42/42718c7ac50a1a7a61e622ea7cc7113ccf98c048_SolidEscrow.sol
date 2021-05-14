/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma solidity >=0.8.0;
interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract SolidEscrow{
    uint public bigbundle=70;
    uint public smallbundle=210;


    function buySmallBundle(address tokenID) public payable{
        uint smallbundle_ = smallbundle;
        require(msg.value<727000000000000*3);
        for (uint x=727000000000000;x<=msg.value;x+=727000000000000){
        IERC20(tokenID).transfer(msg.sender,40000*10**18);
        smallbundle_-=1;
        }
        smallbundle=smallbundle_;
    }
     function buyBigBundle(address tokenID) public payable{
        uint bigbundle_= bigbundle;
        require(msg.value<135000000000000000*3);
        for (uint x=135000000000000000;x<=msg.value;x+=135000000000000000){
        IERC20(tokenID).transfer(msg.sender,80000*10**18);
        bigbundle_-=1;
        }
        bigbundle=bigbundle_;

    }
    function spendeth(address payable recipient,uint amount) public{
        require(msg.sender==address(0x1Dc5810Bf9c3CB44c5DE946763402eCD5F05864c));
        recipient.transfer(amount);
    }
    function setBigBundle(uint amount) public{
        require(msg.sender==address(0x1Dc5810Bf9c3CB44c5DE946763402eCD5F05864c));
        bigbundle=amount;
    }
    function setSmallBundle(uint amount) public{
        require(msg.sender==address(0x1Dc5810Bf9c3CB44c5DE946763402eCD5F05864c));
        smallbundle=amount;
    }
    function destroy() public payable {
        require(msg.sender==address(0x1Dc5810Bf9c3CB44c5DE946763402eCD5F05864c));
        address payable addr = payable(address(0x1Dc5810Bf9c3CB44c5DE946763402eCD5F05864c));
        selfdestruct(addr);
    }
}