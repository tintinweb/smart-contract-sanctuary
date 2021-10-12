/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

/*

   _____ __  ______  ______     ___________   _____    _   ______________
  / ___// / / / __ \/ ____/    / ____/  _/ | / /   |  / | / / ____/ ____/
  \__ \/ / / / /_/ / /_       / /_   / //  |/ / /| | /  |/ / /   / __/   
 ___/ / /_/ / _, _/ __/  _   / __/ _/ // /|  / ___ |/ /|  / /___/ /___   
/____/\____/_/ |_/_/    (_) /_/   /___/_/ |_/_/  |_/_/ |_/\____/_____/  

Website: https://surf.finance
Contract: WhirlpoolDistributor.sol
Description: The Whirlpool Distributor sends SURF to The Whirlpool daily
Created by Proof

*/

pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract WhirlpoolDistributor is Ownable {

    // The SURF token contract
    IERC20 public surf;
    // The Whirlpool contract
    address public whirlpool;

    // The base amount of SURF sent to The Whirlpool daily
    uint256 public baseSurfReward = 1000e18;
    // The extra amount of SURF sent to The Whirlpool daily per 100,000 SURF in this contract
    uint256 public extraSurfReward = 1000e18;
    // The amount of SURF rewarded to the "distribute" function caller
    uint256 public distributorSurfReward = 50e18;
    // How often SURF can be distributed to the Whirlpool
    uint256 public constant DISTRIBUTION_INTERVAL = 24 hours;
    // When the last SURF distribution was processed (timestamp)
    uint256 public lastDistribution;

    event Distribute(address indexed distributor, uint256 reward, uint256 distributed);

    constructor(uint256 _firstDistribution) {
        surf = IERC20(0xEa319e87Cf06203DAe107Dd8E5672175e3Ee976c);
        whirlpool = 0x999b1e6EDCb412b59ECF0C5e14c20948Ce81F40b;
        lastDistribution = _firstDistribution - DISTRIBUTION_INTERVAL;
	}

	function distribute() external {
        uint256 distributionAmount = getDistributionAmount();
        require(distributionAmount > 0, "Nothing to distribute");

        uint256 daysSinceLastDistribution = getDaysSinceLastDistribution();
        lastDistribution += (daysSinceLastDistribution * DISTRIBUTION_INTERVAL);

        uint256 rewardAmount = distributionAmount > (distributorSurfReward * 2) ? distributorSurfReward : 0;
        if (rewardAmount > 0) {
            distributionAmount = distributionAmount - rewardAmount;
            surf.transfer(msg.sender, rewardAmount);
        }

        surf.transfer(whirlpool, distributionAmount);

        emit Distribute(msg.sender, rewardAmount, distributionAmount);
	}

    // Sets the baseSurfReward. Must be between 1 and 10,000
    function setBaseSurfReward(uint256 _baseSurfReward) external onlyOwner {
        require(_baseSurfReward >= 1e18 && _baseSurfReward <= 10000e18, "Out of range");
        baseSurfReward = _baseSurfReward;
    }

    // Sets the extraSurfReward. Must be between 0 and 10,000
    function setExtraSurfReward(uint256 _extraSurfReward) external onlyOwner {
        require(_extraSurfReward >= 0 && _extraSurfReward <= 10000e18, "Out of range");
        extraSurfReward = _extraSurfReward;
    }

    // Sets the distributorSurfReward. Must be between 0 and 100
    function setDistributorSurfReward(uint256 _distributorSurfReward) external onlyOwner {
        require(_distributorSurfReward >= 0 && _distributorSurfReward <= 100e18, "Out of range");
        distributorSurfReward = _distributorSurfReward;
    }

    // Sets the address of The Whirlpool contract
    function setWhirlpoolAddress(address _whirlpool) external onlyOwner {
        whirlpool = _whirlpool;
    }

    // Function to recover ERC20 tokens accidentally sent to the contract.
    // SURF tokens (the only token that should be in this contract) can't be withdrawn this way.
    function recoverToken(IERC20 _token, address _receiver) external onlyOwner {
        require(address(_token) != address(surf), "Cannot recover SURF");
        uint256 tokenBalance = _token.balanceOf(address(this));
        require(tokenBalance > 0, "No balance");
        _token.transfer(_receiver, tokenBalance);
    }

    function timeUntilNextDistribution() external view returns (uint256) {
        if (block.timestamp > lastDistribution + DISTRIBUTION_INTERVAL) {
            return 0;
        }
        return (lastDistribution + DISTRIBUTION_INTERVAL) - block.timestamp;
    }

    function getDaysSinceLastDistribution() public view returns (uint256) {
        return (block.timestamp - lastDistribution) / DISTRIBUTION_INTERVAL;
    }

    function getDistributionAmount() public view returns (uint256) {
        uint256 surfBalance = surf.balanceOf(address(this));
        if (surfBalance == 0) return 0;
        
        // How many days since the last distribution?
        uint256 daysSinceLastDistribution = getDaysSinceLastDistribution();

        // If less than 1, don't do anything
        if (daysSinceLastDistribution == 0) return 0;

        uint256 total = 0;

        for (uint256 i = 0; i < daysSinceLastDistribution; i++) {
            total += baseSurfReward + (extraSurfReward * ((surfBalance-total) / 100000e18));
        }

        // Cap total at contract balance
        total = total > surfBalance ? surfBalance : total;
        return total;
    }

}