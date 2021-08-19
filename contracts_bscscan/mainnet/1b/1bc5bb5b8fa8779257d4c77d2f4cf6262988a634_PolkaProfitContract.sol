/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IERC721 {

    function setPaymentDate(uint256 _asset) external;
    function getTokenDetails(uint256 index) external view returns (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue, string memory coin);
    function polkaCitizens() external view returns(uint256 _citizens);
    function assetsByType(uint256 _assetType) external view returns (uint64 maxAmount, uint64 mintedAmount, uint128 baseValue);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address _owner) external view returns (uint256);
}

contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract PolkaProfitContract is Ownable {
    
    event Payment(address indexed to, uint256 amount);
    
    bool public paused;

    struct paymentByType {
        uint256 weeklyPayment;
        uint256 variantFactor; 
        uint256 basePriceFactor;
    }
    
    struct Claim {
        address account;
        uint256 assetId;
        uint256 amount;
        uint256 date;
    }
    
    Claim[] public payments;
    
    mapping (address => bool) public blackListed;
    mapping (uint256 => paymentByType) public paymentAmount;
    address public nftAddress = 0xd6EB2D21a6267ae654eF5dbeD49D93F8b9FEEad9;
    address public tokenAddress = 0x6Ae9701B9c423F40d54556C9a443409D79cE170a;
    address public walletAddress;
    mapping (uint256 => uint256) public bankWithdraws;
    uint256 public bankEarnings;
    address bridgeContract;

    uint256 wUnit = 1 weeks;
    
    constructor() {
        fillPayments(1,    60000000000000000000, 10, 15000000000000);
        fillPayments(2,   135000000000000000000, 10, 30000000000000);
        fillPayments(3,   375000000000000000000, 10, 75000000000000);
        fillPayments(4,   550000000000000000000, 10, 100000000000000);
        fillPayments(5,   937500000000000000000, 10, 150000000000000);
        fillPayments(6,  8250000000000000000000, 10, 750000000000000);
        fillPayments(7,  6500000000000000000000, 10, 655000000000000);
        fillPayments(8,  3000000000000000000000, 20, 400000000000000);
        fillPayments(9, 10800000000000000000000, 50, 900000000000000);
        fillPayments(10, 5225000000000000000000, 30, 550000000000000);
        fillPayments(11,13125000000000000000000, 20, 1050000000000000);
        fillPayments(12, 4500000000000000000000, 10, 500000000000000);
        fillPayments(13, 1500000000000000000000, 10, 225000000000000);
        fillPayments(14, 2100000000000000000000, 15, 300000000000000);
        fillPayments(15, 3750000000000000000000, 10, 450000000000000);
        fillPayments(20,   18000000000000000000, 0, 0);
        fillPayments(22,    4000000000000000000, 0, 0);
        fillPayments(23,    3000000000000000000, 0, 0);
        fillPayments(25, 1041000000000000000000, 0, 0);
        fillPayments(26,   44000000000000000000, 0, 0);
        fillPayments(29, 3125000000000000000000, 0, 0);
        fillPayments(30,   29000000000000000000, 0, 0);
        fillPayments(31,    5000000000000000000, 0, 0);
        fillPayments(32,   20000000000000000000, 0, 0);
        fillPayments(34,   10000000000000000000, 0, 0);
        fillPayments(36,   70000000000000000000, 0, 0);
        fillPayments(37,  105000000000000000000, 0, 0);
        fillPayments(38,  150000000000000000000, 0, 0);
        fillPayments(39,  600000000000000000000, 0, 0);
        fillPayments(40,   20000000000000000000, 0, 0);
        fillPayments(45,  750000000000000000000, 0, 0);
        fillPayments(46, 1750000000000000000000, 0, 0);

        walletAddress = 0xeA50CE6EBb1a5E4A8F90Bfb35A2fb3c3F0C673ec;

    }
    
    function fillPayments(uint256 _assetId, uint256 _weeklyPayment, uint256 _variantFactor, uint256 _basePriceFactor) private {
        paymentAmount[_assetId].weeklyPayment = _weeklyPayment;
        paymentAmount[_assetId].variantFactor = _variantFactor;
        paymentAmount[_assetId].basePriceFactor = _basePriceFactor;
    }
    
    function profitsPayment(uint256 _assetId) public returns (bool success) {
        require(paused == false, "Contract is paused");
        IERC721 nft = IERC721(nftAddress);
        address assetOwner = nft.ownerOf(_assetId);
        require(assetOwner == msg.sender, "Only asset owner can claim profits");
        require(blackListed[assetOwner] == false, "This address cannot claim profits");
        (uint256 totalPayment, ) = calcProfit(_assetId);
        require (totalPayment > 0, "You need to wait at least 1 week to claim");
        nft.setPaymentDate(_assetId);
        IERC20Token token = IERC20Token(tokenAddress);
        require(token.transferFrom(walletAddress, assetOwner, totalPayment), "ERC20 transfer fail");
        Claim memory thisclaim = Claim(msg.sender, _assetId, totalPayment, block.timestamp);
        payments.push(thisclaim);
        emit Payment(msg.sender, totalPayment);
        return true;
    }
    
    function calcProfit(uint256 _assetId) public view returns (uint256 _profit, uint256 _lastPayment) {
        IERC721 nft = IERC721(nftAddress);
        (uint32 assetType,, uint32 lastTransfer, uint32 lastPayment, , ) = nft.getTokenDetails(_assetId);
        uint256 cTime = block.timestamp - lastTransfer;
        uint256 dTime = 0;
        uint256 totalPayment;
        if (lastTransfer < lastPayment) {
            dTime = lastPayment - lastTransfer;
        }
        if ((cTime) < wUnit) { 
            return (0, lastTransfer);
        } else {
             uint256 weekCount;  
            if (dTime == 0) {
                weekCount = ((cTime)/(wUnit));
            } else {
                weekCount = ((cTime)/(wUnit)) - (dTime)/(wUnit);
            }
            if (weekCount < 1) {
                return (0, lastPayment);
            } else {
                uint256 daysCount = weekCount * 7; 
                paymentByType memory thisPayment = paymentAmount[uint256(assetType)];
                if (assetType > 19) {
                    totalPayment = weekCount * thisPayment.weeklyPayment;
                } else {
                    uint256 variantCount;
                    if (assetType == 8 || assetType == 15) {
                        variantCount = countTaxis();
                    } else {
                        variantCount = nft.polkaCitizens();
                    }
                    uint256 dailyProfit = ((thisPayment.basePriceFactor*(variantCount*thisPayment.variantFactor))/30)*daysCount;
                    totalPayment = ((weekCount * thisPayment.weeklyPayment) + dailyProfit);
                     
                }
             
                return (totalPayment, lastPayment);
            }
        }
    }
    
    function calcTotalEarnings(uint256 _assetId) public view returns (uint256 _profit, uint256 _lastPayment) {
        IERC721 nft = IERC721(nftAddress);
        (uint32 assetType,, uint32 lastTransfer, , , ) = nft.getTokenDetails(_assetId);
        uint256 timeFrame = block.timestamp - lastTransfer;
        if (timeFrame < wUnit) {  
            return (0, lastTransfer);
        } else {
            uint256 weekCount = timeFrame/(wUnit); 
            uint256 daysCount = weekCount * 7;  
            uint256 totalPayment;
            paymentByType memory thisPayment = paymentAmount[uint256(assetType)];
            if (assetType > 19) {
                totalPayment = weekCount * thisPayment.weeklyPayment;
            } else {
                uint256 variantCount;
                if (assetType == 8 || assetType == 15) {
                    variantCount = countTaxis();
                } else {
                    variantCount = nft.polkaCitizens();
                }
            uint256 dailyProfit = ((thisPayment.basePriceFactor*(variantCount*thisPayment.variantFactor))/30)*daysCount;
            totalPayment = ((weekCount * thisPayment.weeklyPayment) + dailyProfit);
                 
            }

            return (totalPayment, lastTransfer);    
        }

    }
    

    function countTaxis() private view returns (uint256 taxis) {
        uint256 taxiCount = 0;
        uint64 assetMinted;
        IERC721 nft = IERC721(nftAddress);
        (, assetMinted,) = nft.assetsByType(1);
        taxiCount += uint256(assetMinted);
        (, assetMinted,) = nft.assetsByType(2);
        taxiCount += uint256(assetMinted);
        (, assetMinted,) = nft.assetsByType(3);
        taxiCount += uint256(assetMinted);
        (, assetMinted,) = nft.assetsByType(4);
        taxiCount += assetMinted;
        (, assetMinted,) = nft.assetsByType(5);
        taxiCount += uint256(assetMinted);
        return taxiCount;
    }

    
    function pauseContract(bool _paused) public onlyOwner {
        paused = _paused;
    }
    
    function blackList(address _wallet, bool _blacklist) public onlyOwner {
        blackListed[_wallet] = _blacklist;
    }

    function paymentCount() public view returns (uint256 _paymentCount) {
        return payments.length;
    }
    
    function paymentDetail(uint256 _paymentIndex) public view returns (address _to, uint256 assetId, uint256 _amount, uint256 _date) {
        Claim memory thisPayment = payments[_paymentIndex];
        return (thisPayment.account, thisPayment.assetId, thisPayment.amount, thisPayment.date);
    }

    function setWalletAddress(address _wallet) public onlyOwner {
        walletAddress = _wallet;
    }
    
    function setBridgeContract(address _contract) public onlyOwner {
        bridgeContract = _contract;
    }
    
    function addType(uint256 _aType, uint256 _weekly) public onlyOwner {
        fillPayments(_aType, _weekly, 0, 0);
    }
    
    function addBankEarnings(uint256 _amount) public {
        require(msg.sender == bridgeContract, "Not Allowed");
        bankEarnings += _amount;
    }
    
    function claimBankEarnings(uint256 _assetId) public {
        IERC721 nft = IERC721(nftAddress);
        (uint32 assetType,,,,, ) = nft.getTokenDetails(_assetId);
        address assetOwner = nft.ownerOf(_assetId);
        require(assetType == 33, "Invalid asset");
        uint256 toPay = bankEarnings - bankWithdraws[_assetId];
        if (toPay > 0) {
            bankWithdraws[_assetId] = bankEarnings;
            IERC20Token token = IERC20Token(tokenAddress);
            require(token.transferFrom(walletAddress, assetOwner, toPay), "ERC20 transfer fail");
            emit Payment(assetOwner, toPay);
        }
    }
    
}