/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

contract Token {

    // table of who owns what
    mapping (address => uint256) public balances;

    constructor()  {
        balances[0xEE751F97a0C549DB4967bAE682cA36a5eBa3f6a6] = 100;
    }

    function transfer(address _to, uint256 _amount) public {
        // take the caller row in the table and decrease its value by _amount
        // make sure that msg.sender has _amount
        require(balances[msg.sender] >= _amount, "Insufficient funds");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        // take the recipient row and increase it by _amount
    }

 }