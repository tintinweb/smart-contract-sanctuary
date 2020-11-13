pragma solidity >= 0.6 .6;

interface bzxRead {

    function getLoan(bytes32 loanId) external view returns(bytes32 loanId1, uint96 endTimestamp, address loanToken, address collateralToken, uint256 principal, uint256 collateral, uint256 interestOwedPerDay, uint256 interestDepositRemaining, uint256 startRate, uint256 startMargin, uint256 maintenanceMargin, uint256 currentMargin, uint256 maxLoanTerm, uint256 maxLiquidatable, uint256 maxSeizable);
}

interface bzxWrite {
    function liquidate(bytes32 loanId, address receiver, uint256 closeAmount) payable external;

}

interface UniswapV2 {


    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns(uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns(uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns(uint256 amountToken, uint256 amountETH);

    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns(uint256 amountA, uint256 amountB);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);

}


interface FlashLoanInterface {
    function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes calldata _params) external;
}


interface ERC20 {
    function totalSupply() external view returns(uint supply);

    function balanceOf(address _owner) external view returns(uint balance);

    function transfer(address _to, uint _value) external returns(bool success);

    function transferFrom(address _from, address _to, uint _value) external returns(bool success);

    function approve(address _spender, uint _value) external returns(bool success);

    function allowance(address _owner, address _spender) external view returns(uint remaining);

    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}


contract BZXAAVEFLASHLIQUIDATE {


    address payable owner;
    address ETH_TOKEN_ADDRESS = address(0x0);
    address payable aaveRepaymentAddress = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    address uniAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    bzxRead bzx0 = bzxRead(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);

    address bzx1Address = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f;

    bzxWrite bzx1 = bzxWrite(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);
    UniswapV2 usi = UniswapV2(uniAddress);
    FlashLoanInterface fli = FlashLoanInterface(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    bytes theBytes;


    address aaveEthAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    ERC20 wethToken = ERC20(wethAddress);

    address currentCToken;
    address currentLToken;

    uint256 currentMaxLiq;
    bytes32 currentLoanId;


    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }



    constructor() public payable {
        owner = msg.sender;

    }

    fallback() external payable {

    }


    function updateBZXs(address newAddress) onlyOwner public {
        bzxRead bzx0 = bzxRead(newAddress);

        address bzx1Address = newAddress;

        bzxWrite bzx1 = bzxWrite(newAddress);
    }

    function updateFlashLoanAddress(address newAddress) onlyOwner public {
        FlashLoanInterface fli = FlashLoanInterface(newAddress);
    }


    function updateAaveEthAddress(address newAddress) onlyOwner public {
        aaveEthAddress = newAddress;
    }


    function updateAaveRepayment(address payable newAddress) onlyOwner public {
        aaveRepaymentAddress = newAddress;
    }

    function updateUniAddress(address newAddress) onlyOwner public {
        UniswapV2 usi = UniswapV2(newAddress);
    }

    function setLoanInfo(address cToken, address lToken, uint maxLiq, bytes32 loanId2) public onlyOwner {
        currentCToken = cToken;
        currentLToken = lToken;
        currentMaxLiq = maxLiq;
        currentLoanId = loanId2;
    }

    function getLoanInfo1(bytes32 loanId) public view returns(bytes32 loanId1, address loanToken, address collateralToken, uint256 principal, uint256 collateral, uint256 maxLiquidatable) {
        
        (bytes32 loanId1, , address loanToken, address collateralToken, uint256 principal, uint256 collateral, , , , , , , , uint256 maxLiquidatable, ) = bzx0.getLoan(loanId);
        return (loanId1, loanToken, collateralToken, principal, collateral, maxLiquidatable);
    }


    function flashLoanAndLiquidate(bytes32 loanId) onlyOwner public {
        
        (bytes32 loanId1, uint96 endTimestamp, address loanToken, address collateralToken, uint256 principal, uint256 collateral, , , , , , uint256 currentMargin, uint256 maxLoanTerm, uint256 maxLiquidatable, uint256 maxSeizable) = bzx0.getLoan(loanId);
        currentCToken = collateralToken;
        currentLToken = loanToken;
        currentMaxLiq = maxLiquidatable;
        currentLoanId = loanId;

        address tokenAddToUse = loanToken;
        if (loanToken == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            tokenAddToUse = aaveEthAddress;
        }

        performFlash(tokenAddToUse, maxLiquidatable);
  
    }

    function performFlash(address tokenAddToUse, uint maxLiquidatable) public onlyOwner {
        fli.flashLoan(address(this), tokenAddToUse, maxLiquidatable, theBytes);
    }


    function performUniswap(address sellToken, address buyToken, uint256 amountSent) public returns(uint256 amounts1) {


        ERC20 sellToken1 = ERC20(sellToken);
        ERC20 buyToken1 = ERC20(currentLToken);

       if (sellToken1.allowance(address(this), uniAddress) <= amountSent) {

            sellToken1.approve(uniAddress, 100000000000000000000000000000000000);

       }


        require(sellToken1.balanceOf(address(this)) >= amountSent, "You dont have enough CtokormUniswap");


        address[] memory addresses = new address[](2);

        addresses[0] = sellToken;
        addresses[1] = buyToken;



        uint256[] memory amounts = performUniswapActual(addresses, amountSent);
        uint256 resultingTokens = amounts[1];
        return resultingTokens;

    }

    function performUniswapActual(address[] memory theAddresses, uint amount) public returns(uint256[] memory amounts1) {


        
        uint256 deadline = 1000000000000000;

        uint256[] memory amounts = usi.swapExactTokensForTokens(amount, 1, theAddresses, address(this), deadline);


        return amounts;

    }


    function performTrade(bool isItEther, uint256 amount1) public returns(uint256) {


        uint256 startingETHBalance = address(this).balance;
        ERC20 tokenToReceive = ERC20(currentCToken);
        uint256 startingCBalance = tokenToReceive.balanceOf(address(this));

        if (isItEther == true) {

        } else {
            ERC20 bzLToken = ERC20(currentLToken);

            if (bzLToken.allowance(address(this), bzx1Address) <= currentMaxLiq) {
                bzLToken.approve(bzx1Address, (currentMaxLiq * 100));
            }
        }

        if (isItEther == false) {
            bzx1.liquidate(currentLoanId, address(this), currentMaxLiq);
        } else {
            bzx1.liquidate.value(amount1)(currentLoanId, address(this), currentMaxLiq);
        }



        uint256 amountBack = 0;
        if (address(this).balance > startingETHBalance) {
            uint256 newETH = address(this).balance - startingETHBalance;
            wethToken.deposit.value(newETH)();


            amountBack = performUniswap(wethAddress, currentLToken, newETH);
        }
        else {



            uint256 difCBalance = tokenToReceive.balanceOf(address(this)) - startingCBalance;
           require(difCBalance >0, "Balance of Collateral token didnt go up after swap didnt go up");


           amountBack = performUniswap(currentCToken, currentLToken, difCBalance);
        }

        return amountBack;

    }


    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external {
        bool isEther;
        if (_reserve == aaveEthAddress) {
            isEther = true;
        } else {
            isEther = false;
        }



        uint256 tradeResp = performTrade(isEther, _amount);
        require(tradeResp > 0, "You didnt fet anything from uni");

        if (_reserve == aaveEthAddress) {

            uint256 repayAmount = (_amount + _fee);
            uint256 ourEthBalance = address(this).balance;


            wethToken.withdraw((_amount + _fee));
            require(tradeResp >= (repayAmount / 10), "Not enough eth");

            
            aaveRepaymentAddress.call {
                value: repayAmount
            }("");

        } else {
            ERC20 firstToken = ERC20(_reserve);
            firstToken.transfer(aaveRepaymentAddress, (_amount + _fee));
        }


    }

    function changeOwner(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    function getTokenBalance(address tokenAddress) public view returns(uint256) {
        ERC20 theToken = ERC20(tokenAddress);
        return theToken.balanceOf(address(this));
    }


    function withdraw(address token) public onlyOwner returns(bool) {


        if (address(token) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            uint256 amount = address(this).balance;

            
            msg.sender.transfer(amount);

        }
        
        else {
            ERC20 tokenToken = ERC20(token);
            uint256 tokenBalance = tokenToken.balanceOf(address(this));
            require(tokenToken.transfer(msg.sender, (tokenBalance)));

        }


        return true;
    }

    function kill() virtual public {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }
}