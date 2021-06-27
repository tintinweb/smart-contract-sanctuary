/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity >=0.4.22 <0.9.0;

contract HasanCryptoToken {
    //name
    string public name = "Hasan Token";                   //3
    //symbol 
    string public symbol = "HT";                       //3
    //standard
    string public standard = "Hasan Token v1.0";          //3
     //total supply
    uint256 public totalSupply;                          //1
    //decimal
     uint256 public decimals=18;
    // transfer event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);            //7
    //approve
    event Approval(  address indexed _owner, address indexed _spender,  uint256 _value);   //9

    // balance store in keyvalue pair
    mapping(address => uint256) public balanceOf;           //2

    //allowance
    mapping(address => mapping(address =>uint256)) public allowance;                       //10

    // constructor
    //set the total number of tokens
    //Read the total number of tokens
    constructor(uint256 _initialToken) {             //1
    //allocate the initial supply
        balanceOf[msg.sender] = _initialToken;              //2
        totalSupply = _initialToken;                        //1
    }

    //transfer
    //exception if account doesnot have enough
    //return a boolean
    //transfer event

    function transfer(address _to, uint256 _value)           //4
        public
        returns (bool success)
    {
        //exception if account doesnot have enough balance
        require(balanceOf[msg.sender] >= _value, 'you have not enough balance' );             //5  
        //deduct balance msg.sender
        balanceOf[msg.sender] -= _value;                      //6
        //add balance to sender that is _to
        balanceOf[_to] += _value;                             //6
        //triger transfer event
        emit Transfer(msg.sender, _to, _value);               //7

        return true;
    }

    //approved
    //transferForm
    //allowance

    function approve(address _spender, uint256 _value)           //8
        public
        returns (bool success)
    {
        // increase allowance

        allowance[msg.sender][_spender]+= _value;                 //10
        

        // approve event   // emit allownce event
        emit Approval(msg.sender, _spender, _value);              //9
        return true;
    }
    //transferFrom
    function transferFrom(address _from,address _to,uint256 _value) public returns(bool success){   //11
         //Require _from has enough tokens 
         require(_value <= balanceOf[_from],'user has no balance');                      //12
         //require allownace is big enough
         require(_value <= allowance[_from][msg.sender],'spender has no allowance');          //13
         //change the balance   
         balanceOf[_from] -= _value;                               //15
         balanceOf[_to] += _value;
         // update the allowance
         allowance[_from][msg.sender]-=_value;                      //16
         //emit transfer  event
         emit Transfer(_from, _to, _value);         //14
       
 
         //return a boolean
      return true;
    }
}