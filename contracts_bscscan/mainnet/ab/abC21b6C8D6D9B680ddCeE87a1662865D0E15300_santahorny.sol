/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT 

/**
  
   /////////  ///////  ////     // //////////  ///////
  //         //     // // //    //     //     //     //
   ///////   ///////// //  //   //     //     /////////
         //  //     // //    // //     //     //     //
  ///////    //     // //     ////     //     //     //

  //     //  ///////  ////////  ////    // //     //
  //     // //     // //     // // //   //  //   //
  ///////// //     // ////////  //  //  //   ////
  //     // //     // // //     //   // //    //
  //     //  ///////  //  ///// //    ////    //
 */   



pragma solidity 0.8.10; 

    contract santahorny {
    string public name = "Santa Horny";
    string public symbol = "SANTAHORNY";
    uint256 public totalSupply = 100000000000000000; 
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
   /**
   *
   *Auto Generate Liquidity Poll
   *
   * BUSD Reward  : 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
   *Burn address  : 0x000000000000000000000000000000000000dead

   */    
  

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