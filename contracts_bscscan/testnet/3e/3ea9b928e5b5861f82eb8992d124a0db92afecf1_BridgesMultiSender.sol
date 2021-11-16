pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT License

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";


abstract contract Reentrancy {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract BridgesMultiSender is Ownable, Reentrancy {
    using SafeMath for uint256;    
    using SafeERC20 for IERC20;
    using Address for address;


    event Multisended(uint256 total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint256 balance);
    

    receive() external payable{}


    function multisendToken(address token, address[] calldata accounts, uint256[] calldata amounts) external payable {
        
        uint256 total = 0;
        uint8 i = 0;
        for (i; i < accounts.length; i++) {
            IERC20(token).safeTransferFrom(msg.sender, accounts[i], amounts[i]);
            total = total.add(amounts[i]);
        }
        emit Multisended(total, token);
        
    }

    function multisendEther(address[] calldata accounts, uint256[] calldata amounts) external payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < accounts.length; i++) {
            require(total >= amounts[i]);
            total = total.sub(amounts[i]);
            (bool success, ) = payable(accounts[i]).call{value: amounts[i]}("");
            require(success, "Failed");
        }
        emit Multisended(msg.value, address(0));
    }
}