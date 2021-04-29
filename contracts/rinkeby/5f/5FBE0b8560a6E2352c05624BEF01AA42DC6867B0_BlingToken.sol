/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity >=0.5.16;

contract BlingToken{
    //name
    string public name = 'Bling Token';
    //symbol
    string public symbol = '*Bling*';
    address admin;
    uint256   public totalSupply;
    mapping(address => uint256) public balanceOf;  

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initialSupply) public {
        // assign tokens to an admin account
        admin = msg.sender;
        balanceOf[admin] = _initialSupply;
        //initialize totoal supply of token
          totalSupply = _initialSupply;
          // allocate initial supply
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        // exception if account doesnt have enough balance
        require(balanceOf[msg.sender] >= _value);
        // transfer the balance
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        //trigger event
         emit Transfer(msg.sender, _to, _value);
        return true;        
    }

    //deligate transfers
     function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    

    


}