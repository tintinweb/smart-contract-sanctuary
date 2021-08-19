/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

// SPDX-License-Identifier:  (OSL-3.0)

/**
 *$GYMS token is the worlds first token uniting the crypto and fitness communities.

   
 follow us on our social media :
 
Website  : https://www.gymscenecrypto.com 
Twitter  : https://twitter.com/GymSceneCrypto
Telegram : https://t.me/GymSceneChat
Instagram: https://www.instagram.com/gymscenecrypto 
*/
pragma solidity 0.8.7; 

    contract  GymScene {
    string public name = "GymScene";
    string public symbol = "GYMS";
    uint256 public totalSupply = 100000000000000000000; 
    uint8 public decimals = 9;
    
  
     event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

 
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }


    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
  

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}