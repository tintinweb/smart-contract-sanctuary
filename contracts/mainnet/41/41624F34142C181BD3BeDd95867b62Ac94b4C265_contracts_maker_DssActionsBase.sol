// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../Constants.sol";
import "./IDssCdpManager.sol";

interface GemLike {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;
}

interface GemJoinLike {
    function dec() external returns (uint256);

    function gem() external returns (address);

    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}

interface VatLike {
    function can(address, address) external view returns (uint256);

    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function frob(
        bytes32,
        address,
        address,
        address,
        int256,
        int256
    ) external;

    function hope(address) external;

    function move(
        address,
        address,
        uint256
    ) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint256);

    function ilks(bytes32) external view returns (uint256, uint256);
}

interface DaiJoinLike {
    function vat() external returns (VatLike);

    function dai() external returns (GemLike);

    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}

contract DssActionsBase {
    uint256 constant RAY = 10**27;

    using SafeMath for uint256;

    function _convertTo18(address gemJoin, uint256 amt)
        internal
        returns (uint256 wad)
    {
        // For those collaterals that have less than 18 decimals precision we need to do the conversion before passing to frob function
        // Adapters will automatically handle the difference of precision
        wad = amt.mul(10**(18 - GemJoinLike(gemJoin).dec()));
    }

    function _toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int-overflow");
    }

    function _toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = wad.mul(10**27);
    }

    function _gemJoin_join(
        address apt,
        address urn,
        uint256 wad,
        bool transferFrom
    ) internal {
        // Only executes for tokens that have approval/transferFrom implementation
        if (transferFrom) {
            // Tokens already in address(this)
            // GemLike(GemJoinLike(apt).gem()).transferFrom(msg.sender, address(this), wad);
            // Approves adapter to take the token amount
            GemLike(GemJoinLike(apt).gem()).approve(apt, wad);
        }
        // Joins token collateral into the vat
        GemJoinLike(apt).join(urn, wad);
    }

    function _daiJoin_join(
        address apt,
        address urn,
        uint256 wad
    ) internal {
        // Contract already has tokens
        // Gets DAI from the user's wallet
        // DaiJoinLike(apt).dai().transferFrom(msg.sender, address(this), wad);
        // Approves adapter to take the DAI amount
        DaiJoinLike(apt).dai().approve(apt, wad);
        // Joins DAI into the vat
        DaiJoinLike(apt).join(urn, wad);
    }

    function _getDrawDart(
        address vat,
        address jug,
        address urn,
        bytes32 ilk,
        uint256 wad
    ) internal returns (int256 dart) {
        // Updates stability fee rate
        uint256 rate = JugLike(jug).drip(ilk);

        // Gets DAI balance of the urn in the vat
        uint256 dai = VatLike(vat).dai(urn);

        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < wad.mul(RAY)) {
            // Calculates the needed dart so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            dart = _toInt(wad.mul(RAY).sub(dai) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra dart wei (for the given DAI wad amount)
            dart = uint256(dart).mul(rate) < wad.mul(RAY) ? dart + 1 : dart;
        }
    }

    function _getWipeDart(
        address vat,
        uint256 dai,
        address urn,
        bytes32 ilk
    ) internal view returns (int256 dart) {
        // Gets actual rate from the vat
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        // Gets actual art value of the urn
        (, uint256 art) = VatLike(vat).urns(ilk, urn);

        // Uses the whole dai balance in the vat to reduce the debt
        dart = _toInt(dai / rate);
        // Checks the calculated dart is not higher than urn.art (total debt), otherwise uses its value
        dart = uint256(dart) <= art ? -dart : -_toInt(art);
    }

    function _getWipeAllWad(
        address vat,
        address usr,
        address urn,
        bytes32 ilk
    ) internal view returns (uint256 wad) {
        // Gets actual rate from the vat
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        // Gets actual art value of the urn
        (, uint256 art) = VatLike(vat).urns(ilk, urn);
        // Gets actual dai amount in the urn
        uint256 dai = VatLike(vat).dai(usr);

        uint256 rad = art.mul(rate).sub(dai);
        wad = rad / RAY;

        // If the rad precision has some dust, it will need to request for 1 extra wad wei
        wad = wad.mul(RAY) < rad ? wad + 1 : wad;
    }

    function _getSuppliedAndBorrow(address gemJoin, uint256 cdp)
        internal
        returns (uint256, uint256)
    {
        IDssCdpManager manager = IDssCdpManager(Constants.CDP_MANAGER);

        address vat = manager.vat();
        bytes32 ilk = manager.ilks(cdp);

        // Gets actual rate from the vat
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        // Gets actual art value of the urn
        (uint256 supplied, uint256 art) = VatLike(vat).urns(
            ilk,
            manager.urns(cdp)
        );
        // Gets actual dai amount in the urn
        uint256 dai = VatLike(vat).dai(manager.owns(cdp));

        uint256 rad = art.mul(rate).sub(dai);
        uint256 wad = rad / RAY;

        // If the rad precision has some dust, it will need to request for 1 extra wad wei
        uint256 borrowed = wad.mul(RAY) < rad ? wad + 1 : wad;

        // Convert back to native units
        supplied = supplied.div(10**(18 - GemJoinLike(gemJoin).dec()));

        return (supplied, borrowed);
    }

    function _lockGemAndDraw(
        address gemJoin,
        uint256 cdp,
        uint256 wadC,
        uint256 wadD
    ) internal {
        IDssCdpManager manager = IDssCdpManager(Constants.CDP_MANAGER);

        address urn = manager.urns(cdp);
        address vat = manager.vat();
        bytes32 ilk = manager.ilks(cdp);

        // Receives ETH amount, converts it to WETH and joins it into the vat
        _gemJoin_join(gemJoin, urn, wadC, true);

        // Locks GEM amount into the CDP and generates debt
        manager.frob(
            cdp,
            _toInt(_convertTo18(gemJoin, wadC)),
            _getDrawDart(vat, Constants.MCD_JUG, urn, ilk, wadD)
        );

        // Moves the DAI amount (balance in the vat in rad) to proxy's address
        manager.move(cdp, address(this), _toRad(wadD));

        // Allows adapter to access to proxy's DAI balance in the vat
        if (
            VatLike(vat).can(address(this), address(Constants.MCD_JOIN_DAI)) ==
            0
        ) {
            VatLike(vat).hope(Constants.MCD_JOIN_DAI);
        }
        // Exits DAI to the user's wallet as a token
        DaiJoinLike(Constants.MCD_JOIN_DAI).exit(address(this), wadD);
    }

    function _wipeAllAndFreeGem(
        address gemJoin,
        uint256 cdp,
        uint256 amtC
    ) internal {
        IDssCdpManager manager = IDssCdpManager(Constants.CDP_MANAGER);

        address vat = manager.vat();
        address urn = manager.urns(cdp);
        bytes32 ilk = manager.ilks(cdp);
        (, uint256 art) = VatLike(vat).urns(ilk, urn);

        // Joins DAI amount into the vat
        _daiJoin_join(
            Constants.MCD_JOIN_DAI,
            urn,
            _getWipeAllWad(vat, urn, urn, ilk)
        );
        uint256 wadC = _convertTo18(gemJoin, amtC);
        // Paybacks debt to the CDP and unlocks token amount from it
        manager.frob(cdp, -_toInt(wadC), -int256(art));
        // Moves the amount from the CDP urn to proxy's address
        manager.flux(cdp, address(this), wadC);
        // Exits token amount to the user's wallet as a token
        GemJoinLike(gemJoin).exit(address(this), amtC);
    }

    function _openLockGemAndDraw(
        address gemJoin,
        bytes32 ilk,
        uint256 amtC,
        uint256 wadD
    ) internal returns (uint256 cdp) {
        cdp = IDssCdpManager(Constants.CDP_MANAGER).open(ilk, address(this));
        _lockGemAndDraw(gemJoin, cdp, amtC, wadD);
    }
}
