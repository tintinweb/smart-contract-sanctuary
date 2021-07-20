/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity >=0.4.21 <0.6.0;

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}


contract EnergySupply is Ownable{

  struct energy_supply_item{
    string category;
    string month;
    string area_name;
    uint256 value;
    string value_unit;
    uint256 prod;
    bool exists;
  }

  uint256 public value_base;
  uint256 public prod_base;

  bool public paused;
  mapping(bytes32 => energy_supply_item) private energy_supply_info;

  constructor(uint256 _value_base, uint256 _prod_base)  public{
    value_base = _value_base;
    prod_base = _prod_base;
    paused = false;
  }

  function pause() public onlyOwner{
    paused = true;
  }
  function unpause() public onlyOwner{
    paused = false;
  }

  event AddEnergySupply(string energy_category, string month, string area, uint256 value, string value_unit, uint256 prod);
  function add_energy_supply(string memory _energy_category,
                             string memory _month,
                             string memory _area_name,
                             uint256 _value,
                             string memory _value_unit,
                             uint256 _prod) public returns(bool){
    require(paused == false, "already paused");
    bytes32 ehash = keccak256(abi.encodePacked(_energy_category, _month));

    energy_supply_info[ehash].category = _energy_category;
    energy_supply_info[ehash].month = _month;
    energy_supply_info[ehash].area_name = _area_name;
    energy_supply_info[ehash].value = _value;
    energy_supply_info[ehash].value_unit = _value_unit;
    energy_supply_info[ehash].prod = _prod;
    energy_supply_info[ehash].exists = true;

    emit AddEnergySupply(_energy_category, _month, _area_name, _value, _value_unit, _prod);
    return true;
  }

  function get_energy_supply_info(string memory _energy_category,
                                  string memory _month) public view returns(string memory energy_category,
                                                                     string memory month,
                                                                     string memory area_name,
                                                                     uint256 value,
                                                                     string memory value_unit,
                                                                     uint256 prod){
    bytes32 ehash = keccak256(abi.encodePacked(_energy_category, _month));
    require(energy_supply_info[ehash].exists, "energy supply info does not exists!");
    energy_supply_item storage item = energy_supply_info[ehash];
    energy_category = item.category;
    month = item.month;
    area_name = item.area_name;
    value = item.value;
    value_unit = item.value_unit;
    prod = item.prod;
  }

  function energy_supply_exists(string memory _energy_category,
                                string memory _month) public view returns(bool) {
    bytes32 ehash = keccak256(abi.encodePacked(_energy_category, _month));
    return energy_supply_info[ehash].exists;
  }
}

contract EnergySupplyFactory {
  event CreateEnergySupply(uint256 value_base, uint256 prod_base);

  function newEnergySupply(uint256 _value_base, uint256 _prod_base) public returns(address){
    EnergySupply addr = new EnergySupply(_value_base, _prod_base);
    emit CreateEnergySupply(_value_base, _prod_base);
    addr.transferOwnership(msg.sender);
    return address(addr);
  }
}