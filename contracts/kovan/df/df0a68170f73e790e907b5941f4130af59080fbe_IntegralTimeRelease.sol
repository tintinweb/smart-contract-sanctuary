// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM_ADD_OVERFLOW');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM_SUB_UNDERFLOW');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM_MUL_OVERFLOW');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM_DIV_BY_ZERO');
        uint256 c = a / b;
        return c;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (c == mul(a, b)) {
            return c;
        } else {
            return add(c, 1);
        }
    }

    function add96(uint96 a, uint96 b) internal pure returns (uint96 c) {
        c = a + b;
        require(c >= a, 'SM_ADD_OVERFLOW');
    }

    function sub96(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b <= a, 'SM_SUB_UNDERFLOW');
        return a - b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, 'TH_ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IIntegralTimeRelease {
    event OwnerSet(address owner);
    event Claim(address claimer, uint256 option1Amount, uint256 option2Amount);
    event Option1Withdrawn(uint256 option1Amount);
    event Option2Withdrawn(uint256 option2Amount);
    event Option1StopBlockSet(uint256 option1StopBlock);
    event Option2StopBlockSet(uint256 option2StopBlock);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'Math.sol';
import 'SafeMath.sol';
import 'TransferHelper.sol';
import 'IERC20.sol';
import 'IIntegralTimeRelease.sol';

contract IntegralTimeRelease is IIntegralTimeRelease {
    using SafeMath for uint256;

    address public token;
    address public owner;

    uint256 public option1TotalAllocations;
    uint256 public option2TotalAllocations;
    uint256 public option1TotalClaimed;
    uint256 public option2TotalClaimed;
    bool public option1Withdrawn;
    bool public option2Withdrawn;

    mapping(address => uint256) public option1Allocations;
    mapping(address => uint256) public option2Allocations;
    mapping(address => uint256) public option1Claimed;
    mapping(address => uint256) public option2Claimed;

    uint256 public option1StartBlock;
    uint256 public option1EndBlock;
    uint256 public option1StopBlock;

    uint256 public option2StartBlock;
    uint256 public option2EndBlock;
    uint256 public option2StopBlock;

    constructor(
        address _token,
        uint256 _option1StartBlock,
        uint256 _option1EndBlock,
        uint256 _option2StartBlock,
        uint256 _option2EndBlock
    ) {
        owner = msg.sender;
        token = _token;
        _setOption1Timeframe(_option1StartBlock, _option1EndBlock);
        _setOption2Timeframe(_option2StartBlock, _option2EndBlock);
        option1Withdrawn = false;
        option2Withdrawn = false;
    }

    function setOwner(address _owner) external {
        owner = _owner;
        emit OwnerSet(owner);
    }

    function _setOption1Timeframe(uint256 _option1StartBlock, uint256 _option1EndBlock) internal {
        require(_option1EndBlock > _option1StartBlock, 'INVALID_OPTION1_TIME_FRAME');
        option1StartBlock = _option1StartBlock;
        option1EndBlock = _option1EndBlock;
        option1StopBlock = _option1EndBlock;
    }

    function _setOption2Timeframe(uint256 _option2StartBlock, uint256 _option2EndBlock) internal {
        require(_option2EndBlock > _option2StartBlock, 'INVALID_OPTION2_TIME_FRAME');
        option2StartBlock = _option2StartBlock;
        option2EndBlock = _option2EndBlock;
        option2StopBlock = _option2EndBlock;
    }

    function setOption1Allocations(address[] calldata wallets, uint256[] calldata amounts) external {
        require(msg.sender == owner, 'TR_FORBIDDEN');
        require(!option1Withdrawn, 'TR_ALLOCATION_WITHDRAWN');
        require(wallets.length == amounts.length, 'TR_INVALID_LENGTHS');
        for (uint32 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            require(option1Allocations[wallet] == 0, 'TR_ALLOCATION_ALREADY_SET');
            uint256 amount = amounts[i];
            option1Allocations[wallet] = amount;
            option1TotalAllocations += amount;
        }
        require(
            IERC20(token).balanceOf(address(this)) >= option1TotalAllocations.add(option2TotalAllocations),
            'TR_INSUFFICIENT_BALANCE'
        );
    }

    function setOption2Allocations(address[] calldata wallets, uint256[] calldata amounts) external {
        require(msg.sender == owner, 'TR_FORBIDDEN');
        require(!option2Withdrawn, 'TR_ALLOCATION_WITHDRAWN');
        require(wallets.length == amounts.length, 'TR_INVALID_LENGTHS');
        for (uint32 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            require(option2Allocations[wallet] == 0, 'TR_ALLOCATION_ALREADY_SET');
            uint256 amount = amounts[i];
            option2Allocations[wallet] = amount;
            option2TotalAllocations += amount;
        }
        require(
            IERC20(token).balanceOf(address(this)) >= option1TotalAllocations.add(option2TotalAllocations),
            'TR_INSUFFICIENT_BALANCE'
        );
    }

    function updateOption1Allocations(address[] calldata wallets, uint256[] calldata amounts) external {
        require(msg.sender == owner, 'TR_FORBIDDEN');
        require(!option1Withdrawn, 'TR_ALLOCATION_WITHDRAWN');
        require(wallets.length == amounts.length, 'TR_INVALID_LENGTHS');
        for (uint32 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint256 amount = amounts[i];
            require(getReleasedOption1(wallet) <= amount, 'TR_ALLOCATION_TOO_LITTLE');
            option1TotalAllocations = option1TotalAllocations.sub(option1Allocations[wallet]).add(amount);
            option1Allocations[wallet] = amount;
        }
        require(
            IERC20(token).balanceOf(address(this)) >= option1TotalAllocations.add(option2TotalAllocations),
            'TR_INSUFFICIENT_BALANCE'
        );
    }

    function updateOption2Allocations(address[] calldata wallets, uint256[] calldata amounts) external {
        require(msg.sender == owner, 'TR_FORBIDDEN');
        require(!option2Withdrawn, 'TR_ALLOCATION_WITHDRAWN');
        require(wallets.length == amounts.length, 'TR_INVALID_LENGTHS');
        for (uint32 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint256 amount = amounts[i];
            require(getReleasedOption2(wallet) <= amount, 'TR_ALLOCATION_TOO_LITTLE');
            option2TotalAllocations = option2TotalAllocations.sub(option2Allocations[wallet]).add(amount);
            option2Allocations[wallet] = amount;
        }
        require(
            IERC20(token).balanceOf(address(this)) >= option1TotalAllocations.add(option2TotalAllocations),
            'TR_INSUFFICIENT_BALANCE'
        );
    }

    function setOption1StopBlock(uint256 _option1StopBlock) external {
        require(msg.sender == owner, 'TR_FORBIDDEN');
        require(_option1StopBlock >= block.number && _option1StopBlock <= option1EndBlock, 'TR_INVALID_BLOCK_NUMBER');
        option1StopBlock = _option1StopBlock;
        emit Option1StopBlockSet(_option1StopBlock);
    }

    function setOption2StopBlock(uint256 _option2StopBlock) external {
        require(msg.sender == owner, 'TR_FORBIDDEN');
        require(_option2StopBlock >= block.number && _option2StopBlock <= option2EndBlock, 'TR_INVALID_BLOCK_NUMBER');
        option2StopBlock = _option2StopBlock;
        emit Option2StopBlockSet(_option2StopBlock);
    }

    function withdrawOption1() external {
        require(msg.sender == owner, 'TR_FORBIDDEN');
        require(block.number >= option1StopBlock, 'TR_NOT_ALLOWED_YET');
        require(!option1Withdrawn, 'TR_ALREADY_WITHDRAWN');

        uint256 option1Amount = option1TotalAllocations.mul(option1EndBlock.sub(option1StopBlock)).div(
            option1EndBlock.sub(option1StartBlock)
        );
        TransferHelper.safeTransfer(token, msg.sender, option1Amount);
        option1Withdrawn = true;

        emit Option1Withdrawn(option1Amount);
    }

    function withdrawOption2() external {
        require(msg.sender == owner, 'TR_FORBIDDEN');
        require(block.number >= option2StopBlock, 'TR_NOT_ALLOWED_YET');
        require(!option2Withdrawn, 'TR_ALREADY_WITHDRAWN');

        uint256 option2Amount = option2TotalAllocations.mul(option2EndBlock.sub(option2StopBlock)).div(
            option2EndBlock.sub(option2StartBlock)
        );
        TransferHelper.safeTransfer(token, msg.sender, option2Amount);
        option2Withdrawn = true;

        emit Option2Withdrawn(option2Amount);
    }

    function getReleasedOption1(address wallet) public view returns (uint256) {
        return _getReleasedOption1ForBlock(wallet, block.number);
    }

    function _getReleasedOption1ForBlock(address wallet, uint256 blockNumber) internal view returns (uint256) {
        if (blockNumber <= option1StartBlock) {
            return 0;
        }
        uint256 elapsed = Math.min(blockNumber, option1StopBlock).sub(option1StartBlock);
        uint256 allocationTime = option1EndBlock.sub(option1StartBlock);
        return option1Allocations[wallet].mul(elapsed).div(allocationTime);
    }

    function getReleasedOption2(address wallet) public view returns (uint256) {
        return _getReleasedOption2ForBlock(wallet, block.number);
    }

    function _getReleasedOption2ForBlock(address wallet, uint256 blockNumber) internal view returns (uint256) {
        if (blockNumber <= option2StartBlock) {
            return 0;
        }
        uint256 elapsed = Math.min(blockNumber, option2StopBlock).sub(option2StartBlock);
        uint256 allocationTime = option2EndBlock.sub(option2StartBlock);
        return option2Allocations[wallet].mul(elapsed).div(allocationTime);
    }

    function getClaimableOption1(address wallet) external view returns (uint256) {
        return getReleasedOption1(wallet).sub(option1Claimed[wallet]);
    }

    function getClaimableOption2(address wallet) external view returns (uint256) {
        return getReleasedOption2(wallet).sub(option2Claimed[wallet]);
    }

    function claim() external {
        uint256 _option1Claimed = option1Claimed[msg.sender];
        uint256 _option2Claimed = option2Claimed[msg.sender];
        uint256 option1Amount = getReleasedOption1(msg.sender).sub(_option1Claimed);
        uint256 option2Amount = getReleasedOption2(msg.sender).sub(_option2Claimed);

        option1Claimed[msg.sender] = _option1Claimed.add(option1Amount);
        option2Claimed[msg.sender] = _option2Claimed.add(option2Amount);
        option1TotalClaimed = option1TotalClaimed.add(option1Amount);
        option2TotalClaimed = option2TotalClaimed.add(option2Amount);

        TransferHelper.safeTransfer(token, msg.sender, option1Amount.add(option2Amount));
        emit Claim(msg.sender, option1Amount, option2Amount);
    }
}

