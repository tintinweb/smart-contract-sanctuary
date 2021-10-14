// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ManagerInterface.sol";

contract PluvialERC20 is Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 public amountPlayToEarn = 280 * 10**6 * 10**18;
    uint256 public playToEarnReward;
    uint256 internal amountFarm = 150 * 10**6 * 10**18;
    uint256 private farmReward;

    ManagerInterface public manager;

    uint256 public tokenForBosses = 2 * 10**6 * 10**18;

    address public addressForBosses;
    uint256 public sellFeeRate = 5;
    uint256 public buyFeeRate = 2;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        addressForBosses = _msgSender();
    }

    modifier onlyFarmOwners() {
        require(manager.farmOwners(_msgSender()), "caller is not the farmer");
        _;
    }

    modifier onlyEvolver() {
        require(manager.evolvers(_msgSender()), "caller is not the evolver");
        _;
    }

    function setManager(address _manager) public onlyOwner {
        manager = ManagerInterface(_manager);
    }

    function setTransferFeeRate(uint256 _sellFeeRate, uint256 _buyFeeRate)
        public
        onlyOwner
    {
        sellFeeRate = _sellFeeRate;
        buyFeeRate = _buyFeeRate;
    }

    function setMinTokensBeforeSwap(uint256 _tokenForBosses)
        public
        onlyOwner
    {
        require(_tokenForBosses < 20 * 10**6 * 10**18);
        tokenForBosses = _tokenForBosses;
    }

    function farm(address recipient, uint256 amount) external onlyFarmOwners {
        require(amountFarm != farmReward, "Over cap farm");
        require(recipient != address(0), "0x is not accepted here");
        require(amount > 0, "not accept 0 value");

        farmReward = farmReward.add(amount);
        if (farmReward <= amountFarm) _mint(recipient, amount);
        else {
            uint256 availableReward = farmReward.sub(amountFarm);
            _mint(recipient, availableReward);
            farmReward = amountFarm;
        }
    }

    function win(address winner, uint256 reward) external onlyEvolver {
        require(playToEarnReward != amountPlayToEarn, "Over cap farm");
        require(winner != address(0), "0x is not accepted here");
        require(reward > 0, "not accept 0 value");

        playToEarnReward = playToEarnReward.add(reward);
        if (playToEarnReward <= amountPlayToEarn) _mint(winner, reward);
        else {
            uint256 availableReward = playToEarnReward.sub(amountPlayToEarn);
            _mint(winner, availableReward);
            playToEarnReward = amountPlayToEarn;
        }
    }
}