/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;


contract Storage {
    
    address payable rtrowner;
    
    uint256 minimalprice=10000000000000000;
    uint256 maximumprice=2000000000000000000;
    
    uint256 totalsupply=50000000;
    uint256 buyedtoken=0;
    uint16 currentphase=0;
    
      struct Phase  {
        uint256 tokennumber;
        uint256 price;
    }
    
    Phase[] phases;
    
    mapping(address => uint256) tokenrequesters;
    address[] users;
    
    event buyTokenReady(address useraddress, uint256 piece);

    constructor()  {
       rtrowner=payable(address(msg.sender));
        phases.push(Phase(10000000,1));
        phases.push(Phase(40000000,2));
        phases.push(Phase(50000000,3));
    }
    
    
       function getUsers(uint256 index) external view returns (address useraddress,uint256 usercount) {
            require(users.length!=0, "no user" );
              require(users.length-1>=index, "wrong index" );
            
        return (users[index],users.length);
    }
   
      function getUserTokenNumber(address useraddress) external view returns (uint256 _buyedtoken) {
        return tokenrequesters[useraddress];
    }
   
      function getCurrentTokenNumber() external view returns (uint256 _buyedtoken) {
        return buyedtoken;
    }
   
    function getCurrentPhase() external view returns (uint16 _currentphase) {
        return currentphase+1;
    }
    

    function buyToken(uint256 piece) public payable
    {
        /*
        require(msg.value >= minimalprice, "minimalprice");
       require(msg.value <= maximumprice, "maximumprice");
        */
        require(piece>0, "minimal token");
        
        require(buyedtoken+piece<=totalsupply, "not enough tokens");
       
        if (buyedtoken+piece<=phases[currentphase].tokennumber)
        {
            
             uint256 priceNeed=phases[currentphase].price*piece;
            
             require(msg.value == priceNeed, "value error");

            rtrowner.transfer(msg.value);
            
            if (tokenrequesters[msg.sender]==0)
            users.push(msg.sender);
            
            tokenrequesters[msg.sender] +=piece;
            
            buyedtoken +=piece; 
            
        }
        else
        {
            require(currentphase<2, "currentphase error");
              
            uint256 elapsedtoken=piece-((piece+buyedtoken)-phases[currentphase].tokennumber);
            
            uint256 priceNeed=phases[currentphase].price*elapsedtoken;
            
            priceNeed +=phases[currentphase+1].price*(piece-elapsedtoken);
            
            require(msg.value == priceNeed, "value error");

            rtrowner.transfer(msg.value);
            
            currentphase++;
            
            if (tokenrequesters[msg.sender]==0)
            users.push(msg.sender);
            
            tokenrequesters[msg.sender] +=piece;
            
            buyedtoken +=piece; 
        }
        
       emit buyTokenReady(msg.sender,piece);
       
    }
    
}