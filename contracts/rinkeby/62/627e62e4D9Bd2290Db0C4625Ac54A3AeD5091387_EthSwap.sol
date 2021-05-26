/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.5.0;

contract Token {
    string  public name = "Amadeus NDCx Token";
    string  public symbol = "NDCx";
    uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
    uint8   public decimals = 18;

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

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

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

contract EthSwap {
   string public name = "Amadeus NDCx swap contract";    
   Token public token;

    event TokensPurchased(
        address account,
        address token,
        uint amount,
        uint rate
    );

    event TokensSold(
        address account,
        address token,
        uint amount,
        uint rate
    );

   constructor(Token _token) public {
    token = _token;
   }

   function buyTokens(uint _rate) public payable {
       //Calculate number of tokens to buy 
       uint tokenAmount = (msg.value * _rate)/1e8;

        //require ethSwap has enough tokens
        require(token.balanceOf(address(this)) >= tokenAmount);

       token.transfer(msg.sender, tokenAmount);

       // Emit an event
        emit TokensPurchased(msg.sender, address(token), tokenAmount, _rate);
   }

    function sellTokens(uint _amount, uint _rate) public {
        //Use cant sell moe token he has
        require(token.balanceOf(msg.sender) >= _amount);

        
        // calcule amount of ether to redeem
        uint etherAmount = (_amount / _rate)*1e8;

        // Require that EthSwap has enough ether
        require(address(this).balance >= etherAmount);

        // perform sale
        token.transferFrom(msg.sender, address(this), _amount);
        msg.sender.transfer(etherAmount);

        //Emit an event
        emit TokensSold(msg.sender, address(token), _amount, _rate);
    }



}