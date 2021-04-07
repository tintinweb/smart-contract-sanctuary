/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.8.3;

contract VerifiedCompanies{
    address owner;
    constructor(){
      owner=msg.sender;
    }

    modifier onlyOwner(){ 
           require(msg.sender == owner);  
           _; 
    } 
  
    mapping (address=>bool) public sellers;

    function addVerifiedCompany(address ofCompany) public onlyOwner{
      sellers[ofCompany]=true;
    }
}

contract Factory is VerifiedCompanies{

    uint256 public Companies;
    event CompanyCreated(address indexed owner, string indexed name);

    modifier onlyVerified(){ 
            require(sellers[msg.sender]==true);  
            _; 
    } 
  
    function create_Company(string memory name) public onlyVerified returns(Company newContract)
      {
        Company c = new Company(name);
        emit CompanyCreated(msg.sender, name); 
       return c;
     }
}


contract Company{

    address owner;                             
    string public company_name;
    
    event NewOrder(address indexed buyer, uint256 indexed deadline);
    
    constructor(string memory name) public{
      owner=msg.sender;
      company_name=name;
    }

    modifier onlyOwner(){ 
        require(msg.sender == owner);  
        _; 
    } 
  
    function create_Order(address payable buyer, uint256 stamp) public onlyOwner returns(Order newContract)
  { 
    emit NewOrder(buyer, block.timestamp + stamp*1 minutes);
    Order c = new Order(buyer,stamp);
    return c;
  }
}

contract Order {
    
address payable public seller; 
address payable public buyer; 

uint256 public allSum=0;                         //no public? 
uint256 public time;
uint256 public changeTime=0;

bool buyerOK=false;

constructor(address payable _buyer, uint256 stamp) public{ 
        buyer = _buyer; 
        seller = payable(msg.sender);
        time=(block.timestamp + stamp*1 minutes);       //+ 7 days  - потом дни сделать везде 
    } 
    
//////////////Модификаторы//////////////
    modifier onlyBuyer(){ 
        require(msg.sender == buyer);  
        _; 
    } 
  

    modifier onlySeller(){ 
        require(msg.sender == seller); 
        _; 
    } 
    
    modifier onlyBS(){ 
        require((msg.sender == seller)||(msg.sender == buyer)); 
        _; 
    } 
     

//////////////Основные функции//////////////

function setOK(bool bOk) private onlyBuyer {               // для соглашений - переправки селлеру и изменения временной метки
        buyerOK=bOk;
    }
    
function pay_to_Contract() onlyBuyer public payable{ 
        require(msg.value < (msg.sender).balance,
            "Not enough Ether provided."
        ); 
        allSum+=msg.value;
    } 
    

function deliver_from_Contract_to_Seller_All() onlyBS private{   
          require(address(this).balance>0,                                                 
            "Not enough Ether provided."
        );
        if(msg.sender==buyer){
           seller.transfer(address(this).balance); 
        }
        
        else{

          if (block.timestamp>(time + 10 days)){
              seller.transfer(address(this).balance); 
          }

          else if ((buyerOK)==true){
          seller.transfer(address(this).balance); 
          buyerOK=false;
          }

          else {
          revert("No permission or impossible amount.");
          }  

        }
          
    } 

function deliver_from_Contract_to_Seller_NotAll(uint256 percent) onlyBuyer private{   
          require(address(this).balance>0,                                                 
            "Not enough Ether provided."
        );
          uint summ=(address(this).balance)*percent/100;
          seller.transfer(summ); 

    } 
    

function return_payment() private { 
   uint bal=address(this).balance;

       require(bal>0,
            "Not enough Ether provided."
        );

          if (msg.sender==seller){
              buyer.transfer(bal);
              allSum-=bal;
        }
          else if (block.timestamp>(time+30 days)){
              buyer.transfer(bal);
              allSum-=bal;
          }
    }  
    
//////////////Дополнительные//////////////

function change(uint256 newStamp) private onlyBuyer {               // для изменения переменной
        changeTime=newStamp;
    }   

function changeStamp(uint256 howMuchDaysNeeded) onlySeller private {    //изменение временного штампа - необходимо согласие 2 сторон 
        if ((changeTime==howMuchDaysNeeded)&&(buyerOK==true)&&(changeTime!=0)){
            time+=changeTime*1 minutes;
            changeTime=0;
            buyerOK=false;
        }
    }
    
function kill() onlySeller private {                                            
            if ((address(this).balance)==0){
                selfdestruct(seller);
            }
    }

}