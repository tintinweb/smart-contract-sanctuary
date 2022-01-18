// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";




interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISandwichRouter {
    function sandwichExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function sandwichTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}




interface IWBNB {
    function withdraw(uint) external;
    function deposit() external payable;
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}




contract Trigger2 is Ownable {

    // bsc variables 
    address constant wbnb= 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant cakeFactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    // eth variables 
    // address constant wbnb= 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address constant cakeRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // address constant cakeFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
    address payable private administrator;
    address private sandwichRouter = 0xE86d6A7549cFF2536918a206b6418DE0baE95e99;
    uint private wbnbIn;
    uint private minTknOut;
    address private tokenToBuy;
    address private tokenPaired;
    bool private snipeLock;
    
    mapping(address => bool) public authenticatedSeller;
    
    constructor(){
        administrator = payable(msg.sender);
        authenticatedSeller[msg.sender] = true;
    }
    
    receive() external payable {
        IWBNB(wbnb).deposit{value: msg.value}();
    }

//================== main functions ======================

    // Trigger2 is the smart contract in charge or performing liquidity sniping and sandwich attacks. 
    // For liquidity sniping, its role is to hold the BNB, perform the swap once dark_forester detect the tx in the mempool and if all checks are passed; then route the tokens sniped to the owner. 
    // For liquidity sniping, it require a first call to configureSnipe in order to be armed. Then, it can snipe on whatever pair no matter the paired token (BUSD / WBNB etc..).
    // This contract uses a custtom router which is a copy of PCS router but with modified selectors, so that our tx are more difficult to listen than those directly going through PCS router.   
    
    // perform the liquidity sniping
    function snipeListing() external returns(bool success){
        
        require(IERC20(wbnb).balanceOf(address(this)) >= wbnbIn, "snipe: not enough wbnb on the contract");
        IERC20(wbnb).approve(sandwichRouter, wbnbIn);
        require(snipeLock == false, "snipe: sniping is locked. See configure");
        snipeLock = true;
        
        address[] memory path;
        if (tokenPaired != wbnb){
            path = new address[](3);
            path[0] = wbnb;
            path[1] = tokenPaired;
            path[2] = tokenToBuy;

        } else {
            path = new address[](2);
            path[0] = wbnb;
            path[1] = tokenToBuy;
        }

        ISandwichRouter(sandwichRouter).sandwichExactTokensForTokens(
              wbnbIn,
              minTknOut,
              path, 
              administrator,
              block.timestamp + 120
        );
        return true;
    }
    
    // manage the "in" phase of the sandwich attack
    function sandwichIn(address tokenOut, uint  amountIn, uint amountOutMin) external returns(bool success) {
        
        require(msg.sender == administrator || msg.sender == owner(), "in: must be called by admin or owner");
        require(IERC20(wbnb).balanceOf(address(this)) >= amountIn, "in: not enough wbnb on the contract");
        IERC20(wbnb).approve(sandwichRouter, amountIn);
        
        address[] memory path;
        path = new address[](2);
        path[0] = wbnb;
        path[1] = tokenOut;
        
        ISandwichRouter(sandwichRouter).sandwichExactTokensForTokens(
            amountIn,
            amountOutMin,
            path, 
            address(this),
            block.timestamp + 120
        );
        return true;
    }
    
    // manage the "out" phase of the sandwich. Should be accessible to all authenticated sellers
    function sandwichOut(address tokenIn, uint amountOutMin) external returns(bool success) {
        
        require(authenticatedSeller[msg.sender] == true, "out: must be called by authenticated seller");
        uint amountIn = IERC20(tokenIn).balanceOf(address(this));
        require(amountIn >= 0, "out: empty balance for this token");
        IERC20(tokenIn).approve(sandwichRouter, amountIn);
        
        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = wbnb;
        
        ISandwichRouter(sandwichRouter).sandwichExactTokensForTokens(
            amountIn,
            amountOutMin,
            path, 
            address(this),
            block.timestamp + 120
        );
        
        return true;
    }
    

    
    
//================== owner functions=====================


    function authenticateSeller(address _seller) external onlyOwner {
        authenticatedSeller[_seller] = true;
    }

    function getAdministrator() external view onlyOwner returns( address payable){
        return administrator;
    }

    function setAdministrator(address payable _newAdmin) external onlyOwner returns(bool success){
        administrator = _newAdmin;
        authenticatedSeller[_newAdmin] = true;
        return true;
    }
    
    function getSandwichRouter() external view onlyOwner returns(address){
        return sandwichRouter;
    }
    
    function setSandwichRouter(address _newRouter) external onlyOwner returns(bool success){
        sandwichRouter = _newRouter;
        return true;
    }
    
    // must be called before sniping
    function configureSnipe(address _tokenPaired, uint _amountIn, address _tknToBuy,  uint _amountOutMin) external onlyOwner returns(bool success){
        
        tokenPaired = _tokenPaired;
        wbnbIn = _amountIn;
        tokenToBuy = _tknToBuy;
        minTknOut= _amountOutMin;
        snipeLock = false;
        return true;
    }
    
    function getSnipeConfiguration() external view onlyOwner returns(address, uint, address, uint, bool){
        return (tokenPaired, wbnbIn, tokenToBuy, minTknOut, snipeLock);
    }
    
    // here we precise amount param as certain bep20 tokens uses strange tax system preventing to send back whole balance
    function emmergencyWithdrawTkn(address _token, uint _amount) external onlyOwner returns(bool success){
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "not enough tokens in contract");
        IERC20(_token).transfer(administrator, _amount);
        return true;
    }
    
    // souldn't be of any use as receive function automaticaly wrap bnb incoming
    function emmergencyWithdrawBnb() external onlyOwner returns(bool success){
        require(address(this).balance >0 , "contract has an empty BNB balance");
        administrator.transfer(address(this).balance);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;
import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}