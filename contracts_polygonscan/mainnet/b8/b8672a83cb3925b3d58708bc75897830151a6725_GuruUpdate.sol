// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import './SafeMath.sol';
import './IERC20.sol';
import './ERC20.sol';
import './SafeERC20.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';




contract GuruUpdate is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant Guru =    0x96e7593E376a8f75fD52ae71B7b45358eF373AE8;//GuruAddr
    address public constant GuruV2 =    0x6d88d72DdC4FF139aC3b45Fc13242C3c3709F68D;//GuruV2Addr

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    function safeGuruV2Transfer(address _to, uint256 _GuruAmt) internal {
        uint256 GuruBal = IERC20(GuruV2).balanceOf(address(this));
        if (_GuruAmt > GuruBal) {
            IERC20(GuruV2).transfer(_to, GuruBal);
        } else {
            IERC20(GuruV2).transfer(_to, _GuruAmt);
        }
    }
    function GuruToGuruV2(uint256 _amt) external nonReentrant{

        IERC20(Guru).safeTransferFrom(
            address(msg.sender),
            burnAddress,
            _amt
        );

        safeGuruV2Transfer(msg.sender, _amt);
    }


}