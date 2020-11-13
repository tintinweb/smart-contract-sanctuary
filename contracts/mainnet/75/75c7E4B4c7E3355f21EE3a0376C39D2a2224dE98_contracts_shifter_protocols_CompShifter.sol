pragma solidity ^0.6.0;

import "../../compound/helpers/CompoundSaverHelper.sol";

contract CompShifter is CompoundSaverHelper {

    address public constant COMPTROLLER_ADDR = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    function getWholeDebt(uint _cdpId, address _joinAddr) public virtual returns(uint loanAmount) {
        return CTokenInterface(_joinAddr).borrowBalanceCurrent(msg.sender);
    }

    function close(
        address _cCollAddr,
        address _cBorrowAddr,
        uint _collAmount,
        uint _debtAmount
    ) public {
        address collAddr = getUnderlyingAddr(_cCollAddr);

        // payback debt
        paybackDebt(_debtAmount, _cBorrowAddr, getUnderlyingAddr(_cBorrowAddr), tx.origin);

        // draw coll
        if (CTokenInterface(_cBorrowAddr).borrowBalanceCurrent(address(this)) == 0) {
            uint cTokenBalance = CTokenInterface(_cCollAddr).balanceOf(address(this));
            require(CTokenInterface(_cCollAddr).redeem(cTokenBalance) == 0);
        } else {
            require(CTokenInterface(_cCollAddr).redeemUnderlying(_collAmount) == 0);
        }

        // Send back money to repay FL
        if (collAddr == ETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(collAddr).transfer(msg.sender, ERC20(collAddr).balanceOf(address(this)));
        }
    }

    function changeDebt(
        address _cBorrowAddrOld,
        address _cBorrowAddrNew,
        uint _debtAmountOld,
        uint _debtAmountNew
    ) public {

        address borrowAddrNew = getUnderlyingAddr(_cBorrowAddrNew);

        // payback debt in one token
        paybackDebt(_debtAmountOld, _cBorrowAddrOld, getUnderlyingAddr(_cBorrowAddrOld), tx.origin);

        // draw debt in another one
        borrowCompound(_cBorrowAddrNew, _debtAmountNew);

        // Send back money to repay FL
        if (borrowAddrNew == ETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(borrowAddrNew).transfer(msg.sender, ERC20(borrowAddrNew).balanceOf(address(this)));
        }
    }

    function open(
        address _cCollAddr,
        address _cBorrowAddr,
        uint _debtAmount
    ) public {

        address collAddr = getUnderlyingAddr(_cCollAddr);
        address borrowAddr = getUnderlyingAddr(_cBorrowAddr);

        uint collAmount = 0;

        if (collAddr == ETH_ADDRESS) {
            collAmount = address(this).balance;
        } else {
            collAmount = ERC20(collAddr).balanceOf(address(this));
        }

        depositCompound(collAddr, _cCollAddr, collAmount);

        // draw debt
        borrowCompound(_cBorrowAddr, _debtAmount);

        // Send back money to repay FL
        if (borrowAddr == ETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(borrowAddr).transfer(msg.sender, ERC20(borrowAddr).balanceOf(address(this)));
        }

    }

    function depositCompound(address _tokenAddr, address _cTokenAddr, uint _amount) internal {
        approveCToken(_tokenAddr, _cTokenAddr);

        enterMarket(_cTokenAddr);

        if (_tokenAddr != ETH_ADDRESS) {
            require(CTokenInterface(_cTokenAddr).mint(_amount) == 0, "mint error");
        } else {
            CEtherInterface(_cTokenAddr).mint{value: _amount}();
        }
    }

    function borrowCompound(address _cTokenAddr, uint _amount) internal {
        enterMarket(_cTokenAddr);

        require(CTokenInterface(_cTokenAddr).borrow(_amount) == 0);
    }

    function enterMarket(address _cTokenAddr) public {
        address[] memory markets = new address[](1);
        markets[0] = _cTokenAddr;

        ComptrollerInterface(COMPTROLLER_ADDR).enterMarkets(markets);
    }

}
