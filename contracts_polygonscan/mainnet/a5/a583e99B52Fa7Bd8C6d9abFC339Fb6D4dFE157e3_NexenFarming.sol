// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ILendingPool.sol";
import "./WadRayMath.sol";
import "./DataTypes.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";


contract NexenFarming is Ownable {
    using WadRayMath for uint256;

    ILendingPool lendingPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);
    address daiToken = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address usdtToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address nexenToken = 0xb32e335B798A1Ac07007390683A128f134aa6e25;

    uint256 public daiFees;
    uint256 public usdtFees;

    mapping(address => Supply) public DAISupplies;
    mapping(address => Supply) public USDTSupplies;

    struct Supply {
        uint256 initialSupply;
        uint256 aaveInitialBalance;
    }

    constructor() {
        _approve(daiToken, 1e24);
        _approve(usdtToken, 1e12);
    }

    function depositDAI(uint256 _amount) public {
        _deposit(_amount, daiToken);

        DAISupplies[msg.sender].initialSupply += _amount;

        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(daiToken);
        uint256 index = reserve.liquidityIndex;

        DAISupplies[msg.sender].aaveInitialBalance += _amount.rayDiv(index);
    }

    function depositUSDT(uint256 _amount) public {
        _deposit(_amount, usdtToken);
        
        USDTSupplies[msg.sender].initialSupply += _amount;

        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(usdtToken);
        uint256 index = reserve.liquidityIndex;

        USDTSupplies[msg.sender].aaveInitialBalance += _amount.rayDiv(index);
    }

    function redeemDAI() public {
        uint256 deposited = DAISupplies[msg.sender].initialSupply;
        require(deposited > 0, 'Nothing to redeem');

        uint256 totalToRecover = getUserDAIBalance(msg.sender);

        DAISupplies[msg.sender].initialSupply = 0;
        DAISupplies[msg.sender].aaveInitialBalance = 0;

        uint256 recovered = lendingPool.withdraw(daiToken, totalToRecover, address(this));
        uint256 interests = recovered - deposited;
        uint256 halfInterests = 0;
        uint256 nexenTokensToReturn = 0;

        if (interests > 0) {
            halfInterests = interests / 2;
            uint256 keep = interests - halfInterests;
            daiFees += keep;
            
            //14 DAI = 100 NXN
            nexenTokensToReturn = interests * 100 / 14;
        }

        require(IERC20(daiToken).transfer(msg.sender, halfInterests + deposited), 'Could not transfer tokens');
        
        if (nexenTokensToReturn > 0) {
            require(IERC20(nexenToken).transfer(msg.sender, nexenTokensToReturn), 'Could not transfer tokens');
        }
    }

    function redeemUSDT() public {
        uint256 deposited = USDTSupplies[msg.sender].initialSupply;
        require(deposited > 0, 'Nothing to redeem');

        uint256 totalToRecover = getUserUSDTBalance(msg.sender);

        USDTSupplies[msg.sender].initialSupply = 0;
        USDTSupplies[msg.sender].aaveInitialBalance = 0;

        uint256 recovered = lendingPool.withdraw(usdtToken, totalToRecover, address(this));
        uint256 interests = recovered - deposited;
        uint256 halfInterests = 0;
        uint256 nexenTokensToReturn = 0;

        if (interests > 0) {
            halfInterests = interests / 2;
            uint256 keep = interests - halfInterests;
            usdtFees += keep;
            
            //14 USDT = 100 NXN
            nexenTokensToReturn = interests * 100 / 14;
        }

        require(IERC20(usdtToken).transfer(msg.sender, halfInterests + deposited), 'Could not transfer tokens');
        
        if (nexenTokensToReturn > 0) {
            require(IERC20(nexenToken).transfer(msg.sender, nexenTokensToReturn), 'Could not transfer tokens');
        }
    }

    function _deposit(uint256 _amount, address _token) internal {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), 'Could not transfer tokens');
        lendingPool.deposit(_token, _amount, address(this), 0);
    }

    function getUserDAIBalance(address _user) public view returns(uint256) {
        uint256 initial = DAISupplies[_user].aaveInitialBalance;
        return getAAVEBalance(initial, daiToken);
    }

    function getUserUSDTBalance(address _user) public view returns(uint256) {
        uint256 initial = USDTSupplies[_user].aaveInitialBalance;
        return getAAVEBalance(initial, usdtToken);
    }

    function getAAVEBalance(uint256 _initial, address _asset) public view returns (uint256) {
        return _initial.rayMul(getPoolReserve(_asset));
    }

    function getPoolReserve(address _asset) public view returns (uint256) {
        return lendingPool.getReserveNormalizedIncome(_asset);
    }

    function _withdrawFees() public onlyOwner {
        uint256 totalDaiFees = daiFees;
        if (totalDaiFees > 0) {
            daiFees = 0;
            IERC20(daiToken).transferFrom(address(this), msg.sender, totalDaiFees);
        }

        uint256 totalUsdtFees = usdtFees;
        if (totalUsdtFees > 0) {
            usdtFees = 0;
            SafeERC20.safeTransfer(ERC20(usdtToken), msg.sender, totalUsdtFees);
        }
    }

    function _approve(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).approve(address(lendingPool), _amount);
    }
    
    function _recoverNexenTokens(uint256 _amount) public onlyOwner {
        require(IERC20(nexenToken).transfer(msg.sender, _amount), 'Could not transfer tokens');
    }

    function _recoverTokens(uint256 _amount, address _asset) public onlyOwner {
        require(IERC20(_asset).transfer(msg.sender, _amount), 'Could not transfer tokens');
    }
}