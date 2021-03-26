/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

/**
限制为 10 个用户
用户必须支付 0.1ETH 才能加入以太坊彩票
同一用户只能加入一次
合约创建者可以加入以太坊彩票
第 10 个用户进入后，选择获胜者
赢家收走所有的钱
选出获胜者之后，开始下一轮
 */

pragma solidity ^0.5.16;

contract Lottery{
    uint payFee = 0.1 ether;
    uint payUserLimit = 2;
    uint randNonce = 0;
    address payable[] betUsers;

    //获取1-10的随机数
    function getRandomNumber() internal returns(uint){
        uint rand = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % payUserLimit;
        randNonce ++;
        return rand;
    }

    //判断是否已经投注过
    function betAlready(address _userAddr) public view returns(bool) {
        for(uint i=0; i<payUserLimit; i++){
            if(betUsers[i] == _userAddr){
                return true;
            }
        }
        return false;
    }
    //下注
    function bet() public payable {
        require(msg.value == payFee, "must 0.1 ether");
        require(betUsers.length < payUserLimit, "must bet 10 user");
        require(!betAlready(msg.sender), "betAlready");
        betUsers.push(msg.sender);
        if(betUsers.length == payUserLimit){
            uint randNum = getRandomNumber();
            address payable winAddr= betUsers[randNum];
            winAddr.transfer(payFee * payUserLimit);
            delete betUsers;
        }
    }

}