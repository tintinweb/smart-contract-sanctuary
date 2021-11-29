/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

/// @title Any ERC20 contract use the send method will charge 10%
/// @author reason
/// @notice amount less than 100 will failed
contract Charge {
    
    // 10% charge
    uint percent = 90;

    // owner
    address public owner;

    // ONEC
    address token = 0xe90b176264754786d30D1058d3F0800064E6B89B;

    using SafeMath for uint256;

    constructor() {
        owner = msg.sender;
    }

    /// @param _amount transfer amount
    /// @dev amount less than 100 will failed
    modifier lessThan(uint _amount) {
        require(_amount >= 100);
        _;
    }
    
    /// @dev send will charge 10% to owner
    function send(address _to, uint256 _amount) public lessThan(_amount) {
        uint real = _amount.mul(percent).div(100);
        uint fee = _amount.sub(real);
        _safeTransferFrom(msg.sender, _to, real);
        _safeTransferFrom(msg.sender, owner, fee);
    }

    function _safeTransferFrom(address _from, address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}