// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./Context.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./ITokenManager.sol";
import "./ReentrancyGuard.sol";

contract INFBundleERC20 is Ownable, ERC20, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public TOTAL_SUPPLY = 1000 * (10 ** 6) * (10 ** 18);
    uint256 public PLAY_TO_EARN_AMOUNT = 330 * (10 ** 6) * (10 ** 18);
    uint256 public TOTAL_FARM_AMOUNT = 100 * (10 ** 6) * (10 ** 18);

    uint256 public currentPlayToEarnAmount;
    uint256 public currentFarmAmount;

    uint256 public transferFeeRate = 0;
    address public feeAddress;

    ITokenManager public manager;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(_msgSender(), TOTAL_SUPPLY.sub(TOTAL_FARM_AMOUNT).sub(PLAY_TO_EARN_AMOUNT));
    }

    modifier onlyBattlePlace() {
        require(manager.isBattlePlace(_msgSender()), "require BattlePlace");
        _;
    }

    modifier onlyFarmer() {
        require(manager.isFarmer(_msgSender()), "require Farmer");
        _;
    }

    function setTokenManager(address _manager) external onlyOwner {
        manager = ITokenManager(_manager);
    }

    function earnToken(address winner, uint256 reward) external onlyBattlePlace {
        require(currentPlayToEarnAmount < PLAY_TO_EARN_AMOUNT, "play to earn over cap");
        require(winner != address(0), "0x address is not accepted");
        require(reward > 0, "reward must greater than 0");

        if (currentPlayToEarnAmount.add(reward) <= PLAY_TO_EARN_AMOUNT) {
            _mint(winner, reward);
            currentPlayToEarnAmount = currentPlayToEarnAmount.add(reward);
        } else {
            uint256 availableReward = PLAY_TO_EARN_AMOUNT.sub(currentPlayToEarnAmount);
            _mint(winner, availableReward);
            currentPlayToEarnAmount = PLAY_TO_EARN_AMOUNT;
        }
    }

    function farmToken(address farmer, uint256 amount) external onlyFarmer {
        require(currentFarmAmount < TOTAL_FARM_AMOUNT, "farm amount over cap");
        require(farmer != address(0), "0x address is not accepted");
        require(amount > 0, "amount must greater than 0");

        if (currentFarmAmount.add(amount) <= TOTAL_FARM_AMOUNT) {
            _mint(farmer, amount);
            currentFarmAmount = currentFarmAmount.add(amount);
        } else {
            uint256 availableFarm = TOTAL_FARM_AMOUNT.sub(currentFarmAmount);
            _mint(farmer, availableFarm);
            currentFarmAmount = TOTAL_FARM_AMOUNT;
        }
    }

    function setFeeRate(uint256 _feeRate) public onlyOwner {
        transferFeeRate = _feeRate;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (
            transferFeeRate > 0 &&
            recipient != address(0) &&
            feeAddress != address(0)
        ) {
            uint256 _fee = amount.div(100).mul(transferFeeRate);
            super._transfer(sender, feeAddress, _fee);
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }
}