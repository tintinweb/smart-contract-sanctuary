/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library SafeMath {



    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        //assert(a == b * c + a % b); // There is no case in which this doesn't hold ---------------------------------------------

        return c;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

interface IUserManagement {
    
    // Read Functions

    function isOwner(address account) external view returns (bool);
    function isAuthorized(address adr) external view returns (bool);
    function isAuthorizedContract(address adr) external view returns (bool);
    function isRegisteredUser(address adr) external view returns (bool);
    function getUserNickname(address _userAddress) external view returns(string memory);
    function getAllUsers() external view returns (address[] memory);

   // Edit Functions

    function contractEditUserRole (address _address, uint _role) external;
    function registerNewUser (address _userAddress, string memory _userNickname) external;
}

contract UserManagement {

    address internal owner;

    address[] public userAddresses;
    address[] public authorizedContracts;

    mapping (address => bool) internal authorizations;
    mapping (address => bool) internal contractAuthorizations;
    mapping (address => uint) userRole;
    mapping (address => bool) isRegistred;
    mapping (address => userDetails) userList;

    struct userDetails {
        address userAddress;
        string userNickname;
        uint256 role;   // 0 - user without  contract approvation || 1 - user with contract approvation || 2 - authorized contract || 3 - admin
    }
    
    // Events

    event OwnershipTransferred(address owner);
    event UserProfileUpdated(address user);
    event UserCreated(address user);
    event UserRoleUpdated(address user, uint role);
    event AuthorizedContractAdded(address contractAddress);

    // Initialize Parameters

    constructor(address _owner, address _mainContract) {
        owner = _owner;   
        authorizations[_owner] = true;  
        isRegistred[_owner] = true;
        userRole[_owner] = 3;
        userList[_owner].userAddress = address(_owner);
        userList[_owner].userNickname = "Admin";
        userList[_owner].role = 3;
        userAddresses.push(_owner);
        addAuthorizedContract(_mainContract);
    }

    // Initialize Interfaces



    // Modifiers

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    modifier authorizedContract() {
        require(isAuthorizedContract(msg.sender), "!AUTHORIZED"); _;
    }

    modifier registeredUser() {
        require(isRegisteredUser(msg.sender), "!REGISTERED"); _;
    }

    // Read Functions

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
    
    function isAuthorizedContract(address adr) public view returns (bool) {
        return contractAuthorizations[adr];
    }
    
    function isRegisteredUser(address adr) public view returns (bool) {
        return isRegistred[adr];
    }

    function getUserNickname(address _userAddress) external view returns(string memory _userNickname) {
        _userNickname = userList[_userAddress].userNickname;
        return _userNickname;
    }

    function getAllUsers() public view returns (address[] memory) {
        return userAddresses;
    }

    // Edit Functions
    
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function editUserRole (address _address, uint _role) public authorized {
        userList[_address].role = _role;
        userRole[_address] = _role;
        emit UserRoleUpdated(_address, _role);
    }
  
    function contractEditUserRole (address _address, uint _role) external authorizedContract {
        userList[_address].role = _role;
        userRole[_address] = _role;
        emit UserRoleUpdated(_address, _role);
    }

    function registerNewUser (address _userAddress, string memory _userNickname) external {
        require(isRegisteredUser(_userAddress) == false);
        addUser(_userAddress, _userNickname);
    }
      
    function addUser(address _userAddress, string memory _userNickname) internal {
        require(isRegistred[_userAddress] == false, "User already registered");
        userRole[_userAddress] = 0;
        userList[_userAddress].userAddress = address(_userAddress);
        userList[_userAddress].role = 0;
        userList[_userAddress].userNickname = _userNickname;
        userAddresses.push(_userAddress);
        isRegistred[_userAddress] = true;
        emit UserCreated(_userAddress);
    }

    function updateUser(address _userAddress, string memory _nickname) internal {
        require(isRegistred[_userAddress] == true, "User not registered");
        userList[_userAddress].userAddress = address(_userAddress);
        userList[_userAddress].userNickname = _nickname;
        emit UserProfileUpdated(_userAddress);
    }
      
    function addAuthorizedContract(address _contractAddress) internal {
        require(isRegistred[_contractAddress] == false, "contract already registered");
        contractAuthorizations[_contractAddress] = true;
        authorizedContracts.push(_contractAddress);
        isRegistred[_contractAddress] = true;
        emit AuthorizedContractAdded(_contractAddress);
    }
}

contract Context {

    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
}

interface IObjectSale {

    function BuyObject() external payable;
    function getPriceInBNB() external view returns (uint256);
}

contract ObjectSale is Context {

    uint256 public saleId;
    string public objectName;
    uint256 public objectPriceInUsd;
    string public objectDescription;
    address public sellerAddress;
    bool private objectSold;

    // Events

    event Sold(uint sellDate);


    constructor (uint256 _saleId, string memory _objectName, uint256 _objectPriceInUsd, string memory _objectDescription, address _sellerAddress) {
        saleId = _saleId;
        objectName = _objectName;
        objectPriceInUsd = _objectPriceInUsd;
        objectDescription = _objectDescription;
        sellerAddress = _sellerAddress;

    }

    // Initialize Interfaces

    IDEXRouter iROUTER = IDEXRouter(ROUTER);

    // User Functions

    function BuyObject() external payable {
        uint256 objectPriceInWei;
        objectPriceInWei = objectPriceInUsd*1000000000000000000;
        require(msg.value >= iROUTER.getAmountsIn(objectPriceInWei, getPathForWBNBToBUSD())[0]);
        require(objectSold = false);
        objectSold = true;
        emit Sold(block.timestamp);
    }

    function getPriceInBNB() external view returns (uint256) {
            uint256 bnbQuote;
            uint256 objectPriceInWei;
            objectPriceInWei = objectPriceInUsd*1000000000000000000;
            bnbQuote = iROUTER.getAmountsIn(objectPriceInWei, getPathForWBNBToBUSD())[0];
            return bnbQuote;
    }

    // Internal Utility Functions

    function getPathForTokenToBNB(address _tokenAddress) internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = WBNB;
        return path;
    }

    function getPathForWBNBToBUSD() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = BUSD;
        return path;
    }
}

contract ObjectMarket {
    using SafeMath for uint256;

    // General settings

    address public admin;
    address[] private sellsList;
    uint[] private sellsIds;

    struct ObjectSaleStruct {
        address sellContractAddress;
        string objectName;
        uint256 objectPriceInUsd;
        string objectDescription;
        address sellerAddress;
    }

    mapping (uint => ObjectSaleStruct) salesDetails;
    mapping (address => uint[]) userSales;

    // Contracts

    UserManagement userManagement;
    address private userManagementAddress = address(userManagement);

    // Initialize Parameters

    constructor() {

        userManagement = new UserManagement(address(msg.sender), address(this));
        admin = address(msg.sender);

    }

    // Initialize Interfaces

    IUserManagement iUserManagement = IUserManagement(userManagementAddress);

    // Events

    // Modifiers

    modifier onlyOwner() {
        require(userManagement.isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(userManagement.isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    modifier authorizedContract() {
        require(userManagement.isAuthorizedContract(msg.sender), "!AUTHORIZED"); _;
    }
 
    modifier registeredUser() {
        require(userManagement.isRegisteredUser(msg.sender), "!REGISTERED"); _;
    }

    // User Functions

    function registerUser (string memory userNickname) public {
        require(userManagement.isRegisteredUser(msg.sender) == false, "You are already regitered");
        address userAddress = address(msg.sender);
        userManagement.registerNewUser(userAddress, userNickname);
    }

    function createSell(string memory objectName, uint256 objectPriceInUsd, string memory objectDescription) public registeredUser {

        uint newId = sellsIds.length + 1;
        address sellerAddress = address(msg.sender);
        ObjectSale newSellContract = new ObjectSale(newId, objectName, objectPriceInUsd, objectDescription, sellerAddress);
        address newSell = address(newSellContract);

        sellsList.push(newSell);
        sellsIds.push(newId);
        salesDetails[newId].sellContractAddress = newSell;
        salesDetails[newId].objectName = objectName;
        salesDetails[newId].objectPriceInUsd = objectPriceInUsd;
        salesDetails[newId].objectDescription = objectDescription;
        salesDetails[newId].sellerAddress = sellerAddress;
        userSales[sellerAddress].push(newId);
    }

    function viewSellDetails(uint saleId) public view returns(address, string memory, uint256, string memory, address) {
        address contractAddress;
        string memory objectName;
        uint256 priceInUsd;
        string memory objectDescription;
        address sellerAddress;

        contractAddress = salesDetails[saleId].sellContractAddress;
        objectName = salesDetails[saleId].objectName;
        priceInUsd = salesDetails[saleId].objectPriceInUsd;
        objectDescription = salesDetails[saleId].objectDescription;
        sellerAddress = salesDetails[saleId].sellerAddress;
        
        return(contractAddress, objectName, priceInUsd, objectDescription, sellerAddress);
    }

    function viewUserSales(address _userAddressToCheck) public view returns(uint[] memory) {
        require(userManagement.isRegisteredUser(_userAddressToCheck) == true, "User not registered");
        uint[] memory results;
        results = userSales[_userAddressToCheck];
        return results;
    }

    function getObjectPriceInBNB (uint _saleId) public view returns(uint256) {
        IObjectSale iSale = IObjectSale(salesDetails[_saleId].sellContractAddress);
        return iSale.getPriceInBNB();
    }

    function buyObject(uint _saleId) public payable {
        IObjectSale iSale = IObjectSale(salesDetails[_saleId].sellContractAddress);
        iSale.BuyObject();
    }

    // Admin Functions



    // Internal utility functions

}