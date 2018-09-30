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
    
    byte defaultStatus = 0x01;
    
    function changeServiceAddress(address _serviceAddress) {
        require(msg.sender == owner);
        serviceAddress = _serviceAddress;
    }
    
    function changeServiceAddress2(address _serviceAddress2) {
        require(msg.sender == owner);
        serviceAddress2 = _serviceAddress2;
    }
    
    function addDeal(uint _value, uint _cancelTime, string _seller, string _buyer, uint _commission, string _coinName, bytes32 _hashDeal) {
        require(msg.sender == serviceAddress || msg.sender == serviceAddress2);
        deals.push(Deal(_value,
                        _cancelTime,
                        _seller, 
                        _buyer,
                        defaultStatus,
                        _commission,
                        _coinName
                        )
                    );
        dealsIndex[_hashDeal] = deals.length - 1;
        emit newDeal(_coinName, _hashDeal, _buyer, _seller);
    }
    
    function changeStatus(byte _newStatus, bytes32 _hashDeal ) public {
        require(msg.sender == serviceAddress || msg.sender == serviceAddress2);
        deals[dealsIndex[_hashDeal]].status = _newStatus;
        emit dealChangedStatus(deals[dealsIndex[_hashDeal]].coinName,
                               _hashDeal, 
                               _newStatus);
    }
    
    function getDealData(bytes32 _hashDeal) public view returns(uint256, uint256,string,string, byte, uint256, string) {
        uint  dealIndex = dealsIndex[_hashDeal];
        return (deals[dealIndex].value, 
                deals[dealIndex].cancelTime,
                deals[dealIndex].seller,
                deals[dealIndex].buyer,
                deals[dealIndex].status,
                deals[dealIndex].commission,
                deals[dealIndex].coinName);
    }
}