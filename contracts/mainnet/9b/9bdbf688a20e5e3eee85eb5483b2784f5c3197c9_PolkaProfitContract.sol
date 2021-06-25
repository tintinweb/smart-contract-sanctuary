/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IERC721 {

    function setPaymentDate(uint256 _asset) external;
    function getTokenDetails(uint256 index) external view returns (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue, string memory coin);
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
    
    event Payment(address indexed _from, uint256 _amount, uint8 network);
    
    bool public paused;

    struct Claim {
        address account;
        uint8 dNetwork;  // 1= Ethereum   2= BSC
        uint256 assetId;
        uint256 amount;
        uint256 date;
    }
    
    Claim[] public payments;
    
    mapping (address => bool) public blackListed;
    mapping (uint256 => uint256) public weeklyByType;
    address public nftAddress = 0xB20217bf3d89667Fa15907971866acD6CcD570C8;
    address public tokenAddress = 0xaA8330FB2B4D5D07ABFE7A72262752a8505C6B37;
    address public walletAddress = 0xeA50CE6EBb1a5E4A8F90Bfb35A2fb3c3F0C673ec;
    uint256 public gasFee = 1000000000000000;

    uint256 wUnit = 1 weeks;
    
    constructor() {
        weeklyByType[20] = 18 ether;
        weeklyByType[22] = 4 ether;
        
        weeklyByType[23] = 3 ether;
        weeklyByType[25] = 1041 ether;
        weeklyByType[26] = 44 ether;
        weeklyByType[29] = 3125 ether;
        weeklyByType[30] = 29 ether;
        weeklyByType[31] = 5 ether;
        weeklyByType[32] = 20 ether;
        weeklyByType[34] = 10 ether;
        
        weeklyByType[36] = 70 ether;
        weeklyByType[37] = 105 ether;
        weeklyByType[38] = 150 ether;
        weeklyByType[39] = 600 ether;
        weeklyByType[40] = 20 ether;
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
        Claim memory thisclaim = Claim(msg.sender, 1, _assetId, totalPayment, block.timestamp);
        payments.push(thisclaim);
        emit Payment(msg.sender, totalPayment, 1);
        return true;
    }
    
    function profitsPaymentBSC(uint256 _assetId) public payable returns (bool success) {
        require(paused == false, "Contract is paused");
        require(msg.value >= gasFee, "Gas fee too low");
        IERC721 nft = IERC721(nftAddress);
        address assetOwner = nft.ownerOf(_assetId);
        require(assetOwner == msg.sender, "Only asset owner can claim profits");
        require(blackListed[assetOwner] == false, "This address cannot claim profits");
        (uint256 totalPayment, ) = calcProfit(_assetId);
        require (totalPayment > 0, "You need to wait at least 1 week to claim");
        nft.setPaymentDate(_assetId);
        Claim memory thisclaim = Claim(msg.sender, 2, _assetId, totalPayment, block.timestamp);
        payments.push(thisclaim);
        emit Payment(msg.sender, totalPayment, 2);
        return true;
    }
    
    function calcProfit(uint256 _assetId) public view returns (uint256 _profit, uint256 _lastPayment) {
        IERC721 nft = IERC721(nftAddress);
        (uint32 assetType,, uint32 lastTransfer, uint32 lastPayment,, ) = nft.getTokenDetails(_assetId);
        uint256 cTime = block.timestamp - lastTransfer;
        uint256 dTime = 0;
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
                uint256 totalPayment;
                totalPayment = ((weekCount * weeklyByType[assetType]));
                return (totalPayment, lastPayment);  
                
            }
        }
    }
    
    function calcTotalEarnings(uint256 _assetId) public view returns (uint256 _profit, uint256 _lastPayment) {
        IERC721 nft = IERC721(nftAddress);
        (uint32 assetType,, uint32 lastTransfer,,, ) = nft.getTokenDetails(_assetId);
        uint256 timeFrame = block.timestamp - lastTransfer;
        if (timeFrame < wUnit) {  
            return (0, lastTransfer);
        } else {
            uint256 weekCount = timeFrame/(wUnit); 
            uint256 totalPayment;
            totalPayment = ((weekCount * weeklyByType[assetType]));
            return (totalPayment, lastTransfer);    
        }

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
    
    function paymentDetail(uint256 _paymentIndex) public view returns (address _to, uint8 _network, uint256 assetId, uint256 _amount, uint256 _date) {
        Claim memory thisPayment = payments[_paymentIndex];
        return (thisPayment.account, thisPayment.dNetwork, thisPayment.assetId, thisPayment.amount, thisPayment.date);
    }
    
    function addType(uint256 _aType, uint256 _weekly) public onlyOwner {
        weeklyByType[_aType] = _weekly;
    }
    
    function setGasFee(uint256 _gasFee) public onlyOwner {
        gasFee = _gasFee;
    }
    
}