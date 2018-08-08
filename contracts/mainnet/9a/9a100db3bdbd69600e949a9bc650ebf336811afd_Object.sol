pragma solidity ^0.4.18;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract BuildingStatus is Ownable {
  /* Observer contract  */
  address public observer;

  /* Crowdsale contract */
  address public crowdsale;

  enum statusEnum {
      crowdsale,
      refund,
      preparation_works,
      building_permit,
      design_technical_documentation,
      utilities_outsite,
      construction_residential,
      frame20,
      frame40,
      frame60,
      frame80,
      frame100,
      stage1,
      stage2,
      stage3,
      stage4,
      stage5,
      facades20,
      facades40,
      facades60,
      facades80,
      facades100,
      engineering,
      finishing,
      construction_parking,
      civil_works,
      engineering_further,
      commisioning_project,
      completed
  }

  modifier notCompleted() {
      require(status != statusEnum.completed);
      _;
  }

  modifier onlyObserver() {
    require(msg.sender == observer || msg.sender == owner || msg.sender == address(this));
    _;
  }

  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale || msg.sender == owner || msg.sender == address(this));
    _;
  }

  statusEnum public status;

  event StatusChanged(statusEnum newStatus);

  function setStatus(statusEnum newStatus) onlyCrowdsale  public {
      status = newStatus;
      StatusChanged(newStatus);
  }

  function changeStage(uint8 stage) public onlyObserver {
      if (stage==1) status = statusEnum.stage1;
      if (stage==2) status = statusEnum.stage2;
      if (stage==3) status = statusEnum.stage3;
      if (stage==4) status = statusEnum.stage4;
      if (stage==5) status = statusEnum.stage5;
  }
 
}

/*
 * Manager that stores permitted addresses 
 */
contract PermissionManager is Ownable {
    mapping (address => bool) permittedAddresses;

    function addAddress(address newAddress) public onlyOwner {
        permittedAddresses[newAddress] = true;
    }

    function removeAddress(address remAddress) public onlyOwner {
        permittedAddresses[remAddress] = false;
    }

    function isPermitted(address pAddress) public view returns(bool) {
        if (permittedAddresses[pAddress]) {
            return true;
        }
        return false;
    }
}

contract ERC223Interface {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  function allowedAddressesOf(address who) public view returns (bool);
  function getTotalSupply() public view returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
  event TransferContract(address indexed from, address indexed to, uint value, bytes data);
}

/**
 * @title Building Object contract.
 * @author Vladimir Kovalchuk
 */
contract Object is BuildingStatus {

  /* Name of an object */
  string public name;

  /* Gross building area */
  uint32 public gba;

  /* Gress sale area */
  uint32 public gla;

  /* Parking space */
  uint32 public parking;

  /* Type of the building */
  enum unitEnum {appartment, residential}

  unitEnum public unit;

  /* Developer of an object */
  string public developer;

  /* Leed */
  string public leed;

  /* Location of an object */
  string public location;

  /* start date of a project */
  uint public constructionStart;

  /* end of construction of an object */
  uint public constructionEnd;
  // unt sqm
  uint public untsqm;

  /* report of completion */
  string public report;

  event ConstructionDateChanged(uint constructStart, uint constructEnd);
  event PropertyChanged(uint32 gba, uint32 gla, uint32 parking, unitEnum unit, string developer,
    string leed, string location, uint constructionStart, uint constructionEnd);

  event HoldChanged(address newHold);
  event ObserverChanged(address newObserver);
  event CrowdsaleChanged(address newCrowdsale);
  event TokenChanged(address newCrowdsale);

  /* ERC223 Unity token */
  ERC223Interface public token;

  /* Hold contract */
  address public hold;

  /* Permission manager contract */
  PermissionManager public permissionManager;

  modifier onlyPermitted() {
    require(permissionManager.isPermitted(msg.sender) || msg.sender == owner || msg.sender == address(this));
    _;
  }

  event Completed(string report);

  /* Constructor of an object */
  function Object(string iName, uint32 iGBA, uint32 iGSA, uint32 iParking, unitEnum iUnit,
    string iDeveloper, string iLeed, string iLocation, uint iStartDate, uint iEndDate, uint UNTSQM,
    address iToken, address iCrowdsale, address iObserver, address iHold, address pManager) public {
      name = iName;
      gba = iGBA;
      gla = iGSA;
      parking = iParking;
      unit = iUnit;
      developer = iDeveloper;
      leed = iLeed;
      location = iLocation;
      untsqm = UNTSQM;
      constructionStart = iStartDate;
      constructionEnd = iEndDate;

      token = ERC223Interface(iToken);
      crowdsale = iCrowdsale;
      observer = iObserver;
      hold = iHold;
      permissionManager = PermissionManager(pManager);
  }

  function setPermissionManager(address _permadr) public onlyOwner {
    require(_permadr != 0x0);
    permissionManager = PermissionManager(_permadr);
  }

  /*
   * Public setters area
   */
  function setGBA(uint32 newGBA) public onlyPermitted notCompleted {
    gba = newGBA;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }

  function setGLA(uint32 newGLA) public onlyPermitted notCompleted {
    gla = newGLA;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }

  function setParking(uint32 newParking) public onlyPermitted notCompleted {
    parking = newParking;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }

  function setUnit(unitEnum newUnit) public onlyPermitted notCompleted {
    unit = newUnit;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }

  function setDeveloper(string newDeveloper) public onlyPermitted notCompleted {
    developer = newDeveloper;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }

  function setLeed(string newLeed) public onlyPermitted notCompleted {
    leed = newLeed;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }

  function setLocation(string newLocation) public onlyPermitted notCompleted {
    location = newLocation;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }

  function setStartDate(uint newStartDate) public onlyPermitted notCompleted {
    constructionStart = newStartDate;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }

  function setEndDate(uint newEndDate) public onlyPermitted notCompleted {
    constructionEnd = newEndDate;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }


  function setName(string _name) public onlyPermitted notCompleted {
    name = _name;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }
  
  function setUntsqm(uint _untsqm) public onlyPermitted notCompleted {
    untsqm = _untsqm;
    PropertyChanged(gba, gla, parking, unit, developer, leed, location, constructionStart, constructionEnd);
  }

  function setObserver(address _observer) public onlyOwner {
    require(_observer != 0x0);
    observer = _observer;
    ObserverChanged(_observer);
  }

  function setToken(address _token) public onlyOwner {
    require(_token != 0x0);
    token = ERC223Interface(_token);
    TokenChanged(_token);
  }

  function setHold(address _hold) public onlyOwner {
    require(_hold != 0x0);
    hold = _hold;
    HoldChanged(_hold);
  }

  function setCrowdsale(address _crowdsale) public onlyOwner {
    require(_crowdsale != 0x0);
    crowdsale = _crowdsale;
    CrowdsaleChanged(_crowdsale);
  }

  function getTotalSupply() public view returns (uint) {
    return token.getTotalSupply();
  }

  function getUNTSQM() public view returns (uint) {
    return untsqm;
  }

  function setProperty(string property, string typeArg, uint intVal, string strVal) public onlyObserver {
    string memory set = "set";
    string memory s = "(";
    string memory s2 = ")";
    bytes memory _ba = bytes(set);
    bytes memory _bb = bytes(property);
    bytes memory _t = bytes(typeArg);
    bytes memory _s = bytes(s);
    bytes memory _s2 = bytes(s2);
    string memory ab = new string(_ba.length + _bb.length + 1 + _t.length + 1);
    bytes memory babcde = bytes(ab);
    uint k = 0;

    for (uint i = 0; i < _ba.length; i++) {
      babcde[k++] = _ba[i];
    }
    for (i = 0; i < _bb.length; i++) {
      babcde[k++] = _bb[i];
    }
    babcde[k++] = _s[0];

    for (i = 0; i < _t.length; i++) {
      babcde[k++] = _t[i];
    }

    babcde[k++] = _s2[0];
    if (intVal == 0) {
      assert(this.call(bytes4(keccak256(string(babcde))), strVal));
    } else {
      assert(this.call(bytes4(keccak256(string(babcde))), intVal));
    }
  }

  function completeStatus(string newReport) public onlyOwner notCompleted {
    status = statusEnum.completed;
    report = newReport;
    Completed(report);
  }


}