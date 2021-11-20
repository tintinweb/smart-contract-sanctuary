//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import "./AddressArrayUtils.sol";
import "./Context.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract AntexVesting is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AddressArrayUtils for address[];

    address public constant payTokenAddress = address(0x2D94cd4FE899ABB0D1f4fF945836a34409306c78);

    event ClaimToken(address userAddress, uint256 tokenAmount, uint256 timeRequire, uint256 timeClaim, uint8 claimNumber, string roundType);

    struct ClaimHistory {
        uint256 tokenAmount;
        uint256 timeRequire;
        uint256 timeClaim;
        uint256 claimNumber;
        uint8 percent;
    }

    bool public allowClaim = false;

    uint8 public constant firstSeedPercent = 10;
    uint8 public constant seedMonth = 12;
    uint8 public constant firstPrivatePercent = 15;
    uint8 public constant privateMonth = 10;
    uint8 public constant firstPresalePercent = 15;
    uint8 public constant presaleMonth = 9;

    uint256 public totalSeedAmount = 0;
    uint256 public totalSeedTakeAmount = 0;

    uint256 public totalPrivateAmount = 0;
    uint256 public totalPrivateTakeAmount = 0;

    uint256 public totalPresaleAmount = 0;
    uint256 public totalPresaleTakeAmount = 0;

    uint8[] public seedPercentMonth = [4, 5, 6, 7, 8, 8, 9, 9, 10, 11, 11, 12];
    uint8[] public privatePercentMonth = [5, 6, 7, 8, 9, 11, 12, 13, 14, 15];
    uint8[] public presalePercentMonth = [6, 7, 8, 10, 11, 13, 14, 15, 16];

    EnumerableSet.AddressSet private SEED_ADDRESS;
    mapping(address => uint256) public SEED_AMOUNT;
    mapping(address => uint256) public SEED_TAKE_AMOUNT;
    mapping(address => uint256) public SEED_AFTER_TGE_AMOUNT;
    mapping(address => uint256) public SEED_REMAIN_AMOUNT;
    mapping(address => uint256[]) public SEED_REQUIRE_TIME;
    mapping(address => uint256[]) public SEED_HISTORY_TIME;
    mapping(address => uint256[]) public SEED_HISTORY_TAKE_AMOUNT;

    EnumerableSet.AddressSet private PRIVATE_ADDRESS;
    mapping(address => uint256) public PRIVATE_AMOUNT;
    mapping(address => uint256) public PRIVATE_TAKE_AMOUNT;
    mapping(address => uint256) public PRIVATE_AFTER_TGE_AMOUNT;
    mapping(address => uint256) public PRIVATE_REMAIN_AMOUNT;
    mapping(address => uint256[]) public PRIVATE_REQUIRE_TIME;
    mapping(address => uint256[]) public PRIVATE_HISTORY_TIME;
    mapping(address => uint256[]) public PRIVATE_HISTORY_TAKE_AMOUNT;

    EnumerableSet.AddressSet private PRESALE_ADDRESS;
    mapping(address => uint256) public PRESALE_AMOUNT;
    mapping(address => uint256) public PRESALE_TAKE_AMOUNT;
    mapping(address => uint256) public PRESALE_AFTER_TGE_AMOUNT;
    mapping(address => uint256) public PRESALE_REMAIN_AMOUNT;
    mapping(address => uint256[]) public PRESALE_REQUIRE_TIME;
    mapping(address => uint256[]) public PRESALE_HISTORY_TIME;
    mapping(address => uint256[]) public PRESALE_HISTORY_TAKE_AMOUNT;


    modifier validAddressData(address[] memory listAddress, uint256[] memory listAmount) {
        require(listAddress.length > 0, "INVALID ADDRESS LENGTH");
        require(listAddress.length == listAmount.length, "INVALID DATA LENGTH");
        require(!AddressArrayUtils.hasDuplicate(listAddress), "DUPLICATE ADDRESS");
        _;
    }

    modifier allowToClaim() {
        require(allowClaim, "CANNOT CLAIM NOW");
        _;
    }

    // SEED
    function setSeedData(address[] memory listAddress, uint256[] memory listAmount) external onlyOwner validAddressData(listAddress, listAmount) {
        require(!allowClaim, "USER CAN CLAIM NOW");
        uint256 amountLength = listAmount.length;
        for (uint256 i = 0; i < amountLength; i++) {
            require(listAmount[i] > 0, "INVALID AMOUNT");
            SEED_ADDRESS.add(listAddress[i]);
            totalSeedAmount = totalSeedAmount.sub(SEED_AMOUNT[listAddress[i]]);
            SEED_AMOUNT[listAddress[i]] = listAmount[i];
            totalSeedAmount = totalSeedAmount.add(listAmount[i]);
        }
    }

    function getSeedAddressLength() external view returns (uint256) {
        return SEED_ADDRESS.length();
    }

    function getSeedAddressInfoByIndex(uint256 index) external view returns (uint256 totalAmount, uint256 takeAmount, uint256 remainAmount, uint256 nextClaimTime, uint256 nextClaimAmount) {
        address userAddress = SEED_ADDRESS.at(index);
        return getSeedAddressInfo(userAddress);
    }

    function getSeedAddressInfo(address userAddress) public view returns (uint256 totalAmount, uint256 takeAmount, uint256 remainAmount, uint256 nextClaimTime, uint256 nextClaimAmount) {
        uint256[] memory _listHistoryTime = SEED_HISTORY_TIME[userAddress];
        uint256 _remainAmount = SEED_REMAIN_AMOUNT[userAddress];
        uint256 _nextClaimTime = 0;
        if (_listHistoryTime.length > 0 && _listHistoryTime.length <= seedMonth) {
            _nextClaimTime = SEED_REQUIRE_TIME[userAddress][_listHistoryTime.length];
        }

        uint256 _nextClaimAmount = 0;
        if (_listHistoryTime.length == 0) {
            // First Claim
            _nextClaimAmount = SEED_AMOUNT[userAddress].div(100).mul(firstSeedPercent);
        } else {

            if (_listHistoryTime.length <= seedMonth) {
                if (_listHistoryTime.length == seedMonth) {
                    // Last claim
                    _nextClaimAmount = SEED_AMOUNT[userAddress].sub(SEED_TAKE_AMOUNT[userAddress]);
                } else {
                    _nextClaimAmount = SEED_AFTER_TGE_AMOUNT[userAddress].div(100).mul(seedPercentMonth[_listHistoryTime.length - 1]);
                }
            }
        }

        return (SEED_AMOUNT[userAddress], SEED_TAKE_AMOUNT[userAddress], _remainAmount, _nextClaimTime, _nextClaimAmount);
    }

    function claimSeedRound() nonReentrant allowToClaim external returns (bool) {
        require(SEED_ADDRESS.contains(msg.sender), "USER NOT IN SEED ROUND");
        uint256[] storage listHistoryTime = SEED_HISTORY_TIME[msg.sender];
        require(listHistoryTime.length <= seedMonth + 1, "NO REMAINING AMOUNT");
        uint256 takeAmount = 0;
        uint256 nextClaim = 0;
        if (listHistoryTime.length == 0) {
            // First Claim, Init Require Time
            for (uint256 i = 1; i <= seedMonth; i++) {
                SEED_REQUIRE_TIME[msg.sender].push(block.timestamp + (i * 1 minutes));
            }
        } else {
            nextClaim = SEED_REQUIRE_TIME[msg.sender][listHistoryTime.length - 1];
            require(block.timestamp >= nextClaim, "PLEASE WAIT FOR NEXT CLAIM");
        }
        uint8 percent = 0;
        if (listHistoryTime.length == 0) {
            // First Claim
            percent = firstSeedPercent;
            takeAmount = SEED_AMOUNT[msg.sender].div(100).mul(firstSeedPercent);
            SEED_AFTER_TGE_AMOUNT[msg.sender] = SEED_AMOUNT[msg.sender].sub(takeAmount);
        } else {
            percent = seedPercentMonth[listHistoryTime.length - 1];
            if (listHistoryTime.length == seedMonth) {
                // Last claim
                takeAmount = SEED_AMOUNT[msg.sender].sub(SEED_TAKE_AMOUNT[msg.sender]);
            } else {
                takeAmount = SEED_AFTER_TGE_AMOUNT[msg.sender].div(100).mul(percent);
            }
        }

        listHistoryTime.push(block.timestamp);
        SEED_HISTORY_TAKE_AMOUNT[msg.sender].push(takeAmount);
        SEED_TAKE_AMOUNT[msg.sender] = SEED_TAKE_AMOUNT[msg.sender].add(takeAmount);
        SEED_REMAIN_AMOUNT[msg.sender] = SEED_AMOUNT[msg.sender].sub(SEED_TAKE_AMOUNT[msg.sender]);
        totalSeedTakeAmount = totalSeedTakeAmount.add(takeAmount);
        return IERC20(payTokenAddress).transfer(msg.sender, takeAmount);
    }

    function getSeedHistory(address userAddress) external view returns (uint256[] memory listHistoryTime, uint256[] memory listHistoryTakeAmount) {
        return (SEED_HISTORY_TIME[userAddress], SEED_HISTORY_TAKE_AMOUNT[userAddress]);
    }

    function getSeedRequireTime(address userAddress) external view returns (uint256[] memory) {
        return SEED_REQUIRE_TIME[userAddress];
    }

    // PRIVATE
    function setPrivateData(address[] memory listAddress, uint256[] memory listAmount) external onlyOwner validAddressData(listAddress, listAmount) {
        require(!allowClaim, "USER CAN CLAIM NOW");
        uint256 amountLength = listAmount.length;
        for (uint256 i = 0; i < amountLength; i++) {
            require(listAmount[i] > 0, "INVALID AMOUNT");
            PRIVATE_ADDRESS.add(listAddress[i]);
            totalPrivateAmount = totalPrivateAmount.sub(PRIVATE_AMOUNT[listAddress[i]]);
            PRIVATE_AMOUNT[listAddress[i]] = listAmount[i];
            totalPrivateAmount = totalPrivateAmount.add(listAmount[i]);
        }
    }

    function getPrivateAddressLength() external view returns (uint256) {
        return PRIVATE_ADDRESS.length();
    }

    function getPrivateAddressInfoByIndex(uint256 index) external view returns (uint256 totalAmount, uint256 takeAmount, uint256 remainAmount, uint256 nextClaimTime, uint256 nextClaimAmount) {
        address userAddress = PRIVATE_ADDRESS.at(index);
        return getPrivateAddressInfo(userAddress);
    }

    function getPrivateAddressInfo(address userAddress) public view returns (uint256 totalAmount, uint256 takeAmount, uint256 remainAmount, uint256 nextClaimTime, uint256 nextClaimAmount) {
        uint256[] memory _listHistoryTime = PRIVATE_HISTORY_TIME[userAddress];
        uint256 _remainAmount = PRIVATE_REMAIN_AMOUNT[userAddress];
        uint256 _nextClaimTime = 0;
        if (_listHistoryTime.length > 0 && _listHistoryTime.length <= privateMonth) {
            _nextClaimTime = PRIVATE_REQUIRE_TIME[userAddress][_listHistoryTime.length];
        }

        uint256 _nextClaimAmount = 0;
        if (_listHistoryTime.length == 0) {
            // First Claim
            _nextClaimAmount = PRIVATE_AMOUNT[userAddress].div(100).mul(firstSeedPercent);
        } else {

            if (_listHistoryTime.length <= seedMonth) {
                if (_listHistoryTime.length == seedMonth) {
                    // Last claim
                    _nextClaimAmount = PRIVATE_AMOUNT[userAddress].sub(PRIVATE_TAKE_AMOUNT[userAddress]);
                } else {
                    _nextClaimAmount = PRIVATE_AFTER_TGE_AMOUNT[userAddress].div(100).mul(seedPercentMonth[_listHistoryTime.length - 1]);
                }
            }
        }

        return (PRIVATE_AMOUNT[userAddress], PRIVATE_TAKE_AMOUNT[userAddress], _remainAmount, _nextClaimTime, _nextClaimAmount);
    }

    function claimPrivateRound() nonReentrant allowToClaim external returns (bool) {
        require(PRIVATE_ADDRESS.contains(msg.sender), "USER NOT IN PRIVATE SALE ROUND");
        uint256[] storage listHistoryTime = PRIVATE_HISTORY_TIME[msg.sender];
        require(listHistoryTime.length <= privateMonth + 1, "NO REMAINING AMOUNT");
        uint256 takeAmount = 0;
        uint256 nextClaim = 0;
        if (listHistoryTime.length == 0) {
            // First Claim, Init Require Time
            for (uint256 i = 1; i <= privateMonth; i++) {
                PRIVATE_REQUIRE_TIME[msg.sender].push(block.timestamp + (i * 1 minutes));
            }
        } else {
            nextClaim = PRIVATE_REQUIRE_TIME[msg.sender][listHistoryTime.length - 1];
            require(block.timestamp >= nextClaim, "PLEASE WAIT FOR NEXT CLAIM");
        }
        uint8 percent = 0;
        if (listHistoryTime.length == 0) {
            // First Claim
            percent = firstPrivatePercent;
            takeAmount = PRIVATE_AMOUNT[msg.sender].div(100).mul(firstPrivatePercent);
            PRIVATE_AFTER_TGE_AMOUNT[msg.sender] = PRIVATE_AMOUNT[msg.sender].sub(takeAmount);
        } else {
            percent = privatePercentMonth[listHistoryTime.length - 1];
            if (listHistoryTime.length == privateMonth) {
                // Last claim
                takeAmount = PRIVATE_AMOUNT[msg.sender].sub(PRIVATE_TAKE_AMOUNT[msg.sender]);
            } else {
                takeAmount = PRIVATE_AFTER_TGE_AMOUNT[msg.sender].div(100).mul(percent);
            }
        }

        listHistoryTime.push(block.timestamp);
        PRIVATE_HISTORY_TAKE_AMOUNT[msg.sender].push(takeAmount);
        PRIVATE_TAKE_AMOUNT[msg.sender] = PRIVATE_TAKE_AMOUNT[msg.sender].add(takeAmount);
        PRIVATE_REMAIN_AMOUNT[msg.sender] = PRIVATE_AMOUNT[msg.sender].sub(PRIVATE_TAKE_AMOUNT[msg.sender]);
        totalPrivateTakeAmount = totalPrivateTakeAmount.add(takeAmount);
        return IERC20(payTokenAddress).transfer(msg.sender, takeAmount);
    }

    function getPrivateHistory(address userAddress) external view returns (uint256[] memory listHistoryTime, uint256[] memory listHistoryTakeAmount) {
        return (PRIVATE_HISTORY_TIME[userAddress], PRIVATE_HISTORY_TAKE_AMOUNT[userAddress]);
    }

    function getPrivateRequireTime(address userAddress) external view returns (uint256[] memory) {
        return PRIVATE_REQUIRE_TIME[userAddress];
    }

    // PRESALE
    function setPresaleData(address[] memory listAddress, uint256[] memory listAmount) external onlyOwner validAddressData(listAddress, listAmount) {
        require(!allowClaim, "USER CAN CLAIM NOW");
        uint256 amountLength = listAmount.length;
        for (uint256 i = 0; i < amountLength; i++) {
            require(listAmount[i] > 0, "INVALID AMOUNT");
            PRESALE_ADDRESS.add(listAddress[i]);
            totalPresaleAmount = totalPresaleAmount.sub(PRESALE_AMOUNT[listAddress[i]]);
            PRESALE_AMOUNT[listAddress[i]] = listAmount[i];
            totalPresaleAmount = totalPresaleAmount.add(listAmount[i]);
        }
    }

    function getPresaleAddressLength() external view returns (uint256) {
        return PRESALE_ADDRESS.length();
    }

    function getPresaleAddressInfoByIndex(uint256 index) external view returns (uint256 totalAmount, uint256 takeAmount, uint256 remainAmount, uint256 nextClaimTime, uint256 nextClaimAmount) {
        address userAddress = PRESALE_ADDRESS.at(index);
        return getPresaleAddressInfo(userAddress);
    }

    function getPresaleAddressInfo(address userAddress) public view returns (uint256 totalAmount, uint256 takeAmount, uint256 remainAmount, uint256 nextClaimTime, uint256 nextClaimAmount) {
        uint256[] memory _listHistoryTime = PRESALE_HISTORY_TIME[userAddress];
        uint256 _remainAmount = PRESALE_REMAIN_AMOUNT[userAddress];
        uint256 _nextClaimTime = 0;
        if (_listHistoryTime.length > 0 && _listHistoryTime.length <= presaleMonth) {
            _nextClaimTime = PRESALE_REQUIRE_TIME[userAddress][_listHistoryTime.length];
        }

        uint256 _nextClaimAmount = 0;
        if (_listHistoryTime.length == 0) {
            // First Claim
            _nextClaimAmount = PRESALE_AMOUNT[userAddress].div(100).mul(firstSeedPercent);
        } else {

            if (_listHistoryTime.length <= seedMonth) {
                if (_listHistoryTime.length == seedMonth) {
                    // Last claim
                    _nextClaimAmount = PRESALE_AMOUNT[userAddress].sub(PRESALE_TAKE_AMOUNT[userAddress]);
                } else {
                    _nextClaimAmount = PRESALE_AFTER_TGE_AMOUNT[userAddress].div(100).mul(seedPercentMonth[_listHistoryTime.length - 1]);
                }
            }
        }

        return (PRESALE_AMOUNT[userAddress], PRESALE_TAKE_AMOUNT[userAddress], _remainAmount, _nextClaimTime, _nextClaimAmount);
    }

    function claimPresaleRound() nonReentrant allowToClaim external returns (bool) {
        require(PRESALE_ADDRESS.contains(msg.sender), "USER NOT IN PRESALE ROUND");
        uint256[] storage listHistoryTime = PRESALE_HISTORY_TIME[msg.sender];
        require(listHistoryTime.length <= presaleMonth + 1, "NO REMAINING AMOUNT");
        uint256 takeAmount = 0;
        uint256 nextClaim = 0;
        if (listHistoryTime.length == 0) {
            // First Claim, Init Require Time
            for (uint256 i = 1; i <= presaleMonth; i++) {
                PRESALE_REQUIRE_TIME[msg.sender].push(block.timestamp + (i * 1 minutes));
            }
        } else {
            nextClaim = PRESALE_REQUIRE_TIME[msg.sender][listHistoryTime.length - 1];
            require(block.timestamp >= nextClaim, "PLEASE WAIT FOR NEXT CLAIM");
        }
        uint8 percent = 0;
        if (listHistoryTime.length == 0) {
            // First Claim
            percent = firstPresalePercent;
            takeAmount = PRESALE_AMOUNT[msg.sender].div(100).mul(firstPresalePercent);
            PRESALE_AFTER_TGE_AMOUNT[msg.sender] = PRESALE_AMOUNT[msg.sender].sub(takeAmount);
        } else {
            percent = presalePercentMonth[listHistoryTime.length - 1];
            if (listHistoryTime.length == presaleMonth) {
                // Last claim
                takeAmount = PRESALE_AMOUNT[msg.sender].sub(PRESALE_TAKE_AMOUNT[msg.sender]);
            } else {
                takeAmount = PRESALE_AFTER_TGE_AMOUNT[msg.sender].div(100).mul(percent);
            }
        }

        listHistoryTime.push(block.timestamp);
        PRESALE_HISTORY_TAKE_AMOUNT[msg.sender].push(takeAmount);
        PRESALE_TAKE_AMOUNT[msg.sender] = PRESALE_TAKE_AMOUNT[msg.sender].add(takeAmount);
        PRESALE_REMAIN_AMOUNT[msg.sender] = PRESALE_AMOUNT[msg.sender].sub(PRESALE_TAKE_AMOUNT[msg.sender]);
        totalPresaleTakeAmount = totalPresaleTakeAmount.add(takeAmount);
        return IERC20(payTokenAddress).transfer(msg.sender, takeAmount);
    }

    function getPresaleHistory(address userAddress) external view returns (uint256[] memory listHistoryTime, uint256[] memory listHistoryTakeAmount) {
        return (PRESALE_HISTORY_TIME[userAddress], PRESALE_HISTORY_TAKE_AMOUNT[userAddress]);
    }

    function getPresaleRequireTime(address userAddress) external view returns (uint256[] memory) {
        return PRESALE_REQUIRE_TIME[userAddress];
    }

    // CHANGE CLAIM STATUS
    function changeClaimStatus(bool _claimStatus) external onlyOwner {
        allowClaim = _claimStatus;
    }

    function getJoinedRound(address userAddress) external view returns (bool joinSeed, bool joinPrivate, bool joinPresale) {
        return (SEED_ADDRESS.contains(userAddress), PRIVATE_ADDRESS.contains(userAddress), PRESALE_ADDRESS.contains(userAddress));
    }

    function retrieveERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(owner(), tokens);
    }

    function retrieveMainBalance() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}