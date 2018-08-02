pragma solidity ^0.4.22;

/*
  DIMENSION SRL
  DataDispenser DEMO  
*/

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract DataDispenser{
    address public owner;
    address public dataServer;
    uint256 public price;
    
    modifier onlyOwner {
        if(msg.sender != owner) 
            revert();
        _;
    }
    
    modifier onlyDataServer {
         if(msg.sender != dataServer && msg.sender != owner) 
            revert();
        _;
    }
    
    event DataRequest(bytes32 dataID, string publicKey, bytes32 requestID);
    event DataResponse(string dataValue, bytes32 requestID);
    
    constructor() public {
        owner = 0x217c4FaA04BbED3B42B7Ed10344979439bE4d826;
        dataServer = 0x217c4FaA04BbED3B42B7Ed10344979439bE4d826;
        price=1000000000000000; //0.001 eth
    }
 
    function SetPrice(uint256 newPrice) public onlyOwner {
        price=newPrice;
    }
    
    function SetDataServerAddress(address serverAddress) public onlyOwner {
        dataServer=serverAddress;
    }
        
    function TakeMoney() public onlyOwner returns (bool) {
        uint balance = address(this).balance;
        owner.transfer(balance);
        return true;
    }
 
    function GetData(bytes32 dataID, string publicKey, bytes32 requestID) public payable {
        uint256 payment=msg.value;
        if (payment >= price ) {
            uint256 cashBack = SafeMath.sub(payment, price);
            if (cashBack>0) {
                msg.sender.transfer(cashBack);
            }
            emit DataRequest(dataID, publicKey, requestID);
        } else {
            revert();
        }
    }

    function CallBack(string dataValue, bytes32 requestID) public onlyDataServer {
        emit DataResponse(dataValue,requestID);
    }
    
    function OwnerKill() public payable onlyOwner {
        selfdestruct(owner);
    }
}