//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./ReentrantGuard.sol";

contract UselessSwapper is ReentrancyGuard {
    
    using Address for address;
    using SafeMath for uint256;

    // constants
    uint256 constant unit = 10**18;
    uint256 constant _denominator = 10**5;
    address constant _token = 0x2cd2664Ce5639e46c6a3125257361e01d0213657;
    
    // fees
    uint256 public _startingFee;
    uint256 public _minFee;
    uint256 public _bnbPercent;
    address public _furnace;

    // math
    uint256 public _factor;
    uint256 public _minBNBForDiscount;
    
    // PCS 
    IUniswapV2Router02 _router;
    address[] path;
    
    // swaps
    bool public _swapEnabled;
    
    // path of Token -> BNB
    address[] sellPath;

    // fee allocated to furnace
    uint256 public _furnaceFee;
    
    // fee allocated to furnace on bypass
    uint256 public _bypassFee;
    
    // ownership
    address _master;
    modifier onlyOwner(){require(msg.sender == _master, 'Invalid Entry'); _;}
    
    // events
    event BoughtAndReturnedToken(address to, uint256 amounttoken);
    event UpdatedBNBPercentage(uint256 newPercent);
    event UpdatedFactor(uint256 newFactor);
    event UpdatedMinBNB(uint256 newMin);
    event UpdatedMinimumFee(uint256 minFee);
    event UpdatedStartingFee(uint256 newStartingFee);
    event UpdatedFurnace(address newDistributor);
    event UpdatedSwapEnabled(bool swapEnabled);
    event TransferredOwnership(address newOwner);
    event UpdatedFurnaceFee(uint256 newFee);
    event UpdatedBypassFee(uint256 newBypassFee);
    event UpdatedPancakeswapRouter(address newPCSRouter);

    constructor() {
        // ownership
        _master = msg.sender;
        // state
        _swapEnabled = true;
        _minBNBForDiscount = 10 * unit;
        _factor = 80;
        _startingFee = 8000;
        _bnbPercent = 50;
        _furnaceFee = 80;
        _bypassFee = 40;
        _minFee = 0;
        _furnace = 0x03F9332cBA1dFc80b503b7EE3A085FBB8532abea;
        _router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        path = new address[](2);
        path[0] = _router.WETH();
        path[1] = _token;
        sellPath = new address[](2);
        sellPath[0] = _token;
        sellPath[1] = _router.WETH();
    }

    
    
    function calculateFees(uint256 amount) public view returns (uint256, uint256) {
        
        uint256 bVal = _factor.mul(amount).div(unit);
        if (bVal >= _startingFee) {
            return (_minFee,_minFee);
        }
        
        uint256 fee = _startingFee.sub(bVal).add(_minFee);
        uint256 bAlloc = _bnbPercent.mul(fee).div(10**2);
        return (bAlloc, fee.sub(bAlloc));
    }
    
    function updateBNBPercentage(uint256 bnbPercent) external onlyOwner {
        require(bnbPercent <= 100);
        _bnbPercent = bnbPercent;
        emit UpdatedBNBPercentage(bnbPercent);
    }
    
    function updateFactor(uint256 newFactor) external onlyOwner {
        _factor = newFactor;
        emit UpdatedFactor(newFactor);
    }
    
    function updateMinimumBNB(uint256 newMinimum) external onlyOwner {
        _minBNBForDiscount = newMinimum;
        emit UpdatedMinBNB(newMinimum);
    }
    
    function updateStartingFee(uint256 newFee) external onlyOwner {
        _startingFee = newFee;
        emit UpdatedStartingFee(newFee);
    }
    
    function updateFurnaceAddress(address newFurnace) external onlyOwner {
        _furnace = newFurnace;
        emit UpdatedFurnace(newFurnace);
    }
    
    function setSwapperEnabled(bool isEnabled) external onlyOwner {
        _swapEnabled = isEnabled;
        emit UpdatedSwapEnabled(isEnabled);
    }
    
    function setMinFee(uint256 minFee) external onlyOwner {
        _minFee = minFee;
        emit UpdatedMinimumFee(minFee);
    }

    function withdrawBNB(uint256 percent) external onlyOwner returns (bool s) {
        uint256 am = address(this).balance.mul(percent).div(10**2);
        require(am > 0);
        (s,) = payable(_master).call{value: am}("");
    }

    function withdrawToken(address token) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(_master, bal);
    }
    
    /** Updates The Fee Taken By The Furnace */
    function updateFurnaceFee(uint256 newFee) external onlyOwner {
        require(newFee <= 500, 'Fee Too High!!');
        _furnaceFee = newFee;
        emit UpdatedFurnaceFee(newFee);
    }
    
    /** Updates Fee To Use The Bypass */
    function updateBypassFee(uint256 newBypassFee) external onlyOwner {
        require(newBypassFee <= 500, 'Fee Too High!!');
        _bypassFee = newBypassFee;
        emit UpdatedBypassFee(newBypassFee);
    }
    
    /** Updates the Pancakeswap Router and Pancakeswap pairing for BNB In Case of migration */
    function updatePancakeswapRouter(address newPCSRouter) external onlyOwner {
        require(newPCSRouter != address(0), 'Pancakeswap Router To Zero Address');
        _router = IUniswapV2Router02(newPCSRouter);
        path[0] = _router.WETH();
        sellPath[1] = _router.WETH();
        emit UpdatedPancakeswapRouter(newPCSRouter);
    }

    function transferOwnership(address newMaster) external onlyOwner {
        _master = newMaster;
        emit TransferredOwnership(newMaster);
    }
    
    /** Swaps BNB For Useless, sending fee to furnace */
    function purchaseToken(address receiver) external payable nonReentrant {
        require(receiver != address(0) && receiver != address(this), 'Invalid Receive');
        require(msg.value > 10**9, 'Amount Too Few');
        if (msg.value < _minBNBForDiscount) {
            _purchaseToken(receiver);
        } else {
            _buyTokenAtDiscount(receiver);
        }
    }
    
    /** Sells Token For Useless, Fueling the Useless Furnace. Requires Token Approval */
    function sellUselessForBNB(uint256 numUseless) external nonReentrant {
        // balance of Useless
        uint256 uselessBalance = IERC20(_token).balanceOf(msg.sender);
        // ensure they have enough useless
        require(numUseless <= uselessBalance && numUseless > 0, 'Insufficient Balance');
        // balance of contract before swap
        uint256 contractBalanceBefore = IERC20(_token).balanceOf(address(this));
        // move tokens into this swapper
        IERC20(_token).transferFrom(msg.sender, address(this), numUseless);
        // how many tokens were received from transfer
        uint256 receivedFromTransfer = IERC20(_token).balanceOf(address(this)).sub(contractBalanceBefore);
        // ensure we gained tokens and that it matches numUseless
        require(receivedFromTransfer > 0 && receivedFromTransfer >= numUseless, 'Incorrect Amount Received From Transfer');
        // sell these tokens for BNB, sending to owner
        _sellToken(receivedFromTransfer);
    }
    
    function uselessBypass(address receiver, uint256 numTokens) external nonReentrant {
        // balance of Useless
        uint256 balance = IERC20(_token).balanceOf(msg.sender);
        // check balances
        require(numTokens <= balance && balance > 0, 'Insufficient Balance');
        // balance before transfer
        uint256 contractBalanceBefore = IERC20(_token).balanceOf(address(this));
        // transfer to this contract
        bool succOne = IERC20(_token).transferFrom(msg.sender, address(this), numTokens);
        // require success
        require(succOne, 'Failure on Transfer From');
        // transfer received tokens to recipient
        uint256 diff = IERC20(_token).balanceOf(address(this)).sub(contractBalanceBefore);
        // ensure it matches
        require(diff >= numTokens, 'Transfer was taxed');
        // apply fee to tokens
        uint256 tokensForFurnace = numTokens.mul(_bypassFee).div(1000);
        // tokens for Furnace
        uint256 tokensToTransfer = numTokens.sub(tokensForFurnace);
        // transfer tokens to recipient
        bool succTwo = IERC20(_token).transfer(receiver, tokensToTransfer);
        // transfer tokens to furnace
        bool success = IERC20(_token).transfer(_furnace, tokensForFurnace);
        // require success
        require(succTwo, 'Failure on Transfer To Recipient');
        require(success, 'Failure on Transfer To Furnace');
    }
    
    function _buyTokenAtDiscount(address receiver) private {
        
        // calculate fees
        (uint256 _bnbFee, uint256 _tokenFee) = calculateFees(msg.value);
        
        // portion out amounts
        uint256 furnaceAmount = msg.value.mul(_bnbFee).div(_denominator);
        uint256 swapAmount = msg.value.sub(furnaceAmount);
        
        // purchase token
        uint256 tokenReceived = _purchaseTokenReturnAmount(swapAmount);
        
        // send bnb to distributor
        if (furnaceAmount > 0) {
            (bool s2,) = payable(_furnace).call{value: furnaceAmount}("");
            require(s2, 'Error On Distributor Payment');
        }
        
        // portion amount for sender
        uint256 burnAmount = tokenReceived.mul(_tokenFee).div(_denominator);
        uint256 sendAmount = tokenReceived.sub(burnAmount);
        
        // transfer token To Sender
        bool success = IERC20(_token).transfer(receiver, sendAmount);
        require(success, 'Error on token Transfer');
        
        // Send token Balance To Furnace
        if (burnAmount > 0) {
            bool successful = IERC20(_token).transfer(_furnace, burnAmount);
            require(successful, 'Error Sending token To Furnace');
        }
        emit BoughtAndReturnedToken(receiver, sendAmount);
    }
    
    /** Swaps BNB For Useless, sending fee to furnace */
    function _sellToken(uint256 numTokens) private {
        
        // fee removed for Useless Furnace
        uint256 furnaceFee = _furnaceFee.mul(numTokens).div(1000);
        // amount to swap for USELESS
        uint256 tokensToSwap = numTokens.sub(furnaceFee);
        // approve PCS Router of Useless Amount
        IERC20(_token).approve(address(_router), tokensToSwap);
        
        // Swap BNB for Token
        try _router.swapExactTokensForETH(
            tokensToSwap,
            0,
            sellPath,
            msg.sender,
            block.timestamp.add(30)
        ) {} catch{revert();}

        bool success = IERC20(_token).transfer(_furnace, furnaceFee);
        require(success, 'Furnace Payment Failed');
    }
    
    function _purchaseTokenReturnAmount(uint256 amount) internal returns (uint256) {
        uint256 tokenBefore = IERC20(_token).balanceOf(address(this));
        _router.swapExactETHForTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp.add(30)
        );
        return IERC20(_token).balanceOf(address(this)).sub(tokenBefore);
    }
    
    function _purchaseToken(address receiver) private {
        // fee removed for Useless Furnace
        uint256 furnaceFee = _furnaceFee.mul(msg.value).div(1000);
        // amount to swap for USELESS
        uint256 bnbToSwap = msg.value.sub(furnaceFee);
        // purchase tokens
        uint256 received = _purchaseTokenReturnAmount(bnbToSwap);
        // transfer balance after to sender
        bool successful = IERC20(_token).transfer(receiver, received);
        // ensure transfer was successful
        require(successful, 'Failed on Token Transfer');
        // send proceeds to furnace
        (bool success,) = payable(_furnace).call{value: furnaceFee, gas:26000}("");
        require(success, 'Furnace Payment Failed');
    }
	
    // Swap For Useless
    receive() external payable {
        require(_swapEnabled, 'Swapping Is Disabled');
        require(msg.value >= 10**9, 'Amount Too Few');
        if (msg.value < _minBNBForDiscount) {
            _purchaseToken(msg.sender);
        } else {
            _buyTokenAtDiscount(msg.sender);
        }
    }
}