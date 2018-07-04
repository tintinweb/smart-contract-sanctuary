pragma solidity ^0.4.23;
//pragma experimental ABIEncoderV2;


contract DeliveryFactory {
    mapping (address => uint) public openDeliveries;
    address[24] public available;
    event DeliveryAddress(address indexed _from, address _value);

    function createContract(
        uint256 itemValue, 
        uint256 deliveryDate, 
        int256 deliveryLat, 
        int256 deliveryLon, 
        int256 pickupLat, 
        int256 pickupLon
    ) public payable returns(address) {
        require(msg.value > 0);

        address newDelivery = (new Delivery).value(msg.value)(
            msg.sender, 
            itemValue, 
            deliveryDate, 
            deliveryLat, 
            deliveryLon, 
            pickupLat, 
            pickupLon,
            address(this)
        );
        
        for (uint i=0; i < 24; i++) {
            if (available[i] == address(0)) {
                available[i] = newDelivery;
                break;
            }
        }

        DeliveryAddress(msg.sender, newDelivery);
        return newDelivery;
    }

    function deleteContract() public {
        delete openDeliveries[msg.sender];
    }

    function getDelivery() public view returns(address[24]) {
        return available;
    }
}


contract Delivery {
    address public owner;
    uint256 public contractDate;
    uint256 public expirationDate;
    uint256 public itemValue;
    uint256 public deliveryDate;
    uint256 public deliveryValue;
    int256 public deliveryLat;
    int256 public deliveryLon;
    int256 public pickupLat;
    int256 public pickupLon;
    bool public pickupable;
    address public currentCarrier;
    
    Delivery public outsourced;
    address public outsourcedAddress;
    DeliveryFactory public parent;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyCarrier {
        require(msg.sender == currentCarrier);
        _;
    }
    
    modifier dateExpired {
        require(now > expirationDate);
        _;
    }
    
    modifier isPickupable {
        require(pickupable == true);
        _;
    }

    modifier itemValueDeposit {
        require(msg.value >= itemValue);
        _;
    }

    function Delivery(    
        address _owner,
        uint256 _itemValue,
        uint256 _deliveryDate,
        int256 _deliveryLat,
        int256 _deliveryLon,
        int256 _pickupLat,
        int256 _pickupLon,
        address _parent
    ) public payable {
        owner = _owner;
        contractDate = block.timestamp;
        itemValue = _itemValue;
        deliveryDate = _deliveryDate;
        deliveryLat = _deliveryLat;
        deliveryLon = _deliveryLon;
        pickupLat = _pickupLat;
        pickupLon = _pickupLon;
        pickupable = true;
        deliveryValue = msg.value;
        parent = DeliveryFactory(_parent);
    }
  
    function getDepositValue() public view returns(uint256) {
        return address(this).balance;
    }
  
    function refund() public onlyOwner dateExpired {
        selfdestruct(owner);
    }

    function getTupleDetails() public view 
    returns(uint256, uint256, uint256, int256, int256, int256, int256, uint256, address, uint256, address, address) {
        return (
            this.contractDate(), 
            this.deliveryDate(), 
            this.itemValue(), 
            this.deliveryLat(), 
            this.deliveryLon(), 
            this.pickupLat(),
            this.pickupLon(), 
            this.deliveryValue(),
            this.currentCarrier(), 
            address(this).balance, 
            this.owner(),
            this.outsourcedAddress()
        );
    }

    function subscribe() public itemValueDeposit isPickupable payable {
        pickupable = false;
        currentCarrier = msg.sender;
    }

    function finishDelivery() public onlyOwner {
        selfdestruct(currentCarrier);
    }

    function updateLocation(int256 lat, int256 lon) public onlyCarrier {
        pickupLat = lat;
        pickupLon = lon;
    }

    function outsourceDelivery(
        uint256 _itemValue, 
        uint256 _deliveryDate, 
        int256 _deliveryLat, 
        int256 _deliveryLon, 
        int256 _pickupLat, 
        int256 _pickupLon
        ) public payable onlyCarrier {
        outsourcedAddress = (parent.createContract).value(msg.value)(
            _itemValue,
            _deliveryDate,
            _deliveryLat,
            _deliveryLon,
            _pickupLat,
            _pickupLon
        );
        outsourced = Delivery(outsourcedAddress);
    }

}