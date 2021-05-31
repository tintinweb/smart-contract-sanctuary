/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.6.7;

interface GemLike {
    function approve(address, uint) external;

    function transfer(address, uint) external;

    function transferFrom(address, address, uint) external;

    function deposit() external payable;

    function withdraw(uint) external;
}

interface DaiJoinLike {
    function vat() external returns (VatLike);

    function dai() external returns (GemLike);

    function join(address, uint) external payable;

    function exit(address, uint) external;
}

interface VatLike {
    function can(address, address) external view returns (uint);

    function ilks(bytes32) external view returns (uint, uint, uint, uint, uint);

    function dai(address) external view returns (uint);

    function urns(bytes32, address) external view returns (uint, uint);

    function frob(bytes32, address, address, address, int, int) external;

    function hope(address) external;

    function move(address, address, uint) external;
}

interface GemJoinLike {
    function dec() external returns (uint);

    function gem() external returns (GemLike);

    function join(address, uint) external payable;

    function exit(address, uint) external;
}

interface OasisLike {
    function sellAllAmount(address pay_gem, uint pay_amt, address buy_gem, uint min_fill_amount) external returns (uint);
}

interface ManagerLike {
    function cdpCan(address, uint, address) external view returns (uint);

    function ilks(uint) external view returns (bytes32);

    function owns(uint) external view returns (address);

    function urns(uint) external view returns (address);

    function vat() external view returns (address);

    function open(bytes32) external returns (uint);

    function give(uint, address) external;

    function cdpAllow(uint, address, uint) external;

    function urnAllow(address, uint) external;

    function frob(uint, int, int) external;

    function flux(uint, address, uint) external;

    function move(uint, address, uint) external;

    function exit(address, uint, address, uint) external;

    function quit(uint, address) external;

    function enter(address, uint) external;

    function shift(uint, uint) external;
}

contract Delev {

    function wipeWithEth(
        address manager,
        address ethJoin,
        address daiJoin,
        address oasisMatchingMarket,
        uint cdp,
        uint wadEth
    ) public {
        address urn = ManagerLike(manager).urns(cdp);
        require(wadEth > 0);

        //Remove the WETH from the vault
        ManagerLike(manager).frob(cdp, - int(wadEth), int(0));
        // Moves the WETH from the CDP urn to proxy's address
        ManagerLike(manager).flux(cdp, address(this), wadEth);
        // Exits WETH amount to proxy address as a token
        GemJoinLike(ethJoin).exit(address(this), wadEth);

        //Approve Oasis to obtain the WETH to be sold
        GemJoinLike(ethJoin).gem().approve(oasisMatchingMarket, wadEth);
        //Market order to sell the WETH for DAI
        uint daiAmt = OasisLike(oasisMatchingMarket).sellAllAmount(
            address(GemJoinLike(ethJoin).gem()),
            wadEth,
            address(DaiJoinLike(daiJoin).dai()),
            uint(0)
        );

        // Approves adapter to take the DAI amount
        DaiJoinLike(daiJoin).dai().approve(daiJoin, daiAmt);
        // Joins DAI into the vat
        DaiJoinLike(daiJoin).join(urn, daiAmt);
        // Calculate the amount of art corresponding to DAI (accumulated rates)
        int dart = _getWipeDart(ManagerLike(manager).vat(), VatLike(ManagerLike(manager).vat()).dai(urn), urn, ManagerLike(manager).ilks(cdp));
        // Pay back the art/dai in the vault
        ManagerLike(manager).frob(cdp, int(0), dart);
    }

    function _getWipeDart(
        address vat,
        uint dai,
        address urn,
        bytes32 ilk
    ) internal view returns (int dart) {
        // Gets actual rate from the vat
        (, uint rate,,,) = VatLike(vat).ilks(ilk);
        // Gets actual art value of the urn
        (, uint art) = VatLike(vat).urns(ilk, urn);

        // Uses the whole dai balance in the vat to reduce the debt
        dart = int(dai / rate);
        // Checks the calculated dart is not higher than urn.art (total debt), otherwise uses its value
        dart = uint(dart) <= art ? - dart : - int(art);
    }

}