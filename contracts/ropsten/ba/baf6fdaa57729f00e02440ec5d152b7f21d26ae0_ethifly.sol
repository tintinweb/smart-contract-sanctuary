pragma solidity 0.5.1;

interface Token {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

contract ethifly{

    constructor() public{
        //owner = msg.sender;
    }
    
    function() payable external
    {
        revert();
    }
    
    function newEscrow(address _token, uint _amount) payable public returns (bool) {

    //require(msg.sender != escrowAddress);
    Token token = Token(_token);
    uint amount = _amount * 10**18; //Grab decimal directly from contract in the future
    
    require(
    token.transferFrom(
        msg.sender,
        address(this),
        (amount)
    ));  // Require the token for escrow to be sucessfully sent to contract first
    
    
    return true;

}
    function WithdrawFunds(address _token, uint amount) public
    {
        Token token = Token(_token);
        amount = amount * 10**18;
        token.transfer(msg.sender, amount);
            
    }


}