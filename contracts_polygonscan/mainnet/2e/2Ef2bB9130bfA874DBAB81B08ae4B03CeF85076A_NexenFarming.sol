// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {ILendingPool} from './ILendingPool.sol';
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";


contract NexenFarming is Ownable {
    ILendingPool lendingPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);
    address daiToken = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address usdtToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address nexenToken = 0xb32e335B798A1Ac07007390683A128f134aa6e25;
    address daiAToken = 0x27F8D03b3a2196956ED754baDc28D73be8830A6e;
    address usdtAToken = 0x60D55F02A771d515e077c9C2403a1ef324885CeC;
    
    uint256 public daiFees;
    uint256 public usdtFees;
    uint256 public ethFees;

    mapping(address => uint256) public DAISupplies;
    mapping(address => uint256) public USDTSupplies;

    function _deposit(uint256 _amount, address _token) internal {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), 'Could not transfer tokens');
        IERC20(_token).approve(address(lendingPool), _amount);
        lendingPool.deposit(_token, _amount, msg.sender, 0);
    }

    function depositDAI(uint256 _amount) public {
        _deposit(_amount, daiToken);
        DAISupplies[msg.sender] += _amount;
    }

    function depositUSDT(uint256 _amount) public {
        _deposit(_amount, usdtToken);
        USDTSupplies[msg.sender] += _amount;
    }

    function redeemDAI() internal {
        uint256 original = DAISupplies[msg.sender];
        require(original > 0, 'Nothing to redeem');
        DAISupplies[msg.sender] = 0;

        uint256 aTokens = ERC20(daiAToken).balanceOf(msg.sender);
        require(aTokens > 0, 'Nothing to redeem');

        uint256 totalRecovered = lendingPool.withdraw(daiToken, aTokens, address(this));
        uint256 interests = totalRecovered - original;
        uint256 halfInterests = interests / 2;
        uint256 keep = interests - halfInterests;
        daiFees += keep;
        
        //14 DAI = 100 NXN
        uint256 nexenTokensToReturn = interests * 100 / 14;

        require(IERC20(daiToken).transferFrom(address(this), msg.sender, halfInterests + original), 'Could not transfer tokens');
        require(IERC20(nexenToken).transferFrom(address(this), msg.sender, nexenTokensToReturn), 'Could not transfer tokens');
    }

    function redeemUSDT() internal {
        uint256 original = USDTSupplies[msg.sender];
        require(original > 0, 'Nothing to redeem');
        USDTSupplies[msg.sender] = 0;

        uint256 aTokens = ERC20(usdtAToken).balanceOf(msg.sender);
        require(aTokens > 0, 'Nothing to redeem');

        uint256 totalRecovered = lendingPool.withdraw(usdtToken, aTokens, address(this));
        uint256 interests = totalRecovered - original;
        uint256 halfInterests = interests / 2;
        uint256 keep = interests - halfInterests;
        usdtFees += keep;
        
        //14 DAI = 100 NXN
        uint256 nexenTokensToReturn = interests * 100 / 14;

        require(IERC20(usdtToken).transferFrom(address(this), msg.sender, halfInterests + original), 'Could not transfer tokens');
        require(IERC20(nexenToken).transferFrom(address(this), msg.sender, nexenTokensToReturn), 'Could not transfer tokens');
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
    
    function _recoverNexenTokens(uint256 _amount) public onlyOwner {
        require(IERC20(nexenToken).transfer(msg.sender, _amount), 'Could not transfer tokens');
    }
}