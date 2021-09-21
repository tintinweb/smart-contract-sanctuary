// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.26;

import './Ownable.sol';
import './SafeMath.sol';
import './IERC20.sol';

contract BatchTransfer is Ownable {
    using SafeMath for uint256;

    function transferETH (address[] memory to, uint256 amount) payable public {
        require(to.length > 0, 'NO ADDRESS');
        require(msg.value > amount * to.length, 'NOT ENOUGH');
        for (uint i; i < to.length; i++) {
            to[i].transfer(amount);
        }
    }

    function transferToken (address token, address[] memory to, uint amount) payable public {
        require(to.length > 0, 'NO ADDRESS');
        require(IERC20(token).balanceOf(msg.sender) >= amount*to.length, 'NOT ENOUGH');
        for (uint i; i < to.length; i++) {
            IERC20(token).transferFrom(msg.sender, to[i], amount);
        }
    }

    function withdraw () public onlyOwner {
        owner.transfer(address(this).balance);
    }

}