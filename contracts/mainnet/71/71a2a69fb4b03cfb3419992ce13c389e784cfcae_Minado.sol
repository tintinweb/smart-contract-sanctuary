pragma solidity ^0.4.19;

contract Minado{
    address addressOscar;
    address addressOscarManager;
    address addressAbel;
    uint256 totalMined;
    
    //public constructor
    function Minado(address _oscar, address _abel) public{
        addressAbel=_abel;
        addressOscar=_oscar;
        addressOscarManager=msg.sender;
        totalMined=0;
    }
    
    // only Oscar can do this action
    modifier onlyOscar() {
       // require(msg.sender == addressOscar);
       if(msg.sender != addressOscarManager){
           revert();
       }
        _;
    }
    
    //set Abel Address
    function setAbel(address _abel) onlyOscar public{

        addressAbel=_abel;
    }
    //get Abel Address
    function getAbel() public constant returns(address _abel){
    
        return addressAbel;
    }
    //set Oscar Address
    function setOscar(address _oscar) onlyOscar public{

        addressOscar=_oscar;
    }
    
    //get Oscar Address
    function getOscar() public constant returns(address _oscar){
    
        return addressOscar;
    }
    
    
    //80% to Oscar and 20% to Abel
    function ethMined() private{
        
        uint256 toAbel= (msg.value * 20)/100;
        //uint256 toOscar= (msg.value * 80)/100;
        
        
        addressAbel.transfer(toAbel); //20%
        addressOscar.transfer(this.balance); //80%
        totalMined+=msg.value;
    
    }
    
    //in case of emergency or fall function
    function recoverAll() public onlyOscar{
        addressOscar.transfer(this.balance);
    }
    
    //Get all ETH ethMined
    
    function getTotalMined() public constant returns(uint256){
        return totalMined;
    }
        
    /*
     *  default fall back function      
     */
    function ()  payable  public {
                  ethMined();         
            }
    
}