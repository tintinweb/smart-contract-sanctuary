pragma solidity ^0.6.0;

import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ComptrollerInterface.sol";
import "../../utils/SafeERC20.sol";

contract CreamBorrowProxy {

    using SafeERC20 for ERC20;

    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant COMPTROLLER_ADDR = 0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258;

    function borrow(address _cCollToken, address _cBorrowToken, address _borrowToken, uint _amount) public {
        address[] memory markets = new address[](2);
        markets[0] = _cCollToken;
        markets[1] = _cBorrowToken;

        ComptrollerInterface(COMPTROLLER_ADDR).enterMarkets(markets);

        require(CTokenInterface(_cBorrowToken).borrow(_amount) == 0);

        // withdraw funds to msg.sender
        if (_borrowToken != ETH_ADDR) {
            ERC20(_borrowToken).safeTransfer(msg.sender, ERC20(_borrowToken).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }
    }
}
