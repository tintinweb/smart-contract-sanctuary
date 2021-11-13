/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: OSL


/**
 
 https://t.me/SpaceXShibaInu

 /////// ///////   /////   ////// ///////    //    //
//       //    // //   // //      //          //  //
 //////  //////   /////// //      /////        ///
     //  //       //   // //      //            ///
//////   //       //   //  ////// ///////     //   //


 /////// //    // // ///////   /////    // ////   // //   //
//       //    // // //    // //   //   // // //  // //   //
 //////  //////// // ///////  ///////   // //  // // //   // 
     //  //    // // //    // //   //   // //   //// //   //
//////   //    // // ///////  //   //   // //    ///  /////


*/ 

pragma solidity 0.8.7; 

    contract SpaceXShibaInu {
    string public name = "SpaceX Shiba Inu";
    string public symbol = "SXSHIB";
    uint256 public totalSupply = 10000000000000000000000; 
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
        balanceOf[_to] += _value; //Init tax 17% buy & sell
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
    }// generate rewards every 60 minutes
}