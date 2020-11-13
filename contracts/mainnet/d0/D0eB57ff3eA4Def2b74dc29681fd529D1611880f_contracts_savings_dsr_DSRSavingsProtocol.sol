pragma solidity ^0.6.0;

import "../../interfaces/Join.sol";
import "../../DS/DSMath.sol";

abstract contract VatLike {
    function can(address, address) virtual public view returns (uint);
    function ilks(bytes32) virtual public view returns (uint, uint, uint, uint, uint);
    function dai(address) virtual public view returns (uint);
    function urns(bytes32, address) virtual public view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) virtual public;
    function hope(address) virtual public;
    function move(address, address, uint) virtual public;
}

abstract contract PotLike {
    function pie(address) virtual public view returns (uint);
    function drip() virtual public returns (uint);
    function join(uint) virtual public;
    function exit(uint) virtual public;
}

abstract contract GemLike {
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public;
    function transferFrom(address, address, uint) virtual public;
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
}

abstract contract DaiJoinLike {
    function vat() virtual public returns (VatLike);
    function dai() virtual public returns (GemLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

contract DSRSavingsProtocol is DSMath {

    // Mainnet
    address public constant POT_ADDRESS = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;

    function dsrDeposit(uint _amount, bool _fromUser) internal {
        VatLike vat = DaiJoinLike(DAI_JOIN_ADDRESS).vat();

        uint chi = PotLike(POT_ADDRESS).drip();

        daiJoin_join(DAI_JOIN_ADDRESS, address(this), _amount, _fromUser);

        if (vat.can(address(this), address(POT_ADDRESS)) == 0) {
            vat.hope(POT_ADDRESS);
        }

        PotLike(POT_ADDRESS).join(mul(_amount, RAY) / chi);
    }

    function dsrWithdraw(uint _amount, bool _toUser) internal {
        VatLike vat = DaiJoinLike(DAI_JOIN_ADDRESS).vat();

        uint chi = PotLike(POT_ADDRESS).drip();
        uint pie = mul(_amount, RAY) / chi;

        PotLike(POT_ADDRESS).exit(pie);
        uint balance = DaiJoinLike(DAI_JOIN_ADDRESS).vat().dai(address(this));

        if (vat.can(address(this), address(DAI_JOIN_ADDRESS)) == 0) {
            vat.hope(DAI_JOIN_ADDRESS);
        }

        address to;
        if (_toUser) {
            to = msg.sender;
        } else {
            to = address(this);
        }

        if (_amount == uint(-1)) {
            DaiJoinLike(DAI_JOIN_ADDRESS).exit(to, mul(chi, pie) / RAY);
        } else {
            DaiJoinLike(DAI_JOIN_ADDRESS).exit(
                to,
                balance >= mul(_amount, RAY) ? _amount : balance / RAY
            );
        }
    }

    function daiJoin_join(address apt, address urn, uint wad, bool _fromUser) internal {
        if (_fromUser) {
            DaiJoinLike(apt).dai().transferFrom(msg.sender, address(this), wad);
        }

        DaiJoinLike(apt).dai().approve(apt, wad);

        DaiJoinLike(apt).join(urn, wad);
    }
}
