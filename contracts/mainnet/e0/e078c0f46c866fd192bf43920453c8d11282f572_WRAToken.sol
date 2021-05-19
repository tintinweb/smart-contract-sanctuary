pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract WRAToken is ERC20("WrapFi", "WRA"), Ownable {
    using SafeMath for uint256;

    uint256 public NUMBER_BLOCKS_PER_YEAR;
    uint256 public startAtBlock;

    address public genesisLaunchAddress;
    address public stakingReserveAddress;
    address public wrapFiUsersAddress;
    address public devFundAddress;
    address public ecoFundAddress;

    mapping (address => mapping (uint256 => bool)) public unLockResult;
    mapping (address => mapping (uint256 => uint256)) public unLockInfo;

    constructor(
        uint256 _numberBlocksPerYear,
        address _genesisLaunchAddress,
        address _stakingReserveAddress,
        address _wrapFiUsersAddress,
        address _devFundAddress,
        address _ecoFundAddress) public {
        NUMBER_BLOCKS_PER_YEAR = _numberBlocksPerYear > 0 ? _numberBlocksPerYear : 2254114;
        genesisLaunchAddress = _genesisLaunchAddress;
        stakingReserveAddress = _stakingReserveAddress;
        wrapFiUsersAddress = _wrapFiUsersAddress;
        devFundAddress = _devFundAddress;
        ecoFundAddress = _ecoFundAddress;
        startAtBlock = block.number;
        initUnLockInfo();
        _mint(msg.sender, 90000000e18);
        _mint(genesisLaunchAddress, 10000000e18);
    }

    function initUnLockInfo() internal {
        unLockInfo[stakingReserveAddress][1] = 60;
        unLockInfo[stakingReserveAddress][2] = 45;
        unLockInfo[stakingReserveAddress][3] = 30;
        unLockInfo[stakingReserveAddress][4] = 15;

        unLockInfo[wrapFiUsersAddress][1] = 240;
        unLockInfo[wrapFiUsersAddress][2] = 180;
        unLockInfo[wrapFiUsersAddress][3] = 120;
        unLockInfo[wrapFiUsersAddress][4] = 60;

        unLockInfo[devFundAddress][1] = 40;
        unLockInfo[devFundAddress][2] = 30;
        unLockInfo[devFundAddress][3] = 20;
        unLockInfo[devFundAddress][4] = 10;

        unLockInfo[ecoFundAddress][1] = 20;
        unLockInfo[ecoFundAddress][2] = 15;
        unLockInfo[ecoFundAddress][3] = 10;
        unLockInfo[ecoFundAddress][4] = 5;
    }

    function unLockForStakingReserve() public onlyOwner {
        unLockFor(stakingReserveAddress);
    }

    function unLockForWrapFiUsers() public onlyOwner {
        unLockFor(wrapFiUsersAddress);
    }

    function unLockForDevFund() public onlyOwner {
        unLockFor(devFundAddress);
    }

    function unLockForEcoFund() public onlyOwner {
        unLockFor(ecoFundAddress);
    }

    function unLockFor(address _to) private {
        uint256 blockNow = block.number;
        uint256 yearNow = blockNow.sub(startAtBlock).div(NUMBER_BLOCKS_PER_YEAR);
        uint256 amount;
        for (uint256 i = 1; i < 5; i++) {
            if (i > yearNow) {
                break;
            }
            if (!unLockResult[_to][i]) {
                amount = amount.add(totalSupply().mul(unLockInfo[_to][i]).div(1000));
                unLockResult[_to][i] = true;
            }
        }
        if (amount > 0){
            transfer(_to, amount);
        }
    }
}