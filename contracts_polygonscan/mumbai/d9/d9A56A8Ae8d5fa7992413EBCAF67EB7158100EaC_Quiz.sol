/**
 *Submitted for verification at polygonscan.com on 2021-10-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Quiz {
    IERC20 public ERC20Interface;
    address public owner;

    struct Answers {
        uint256 questionId;
        string option;
    }

    struct UserDetails {
        address user;
        Answers[] answers;
        uint256 percentage;
        uint256 reward;
        string participationID;
    }

    constructor(address _tokenAddress, address _owner) {
        owner = _owner;
        ERC20Interface = IERC20(_tokenAddress);
    }

    mapping(string => UserDetails[]) private userDetails;

    function updateOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function submitContestDetails(
        UserDetails[] calldata _userDetails,
        string memory _contestID
    ) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _userDetails.length; i++) {
            userDetails[_contestID].push(_userDetails[i]);
        }
        return true;
    }

    function returnContestData(string memory _contestID)
        external
        view
        returns (UserDetails[] memory)
    {
        return userDetails[_contestID];
    }

    function distribute(
        address[] memory users,
        uint256[] memory rewards,
        uint256 totalReward
    ) external onlyOwner returns (bool) {
        require(users.length == rewards.length, "Incorrect data");
        uint256 reward = totalReward;
        for (uint256 i = 0; i < users.length; i++) {
            require(
                ERC20Interface.allowance(msg.sender, address(this)) >=
                    totalReward,
                "Not enough allowance"
            );
            reward = reward - rewards[i];
            require(
                ERC20Interface.transferFrom(msg.sender, users[i], rewards[i]),
                "Payment failed"
            );
        }

        require(reward == 0, "Incorrect rewards");

        return true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
}