/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

pragma solidity 0.6.12;

contract DVT2 {
    uint secret;
    address payable owner;
    
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public gift;
    mapping(address => uint) public isbet;
    
    event SendFlag(string b64email);
    
    function DvT2() public{
        owner = msg.sender;
    }
    
    function payforflag(string memory b64email) public {
        require(balanceOf[msg.sender] >= 100000);
        balanceOf[msg.sender]=0;
        owner.transfer(address(this).balance);
        emit SendFlag(b64email);
    }
    
    
    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }
    
    function setsecret(uint secretrcv) public only_owner {
        secret=secretrcv;
    }
    
    function deposit() public payable{
        uint geteth=msg.value/1000000000000000000;
        balanceOf[msg.sender]+=geteth;
    }
    
    function profit() public {
        require(gift[msg.sender]==0);
        gift[msg.sender]=1;
        balanceOf[msg.sender]+=1;
    }
    
    function betgame(uint secretguess) public {
        require(balanceOf[msg.sender]>0);
        balanceOf[msg.sender]-=1;
        if (secretguess==secret)
        {
            balanceOf[msg.sender]+=2;
            isbet[msg.sender]=1;
        }
    }
    
    function doublebetgame(uint secretguess) public only_owner{
        require(balanceOf[msg.sender]-2>0);
        require(isbet[msg.sender]==1);
        balanceOf[msg.sender]-=2;
        if (secretguess==secret)
        {
            balanceOf[msg.sender]+=2;
        }
    }

}