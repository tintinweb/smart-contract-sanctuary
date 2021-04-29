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

contract TokenSale{
    address admin;
    BlingToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);

   constructor(BlingToken _tokenContract, uint256 _tokenPrice) public{
       // initialize admin
       admin = msg.sender;
       tokenContract = _tokenContract;
       // add token contarctbuyToken
       tokenPrice = _tokenPrice;

   }

   function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

   function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value >= multiply(_numberOfTokens, tokenPrice),"value valid");
        require(tokenContract.transferFrom(admin,msg.sender, _numberOfTokens),"transfer valid");

        tokensSold += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
    }

    


}