pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
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
  function isOwner() public view returns(bool) {
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

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    //function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    //function approve(address spender, uint tokens) public returns (bool success);
    //function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    //event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ACC is Ownable{
    using SafeMath for uint256;
    
    address constant private ZERO_ADDRESS = address(0);
    //address constant public partnerMainAddress = REPLACEIT;
    address constant private partnerMainAddress = 0xe7C2070CfeC702DdC090198B5F938E7C10C1F97E;
    
    struct Customer {
        address addr;
        bool isLocked;
        uint expiredTime;
        bool approvalStatus;
    }
    
    string public partnerName;
    mapping(address => bool) private partnerApprovalAddresses;

    address private WLCAddress;
    address private PCAddress;
    
    mapping(address => Customer) private customers;
    
    
    // BEGIN OF VALIDATIONS
    
    modifier isValidAddress(address addr) {
        require(addr != ZERO_ADDRESS);
        _;
    }
    
    modifier isWLAddress(address addr) {
        require(addr != ZERO_ADDRESS);
        require(addr == WLCAddress);
        _;
    }
    
    modifier isContract(address addr){
        require(AddressUtils.isContract(addr));
        _;
    }
    
    modifier isAvailableTokenBalance(address tokenAddr, uint tokenAmount) {
        require(tokenAmount > 0);
        require(ERC20(tokenAddr).balanceOf(this) >= tokenAmount);
        _;
    }
    
    modifier isACCAddress(address addr) {
        require(addr != ZERO_ADDRESS);
        require(partnerApprovalAddresses[addr]);
        _;
    }
    
    modifier isACCMainAddress(address addr) {
        require(addr != ZERO_ADDRESS);
        require(addr == partnerMainAddress);
        _;
    }
    
    modifier isCustomerNotAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].addr == ZERO_ADDRESS);
        _;
    }
    
    modifier isCustomerAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].addr == addr);
        _;
    }
    
    modifier isLockedCustomer(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].isLocked);
        _;
    }
    
    modifier isUnLockedCustomer(address addr) {
        require(addr != ZERO_ADDRESS);
        require(!customers[addr].isLocked);
        _; 
    }
    
    // END OF VALIDATIONS
    
    constructor(string _name, address _wlCAddress, address _pCAddress) public isContract(_wlCAddress) isContract(_pCAddress) {
        partnerName = _name;
        WLCAddress = _wlCAddress;
        PCAddress = _pCAddress;
        partnerApprovalAddresses[partnerMainAddress] = true;
    }
    
    
    function getWLAddress() public view onlyOwner returns(address){
        return WLCAddress;
    }
    
    function setWLAddress(address _wlCAddress) public onlyOwner isContract(_wlCAddress) returns(bool){
        WLCAddress = _wlCAddress;
        return true;
    }
    
    function getPCAddress() public view onlyOwner returns(address){
        return PCAddress;
    }
    
    function setPCAddress(address _pCAddress) public onlyOwner isContract(_pCAddress) returns(bool){
        PCAddress = _pCAddress;
        return true;
    }
    
    function addCustomer(address _customerAddress) public onlyOwner isCustomerNotAdded(_customerAddress) returns (bool){
        customers[_customerAddress] = Customer(_customerAddress, false, now, false);
        return true;
    }

    function addCustomerFromACC(address _customerAddress) public isACCAddress(msg.sender) isCustomerNotAdded(_customerAddress) returns (bool){
        customers[_customerAddress] = Customer(_customerAddress, false, now, false);
        return true;
    }
    
    function setApprovalStatus(address _customerAddress) public onlyOwner isCustomerAdded(_customerAddress) returns (bool){
        Customer storage c = customers[_customerAddress];
        c.approvalStatus = true;
        return true;
    }
    
    function removeApprovalStatus(address _customerAddress) public onlyOwner isCustomerAdded(_customerAddress) returns (bool){
        Customer storage c = customers[_customerAddress];
        c.approvalStatus = false;
        return true;
    }
    
    function getCustomerInfo(address _customerAddress) public view onlyOwner isCustomerAdded(_customerAddress) returns (address, bool, uint, bool){
        Customer memory c = customers[_customerAddress];
        return (c.addr, c.isLocked, c.expiredTime, c.approvalStatus);
    }
    
    function lockedCustomer(address _customerAddress) public onlyOwner  
        isCustomerAdded(_customerAddress) isUnLockedCustomer(_customerAddress) returns(bool){
        Customer storage c = customers[_customerAddress];
        c.isLocked = true;
        return true;
    }
    
    function unlockedCustomer(address _customerAddress) public onlyOwner  
        isCustomerAdded(_customerAddress) isLockedCustomer(_customerAddress) returns(bool){
        Customer storage c = customers[_customerAddress];
        c.isLocked = false;
        return true;
    }

    function isCustomerHasACCfromWL(address _customerAddress) public view isCustomerAdded(_customerAddress) isWLAddress(msg.sender) returns (bool){
        Customer memory c = customers[_customerAddress];
        require (!c.isLocked && c.expiredTime > now);
        return true;
    }
    
    function addPartnerAddress(address _partnerAddress) public onlyOwner isValidAddress(_partnerAddress) returns(bool){
        partnerApprovalAddresses[_partnerAddress] = true;
        return true;
    }
    
    function removePartnerAddress(address _partnerAddress) public onlyOwner isValidAddress(_partnerAddress) returns(bool){
        partnerApprovalAddresses[_partnerAddress] = false;
        return true;
    }
    
    function getPartnerAddressStatus(address _partnerAddress) public view onlyOwner isValidAddress(_partnerAddress) returns(bool){
        return partnerApprovalAddresses[_partnerAddress];
    }
    
    // ONLY USE ACC 
    
    function setCustomerSignature(address _customerAddress, uint _expiredTime) public
        isACCAddress(msg.sender) isCustomerAdded(_customerAddress) returns(bool){ 
            require(_expiredTime > now);
            Customer storage c = customers[_customerAddress];
            require(c.approvalStatus);
            c.expiredTime = _expiredTime;
            c.approvalStatus = false;
            return true;
    }
    
    function startPaymentProcess(address _paymentAddress) public isACCMainAddress(msg.sender) isValidAddress(_paymentAddress) returns(bool){
        return PCAddress.call(bytes4(keccak256("payProviderFee(address)")), _paymentAddress);
    }
    
    // BEGIN OF PAYABLE FUNCTIONS
    
    function() public payable {
        revert(); 
    }
    
    function tokenTransfer(address _address, address _tokenAddress, uint _tokenAmount) public onlyOwner isValidAddress(_address) 
        isContract(_tokenAddress) isAvailableTokenBalance(_tokenAddress, _tokenAmount) returns(bool){
            ERC20(_tokenAddress).transfer(_address, _tokenAmount);
            return true;
    }
    
    // END OF PAYABLE FUNCTIONS
    
}