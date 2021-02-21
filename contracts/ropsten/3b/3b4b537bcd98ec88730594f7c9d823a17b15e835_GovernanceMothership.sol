// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";
import "./IGovernanceModule.sol";
import "./BalanceAccounting.sol";


contract GovernanceMothership is Ownable, BalanceAccounting {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);

    IERC20 public immutable RIEToken;

    EnumerableSet.AddressSet private _modules;

    constructor(IERC20 _RIEToken) {
        RIEToken = _RIEToken;
    }

    function name() external pure returns(string memory) {
        return "RIE Token (Staked)";
    }

    function symbol() external pure returns(string memory) {
        return "stRIE";
    }

    function decimals() external pure returns(uint8) {
        return 18;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Empty stake is not allowed");

        RIEToken.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        _notifyFor(msg.sender, balanceOf(msg.sender));
        emit Transfer(address(0), msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Empty unstake is not allowed");

        _burn(msg.sender, amount);
        _notifyFor(msg.sender, balanceOf(msg.sender));
        RIEToken.transfer(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function notify() external {
        _notifyFor(msg.sender, balanceOf(msg.sender));
    }

    function notifyFor(address account) external {
        _notifyFor(account, balanceOf(account));
    }

    function batchNotifyFor(address[] memory accounts) external {
        uint256 modulesLength = _modules.length();
        uint256[] memory balances = new uint256[](accounts.length);
        for (uint256 j = 0; j < accounts.length; ++j) {
            balances[j] = balanceOf(accounts[j]);
        }
        for (uint256 i = 0; i < modulesLength; ++i) {
            IGovernanceModule(_modules.at(i)).notifyStakesChanged(accounts, balances);
        }
    }

    function addModule(address module) external onlyOwner {
        require(_modules.add(module), "Module already registered");
        emit AddModule(module);
    }

    function removeModule(address module) external onlyOwner {
        require(_modules.remove(module), "Module was not registered");
        emit RemoveModule(module);
    }

    function _notifyFor(address account, uint256 balance) private {
        bytes32[] memory cached = _modules._inner._values;
        for (uint256 i = 0; i < cached.length; ++i) {
            IGovernanceModule(address(uint256(cached[i]))).notifyStakeChanged(account, balance);
        }
    }
}