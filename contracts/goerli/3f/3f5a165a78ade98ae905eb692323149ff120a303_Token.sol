/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

contract Token{

    //table of who owns what
    mapping (address => uint256) public balances;

    constructor() {
        balances[0x934B80edC8ba22166DAC3A0AF994FE27C4eEa96C] = 100;
    }

    function transfer(address _to, uint256 _amount) public{
        //take the caller row in the table and decrease its value by _amount
        //make sure that msg.sender has _amount
        require(balances[msg.sender] >= _amount, "Insufficient funds");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;  
        // take the recipient row and increase it by _amount
    }

}