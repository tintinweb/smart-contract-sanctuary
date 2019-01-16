pragma solidity ^0.4.18;

interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract Wrapper{
   
    address constant public constAddr = 0x723f12209b9C71f17A7b27FCDF16CA5883b7BBB0;
    
   
    event TestDone();
    
    function testWrapper(ERC20 src, uint256 amount){
        require(src.transferFrom(msg.sender, constAddr, amount));
        TestDone();
    }
}