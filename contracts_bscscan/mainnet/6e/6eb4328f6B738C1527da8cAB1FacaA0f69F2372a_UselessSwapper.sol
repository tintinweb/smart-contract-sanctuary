pragma solidity 0.8.0;

/**
 * Created September 1st 2021
 * Developed by Markymark (MoonMark)
 * Swapper Contract to Accept BNB and return Useless to Sender
 * Splitting off a tax to fuel the Useless Furnace
 */
// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";

/**
 * BNB Sent to this contract will be used to automatically buy Useless and send it back to the sender
 */
contract UselessSwapper {
    
    using Address for address;
    using SafeMath for uint256;

    // Initialize Pancakeswap Router
    IUniswapV2Router02 public _router;
  
    // Receive Token From Swap 
    address public _token;
    
    // path of BNB -> Token
    address[] path;

    // Useless Furnace Address
    address public _uselessFurnace;

    // fee allocated to furnace
    uint256 public _furnaceFee;
    
    // whether we accept bnb for swaps or not
    bool public _swappingEnabled;

    // owner of Swapper
    address public _owner;
    modifier onlyOwner() {require(msg.sender == _owner, 'Only Owner Function!'); _;}
  
    // initialize variables
    constructor() {
        _token = 0x2cd2664Ce5639e46c6a3125257361e01d0213657;
        _router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _uselessFurnace = 0x16F21Ae97D967E87792A40c826c0AA943b78A6ec;
        _furnaceFee = 80;
        _swappingEnabled = true;
        _owner = msg.sender;
        path = new address[](2);
        path[0] = _router.WETH();
        path[1] = _token;
    }

    /** Updates the Pancakeswap Router and Pancakeswap pairing for BNB In Case of migration */
    function updatePancakeswapRouter(address newPCSRouter) external onlyOwner {
        require(newPCSRouter != address(0), 'Cannot Set Pancakeswap Router To Zero Address');
        _router = IUniswapV2Router02(newPCSRouter);
        path[0] = _router.WETH();
        emit UpdatedPancakeswapRouter(newPCSRouter);
    }
    
    /** Updates The Useless Furnace in Case of Migration */
    function updateFurnaceContractAddress(address newFurnace) external onlyOwner {
        require(newFurnace != address(0), 'Cannot Set Furnace To Zero Address');
        _uselessFurnace = newFurnace;
        emit UpdateFurnaceContractAddress(newFurnace);
    }
    
    function updateUselessContractAddress(address newUselessAddress) external onlyOwner {
        require(newUselessAddress != address(0), 'CANNOT ASSIGN THE ZERO ADDRESS');
        _token = newUselessAddress;
        path[1] = newUselessAddress;
        emit UpdatedUselessContractAddress(newUselessAddress);
    }
    
    /** Updates The Fee Taken By The Furnace */
    function updateFurnaceFee(uint256 newFee) external onlyOwner {
        require(newFee <= 500, 'Fee Too High!!');
        _furnaceFee = newFee;
        emit UpdatedFurnaceFee(newFee);
    }
    
    function updateSwappingEnabled(bool swappingEnabled) external onlyOwner {
        _swappingEnabled = swappingEnabled;
        emit UpdatedSwappingEnabled(swappingEnabled);
    }

    /** Withdraws Tokens Mistakingly Sent To This Contract Address */
    function withdrawTokens(address tokenToWithdraw) external onlyOwner {
	    uint256 balance = IERC20(tokenToWithdraw).balanceOf(address(this));
	    require(balance > 0, 'Cannot Withdraw Token With Zero Balance');
	    bool success = IERC20(tokenToWithdraw).transfer(msg.sender, balance);
	    require(success, 'Token Transfer Failed');
	    emit OwnerWithdrawTokens(tokenToWithdraw, balance);
    }
  
    /** Withdraws BNB Given The Unlikely Scenario Some is Stuck inside the contract */
    function withdrawBNB() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'Cannot Withdraw Zero BNB');
	    (bool success,) = payable(msg.sender).call{value: balance, gas: 26000}("");
	    require(success, 'BNB Withdrawal Failed');
	    emit OwnerWithdrawBNB(balance);
    }
    
    /** Transfers Ownership To New Address */
    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
        emit OwnershipTransfered(newOwner);
    }
    
    /** Swaps BNB For Useless, sending fee to furnace */
    function swapForToken() private {
        // fee removed for Useless Furnace
        uint256 furnaceFee = _furnaceFee.mul(msg.value).div(1000);
        // amount to swap for USELESS
        uint256 bnbToSwap = msg.value.sub(furnaceFee);
        // Swap BNB for Token
        try _router.swapExactETHForTokens{value: bnbToSwap}(
            0,
            path,
            msg.sender,
            block.timestamp.add(30)
        ) {} catch{revert();}

        (bool success,) = payable(_uselessFurnace).call{value: furnaceFee, gas:26000}("");
        require(success, 'Furnace Payment Failed');
    }
	
    // Swap For Useless
    receive() external payable {
        require(_swappingEnabled, 'Swapping Is Disabled');
        swapForToken();
    }

    // EVENTS
    event UpdatedFurnaceFee(uint256 newFee);
    event UpdatedSwappingEnabled(bool swappingEnabled);
    event UpdatedPancakeswapRouter(address newRouter);
    event UpdateFurnaceContractAddress(address newFurnaceContractAddrss);
    event UpdatedUselessContractAddress(address newUselessContractAddress);
    event OwnerWithdrawTokens(address tokenWithdrawn, uint256 numTokensWithdrawn);
    event OwnerWithdrawBNB(uint256 numBNB);
    event OwnershipTransfered(address newOwner);
  
}