// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Coupon.sol";

contract Market {
    uint256 public volume; // total volume of coupons

    mapping(uint256 => address) coupons; // store coupon IDs --> coupon addresses

    event CreateCoupon(uint256 id, address new_address);

    // Constructor
    constructor() {
        volume = 0;
    }

    // Get Available ID
    function getNextID() internal returns (uint256) {
        volume = volume + 1; // Increment total volume
        return volume;
    }

    function createCoupon(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _value
    ) public returns (uint256) {
        uint256 _couponID = getNextID();
        Coupon couponInstance = new Coupon(
            _couponID,
            _startTime,
            _endTime,
            _value
        );
        coupons[_couponID] = address(couponInstance);
        emit CreateCoupon(_couponID, address(couponInstance));
        return _couponID;
    }

    // Return coupon address
    function getCouponAddrByID(uint256 couponID) public view returns (address) {
        return coupons[couponID];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Coupon {
    uint256 public ID;
    address public issuer;
    address public owner;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public value;

    event ChangeOwnerToEvent(address new_owner);

    constructor(
        uint256 id,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _value
    ) {
        require(_endTime >= _startTime);

        ID = id;
        issuer = msg.sender;
        owner = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
        value = _value;
    }

    modifier isValidRedeemTime() {
        require(startTime <= block.timestamp);
        require(endTime >= block.timestamp);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function transfer(address receiver) public onlyOwner {
        owner = receiver;
        emit ChangeOwnerToEvent(receiver);
    }

    function redeem() public onlyOwner isValidRedeemTime {
        transfer(issuer);
    }
}