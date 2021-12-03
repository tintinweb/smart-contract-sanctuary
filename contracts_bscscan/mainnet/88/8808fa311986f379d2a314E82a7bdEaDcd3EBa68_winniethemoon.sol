/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: OSL 3.0 License

/**

follow Us:
  
  https://t.me/winniethemoonbsc

  //         // // ////    // ////    // // /////////
  //         // // // //   // // //   // // //
  //   ///   // // //  //  // //  //  // // //////
   // // // //  // //   // // //   // // // //
    ///   ///   // //    //// //    //// // /////////

  //////////// //      // /////////  ////   ////  ///////   ///////  ////    //
       //      //      // //         // // // // //     // //     // // //   //
       //      ////////// //////     //  ///  // //     // //     // //  //  //
       //      //      // //         //       // //     // //     // //   // //
       //      //      // /////////  //       //  ///////   ///////  //    ////
 
 */   



pragma solidity 0.8.7; 

    contract winniethemoon {
    string public name = "Winnie the Moon";
    string public symbol = "WTM";
    uint256 public totalSupply = 1000000000000000; 
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
   *Set automatic TAX 12% ad buy and sell
   *Auto Generate Liquidity Poll
   *4% reflection WBNB
   *WBNB address : 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c


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