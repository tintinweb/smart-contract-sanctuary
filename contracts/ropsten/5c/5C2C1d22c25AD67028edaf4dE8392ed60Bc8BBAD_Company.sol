/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

pragma solidity ^0.6.0;

contract Company {
    
address payable public seller; 
address payable public ownerOfCont;
    
mapping (address=>uint256) public deadLine;

      constructor(address payable _seller) public{                      
        ownerOfCont = msg.sender; 
        seller = _seller; 
    } 
    
    
    modifier notBuyer(){ 
        require((msg.sender == ownerOfCont) || ( msg.sender == seller)); 
        _; 
    } 
    modifier onlyOwner(){ 
        require(msg.sender == ownerOfCont); 
        _; 
    } 

    function confPay(uint256 stamp) public payable  {                        // №1 перевод на контракт+метка в мэппинг
          require(
            msg.value < (msg.sender).balance,
            "Not enough Ether provided."
        );
        if (deadLine[msg.sender]!=0){
        deadLine[msg.sender]=now+stamp *1 minutes;
    }
    }
    
    function changeStamp(uint256 stamp, address buyer) public onlyOwner(){
        deadLine[buyer]=stamp*1 minutes;
    }
    

    
    function PayToSeller(uint amount,address buyer) public notBuyer  {      // №2 перевод продавцу
      if ((msg.sender==seller)&& (now>deadLine[buyer])){
          seller.transfer(amount);
      }
      else if (msg.sender==ownerOfCont){
          seller.transfer(amount);
      }
      else{
          revert("No permission.");
      }
}
    function returnPay (uint amount, address payable _buyer) public notBuyer{               // №3 возврат денег
          _buyer.transfer(amount);
        }
    
    function kill() public onlyOwner{                                            // №4 УНИЧТОЖЕНИЕ  КОНТРАКТА БУДУУУУМТСС
            selfdestruct(seller);
    }
}