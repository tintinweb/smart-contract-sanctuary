/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity ^0.6.6;
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract BatchTransfer{
    function batchTransferEth(address payable[] memory to,uint256[] memory values) payable public{//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
        //require(to.length == values.length);
        uint256 remainValue = msg.value;
        for(uint32 i=0;i<to.length;i++){
            require(remainValue >= values[i]);
            remainValue -= values[i];
            to[i].transfer(values[i]);
        }
        if(remainValue>0){
            msg.sender.transfer(remainValue);
        }
    }
    // function batchTransferErc20V0(address erc20Address,address payable[] memory to,uint256[] memory values) public{
    //这个方法不好，因为transferFrom操作比较消耗GAS,所以应该先把token划转到合约，再转账出去，批量转账3次内本方法较高，3次以上先划转的方法效率高
    //     //require(to.length == values.length);
    //     IERC20 erc20Token = IERC20(erc20Address);
    //     for(uint32 i=0;i<to.length;i++){
    //         erc20Token.transferFrom(msg.sender,to[i],values[i]);
    //     }
    // }
    function batchTransferErc20(address erc20Address,address payable[] memory to,uint256[] memory values) public{
        //require(to.length == values.length);
        uint256 totalValue = 0;
        for(uint32 i=0;i<to.length;i++){
            totalValue += values[i];
        }
        
        IERC20 erc20Token = IERC20(erc20Address);
        erc20Token.transferFrom(msg.sender,address(this),totalValue);
        for(uint32 i=0;i<to.length;i++){
            erc20Token.transfer(to[i],values[i]);
        }
    }
}