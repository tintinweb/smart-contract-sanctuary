// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Interfaces/IBEP20.sol";
import "./Interfaces/IConfig.sol";
import "./Context.sol";
import "./Interfaces/ICoin.sol";

contract UserManagement is ContextMaster {

    address[] public userAddresses;

    mapping (address => bool) internal authorizations;
    mapping (address => uint) userRole;
    mapping (address => bool) isRegistred;
    mapping (address => userDetails) userList;

    struct userDetails {
        address userAddress;
        uint256 userBalance;
        uint256 totalDonation;
        uint256 totalCharityBuyAmount;
        uint256 role;   // 0 - user without  contract approvation || 1 - user with contract approvation || 2 - authorized contract || 3 - admin
    }
    
    // Events

    event OwnershipTransferred(address owner);
    event UserStatsUpdated(address user);
    event UserCreated(address user);
    event UserRoleUpdated(address user, uint role);

    // Initialize Parameters

    constructor() {
  
        TOKEN = address(msg.sender);
        
        authorizations[owner] = true; 
        authorizations[TOKEN] = true;  
        userRole[owner] = 3;
        userList[owner].userAddress = address(owner);
        userList[owner].userBalance = 0;
        userList[owner].totalDonation = 999999999999999;
        userList[owner].totalCharityBuyAmount = 999999999999999;
        userList[owner].role = 3;
        userAddresses.push(owner);  
    }

    // Modifiers

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    modifier authorizedContract() {
        require(userRole[msg.sender] == 1); _;
    }

    // Read Functions

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
    
    function getUserBalance(address _userAddress) external view returns(uint _userBalance) {
        _userBalance = userList[_userAddress].userBalance;
        return _userBalance;
    }

    function getUserTotalDonation(address _userAddress) external view returns(uint _userTotalDonation) {
        _userTotalDonation = userList[_userAddress].totalDonation;
        return _userTotalDonation;
    }

    function getUserTotalCharityBuyAmount(address _userAddress) external view returns(uint _userTotalCharityBuyAmount) {
        _userTotalCharityBuyAmount = userList[_userAddress].totalCharityBuyAmount;
        return _userTotalCharityBuyAmount;
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

    function updateUserGiftStats(address _userAddress, uint bnbDonationAmount, uint tokenBuyAmount) external authorizedContract {
        if (isRegistred[_userAddress] == true) {
            updateUser(_userAddress, bnbDonationAmount, tokenBuyAmount);
        }
        else {
            addUser(_userAddress);
         }
    }
      
    function addUser(address _userAddress) internal {
        require(isRegistred[_userAddress] == false);
        userRole[_userAddress] = 0;
        userList[_userAddress].userAddress = address(_userAddress);
        userList[_userAddress].userBalance = iToken.balanceOf(_userAddress);
        userList[_userAddress].totalDonation = 0;
        userList[_userAddress].totalCharityBuyAmount = 0;
        userList[_userAddress].role = 0;
        userAddresses.push(_userAddress);
        isRegistred[_userAddress] = true;
        emit UserCreated(_userAddress);
    }

    function updateUser(address _userAddress, uint _BnbDonationAmount, uint _TokenBuyAmount) internal {
        require(isRegistred[_userAddress] == true);
        userList[_userAddress].userAddress = address(_userAddress);
        userList[_userAddress].userBalance = iToken.balanceOf(_userAddress);
        userList[_userAddress].totalDonation = userList[_userAddress].totalDonation + _BnbDonationAmount;
        userList[_userAddress].totalCharityBuyAmount = userList[_userAddress].totalCharityBuyAmount + _TokenBuyAmount;
        emit UserStatsUpdated(_userAddress);
    }

    // Initial Variables Edition

    function initialVariableEdition(address a1, address a2, address a3, address a4) external {
        require(msg.sender == TOKEN);
        dexPair = a1;
        charityVaultAddress = a2;
        preSalesAddress = a3;
        distributorAddress = a4;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;


interface IConfig {

    function getOwnerAddress() external view returns(address);
    function getPairAddress() external view returns(address);
    function getTokenAddress() external view returns(address);
    function getWBNBAddress() external view returns(address);
    function getBUSDAddress() external view returns(address);
    function getRouterAddress() external view returns(address);
    function getDevWalletAddress() external view returns(address);
    function getUserManagementAddress() external view returns(address);
    function getDistributorAddress() external view returns(address);    
    function getCharityVaultAddress() external view returns(address);
    function getPreSalesAddress() external view returns(address);

}

pragma solidity >=0.8.9;
// SPDX-License-Identifier: MIT

import "./Interfaces/IDEXFactory+IDEXRouter.sol";
import "./Interfaces/IBEP20.sol";
import "./Interfaces/IPreSale.sol";
import "./Interfaces/IUserManagement.sol";
import "./Interfaces/IConfig.sol";
import "./Interfaces/ICharityVault.sol";
import "./Interfaces/ICoin.sol";


contract Context {

    // Constant Addresses & Parameters

    address public owner;

    address public BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address public WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;
    address public ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address public DEVWALLET = 0xF53c251ACbfc7Df58A2f47F063af69A3ED897042;    
    uint256 constant public MAX_INT = 2**256 - 1;

    IDEXRouter iRouter;
    IPreSale iPreSaleConfig;
    IUserManagement iUserManagement;
    IBEP20 iToken;
    ICharityVault iCharityVault;
    ICoin iCoin;

}

contract ContextMaster is Context {


    // Addresses from Token Creation

    address public TOKEN;
    address public dexPair;
    address public userManagementAddress = address(this);
    address public charityVaultAddress;
    address public preSalesAddress;
    address public distributorAddress;

    // Admin Settings

    function changeInitialVariables(address _BUSD, address _WBNB, address _ROUTER, address _DEVWALLET, address _TOKEN, address _dexPair, address _charityVaultAddress, address _preSalesAddress, address _distributorAddress) public {

        BUSD = _BUSD;
        WBNB = _WBNB;
        ROUTER = _ROUTER;
        DEVWALLET = _DEVWALLET;
        TOKEN = _TOKEN;
        dexPair = _dexPair;
        userManagementAddress = address(this);
        charityVaultAddress = _charityVaultAddress;
        preSalesAddress = _preSalesAddress;
        distributorAddress = _distributorAddress; 

        iRouter = IDEXRouter(_ROUTER);
        iPreSaleConfig = IPreSale(_preSalesAddress);
        iUserManagement = IUserManagement(address(this));
        iToken = IBEP20(_TOKEN);
        iCharityVault = ICharityVault(_charityVaultAddress);
        iCoin = ICoin(_TOKEN);

        iCoin.adminEditSettings();
        iCharityVault.adminEditSettings();
        iPreSaleConfig.adminEditSettings();
    }


    // Interface View Function 
    
    function getOwnerAddress() external view returns(address) { return owner;}
    function getPairAddress() external view returns(address) { return dexPair;}
    function getTokenAddress() external view returns(address) { return address(this);}
    function getWBNBAddress() external view returns(address) { return WBNB;}
    function getBUSDAddress() external view returns(address) { return BUSD;}
    function getRouterAddress() external view returns(address) { return ROUTER;}
    function getDevWalletAddress() external view returns(address) { return DEVWALLET;}
    function getUserManagementAddress() external view returns(address) { return userManagementAddress;}
    function getDistributorAddress() external view returns(address) { return distributorAddress;}    
    function getCharityVaultAddress() external view returns(address) { return charityVaultAddress;}
    function getPreSalesAddress() external view returns(address) { return preSalesAddress;} 
}

contract ContextSlave is Context {

    // Addresses from Token Creation

    address public TOKEN;
    address public dexPair;
    address public userManagementAddress;
    address public charityVaultAddress;
    address public preSalesAddress;
    address public distributorAddress;

    // Slave Edit Function

    function adminEditSettings() external  {
        require(msg.sender == userManagementAddress);
        IConfig iConfig = IConfig(userManagementAddress);
    
        owner = iConfig.getOwnerAddress();
        TOKEN = iConfig.getTokenAddress();
        dexPair = iConfig.getPairAddress();
        userManagementAddress = iConfig.getUserManagementAddress();
        charityVaultAddress = iConfig.getCharityVaultAddress();
        preSalesAddress = iConfig.getPreSalesAddress();
        distributorAddress = iConfig.getDistributorAddress();
        BUSD = iConfig.getBUSDAddress();
        WBNB = iConfig.getWBNBAddress();
        ROUTER = iConfig.getRouterAddress();
        DEVWALLET = iConfig.getDevWalletAddress();   
    }
}

pragma solidity >=0.8.9;
// SPDX-License-Identifier: MIT


interface ICoin {
    
    // Slave Edit Function

    function adminEditSettings() external ;
     
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;


interface IPreSale {


    // View Functions
    
    function getEstimatedTokenForBNB(uint buyAmountInWei) external view  returns (uint[] memory bnbQuote);

    // Buy Functions

    function externalCharityBuyForLiquidity(address _sender, uint _amount) external;

    // Settings Functions

    function endSale(address _sender) external;
    function changeToken (address _newTokenAddress, address _newPairAddress) external;
    function changeRouter (address _newRouterAddress) external;

    // Token Initialization Function
    
    function setUserManagementAddress(address _newAddress) external;
    
    // Slave Edit Function

    function adminEditSettings() external ;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IUserManagement {
    
    // Read Functions

    function isOwner(address account) external view returns (bool);
    function isAuthorized(address adr) external view returns (bool);
    function getUserBalance(address _userAddress) external view returns(uint _userBalance);
    function getUserTotalDonation(address _userAddress) external view returns(uint _userTotalDonation);
    function getUserTotalCharityBuyAmount(address _userAddress) external view returns(uint _userTotalCharityBuyAmount);
    function getAllUsers() external view returns (address[] memory);

   // Edit Functions

    function contractEditUserRole (address _address, uint _role) external;
    function updateUserGiftStats(address _userAddress, uint bnbDonationAmount, uint tokenBuyAmount) external;

    // Initialization

    function initialVariableEdition(address a1, address a2, address a3, address a4) external;
}

pragma solidity >=0.8.9;
// SPDX-License-Identifier: MIT


interface ICharityVault {
    
    // Settings Functions
    
    function setUserManagementAddress(address _newAddress) external;
    
    // Slave Edit Function

    function adminEditSettings() external; 
}