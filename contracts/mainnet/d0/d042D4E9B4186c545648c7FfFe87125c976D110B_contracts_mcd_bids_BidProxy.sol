pragma solidity ^0.6.0;

import "../../interfaces/Join.sol";
import "../../interfaces/ERC20.sol";
import "../../interfaces/Vat.sol";
import "../../interfaces/Flipper.sol";
import "../../interfaces/Gem.sol";

contract BidProxy {

    address public constant DAI_JOIN = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;

    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function daiBid(uint _bidId, uint _amount, address _flipper) public {
        uint tendAmount = _amount * (10 ** 27);

        joinDai(_amount);

        (, uint lot, , , , , , ) = Flipper(_flipper).bids(_bidId);

        Vat(VAT_ADDRESS).hope(_flipper);

        Flipper(_flipper).tend(_bidId, lot, tendAmount);
    }

    function collateralBid(uint _bidId, uint _amount, address _flipper) public {
        (uint bid, , , , , , , ) = Flipper(_flipper).bids(_bidId);

        joinDai(bid / (10**27));

        Vat(VAT_ADDRESS).hope(_flipper);

        Flipper(_flipper).dent(_bidId, _amount, bid);
    }

    function closeBid(uint _bidId, address _flipper, address _joinAddr) public {
        bytes32 ilk = Join(_joinAddr).ilk();

        Flipper(_flipper).deal(_bidId);
        uint amount = Vat(VAT_ADDRESS).gem(ilk, address(this));

        Vat(VAT_ADDRESS).hope(_joinAddr);
        Gem(_joinAddr).exit(msg.sender, amount);
    }

    function exitCollateral(address _joinAddr) public {
        bytes32 ilk = Join(_joinAddr).ilk();

        uint amount = Vat(VAT_ADDRESS).gem(ilk, address(this));

        Vat(VAT_ADDRESS).hope(_joinAddr);
        Gem(_joinAddr).exit(msg.sender, amount);
    }

    function exitDai() public {
        uint amount = Vat(VAT_ADDRESS).dai(address(this)) / (10**27);

        Vat(VAT_ADDRESS).hope(DAI_JOIN);
        Gem(DAI_JOIN).exit(msg.sender, amount);
    }

    function withdrawToken(address _token) public {
        uint balance = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(msg.sender, balance);
    }

    function withdrawEth() public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function joinDai(uint _amount) internal {
        uint amountInVat = Vat(VAT_ADDRESS).dai(address(this)) / (10**27);

        if (_amount > amountInVat) {
            uint amountDiff = (_amount - amountInVat) + 1;

            ERC20(DAI_ADDRESS).transferFrom(msg.sender, address(this), amountDiff);
            ERC20(DAI_ADDRESS).approve(DAI_JOIN, amountDiff);
            Join(DAI_JOIN).join(address(this), amountDiff);
        }
    }
}
