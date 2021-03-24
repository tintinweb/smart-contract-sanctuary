/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.5.17;
contract Mycontract 
{
    uint256 public numbercount=0;
    uint256 public  peoplecount=0;
   
   
    address  librarian;
    constructor(address payable _owner)public {
       librarian=_owner;
      
       
    }
    modifier onlyowner(){
        require(librarian==msg.sender);
         _;
    }
   
   
     struct  Books{
         uint ID;
         string Title;
         string Author;
         uint Edition;
         uint amount;
       
    }
  
    struct User{
        uint ID;
        string Name;
        uint Dob;
        string Dept;
        uint bookstaken;
        uint initialpayment;
        
        uint durationtime;
        uint Booksreturn;
        uint[] Bookid;
        }
        
         mapping(uint=>Books)public Bookdetails;
         mapping(uint=>User)public Userdetails;
    
         
       
    function addingbook(uint _ID,string memory _Title,string memory _Author,uint _Edition,uint _amount)public onlyowner{
         numbercount+=1;
        Bookdetails[numbercount].ID=_ID;
        Bookdetails[numbercount].Title=_Title;
        Bookdetails[numbercount].Author=_Author;
        Bookdetails[numbercount].amount=_amount;
        
    }
        
    function addusers(uint _ID,string memory _Name,uint _Dob,string memory _Dept,uint _initialpayment)public  onlyowner{
         peoplecount+=1;
    Userdetails[peoplecount].ID = _ID;
    Userdetails[peoplecount].Name = _Name;
    Userdetails[peoplecount].Dob =_Dob;
    Userdetails[peoplecount].Dept= _Dept;    
   
    Userdetails[peoplecount].initialpayment= 0;
    
    
    

     }
     
  
     function getfunction(uint _ID,uint[] memory _Id,uint _bookstaken)public  {
        
          Userdetails[_ID].ID=_ID;
          Userdetails[_ID].bookstaken= _bookstaken;  
         for(uint i=0; i<5; i++) {
          Userdetails[_ID].Bookid.push(_Id[i]);
         
          
          
         }
        
          numbercount = numbercount - _bookstaken;
       
          
     }
     
    function deposit(uint _initialpayment,uint _ID)public payable {
       require(msg.value == 30 ether, "error");
        Userdetails[_ID].initialpayment = msg.value;
        
    }
    
    function ReturnBook(uint _ID, uint[] memory _Id, uint _Booksreturn, uint _initialpayment)public{
        
       
        uint takentime;
        uint current;
        uint calculation;
        uint  fine;
        
        Userdetails[_ID].durationtime;
        current = block.timestamp;
        calculation = 1 seconds * 0.00000001 ether;
        fine = calculation * (current - takentime);
        for(uint i=0; i<5; i++) {
        Userdetails[_ID].Bookid.push(_Id[i]);
        
        Userdetails[_ID].initialpayment =Userdetails[_ID].initialpayment - fine;
      
        
            
        }
        Userdetails[_ID].Booksreturn=_Booksreturn;
         numbercount = numbercount + _Booksreturn;
        require(address(uint160(librarian)).send(fine),"Transaction failed");
    }
        
    
        
    
    
    function showBalance()public view returns(uint){
        
        return address(this).balance;
    }
}