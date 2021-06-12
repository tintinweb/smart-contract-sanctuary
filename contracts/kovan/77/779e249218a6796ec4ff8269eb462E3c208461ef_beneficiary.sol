/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// ----------------------------------------------------------------------------

// SPDX-License-Identifier: GPL-3.0

// @whoismbm

// ----------------------------------------------------------------------------

pragma solidity ^0.5.0;



contract beneficiary{
    
    event NewUser(string _name, uint _userId); // emits and event with userID and name 
    event NewPurchase(string _name, uint _purchasecount); // emits event with purchaseid
   
// ----------------------------------------------------------------------------

// global variables

// ----------------------------------------------------------------------------
  
    uint public usrcount;
    uint public purchasecount;
    address public owner;
    
// ----------------------------------------------------------------------------

// mappings 

// ----------------------------------------------------------------------------

    mapping (uint => address) public userIdToOwner;
    mapping (address => uint) public ownerToUserId;



// ----------------------------------------------------------------------------

// Structure for storing user data 

// ----------------------------------------------------------------------------
    struct User{
        uint id;
        string name;
        uint category;
        bool registered;
        uint[] purchaseIds;
        uint usrLimitCom1;
        uint usrLimitCom2;
        uint usrLimitCom3;
        uint usrLimitCom4;
    }

// ----------------------------------------------------------------------------

// Structure for storing purchase data 

// ----------------------------------------------------------------------------
    
    struct Purchase{
        uint userId;
        uint qtyCom1;
        uint qtyCom2;
        uint qtyCom3;
        uint qtyCom4;  

        uint priceCom1;
        uint priceCom2;
        uint priceCom3;
        uint priceCom4;
        
        uint totalPrice;
    }
// ----------------------------------------------------------------------------

// Structure for storing price data for different categories 

// ----------------------------------------------------------------------------
   
    struct Prices{
        mapping(uint => uint) priceCom1;
        mapping(uint => uint) priceCom2;
        mapping(uint => uint) priceCom3;
        mapping(uint => uint) priceCom4;
    }
    
// ----------------------------------------------------------------------------

// Structure for storing user data 

// ----------------------------------------------------------------------------    
    
    struct Quota{           
        mapping(uint => uint) limitCom1;
        mapping(uint => uint) limitCom2;
        mapping(uint => uint) limitCom3;
        mapping(uint => uint) limitCom4;
    }
// ----------------------------------------------------------------------------

// Objects of the above structures

// ----------------------------------------------------------------------------    
    
    User[] users;
    Purchase[] purchases;
    Prices prices;
    Quota quota;


    constructor()  public {
        usrcount = 0;
        purchasecount = 0;
        owner = msg.sender; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, " You are Unauthorized");
        _;

     }
     
// ----------------------------------------------------------------------------

// setting price for commodities per category - manual input for now in wei

// ----------------------------------------------------------------------------


    function setprice(uint _category, uint _p1, uint _p2, uint _p3, uint _p4) external onlyOwner() {
        prices.priceCom1[_category] = _p1;
        prices.priceCom2[_category] = _p2;
        prices.priceCom3[_category] = _p3;
        prices.priceCom4[_category] = _p4;

    }

// ----------------------------------------------------------------------------

// getting price for commodities per category in wei

// ----------------------------------------------------------------------------


    function getprice(uint _category) view public returns (uint, uint, uint, uint){
        return(prices.priceCom1[_category], prices.priceCom2[_category], prices.priceCom3[_category], prices.priceCom4[_category]);

    }

// ----------------------------------------------------------------------------

// setting quota for commodities per category - manual input for now

// ----------------------------------------------------------------------------


    function setquota(uint _category, uint _q1, uint _q2, uint _q3, uint _q4) external onlyOwner() {
        quota.limitCom1[_category] = _q1;
        quota.limitCom2[_category] = _q2;
        quota.limitCom3[_category] = _q3;
        quota.limitCom4[_category] = _q4;

    }

// ----------------------------------------------------------------------------

// getting quota for commodities

// ----------------------------------------------------------------------------


    function getquota(uint _category) view public returns(uint, uint, uint, uint){
        return(quota.limitCom1[_category], quota.limitCom2[_category], quota.limitCom3[_category], quota.limitCom4[_category]); 

    }

// ----------------------------------------------------------------------------

// create new user and emit event after creation 

// ----------------------------------------------------------------------------


    function _createUser(address _userAddress, string calldata _name, uint _category) external onlyOwner() {

        usrcount++ ;
        uint[] memory emptyArray;
        User memory tmpUser = User (usrcount, _name, _category, true,emptyArray, quota.limitCom1[_category], 
                            quota.limitCom2[_category], quota.limitCom3[_category], quota.limitCom4[_category]);
                            
        users.push(tmpUser);
        userIdToOwner[usrcount] = _userAddress;
        ownerToUserId[_userAddress] = usrcount;
        emit NewUser(_name, usrcount);
    }
    
// ----------------------------------------------------------------------------

// Get user info using user Id

// ----------------------------------------------------------------------------

    function getUser(uint _id) public view returns( uint, string memory, uint, uint, uint, uint, uint){
        uint _i = _id -1;
        require(users[_i].registered == true,"User does not exist"); 
        return(users[_i].id, users[_i].name, users[_i].category, users[_i].usrLimitCom1, users[_i].usrLimitCom2, users[_i].usrLimitCom3, users[_i].usrLimitCom4);
    }

// ----------------------------------------------------------------------------

// purchase commodities 

// ----------------------------------------------------------------------------

   function getTotalPrice(uint _id, uint _qty1, uint _qty2, uint _qty3, uint _qty4) public view returns(uint){
        
        uint _i = _id-1;
       // require(userIdToOwner[_id] == msg.sender, "Wrong user Id or user does not exist");
        
        require(users[_i].usrLimitCom1 >= _qty1, "Quota exceeded for commodity 1");
        require(users[_i].usrLimitCom2 >= _qty2, "Quota exceeded for commodity 2");
        require(users[_i].usrLimitCom3 >= _qty3, "Quota exceeded for commodity 3");
        require(users[_i].usrLimitCom4 >= _qty4, "Quota exceeded for commodity 4");
        
        uint _category = users[_i].category;
        uint _totalPrice = (_qty1 * prices.priceCom1[_category]) + (_qty2 * prices.priceCom2[_category]) + 
                    (_qty3 * prices.priceCom3[_category]) + (_qty4 * prices.priceCom4[_category]);
        
        
        return _totalPrice;
        
    }


    function doPurchase(uint _id, uint _qty1, uint _qty2, uint _qty3, uint _qty4, uint _totalPrice) external returns(uint){ 
       
        uint _i = _id-1;
        require(userIdToOwner[_id] == msg.sender, "Wrong user Id or user does not exist");
        require(_totalPrice > 0, "Please purchase something to pay"); 
        users[_i].usrLimitCom1 -= _qty1;
        users[_i].usrLimitCom2 -= _qty2;
        users[_i].usrLimitCom3 -= _qty3;
        users[_i].usrLimitCom4 -= _qty4;

        uint _category = users[_i].category;

        uint _priceCom1 = prices.priceCom1[_category];
        uint _priceCom2 = prices.priceCom2[_category];
        uint _priceCom3 = prices.priceCom3[_category];
        uint _priceCom4 = prices.priceCom4[_category];

        Purchase memory tmpPurchase = Purchase(_id, _qty1, _qty2, _qty3, _qty4, _priceCom1, _priceCom2, _priceCom3, _priceCom4, _totalPrice);
        purchases.push(tmpPurchase);
        purchasecount++;
        users[_i].purchaseIds.push(purchasecount);
       
        return purchasecount;
   
    }

// ----------------------------------------------------------------------------

// get purchase info using purchase id    

// ----------------------------------------------------------------------------

    function getPurchase(uint _purchaseId) public view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint){
        uint _pid = _purchaseId - 1;
        Purchase storage _purchase = purchases[_pid];
        return (_purchase.userId, _purchase.qtyCom1, _purchase.qtyCom2, _purchase.qtyCom3, _purchase.qtyCom4,
         _purchase.priceCom1, _purchase.priceCom2, _purchase.priceCom3, _purchase.priceCom4, _purchase.totalPrice);

    }
    

    

}