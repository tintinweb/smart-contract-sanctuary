/**
 *Submitted for verification at BscScan.com on 2022-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 amount) external returns (bool);
}

contract TokenClaim {

    address public tokenAddress;
    IERC20 public ERC20Interface;

    struct Vesting {
        uint256 totalAmount;
        uint256 startAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 claimed;
    }

    mapping(address => Vesting) public userVesting;

    constructor(address _token) {
        require(_token != address(0), "Zero token address");
        tokenAddress = _token;
        ERC20Interface = IERC20(tokenAddress);
    }

    function addUserVesting(
        address _user,
        uint256 _amount,
        uint256 _startAmount,
        uint256 _startTime,
        uint256 _endTime
    ) internal returns (bool) {
        require(_amount > 0, "Zero amount");
        uint256 _claimed = userVesting[_user].claimed;
        userVesting[_user] = Vesting(
            _amount,
            _startAmount,
            _startTime,
            _endTime,
            _claimed
        );
        return true;
    }

    function massUpdate(
        address[] calldata _user,
        uint256[] calldata _amount,
        uint256[] calldata _startAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalTokens
    ) external returns (bool) {
        uint256 length = _user.length;
        require(
            length == _amount.length && length == _startAmount.length,
            "Wrong data"
        );

        uint256 total;
        for (uint256 i = 0; i < length; i++) {
            total = total + _amount[i];
        }

        require(total == _totalTokens, "Token amount mismatch");

        ERC20Interface.transferFrom(
            msg.sender,
            address(this),
            _totalTokens
        );

        for (uint256 j = 0; j < length; j++) {
            bool success = addUserVesting(
                _user[j],
                _amount[j],
                _startAmount[j],
                _startTime,
                _endTime
            );
            require(success, "User vesting updation failed");
        }

        return true;
    }

    function claim() external returns (bool) {
        uint256 tokens = getClaimableAmount(msg.sender);
        require(tokens > 0, "No claimable tokens available");
        userVesting[msg.sender].claimed =
            userVesting[msg.sender].claimed +
            tokens;
        ERC20Interface.transfer(msg.sender, tokens);
        return true;
    }

    function getClaimableAmount(address _user)
        public
        view
        returns (uint256 claimableAmount)
    {
        Vesting storage _vesting = userVesting[_user];
        require(_vesting.totalAmount > 0, "No vesting available for user");
        if (_vesting.totalAmount == _vesting.claimed) return 0;
        if (_vesting.startTime > block.timestamp) return 0;
        if (block.timestamp < _vesting.endTime) {
            uint256 timePassedRatio = ((block.timestamp - _vesting.startTime) *
                10**18) / (_vesting.endTime - _vesting.endTime);

            claimableAmount =
                (((_vesting.totalAmount - _vesting.startAmount) *
                    timePassedRatio) / 10**18) +
                _vesting.startAmount;
        } else {
            claimableAmount = _vesting.totalAmount;
        }
        claimableAmount = claimableAmount - _vesting.claimed;
    }
}