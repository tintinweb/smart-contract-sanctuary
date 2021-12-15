// SPDX-License-Identifier: AGPL-3.0-or-later

/// MultiplyProxyActions.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import {IERC20} from "../interfaces/IERC20.sol";
import "../utils/SafeMath.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/mcd/IJoin.sol";
import "../interfaces/mcd/IManager.sol";
import "../interfaces/mcd/IVat.sol";
import "../interfaces/mcd/IJug.sol";
import "../interfaces/mcd/IDaiJoin.sol";
import "../interfaces/exchange/IExchange.sol";
import "./ExchangeData.sol";

import "./../flashMint/interface/IERC3156FlashBorrower.sol";
import "./../flashMint/interface/IERC3156FlashLender.sol";

pragma solidity >=0.7.6;
pragma abicoder v2;

struct CdpData {
  address gemJoin;
  address payable fundsReceiver;
  uint256 cdpId;
  bytes32 ilk;
  uint256 requiredDebt;
  uint256 borrowCollateral;
  uint256 withdrawCollateral;
  uint256 withdrawDai;
  uint256 depositDai;
  uint256 depositCollateral;
  bool skipFL;
  string methodName;
}

struct AddressRegistry {
  address jug;
  address manager;
  address multiplyProxyActions;
  address lender;
  address exchange;
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract MultiplyProxyActions is IERC3156FlashBorrower {
  using SafeMath for uint256;

  uint256 constant RAY = 10**27;

  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public constant DAIJOIN = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;

  modifier logMethodName(
    string memory name,
    CdpData memory data,
    address destination
  ) {
    if (bytes(data.methodName).length == 0) {
      data.methodName = name;
    }
    _;
    data.methodName = "";
  }

  function takeAFlashLoan(
    AddressRegistry memory addressRegistry,
    CdpData memory cdpData,
    bytes memory paramsData
  ) internal {
    IManager(addressRegistry.manager).cdpAllow(
      cdpData.cdpId,
      addressRegistry.multiplyProxyActions,
      1
    );

    IERC3156FlashLender(addressRegistry.lender).flashLoan(
      IERC3156FlashBorrower(addressRegistry.multiplyProxyActions),
      DAI,
      cdpData.requiredDebt,
      paramsData
    );

    IManager(addressRegistry.manager).cdpAllow(
      cdpData.cdpId,
      addressRegistry.multiplyProxyActions,
      0
    );
  }

  function toInt256(uint256 x) internal pure returns (int256 y) {
    y = int256(x);
    require(y >= 0, "int256-overflow");
  }

  function convertTo18(address gemJoin, uint256 amt) internal returns (uint256 wad) {
    // For those collaterals that have less than 18 decimals precision we need to do the conversion before passing to frob function
    // Adapters will automatically handle the difference of precision
    wad = amt.mul(10**(18 - IJoin(gemJoin).dec()));
  }

  function _getDrawDart(
    address vat,
    address jug,
    address urn,
    bytes32 ilk,
    uint256 wad
  ) internal returns (int256 dart) {
    // Updates stability fee rate
    uint256 rate = IJug(jug).drip(ilk);

    // Gets DAI balance of the urn in the vat
    uint256 dai = IVat(vat).dai(urn);

    // If there was already enough DAI in the vat balance, just exits it without adding more debt
    if (dai < wad.mul(RAY)) {
      // Calculates the needed dart so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
      dart = toInt256(wad.mul(RAY).sub(dai) / rate);
      // This is neeeded due lack of precision. It might need to sum an extra dart wei (for the given DAI wad amount)
      dart = uint256(dart).mul(rate) < wad.mul(RAY) ? dart + 1 : dart;
    }
  }

  function openMultiplyVault(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    payable
    logMethodName("openMultiplyVault", cdpData, addressRegistry.multiplyProxyActions)
  {
    cdpData.ilk = IJoin(cdpData.gemJoin).ilk();
    cdpData.cdpId = IManager(addressRegistry.manager).open(cdpData.ilk, address(this));
    increaseMultipleDepositCollateral(exchangeData, cdpData, addressRegistry);
  }

  function increaseMultipleDepositCollateral(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    payable
    logMethodName(
      "increaseMultipleDepositCollateral",
      cdpData,
      addressRegistry.multiplyProxyActions
    )
  {
    IGem gem = IJoin(cdpData.gemJoin).gem();

    if (address(gem) == WETH) {
      gem.deposit{value: msg.value}();
      if (cdpData.skipFL == false) {
        gem.transfer(addressRegistry.multiplyProxyActions, msg.value);
      }
    } else {
      if (cdpData.skipFL == false) {
        gem.transferFrom(
          msg.sender,
          addressRegistry.multiplyProxyActions,
          cdpData.depositCollateral
        );
      } else {
        gem.transferFrom(msg.sender, address(this), cdpData.depositCollateral);
      }
    }
    increaseMultipleInternal(exchangeData, cdpData, addressRegistry);
  }

  function toRad(uint256 wad) internal pure returns (uint256 rad) {
    rad = wad.mul(10**27);
  }

  function drawDaiDebt(
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry,
    uint256 amount
  ) internal {
    address urn = IManager(addressRegistry.manager).urns(cdpData.cdpId);
    address vat = IManager(addressRegistry.manager).vat();
    IManager(addressRegistry.manager).frob(
      cdpData.cdpId,
      0,
      _getDrawDart(vat, addressRegistry.jug, urn, cdpData.ilk, amount)
    );
    IManager(addressRegistry.manager).move(cdpData.cdpId, address(this), toRad(amount));
    if (IVat(vat).can(address(this), address(DAIJOIN)) == 0) {
      IVat(vat).hope(DAIJOIN);
    }

    IJoin(DAIJOIN).exit(address(this), amount);
  }

  function increaseMultipleDepositDai(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    logMethodName("increaseMultipleDepositDai", cdpData, addressRegistry.multiplyProxyActions)
  {
    if (cdpData.skipFL) {
      IERC20(DAI).transferFrom(msg.sender, address(this), cdpData.depositDai);
    } else {
      IERC20(DAI).transferFrom(
        msg.sender,
        addressRegistry.multiplyProxyActions,
        cdpData.depositDai
      );
    }
    increaseMultipleInternal(exchangeData, cdpData, addressRegistry);
  }

  function increaseMultiple(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  ) public logMethodName("increaseMultiple", cdpData, addressRegistry.multiplyProxyActions) {
    increaseMultipleInternal(exchangeData, cdpData, addressRegistry);
  }

  function increaseMultipleInternal(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  ) internal {
    cdpData.ilk = IJoin(cdpData.gemJoin).ilk();

    bytes memory paramsData = abi.encode(1, exchangeData, cdpData, addressRegistry);

    if (cdpData.skipFL) {
      //we want to draw our own DAI and use them in the exchange to buy collateral
      IGem gem = IJoin(cdpData.gemJoin).gem();
      uint256 collBalance = IERC20(address(gem)).balanceOf(address(this));
      if (collBalance > 0) {
        //if someone provided some collateral during increase
        //add it to vault and draw DAI
        joinDrawDebt(cdpData, cdpData.requiredDebt, addressRegistry.manager, addressRegistry.jug);
      } else {
        //just draw DAI
        drawDaiDebt(cdpData, addressRegistry, cdpData.requiredDebt);
      }
      _increaseMP(exchangeData, cdpData, addressRegistry, 0);
    } else {
      takeAFlashLoan(addressRegistry, cdpData, paramsData);
    }
  }

  function decreaseMultiple(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  ) public logMethodName("decreaseMultiple", cdpData, addressRegistry.multiplyProxyActions) {
    decreaseMultipleInternal(exchangeData, cdpData, addressRegistry);
  }

  function decreaseMultipleInternal(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  ) internal {
    cdpData.ilk = IJoin(cdpData.gemJoin).ilk();

    bytes memory paramsData = abi.encode(0, exchangeData, cdpData, addressRegistry);

    if (cdpData.skipFL) {
      _decreaseMP(exchangeData, cdpData, addressRegistry, 0);
    } else {
      takeAFlashLoan(addressRegistry, cdpData, paramsData);
    }
  }

  function decreaseMultipleWithdrawCollateral(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    logMethodName(
      "decreaseMultipleWithdrawCollateral",
      cdpData,
      addressRegistry.multiplyProxyActions
    )
  {
    decreaseMultipleInternal(exchangeData, cdpData, addressRegistry);
  }

  function decreaseMultipleWithdrawDai(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    logMethodName("decreaseMultipleWithdrawDai", cdpData, addressRegistry.multiplyProxyActions)
  {
    decreaseMultipleInternal(exchangeData, cdpData, addressRegistry);
  }

  function closeVaultExitGeneric(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry,
    uint8 mode
  ) private {
    cdpData.ilk = IJoin(cdpData.gemJoin).ilk();

    address urn = IManager(addressRegistry.manager).urns(cdpData.cdpId);
    address vat = IManager(addressRegistry.manager).vat();

    uint256 wadD = _getWipeAllWad(vat, urn, urn, cdpData.ilk);
    cdpData.requiredDebt = wadD;

    bytes memory paramsData = abi.encode(mode, exchangeData, cdpData, addressRegistry);

    if (cdpData.skipFL == false) {
      takeAFlashLoan(addressRegistry, cdpData, paramsData);
    } else {
      if (mode == 2) {
        _closeWithdrawCollateralSkipFL(
          exchangeData,
          cdpData,
          addressRegistry,
          cdpData.borrowCollateral
        );
      } else {
        require(false, "this code should be unreachable");
      }
    }
  }

  function closeVaultExitCollateral(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    logMethodName("closeVaultExitCollateral", cdpData, addressRegistry.multiplyProxyActions)
  {
    closeVaultExitGeneric(exchangeData, cdpData, addressRegistry, 2);
  }

  function closeVaultExitDai(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  ) public logMethodName("closeVaultExitDai", cdpData, addressRegistry.multiplyProxyActions) {
    require(cdpData.skipFL == false, "cannot close to DAI if FL not used");
    closeVaultExitGeneric(exchangeData, cdpData, addressRegistry, 3);
  }

  function joinDrawDebt(
    CdpData memory cdpData,
    uint256 borrowedDai,
    address manager,
    address jug
  ) private {
    IGem gem = IJoin(cdpData.gemJoin).gem();

    uint256 balance = IERC20(address(gem)).balanceOf(address(this));
    gem.approve(address(cdpData.gemJoin), balance);

    address urn = IManager(manager).urns(cdpData.cdpId);
    address vat = IManager(manager).vat();

    IJoin(cdpData.gemJoin).join(urn, balance);

    IManager(manager).frob(
      cdpData.cdpId,
      toInt256(convertTo18(cdpData.gemJoin, balance)),
      _getDrawDart(vat, jug, urn, cdpData.ilk, borrowedDai)
    );
    IManager(manager).move(cdpData.cdpId, address(this), borrowedDai.mul(RAY));

    IVat(vat).hope(DAIJOIN);

    IJoin(DAIJOIN).exit(address(this), borrowedDai);
  }

  function getInk(address manager, CdpData memory cdpData) internal view returns (uint256) {
    address urn = IManager(manager).urns(cdpData.cdpId);
    address vat = IManager(manager).vat();

    (uint256 ink, ) = IVat(vat).urns(cdpData.ilk, urn);
    return ink;
  }

  function _getWipeDart(
    address vat,
    uint256 dai,
    address urn,
    bytes32 ilk
  ) internal view returns (int256 dart) {
    // Gets actual rate from the vat
    (, uint256 rate, , , ) = IVat(vat).ilks(ilk);
    // Gets actual art value of the urn
    (, uint256 art) = IVat(vat).urns(ilk, urn);

    // Uses the whole dai balance in the vat to reduce the debt
    dart = toInt256(dai / rate);
    // Checks the calculated dart is not higher than urn.art (total debt), otherwise uses its value
    dart = uint256(dart) <= art ? -dart : -toInt256(art);
  }

  function _getWipeAllWad(
    address vat,
    address usr,
    address urn,
    bytes32 ilk
  ) internal view returns (uint256 wad) {
    // Gets actual rate from the vat
    (, uint256 rate, , , ) = IVat(vat).ilks(ilk);
    // Gets actual art value of the urn
    (, uint256 art) = IVat(vat).urns(ilk, urn);
    // Gets actual dai amount in the urn
    uint256 dai = IVat(vat).dai(usr);

    uint256 rad = art.mul(rate).sub(dai);
    wad = rad / RAY;

    // If the rad precision has some dust, it will need to request for 1 extra wad wei
    wad = wad.mul(RAY) < rad ? wad + 1 : wad;
  }

  function wipeAndFreeGem(
    address manager,
    address gemJoin,
    uint256 cdp,
    uint256 borrowedDai,
    uint256 collateralDraw
  ) internal {
    address vat = IManager(manager).vat();
    address urn = IManager(manager).urns(cdp);
    bytes32 ilk = IManager(manager).ilks(cdp);

    IERC20(DAI).approve(DAIJOIN, borrowedDai);
    IDaiJoin(DAIJOIN).join(urn, borrowedDai);

    uint256 wadC = convertTo18(gemJoin, collateralDraw);

    IManager(manager).frob(cdp, -toInt256(wadC), _getWipeDart(vat, IVat(vat).dai(urn), urn, ilk));

    IManager(manager).flux(cdp, address(this), wadC);
    IJoin(gemJoin).exit(address(this), collateralDraw);
  }

  function _withdrawGem(
    address gemJoin,
    address payable destination,
    uint256 amount
  ) private {
    IGem gem = IJoin(gemJoin).gem();

    if (address(gem) == WETH) {
      gem.withdraw(amount);
      destination.transfer(amount);
    } else {
      IERC20(address(gem)).transfer(destination, amount);
    }
  }

  function _increaseMP(
    ExchangeData memory exchangeData,
    CdpData memory cdpData,
    AddressRegistry memory addressRegistry,
    uint256 premium
  ) private {
    IExchange exchange = IExchange(addressRegistry.exchange);
    uint256 borrowedDai = cdpData.requiredDebt.add(premium);
    if (cdpData.skipFL) {
      borrowedDai = 0; //this DAI are not borrowed and shal not stay after this method execution
    }
    require(
      IERC20(DAI).approve(address(exchange), exchangeData.fromTokenAmount.add(cdpData.depositDai)),
      "MPA / Could not approve Exchange for DAI"
    );
    exchange.swapDaiForToken(
      exchangeData.toTokenAddress,
      exchangeData.fromTokenAmount.add(cdpData.depositDai),
      exchangeData.minToTokenAmount,
      exchangeData.exchangeAddress,
      exchangeData._exchangeCalldata
    );
    //here we add collateral we got from exchange, if skipFL then borrowedDai = 0
    joinDrawDebt(cdpData, borrowedDai, addressRegistry.manager, addressRegistry.jug);
    //if some DAI are left after exchange return them to the user
    uint256 daiLeft = IERC20(DAI).balanceOf(address(this)).sub(borrowedDai);
    emit MultipleActionCalled(
      cdpData.methodName,
      cdpData.cdpId,
      exchangeData.minToTokenAmount,
      exchangeData.toTokenAmount,
      0,
      daiLeft
    );

    if (daiLeft > 0) {
      IERC20(DAI).transfer(cdpData.fundsReceiver, daiLeft);
    }
  }

  function _decreaseMP(
    ExchangeData memory exchangeData,
    CdpData memory cdpData,
    AddressRegistry memory addressRegistry,
    uint256 premium
  ) private {
    IExchange exchange = IExchange(addressRegistry.exchange);

    uint256 debtToBeWiped = cdpData.skipFL ? 0 : cdpData.requiredDebt.sub(cdpData.withdrawDai);

    wipeAndFreeGem(
      addressRegistry.manager,
      cdpData.gemJoin,
      cdpData.cdpId,
      debtToBeWiped,
      cdpData.borrowCollateral.add(cdpData.withdrawCollateral)
    );

    require(
      IERC20(exchangeData.fromTokenAddress).approve(
        address(exchange),
        exchangeData.fromTokenAmount
      ),
      "MPA / Could not approve Exchange for Token"
    );

    exchange.swapTokenForDai(
      exchangeData.fromTokenAddress,
      exchangeData.fromTokenAmount,
      cdpData.requiredDebt.add(premium),
      exchangeData.exchangeAddress,
      exchangeData._exchangeCalldata
    );

    uint256 collateralLeft = IERC20(exchangeData.fromTokenAddress).balanceOf(address(this));

    uint256 daiLeft = 0;
    if (cdpData.skipFL) {
      wipeAndFreeGem(
        addressRegistry.manager,
        cdpData.gemJoin,
        cdpData.cdpId,
        IERC20(DAI).balanceOf(address(this)).sub(cdpData.withdrawDai),
        0
      );
      daiLeft = cdpData.withdrawDai;
    } else {
      daiLeft = IERC20(DAI).balanceOf(address(this)).sub(cdpData.requiredDebt.add(premium));
    }
    emit MultipleActionCalled(
      cdpData.methodName,
      cdpData.cdpId,
      exchangeData.minToTokenAmount,
      exchangeData.toTokenAmount,
      collateralLeft,
      daiLeft
    );

    if (daiLeft > 0) {
      IERC20(DAI).transfer(cdpData.fundsReceiver, daiLeft);
    }
    if (collateralLeft > 0) {
      _withdrawGem(cdpData.gemJoin, cdpData.fundsReceiver, collateralLeft);
    }
  }

  function _closeWithdrawCollateralSkipFL(
    ExchangeData memory exchangeData,
    CdpData memory cdpData,
    AddressRegistry memory addressRegistry,
    uint256 ink
  ) private {
    IExchange exchange = IExchange(addressRegistry.exchange);
    address gemAddress = address(IJoin(cdpData.gemJoin).gem());

    wipeAndFreeGem(
      addressRegistry.manager,
      cdpData.gemJoin,
      cdpData.cdpId,
      0,
      exchangeData.fromTokenAmount
    );
    require(
      IERC20(exchangeData.fromTokenAddress).approve(address(exchange), ink),
      "MPA / Could not approve Exchange for Token"
    );
    exchange.swapTokenForDai(
      exchangeData.fromTokenAddress,
      exchangeData.fromTokenAmount,
      exchangeData.minToTokenAmount,
      exchangeData.exchangeAddress,
      exchangeData._exchangeCalldata
    );

    uint256 daiLeft = IERC20(DAI).balanceOf(address(this));

    require(cdpData.requiredDebt <= daiLeft, "cannot repay all debt");

    wipeAndFreeGem(
      addressRegistry.manager,
      cdpData.gemJoin,
      cdpData.cdpId,
      cdpData.requiredDebt,
      cdpData.withdrawCollateral
    );
    daiLeft = IERC20(DAI).balanceOf(address(this));

    uint256 collateralLeft = IERC20(gemAddress).balanceOf(address(this));

    if (daiLeft > 0) {
      IERC20(DAI).transfer(cdpData.fundsReceiver, daiLeft);
    }
    if (collateralLeft > 0) {
      _withdrawGem(cdpData.gemJoin, cdpData.fundsReceiver, collateralLeft);
    }
    emit MultipleActionCalled(
      cdpData.methodName,
      cdpData.cdpId,
      exchangeData.minToTokenAmount,
      exchangeData.toTokenAmount,
      collateralLeft,
      daiLeft
    );
  }

  function _closeWithdrawCollateral(
    ExchangeData memory exchangeData,
    CdpData memory cdpData,
    AddressRegistry memory addressRegistry,
    uint256 borrowedDaiAmount,
    uint256 ink
  ) private {
    IExchange exchange = IExchange(addressRegistry.exchange);
    address gemAddress = address(IJoin(cdpData.gemJoin).gem());

    wipeAndFreeGem(
      addressRegistry.manager,
      cdpData.gemJoin,
      cdpData.cdpId,
      cdpData.requiredDebt,
      ink
    );

    require(
      IERC20(exchangeData.fromTokenAddress).approve(address(exchange), ink),
      "MPA / Could not approve Exchange for Token"
    );
    exchange.swapTokenForDai(
      exchangeData.fromTokenAddress,
      exchangeData.fromTokenAmount,
      exchangeData.minToTokenAmount,
      exchangeData.exchangeAddress,
      exchangeData._exchangeCalldata
    );

    uint256 daiLeft = IERC20(DAI).balanceOf(address(this)).sub(borrowedDaiAmount);
    uint256 collateralLeft = IERC20(gemAddress).balanceOf(address(this));

    if (daiLeft > 0) {
      IERC20(DAI).transfer(cdpData.fundsReceiver, daiLeft);
    }
    if (collateralLeft > 0) {
      _withdrawGem(cdpData.gemJoin, cdpData.fundsReceiver, collateralLeft);
    }
    emit MultipleActionCalled(
      cdpData.methodName,
      cdpData.cdpId,
      exchangeData.minToTokenAmount,
      exchangeData.toTokenAmount,
      collateralLeft,
      daiLeft
    );
  }

  function _closeWithdrawDai(
    ExchangeData memory exchangeData,
    CdpData memory cdpData,
    AddressRegistry memory addressRegistry,
    uint256 borrowedDaiAmount,
    uint256 ink
  ) private {
    IExchange exchange = IExchange(addressRegistry.exchange);
    address gemAddress = address(IJoin(cdpData.gemJoin).gem());

    wipeAndFreeGem(
      addressRegistry.manager,
      cdpData.gemJoin,
      cdpData.cdpId,
      cdpData.requiredDebt,
      ink
    );

    require(
      IERC20(exchangeData.fromTokenAddress).approve(
        address(exchange),
        IERC20(gemAddress).balanceOf(address(this))
      ),
      "MPA / Could not approve Exchange for Token"
    );
    exchange.swapTokenForDai(
      exchangeData.fromTokenAddress,
      ink,
      exchangeData.minToTokenAmount,
      exchangeData.exchangeAddress,
      exchangeData._exchangeCalldata
    );

    uint256 daiLeft = IERC20(DAI).balanceOf(address(this)).sub(borrowedDaiAmount);

    if (daiLeft > 0) {
      IERC20(DAI).transfer(cdpData.fundsReceiver, daiLeft);
    }
    uint256 collateralLeft = IERC20(gemAddress).balanceOf(address(this));
    /*
    if (collateralLeft > 0) {
      _withdrawGem(cdpData.gemJoin, cdpData.fundsReceiver, collateralLeft);
    }*/
    emit MultipleActionCalled(
      cdpData.methodName,
      cdpData.cdpId,
      exchangeData.minToTokenAmount,
      exchangeData.toTokenAmount,
      collateralLeft,
      daiLeft
    );
  }

  function onFlashLoan(
    address initiator,
    address token,
    uint256 amount,
    uint256 fee,
    bytes calldata params
  ) public override returns (bytes32) {
    (
      uint8 mode,
      ExchangeData memory exchangeData,
      CdpData memory cdpData,
      AddressRegistry memory addressRegistry
    ) = abi.decode(params, (uint8, ExchangeData, CdpData, AddressRegistry));

    require(msg.sender == address(addressRegistry.lender), "mpa-untrusted-lender");

    uint256 borrowedDaiAmount = amount.add(fee);
    emit FLData(IERC20(DAI).balanceOf(address(this)).sub(cdpData.depositDai), borrowedDaiAmount);

    require(
      cdpData.requiredDebt.add(cdpData.depositDai) <= IERC20(DAI).balanceOf(address(this)),
      "mpa-receive-requested-amount-mismatch"
    );

    if (mode == 0) {
      _decreaseMP(exchangeData, cdpData, addressRegistry, fee);
    }
    if (mode == 1) {
      _increaseMP(exchangeData, cdpData, addressRegistry, fee);
    }
    if (mode == 2) {
      _closeWithdrawCollateral(
        exchangeData,
        cdpData,
        addressRegistry,
        borrowedDaiAmount,
        cdpData.borrowCollateral
      );
    }
    if (mode == 3) {
      _closeWithdrawDai(
        exchangeData,
        cdpData,
        addressRegistry,
        borrowedDaiAmount,
        cdpData.borrowCollateral
      );
    }

    IERC20(token).approve(addressRegistry.lender, borrowedDaiAmount);

    return keccak256("ERC3156FlashBorrower.onFlashLoan");
  }

  event FLData(uint256 borrowed, uint256 due);
  event MultipleActionCalled(
    string methodName,
    uint256 indexed cdpId,
    uint256 swapMinAmount,
    uint256 swapOptimistAmount,
    uint256 collateralLeft,
    uint256 daiLeft
  );

  fallback() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IERC20 {
  function totalSupply() external view returns (uint256 supply);

  function balanceOf(address _owner) external view returns (uint256 balance);

  function transfer(address _to, uint256 _value) external returns (bool success);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool success);

  function approve(address _spender, uint256 _value) external returns (bool success);

  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  function decimals() external view returns (uint256 digits);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import './IERC20.sol';

abstract contract IWETH {
  function allowance(address, address) public virtual returns (uint256);

  function balanceOf(address) public virtual returns (uint256);

  function approve(address, uint256) public virtual;

  function transfer(address, uint256) public virtual returns (bool);

  function transferFrom(
    address,
    address,
    uint256
  ) public virtual returns (bool);

  function deposit() public payable virtual;

  function withdraw(uint256) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import './IGem.sol';

abstract contract IJoin {
  bytes32 public ilk;

  function dec() public view virtual returns (uint256);

  function gem() public view virtual returns (IGem);

  function join(address, uint256) public payable virtual;

  function exit(address, uint256) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract IManager {
  function last(address) public virtual returns (uint256);

  function cdpCan(
    address,
    uint256,
    address
  ) public view virtual returns (uint256);

  function ilks(uint256) public view virtual returns (bytes32);

  function owns(uint256) public view virtual returns (address);

  function urns(uint256) public view virtual returns (address);

  function vat() public view virtual returns (address);

  function open(bytes32, address) public virtual returns (uint256);

  function give(uint256, address) public virtual;

  function cdpAllow(
    uint256,
    address,
    uint256
  ) public virtual;

  function urnAllow(address, uint256) public virtual;

  function frob(
    uint256,
    int256,
    int256
  ) public virtual;

  function flux(
    uint256,
    address,
    uint256
  ) public virtual;

  function move(
    uint256,
    address,
    uint256
  ) public virtual;

  function exit(
    address,
    uint256,
    address,
    uint256
  ) public virtual;

  function quit(uint256, address) public virtual;

  function enter(address, uint256) public virtual;

  function shift(uint256, uint256) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract IVat {
  struct Urn {
    uint256 ink; // Locked Collateral  [wad]
    uint256 art; // Normalised Debt    [wad]
  }

  struct Ilk {
    uint256 Art; // Total Normalised Debt     [wad]
    uint256 rate; // Accumulated Rates         [ray]
    uint256 spot; // Price with Safety Margin  [ray]
    uint256 line; // Debt Ceiling              [rad]
    uint256 dust; // Urn Debt Floor            [rad]
  }

  mapping(bytes32 => mapping(address => Urn)) public urns;
  mapping(bytes32 => Ilk) public ilks;
  mapping(bytes32 => mapping(address => uint256)) public gem; // [wad]

  function can(address, address) public view virtual returns (uint256);

  function dai(address) public view virtual returns (uint256);

  function frob(
    bytes32,
    address,
    address,
    address,
    int256,
    int256
  ) public virtual;

  function hope(address) public virtual;

  function move(
    address,
    address,
    uint256
  ) public virtual;

  function fork(
    bytes32,
    address,
    address,
    int256,
    int256
  ) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract IJug {
  struct Ilk {
    uint256 duty;
    uint256 rho;
  }

  mapping(bytes32 => Ilk) public ilks;

  function drip(bytes32) public virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import './IVat.sol';
import './IGem.sol';

abstract contract IDaiJoin {
  function vat() public virtual returns (IVat);

  function dai() public virtual returns (IGem);

  function join(address, uint256) public payable virtual;

  function exit(address, uint256) public virtual;
}

pragma solidity >=0.7.0;

abstract contract IExchange {
  function swapDaiForToken(
    address asset,
    uint256 amount,
    uint256 receiveAtLeast,
    address callee,
    bytes calldata withData
  ) external virtual;

  function swapTokenForDai(
    address asset,
    uint256 amount,
    uint256 receiveAtLeast,
    address callee,
    bytes calldata withData
  ) external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.7.6;

struct ExchangeData {
  address fromTokenAddress;
  address toTokenAddress;
  uint256 fromTokenAmount;
  uint256 toTokenAmount;
  uint256 minToTokenAmount;
  address exchangeAddress;
  bytes _exchangeCalldata;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.6.12;

interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.6.12;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract IGem {
  function dec() public virtual returns (uint256);

  function gem() public virtual returns (IGem);

  function join(address, uint256) public payable virtual;

  function exit(address, uint256) public virtual;

  function approve(address, uint256) public virtual;

  function transfer(address, uint256) public virtual returns (bool);

  function transferFrom(
    address,
    address,
    uint256
  ) public virtual returns (bool);

  function deposit() public payable virtual;

  function withdraw(uint256) public virtual;

  function allowance(address, address) public virtual returns (uint256);
}