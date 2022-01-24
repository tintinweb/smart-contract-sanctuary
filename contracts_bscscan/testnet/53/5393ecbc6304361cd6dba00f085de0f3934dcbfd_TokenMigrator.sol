/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

pragma solidity 0.7.5;

// ----------------------------------------------------------------------------
// --- Name   : AlphaDAO - [https://www.alphadao.financial/]
// --- Symbol : Format - {OX}
// --- Supply : Generated from DAO
// --- @title : the Beginning and the End 
// --- 01000110 01101111 01110010 00100000 01110100 01101000 01100101 00100000 01101100 
// --- 01101111 01110110 01100101 00100000 01101111 01100110 00100000 01101101 01111001 
// --- 00100000 01100011 01101000 01101001 01101100 01100100 01110010 01100101 01101110
// --- AlphaDAO.financial - EJS32 - 2021
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// --- interface IERC20
// ----------------------------------------------------------------------------

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// ----------------------------------------------------------------------------
// --- interface IOwnable
// ----------------------------------------------------------------------------

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

// ----------------------------------------------------------------------------
// --- contract Ownable
// ----------------------------------------------------------------------------


abstract contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyOwner {
        emit OwnershipPulled(_owner, address(0));
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyOwner {
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// --- Library SafeERC20
// ----------------------------------------------------------------------------

library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// ----------------------------------------------------------------------------
// --- contract TokenMigrator
// ----------------------------------------------------------------------------

contract TokenMigrator is Ownable {
    using SafeERC20 for IERC20;

    IERC20 internal immutable oldOX; // v1 token
    IERC20 internal immutable newOX; // v2 token

    constructor(address _oldOX, address _newOX) {
        require(_oldOX != address(0), "Zero address: oldOX");
        oldOX = IERC20(_oldOX);
        require(_newOX != address(0), "Zero address: newOX");
        newOX = IERC20(_newOX);
    }

    // migrate oldOX to newOX - 1:1 like kind
    function migrate(uint256 amount) external {
        oldOX.safeTransferFrom(msg.sender, address(this), amount);
        newOX.safeTransfer(msg.sender, amount);
    }

    // withdraw oldOX so it can be bridged on ETH and returned as more newOX
    function replenish() external onlyOwner {
        oldOX.safeTransfer(msg.sender, oldOX.balanceOf(address(this)));
    }

    // withdraw migrated oldOX and unmigrated newOX
    function clear() external onlyOwner {
        oldOX.safeTransfer(msg.sender, oldOX.balanceOf(address(this)));
        newOX.safeTransfer(msg.sender, newOX.balanceOf(address(this)));
    }
}