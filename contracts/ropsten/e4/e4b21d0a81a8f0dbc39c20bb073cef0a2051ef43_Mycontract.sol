/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity ^0.5.8;
contract Mycontract 
{
    uint256  numbercount=0;
    uint256  peoplecount=0;
    uint public Totalbooks=20;
   
    address  librarian;
    constructor(address payable _owner)public {
       librarian=_owner;
       librarian==msg.sender;
       
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
        uint booktakentime;
        uint durationtime;
        uint Booksreturn;
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
        
    function addusers(uint _ID,string memory _Name,uint _Dob,string memory _Dept,uint _bookstaken,uint _initialpayment,uint _durationtime)public  onlyowner{
         peoplecount+=1;
    Userdetails[peoplecount].ID = _ID;
    Userdetails[peoplecount].Name = _Name;
    Userdetails[peoplecount].Dob =_Dob;
    Userdetails[peoplecount].Dept= _Dept;    
    Userdetails[peoplecount].bookstaken = _bookstaken;    
    Userdetails[peoplecount].initialpayment = 0;
    Userdetails[peoplecount].durationtime=_durationtime;
    
    

     }
     
     function getfunction(uint _ID,uint _bookstaken,uint _booktakentime,uint _durationtime)public onlyowner {
       Userdetails[_ID].ID=_ID;
       Userdetails[_ID].bookstaken=_bookstaken;
       Userdetails[_ID].booktakentime= now+_booktakentime;
       Userdetails[_ID].durationtime = _durationtime;
        Totalbooks=Totalbooks - _bookstaken;
     }
 function deposit(uint _initialpayment,uint _ID)public payable {
       require(msg.value == 30 ether, "error");
        Userdetails[_ID].initialpayment = msg.value;
        
    }
    
    function ReturnBook(uint _ID, uint _Booksreturn, uint _initialpayment)public{
        
       
        uint takentime;
        uint current;
        uint calculation;
        uint  fine;
        
        takentime = Userdetails[_ID].durationtime;
        current = block.timestamp;
        calculation = 1 seconds * 0.00000001 ether;
        fine = calculation * (current - takentime);
        
        Userdetails[_ID].ID = _ID;
        Userdetails[_ID].Booksreturn = _Booksreturn;
        Userdetails[_ID].initialpayment =Userdetails[_ID].initialpayment - fine;
       
        
         Totalbooks=Totalbooks + _Booksreturn;
        
       
       address(uint(librarian)).transfer(fine);
        
    }
    
    function showBalance()public view returns(uint){
        
        return address(this).balance;
    }
}