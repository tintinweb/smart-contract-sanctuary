// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "ERC20.sol";
import "SafeERC20.sol";
import "Ownable.sol";


interface IOption {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function mint(address account, uint256 amount) external;
    
    function getUnderlying() external view returns (string memory);
    
    function getStrike() external view returns (uint);

    function getExpiresOn() external view returns (uint);
    
    function isPut() external view returns (bool);
}

interface IPriceConsumerV3EthUsd {
    function getLatestPrice() external view returns (int);
}

interface IUniswapV2Router02 {
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
      
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);  
    
    function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
      
    function WETH() external returns (address); 
    
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    
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
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
}

contract Octopus is Ownable {
    IPriceConsumerV3EthUsd priceConsumer = IPriceConsumerV3EthUsd(0x17A8402bF6BeA74535c9ff69648EBb6Ede7399e3);
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 kiboToken =  IERC20(0xF096C24D20528bD45aC555F3c0cbf4F781316556);
    ERC20 usdtToken = ERC20(0x8464c1368711F3A44d876e4359A8F67758609430);

    struct Seller {
        bool isValid;
        uint256 collateral; //This is in USDT for PUT and in the underlying for CALL
        uint256 notional;
        bool claimed;
    }
    
    struct Option {
        bool isValid;
        uint256 etherPriceInUSDTAtMaturity;
        uint256 optionWorth;
        mapping(address => Seller) sellers;
    }
    
    mapping(address => Option) public options;
    mapping(address => uint256) public kiboRewards;

    uint256 public totalFees;

    event OptionPurchase(address indexed option, address indexed buyer, uint256 weiNotional, uint256 usdtCollateral, uint256 premium);
    event RewardsIncreased(address indexed beneficiary, uint256 total);
    event RewardsWithdrawn(address indexed beneficiary, uint256 total);
    event ReturnedToSeller(address indexed option, address indexed seller, uint256 totalUSDTReturned, uint256 collateral, uint256 notional);
    event ReturnedToBuyer(address indexed option, address indexed buyer, uint256 totalUSDTReturned, uint256 _numberOfTokens);
    event OptionFinalPriceSet(address indexed option, uint256 ethPriceInUsdt, uint256 optionWorthInUsdt);

    function sell(address _optionAddress, uint256 _weiNotional) payable public {
        require(options[_optionAddress].isValid, "Invalid option");
        require(IOption(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        
        uint256 difference;
        uint256 usdCollateral;
        uint256 feesToCollect;
         
        if (IOption(_optionAddress).isPut()) {
            usdCollateral = calculateCollateralForPut(_optionAddress, _weiNotional);
            SafeERC20.safeTransferFrom(usdtToken, msg.sender, address(this), usdCollateral);
        } else {
            require(msg.value >= _weiNotional, 'Invalid collateral');
            difference = msg.value - _weiNotional;
            if (difference > 0) {
                payable(msg.sender).transfer(difference);
            }
        }   
        
        IOption(_optionAddress).mint(address(this), _weiNotional);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        
        //We sell the tokens for USDT in Uniswap, which is sent to the user
        uint256 premium = sellTokensInUniswap(_optionAddress, _weiNotional);
        
        if (IOption(_optionAddress).isPut()) {
            feesToCollect = usdCollateral / 100;
            seller.collateral += usdCollateral - feesToCollect;
        } else {
            feesToCollect = _weiNotional / 100;
            seller.collateral += _weiNotional - feesToCollect;
        }

        totalFees += feesToCollect;
        
        seller.isValid = true;
        seller.notional += _weiNotional;
        
        //We emit an event to be able to send KiboTokens offchain, according to the difference against the theoretical Premium
        emit OptionPurchase(_optionAddress, msg.sender, _weiNotional, usdCollateral, premium);
    }
    
    function calculateCollateralForPut(address _optionAddress, uint256 _notionalInWei) public view returns (uint256) {
        require(options[_optionAddress].isValid, "Invalid option");
        return IOption(_optionAddress).getStrike() * _notionalInWei / 1e18;
    }
    
    function claimCollateralAtMaturityForSellers(address _optionAddress) public {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].etherPriceInUSDTAtMaturity > 0, "Still not ready");
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        
        require(seller.isValid, "Seller not valid");
        require(!seller.claimed, "Already claimed");
        
        uint256 totalToReturn = getHowMuchToClaimForSellers(_optionAddress, msg.sender);
        require(totalToReturn > 0, 'Nothing to return');
        
        seller.claimed = true;

        if (IOption(_optionAddress).isPut()) {
            SafeERC20.safeTransfer(usdtToken, msg.sender, totalToReturn);
        } else {
            payable(msg.sender).transfer(totalToReturn);
        }
        
        emit ReturnedToSeller(_optionAddress, msg.sender, totalToReturn, seller.collateral, seller.notional);
    }
    
    function getHowMuchToClaimForSellers(address _optionAddress, address _seller) public view returns (uint256) {
        Seller memory seller = options[_optionAddress].sellers[_seller];
        if (seller.claimed) {
            return 0;
        }
        uint256 optionWorth = options[_optionAddress].optionWorth;
        uint256 amountToSubstract;
        
        if (IOption(_optionAddress).isPut()) {
            amountToSubstract = seller.notional * optionWorth / 1e18;
        } else {
            uint256 optionWorthInEth = optionWorth * 1e18 / (options[_optionAddress].etherPriceInUSDTAtMaturity * 1e6);
            amountToSubstract = seller.notional * optionWorthInEth / 1e18;
        }
        return seller.collateral - amountToSubstract;
    }
    
    function getHowMuchToClaimForBuyers(address _optionAddress, uint256 _numberOfTokens) public view returns (uint256) {
        uint256 optionWorth = options[_optionAddress].optionWorth;
        if (IOption(_optionAddress).isPut()) {
            return _numberOfTokens * optionWorth / 1e18;
        } else {
            uint256 optionWorthInEth = optionWorth * 1e18 / (options[_optionAddress].etherPriceInUSDTAtMaturity * 1e6);
            return _numberOfTokens * optionWorthInEth / 1e18;
        }
    }
    
    function claimCollateralAtMaturityForBuyers(address _optionAddress, uint256 _numberOfTokens) public {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].etherPriceInUSDTAtMaturity > 0, "Still not ready");
        
        require(IERC20(_optionAddress).transferFrom(msg.sender, address(this), _numberOfTokens), "Transfer failed");
        
        uint256 totalToReturn = getHowMuchToClaimForBuyers(_optionAddress, _numberOfTokens);
        
        if (IOption(_optionAddress).isPut()) {
            SafeERC20.safeTransfer(usdtToken, msg.sender, totalToReturn);
        } else {
            payable(msg.sender).transfer(totalToReturn);
        }

        emit ReturnedToBuyer(_optionAddress, msg.sender, totalToReturn, _numberOfTokens);
    }
    
    function withdrawKiboTokens() public {
        require(kiboRewards[msg.sender] > 0, "Nothing to withdraw");
        uint256 total = kiboRewards[msg.sender];
        kiboRewards[msg.sender] = 0;
        SafeERC20.safeTransfer(kiboToken, msg.sender, total);
        emit RewardsWithdrawn(msg.sender, total);
    }

    // Public functions
    
    // Returns the amount in USDT if you sell 1 KiboToken in Uniswap
    function getKiboSellPrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(kiboToken);
        path[1] = address(usdtToken);
        uint[] memory amounts = uniswapRouter.getAmountsOut(1e18, path);
        return amounts[1];
    }
    
    // Returns the amount in USDT if you buy 1 KiboToken in Uniswap
    function getKiboBuyPrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(usdtToken);
        path[1] = address(kiboToken);
        uint[] memory amounts = uniswapRouter.getAmountsIn(1e18, path);
        return amounts[0];
    }
    
    // Internal functions
    
    function sellTokensInUniswap(address _optionAddress, uint256 _tokensAmount) internal returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = _optionAddress;
        path[1] = address(usdtToken);
        IERC20(_optionAddress).approve(address(uniswapRouter), _tokensAmount);
        // TODO: uint256[] memory amountsOutMin = uniswapRouter.getAmountsOut(_tokensAmount, path);
        // Use amountsOutMin[1]
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(_tokensAmount, 0, path, msg.sender, block.timestamp);
        return amounts[1];
    }
    
    function createPairInUniswap(address _optionAddress, uint256 _totalTokens, uint256 _totalUSDT) internal returns (uint amountA, uint amountB, uint liquidity) {
        uint256 allowance = usdtToken.allowance(address(this), address(uniswapRouter));
        if (allowance > 0 && allowance < _totalUSDT) {
            SafeERC20.safeApprove(usdtToken, address(uniswapRouter), 0);
        }
        if (allowance == 0) {
            SafeERC20.safeApprove(usdtToken, address(uniswapRouter), _totalUSDT);
        }
        IERC20(_optionAddress).approve(address(uniswapRouter), _totalTokens);
        (amountA, amountB, liquidity) = uniswapRouter.addLiquidity(_optionAddress, address(usdtToken), _totalTokens, _totalUSDT, 0, 0, msg.sender, block.timestamp);
    }

    //Admin functions
    
    function _addKiboRewards(address _beneficiary, uint256 _total) public onlyOwner {
        kiboRewards[_beneficiary] += _total;
        emit RewardsIncreased(_beneficiary, _total);
    }
    
    function _deactivateOption(address _optionAddress) public onlyOwner {
        require(options[_optionAddress].isValid, "Already not activated");
        options[_optionAddress].isValid = false;
    }
    
    function _activateEthPutOption(address _optionAddress, uint256 _usdtCollateral, uint256 _uniswapInitialUSDT, uint256 _uniswapInitialTokens, bool _createPair) public onlyOwner {
        require(IOption(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        require(!options[_optionAddress].isValid, "Already activated");
        require(_usdtCollateral > 0, "Collateral cannot be zero");
        require(_uniswapInitialUSDT > 0, "Uniswap USDT cannot be zero");
        require(_uniswapInitialTokens > 0, "Uniswap tokens cannot be zero");
        require(IOption(_optionAddress).isPut(), "Option is not PUT");
        
        options[_optionAddress].isValid = true;

        IOption(_optionAddress).mint(address(this), _uniswapInitialTokens);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        seller.collateral = _usdtCollateral;
        seller.isValid = true;
        seller.notional = _uniswapInitialTokens;
        
        SafeERC20.safeTransferFrom(usdtToken, msg.sender, address(this), _uniswapInitialUSDT + _usdtCollateral);
        
        if (_createPair) {
            createPairInUniswap(_optionAddress, _uniswapInitialTokens, _uniswapInitialUSDT);
        }
    }
    
    function _activateEthCallOption(address _optionAddress, uint256 _uniswapInitialUSDT, uint256 _uniswapInitialTokens, bool _createPair) public payable onlyOwner {
        require(IOption(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        require(!options[_optionAddress].isValid, "Already activated");
        require(msg.value > 0, "Collateral cannot be zero");
        require(_uniswapInitialUSDT > 0, "Uniswap USDT cannot be zero");
        require(_uniswapInitialTokens > 0, "Uniswap tokens cannot be zero");
        require(!IOption(_optionAddress).isPut(), "Option is not CALL");

        options[_optionAddress].isValid = true;

        IOption(_optionAddress).mint(address(this), _uniswapInitialTokens);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        seller.collateral = msg.value;
        seller.isValid = true;
        seller.notional = _uniswapInitialTokens;
        
        SafeERC20.safeTransferFrom(usdtToken, msg.sender, address(this), _uniswapInitialUSDT);
        
        if (_createPair) {
            createPairInUniswap(_optionAddress, _uniswapInitialTokens, _uniswapInitialUSDT);
        }
    }
    
    function _setEthFinalPriceAtMaturity(address _optionAddress) public onlyOwner {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].etherPriceInUSDTAtMaturity == 0, "Already set");
        require(IOption(_optionAddress).getExpiresOn() < block.timestamp, "Still not expired");
        
        //Gets the price in WEI for 1 usdtToken
        uint256 usdPriceOfEth = uint256(priceConsumer.getLatestPrice());
        //I need the price in USDT for 1 ETH
        uint256 spotPrice = uint256(1 ether) / usdPriceOfEth;
        uint256 strike = IOption(_optionAddress).getStrike();

        uint256 optionWorth = 0;
        
        bool isPut = IOption(_optionAddress).isPut();
    
        if (isPut && spotPrice < strike) {
            optionWorth = strike - spotPrice;
        }
        else if (!isPut && spotPrice > strike) {
            optionWorth = spotPrice - strike;
        }
        
        options[_optionAddress].etherPriceInUSDTAtMaturity = spotPrice;
        options[_optionAddress].optionWorth = optionWorth * 1e6;
        
        emit OptionFinalPriceSet(_optionAddress, spotPrice, optionWorth);
    }
    
    function _withdrawFees() public onlyOwner {
        require(totalFees > 0, 'Nothing to claim');
        uint256 amount = totalFees;
        totalFees = 0;
        payable(msg.sender).transfer(amount);
    }

    function _withdrawETH(uint256 _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }
    
    function _withdrawUSDT(uint256 _amount) public onlyOwner {
        SafeERC20.safeTransfer(usdtToken, msg.sender, _amount);
    }
    
    function _withdrawKibo(uint256 _amount) public onlyOwner {
        SafeERC20.safeTransfer(kiboToken, msg.sender, _amount);
    }
    
    function getOption(address _optionAddress) public view returns (bool _isValid, bool _isPut, uint256 _etherPriceInUSDTAtMaturity, uint256 _optionWorth) {
        return (options[_optionAddress].isValid, IOption(_optionAddress).isPut(), options[_optionAddress].etherPriceInUSDTAtMaturity, options[_optionAddress].optionWorth);
    }
    
    function getSeller(address _optionAddress, address _seller) public view returns (bool _isValid, uint256 _collateral, uint256 _notional, bool _claimed) {
        Seller memory seller = options[_optionAddress].sellers[_seller];
        return (seller.isValid, seller.collateral, seller.notional, seller.claimed);
    }

    receive() external payable {
        revert();
    }
}