// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/factory/IHarvestETHStrategyFactory.sol";
import "../interfaces/factory/IHarvestSCStrategyFactory.sol"; 
import "../interfaces/factory/ISushiSLPStrategyFactory.sol";
import "../interfaces/factory/ISushiStableCoinStrategyFactory.sol";
import "../interfaces/router/IStrategyRouter.sol";
contract StrategyRouter is IStrategyRouter {

    address public harvestEthFactory;
    address public harvestSCFactory; 
    address public sushiSLPFactory;
    address public sushiStableCoinFactory;
 
    constructor(
            address _harvestEthFactory,
            address _harvestSCFactory, 
            address _sushiSLPFactory, 
            address _sushiStableCoinFactory)  { 
        require(_harvestEthFactory != address(0), "ADDRESS_0x0_harvestEthFactory");
        require(_harvestSCFactory != address(0), "ADDRESS_0x0_harvestSCFactory"); 
        require(_sushiSLPFactory != address(0), "ADDRESS_0x0_sushiSLPFactory");
        require(_sushiStableCoinFactory != address(0), "ADDRESS_0x0_sushiStableCoinFactory");
                       
        harvestEthFactory = _harvestEthFactory;
        harvestSCFactory = _harvestSCFactory; 
        sushiSLPFactory = _sushiSLPFactory;
        sushiStableCoinFactory = _sushiStableCoinFactory;
    }

    function createHarvestEthStrategy( address _harvestfToken, address _token, address payable _treasuryAddress,address payable _feeAddress) external override {
        require(_harvestfToken != address(0), "ADDRESS_0x0__harvestfToken");
        require(_token != address(0), "ADDRESS_0x0__token");
        require(_treasuryAddress != address(0), "ADDRESS_0x0__treasuryAddress");
        require(_feeAddress != address(0), "ADDRESS_0x0__feeAddress");

        IHarvestETHStrategyFactory(harvestEthFactory).createStrategy(_harvestfToken, _token, _treasuryAddress, _feeAddress, msg.sender);
    }

    function createHarvestSCStrategy(address _harvestfToken,address _token,  address payable _treasuryAddress, address payable _feeAddress) external override {
        require(_harvestfToken != address(0), "ADDRESS_0x0_harvestfToken");
        require(_token != address(0), "ADDRESS_0x0_token");
        require(_treasuryAddress != address(0), "ADDRESS_0x0_treasuryAddress");
        require(_feeAddress != address(0), "ADDRESS_0x0_feeAddress");

        IHarvestSCStrategyFactory(harvestSCFactory).createStrategy(_harvestfToken, _token, _treasuryAddress, _feeAddress,msg.sender);
    }
 
    function createSushiSLPStrategy(address _token,address payable _treasuryAddress, address payable _feeAddress,  uint256 _poolId, address _slp) external override {
        require(_token != address(0), "ADDRESS_0x0_token");
        require(_treasuryAddress != address(0), "ADDRESS_0x0_treasuryAddress");
        require(_feeAddress != address(0), "ADDRESS_0x0_feeAddress");

        ISushiSLPStrategyFactory(sushiSLPFactory).createStrategy(_token, _treasuryAddress, _feeAddress, _poolId,_slp, msg.sender);
    }

    function createSushiStableCoinStrategy(address payable _treasuryAddress, address payable _feeAddress) external override {
        require(_treasuryAddress != address(0), "ADDRESS_0x0_treasuryAddress");
        require(_feeAddress != address(0), "ADDRESS_0x0_feeAddress");

        ISushiStableCoinStrategyFactory(sushiStableCoinFactory).createStrategy( _treasuryAddress, _feeAddress, msg.sender);
    }
 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IHarvestETHStrategyFactory {
     function createStrategy(
        address _harvestfToken,
        address _token,
        address payable _treasuryAddress,
        address payable _feeAddress,
        address _ownerAccount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IHarvestSCStrategyFactory {
    function createStrategy(     
        address _harvestfToken,
        address _token,
        address payable _treasuryAddress,
        address payable _feeAddress,
        address _ownerAccount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ISushiSLPStrategyFactory {
     function createStrategy(  
        address _token,
        address payable _treasuryAddress,
        address payable _feeAddress,
        uint256 _poolId,
        address _slp,
        address _ownerAccount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ISushiStableCoinStrategyFactory {
     function createStrategy(  
        address payable _treasuryAddress,
        address payable _feeAddress,
        address _ownerAccount) external; 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
interface IStrategyRouter {  
    function createHarvestEthStrategy( address _harvestfToken, address _token, address payable _treasuryAddress,address payable _feeAddress) external;

    function createHarvestSCStrategy(address _harvestfToken,address _token,  address payable _treasuryAddress, address payable _feeAddress) external ;

    function createSushiSLPStrategy(address _token,address payable _treasuryAddress, address payable _feeAddress,  uint256 _poolId, address _slp) external;

    function createSushiStableCoinStrategy(address payable _treasuryAddress, address payable _feeAddress) external;
 
}

