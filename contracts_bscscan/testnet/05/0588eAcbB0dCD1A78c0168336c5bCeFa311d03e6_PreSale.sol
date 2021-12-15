// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Libraries/SafeMath.sol";
import "./Interfaces/IUserManagement.sol";
import "./Interfaces/IDEXFactory+IDEXRouter.sol";
import "./Interfaces/IBEP20.sol";
import "./Interfaces/IConfig.sol";
import "./Context.sol";

contract PreSale is ContextSlave {
    using SafeMath for uint256;

    uint tokensSold;

    // Initialize Parameters

    constructor() {

        TOKEN = address(msg.sender);
    }

    // Modifiers 

    modifier onlyToken() {
        require(msg.sender == TOKEN); _;
    }

    // View Functions
    
    function getEstimatedTokenForBNB(uint256 buyAmountInWei) external view  returns (uint256) {
        uint256 bnbQuote;
        bnbQuote = iRouter.getAmountsOut(buyAmountInWei, getPathForWBNBToToken())[1];
        return bnbQuote;
    }

    // Utility Functions

    receive() external payable {}

    function getPathForWBNBToToken() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = TOKEN;
        
        return path;
    }

    function checkAmountValidity (uint buyAmountInWei) internal view returns(bool checkResult) {
        try iRouter.getAmountsOut(buyAmountInWei, getPathForWBNBToToken()) {
            checkResult = true;
            return checkResult;        
            }
        catch {
            checkResult = false;
            return checkResult;
            }
    }

    // Buy Functions

    function CharityBuyForLiquidity() public payable {

        require(checkAmountValidity(msg.value) == true, "Amount is not valide");

        uint amountOfToken = iRouter.getAmountsOut(msg.value, getPathForWBNBToToken())[1];

        require(iToken.balanceOf(address(this)) >= amountOfToken, "There is not enought tokens");

        emit Sold(address(msg.sender), amountOfToken);
        tokensSold += amountOfToken;

        require(iToken.transfer(address(msg.sender), amountOfToken));
        iUserManagement.updateUserGiftStats(address(msg.sender), msg.value, amountOfToken);
    }

    function externalCharityBuyForLiquidity(address _sender, uint _amount) external {
        require(checkAmountValidity(_amount) == true, "Amount is not valide");

        uint amountOfToken = iRouter.getAmountsOut(_amount, getPathForWBNBToToken())[1];

        require(iToken.balanceOf(address(this)) >= amountOfToken, "There is not enought tokens");

        emit Sold(_sender, amountOfToken);
        tokensSold += amountOfToken;

        require(iToken.transfer(_sender, amountOfToken));
        iUserManagement.updateUserGiftStats(address(_sender), _amount, amountOfToken);
    }

    // Settings Functions

    function endSale(address _sender) external  onlyToken{
        require(iUserManagement.isAuthorized(_sender) == true);
        require(iToken.transfer(TOKEN, iToken.balanceOf(address(this))));

        payable(msg.sender).transfer(address(this).balance);
    }

    function setUserManagementAddress(address _newAddress) external onlyToken {
        userManagementAddress = _newAddress;
    }

    // Events

    event Sold(address buyer, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

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

    function initialVariableEdition(address a1, address a2, address a3, address a4, address a5) external;
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

        pushNewVariablesToSalves(_ROUTER, _preSalesAddress, _TOKEN, _charityVaultAddress);

    }

    function pushNewVariablesToSalves(address _ROUTER, address _preSalesAddress, address _TOKEN, address _charityVaultAddress) public {

        iRouter = IDEXRouter(_ROUTER);
        iUserManagement = IUserManagement(address(this));
        iToken = IBEP20(_TOKEN);
        iPreSaleConfig = IPreSale(_preSalesAddress);
        iCharityVault = ICharityVault(_charityVaultAddress);
        iCoin = ICoin(_TOKEN);

        iCoin.adminEditSettings();
        iCharityVault.adminEditSettings();
        iPreSaleConfig.adminEditSettings();
    }


    // Interface View Function 
    
    function getOwnerAddress() external view returns(address) { return owner;}
    function getPairAddress() external view returns(address) { return dexPair;}
    function getTokenAddress() external view returns(address) { return TOKEN;}
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

        iRouter = IDEXRouter(ROUTER);
        iUserManagement = IUserManagement(userManagementAddress);
        iToken = IBEP20(TOKEN);
        iPreSaleConfig = IPreSale(preSalesAddress);
        iCharityVault = ICharityVault(charityVaultAddress);
        iCoin = ICoin(TOKEN);
    }
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

pragma solidity >=0.8.9;
// SPDX-License-Identifier: MIT


interface ICharityVault {
    
    // Settings Functions
    
    function setUserManagementAddress(address _newAddress) external;
    
    // Slave Edit Function

    function adminEditSettings() external; 
}

pragma solidity >=0.8.9;
// SPDX-License-Identifier: MIT


interface ICoin {
    
    // Slave Edit Function

    function adminEditSettings() external ;
     
}