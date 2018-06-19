pragma solidity ^0.4.16;
contract Token { 
    function issue(address _recipient, uint256 _value) returns (bool success) {} 
    function totalSupply() constant returns (uint256 supply) {}
    function unlock() returns (bool success) {}
}

contract STARCrowdsale {

    address public creator; 
    
    uint256 public maxSupply = 104400000 * 10**8; 
    uint256 public minAcceptedAmount = 1 ether; // 1 ether

    uint256 public rateAngel = 1136;
    uint256 public rateA = 558;
    uint256 public rateB = 277;
    uint256 public rateC = 136;
    
    
    bool public close = false;

    
    address public address1 = 0x08294159dE662f0Bd810FeaB94237cf3A7bB2A3D;
    address public address2 = 0xAed27d4ecCD7C0a0bd548383DEC89031b7bBcf3E;
    address public address3 = 0x41ba7eED9be2450961eBFD7C9Fb715cae077f1dC;
    address public address4 = 0xb9cdb4CDC8f9A931063cA30BcDE8b210D3BA80a3;
    address public address5 = 0x5aBF2CA9e7F5F1895c6FBEcF5668f164797eDc5D;
    

    enum Stages {
        InProgress,
        Ended,
        Withdrawn
    }

    Stages public stage = Stages.InProgress;
    
    uint256 public raised;


    Token public starToken;


    mapping (address => uint256) balances;

    modifier atStage(Stages _stage) {
        if (stage != _stage) {
            throw;
        }
        _;
    }
    
    modifier onlyOwner() {
        if (creator != msg.sender) {
            throw;
        }
        _;
    }
  

    function balanceOf(address _investor) constant returns (uint256 balance) {
        return balances[_investor];
    }

    function STARCrowdsale() {
        
        
        starToken = Token(0x7b6054262d9ac537110a434ae75c880192faac25);
        
        creator = 0x6ADAfB7632859EF19d28276037581af00064d68F;
        
    }
    function toSTAR(uint256 _wei) returns (uint256 amount) {
        uint256 rate = 0;
        if (stage != Stages.Ended) {
            
            
            uint256 supply = starToken.totalSupply();
            
            if (supply <= 3000000 * 10**8) {

                rate = rateAngel;
            }
            
            else if (supply > 3000000 * 10**8) {

                rate = rateA;
            }
            
            else if (supply > 9000000 * 10**8) {

                rate = rateB;
            }
            
            else if (supply > 23400000 * 10**8) {

                rate = rateC;
            }
			
           
        }

        return _wei * rate * 10**8 / 1 ether; // 10**8 for 8 decimals
    }
 
    function endCrowdsale() onlyOwner atStage(Stages.InProgress) {

    
        stage = Stages.Ended;
    }
    
    function setOwner(address _newowner) onlyOwner {

        creator = _newowner;
    }


    function withdraw() onlyOwner atStage(Stages.Ended) {

        creator.transfer(this.balance);

        stage = Stages.Withdrawn;
    }
    
    function close() onlyOwner{

       close = true;
    }

    function () payable atStage(Stages.InProgress) {

            
        if (msg.value < minAcceptedAmount) {
            throw;
        }
        
        if(close == true){
            throw;
        }
 
        uint256 received = msg.value;
        uint256 valueInSCL = toSTAR(msg.value);


        if (valueInSCL == 0) {
            throw;
        }

        if (!starToken.issue(msg.sender, valueInSCL)) {
            throw;
        }

        address1.transfer(received/5);
        address2.transfer(received/5);
        address3.transfer(received/5);
        address4.transfer(received/5);
        address5.transfer(received/5);

        raised += received;

        if (starToken.totalSupply() >= maxSupply) {
            stage = Stages.Ended;
        }
    }
}