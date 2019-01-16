pragma solidity >0.4.99 <0.6.0;

contract StorePowerPodData {

    struct PowerPodReading {
        string  PowerPodId;
        string  PowerPodDate;
        string  ReadingType;
        int     PowerPodReading;
        uint8   OwnerCategory;
        address OwnerAddress;
    }

    address public AddedBy  = msg.sender;

    modifier onlyOwner {
        require(msg.sender == AddedBy);
        _;
    } 
    
    PowerPodReading[] public GetPowerPodReading;

    function StorePowerPodReading(
        string  memory PPId,
        string  memory PPDate,
        string  memory Type,
        int     MeterReading,
        uint8   Category,
        address Address
    )
    onlyOwner
    public {

        PowerPodReading memory newPowerPodReading = PowerPodReading({
            
            PowerPodId     : PPId,
            PowerPodDate   : PPDate,
            ReadingType    : Type,
            PowerPodReading: MeterReading,
            OwnerCategory  : Category,
            OwnerAddress   : Address
            
        });

        GetPowerPodReading.push(newPowerPodReading);

    }

    
    function TotalCount() public view returns(uint)  {
        return GetPowerPodReading.length;
    }

}