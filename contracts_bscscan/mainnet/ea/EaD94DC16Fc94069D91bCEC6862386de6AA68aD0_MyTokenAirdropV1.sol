/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// MyTokenAirdrop: reward store on the contract
contract MyTokenAirdropV1 {
    IERC20 public immutable MyToken;
    bool public paused;
    uint256 public reveiveBlockNum;
    address payable public owner;
    mapping(address => uint256) public rewards;

    event OwnershipTransferred(address indexed _old, address indexed _new);
    event Claim(address indexed _user, uint256 indexed _amount);
    event Pause();
    event Unpause();

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "only not pause");
        _;
    }

    modifier whenPaused() {
        require(paused, "only pause");
        _;
    }

    constructor(IERC20 _token, uint256 _reveiveBlockNum) public {
        owner = msg.sender;
        MyToken = _token;
        reveiveBlockNum = _reveiveBlockNum;
        paused = false;
        emit OwnershipTransferred(address(0), owner);
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }

    struct RewardInfo {
        address user;
        uint256 amount; // 0: no reward, others: reward amount
    }

    function setRewards(RewardInfo[] memory _infos)
        public
        onlyOwner
        whenNotPaused
    {
        for (uint256 i = 0; i < _infos.length; i++) {
            rewards[_infos[i].user] =
                rewards[_infos[i].user] +
                _infos[i].amount;
        }
    }

    function clearUsers(address[] memory _users) public onlyOwner whenPaused {
        for (uint256 i = 0; i < _users.length; i++) {
            rewards[_users[i]] = 0;
        }
    }

    function updateReveiveBlock(uint256 _blockNum) public onlyOwner whenPaused {
        reveiveBlockNum = _blockNum;
    }

    function claim() public whenNotPaused returns (bool) {
        uint256 amount = rewards[msg.sender];
        require(amount > 1, "invalid amount");
        require(block.number >= reveiveBlockNum, "not yed");
        uint256 balance = MyToken.balanceOf(address(this));
        require(balance >= amount, "not enough balance");
        MyToken.approve(address(this), balance);
        rewards[msg.sender] = 0;
        assert(MyToken.transferFrom(address(this), msg.sender, amount));
        emit Claim(msg.sender, amount);
        return true;
    }

    function recoverTokens() external onlyOwner whenPaused {
        uint256 unreachableAmount = MyToken.balanceOf(address(this));
        MyToken.approve(address(this), unreachableAmount);
        MyToken.transferFrom(address(this), owner, unreachableAmount);
        emit Claim(owner, unreachableAmount);
    }

    function recoverBNB() external onlyOwner whenPaused {
        payable(owner).transfer(address(this).balance);
    }
}