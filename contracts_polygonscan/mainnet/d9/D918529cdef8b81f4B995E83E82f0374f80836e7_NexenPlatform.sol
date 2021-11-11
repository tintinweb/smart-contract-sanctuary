// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

pragma solidity ^0.8.9;

interface IPriceConsumerV3 {
    function getLatestPrice() external view returns (int);
}

interface IUniswapV2Router02 {
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
      
    function WETH() external returns (address); 
    
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}


contract NexenPlatform is Ownable {
    using SafeERC20 for IERC20;

    enum RequestState {None, LenderCreated, BorrowerCreated, Cancelled, Matched, Closed, Expired, Disabled}
    enum Currency {DAI, USDT, ETH}
    
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    
    IPriceConsumerV3 public priceConsumerDAI;
    IPriceConsumerV3 public priceConsumerUSDT;
    
    IERC20 public nexenToken;
    
    ERC20 daiToken = ERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063); 
    ERC20 usdtToken = ERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    
    bool public paused = false;
    bool public genesisPhase = false;
    uint256 public amountToReward = 1000 * 10 ** 18;
    
    uint public lenderFee = 1; //1%
    uint public borrowerFee = 1; //1%
    
    mapping(uint256 => uint256) public interests;

    mapping(address => uint256) public depositedDAI;
    mapping(address => uint256) public depositedUSDT;
    mapping(address => uint256) public depositedWEI;
    
    uint256 public daiFees;
    uint256 public usdtFees;
    uint256 public ethFees;
    
    struct Request {
        // Internal fields
        RequestState state;
        address payable borrower;
        address payable lender;
        Currency currency;
        // Fields for both parties
        uint256 cryptoAmount;
        uint256 durationInDays;
        uint256 expireIfNotMatchedOn;
        // Fields for borrower
        uint256 ltv;
        uint256 weiAmount;
        uint256 daiVsWeiCurrentPrice;
        uint256 usdtVsWeiCurrentPrice;
        // Fields after matching
        uint256 lendingFinishesOn;
    }
    
    mapping (uint256 => Request) public requests;
    
    event OpenRequest(uint256 requestId, address indexed borrower, address indexed lender, uint256 cryptoAmount, uint256 durationInDays, uint256 expireIfNotMatchedOn, uint256 ltv, uint256 weiAmount, uint256 daiVsWeiCurrentPrice, uint256 usdtVsWeiCurrentPrice, uint256 lendingFinishesOn, RequestState state, Currency currency);
    event RequestMatchedBorrower(uint256 requestId, address indexed borrower, address indexed lender, uint256 cryptoAmount, uint256 weiAmount, uint256 daiVsWeiCurrentPrice, uint256 usdtVsWeiCurrentPrice);
    event RequestMatchedLender(uint256 requestId, address indexed borrower, address indexed lender, uint256 cryptoAmount);
    event RequestCancelled(uint256 requestId, address indexed borrower, address indexed lender, RequestState state, uint256 weiAmount, uint256 cryptoAmount);
    event RequestFinishedForLender(uint256 requestId, address indexed lender, uint256 daiToTransfer, uint256 totalLenderFee);
    event RequestFinishedForBorrower(uint256 requestId, address indexed borrower, uint256 daiToTransfer, uint256 weiAmount, uint256 totalBorrowerFee);
    event CollateralSoldBorrower(uint256 requestId, address indexed borrower, uint256 weiAmount, uint256 amountSold, uint256 daiToTransfer, uint256 weiRecovered, uint256 totalBorrowerFee);
    event CollateralSoldLender(uint256 requestId, address indexed lender, uint256 weiAmount, uint256 amountSold, uint256 tokenToTransfer, uint256 tokenRecovered, uint256 totalLenderFee);
    event CoinDeposited(address indexed caller, uint256 value, Currency currency);
    event CoinWithdrawn(address indexed caller, uint256 value, Currency currency);

    receive() external payable {
        
    }

    constructor(IPriceConsumerV3 _priceConsumerDAI, IPriceConsumerV3 _priceConsumerUSDT) {
        priceConsumerDAI = _priceConsumerDAI;
        priceConsumerUSDT = _priceConsumerUSDT;
        
        interests[20] = 4;
        interests[40] = 6;
        interests[60] = 8;
    }
    
    function createRequest(bool lend, uint256 cryptoAmount, uint256 durationInDays, uint256 expireIfNotMatchedOn, uint256 ltv, Currency currency) public payable {
        require(currency == Currency.USDT || currency == Currency.DAI, "Invalid currency");
        require(expireIfNotMatchedOn > block.timestamp, "Invalid expiration date");
        require(!paused, "The contract is paused");

        if (currency == Currency.USDT) {
            require(cryptoAmount >= 100 * 10 ** 6, "Minimum amount is 100 USDT");
        } else {
            require(cryptoAmount >= 100 * 10 ** 18, "Minimum amount is 100 DAI");
        }
        
        Request memory r;
        (r.cryptoAmount, r.durationInDays, r.expireIfNotMatchedOn, r.currency) = (cryptoAmount, durationInDays, expireIfNotMatchedOn, currency);
        
        if (lend) {
            r.lender = payable(msg.sender);
            r.state = RequestState.LenderCreated;
            
            if (currency == Currency.USDT) {
                require(depositedUSDT[msg.sender] >= r.cryptoAmount, "Not enough USDT deposited");
                depositedUSDT[msg.sender] -= r.cryptoAmount;
            } else {
                require(depositedDAI[msg.sender] >= r.cryptoAmount, "Not enough DAI deposited");
                depositedDAI[msg.sender] -= r.cryptoAmount;
            }
        } else {
            require(interests[ltv] > 0, 'Invalid LTV');
            
            r.borrower = payable(msg.sender);
            r.state = RequestState.BorrowerCreated;
            r.ltv = ltv;
            
            if (currency == Currency.USDT) {
                r.usdtVsWeiCurrentPrice = uint256(priceConsumerUSDT.getLatestPrice());
                r.weiAmount = calculateWeiAmountForUSDT(r.cryptoAmount, ltv, r.usdtVsWeiCurrentPrice);
            } else {
                r.daiVsWeiCurrentPrice = uint256(priceConsumerDAI.getLatestPrice());
                r.weiAmount = calculateWeiAmountForDAI(r.cryptoAmount, ltv, r.daiVsWeiCurrentPrice);
            }

            //We take the payment from the msg.value or from the deposited WEI
            if (msg.value > r.weiAmount) {
                payable(msg.sender).transfer(msg.value - r.weiAmount);
            }
            else if (msg.value < r.weiAmount) {
                require(depositedWEI[msg.sender] > (r.weiAmount - msg.value), "Not enough ETH deposited");
                depositedWEI[msg.sender] = depositedWEI[msg.sender] - r.weiAmount + msg.value;
            }
        }

        uint256 requestId = uint256(keccak256(abi.encodePacked(r.borrower, r.lender, r.cryptoAmount, r.durationInDays, r.expireIfNotMatchedOn, r.ltv, r.currency)));
        
        require(requests[requestId].state == RequestState.None, 'Request already exists');
        
        requests[requestId] = r;

        emit OpenRequest(requestId, r.borrower, r.lender, r.cryptoAmount, r.durationInDays, r.expireIfNotMatchedOn, r.ltv, r.weiAmount, r.daiVsWeiCurrentPrice, r.usdtVsWeiCurrentPrice, r.lendingFinishesOn, r.state, r.currency);
    }
    
    function matchRequestAsLender(uint256 requestId) public {
        Request storage r = requests[requestId];
        require(r.state == RequestState.BorrowerCreated, 'Invalid request');
        require(r.expireIfNotMatchedOn > block.timestamp, 'Request expired');
        require(r.borrower != msg.sender, 'You cannot match yourself');

        r.lender = payable(msg.sender);
        r.lendingFinishesOn = getExpirationAfter(r.durationInDays);
        r.state = RequestState.Matched;
        
        if (r.currency == Currency.DAI) {
            require(depositedDAI[msg.sender] >= r.cryptoAmount, "Not enough DAI deposited");
            depositedDAI[msg.sender] -= r.cryptoAmount;
            depositedDAI[r.borrower] += r.cryptoAmount;
        } else {
            require(depositedUSDT[msg.sender] >= r.cryptoAmount, "Not enough USDT deposited");
            depositedUSDT[msg.sender] -= r.cryptoAmount;
            depositedUSDT[r.borrower] += r.cryptoAmount;
        }
        
        if (genesisPhase) {
            require(nexenToken.transfer(msg.sender, amountToReward), 'Could not transfer tokens');
            require(nexenToken.transfer(r.borrower, amountToReward), 'Could not transfer tokens');
        }
        
        emit RequestMatchedLender(requestId, r.borrower, r.lender, r.cryptoAmount);
    }
    
    function matchRequestAsBorrower(uint256 requestId, uint256 ltv) public {
        Request storage r = requests[requestId];
        require(r.state == RequestState.LenderCreated, 'Invalid request');
        require(r.expireIfNotMatchedOn > block.timestamp, 'Request expired');
        require(r.lender != msg.sender, 'You cannot match yourself');

        r.borrower = payable(msg.sender);
        r.lendingFinishesOn = getExpirationAfter(r.durationInDays);
        r.state = RequestState.Matched;
        
        r.ltv = ltv;
        
        if (r.currency == Currency.DAI) {
            r.daiVsWeiCurrentPrice = uint256(priceConsumerDAI.getLatestPrice());
            r.weiAmount = calculateWeiAmountForDAI(r.cryptoAmount, r.ltv, r.daiVsWeiCurrentPrice);
            depositedDAI[r.borrower] += r.cryptoAmount;
        } else {
            r.usdtVsWeiCurrentPrice = uint256(priceConsumerUSDT.getLatestPrice());
            r.weiAmount = calculateWeiAmountForUSDT(r.cryptoAmount, r.ltv, r.usdtVsWeiCurrentPrice);
            depositedUSDT[r.borrower] += r.cryptoAmount;
        }
        
        require(depositedWEI[msg.sender] > r.weiAmount, "Not enough WEI");
        depositedWEI[msg.sender] -= r.weiAmount;

        if (genesisPhase) {
            require(nexenToken.transfer(msg.sender, amountToReward), 'Could not transfer tokens');
            require(nexenToken.transfer(r.lender, amountToReward), 'Could not transfer tokens');
        }

        emit RequestMatchedBorrower(requestId, r.borrower, r.lender, r.cryptoAmount, r.weiAmount, r.daiVsWeiCurrentPrice, r.usdtVsWeiCurrentPrice);
    }
    
    function cancelRequest(uint256 requestId) public {
        Request storage r = requests[requestId];
        require(r.state == RequestState.BorrowerCreated || r.state == RequestState.LenderCreated);
        
        r.state = RequestState.Cancelled;

        if (msg.sender == r.borrower) {
            depositedWEI[msg.sender] += r.weiAmount;
        } else if (msg.sender == r.lender) {
            if (r.currency == Currency.DAI) {
                depositedDAI[msg.sender] += r.cryptoAmount;
            } else {
                depositedUSDT[msg.sender] += r.cryptoAmount;
            }
        } else {
            revert();
        }

        emit RequestCancelled(requestId, r.borrower, r.lender, r.state, r.weiAmount, r.cryptoAmount);
    }
    
    function finishRequest(uint256 _requestId) public {
        Request storage r = requests[_requestId];
        require(r.state == RequestState.Matched, "State needs to be Matched");
        
        require(msg.sender == r.borrower, 'Only borrower can call this');

        r.state = RequestState.Closed;
        
        uint256 cryptoToTransfer = getInterest(r.ltv, r.cryptoAmount) + r.cryptoAmount;
        
        uint256 totalLenderFee = computeLenderFee(r.cryptoAmount);
        uint256 totalBorrowerFee = computeBorrowerFee(r.weiAmount);
        ethFees += totalBorrowerFee;

        if (r.currency == Currency.DAI) {
            require(depositedDAI[r.borrower] >= cryptoToTransfer, "Not enough DAI deposited");
            daiFees += totalLenderFee;
            depositedDAI[r.lender] += cryptoToTransfer - totalLenderFee;
            depositedDAI[r.borrower] -= cryptoToTransfer;
        } else {
            require(depositedUSDT[r.borrower] >= cryptoToTransfer, "Not enough USDT deposited");
            usdtFees = daiFees + totalLenderFee;
            depositedUSDT[r.lender] += cryptoToTransfer - totalLenderFee;
            depositedUSDT[r.borrower] -= cryptoToTransfer;
        }

        depositedWEI[r.borrower] += r.weiAmount - totalBorrowerFee;
        
        emit RequestFinishedForLender(_requestId, r.lender, cryptoToTransfer - totalLenderFee, totalLenderFee);
        emit RequestFinishedForBorrower(_requestId, r.borrower, cryptoToTransfer, r.weiAmount - totalBorrowerFee, totalBorrowerFee);
    }
    
    function expireNonFullfiledRequest(uint256 _requestId) public {
        Request storage r = requests[_requestId];

        require(r.state == RequestState.Matched, "State needs to be Matched");
        require(msg.sender == r.lender, "Only lender can call this");
        require(block.timestamp > r.lendingFinishesOn, "Request not finished yet");
        
        r.state = RequestState.Expired;
        
        burnCollateral(_requestId, r);
    }
    
    function burnCollateral(uint256 _requestId, Request storage r) internal {
        //Minimum that we should get according to Chainlink
        //r.weiAmount.div(daiVsWeiCurrentPrice);

        //But we will use as minimum the amount we need to return to the Borrower
        uint256 cryptoToTransfer = getInterest(r.ltv, r.cryptoAmount) + r.cryptoAmount;
        
        uint256[] memory amounts = sellCollateralInUniswap(cryptoToTransfer, r.weiAmount, r.currency);
        //amounts[0] represents how much ETH was actually sold        
        
        uint256 dust = r.weiAmount - amounts[0];
        
        uint256 totalLenderFee = computeLenderFee(r.cryptoAmount);
        uint256 totalBorrowerFee = computeBorrowerFee(r.weiAmount);

        if (totalBorrowerFee > dust) {
            totalBorrowerFee = dust;
        }
        
        if (r.currency == Currency.DAI) {
            daiFees = daiFees + totalLenderFee;
            depositedDAI[r.lender] += cryptoToTransfer - totalLenderFee;
        } else {
            usdtFees = usdtFees + totalLenderFee;
            depositedUSDT[r.lender] += cryptoToTransfer - totalLenderFee;
        }

        ethFees = ethFees + totalBorrowerFee;
        depositedWEI[r.borrower] += dust - totalBorrowerFee;
        
        emit CollateralSoldBorrower(_requestId, r.borrower, r.weiAmount, amounts[0], cryptoToTransfer, dust - totalBorrowerFee, totalBorrowerFee);
        emit CollateralSoldLender(_requestId, r.lender, r.weiAmount, amounts[0], cryptoToTransfer, cryptoToTransfer - totalLenderFee, totalLenderFee);
    }
    
    function sellCollateralInUniswap(uint256 tokensToTransfer, uint256 weiAmount, Currency currency) internal returns (uint256[] memory)  {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        
        if (currency == Currency.DAI) {
            path[1] = address(daiToken);
        } else {
            path[1] = address(usdtToken);
        }
        
        return uniswapRouter.swapETHForExactTokens{value:weiAmount}(tokensToTransfer, path, address(this), block.timestamp);
    }

    function canBurnCollateralForDAI(uint256 requestId, uint256 daiVsWeiCurrentPrice) public view returns (bool) {
        Request memory r = requests[requestId];
        
        uint256 howMuchEthTheUserCanGet = r.cryptoAmount * daiVsWeiCurrentPrice / 1e18;
        uint256 eigthyPercentOfCollateral = r.weiAmount * 8 / 10;
        
        return howMuchEthTheUserCanGet > eigthyPercentOfCollateral;
    }    

    function canBurnCollateralForUSDT(uint256 requestId, uint256 usdtVsWeiCurrentPrice) public view returns (bool) {
        Request memory r = requests[requestId];
        
        uint256 howMuchEthTheUserCanGet = r.cryptoAmount * usdtVsWeiCurrentPrice / 1e6;
        uint256 eigthyPercentOfCollateral = r.weiAmount * 8 / 10;
        
        return howMuchEthTheUserCanGet > eigthyPercentOfCollateral;
    }    
    
    //Calculates the amount of WEI that is needed as a collateral for this amount of DAI and the chosen LTV
    function calculateWeiAmountForDAI(uint256 _daiAmount, uint256 _ltv, uint256 _daiVsWeiCurrentPrice) public pure returns (uint256) {
        //I calculate the collateral in DAI, then I change it to WEI and I remove the decimals from the token
        return _daiAmount * 100 / _ltv * _daiVsWeiCurrentPrice / 1e18;
    }

    //Calculates the amount of WEI that is needed as a collateral for this amount of USDT and the chosen LTV
    function calculateWeiAmountForUSDT(uint256 _usdtAmount, uint256 _ltv, uint256 _usdtVsWeiCurrentPrice) public pure returns (uint256) {
        //I calculate the collateral in USDT, then I change it to WEI and I remove the decimals from the token
        return _usdtAmount * 100 / _ltv * _usdtVsWeiCurrentPrice / 1e6;
    }

    function calculateCollateralForDAI(uint256 daiAmount, uint256 ltv) public view returns (uint256) {
        //Gets the current price in WEI for 1 DAI
        uint256 daiVsWeiCurrentPrice = uint256(priceConsumerDAI.getLatestPrice());
        //Gets the collateral needed in WEI
        return calculateWeiAmountForDAI(daiAmount, ltv, daiVsWeiCurrentPrice);
    }
    
    function calculateCollateralForUSDT(uint256 usdtAmount, uint256 ltv) public view returns (uint256) {
        //Gets the current price in WEI for 1 USDT
        uint256 usdtVsWeiCurrentPrice = uint256(priceConsumerUSDT.getLatestPrice());
        //Gets the collateral needed in WEI
        return calculateWeiAmountForUSDT(usdtAmount, ltv, usdtVsWeiCurrentPrice);
    }
    
    function getLatestDAIVsWeiPrice() public view returns (uint256) {
        return uint256(priceConsumerDAI.getLatestPrice());
    }

    function getLatestUSDTVsWeiPrice() public view returns (uint256) {
        return uint256(priceConsumerUSDT.getLatestPrice());
    }
    
    function getInterest(uint256 _ltv, uint256 _amount) public view returns (uint256) {
        require(interests[_ltv] > 0, "invalid LTV");
        return _amount * interests[_ltv] / 100;
    }
    
    function computeLenderFee(uint256 _value) public view returns (uint256) {
        return _value * lenderFee / 100; 
    }

    function computeBorrowerFee(uint256 _value) public view returns (uint256) {
        return _value * borrowerFee / 100; 
    }
    
    function getExpirationAfter(uint256 amountOfDays) public view returns (uint256) {
        return block.timestamp + amountOfDays * 1 days;
    }
    
    // Withdraw and Deposit functions
    
    function withdrawUSDT(uint256 _amount) public {
        require(depositedUSDT[msg.sender] >= _amount, "Not enough USDT deposited");
        require(ERC20(usdtToken).balanceOf(address(this)) >= _amount, "Not enough balance in contract");
        
        depositedUSDT[msg.sender] -= _amount;
        IERC20(usdtToken).safeTransfer(msg.sender, _amount);
        
        emit CoinWithdrawn(msg.sender, _amount, Currency.USDT);
    }

    function withdrawDAI(uint256 _amount) public {
        require(depositedDAI[msg.sender] >= _amount, "Not enough DAI deposited");
        require(daiToken.balanceOf(address(this)) >= _amount, "Not enough balance in contract");
        
        depositedDAI[msg.sender] -= _amount;
        require(daiToken.transfer(msg.sender, _amount));
        
        emit CoinWithdrawn(msg.sender, _amount, Currency.DAI);
    }
    
    function withdrawETH(uint256 _amount) public {
        require(depositedWEI[msg.sender] >= _amount, "Not enough ETH deposited");
        require(address(this).balance >= _amount, "Not enough balance in contract");
        
        depositedWEI[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        
        emit CoinWithdrawn(msg.sender, _amount, Currency.ETH);
    }
    
        function _updateNexenTokenAddress(IERC20 _nexenToken) public onlyOwner {
        nexenToken = _nexenToken;
    }

    function depositETH() public payable {
        require(msg.value > 10000000000000000, 'Minimum is 0.01 ETH');
        depositedWEI[msg.sender] += msg.value;

        emit CoinDeposited(msg.sender, msg.value, Currency.ETH);
    }

    function depositDAI(uint256 _amount) public {
        require(IERC20(daiToken).transferFrom(msg.sender, address(this), _amount), "Couldn't take the DAI from the sender");
        depositedDAI[msg.sender] += _amount;

        emit CoinDeposited(msg.sender, _amount, Currency.DAI);
    }
    
    
    function depositUSDT(uint256 _amount) public {
        IERC20(usdtToken).safeTransferFrom(msg.sender, address(this), _amount);
        depositedUSDT[msg.sender] += _amount;
        
        emit CoinDeposited(msg.sender, _amount, Currency.USDT);
    }
    
    //Admin functions
        
    function _expireRequest(uint256 _requestId) public onlyOwner {
        Request storage r = requests[_requestId];

        require(r.state == RequestState.Matched, "State needs to be Matched");
        
        if (r.currency == Currency.DAI) {
            uint256 daiVsWeiCurrentPrice = uint256(priceConsumerDAI.getLatestPrice());
            require(canBurnCollateralForDAI(_requestId, daiVsWeiCurrentPrice), "We cannot burn the collateral");
        } else {
            uint256 usdtVsWeiCurrentPrice = uint256(priceConsumerUSDT.getLatestPrice());
            require(canBurnCollateralForUSDT(_requestId, usdtVsWeiCurrentPrice), "We cannot burn the collateral");
        }
        
        r.state = RequestState.Disabled;

        burnCollateral(_requestId, r);
    }
    
    function _setInterest(uint256 _ltv, uint256 _interest) public onlyOwner {
        interests[_ltv] = _interest;
    }
    
    function _withdrawFees(Currency currency) public onlyOwner {
        if (currency == Currency.ETH) {
            uint256 amount = ethFees;
            ethFees = 0;
            payable(msg.sender).transfer(amount);
        } else if (currency == Currency.USDT) {
            uint256 amount = usdtFees;
            usdtFees = 0;
            IERC20(usdtToken).safeTransfer(msg.sender, amount);
        } else { 
            uint256 amount = daiFees;
            daiFees = 0;
            require(daiToken.transfer(msg.sender, amount), "Transfer failed");
        }
    }
    
    function _setGenesisPhase(IERC20 _nexenToken, bool _genesisPhase, uint256 _amountToReward) public onlyOwner {
        nexenToken = _nexenToken;
        genesisPhase = _genesisPhase;
        amountToReward = _amountToReward;
    }
    
    function _setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }
    
    function _recoverNexenTokens(uint256 _amount) public onlyOwner {
        require(nexenToken.transfer(msg.sender, _amount), 'Could not transfer tokens');
    }
    
    function requestInfo(uint256 requestId) public view  returns (uint256 _tradeId, RequestState _state, address _borrower, address _lender, uint256 _cryptoAmount, uint256 _durationInDays, uint256 _expireIfNotMatchedOn, uint256 _ltv, uint256 _weiAmount, uint256 _tokenVsWeiCurrentPrice, uint256 _lendingFinishesOn, Currency currency) {
        Request storage r = requests[requestId];
        uint256 tokenVsWeiCurrentPrice = r.daiVsWeiCurrentPrice;
        if (r.currency == Currency.USDT) {
            tokenVsWeiCurrentPrice = r.usdtVsWeiCurrentPrice;
        }
        return (requestId, r.state, r.borrower, r.lender, r.cryptoAmount, r.durationInDays, r.expireIfNotMatchedOn, r.ltv, r.weiAmount, tokenVsWeiCurrentPrice, r.lendingFinishesOn, r.currency);
    }
}