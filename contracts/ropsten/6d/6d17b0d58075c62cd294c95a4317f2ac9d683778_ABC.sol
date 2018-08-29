pragma solidity ^0.4.16;


contract ABC {
    
        struct Deal {
        uint256 value;
        uint256 cancelTime;
        string seller;
        string buyer;
        uint8 status;
        uint256 commission;
        }
    
    Deal[] public deals;
    
    event newDeal(bytes32);
    event dealChangedStatus(bytes32, uint8);
    address public owner;
    address public serviceAddress;
    mapping(bytes32 => uint)  public dealsIndex;
    
    constructor(address _serviceAddress) {
        owner = msg.sender;
        serviceAddress = _serviceAddress;
    }
    
    uint8 defaultStatus = 1;
    
    function changeServiceAddress(address _serviceAddress) {
        require(msg.sender == owner);
        serviceAddress = _serviceAddress;
    }
    
    function addDeal(uint _value, uint _cancelTime, string _seller, string _buyer, uint _commission, bytes32 _hashDeal) {
        require(msg.sender == serviceAddress);
        deals.push(Deal(_value,
                        _cancelTime,
                        _seller, 
                        _buyer,
                        defaultStatus,
                        _commission
                        )
                    );
        dealsIndex[_hashDeal] = deals.length - 1;
        emit newDeal(_hashDeal);
    }
    
    function changeStatus(uint8 _newStatus, bytes32 _hashDeal ) public {
        require(msg.sender == serviceAddress);
        deals[dealsIndex[_hashDeal]].status = _newStatus;
        emit dealChangedStatus(_hashDeal, _newStatus);
    }
    
    function getDealData(bytes32 _hashDeal) public view returns(uint256, uint256,string,string, uint8, uint256) {
        uint  dealIndex = dealsIndex[_hashDeal];
        return (deals[dealIndex].value, 
                deals[dealIndex].cancelTime,
                deals[dealIndex].seller,
                deals[dealIndex].buyer,
                deals[dealIndex].status,
                deals[dealIndex].commission);
    }
}