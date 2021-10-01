pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract lpStaking is Ownable {
using SafeMath for uint256;
    IERC20 rpg;
    IERC20 rpgLp;
    uint256 public tokenPerBlock;
    uint256 public commonLp;
    uint256 public commonAmount;
    uint256 public commonLength;
    uint256 public startBlock;
    uint256 public lastCalcBlock;
    uint256 public deactivationTime;
    bool public isFarmActive;
    mapping(uint8 => uint256) public tiers;
    mapping(address => bool) managers;
    mapping(address => user) public Users;

    struct Rank {
        address player;
        uint8 rank;
    }

    struct user {
        userFunds prev;
        userFunds curr;
        uint256 unclaimed;
        uint256 multiplier;
    }

    struct userFunds {
        uint256 startBlock;
        uint256 amount;
    }

    modifier onlyManager() {
        require(managers[_msgSender()], "Staking: onlyManager");
        _;
    }

    modifier onlyIsFarmActive() {
        require(isFarmActive, "Staking: Farm is not active");
        _;
    }

    event LogUserRank(address user, uint8 rank);
    event Claim(address user, uint256 amount);
    event Deposit(address user, uint256 bonus);
    event Withdraw(address user, uint256 lpAmount, uint256 bonus);
    event EmergencyWithdraw(address user, uint256 lpAmount);

    constructor(
        uint256 _tokenPerBlock,
        address _rpg,
        address _rpgLp
    ) {
        rpg = IERC20(_rpg);
        rpgLp = IERC20(_rpgLp);
        tokenPerBlock = _tokenPerBlock;
        managers[msg.sender] = true;
        isFarmActive = false;
        tiers[1] = 100;
        tiers[2] = 150;
        tiers[3] = 175;
        tiers[4] = 200;
    }

    function addManager(address _manager) external onlyOwner {
        require(!managers[_manager], "This address is already a manager");
        managers[_manager] = true;
    }

    function removeManager(address _manager) external onlyOwner {
        require(managers[_manager], "This address is not a manager");
        managers[_manager] = false;
    }

    function changeTokenPerBlock(uint256 _newAmountWei) external onlyOwner {
        require(_newAmountWei < 1*1e18, "Amount is too big");
        require(_newAmountWei >= 1e9, "Amount is too low");
        tokenPerBlock = _newAmountWei;
    }

    function deactivateFarm() external onlyOwner {
        require(isFarmActive,"Farm is already deactivated");
        isFarmActive = false;
        deactivationTime = block.number;
    }

    function reactivateFarm() external onlyOwner {
        require(!isFarmActive,"Farm is active");
        isFarmActive = true;
        startBlock = block.number - 1;
        lastCalcBlock = block.number - 1;
        commonLength = 1;
        commonAmount = tokenPerBlock;
    }

    function initFarm() external onlyOwner {
        require(!isFarmActive,"Farm is active");
        isFarmActive = true;
    }

    function deposit(uint256 _amount) external onlyIsFarmActive {
        require(_amount > 0, "Zero amount is not allowed");
        address sender = _msgSender();
        if (commonLp == 0) {
            startBlock = block.number - 1;
            lastCalcBlock = block.number - 1;
            commonLength = 1;
            commonAmount = tokenPerBlock;
        }
        if (Users[sender].multiplier == 0) {
            Users[sender].multiplier = tiers[4];
        }
        rpgLp.transferFrom(sender, address(this), _amount);
        commonLp += _amount;
        if (Users[sender].curr.amount > 0) {
            claim();
        }
        Users[sender].curr.amount += _amount;
        Users[sender].curr.startBlock = block.number;
        emit Deposit(sender, _amount);
    }

    function withdraw() external {
        address sender = _msgSender();
        require(Users[sender].multiplier != 0, "User is not exist");
        uint256 bonus;
        uint256 amount;
        if (Users[sender].unclaimed > 0) {
            bonus += Users[sender].unclaimed;
            Users[sender].unclaimed = 0;
        }
        if (Users[sender].curr.amount > 0) {
            bonus += userCalc(Users[sender].curr).mul(100).div(tiers[4]);
            amount += Users[sender].curr.amount;
            Users[sender].curr.amount = 0;
        }
        if (Users[sender].prev.amount > 0) {
            bonus += userCalc(Users[sender].prev).mul(100).div(
                Users[sender].multiplier
            );
            amount += Users[sender].prev.amount;
            Users[sender].prev.amount = 0;
        }
        Users[sender].curr.startBlock = block.number;
        Users[sender].prev.startBlock = block.number;
        if (bonus >= commonAmount) {
            bonus = commonAmount;
            commonAmount = 0;
        } else {
            commonAmount -= bonus;
        }
        require(amount > 0, "Nothing to withdraw");
        if (bonus > 0) {
            rpg.transfer(sender, bonus);
        }
        rpgLp.transfer(sender, amount);
        commonLp -= amount;
        emit Withdraw(sender, amount, bonus);
    }

    function processRankingUpdate(bytes calldata data)
        external
        onlyManager
        onlyIsFarmActive
    {
        Rank[] memory temp;
        temp = abi.decode(data, (Rank[]));

        uint256 length = temp.length;
        for (uint256 i = 0; i < length; i++) {
            Rank memory object = temp[i];
            uint256 r;
            address p = object.player;
            if (object.rank > 4) {
                r = tiers[4];
            } else if (object.rank < 1) {
                r = tiers[1];
            } else {
                r = tiers[object.rank];
            }
            uint256 bonus;
            if (Users[p].prev.amount > 0) {
                bonus += userCalc(Users[p].prev).mul(100).div(
                    Users[p].multiplier
                );
            }
            if (Users[p].curr.amount > 0) {
                bonus += userCalc(Users[p].curr).mul(100).div(tiers[4]);
                Users[p].prev.amount += Users[p].curr.amount;
                Users[p].curr.amount = 0;
            }
            Users[p].prev.startBlock = block.number;
            Users[p].curr.startBlock = block.number;
            Users[p].unclaimed += bonus;
            Users[p].multiplier = r;
            emit LogUserRank(p, object.rank);
        }
    }

    function getUserInfo(address _user) external view returns (uint256) {
        require(Users[_user].multiplier != 0, "User is not exist");
        uint256 bonus;
        uint256 mult = Users[_user].multiplier;
        bonus += _viewCalcUser(Users[_user].prev).mul(100).div(mult);
        bonus += _viewCalcUser(Users[_user].curr).mul(100).div(tiers[4]);
        bonus += Users[_user].unclaimed;
        return bonus;
    }

    function emergencyWithdraw() external {
        address sender = _msgSender();
        uint256 amount;
        if (Users[sender].curr.amount > 0) {
            amount += Users[sender].curr.amount;
            Users[sender].curr.amount = 0;
        }
        if (Users[sender].prev.amount > 0) {
            amount += Users[sender].prev.amount;
            Users[sender].prev.amount = 0;
        }
        Users[sender].unclaimed = 0;
        Users[sender].curr.startBlock = block.number;
        Users[sender].prev.startBlock = block.number;
        require(amount > 0, "Nothing to withdraw");
        rpgLp.transfer(sender, amount);
        commonLp -= amount;
        emit EmergencyWithdraw(sender, amount);
    }

    function removeLiquidity() external onlyOwner {
        require(!isFarmActive, "Staking: Farm is still active");
        uint256 balance = rpg.balanceOf(address(this));
        rpg.transfer(_msgSender(), balance);
    }

    function claim() public onlyIsFarmActive {
        address sender = _msgSender();
        require(Users[sender].multiplier != 0, "User is not exist");
        uint256 bonus;
        if (Users[sender].unclaimed > 0) {
            bonus += Users[sender].unclaimed;
            Users[sender].unclaimed = 0;
        }
        if (Users[sender].curr.amount > 0) {
            bonus += userCalc(Users[sender].curr).mul(100).div(tiers[4]);
        }
        if (Users[sender].prev.amount > 0) {
            bonus += userCalc(Users[sender].prev).mul(100).div(
                Users[sender].multiplier
            );
        }
        Users[sender].curr.startBlock = block.number;
        Users[sender].prev.startBlock = block.number;
        if (bonus >= commonAmount) {
            bonus = commonAmount;
            commonAmount = 0;
        } else {
            commonAmount -= bonus;
        }
        require(bonus > 0, "Nothing to claim");
        rpg.transfer(sender, bonus);
        emit Claim(sender, bonus);
    }

    function _viewCalcUser(userFunds memory _userFund)
        internal
        view
        returns (uint256)
    {
        uint256 currentBlock = isFarmActive ? block.number : deactivationTime;
        uint256 commonLengthR = commonLength + currentBlock.sub(lastCalcBlock);
        uint256 commonAmountR = commonAmount +
            (currentBlock.sub(lastCalcBlock)).mul(tokenPerBlock);
        uint256 bonus = commonAmountR
            .mul(currentBlock.sub(_userFund.startBlock))
            .mul(_userFund.amount)
            .div(commonLp.mul(commonLengthR));
        return bonus;
    }

    function userCalc(userFunds memory _userFund) internal returns (uint256) {
        uint256 currentBlock = isFarmActive ? block.number : deactivationTime;
        commonLength += currentBlock.sub(lastCalcBlock);
        commonAmount += (currentBlock.sub(lastCalcBlock)).mul(tokenPerBlock);
        lastCalcBlock = currentBlock;
        uint256 bonus = commonAmount
            .mul(currentBlock.sub(_userFund.startBlock))
            .mul(_userFund.amount)
            .div(commonLp.mul(commonLength));
        return bonus;
    }
}