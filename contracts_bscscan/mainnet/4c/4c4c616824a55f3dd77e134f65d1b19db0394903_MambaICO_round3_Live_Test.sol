/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBEP20 {
   
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);
        
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPancakeRouter02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// MAMBA ICO Round 1 Address: 0x0cCE692e4dF6B413084d5CE6d6140FEfCB3BC325
contract MambaICO_round3_Live_Test is Ownable {
    
    address public tokenAddress = 0xc96CfB037Dfe260323E0FF5FD65c1912007506de; // MAMBA Token address
    IBEP20 token = IBEP20(tokenAddress);
    
    
    address public factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public wBnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    /*
    address public factory = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc; //0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address public wBnb = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    */
    
    IPancakeRouter02 private router = IPancakeRouter02(routerAddress);
    
    mapping (address => uint256) icoBuyersInvestment;
    
    uint256 public icoClaimersCount;
    uint256 public fundsClaimed; // BNBs claimed from round 2
    uint256 public startTime = block.timestamp;
    uint256 public endTime = block.timestamp + 7 days;
    uint256 public lockedBNBbalance;
    bool public icoFinalized = false;
   
    event ICOReinvested(address indexed buyer, uint256 amount);
    
    function buy() external payable returns (bool) {
        require (icoFinalized == false,'ICO is over and finalized you can trade on Pancakeswap');
        require(endTime >= block.timestamp, "ICO has ended");
        
        address buyer = msg.sender;
        
        if(icoBuyersInvestment[buyer] == 0){
            icoClaimersCount++;
        }
        
        icoBuyersInvestment[buyer] = icoBuyersInvestment[buyer] + msg.value;
        
        fundsClaimed = fundsClaimed + msg.value;
        
        emit ICOReinvested(buyer, msg.value);
        
        return true;
    }

    function getContractTokenBalance() public view returns(uint){
        return token.balanceOf(address(this));
    }
    
    function getUserTokenBalance() public view returns(uint){
        return token.balanceOf(msg.sender);
    }
    
    function getBNBInvestment(address _address) external view returns(uint256){
        return icoBuyersInvestment[_address];
    }
    
    function setTokenAddress(address _tokenAddress) external onlyOwner{
        tokenAddress = _tokenAddress;
    }
    
    function setStartTime(uint256 _startTime) external onlyOwner{
        startTime = _startTime;
    }
    
    function setEndTime(uint256 _endTime) external onlyOwner{
        endTime = _endTime;
    }
    
    function withdrawToken() external onlyOwner {
        require(
            token.balanceOf(address(this)) > 0,
            "Insufficient token balance"
        );
        bool success = token.transfer(
            msg.sender,
            token.balanceOf(address(this))
        );
        require(success, "Token Transfer failed.");
    }
    
    function addLiquidity(uint256 _amountTokenDesired, uint256 _amountBNB, uint256 _amountTokenDesiredMin, uint256 _amountBNBMin)
        external
        onlyOwner
    {
        require(
            token.balanceOf(address(this)) >= _amountTokenDesired,
            "Insufficient token balance"
        );
        require(
            address(this).balance >= _amountBNB,
            "Insufficient BNB balance"
        );
        IBEP20(tokenAddress).approve(routerAddress, _amountTokenDesired);
        router.addLiquidityETH{value: _amountBNB}(
            address(token),
            _amountTokenDesired,
            _amountTokenDesiredMin,
            _amountBNBMin,
            address(this),
            block.timestamp + 10 minutes
        );
        
        lockedBNBbalance = lockedBNBbalance + _amountBNB;
    }
    
    function claimInvestment() external { // In case some problem occures and liquidity is not added on DEX (Pancakeswap), Investors can claim back the invested amount.
        require (block.timestamp > endTime + 3 days, 'ICO is not finalized yet');
        require (icoFinalized == false,'ICO is finalized you can trade on Pancakeswap');
        require(icoBuyersInvestment[msg.sender] > 0, 'You do not have any ICO investments');
        (bool success, ) = msg.sender.call{value: icoBuyersInvestment[msg.sender]}("");
        require(success, "Transfer failed.");
    }
    
    function getLPLockedTokensBalance() external view returns (uint256 liquidity) {
        address pair = IUniswapV2Factory(factory).getPair(tokenAddress, wBnb);
        liquidity = IBEP20(pair).balanceOf(address(this));
    }
}