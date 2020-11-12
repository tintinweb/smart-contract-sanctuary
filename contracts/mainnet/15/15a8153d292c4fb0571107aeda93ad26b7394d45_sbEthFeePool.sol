// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./sbControllerInterface.sol";
import "./sbStrongValuePoolInterface.sol";

contract sbEthFeePool {
    using SafeMath for uint256;
    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address payable public superAdmin;
    address payable public pendingSuperAdmin;

    sbControllerInterface public sbController;
    sbStrongValuePoolInterface public sbStrongValuePool;
    IERC20 public strongToken;

    uint256 public superAdminFeeNumerator;
    uint256 public superAdminFeeDenominator;

    uint256 public logsSumFeeAmount;
    mapping(address => uint256[]) public logsContractFeeDays;
    mapping(address => uint256[]) public logsContractFeeAmounts;

    address public constant burnAddress = address(
        0x000000000000000000000000000000000000dEaD
    );

    function init(
        address sbControllerAddress,
        address sbStrongValuePoolAddress,
        address strongTokenAddress,
        address adminAddress,
        address payable superAdminAddress
    ) public {
        require(!initDone, "init done");
        sbController = sbControllerInterface(sbControllerAddress);
        sbStrongValuePool = sbStrongValuePoolInterface(
            sbStrongValuePoolAddress
        );
        strongToken = IERC20(strongTokenAddress);
        admin = adminAddress;
        superAdmin = superAdminAddress;
        initDone = true;
    }

    function updateSuperAdminFee(uint256 numerator, uint256 denominator)
        public
    {
        require(msg.sender == superAdmin);
        require(denominator != 0, "invalid value");
        superAdminFeeNumerator = numerator;
        superAdminFeeDenominator = denominator;
    }

    function deposit() public payable {
        uint256 currentDay = _getCurrentDay();
        uint256 len = logsContractFeeDays[msg.sender].length;
        if (len == 0) {
            logsContractFeeDays[msg.sender].push(currentDay);
            logsContractFeeAmounts[msg.sender].push(msg.value);
        } else {
            uint256 lastIndex = logsContractFeeDays[msg.sender].length.sub(1);
            uint256 lastDay = logsContractFeeDays[msg.sender][lastIndex];
            if (lastDay == currentDay) {
                logsContractFeeAmounts[msg
                    .sender][lastIndex] = logsContractFeeAmounts[msg
                    .sender][lastIndex]
                    .add(msg.value);
            } else {
                logsContractFeeDays[msg.sender].push(currentDay);
                logsContractFeeAmounts[msg.sender].push(msg.value);
            }
        }
        uint256 toSuperAdmin = msg.value.mul(superAdminFeeNumerator).div(
            superAdminFeeDenominator
        );
        logsSumFeeAmount = logsSumFeeAmount.add(msg.value);
        superAdmin.transfer(toSuperAdmin);
    }

    function setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "not admin");
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "not pendingAdmin"
        );
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address payable newPendingSuperAdmin) public {
        require(msg.sender == superAdmin, "not superAdmin");
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(
            msg.sender == pendingSuperAdmin && msg.sender != address(0),
            "not pendingSuperAdmin"
        );
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    function getContractFeeData(address cntrct, uint256 dayNumber)
        public
        view
        returns (uint256, uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        return _getContractFeeData(cntrct, day);
    }

    function _getContractFeeData(address cntrct, uint256 day)
        internal
        view
        returns (uint256, uint256)
    {
        uint256[] memory _Days = logsContractFeeDays[cntrct];
        uint256[] memory _Amounts = logsContractFeeAmounts[cntrct];
        return _get(_Days, _Amounts, day);
    }

    function _get(
        uint256[] memory _Days,
        uint256[] memory _Units,
        uint256 day
    ) internal pure returns (uint256, uint256) {
        uint256 len = _Days.length;
        if (len == 0) {
            return (day, 0);
        }
        if (day < _Days[0]) {
            return (day, 0);
        }
        uint256 lastIndex = len.sub(1);
        uint256 lastDay = _Days[lastIndex];
        if (day == lastDay) {
            return (day, _Units[lastIndex]);
        }
        return _find(_Days, _Units, day);
    }

    function _find(
        uint256[] memory _Days,
        uint256[] memory _Units,
        uint256 day
    ) internal pure returns (uint256, uint256) {
        uint256 left = 0;
        uint256 right = _Days.length.sub(1);
        uint256 middle = right.add(left).div(2);
        while (_Days[middle] != day && left < right) {
            if (_Days[middle] > day) {
                right = middle.sub(1);
            } else if (_Days[middle] < day) {
                left = middle.add(1);
            }
            middle = right.add(left).div(2);
        }
        if (_Days[middle] != day) {
            return (day, 0);
        } else {
            return (day, _Units[middle]);
        }
    }

    function _getCurrentDay() internal view returns (uint256) {
        return block.timestamp.div(1 days).add(1);
    }
}
