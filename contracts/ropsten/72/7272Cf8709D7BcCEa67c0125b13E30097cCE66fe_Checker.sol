/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

/**
1.返回合约地址
2.返回合约创建者的地址
3.返回发送人的地址
4.返回合约的余额
5.返回合约制定者的余额（仅在你为该合约所有者的前提下）
6.返回发送人的余额

7.获取合约的某个erc20代币余额
8.获取发送者某个erc20代币余额
9.提现合约里的ETH
10.提现合约里的erc20代币
 */

pragma solidity ^0.5.16;

//erc20的标准接口
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Checker {

    address payable owner;

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(owner == msg.sender, "only owner can do");
        _;
    }
    //返回合约地址(是用this还是address(this)):0.5.16要用address(this)
    function getContractAddress() public view returns(address){
        return address(this);
    }
    //返回合约创建者的地址
    function getOwnerAddress() public view returns(address){
        return owner;
    }
    //返回发送人的地址
    function getSenderAddress() public view returns(address){
        return msg.sender;
    }
    //返回合约的余额
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    //返回合约制定者的余额（仅在你为该合约所有者的前提下）
    function getOwnerBalance() public view onlyOwner returns(uint){
        return owner.balance;
    }
    //返回发送人的余额
    function getSenderBalance() public view returns(uint){
        return msg.sender.balance;
    }

    //获取合约的某个erc20代币余额
    function getContractERC20Balance(IERC20 token) public view returns(uint) {
        return token.balanceOf(address(this));
    }

    //获取发送者某个erc20代币余额
    function getSenderERC20Balance(IERC20 token) public view returns(uint) {
        return token.balanceOf(msg.sender);
    }
    
    //提现合约里的ETH
    function withdrawEth() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    //提现合约里的erc20代币
    function withdrawERC20(IERC20 token) public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    //获取发送方支付的ETH数量-ETH到了合约地址
    function pay() public payable returns(uint){
        return msg.value;
    }
    
    //发送方发送固定ETH到合约
    // function payAmount(uint amount) public payable {
    //     msg.sender.transfer(address(this), amount);
    // }

    //接收发送方发送的一部分ETH:只收取0.1个ETh，多余的返回
    function payAndBack() public payable {
        uint ticket = 0.1 ether;
        require(msg.value >= ticket);
        uint refundFee = msg.value - ticket;
        msg.sender.transfer(refundFee);
    }

    //合约收到ETH后自动转到owner中，消耗的gas全部由发起转账的账号支付
    function payToOwner() public payable {
        owner.transfer(msg.value);
    }

    //发送发发送代币到合约
    function payERC20(IERC20 token, uint tokenAmount) public payable {
        token.transfer(address(this), tokenAmount);
    }
    //接收发送方发送的一部分ERC20代币
    // function payERC20AndBack(IERC20 token) public payable {
    //     //表示一个精度为18的代币
    //     uint ticket = 1 ether;
    // }

    //这个方法的作用:定义了这个函数，就可以接收ETH了
    // function () external payable {
    //     owner.transfer(msg.value);
    // }

    //把合约的ERC20代币授权给某一个地址，这个地址可以操作合约的代币

    

   


}