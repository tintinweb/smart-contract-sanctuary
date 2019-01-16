pragma solidity >=0.5.0;

contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () internal {
      _owner = msg.sender;
      emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns (address) {
      return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
      require(isOwner());
      _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns (bool) {
      return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0));
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
  }
}

contract ShipmentTracker is Ownable {
  // tracking numbers and the corresponding Shipment
  mapping (bytes16 => Shipment) shipments;

  struct Shipment {
    bool __initialized;     // to track if the shipment started
    address supplier;       // address of supplier performing the delivery
    uint8 status;           // status flag from 0 to 255
    uint32 estDeliveryDate; // stored as yyyymmdd: 20181203
    string notes;           // dynamically-sized UTF-8-encoded string
  }

  event StatusChanged(
    bytes16 indexed trackingNo, // tracking number
    address indexed supplier,   // supplier address assigned to this shipment
    uint8 status                // the new status
  );

  constructor() public {}

  modifier onlySupplierOrOwner(bytes16 _trackingNo) {
    require(
      isOwner() || isSupplier(_trackingNo),
      "Only the supplier or owner can call this function."
    );
    _;
  }

  modifier isTracking(bytes16 _trackingNo) {
    require(
      shipments[_trackingNo].__initialized,
      "Invalid tracking number."
    );
    _;
  }

  modifier isNotTracking(bytes16 _trackingNo) {
    require(
      !shipments[_trackingNo].__initialized,
      "Tracking number already exists."
    );
    _;
  }

  /**
   * @return true if `msg.sender` is the supplier of the shipment
   */
  function isSupplier(bytes16 _trackingNo)
  public view
  returns(bool) {
      return msg.sender == shipments[_trackingNo].supplier;
  }

  // Initializes a shipment tracking
  function start(
    bytes16 _trackingNo,
    address _supplier,
    uint32 _estDeliveryDate,
    string memory _notes
  )
  public
  onlyOwner
  isNotTracking(_trackingNo) {
    shipments[_trackingNo].__initialized = true;
    shipments[_trackingNo].supplier = _supplier;
    shipments[_trackingNo].status = 0;
    shipments[_trackingNo].estDeliveryDate = _estDeliveryDate;
    shipments[_trackingNo].notes = _notes;
    emit StatusChanged(_trackingNo, _supplier, 0);
  }

  // Updates the status of a shipment tracking
  function setStatus(
    bytes16 _trackingNo,
    uint8 status,
    uint32 _estDeliveryDate,
    string memory _notes
  )
  public
  onlySupplierOrOwner(_trackingNo)
  isTracking(_trackingNo) {
    shipments[_trackingNo].status = status;
    shipments[_trackingNo].estDeliveryDate = _estDeliveryDate;
    shipments[_trackingNo].notes = _notes;
    emit StatusChanged(_trackingNo, shipments[_trackingNo].supplier, status);
  }

  /**
   * Reads the state of a shipment tracking
   *
   * @return address of supplier
   * @return uint8 status code
   * @return uint32 estimated Delivery Date
   * @return string notes
   */
  function getStatus(bytes16 _trackingNo)
  public view
  returns (
    address supplier,
    uint8 status,
    uint32 estDeliveryDate,
    string memory notes
  ) {
    return (
      shipments[_trackingNo].supplier,
      shipments[_trackingNo].status,
      shipments[_trackingNo].estDeliveryDate,
      shipments[_trackingNo].notes
    );
  }
}