/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;

 
contract NonoToken {
    string public name = "NonoToken";
    string public symbol = "NTK";
    uint256 public totalSupply = 1000000000000000; 
    uint8 public decimals = 18;
    uint256 fee_marketing =0; 
 
 
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


   
   address marketing = address(0x3cC4eAb414702D2456F2b0906d25270a436aAb05);
   
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        
        fee_marketing = (_value / 100) * 4; // Calculate 4% fee
        
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        
        balanceOf[marketing] += fee_marketing; // add the fee to the marketing balance
        
        balanceOf[_to] += (_value - fee_marketing); 
        
        emit Transfer(msg.sender, marketing, fee_marketing);
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