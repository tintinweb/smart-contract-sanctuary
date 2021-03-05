/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

pragma solidity ^0.4.26;

contract Token{
    function transfer(address _to,uint256 _val) returns(bool success);
    function balanceOf(address _owner) constant returns(uint256 balance);
}

contract FoundationLocaked {
    string public name = "tea FoundationLocaked";
    address beneficiary = 0x79d0DEe22583a29C3070e9e5C18E99920dFFb81A;
    Token public token = Token(0x5dCEd3c2fab61E21B25177c6050D3f166f696110);

    uint256 releaseTime = 1671760800; //2022-12-23 10:00:00

    function release() public{
        require(block.timestamp > releaseTime,"No release time");
        uint256 totalTokenBalance = token.balanceOf(this);
        require(totalTokenBalance > 0 , "The balance is zero");
        token.transfer(beneficiary,totalTokenBalance);
    }


    function getReleaseTime() public constant returns(uint256 timestamp){
        return releaseTime;
    }

    function getBlockTime() public constant returns(uint256 timestamp){
        return block.timestamp;
    }

    function waitReleaseTime() public constant returns(uint256 timestamp){
        if(block.timestamp < releaseTime){
            return releaseTime - block.timestamp;
        }else{
            return 0;
        }
    }

    function getTokenNum()public constant returns(uint256 amount){
        return token.balanceOf(this)/10**18;
    }

    function ()external payable{
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