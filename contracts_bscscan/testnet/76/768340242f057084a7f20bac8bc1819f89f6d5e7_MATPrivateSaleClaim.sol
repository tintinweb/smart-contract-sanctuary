// SPDX-License-Identifier: MIT
/*
6 triệu token, TGE unlock 20%, 80% trả dần trong 6 tháng
min 5k$ max 20k$ ....Giá 0.05$
*/
pragma solidity 0.8.6;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";

contract MATPrivateSaleClaim is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    IBEP20 public MAT;

    uint256 public TGE_RELEASE = 15;
    uint256 public TGE_CLIFF = 86400 * 30 * 2; //2 months
    // uint256 public TGE_CLIFF = 600; //10 mins for testing
    uint256 public VESTING_DURATION = 86400 * 30 * 15; //15 months
    // uint256 public VESTING_DURATION = 3600; //1 hour for testing
    uint256 public MAT_PRICE = 10; //0.1 - 2 decimal

    uint256 public startTime;
    uint256 public endTime;

    // address coldWallet;
    uint8 public stage;

    address[] private whilelists;
    mapping(address => uint256) private locks; // MAT
    mapping(address => uint256) private released; // MAT

    event Claim(address indexed account, uint256 amount, uint256 time);

    // _mat = 0x73e9f666ca55cdc89a9dd734c7f31f3fbc8bc197
    constructor(IBEP20 _mat) {
        MAT = IBEP20(_mat);
        stage = 0;
    }

    modifier canClaim() {
        require(stage == 1, "Can not claim now");
        _;
    }

    modifier canSetup() {
        require(stage == 0, "Can not setup now");
        _;
    }

    function setTgeTime(uint256 _tge) public canSetup onlyOwner {
        startTime = _tge + TGE_CLIFF;
        endTime = startTime + VESTING_DURATION;

        stage = 1;

        //transfer 15% for whilelists;
        for (uint256 i = 0; i < whilelists.length; i++) {
            uint256 matAmount = (locks[whilelists[i]] * TGE_RELEASE) / 100;
            locks[whilelists[i]] -= matAmount;
            MAT.transfer(whilelists[i], matAmount);
        }
    }

    function setWhilelist(address[] calldata _users, uint256[] calldata _busds)
        public
        canSetup
        onlyOwner
    {
        require(_users.length == _busds.length, "Invalid input");
        for (uint256 i = 0; i < _users.length; i++) {
            //calculate
            uint256 matAmount = (_busds[i] * 100) / MAT_PRICE;
            // boughts[_users[i]] += _busds[i];
            locks[_users[i]] += matAmount;
            whilelists.push(_users[i]);
        }
    }

    function claim() external canClaim nonReentrant {
        require(block.timestamp > startTime, "still locked");
        require(locks[_msgSender()] > released[_msgSender()], "no locked");

        uint256 amount = canUnlockAmount(_msgSender());
        require(amount > 0, "Nothing to claim");

        released[_msgSender()] += amount;

        MAT.transfer(_msgSender(), amount);

        emit Claim(_msgSender(), amount, block.timestamp);
    }

    function canUnlockAmount(address _account) public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        } else if (block.timestamp >= endTime) {
            return locks[_account] - released[_account];
        } else {
            uint256 releasedTime = releasedTimes();
            uint256 totalVestingTime = endTime - startTime;
            return
                (((locks[_account]) * releasedTime) / totalVestingTime) -
                released[_account];
        }
    }

    function releasedTimes() public view returns (uint256) {
        uint256 targetNow = (block.timestamp >= endTime)
            ? endTime
            : block.timestamp;
        uint256 releasedTime = targetNow - startTime;
        return releasedTime;
    }

    function info()
        external
        view
        returns (
            uint8,
            uint256,
            uint256
        )
    {
        return (stage, startTime, endTime);
    }

    //For FE
    function infoWallet(address _user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (stage == 0) return (locks[_user], released[_user], 0);
        return (locks[_user], released[_user], canUnlockAmount(_user));
    }

    /* ========== EMERGENCY ========== */
    function governanceRecoverUnsupported(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_token != address(MAT), "Token invalid");
        IBEP20(_token).transfer(_to, _amount);
    }
}