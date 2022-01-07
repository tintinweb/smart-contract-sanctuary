// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";

import "./SafeMath.sol";

contract PresaleSplitterV2 is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public lastTimeClaim;
    mapping(address => uint256) public timesClaimed;
    mapping(address => uint256) public tokenAmount;
    mapping(address => uint256) public tokenAmountVip;
    mapping(address => uint256) public totalClaimedAmount;
    uint256 public presaleStartDate;
    uint256 public firstClaimInterval;
    uint256 public secondClaimInterval;
    address public presaleWalletAddress =
        0x0aEa3638B16633e970c7311f22635e6064559a70;
    address public toAddress =
        0x0aEa3638B16633e970c7311f22635e6064559a70;
    address public tokenAddress;
    //address public payTokenAddress;

    constructor(
        address[] memory addresses,
        address[] memory vipAddresses,
        uint[] memory amountToAddress,
        uint[] memory amountToVip
    ) {
        presaleStartDate = block.timestamp;
        firstClaimInterval = block.timestamp + 5 minutes;
        secondClaimInterval = block.timestamp + 10 minutes;
        tokenAddress = address(0x9c6383Dbba84b935c0A9Ef7167d1BF2fb45F4D9c);
        //payTokenAddress = address(0xd00ae08403B9bbb9124bB305C09058E32C39A48c);
        require(addresses.length == amountToAddress.length, "ARRAY ADDRESS MUST MATCH AMOUNT");
        require(vipAddresses.length == amountToVip.length, "ARRAY SPECIAL MUST MATCH AMOUNT");
        for (uint256 i = 0; i < addresses.length; i++) {
            tokenAmount[addresses[i]] = amountToAddress[i] * 10**18;
        }
        for (uint256 i = 0; i < vipAddresses.length; i++) {
            tokenAmountVip[vipAddresses[i]] = amountToVip[i] * 10**18;
        }
    }

    function updatePresaleAddress(address value) external onlyOwner {
        presaleWalletAddress = value;
    }

    function calculateClaimableAmount()
        private
        view
        returns (uint256 claimAmount)
    {
        if (timesClaimed[msg.sender] == 0) {
            return tokenAmount[msg.sender].mul(30).div(100);
        }
        if (
            firstClaimInterval < block.timestamp &&
            timesClaimed[msg.sender] == 1
        ) {
            return tokenAmount[msg.sender].mul(35).div(100);
        }
        if (
            secondClaimInterval < block.timestamp &&
            timesClaimed[msg.sender] == 2
        ) {
            return tokenAmount[msg.sender].mul(35).div(100);
        }
    }

    function calculateVipClaimableAmount()
        private
        view
        returns (uint256 claimAmount)
    {
        if (timesClaimed[msg.sender] == 0) {
            return tokenAmount[msg.sender].mul(40).div(100);
        }
        if (
            firstClaimInterval < block.timestamp &&
            timesClaimed[msg.sender] == 1
        ) {
            return tokenAmount[msg.sender].mul(30).div(100);
        }
        if (
            secondClaimInterval < block.timestamp &&
            timesClaimed[msg.sender] == 2
        ) {
            return tokenAmount[msg.sender].mul(30).div(100);
        }
    }

    function claim() external {
        require(msg.sender != address(0), "SENDER CAN'T BE ZERO");
        require(tokenAmount[msg.sender] != 0, "SENDER NOT PRESALER");
        require(timesClaimed[msg.sender] < 3, "MAX TOKEN AMOUNT CLAIMED ");
        require(calculateClaimableAmount() > 0, "CLAIM AMOUNT EQUALS 0");
        require(
            ERC20(tokenAddress).balanceOf(presaleWalletAddress) >
                calculateClaimableAmount(),
            "PRESALES POOL EMPTY"
        );

        ERC20(tokenAddress).transferFrom(
            presaleWalletAddress,
            msg.sender,
            calculateClaimableAmount()
        );
        totalClaimedAmount[msg.sender] += calculateClaimableAmount();
        lastTimeClaim[msg.sender] = block.timestamp;
        timesClaimed[msg.sender] += 1;
    }

    function claimVip() external {
        require(msg.sender != address(0), "SENDER CAN'T BE ZERO");
        require(tokenAmountVip[msg.sender] != 0, "SENDER NOT VIP PRESALER");
        require(timesClaimed[msg.sender] < 3, "MAX TOKEN AMOUNT CLAIMED ");
        require(calculateVipClaimableAmount() > 0, "CLAIM AMOUNT EQUALS 0");
        require(
            ERC20(tokenAddress).balanceOf(presaleWalletAddress) >
                calculateVipClaimableAmount(),
            "PRESALES POOL EMPTY"
        );

        ERC20(tokenAddress).transferFrom(
            presaleWalletAddress,
            msg.sender,
            calculateVipClaimableAmount()
        );
        totalClaimedAmount[msg.sender] += calculateVipClaimableAmount();
        lastTimeClaim[msg.sender] = block.timestamp;
        timesClaimed[msg.sender] += 1;
    }

    // function transfer(uint256 amount) external returns (bool) {
    //     require(msg.sender != address(0), "SENDER CAN'T BE ZERO");
    //     require(amount < 100000000000000000, "MIN AMOUNT 0.1 BNB");

    //     ERC20(payTokenAddress).transferFrom(
    //         msg.sender,
    //         toAddress,
    //         amount
    //     );

    //     //aquí tendría que haber un oráculo
    //     tokenAmount[msg.sender] = amount / (0.1*10**18);
    // }


}