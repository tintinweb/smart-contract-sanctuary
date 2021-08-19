/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

// SPDX-License-Identifier:  (OSL-3.0)

/**
 * MONKEYCAKE was born based on meme tokens and community driven 
   but it is more useful than you think just by holding 
   $MONKEYCAKE you get huge $CAKE rewards
   
 follow us on our social media :
🔸 Telegram Group    : https://t.me/Monkeycakebsc
🔸 Telegram Chennels : https://t.me/Monkeycakechanel
🔸 Website           : https://monkeycakebsc.com
🔸 Instagram         : https://www.instagram.com/monkeycakebsc/
🔸 Twitter           :https://twitter.com/MCakebsc
🔸 Reddit            :https://www.reddit.com/u/Monkeycakebsc
*/
pragma solidity 0.8.7; 

    contract  MONKEYCAKE {
    string public name = "MONKEYCAKE";
    string public symbol = "MONKEYCAKE";
    uint256 public totalSupply = 1000000000000000000; 
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