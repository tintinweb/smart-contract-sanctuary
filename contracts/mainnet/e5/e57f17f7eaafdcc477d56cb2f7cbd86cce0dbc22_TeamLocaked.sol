/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

pragma solidity ^0.4.26;

contract Token{
    function transfer(address _to,uint256 _val) returns(bool success);
    function balanceOf(address _owner) constant returns(uint256 balance);
}

contract TeamLocaked{
    string public name = "tea TeamLocaked";
    address beneficiary = 0xF869F8BE0f5C5376bE93ef6A47e97bef25195E5F;
    Token public token = Token(0x5dCEd3c2fab61E21B25177c6050D3f166f696110);

    /*
         分期 分期转账操作
    */

    uint256 internal transferToken = 0;
    uint256 ReleaseTime = 1640224800;  //2021-12-23 10:00:00
    uint256 NextTime = 2592000;  // 30day
    uint internal num = 0;



      function release() public {
        require(block.timestamp > ReleaseTime,"No release time");
        uint256 totalTokenBalance = token.balanceOf(this);
        require(totalTokenBalance>0,"The balance is zero");
        if(transferToken == 0){
             transferToken = token.balanceOf(this) / 5;
        }

        require(totalTokenBalance >= transferToken, "Lack of balance");
        if(num >= 4){
            token.transfer(beneficiary,totalTokenBalance);
        }else if(token.transfer(beneficiary,transferToken)){
            ReleaseTime += NextTime;
            num++;
        }
    }

    function RemainingNum() public constant returns (uint256 remainingNum){
        return 5-num;
    }

    function getReleaseTime() public constant returns(uint256 timestamp){
        return ReleaseTime;
    }

    function getBlockTime() public constant returns(uint256 timestamp){
        return block.timestamp;
    }

    function waitReleaseTime() public constant returns(uint256 timestamp){
        if(block.timestamp < ReleaseTime){
            return ReleaseTime - block.timestamp;
        }else{
            return 0;
        }
    }

    function getTokenLocakedNum()public constant returns(uint256 amount){
        return token.balanceOf(this)/10**18;
    }

    function () external payable{
        if(token.balanceOf(this) == 0){
            if (this.balance>0){
                beneficiary.transfer(this.balance);
            }
        }else{
            if (this.balance>0){
                beneficiary.transfer(this.balance);
            }
            release();
        }
    }

}