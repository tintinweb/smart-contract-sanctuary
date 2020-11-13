// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./maker/IDssCdpManager.sol";
import "./maker/IDssProxyActions.sol";
import "./maker/DssActionsBase.sol";

import "./Constants.sol";

contract VaultStats {
    uint256 constant RAY = 10**27;

    using SafeMath for uint256;

    // CDP ID => DAI/USDC Ratio in 6 decimals
    // i.e. What was DAI/USDC ratio when CDP was opened
    mapping(uint256 => uint256) public daiUsdcRatio6;

    //** View functions for stats ** //

    function _getCdpSuppliedAndBorrowed(
        address vat,
        address usr,
        address urn,
        bytes32 ilk
    ) internal view returns (uint256, uint256) {
        // Gets actual rate from the vat
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        // Gets actual art value of the urn
        (uint256 supplied, uint256 art) = VatLike(vat).urns(ilk, urn);
        // Gets actual dai amount in the urn
        uint256 dai = VatLike(vat).dai(usr);

        uint256 rad = art.mul(rate).sub(dai);
        uint256 wad = rad / RAY;

        // If the rad precision has some dust, it will need to request for 1 extra wad wei
        uint256 borrowed = wad.mul(RAY) < rad ? wad + 1 : wad;

        // Note that supplied is in 18 decimals, so you'll need to convert it back
        // i.e. supplied = supplied / 10 ** (18 - decimals)

        return (supplied, borrowed);
    }

    // Get DAI borrow / supply stats
    function getCdpStats(uint256 cdp)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address vat = IDssCdpManager(Constants.CDP_MANAGER).vat();
        address urn = IDssCdpManager(Constants.CDP_MANAGER).urns(cdp);
        bytes32 ilk = IDssCdpManager(Constants.CDP_MANAGER).ilks(cdp);
        address usr = IDssCdpManager(Constants.CDP_MANAGER).owns(cdp);

        (uint256 supplied, uint256 borrowed) = _getCdpSuppliedAndBorrowed(
            vat,
            usr,
            urn,
            ilk
        );

        uint256 ratio = daiUsdcRatio6[cdp];

        // Note that supplied and borrowed are in 18 decimals
        // while DAI USDC ratio is in 6 decimals
        return (supplied, borrowed, ratio);
    }

    function setDaiUsdcRatio6(uint256 _cdp, uint256 _daiUsdcRatio6) public {
        IDssCdpManager manager = IDssCdpManager(Constants.CDP_MANAGER);
        address owner = manager.owns(_cdp);

        require(
            owner == msg.sender || manager.cdpCan(owner, _cdp, msg.sender) == 1,
            "cdp-not-allowed"
        );

        daiUsdcRatio6[_cdp] = _daiUsdcRatio6;
    }
}
