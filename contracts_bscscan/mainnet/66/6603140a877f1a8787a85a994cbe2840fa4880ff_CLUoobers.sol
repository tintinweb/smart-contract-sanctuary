/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address addr) external returns (uint256);
}

contract CLUoobers {
    mapping(uint256 => address) buyer;
    mapping(address => uint256) amounts;
    mapping(address => uint256) whitelisted;
    
    address owner;
    
    address immutable CLU = 0x7A9867eED57EB0E473b3Ec3C0bC069F293Cc893F;// 0x1162E2EfCE13f99Ed259fFc24d99108aAA0ce935;
    
    uint256 public maxSupply;
    uint256 public maxPurchase = 10;
    uint256 private currentSold;
    uint256 public nftPrice;
    uint256 public whitePrice;
    
    bool public saleIsActive = true;
    uint256 public whiteSaleStart;
    uint256 public whiteSaleDuration;
    
    event Reserve(uint256 amount, address beneficiary);
    event MainSalePriceChange(uint256 price);
    event WhiteSaleStartChange(uint256 timestamp);
    event WhiteSaleDurationChange(uint256 duration);
    event WhiteSalePriceChange(uint256 price);
    event MaxSupplyChange(uint256 supply);
    event SaleState();
    
    modifier onlyOwner{
        require(msg.sender == owner, "You don't own me!");
        _;
    }
    
    constructor(uint256 _whitePrice, uint256 _nftPrice, uint256 _whiteSaleStart, uint256 _whiteSaleDuration, uint256 _maxSupply) {
        owner = msg.sender;
        whitePrice = _whitePrice;
        nftPrice = _nftPrice;
        whiteSaleStart = _whiteSaleStart;
        whiteSaleDuration = _whiteSaleDuration;
        maxSupply = _maxSupply;
    }
    
    function balanceOf(address _address) public view returns (uint256) {
        return amounts[_address];
    }
    
    function onWhitelist(address _address) public view returns (bool) {
        return whitelisted[_address] == 1;
    }
    
    function availableNFTs() public view returns (uint256) {
        return (maxSupply - currentSold);
    }
    
    function currentlyReserved() public view returns (uint256) {
        return currentSold;
    }
    
    function ownerOf(uint16 id) public view returns (address) {
        return buyer[id];
    }
    
    function withdraw(uint256 amount) public onlyOwner {
        require(amount < IERC20(CLU).balanceOf(address(this)));
        IERC20(CLU).transfer(owner, amount);
    }
    
    function whitelist(address[] memory addresses) public onlyOwner {
        for (uint i=0; i < addresses.length; i++){
            whitelisted[addresses[i]] = 1;
        }
    }
    
    function toggleSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
        emit SaleState();
    }
    
    function adminReserve(address[] memory addresses) public onlyOwner {
        require(currentSold + addresses.length <= maxSupply, "Minting that amount would exceed total supply");
        for (uint i=0; i< addresses.length; i++){
            buyer[i + currentSold] = addresses[i];
            amounts[addresses[i]] += 1;
			emit Reserve(1, addresses[i]);
        }
        
        currentSold += addresses.length;
    }
    
    function reserve(uint256 _amount) public {
        reserve(_amount, msg.sender);
    }
    
    function reserve(uint256 _amount, address beneficiary) public {
        require(block.timestamp > whiteSaleStart && saleIsActive, "Sale is not active");
        require(currentSold < maxSupply, "Sold out");
        require(currentSold + _amount <= maxSupply, "Minting that amount would exceed total supply");
        require(amounts[beneficiary] + _amount <= 100, "Beneficiary can't have a claim larger than 100 NFTs");
        
        uint256 price = nftPrice;
        
        if (block.timestamp < whiteSaleStart + whiteSaleDuration){
            require(whitelisted[msg.sender] > 0, "Not whitelisted or used allocation");
            require(_amount == 1, "Whitelist allocation is 1 NFT");
            price = whitePrice;
            whitelisted[msg.sender] = 0;
        } else {
            require(_amount <= maxPurchase, "Maximum of 10 tokens at a time");
        }
        
        require(IERC20(CLU).transferFrom(msg.sender, address(this), price * _amount), "Not enough CLU for purchase");
        
        for (uint i=0; i<_amount; i++){
            buyer[i + currentSold] = beneficiary;
        }
        
        amounts[beneficiary] += _amount;
        currentSold += _amount;
        
        emit Reserve(_amount, beneficiary);
    }
    
    function setWhiteSaleStart(uint256 _startingTimestamp) public onlyOwner {
        whiteSaleStart = _startingTimestamp;
        emit WhiteSaleStartChange(_startingTimestamp);
    }
    
    function setWhiteSaleDuration(uint256 _duration) public onlyOwner {
        whiteSaleDuration = _duration;
        emit WhiteSaleDurationChange(_duration);
    }
    
    function setWhiteSalePrice(uint256 _whitePrice) public onlyOwner {
        whitePrice = _whitePrice;
        emit WhiteSalePriceChange(_whitePrice);
    }
    
    function setMainSalePrice(uint256 _nftPrice) public onlyOwner {
        nftPrice = _nftPrice;
        emit MainSalePriceChange(_nftPrice);
    }
    
    function setMaxSupply(uint256 _maxSupply) public onlyOwner{
        maxSupply = _maxSupply;
        emit MaxSupplyChange(_maxSupply);
    }
}