// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./modules/Upgradable.sol";
import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IERC20.sol';

contract TomiEscrow is UpgradableProduct {
    using SafeMath for uint;

    struct ShareToken {
        uint dgasRate;
        uint totalReward;
    }

    address public DELEGATE;

    mapping(address => ShareToken) public shareTokens;

    event RewardDeposited(address shareToken, uint reward, uint totalReward);
    event RewardWithdraw(address shareToken, uint reward, address to);
    event DgasToTokenRated(uint oldRate, uint newRate);
    event ShareTokenUpdated(address tokenAddress, uint dgasRate);
    event ShareTokenSettled(address tokenAddress, uint dgasRate);

    constructor(address _DELEGATE) UpgradableProduct() public {
        DELEGATE = _DELEGATE;
    }

    modifier onlyDelegate() {
        require(msg.sender == DELEGATE, "TomiEscrow::FORBIDDEN");
        _;
    }

    function setShareToken(address _tokenAddress, uint _dgasRate) public requireImpl {
        require(!shareTokenExisted(_tokenAddress), "TomiEscrow::Share token address already exist!");
        require(_tokenAddress != address(0), "TomiEscrow::Share token address is not illegal");
        require(_dgasRate != uint(0), "TomiEscrow::Share token rate is not illegal");
        shareTokens[_tokenAddress] = ShareToken(_dgasRate, uint(0));

        emit ShareTokenSettled(_tokenAddress, _dgasRate);
    }


    function depositReward(address _tokenAddress, uint _reward) public requireImpl {
        require(shareTokenExisted(_tokenAddress), "DemaxEscrow::Share token not existed!");
        uint allowance = IERC20(_tokenAddress).allowance(impl, address(this));
        require(allowance >= _reward, "DemaxEscrow::Allowance is less than desired reward!");
        
        TransferHelper.safeTransferFrom(_tokenAddress, impl, address(this), _reward);
        
        uint totalReward = shareTokenReward(_tokenAddress);
        totalReward = totalReward.add(_reward);

        _updateShareTokenReward(_tokenAddress, totalReward);
        emit RewardDeposited(_tokenAddress, _reward, totalReward);
    }

    function withdrawReward(address _tokenAddress, uint _amount, address _to) public onlyDelegate {
        require(shareTokenExisted(_tokenAddress), "DemaxEscrow::Share token not existed!");
        uint totalReward = shareTokenReward(_tokenAddress);
        uint DGasToToken = shareTokens[_tokenAddress].dgasRate;
        
        require(totalReward >= _amount, "DemaxEscrow::Not enough rewards for withdraw!");
        
        uint dgasToReward = _amount.mul(DGasToToken);
        TransferHelper.safeTransfer(_tokenAddress, _to, dgasToReward);
        totalReward = totalReward.sub(dgasToReward);

        _updateShareTokenReward(_tokenAddress, totalReward);
        emit RewardWithdraw(_tokenAddress, dgasToReward, _to);
    }

    function updateShareTokenRate(address _tokenAddress, uint _dgasRate) public requireImpl {
        require(shareTokenExisted(_tokenAddress), "DemaxEscrow::Share token not existed!");
        require(_dgasRate != uint(0), "DemaxEscrow::Share token rate is not illegal");
        require( shareTokens[_tokenAddress].dgasRate != _dgasRate, "DemaxEscrow::Not be able to set same Dgas rate!");

        shareTokens[_tokenAddress].dgasRate = _dgasRate;

        emit ShareTokenUpdated(_tokenAddress, _dgasRate);
    }

    function shareTokenExisted(address _tokenAddress) public view returns(bool) {
        require(_tokenAddress != address(0), "DemaxEscrow::Share token address is illegal");
        return shareTokens[_tokenAddress].dgasRate != uint(0);
    }

    function shareTokenReward(address _tokenAddress) public view returns(uint) {
        return shareTokens[_tokenAddress].totalReward;
    }

    function _updateShareTokenReward(address _tokenAddress, uint _newReward) private {
        require(shareTokenExisted(_tokenAddress), "DemaxEscrow::Share token not existed!");
        shareTokens[_tokenAddress].totalReward = _newReward;
    }

}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.16;

contract UpgradableProduct {
    address public impl;

    event ImplChanged(address indexed _oldImpl, address indexed _newImpl);

    constructor() public {
        impl = msg.sender;
    }

    modifier requireImpl() {
        require(msg.sender == impl, 'FORBIDDEN');
        _;
    }

    function upgradeImpl(address _newImpl) public requireImpl {
        require(_newImpl != address(0), 'INVALID_ADDRESS');
        require(_newImpl != impl, 'NO_CHANGE');
        address lastImpl = impl;
        impl = _newImpl;
        emit ImplChanged(lastImpl, _newImpl);
    }
}

contract UpgradableGovernance {
    address public governor;

    event GovernorChanged(address indexed _oldGovernor, address indexed _newGovernor);

    constructor() public {
        governor = msg.sender;
    }

    modifier requireGovernor() {
        require(msg.sender == governor, 'FORBIDDEN');
        _;
    }

    function upgradeGovernance(address _newGovernor) public requireGovernor {
        require(_newGovernor != address(0), 'INVALID_ADDRESS');
        require(_newGovernor != governor, 'NO_CHANGE');
        address lastGovernor = governor;
        governor = _newGovernor;
        emit GovernorChanged(lastGovernor, _newGovernor);
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}