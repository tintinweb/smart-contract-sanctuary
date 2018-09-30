pragma solidity ^0.4.16;


contract streamDesk {
    
        struct Deal {
        uint256 value;
        uint256 cancelTime;
        string seller;
        string buyer;
        byte status;
        uint256 commission;
        string coinName;
        }
    
    Deal[] public deals;
    
    
    
    byte constant public startDealL = 0x00;
    byte constant public cancel = 0x02;
    byte constant public approve = 0x03;
    byte constant public approveRelease = 0x04;
    byte constant public cancelRelease = 0x05;
    
    
    
    event newDeal(string, bytes32, string, string);
    event dealChangedStatus(string,bytes32, byte);
    address public owner;
    address public serviceAddress;
    address public serviceAddress2;
    mapping(bytes32 => uint)  public dealsIndex;
    
    constructor(address _serviceAddress, address _serviceAddress2) {
        owner = msg.sender;
        serviceAddress = _serviceAddress;
        serviceAddress2 = _serviceAddress2;
    }
    
    byte defaultStatus = 0x0;
    
    function changeServiceAddress(address _serviceAddress) public {
        require(msg.sender == owner);
        serviceAddress = _serviceAddress;
    }
    
    function changeServiceAddress2(address _serviceAddress2) public {
        require(msg.sender == owner);
        serviceAddress2 = _serviceAddress2;
    }
    
    
    function addDeal(uint _value, string _seller, string _buyer, uint _commission, string _coinName, bytes32 _hashDeal) public  {
        require(msg.sender == serviceAddress || msg.sender == serviceAddress2);
        require(dealsIndex[_hashDeal] == 0);
        deals.push(Deal(_value,
                        now + 7200,
                        _seller, 
                        _buyer,
                        defaultStatus,
                        _commission,
                        _coinName
                        )
                    );
        dealsIndex[_hashDeal] = deals.length;
        emit newDeal(_coinName, _hashDeal, _buyer, _seller);
    }
    
    byte public tempS1;
    byte public tempS2;
    
    function changeStatus(byte _newStatus, bytes32 _hashDeal ) public {
        require(msg.sender == serviceAddress || msg.sender == serviceAddress2);

        
        if(deals[dealsIndex[_hashDeal] - 1].status == 0x00) {
            require(_newStatus == 0x03 || _newStatus == 0x05);
        }
        else if(deals[dealsIndex[_hashDeal] - 1].status == 0x03) {
            require(_newStatus == 0x04);
        }
        else if(deals[dealsIndex[_hashDeal] - 1].status == 0x02) {
            require(_newStatus == 0x05);
        }
        
        
        deals[dealsIndex[_hashDeal] - 1].status = _newStatus;
        emit dealChangedStatus(deals[dealsIndex[_hashDeal] - 1].coinName,
                               _hashDeal, 
                               _newStatus);
                               
    }
    
    function getDealData(bytes32 _hashDeal) public view returns(uint256, uint256,string,string, byte, uint256, string) {
        uint  dealIndex = dealsIndex[_hashDeal] - 1;
        return (deals[dealIndex].value, 
                deals[dealIndex].cancelTime,
                deals[dealIndex].seller,
                deals[dealIndex].buyer,
                deals[dealIndex].status,
                deals[dealIndex].commission,
                deals[dealIndex].coinName);
    }
}