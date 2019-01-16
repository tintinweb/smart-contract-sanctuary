pragma solidity >0.4.99 <0.6.0;

contract StorePowerPodData {

    // modifier
    modifier OnlyOwner {
        require(msg.sender == AddedBy);
        _;
    }

    address public AddedBy  = msg.sender;


    // event
    event PowerPodReadingEvent(
        string  indexed PowerPodDate,
        string  indexed PowerPodId,
        int     PowerPodReading
    );


    // struct
    struct PowerPodReading {
        string  PowerPodId;
        string  PowerPodDate;
        string  ReadingType;
        int     PowerPodReading;
        uint8   OwnerCategory;
        address OwnerAddress;
    }


    // array
    PowerPodReading[] public GetPowerPodReading;


    // function
    function StorePowerPodReading(
        string  memory PPId,
        string  memory PPDate,
        string  memory Type,
        int     MeterReading,
        uint8   Category,
        address Address
    )
    OnlyOwner
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
        emit PowerPodReadingEvent(PPDate, PPId, MeterReading);

    }


    // count
    function TotalCount() public view returns(uint)  {
        return GetPowerPodReading.length;
    }

}