/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

//SPDX-License-Identifier:UNLICENSED


pragma solidity ^0.8.0;
//ERC20 Token standard interface
interface ERC20Interface{
    // function symbol() external view returns (string memory);

    // function name() external view returns (string memory);

    // function totalSupply() external view returns(uint256);

    // function balanceOf(address tokenOwner) external view returns(uint256 balance);

    // function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    
    function transfer(address to, uint256 tokens) 
        external 
        returns (bool success);

    function approve(address spender, uint256 tokens) 
        external 
        returns(bool success);

    function transferFrom(address from, address to, uint256 tokens)
        external 
        returns(bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20Interface{
    string public name;//token name
    string public symbol;//token symbol
    uint256 public TotalSupply;//supply of tokens

    mapping(address => uint256) public BalanceOf;
    mapping(address => mapping(address => uint256)) public Allownace;
    //token details
    constructor(uint256 _initialSupply){
        name = "Snapper Token";              // token name
        symbol = "ST";                      //token symbol
        BalanceOf[msg.sender] = _initialSupply;
        TotalSupply = _initialSupply;
    }
    function transfer(address _to, uint256 _value)
        public  
        override
        returns(bool success){
          //exception if account doesn't have enough tokens
          require(BalanceOf[msg.sender] >= _value);
          //Transfer the tokens
          BalanceOf[msg.sender] -= _value; //deduct the value from msg.sender
          BalanceOf[_to] += _value;//increase the value of the receiver

          emit Transfer(msg.sender,_to,_value); //Emitting event
          return true; //return status
        }
        function approve(address _spender, uint256 _value)
        public
        override
        returns(bool success){
            Allownace[msg.sender][_spender] = _value; //update Allownace
            emit Approval(msg.sender,_spender,_value);//Emit Event
            return true;//Return status
        }
        function transferFrom(address _from,address _to, uint256 _value) 
        public
        override
        returns(bool success){
            //from has enough token
            require(_value <= BalanceOf[_from]);
            //allowance is big enough to send tokens
            require(_value <= Allownace[_from][msg.sender]);
            //update balance
            BalanceOf[_from] -=_value;
            BalanceOf[_to] += _value;

            //emit Event
            emit Transfer(_from, _to, _value);
            return true; //return status
        }

}