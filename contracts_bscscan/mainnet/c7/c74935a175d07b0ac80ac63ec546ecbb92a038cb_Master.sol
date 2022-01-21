// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./IRouter.sol";
import "./ReentrancyGuard.sol";

contract Master is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct UserGlobal {
        uint256 id;
        address owner;
        address inviter;
        address[] inviteList;
        bool invested;
        uint256 pendingInviteReward; // pending invite reward
        uint256 totalInviteReward; // total invite reward
        uint256 performance;
    }
    mapping (address => UserGlobal) public userInfo;
    uint256 public globalUserId = 1;

    address public usdt;
    address public mot;
    address public eco;

    bool public idoEnable;
    uint256 public salePrice = 650; //  * 1000, 1 mot = salePrice/1000 usdt

    constructor (address _usdt, address _mot) {
        usdt = _usdt;
        mot = _mot;

        eco = msg.sender;
    }

    function submitInviter(address owner, address inviter) public {
        require(owner == msg.sender, "not owner");
        // register user
        UserGlobal storage userGlobal = userInfo[owner];
        if (userGlobal.id == 0) {
            registerUser(owner, inviter);
        }
    }

    function registerUser(address owner, address inviter) internal {
        require(owner != inviter, "can't invite yourself");
        require(inviter != address(0), "zero address");
        if(globalUserId > 1) {
            require(userInfo[inviter].invested, "invaild inviter, inviter has not invested");
        }

        UserGlobal storage userGlobal = userInfo[owner];
        userGlobal.id = globalUserId;
        userGlobal.owner = owner;
        userGlobal.inviter = inviter;

        UserGlobal storage userInviter = userInfo[inviter];
        userInviter.inviteList.push(owner);

        // globalId add 1
        globalUserId = globalUserId.add(1);
    }

    function buy(uint256 usdtAmount, address inviter) public {
        require(idoEnable, "ido not start");

        address sender = msg.sender;
        // register user
        UserGlobal storage user = userInfo[sender];
        if (user.id == 0) { // register user
            if (globalUserId > 1) {
                require(userInfo[inviter].invested, "inviter not invested");
            }
            registerUser(sender, inviter);
        }
        user.invested = true;

        uint256 motAmount = usdtAmount.mul(1000).div(salePrice);
        // transfer usdt to contract
        TransferHelper.safeTransferFrom(usdt, sender, address(this), usdtAmount);
        // transfer mot to user
        TransferHelper.safeTransfer(mot, sender, motAmount);

        // reward inviter layer 1
        address referLayer1 = getInviter(sender);
        updateInviteReward(referLayer1, motAmount.mul(5).div(100), usdtAmount); // 5%

        // reward inviter layer 2
        address referLayer2 = getInviter(referLayer1);
        updateInviteReward(referLayer2, motAmount.mul(1).div(100), usdtAmount); // 1 %
    }

    function updateInviteReward(address inviter, uint256 motAmount, uint256 usdtAmount) internal {
        if (inviter != address(0)) {
            UserGlobal storage user = userInfo[inviter];
            // invite reward
            user.pendingInviteReward = user.pendingInviteReward.add(motAmount);
            user.totalInviteReward = user.totalInviteReward.add(motAmount);
            // performance
            user.performance = user.performance.add(usdtAmount);
        }
    }

    function withdrawInviteReward() public {
        UserGlobal storage user = userInfo[msg.sender];
        require(user.pendingInviteReward > 0, "no pending reward");

        TransferHelper.safeTransfer(mot, msg.sender, user.pendingInviteReward);
        user.pendingInviteReward = 0;
    }

    function getInviter(address owner) public view returns (address) {
        return userInfo[owner].inviter;
    }

    function getInviteList(address owner) public view returns (address[] memory) {
        return userInfo[owner].inviteList;
    }

    function queryInviteReward(address owner) public view returns (uint256 pending, uint256 total, uint256 performance) {
        pending = userInfo[owner].pendingInviteReward;
        total = userInfo[owner].totalInviteReward;
        performance = userInfo[owner].performance;
    }

    // owner operations
    function setEco(address _eco) public onlyOwner {
        eco = _eco;
    }

    function setUsdt(address _usdt) public onlyOwner {
        usdt = _usdt;
    }

    function setMot(address _mot) public onlyOwner {
        mot = _mot;
    }

    function setSalePrice(uint256 _price) public onlyOwner {
        salePrice = _price;
    }

    function setIdoEnable(bool flag) public onlyOwner {
        idoEnable = flag;
    }

    function withdrawMot(uint256 amount) public onlyOwner {
        TransferHelper.safeTransfer(mot, eco, amount);
    }

    function withdrawUsdt(uint256 amount) public onlyOwner {
        TransferHelper.safeTransfer(usdt, eco, amount);
    }
}