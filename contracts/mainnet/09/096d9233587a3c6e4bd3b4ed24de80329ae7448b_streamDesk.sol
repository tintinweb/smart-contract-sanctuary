pragma solidity ^0.4.16;


contract streamDesk {
    
        struct Deal {
        uint256 value;
        uint256 cancelTime;
        string seller;
        string buyer;
        byte status;
        uint256 commission;
        string temporaryWallet;
        }
    
    Deal[] public deals;
    
    
    
    byte constant public startDeal          = 0x01;
    byte constant public coinTrasnferred    = 0x02;
    byte constant public coinNotTrasnferred = 0x03;
    byte constant public fiatTrasnferred    = 0x04;
    byte constant public fiatNotTrasnferred = 0x05;
    byte constant public coinRelease        = 0x06;
    byte constant public coinReturn         = 0x07;
    
    
    
    event newDeal( bytes32, string, string);
    event dealChangedStatus(bytes32, byte);
    address public owner;
    address public serviceAddress;
    mapping(bytes32 => uint)  public dealsIndex;
    
    constructor(address _serviceAddress) {
        owner = msg.sender;
        serviceAddress = _serviceAddress;

    }
    
    byte defaultStatus = 0x01;
    
    function changeServiceAddress(address _serviceAddress) public {
        require(msg.sender == owner);
        serviceAddress = _serviceAddress;
    }
    

    
    
    function addDeal(uint _value, string _seller, string _buyer, uint _commission, bytes32 _hashDeal, string _temporaryWallet) public  {
        require(msg.sender == serviceAddress);
        require(dealsIndex[_hashDeal] == 0);
        deals.push(Deal(_value,
                        now + 7200,
                        _seller, 
                        _buyer,
                        0x01,
                        _commission,
                        _temporaryWallet
                        )
                    );
        dealsIndex[_hashDeal] = deals.length;
        emit newDeal(_hashDeal, _buyer, _seller);
    }
    


    function changeStatus(byte _newStatus, bytes32 _hashDeal ) public {
        require(msg.sender == serviceAddress);

  
        if(deals[dealsIndex[_hashDeal] - 1].status == 0x01) {
            require(_newStatus == 0x02 || _newStatus == 0x03);
        }
        else if(deals[dealsIndex[_hashDeal] - 1].status == 0x02) {
            require(_newStatus == 0x04 || _newStatus == 0x05);
        }
        else if(deals[dealsIndex[_hashDeal] - 1].status == 0x04) {
            require(_newStatus == 0x06);
        }
        else if(deals[dealsIndex[_hashDeal] - 1].status == 0x05) {
            require(_newStatus == 0x07);
        }
        
         emit dealChangedStatus(
                               _hashDeal, 
                               _newStatus);
                               
        if(_newStatus == 0x03 || _newStatus == 0x06 || _newStatus == 0x07) {
            delete deals[dealsIndex[_hashDeal] -1];
            dealsIndex[_hashDeal] = 0;
        }
        else {
            deals[dealsIndex[_hashDeal] - 1].status = _newStatus;
        }
    }
    
    function getDealData(bytes32 _hashDeal) public view returns(uint256, uint256,string,string, byte, uint256,  string) {
        uint  dealIndex = dealsIndex[_hashDeal] - 1;
        return (deals[dealIndex].value, 
                deals[dealIndex].cancelTime,
                deals[dealIndex].seller,
                deals[dealIndex].buyer,
                deals[dealIndex].status,
                deals[dealIndex].commission,
                deals[dealIndex].temporaryWallet);
    }
}