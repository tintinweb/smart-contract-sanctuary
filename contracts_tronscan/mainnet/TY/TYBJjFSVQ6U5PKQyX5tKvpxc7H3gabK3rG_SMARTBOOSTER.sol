//SourceUnit: smartbooster.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract SMARTBOOSTER {

    address private owner;
    uint256 tipo1 = 100000000;
    uint256 pt1_1 = 76000000;
    uint256 pt1_2 = 85000000;
    
    uint256 tipo2 = 300000000;
    uint256 pt2_1 = 228000000;
    uint256 pt2_2 = 256000000;
    
    uint256 tipo3 = 500000000;
    uint256 pt3_1 = 380000000;
    uint256 pt3_2 = 427000000;
    
    uint256 tipo4 = 1000000000;
    uint256 pt4_1 = 760000000;
    uint256 pt4_2 = 855000000;
    
    uint256 tipo5 = 2000000000;
    uint256 pt5_1 = 1520000000;
    uint256 pt5_2 = 1710000000;
    
    uint256 tipo6 = 5000000000;
    uint256 pt6_1 = 3800000000;
    uint256 pt6_2 = 4275000000;
    uint256 fee   = 5;
    
  
    struct Users {
        address wallet;
        uint256 saldo;    
        uint256 ipn;
        uint256 tipo_pend;
        uint256 ap_pend;
        string  refer;   
    } 
    
    mapping(uint256 => Users) public acreedor;
    
    
     constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }
    

    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event retencion(address wallet, uint256 comi);
    event noregister(uint256 refer, string deta);
    
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
     modifier vali_regi(uint256 user_id) {
            require(acreedor[user_id].wallet !=  msg.sender);
            _;
     }
    
    /**
     * @dev Set contract deployer as owner
     */
     
     function registred(uint256  id_user) internal{

                 if(acreedor[id_user].ipn == 0)
                 {
                   acreedor[id_user].wallet =  msg.sender ;
                   acreedor[id_user].saldo = 0;
                   acreedor[id_user].ipn = 1;
                   acreedor[id_user].ap_pend = 0;
                   acreedor[id_user].tipo_pend = 0; 
                   acreedor[id_user].refer = '';
                 }
                
     } 
     
  
     function buy(uint256 user,  uint256 producto ) payable public{
           uint256 precio = price(producto);
           require(msg.value == precio);
           registred(user);
           acreedor[user].tipo_pend = producto; 
           acreedor[user].ap_pend = 1;
     }
     
     
     function paynow_pend(uint256 refer, uint256 producto, uint256 ap, uint256  posi) payable public isOwner{
           
     
               if(acreedor[refer].ipn == 1)
                     {
                       uint256  comi = comision(producto, posi);
                        if(ap == 1)
                       {
                           payable(acreedor[refer].wallet).transfer( acreedor[refer].saldo + comi);
                           acreedor[refer].saldo = 0;
                       }else{
                           acreedor[refer].saldo = acreedor[refer].saldo + comi;
                           emit retencion(acreedor[refer].wallet, comi);
                       }
                   }else{
                       emit noregister(refer,'user no registrado');
                   }
           
     }
     
     function comision(uint256 prod, uint posi) internal view returns (uint256 res){
         
              if(prod == 1)
              {
                    if(posi == 1)
                       res =  pt1_1;
                 if(posi == 3)
                       res =  pt1_2;
              }
              
               if(prod == 2)
              {
                   if(posi == 1)
                       res =  pt2_1;
                   if(posi == 3)
                       res =  pt2_2;
              }
              
                 if(prod == 3)
              {
                   if(posi == 1)
                       res =  pt3_1;
                    if(posi == 3)
                       res =   pt3_2;
              }
              
                 if(prod == 4)
              {
                   if(posi == 1)
                      res =   pt4_1;
                   if(posi == 3)
                      res =   pt4_2;
              }
              
                 if(prod == 5)
              {
                     if(posi == 1)
                      res =   pt5_1;
                    if(posi == 3)
                      res =  pt5_2;
              }
              
                 if(prod == 6)
              {
                    if(posi == 1)
                       res =   pt6_1;
                    if(posi == 3)
                       res =   pt6_2;
                  
              }
              
             return res;
             
     }

     
     function price(uint256  tipo) public view returns(uint256 prices){
         
          if(tipo == 1) prices = tipo1;
          if(tipo == 2) prices = tipo2;
          if(tipo == 3) prices = tipo3;
          if(tipo == 4) prices = tipo4;
          if(tipo == 5) prices = tipo5;
          if(tipo == 6) prices = tipo6;
          return prices;
     }
     
     
      function saldo_contrato() view public returns(uint256){
          uint256 saldo = address(this).balance;
          return saldo;
      }

     
     
      function send_fondos() public payable isOwner {
          payable(owner).transfer(address(this).balance);
      }
      
     
 
}