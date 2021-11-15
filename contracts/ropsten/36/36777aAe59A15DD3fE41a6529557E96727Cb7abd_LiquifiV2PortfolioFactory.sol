// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { PortfolioFactory } from "./interfaces/PortfolioFactory.sol";
import { GovernanceRouter } from "./interfaces/GovernanceRouter.sol";
import { LiquifiV2Portfolio } from "./LiquifiV2Portfolio.sol";

contract LiquifiV2PortfolioFactory is PortfolioFactory {
    address[] public override portfolios;
    GovernanceRouter public override governanceRouter;
    address public override weth;

    constructor(address _governanceRouter) {
        governanceRouter = GovernanceRouter(_governanceRouter);
        weth = address(GovernanceRouter(_governanceRouter).weth());
    }

    function getPortfolioCount() external override view returns (uint) {
        return portfolios.length;
    }

    function getMainPortfolio() external override view returns (address) {
        require(portfolios.length > 0, "ERROR: No portfolios have been added yet");
        return portfolios[0];
    }

    function addPortfolio(uint feeDenominator) external override returns (address portfolio){
        require(msg.sender == address(governanceRouter.governor()), "ERROR: Only governor can add portfolios");
        bool isMain = portfolios.length == 0 ? true : false;
        portfolio = address(new LiquifiV2Portfolio{ /* make portfolio address deterministic */ salt: bytes32(uint(1))}(
            isMain, portfolios.length, address(governanceRouter), feeDenominator
        ));
        portfolios.push(portfolio);
        governanceRouter.minter().addPortfolio(portfolio);
        governanceRouter.oracle().addNewPortfolio(portfolio);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { GovernanceRouter } from "./GovernanceRouter.sol";

interface PortfolioFactory {
    event PortfolioCreatedEvent(address indexed portfolio);

    function portfolios(uint reserveIndex) external view returns (address portfolio);
    function governanceRouter() external view returns (GovernanceRouter);
    function weth() external view returns (address);

    function getPortfolioCount() external view returns (uint);
    function getMainPortfolio() external view returns (address);

    function addPortfolio(uint feeDenominator) external returns (address portfolio);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { WETH } from "./WETH.sol";
import { PortfolioFactory } from "./PortfolioFactory.sol";
import { Oracle } from "./Oracle.sol";
import { Minter } from "./Minter.sol";

interface GovernanceRouter {
    event GovernorChanged(address governor);
    event PortfolioFactoryChanged(address portfolioFactory);
    event OracleChanged(address oracle);
    event MinterChanged(address minter);

    function creator() external view returns(address);
    function weth() external view returns(WETH);
    

    function portfolioFactory() external view returns(PortfolioFactory);
    function setPortfolioFactory(PortfolioFactory _portfolioFactory) external;

    function governor() external view returns(address); 
    function setGovernor(address _governor) external;
    
    function oracle() external view returns(Oracle);
    function setOracle(Oracle _oracle) external;

    function minter() external view returns(Minter);
    function setMinter(Minter _minter) external; 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { Portfolio, ConvertETH } from "./interfaces/Portfolio.sol";
import { WETH } from "./interfaces/WETH.sol";
import { ReserveFactory, LiquifiV2ReserveFactory } from "./LiquifiV2ReserveFactory.sol";
import { Minter } from "./interfaces/Minter.sol";
import { LiquifiV2LiquidityReserve } from "./LiquifiV2LiquidityReserve.sol";
import { GovernanceRouter } from "./interfaces/GovernanceRouter.sol";
import { ERC20 } from "./interfaces/ERC20.sol";
import { Oracle } from "./interfaces/Oracle.sol";

contract LiquifiV2Portfolio is Portfolio {
    ReserveFactory public override immutable factory;
    WETH public override immutable weth;
    GovernanceRouter public override immutable governanceRouter;
    Minter public override immutable minter;
    Oracle public override immutable oracle;

    bool public override immutable isMain;
    uint public override immutable portfolioIndex;
    uint public override feeDenominator;

    constructor(bool _isMain, uint _portfolioIndex, address _governanceRouter, uint _feeDenominator) {
        governanceRouter = GovernanceRouter(_governanceRouter);
        weth = GovernanceRouter(_governanceRouter).weth();
        factory = new LiquifiV2ReserveFactory(_governanceRouter);
        minter = GovernanceRouter(_governanceRouter).minter();
        oracle = GovernanceRouter(_governanceRouter).oracle();

        isMain = _isMain;
        portfolioIndex = _portfolioIndex;
        feeDenominator = _feeDenominator;
    }

    function setFee(uint _feeDenominator) external override {
        require(msg.sender == governanceRouter.governor(), "ERROR: only governor can change fee");
        feeDenominator = _feeDenominator;
    }

    function smartTransferFrom(address token, address from, address to, uint value, ConvertETH convertETH) internal returns(bool) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
            ERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERROR: TRANSFER_FROM_FAILED');
        return true;
    }

    function _deposit(address token, uint amount, address from, ConvertETH convertETH) private returns (uint liquidityOut){
        address reserve = factory.findReserve(token);
        require(reserve != address(0), "ERROR: Reserve doesn`t exist");

        //TODO: Add side pools logic.
        liquidityOut = oracle.curPrice(reserve) * amount;
        require(smartTransferFrom(token, from, reserve, amount, convertETH), "ERROR: Deposit failed");
        
        oracle.addedToReserve(reserve, amount);
        minter.mint(from, liquidityOut);
    }

    function deposit(address token, uint amount) external override returns (uint liquidityOut) {
        return _deposit(token, amount, msg.sender, ConvertETH.NONE);
    }

    function _withdraw(address token, uint liquidity, address to, ConvertETH convertETH) private returns (uint amount){
        address payable reserve = factory.findReserve(token);
        require(reserve != address(0), "LIQUIFI: WITHDRAW_FROM_INVALID_RESERVE");
        uint maxWithdrawAmount = oracle.getMaxWithdrawAmount(reserve);
        amount = liquidity / oracle.curPrice(reserve);
        require((liquidity <= minter.balanceOf(to)) && (amount <= maxWithdrawAmount), "ERROR: You cannot withdraw so many tokens");
        minter.burn(to, liquidity);
        require(
            LiquifiV2LiquidityReserve(reserve).transfer(msg.sender, amount),
            "LIQUIFI: TRANSFER_FAILED"
        );
        oracle.takenFromReserve(reserve, amount);
    }

    function withdraw(address token, uint liquidity) external override returns (uint amount) {
        return _withdraw(token, liquidity, msg.sender, ConvertETH.NONE);
    }

    function withdraw(address[] memory tokens, uint[] memory liquidities) external override returns (uint[] memory amounts) {
        require(tokens.length == liquidities.length, "ERROR: wrong amount of arguments");
        amounts = new uint[](tokens.length);
        for(uint i = 0; i < tokens.length; i++) {
            amounts[i] = _withdraw(tokens[i], liquidities[i], msg.sender, ConvertETH.NONE);
        }
    }

    function withdraw(uint liquidity) external override returns (uint[] memory amounts) {
        require(liquidity <= minter.balanceOf(msg.sender), "ERROR: user doesn`t have enough LP tokens");
        uint portionDenominator = minter.totalSupply() / liquidity;
        uint reserveCount = factory.getReserveCount();
        uint amount;
        address payable reserveAddress;
        amounts = new uint[](reserveCount);
        minter.burn(msg.sender, liquidity);
        for(uint i = 0; i < reserveCount; i++) {
            reserveAddress = factory.reserves(i);
            amount = oracle.curAmount(reserveAddress) / portionDenominator;
            require(
            LiquifiV2LiquidityReserve(reserveAddress).transfer(msg.sender, amount),
                "LIQUIFI: TRANSFER_FAILED"
            );
            oracle.takenFromReserve(reserveAddress, amount);
            amounts[i] = amount;
        }
    }

    function _swap(address tokenIn, uint amountIn, address tokenOut, uint minAmountOut, address from) 
        private returns(uint amountOut) {
        address payable reserveAddress1 = factory.findReserve(tokenIn);
        require(reserveAddress1 != address(0), "Error: no tokenIn in portfolio");

        address payable reserveAddress2 = factory.findReserve(tokenOut);
        require(reserveAddress2 != address(0), "Error: no tokenOut in portfolio");
        uint newPrice1;
        uint newPrice2;
        if(LiquifiV2LiquidityReserve(reserveAddress1).isMain()) {
            (amountOut, newPrice2) = oracle.getMainReserveExchangeAmount(reserveAddress1, amountIn, reserveAddress2, feeDenominator, true);
            newPrice1 = oracle.curPrice(reserveAddress1);
        }
        else if(LiquifiV2LiquidityReserve(reserveAddress2).isMain()) {
            (amountOut, newPrice1) = oracle.getMainReserveExchangeAmount(reserveAddress1, amountIn, reserveAddress2, feeDenominator, false);
            newPrice2 = oracle.curPrice(reserveAddress2);
        }
        else {
            (amountOut, newPrice1, newPrice2) = oracle.getExchangeAmount(reserveAddress1, amountIn, reserveAddress2, feeDenominator);
        }

        require(amountOut >= minAmountOut, "ERROR: Couldn`t provide enough tokens");
        require(smartTransferFrom(tokenIn, from, reserveAddress1, amountIn, ConvertETH.NONE), "ERROR: Transfer from failed");
        require(
            LiquifiV2LiquidityReserve(reserveAddress2).transfer(from, amountOut),
            "LIQUIFI: TRANSFER_FAILED"
        );
        oracle.swapHappened(reserveAddress1, amountIn, newPrice1, reserveAddress2, amountOut, newPrice2);
    }

    function swap(address tokenIn, uint amountIn, address tokenOut, uint minAmountOut) external override returns (uint amountOut) {
        return _swap(tokenIn, amountIn, tokenOut, minAmountOut, msg.sender);
    }

    function addToken(address token, uint price) external override returns (address reserve){
        require(msg.sender == governanceRouter.governor(), "ERROR: Only governor can add new tokens to the portfolio");
        bool isMainReserve;
        (reserve, isMainReserve)= factory.addReserve(token);
        price = isMainReserve ? 1*10**18 : price;
        oracle.addNewReserve(reserve, price);
    }

    function findReserve(address token) external override view returns (address) {
        return factory.findReserve(token);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0; 

import { ERC20 } from "./ERC20.sol";

interface WETH is ERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface Oracle {
    function curPrice(address reserveAddress) external view returns (uint);
    function curAmount(address reserveAddress) external view returns (uint);
    function reserveAverageBase() external view returns (uint);
    function reserveAmount() external view returns (uint);
    function movingAverage(address reserveAddress) external view returns (
        uint ticks,
        uint averagePrice
    );

    function addNewPortfolio(address portfolio) external;
    function addNewReserve(address reserveAddress, uint price) external;

    function getExchangeAmount(address reserveAddress1, uint amount1, address reserveAddress2, uint feeDenominator) external view returns (uint amount2, uint newPrice1, uint newPrice2);
    function getMainReserveExchangeAmount(address reserveAddress1, uint amount1, address reserveAddress2, uint feeDenominator, bool isMainFirst) external view returns (uint amount2, uint newPrice);
    function getMaxWithdrawAmount(address reserveAddress) external view returns (uint maxAmount);

    function addedToReserve(address reserveAddress, uint amount) external;
    function takenFromReserve(address reserveAddress, uint amount) external;
    function swapHappened(address reserveAddress1, uint amount1, uint newPrice1, address reserveAddress2, uint amount2, uint newPrice2) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ERC20 } from "./ERC20.sol";

interface Minter is ERC20 {
    function portfolios(address) external view returns(bool); 
    function portfolioFactory() external view returns(address);
    
    function addPortfolio(address portfolio) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256 supply);

    function approve(address spender, uint256 value) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address to, uint256 value) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ReserveFactory } from "./ReserveFactory.sol";
import { WETH } from "./WETH.sol";
import { GovernanceRouter } from "./GovernanceRouter.sol";
import { Minter } from "./Minter.sol";
import { Oracle } from "./Oracle.sol";

enum ConvertETH { NONE, IN_ETH, OUT_ETH }

interface Portfolio {
    function factory() external view returns (ReserveFactory);
    function weth() external view returns (WETH);
    function isMain() external view returns (bool);
    function portfolioIndex() external view returns (uint);
    function governanceRouter() external view returns (GovernanceRouter);
    function minter() external view returns (Minter);
    function oracle() external view returns (Oracle);
    function feeDenominator() external view returns (uint);

    function setFee(uint _feeDenominator) external;

    function deposit(address token, uint amount) external returns (uint liquidityOut);

    function withdraw(address token, uint liquidity) external returns (uint amount);
    function withdraw(address[] memory tokens, uint[] memory liquidities) external returns (uint[] memory amounts);
    function withdraw(uint liquidity) external returns (uint[] memory amounts);

    function swap(address tokenIn, uint amountIn, address tokenOut, uint minAmountOut) external returns (uint amountOut);

    function addToken(address token, uint price) external returns (address reserve);

    function findReserve(address token) external view returns (address reserveAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ReserveFactory } from "./interfaces/ReserveFactory.sol";
import { LiquifiV2LiquidityReserve } from "./LiquifiV2LiquidityReserve.sol";
import { GovernanceRouter } from "./interfaces/GovernanceRouter.sol";

contract LiquifiV2ReserveFactory is ReserveFactory {
    address public override immutable weth;

    mapping(/*tokenAddress*/address => /*reserveAddress*/address payable) private reserveMap;
    address payable[] public override reserves;
    GovernanceRouter public override governanceRouter;
    address private immutable portfolio;

    constructor (address _governanceRouter) {
        governanceRouter = GovernanceRouter(_governanceRouter);
        weth = address(GovernanceRouter(_governanceRouter).weth());
        portfolio = msg.sender;
    }

    /**
     * @dev Adds new reserve and returns its address. If reserve already exists, the address of the existing
     * reserve would be returned.
     *
     * Requrements:
     *
     * -Only portfolio can call this function.
     */
    function addReserve (address token) external override returns (address payable reserve, bool isMain) {
        require(msg.sender == portfolio, "ERROR: Only portfolio can add reserves");
        bool isWETH = token == weth;
        reserve = reserveMap[token];
        if (reserve == address(0)) {
            isMain = reserves.length == 0;
            reserve = payable(new LiquifiV2LiquidityReserve{ /* make reserve address deterministic */ salt: bytes32(uint(1))}(
                token, isWETH, isMain, reserves.length, portfolio
            ));
            reserves.push(reserve);
            reserveMap[token] = reserve;
            emit ReserveCreatedEvent(token, isWETH, reserve);
        }
    }
    
    function getMainReserve() external override view returns (address mainReserveAddress) {
        require(reserves.length > 0, "ERROR: no reserves have been added yet");
        return reserves[0];
    }

    /** 
    * @dev Returns the address of the reserve in current portfolio with specified {token}. If the portfolio
    * doesn`t contain a reserve for {token}, {address(0)} is returned.
    */
    function findReserve(address token) external override view returns (address payable reserve) {
        return reserveMap[token];
    }

    function getReserveCount() external override view returns (uint) {
        return reserves.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { LiquidityReserve } from "./interfaces/LiquidityReserve.sol";
import { ERC20 } from "./interfaces/ERC20.sol"; 

contract LiquifiV2LiquidityReserve is LiquidityReserve {

   address public override immutable token;
   bool public override immutable isWETH;//indicates whether the reserve's token is WETH or not
   bool public override immutable isMain;//indicates whether the reserve's token is the main token of the portfolio or not
   uint private immutable reserveIndex;
   address private portfolio;

   receive() external payable {
      assert(msg.sender == address(token) && isWETH);
   }

   constructor(address _token, bool _isWETH, bool _isMain, uint _reserveIndex, address _portfolio) {
      token = _token;
      isWETH = _isWETH;
      isMain = _isMain;
      reserveIndex = _reserveIndex;
      portfolio = _portfolio;
   }

   function transfer(address to, uint value) public override returns(bool) {
      require(msg.sender == portfolio, "ERROR: Only portfolio can transfer money from this reserve");
      (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
            ERC20.transfer.selector, to, value));
      success = success && (data.length == 0 || abi.decode(data, (bool)));

      require(success, "ERROR: TOKEN_TRANSFER_FAILED");
      return true;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { GovernanceRouter } from "./GovernanceRouter.sol";

interface ReserveFactory {
    event ReserveCreatedEvent(address token, bool isWETH, address indexed reserve);

    function weth() external view returns(address);
    function governanceRouter() external view returns(GovernanceRouter);

    function addReserve(address token) external returns (address payable reserve, bool isMain);
    function getMainReserve() external view returns (address mainReserveAddress);
    function findReserve(address token) external view returns (address payable reserve);
    function reserves(uint reserveIndex) external view returns (address payable);
    function getReserveCount() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface LiquidityReserve {
    function isWETH() external view returns (bool);
    function isMain() external view returns (bool);
    function token() external view returns (address);

    function transfer(address to, uint value) external returns (bool);
}

