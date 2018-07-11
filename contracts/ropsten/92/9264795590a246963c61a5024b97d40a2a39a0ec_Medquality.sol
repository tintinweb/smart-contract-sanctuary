pragma solidity ^0.4.17;


contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Medquality is Ownable{

  struct Contact{
    string name; //name of the manufacturer
    string address_info; //address of the manufacturer
    string contact_info; //contact information of the manufacturer
  }

  struct Primary_Record {
    string udi_di; //UDI-DI = Device Identifier (DI) 
    string udi_pi; //UDI-PI = PI consists of lot or serial 
    string name; //Name or trade name
    string manufacturing_dt; //Date of manufacturing
    string expiry_dt; //Date of expiry
    string storage_condition; //Reccomended storage condition
    string additional_info_urls; //Url for additional info, IFU, surgical technique, etc..
  }
  
  struct Secondary_Record {
    bool is_single_use_device; //Single-use device (Y/N)
    string irritant_substance; //Containing Irritant substances (ex. Latex)
    bool is_lablled_sterile; //Device labelled sterile (y/n)
    string risk_class; //Device Risk Class
    string device_nomenclature; //Medical device nomenclature
    string qr_code; //Self generated QR code
  }
  
  struct Contact_Record {
    Contact manufacturer;
    Contact complaint_handler; //Complaint handling contacts (eg. email and phone)
  }
  
  mapping (string => Primary_Record) primary_records;
  mapping (string => Secondary_Record) secondary_records;
  mapping (string => Contact_Record) contact_records;

  event PrimaryRecordAdded(string indexed udi_di);
  event SecondaryRecordAdded(string indexed udi_di);
  event ContactRecordAdded(string indexed udi_di);

  function addPrimaryRecord(string _udi_di,
      string _udi_pi,
      string _name,
      string _manufacturing_dt,
      string _expiry_dt,
      string _storage_condition,
      string _additional_info_urls
    ) public onlyOwner returns (bool){
    
    Primary_Record memory pr = Primary_Record({
       udi_di: _udi_di,
       udi_pi: _udi_pi,
       name: _name,
       manufacturing_dt: _manufacturing_dt,
       expiry_dt: _expiry_dt,
       storage_condition: _storage_condition,
       additional_info_urls: _additional_info_urls
    });

    primary_records[_udi_di] = pr;
    emit PrimaryRecordAdded(_udi_di);

    return true;
  }
  
  function getPrimaryRecord(string _udi_di) public constant returns (string, string, string, string, string, string, string){
      Primary_Record storage pr = primary_records[_udi_di];
      return (pr.udi_di, pr.udi_pi, pr.name, pr.manufacturing_dt, pr.expiry_dt, pr.storage_condition, pr.additional_info_urls);
    }
  
  function addSecondaryRecord(string _udi_di,
      bool _is_single_use_device,
      string _irritant_substance,
      bool _is_lablled_sterile,
      string _risk_class,
      string _device_nomenclature,
      string _qr_code
    ) public onlyOwner returns (bool){
    
    Secondary_Record memory sr = Secondary_Record({
       is_single_use_device: _is_single_use_device,
       irritant_substance: _irritant_substance,
       is_lablled_sterile: _is_lablled_sterile,
       risk_class: _risk_class,
       device_nomenclature: _device_nomenclature,
       qr_code: _qr_code
    });

    secondary_records[_udi_di] = sr;
    emit SecondaryRecordAdded(_udi_di);

    return true;
  }
  
  function getSecondaryRecord(string _udi_di) public constant returns (bool, string, bool, string, string, string){
      Secondary_Record storage sr = secondary_records[_udi_di];
      return (sr.is_single_use_device, sr.irritant_substance, sr.is_lablled_sterile, sr.risk_class, sr.device_nomenclature, sr.qr_code);
    }
  
  function addContactRecord(string _udi_di,
      string _manufacturer_name,
      string _manufacturer_address_info,
      string _manufacturer_contact_info,
      string _complaint_handler_name,
      string _complaint_handler_address_info,
      string _complaint_handler_contact_info
    ) public onlyOwner returns (bool){
    
    Contact_Record memory cr = Contact_Record({
     manufacturer: Contact({
       name: _manufacturer_name,
       address_info: _manufacturer_address_info,
       contact_info: _manufacturer_contact_info
      }),
     complaint_handler: Contact({
       name: _complaint_handler_name,
       address_info: _complaint_handler_address_info,
       contact_info: _complaint_handler_contact_info
      })
    });
       

    contact_records[_udi_di] = cr;

    emit ContactRecordAdded(_udi_di);

    return true;
  }
  
  function getContactRecord(string _udi_di) public constant returns (string, string, string, string, string, string){
      Contact_Record storage cr = contact_records[_udi_di];
      return (cr.manufacturer.name, cr.manufacturer.address_info, cr.manufacturer.contact_info, cr.complaint_handler.name, cr.complaint_handler.address_info, cr.complaint_handler.contact_info);
    }

}