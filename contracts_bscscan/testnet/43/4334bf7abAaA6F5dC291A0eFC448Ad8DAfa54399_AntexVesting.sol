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

    uint8 public constant firstPayPercent = 10;
    uint8 public constant seedMonth = 12;
    uint8 public constant privateSaleMonth = 10;
    uint8 public constant presaleMonth = 9;
    uint256 public totalSeedAmount = 0;
    uint256 public totalPrivateSaleAmount = 0;
    uint256 public totalPresaleAmount = 0;
    uint8[] public seedPercentMonth = [4, 5, 6, 7, 8, 8, 9, 9, 10, 11, 11, 12];
    uint8[] public privateSalePercentMonth = [5, 6, 7, 8, 9, 11, 12, 13, 14, 15];
    uint8[] public presalePercentMonth = [6, 7, 8, 10, 11, 13, 14, 15, 16];

    EnumerableSet.AddressSet private SEED_ADDRESS;
    mapping(address => uint256) public SEED_AMOUNT;
    mapping(address => uint256) public SEED_TAKE_AMOUNT;
    mapping(address => uint256[]) public SEED_REQUIRE_TIME;
    mapping(address => uint256) public SEED_REMAIN_AMOUNT;
    mapping(address => ClaimHistory[]) public SEED_HISTORY;

    EnumerableSet.AddressSet private PRIVATE_SALE_ADDRESS;
    mapping(address => uint256) public PRIVATE_SALE_AMOUNT;
    mapping(address => uint256) public PRIVATE_SALE_TAKE_AMOUNT;
    mapping(address => uint256[]) public PRIVATE_SALE_REQUIRE_TIME;
    mapping(address => uint256) public PRIVATE_SALE_REMAIN_AMOUNT;
    mapping(address => ClaimHistory[]) public PRIVATE_SALE_HISTORY;

    EnumerableSet.AddressSet private PRESALE_ADDRESS;
    mapping(address => uint256) public PRESALE_AMOUNT;
    mapping(address => uint256) public PRESALE_TAKE_AMOUNT;
    mapping(address => uint256[]) public PRESALE_REQUIRE_TIME;
    mapping(address => uint256) public PRESALE_REMAIN_AMOUNT;
    mapping(address => ClaimHistory[]) public PRESALE_HISTORY;

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

    function setSeedData(address[] memory listAddress, uint256[] memory listAmount) external onlyOwner validAddressData(listAddress, listAmount) {
        require(!allowClaim, "USER CAN CLAIM NOW");
        uint256 amountLength = listAmount.length;
        for (uint256 i = 0; i < amountLength; i++) {
            require(listAmount[i] > 0, "INVALID AMOUNT");
            SEED_ADDRESS.add(listAddress[i]);
            SEED_AMOUNT[listAddress[i]] = listAmount[i];
            totalSeedAmount = totalSeedAmount.add(listAmount[i]);
        }
    }

    function setPrivateSaleData(address[] memory listAddress, uint256[] memory listAmount) external onlyOwner validAddressData(listAddress, listAmount) {
        require(!allowClaim, "USER CAN CLAIM NOW");
        uint256 amountLength = listAmount.length;
        for (uint256 i = 0; i < amountLength; i++) {
            require(listAmount[i] > 0, "INVALID AMOUNT");
            PRIVATE_SALE_ADDRESS.add(listAddress[i]);
            PRIVATE_SALE_AMOUNT[listAddress[i]] = listAmount[i];
            totalPrivateSaleAmount = totalPrivateSaleAmount.add(listAmount[i]);
        }
    }

    function setPresaleData(address[] memory listAddress, uint256[] memory listAmount) external onlyOwner validAddressData(listAddress, listAmount) {
        require(!allowClaim, "USER CAN CLAIM NOW");
        uint256 amountLength = listAmount.length;
        for (uint256 i = 0; i < amountLength; i++) {
            require(listAmount[i] > 0, "INVALID AMOUNT");
            PRESALE_ADDRESS.add(listAddress[i]);
            PRESALE_AMOUNT[listAddress[i]] = listAmount[i];
            totalPresaleAmount = totalPresaleAmount.add(listAmount[i]);
        }
    }

    function getSeedAddressLength() external view returns (uint256) {
        return SEED_ADDRESS.length();
    }

    function getSeedAddressInfo(uint256 index) external view returns (address userAddress, uint256 totalAmount, uint256 takeAmount, ClaimHistory[] memory history, uint256 nextClaim) {
        address seedAddress = SEED_ADDRESS.at(index);
        uint256 userBalance = SEED_AMOUNT[seedAddress];
        uint256 tokenAmount = SEED_TAKE_AMOUNT[seedAddress];
        ClaimHistory[] memory listHistory = SEED_HISTORY[seedAddress];
        uint256 nextClaimTime = SEED_REQUIRE_TIME[seedAddress][listHistory.length];
        return (seedAddress, userBalance, tokenAmount, listHistory, nextClaimTime);
    }

    function getPrivateSaleAddressLength() external view returns (uint256) {
        return PRIVATE_SALE_ADDRESS.length();
    }

    function getPrivateSaleAddressInfo(uint256 index) external view returns (address userAddress, uint256 totalAmount, uint256 takeAmount, ClaimHistory[] memory history, uint256 nextClaim) {
        address privateSaleAddress = PRIVATE_SALE_ADDRESS.at(index);
        uint256 userBalance = PRIVATE_SALE_AMOUNT[privateSaleAddress];
        uint256 tokenAmount = PRIVATE_SALE_TAKE_AMOUNT[privateSaleAddress];
        ClaimHistory[] memory listHistory = PRIVATE_SALE_HISTORY[privateSaleAddress];
        uint256 nextClaimTime = PRIVATE_SALE_REQUIRE_TIME[privateSaleAddress][listHistory.length];
        return (privateSaleAddress, userBalance, tokenAmount, listHistory, nextClaimTime);
    }

    function getPresaleAddressLength() external view returns (uint256) {
        return PRESALE_ADDRESS.length();
    }

    function getPresaleAddressInfo(uint256 index) external view returns (address userAddress, uint256 totalAmount, uint256 takeAmount, ClaimHistory[] memory history, uint256 nextClaim) {
        address presaleAddress = PRESALE_ADDRESS.at(index);
        uint256 userBalance = PRESALE_AMOUNT[presaleAddress];
        uint256 tokenAmount = PRESALE_TAKE_AMOUNT[presaleAddress];
        ClaimHistory[] memory listHistory = PRESALE_HISTORY[presaleAddress];
        uint256 nextClaimTime = PRESALE_REQUIRE_TIME[presaleAddress][listHistory.length];
        return (presaleAddress, userBalance, tokenAmount, listHistory, nextClaimTime);
    }

    function claimSeedRound() nonReentrant allowToClaim external returns (bool) {
        require(SEED_ADDRESS.contains(msg.sender), "USER NOT IN SEED ROUND");
        ClaimHistory[] storage listHistory = SEED_HISTORY[msg.sender];
        require(listHistory.length <= seedMonth + 1, "NO REMAINING AMOUNT");
        uint256 takeAmount = 0;
        uint256 nextClaim = 0;
        if (listHistory.length == 0) {
            // First Claim, Init Require Time
            for (uint256 i = 1; i <= seedMonth; i++) {
                SEED_REQUIRE_TIME[msg.sender].push(block.timestamp + (i * 30 * 1 days));
            }
        } else {
            nextClaim = SEED_REQUIRE_TIME[msg.sender][listHistory.length - 1];
            require(block.timestamp >= nextClaim, "PLEASE WAIT FOR NEXT CLAIM");
        }
        uint8 percent = 0;
        if (listHistory.length == 0) {
            // First Claim
            percent = firstPayPercent;
            takeAmount = SEED_AMOUNT[msg.sender].div(100).mul(firstPayPercent);
            SEED_REMAIN_AMOUNT[msg.sender] = SEED_AMOUNT[msg.sender].sub(takeAmount);
        } else {
            percent = seedPercentMonth[listHistory.length - 1];
            if (listHistory.length == seedMonth) {
                // Last claim
                takeAmount = SEED_AMOUNT[msg.sender].sub(SEED_TAKE_AMOUNT[msg.sender]);
            } else {
                takeAmount = SEED_REMAIN_AMOUNT[msg.sender].div(100).mul(percent);
            }
        }

        ClaimHistory memory newClaimHistory = ClaimHistory({
        tokenAmount : takeAmount,
        timeRequire : nextClaim,
        timeClaim : block.timestamp,
        claimNumber : listHistory.length + 1,
        percent : percent
        });

        listHistory.push(newClaimHistory);
        SEED_TAKE_AMOUNT[msg.sender].add(takeAmount);
        return IERC20(payTokenAddress).transfer(msg.sender, takeAmount);
    }

    function changeClaimStatus(bool _claimStatus) external onlyOwner {
        allowClaim = _claimStatus;
    }

    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(owner(), tokens);
    }

    function retrieveMainBalance() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}