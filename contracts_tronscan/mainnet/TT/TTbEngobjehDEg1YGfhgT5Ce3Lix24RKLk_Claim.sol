//SourceUnit: Claim.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./TransferHelper.sol";

contract Claim {
    using SafeMath for uint256;
    using TransferHelper for address;

    address public owner;
    address public token;
    mapping(address => uint256) private _accountAwards;

    event ClaimAward(address indexed account, uint256 value);

    constructor(address token_, address owner_) public {
        token = token_;
        owner = owner_;
    }

    function accountAward(address account) public view returns (uint256) {
        return _accountAwards[account];
    }

    function rewardWrite(address account, uint256 amount) public {
        require(msg.sender == owner);

        _accountAwards[account] = _accountAwards[account].add(amount);
    }

    function claimAward(address account) public {
        uint256 value = _accountAwards[account];
        require(value > 0);
        require(token.safeTransfer(account, value));

        _accountAwards[account] = 0;
        emit ClaimAward(account, value);
    }
}


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: TransferHelper.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal returns (bool) {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal returns (bool) {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}