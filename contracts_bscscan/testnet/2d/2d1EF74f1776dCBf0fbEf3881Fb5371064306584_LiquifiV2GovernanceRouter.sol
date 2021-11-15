// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { GovernanceRouter } from "./interfaces/GovernanceRouter.sol";
import { WETH } from "./interfaces/WETH.sol";
import { PortfolioFactory } from "./interfaces/PortfolioFactory.sol";
import { Oracle } from "./interfaces/Oracle.sol";
import { Minter } from "./interfaces/Minter.sol";

contract LiquifiV2GovernanceRouter is GovernanceRouter {

    address public immutable override creator;
    WETH public immutable override weth;

    PortfolioFactory public override portfolioFactory;
    Oracle public override oracle;
    Minter public override minter;

    address public override governor;

    constructor(address _weth) {
        creator = tx.origin;
        weth = WETH(_weth);
    }

    function setGovernor(address _governor) external override {
        require(msg.sender == governor || (governor == address(0) && tx.origin == creator), "LIQUIFI_GVR: INVALID GOVERNANCE SENDER");
        governor = _governor;
        emit GovernorChanged(_governor);
    }

    function setPortfolioFactory(PortfolioFactory _portfolioFactory) external override {
        require(msg.sender == governor || (address(portfolioFactory) == address(0) && tx.origin == creator), "LIQUIFI_GVR: INVALID INIT SENDER");
        portfolioFactory = _portfolioFactory;
        emit PortfolioFactoryChanged(address(_portfolioFactory));
    }

    function setOracle(Oracle _oracle) external override {
        require(msg.sender == governor || (address(oracle) == address(0) && tx.origin == creator), "LIQUIFI_GVR: INVALID INIT SENDER");
        oracle = _oracle;
        emit OracleChanged(address(_oracle));
    }

    function setMinter(Minter _minter) external override {
        require(msg.sender == governor || (address(minter) == address(0) && tx.origin == creator), "LIQUIFI_GVR: INVALID INIT SENDER");
        minter = _minter;
        emit MinterChanged(address(_minter));
    }
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

import { ERC20 } from "./ERC20.sol";

interface WETH is ERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
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

    function addPortfolio() external returns (address portfolio);
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

