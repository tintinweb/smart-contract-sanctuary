// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./libraries/TransferHelper.sol";
contract NGReservations {
    INGNFT private _nft;

    bool private _canReserve;
    mapping (address => bool) private _admins;

    address[] private _allAllocated;
    mapping (address => uint) private _reservations;
    mapping (address => uint) private _allocations;

    uint256 public _pricePerAllocation;

    modifier onlyAdmin() {
        require(_admins[msg.sender], "No admin.");
        _;
    }

    constructor(uint256 pricePer) {
        _admins[msg.sender] = true;

        _pricePerAllocation = pricePer;

        seedAllocations();
    }

    function seedAllocations() private {
        _addAllocation(0xF8D371421790d718B0Fb37F2D3e26d4bD4BB30CE, 15);
        _addAllocation(0x3D2F37e5fE0114F5F34549Bc0CE7A93C0A1b9AC2, 15);
    }

    function addAllocation(address addy, uint amount) external onlyAdmin {
        _addAllocation(addy, amount);
    }

    function _addAllocation(address addy, uint amount) private {
        _allAllocated.push(addy);
        _allocations[addy] = amount;
    }

    function editAllocation(address addy, uint amount) external onlyAdmin {
        require(_allocations[addy] > 0, "Cannot edit because this user has no allocation");

        _allocations[addy] = amount;
    }

    function getReservations(address addy) external view onlyAdmin returns (uint) {
        return _reservations[addy];
    }

    function getAllocations(address addy) external view onlyAdmin returns (uint) {
        return _allocations[addy];
    }

    function setPrice(uint256 price) external onlyAdmin {
        _pricePerAllocation = price;
    }

    function setCanReserve(bool can) external onlyAdmin {
        _canReserve = can;
    }

    function reserve(uint amount) external payable {
        require(address(_nft) != address(0), "NGReservations::reserve: NFT address not set.");
        require(_canReserve, "NGReservations::reserve: Reservations currently closed.");
        require(_allocations[msg.sender] > 0, "NGReservations::reserve: You have no allocation.");
        uint available = _allocations[msg.sender] - _reservations[msg.sender];
        require(available > 0, "NGReservations::reserve: You have already reserved your entire allocation.");
        require(amount <= available, "NGReservations::reserve: You cannot mint more then your allocation.");
        require(msg.value >= amount*_pricePerAllocation, "NGReservations::reserve: Insufficient funds sent for allocation");

        _reservations[msg.sender] += amount;
        _nft.freeMint(msg.sender, amount);
    }

    function getAllAllocated() external view onlyAdmin returns (address[] memory) {
        return _allAllocated;
    }

    receive() external payable {}

    function withdrawErc(address token, address recipient, uint256 amount) external onlyAdmin {
        TransferHelper.safeApprove(token, recipient, amount);
        TransferHelper.safeTransfer(token, recipient, amount);
    }

    function withdrawETH(address recipient, uint256 amount) external onlyAdmin {
        TransferHelper.safeTransferETH(recipient, amount);
    }

    function setNFT(address nft_) external onlyAdmin {
        _nft = INGNFT(nft_);
    }
}

interface INGNFT {
    function freeMint(address to, uint amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}