/**
 *Submitted for verification at arbiscan.io on 2021-10-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

contract Distributor {
    struct Allocation {
        address recipient;
        uint96 share;
    }

    address public boss;
    uint256 public allocationCount;
    Allocation[] public allocations;

    event SetAllocationFor(address indexed recipient, uint96 share);
    event DistributeTo(address indexed recipient, uint256 amount);

    constructor() {
        boss = msg.sender;
    }

    modifier onlyBoss() {
        require(boss == msg.sender, "ops! only boss can call this");
        _;
    }

    function listDistributions()
        external
        view
        returns (address[] memory recipientList, uint96[] memory shareList)
    {
        recipientList = new address[](allocationCount);
        shareList = new uint96[](allocationCount);
        for (uint256 i = 0; i < allocationCount; i++) {
            recipientList[i] = allocations[i].recipient;
            shareList[i] = allocations[i].share;
        }
    }

    function setAllocations(bytes32[] calldata entries) external onlyBoss {
        uint256 count = entries.length;
        require(count > 0, "Distributor::setAllocations::NoAlocationGiven");
        for (uint256 i = 0; i < count; i++) {
            (address recipient, uint96 share) = _decode(entries[i]);
            if (i < allocations.length) {
                allocations[i] = Allocation({
                    recipient: recipient,
                    share: share
                });
            } else {
                allocations.push(
                    Allocation({recipient: recipient, share: share})
                );
            }
            emit SetAllocationFor(recipient, share);
        }
        allocationCount = count;
    }

    function distribute(address token, uint256 totalAmount) external {
        require(totalAmount > 0, "Distributor::setAllocations::ZeroAmount");
        require(
            allocationCount > 0,
            "Distributor::setAllocations::NoAllocationSet"
        );

        IERC20 erc20 = IERC20(token);
        erc20.transferFrom(msg.sender, address(this), totalAmount);
        for (uint256 i = 0; i < allocationCount; i++) {
            address recipient = allocations[i].recipient;
            uint256 share = uint256(allocations[i].share);
            uint256 amount = (totalAmount * share) / 100_00000;
            if (amount == 0) {
                continue;
            }
            erc20.transfer(recipient, amount);
            emit DistributeTo(recipient, amount);
        }
        // refund to sender
        erc20.transfer(msg.sender, erc20.balanceOf(address(this)));
    }

    function decode(bytes32 entry) public pure returns (address, uint96) {
        return _decode(entry);
    }

    function encode(address recipient, uint96 share)
        public
        pure
        returns (bytes32 entry)
    {
        entry = bytes32((uint256(uint160(recipient)) << 96) | uint256(share));
    }

    // entry = |--- 160 bit address ---|--- 96 bit share ---|
    function _decode(bytes32 entry)
        internal
        pure
        returns (address recipient, uint96 share)
    {
        recipient = address(uint160(bytes20(entry)));
        share = uint96(uint256(entry));
    }
}