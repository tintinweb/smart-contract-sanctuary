/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.6;

 

 
  contract AnoToken {
      
    string public name = "AnoToken";
    string public symbol = "ANT";
    uint256 public totalSupply = 1000000000000000000000000000000000; 
    uint8 public decimals = 18;
    uint256 fee_marketing =0; 
    uint256 fee_dev =0; 
    uint256 fee_charity=0;
    uint256 fee_burn =0; 
    address private owner;
 
 
    
    /////////////////////////////////////////
    /////// Check adress of the buyer  /////
 
   function isContract(address addr) internal view returns (bool) {
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    bytes32 codehash;
    assembly {
        codehash := extcodehash(addr)
    }
    return (codehash != 0x0 && codehash != accountHash);
    }
 
  
  
 
  
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  
   
    /////////////////////////////////////////
    ////// get curent balance of token /////
    
    function getBalance(
    ) public view returns(uint256){
        return owner.balance;
    }
 
  
    /////////////////////////////////////////
    ////// get sender adress //////////////
    
   function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
     
     

 
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
     
     
     /////////////////////////////////////////////
    ////// differents wallets adress //////////////

    address marketing_wallet = address(0xB83CF0D9F9f375A1a4E936927ce4E657623C7e47);
    address charity_wallet = address(0xeBc92462e24a4878D7DC02564655e8b2f1d84151);
    address dev_wallet = address(0x1a2050f096719dAc6d19bCEfe96B6E66409eb992);
    address burn = address(0x000000000000000000000000000000000000dEaD);
    uint256 limit = 0;
    bool put_fee = true;
   
   
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        
       require(isContract(_to), "Address: call to non-contract");
         
        /////////////////////////////////////////////
       ////// redistribution fees  total 10% ///////
       
        fee_marketing = (_value / 100) * 3; // 3% for marketing
        fee_dev = (_value / 100) * 2;  // 2% for dev
        fee_charity = (_value / 100) * 1;  // 1% for charity
        fee_burn = (_value / 100) * 4;     // 4% for burn
        
         
         
         if((_msgSender()==marketing_wallet)||(_msgSender()==charity_wallet)||(_msgSender()==dev_wallet)){
           put_fee = false;
         }
         
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        
        balanceOf[marketing_wallet] += fee_marketing; 
        balanceOf[dev_wallet] += fee_dev; 
        balanceOf[charity_wallet] += fee_charity; 
        balanceOf[burn] += fee_burn; 
        
        if(put_fee==true){
        balanceOf[_to] += (_value - fee_marketing - fee_charity - fee_dev - fee_burn); 
        }
        else{
         balanceOf[_to] += (_value);   
        }
        
        
        ///////////////////////////////////////////
        ////// Function Anti whale   //////////////
       /** 
        _____    _____/  |_|__| __  _  _|  |__ _____  |  |   ____  
        \__  \  /    \   __\  | \ \/ \/ /  |  \\__  \ |  | _/ __ \ 
         / __ \|   |  \  | |  |  \     /|   Y  \/ __ \|  |_\  ___/ 
        (____  /___|  /__| |__|   \/\_/ |___|  (____  /____/\___  >
             \/     \/                       \/     \/          \/  
       impossible to buy more then 2.5% of the supply
       **/
        
        limit =  1000000000000000/40;
       
      
        if(_value<=limit){
        
        if(put_fee==true){   
        emit Transfer(msg.sender, marketing_wallet, fee_marketing);
        emit Transfer(msg.sender, dev_wallet, fee_dev);
        emit Transfer(msg.sender, marketing_wallet, fee_marketing);
        emit Transfer(msg.sender, burn, fee_burn);
        }
        
        emit Transfer(msg.sender, _to, _value);
        return true;
       

        }
        else{
        return false; 
        }
        
    }
    
    

    
    
      ///////////////////////////////////////////
      ////// Function approve and transfert /////
    
    

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