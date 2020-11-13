pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/ILoanShifter.sol";
import "../../mcd/saver/MCDSaverProxy.sol";
import "../../mcd/create/MCDCreateProxyActions.sol";

contract McdShifter is MCDSaverProxy {

    address public constant OPEN_PROXY_ACTIONS = 0x6d0984E80a86f26c0dd564ca0CF74a8E9Da03305;

    function getLoanAmount(uint _cdpId, address _joinAddr) public view virtual returns(uint loanAmount) {
        bytes32 ilk = manager.ilks(_cdpId);

        (, uint rate,,,) = vat.ilks(ilk);
        (, uint art) = vat.urns(ilk, manager.urns(_cdpId));
        uint dai = vat.dai(manager.urns(_cdpId));

        uint rad = sub(mul(art, rate), dai);
        loanAmount = rad / RAY;

        loanAmount = mul(loanAmount, RAY) < rad ? loanAmount + 1 : loanAmount;
    }

    function close(
        uint _cdpId,
        address _joinAddr,
        uint _loanAmount,
        uint _collateral
    ) public {
        address owner = getOwner(manager, _cdpId);
        bytes32 ilk = manager.ilks(_cdpId);
        (uint maxColl, ) = getCdpInfo(manager, _cdpId, ilk);

        // repay dai debt cdp
        paybackDebt(_cdpId, ilk, _loanAmount, owner);

        maxColl = _collateral > maxColl ? maxColl : _collateral;

        // withdraw collateral from cdp
        drawMaxCollateral(_cdpId, _joinAddr, maxColl);

        // send back to msg.sender
        if (_joinAddr == ETH_JOIN_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20 collToken = ERC20(getCollateralAddr(_joinAddr));
            collToken.transfer(msg.sender, collToken.balanceOf(address(this)));
        }
    }

    function open(
        uint _cdpId,
        address _joinAddr,
        uint _debtAmount
    ) public {

        uint collAmount = 0;

        if (_joinAddr == ETH_JOIN_ADDRESS) {
            collAmount = address(this).balance;
        } else {
            collAmount = ERC20(address(Join(_joinAddr).gem())).balanceOf(address(this));
        }

        if (_cdpId == 0) {
            openAndWithdraw(collAmount, _debtAmount, address(this), _joinAddr);
        } else {
            // add collateral
            addCollateral(_cdpId, _joinAddr, collAmount);
            // draw debt
            drawDai(_cdpId, manager.ilks(_cdpId), _debtAmount);
        }

        // transfer to repay FL
        ERC20(DAI_ADDRESS).transfer(msg.sender, ERC20(DAI_ADDRESS).balanceOf(address(this)));

        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function openAndWithdraw(uint _collAmount, uint _debtAmount, address _proxy, address _joinAddrTo) internal {
        bytes32 ilk = Join(_joinAddrTo).ilk();

        if (_joinAddrTo == ETH_JOIN_ADDRESS) {
            MCDCreateProxyActions(OPEN_PROXY_ACTIONS).openLockETHAndDraw{value: address(this).balance}(
                address(manager),
                JUG_ADDRESS,
                ETH_JOIN_ADDRESS,
                DAI_JOIN_ADDRESS,
                ilk,
                _debtAmount,
                _proxy
            );
        } else {
            ERC20(getCollateralAddr(_joinAddrTo)).approve(OPEN_PROXY_ACTIONS, uint256(-1));

            MCDCreateProxyActions(OPEN_PROXY_ACTIONS).openLockGemAndDraw(
                address(manager),
                JUG_ADDRESS,
                _joinAddrTo,
                DAI_JOIN_ADDRESS,
                ilk,
                _collAmount,
                _debtAmount,
                true,
                _proxy
            );
        }
    }


    function drawMaxCollateral(uint _cdpId, address _joinAddr, uint _amount) internal returns (uint) {
        manager.frob(_cdpId, -toPositiveInt(_amount), 0);
        manager.flux(_cdpId, address(this), _amount);

        uint joinAmount = _amount;

        if (Join(_joinAddr).dec() != 18) {
            joinAmount = _amount / (10 ** (18 - Join(_joinAddr).dec()));
        }

        Join(_joinAddr).exit(address(this), joinAmount);

        if (_joinAddr == ETH_JOIN_ADDRESS) {
            Join(_joinAddr).gem().withdraw(joinAmount); // Weth -> Eth
        }

        return joinAmount;
    }

}
