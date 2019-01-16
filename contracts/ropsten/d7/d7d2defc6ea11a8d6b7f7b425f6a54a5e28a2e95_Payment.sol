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
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Payment is Ownable {
    
    using SafeMath for uint256;
    address constant private ZERO_ADDRESS = address(0);
    address constant private USDC_ADDRESS = 0x072Ea7c455e5f3D6F3c318A55aE55D805096bc1A;
    
    //CUSTOMER PARAMETER
    struct Customer {
        address addr;
        bool isLocked;
        uint tokenBalance;
        uint weiBalance;
        address[] expectedAddresses;
    }
    
    mapping(address => Customer) private customers;
    mapping(address => address) private linkedAddress;
    
    //PROVIDER PARAMETER
    struct Provider {
        address contractAddr;
        bool isLocked;
        uint tokenBalance;
        uint tokenLimit;
        uint weiBalance;
        uint weiLimit;
    }
    
    mapping(address => Provider) private providers;
    
    //BEGIN OF CUSTOMERS VALIDATIONS
    
    modifier isValidAddress(address addr) {
        require(addr != ZERO_ADDRESS);
        _;
    }
    
    modifier isContract(address addr){
        require(AddressUtils.isContract(addr));
        _;
    }
    
    modifier isCustomerNotAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].addr == ZERO_ADDRESS);
        _;
    }
    
    modifier isCustomerAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].addr != ZERO_ADDRESS);
        _;
    }
    
    modifier checkSecondaryAddress(address secondaryAddress){
        require(secondaryAddress != ZERO_ADDRESS);
        require(linkedAddress[secondaryAddress] == ZERO_ADDRESS);
        _;
    }
    
    modifier isSecondaryAddrAdded(address addr, address secondaryAddress){
        require(addr != ZERO_ADDRESS);
        require(secondaryAddress != ZERO_ADDRESS);
        require(secondaryAddress != addr);
        require(linkedAddress[secondaryAddress] == addr);
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
    
    //END OF CUSTOMERS VALIDATIONS
    
    //BEGIN OF PROVIDERS VALIDATIONS
    
    modifier isProviderNotAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(providers[addr].contractAddr == ZERO_ADDRESS);
        _;
    }
    
    modifier isProviderAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(providers[addr].contractAddr == addr);
        _;
    }
    
    modifier isLockedProvider(address addr) {
        require(addr != ZERO_ADDRESS);
        require(providers[addr].isLocked);
        _;
    }
    
    modifier isUnLockedProvider(address addr) {
        require(addr != ZERO_ADDRESS);
        require(!providers[addr].isLocked);
        _; 
    }
    
    //END OF PROVIDERS VALIDATIONS
    
    // BEGIN OF TRANSFER VALIDATIONS
    
    modifier isAvailableTokenBalance( uint tokenAmount) {
        require(tokenAmount > 0);
        require(ERC20(USDC_ADDRESS).balanceOf(address(this)) >= tokenAmount);
        _;
    }
    
    modifier isAvailableETHBalance(uint amount) {
        require(amount > 0);
        require(address(this).balance > amount);
        _;
    }
    
    modifier isAvailableTokenBalancewithTokenAddress(address tokenAddr, uint tokenAmount) {
        require(tokenAmount > 0);
        require(ERC20(tokenAddr).balanceOf(address(this)) >= tokenAmount);
        _;
    }
    
    // END OF TRANSFER VALIDATIONS
    
    constructor() public {
       
    }
    
    //BEGIN OF CUSTOMERS FUNCTIONS 
    
    function addCustomer(address _customerAddress) public onlyOwner isCustomerNotAdded(_customerAddress) checkSecondaryAddress(_customerAddress) returns (bool){
        address[] memory addressList = new address[](1);
        addressList[0] = _customerAddress;
        customers[_customerAddress] = Customer(_customerAddress, false, 0, 0, addressList);
        linkedAddress[_customerAddress] = _customerAddress;
        return true;
    }

    function addCustomerTokenAmount(address _customerAddress, uint _tokenAmount) public onlyOwner isCustomerAdded(_customerAddress) returns (bool){
        require(_tokenAmount > 0);
        Customer storage c = customers[_customerAddress];
        c.tokenBalance = c.tokenBalance.add(_tokenAmount);
        return true;
    }
    
    function getCustomerInfo(address _customerAddress) public view onlyOwner isCustomerAdded(_customerAddress) returns(bool, uint, uint){
        Customer memory c = customers[_customerAddress];
        return (c.isLocked, c.weiBalance, c.tokenBalance);
    }
    
    function addSecondaryAddress(address _customerAddress, address _secondaryAddress) public onlyOwner isCustomerAdded(_customerAddress) 
        checkSecondaryAddress(_secondaryAddress) returns(bool){
            Customer storage c = customers[_customerAddress];
            c.expectedAddresses.push(_secondaryAddress);
            linkedAddress[_secondaryAddress] = _customerAddress;
            return true;
    }
    
    function deleteSecondaryAddress(address _customerAddress, address _secondaryAddress) public onlyOwner isCustomerAdded(_customerAddress)
        isSecondaryAddrAdded(_customerAddress, _secondaryAddress) returns(bool){
            require(_customerAddress != _secondaryAddress);
            Customer storage c = customers[_customerAddress];
            bool isExist = false;
            uint length = c.expectedAddresses.length;
            address[] memory addressList = new address[](length-1);
            uint l = 0;
            for (uint k=0; k<length; ++k) {
                if(c.expectedAddresses[k] !=_secondaryAddress){
                    addressList[l] = c.expectedAddresses[k];
                    l++;
                }else{
                    isExist = true;
                }
            }
            if(isExist){
                c.expectedAddresses = addressList;
                linkedAddress[_secondaryAddress] = ZERO_ADDRESS;
                return true;
            }
            return false;
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
    
    function getLinkedAddress(address _address) public view onlyOwner isValidAddress(_address) returns(address){
        //require(linkedAddress[_address] != ZERO_ADDRESS);
        return(linkedAddress[_address]);
    }
    
    function transferETHtoProviders(address _customerAddress, address _providerCA, uint _providerFee, address _creoCA, uint _creoFee )
        public onlyOwner isCustomerAdded(_customerAddress) isProviderAdded(_providerCA) isProviderAdded(_creoCA) returns(bool){
            require(_providerFee > 0 && _creoFee > 0);
            Customer storage c = customers[_customerAddress];
            Provider storage p = providers[_providerCA];
            Provider storage creo = providers[_creoCA];
            require(!c.isLocked && !p.isLocked && !creo.isLocked);
            uint totalFee = _providerFee.add(_creoFee);
            require(c.weiBalance>= totalFee);
            p.weiBalance = p.weiBalance.add(_providerFee);
            creo.weiBalance = creo.weiBalance.add(_creoFee);
            c.weiBalance = c.weiBalance.sub(totalFee);
            return true;
    }
    
    function transferTOKENtoProviders(address _customerAddress, address _providerCA, uint _providerFee, address _creoCA, uint _creoFee )
        public onlyOwner isCustomerAdded(_customerAddress) isProviderAdded(_providerCA) isProviderAdded(_creoCA) returns(bool){
            require(_providerFee > 0 && _creoFee > 0);
            Customer storage c = customers[_customerAddress];
            Provider storage p = providers[_providerCA];
            Provider storage creo = providers[_creoCA];
            require(!c.isLocked && !p.isLocked && !creo.isLocked);
            uint totalFee = _providerFee.add(_creoFee);
            require(c.tokenBalance>= totalFee);
            p.tokenBalance = p.tokenBalance.add(_providerFee);
            creo.tokenBalance = creo.tokenBalance.add(_creoFee);
            c.tokenBalance = c.tokenBalance.sub(totalFee);
            return true;
    }
    
    //END OF CUSTOMERS FUNCTIONS
    
    //BEGIN OF PROVIDERS FUNCTIONS
    
    function setProvider(address _providerCA, uint _weiLimit, uint _tokenLmit) public onlyOwner isContract(_providerCA) 
        isProviderNotAdded(_providerCA) returns(bool){
            providers[_providerCA] = Provider(_providerCA, false, 0, _tokenLmit, 0, _weiLimit);
            return true;
    }
    
    function setProviderLimits(address _providerCA, uint _weiLimit, uint _tokenLmit) public onlyOwner isContract(_providerCA) 
        isProviderAdded(_providerCA) returns(bool){
            Provider storage p = providers[_providerCA];
            p.weiLimit = _weiLimit;
            p.tokenLimit = _tokenLmit;
            return true;
    }
    
    function getProviderInfo(address _providerCA) public view onlyOwner isContract(_providerCA)
        isProviderAdded(_providerCA) returns(bool, uint, uint, uint, uint){
            Provider memory p = providers[_providerCA];
            return(p.isLocked, p.weiBalance, p.weiLimit, p.tokenBalance, p.tokenLimit);
    }
    
    function lockedProvider(address _providerCA) public onlyOwner isProviderAdded(_providerCA) isUnLockedProvider(_providerCA) returns(bool){
        Provider storage p = providers[_providerCA];
        p.isLocked = true;
        return true;
    }
    
    function unlockedProvider(address _providerCA) public onlyOwner isProviderAdded(_providerCA) isLockedProvider(_providerCA) returns(bool){
        Provider storage p = providers[_providerCA];
        p.isLocked = false;
        return true;
    }
    
    //END OF PROVIDERS FUNCTIONS
    
    // BEGIN OF PAYABLE FUNCTIONS
    
    function() public payable {
        require(msg.sender != ZERO_ADDRESS);
        require(linkedAddress[msg.sender] != ZERO_ADDRESS);
        require(msg.value > 0);
        address customerAddress = linkedAddress[msg.sender];
        Customer storage c = customers[customerAddress];
        require(c.addr != ZERO_ADDRESS);
        require(!c.isLocked);
        c.weiBalance = c.weiBalance.add(msg.value);
    }
    
    function refundETHToCustomer(address _customerAddress, uint _refundAmount) public onlyOwner isCustomerAdded(_customerAddress) isAvailableETHBalance(_refundAmount) returns(bool){
        Customer storage c = customers[_customerAddress];
        require(_refundAmount > 0 && c.weiBalance>=_refundAmount);
        _customerAddress.transfer(_refundAmount);
        c.weiBalance = c.weiBalance.sub(_refundAmount);
        return true;
    }
    
    function refundTokenToCustomer(address _customerAddress, uint _refundAmount) public onlyOwner isCustomerAdded(_customerAddress) isAvailableTokenBalance(_refundAmount) returns(bool){
        Customer storage c = customers[_customerAddress];
        require(_refundAmount > 0 && c.tokenBalance>=_refundAmount);
        ERC20(USDC_ADDRESS).transfer(_customerAddress, _refundAmount);
        c.tokenBalance = c.tokenBalance.sub(_refundAmount);
        return true;
    }
    
        
    function payProviderFee(address _providerWallet) public isProviderAdded(msg.sender) isValidAddress(_providerWallet){
        Provider memory p = providers[msg.sender];
        require(!p.isLocked);
        if(p.weiBalance >= p.weiLimit){
            payETHToProvider(_providerWallet, msg.sender, p.weiBalance);
        }
        if(p.tokenBalance >= p.tokenLimit){
            payUSDCToProvider(_providerWallet, msg.sender, p.tokenBalance); 
        }
    }
    
    function payETHToProvider(address _providerWallet, address _providerCA, uint _amount) internal isAvailableETHBalance(_amount) returns(bool) {
        Provider storage p = providers[_providerCA];
        _providerWallet.transfer(p.weiBalance);
        p.weiBalance = 0;
        return true;
    }
    
    function payUSDCToProvider(address _providerWallet, address _providerCA, uint _amount) internal isAvailableTokenBalance(_amount) returns(bool) {
        Provider storage p = providers[_providerCA];
        ERC20(USDC_ADDRESS).transfer(_providerWallet, p.tokenBalance);
        p.tokenBalance = 0;
        return true;
    }
    
    function tokenTransfer(address _address, address _tokenAddress, uint _tokenAmount) public onlyOwner isValidAddress(_address) 
        isContract(_tokenAddress) isAvailableTokenBalancewithTokenAddress(_tokenAddress, _tokenAmount) returns(bool){
            ERC20(_tokenAddress).transfer(_address, _tokenAmount);
            return true;
    }
    
    
    //END OF PAYALE FUNCTION
}