/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: IERC20

interface IERC20 {
    // function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: Subscription.sol

contract SubscriptionPayment {
    constructor() {
        admin = msg.sender;
    }

    struct Subscription {
        string name;
        address token_address;
        uint256 amount;
        uint256 duration;
        address deposit_address;
    }
    modifier Onlyowner() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }
    address public admin;
    uint256 private subscription_count;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => mapping(uint256 => uint256)) public subscribers_details;

    function subscribe(uint256 _subscription_id) public payable returns (bool) {
        IERC20 token = IERC20(subscriptions[_subscription_id].token_address);
        require(
            token.approve(
                subscriptions[_subscription_id].deposit_address,
                subscriptions[_subscription_id].amount
            )
        );
        require(
            token.transferFrom(
                msg.sender,
                subscriptions[_subscription_id].deposit_address,
                subscriptions[_subscription_id].amount
            ),
            "Unable to charge User"
        );
        if (
            subscribers_details[msg.sender][_subscription_id] > block.timestamp
        ) {
            subscribers_details[msg.sender][_subscription_id] += subscriptions[
                _subscription_id
            ].duration;
        } else {
            subscribers_details[msg.sender][_subscription_id] =
                subscriptions[_subscription_id].duration +
                block.timestamp;
        }
        return true;
    }

    function createSubscription(
        string memory _name,
        address _token_address,
        uint256 _amount,
        uint256 _duration,
        address _deposit_address
    ) public Onlyowner returns (uint256) {
        subscriptions[subscription_count] = Subscription(
            _name,
            _token_address,
            _amount,
            _duration,
            _deposit_address
        );
        subscription_count++;
        return subscription_count;
    }

    function changeAdmin(address _new_owner) public Onlyowner returns (bool) {
        admin = _new_owner;
        return true;
    }

    function deleteSubscription(uint256 _subscription_id)
        public
        Onlyowner
        returns (bool)
    {
        subscriptions[_subscription_id] = Subscription(
            "",
            address(0),
            0,
            0,
            address(0)
        );
        return true;
    }
}