/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface KapexPresale {
    function allocatedBand(address) external view returns (string memory);
    function bought(address) external view returns (uint256);

    function isEnded() external view returns (bool);
    function isBuyPaused() external view returns (bool);
    function getStartDateBuy() external view returns (uint256);
    function getHouseToken() external view returns (address);
    function getMinHouseTokenHoldAmount() external view returns (uint256);
    function getMaxPurcase() external view returns (uint256);
    function getMinBNB() external view returns (uint256);
    function getMaxBNB() external view returns (uint256);

    function buy() external payable;
}


contract KapexPresaleBuyRouter {
    address private owner;

    address private kapexPresaleAddress; // KAPEX address
    KapexPresale private kapexPresale; // KAPEX Presale Contract

    uint256 private minBNB; // In wei
    uint256 private maxBNB; // In wei
    uint256 private maxPurchase; // In wei (Max amount of bnb he can spend)

    bool private buyPaused = false; // Buy is avaialable from the start
    
    mapping(address => uint256) public bought; // BNB spent by account
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access this function");
        _;
    }

    constructor(
        address _kapexPresaleAddress,
        uint256 _minBNB,
        uint256 _maxBNB,
        uint256 _maxPurchase
    ) {
        owner = msg.sender;
        minBNB = _minBNB;
        maxBNB = _maxBNB;
        maxPurchase = _maxPurchase;

        kapexPresaleAddress = _kapexPresaleAddress;
        kapexPresale = KapexPresale(_kapexPresaleAddress);
    }

    //////////
    // Getters
    
    function getOwner() external view returns (address) {
        return (owner);
    }

    function getKapexPresaleAddress() external view returns (address) {
        return (kapexPresaleAddress);
    }

    function getMinBNB() external view returns (uint256) {
        return (minBNB);
    }

    function getMaxBNB() external view returns (uint256) {
        return (maxBNB);
    }

    function getMaxPurchase() external view returns (uint256) {
        return (maxPurchase);
    }
    
    function isBuyPaused() external view returns (bool) {
        return (buyPaused);
    }

    function getTotalBought() public view returns (uint256) {
        return (kapexPresale.bought(msg.sender) + bought[msg.sender]);
    }

    /////////////
    // Buy token

    receive() external payable {
        buy();
    }

    function buy() public payable {
        require(block.timestamp > kapexPresale.getStartDateBuy(), "Sale hasn't started yet");
        require(!kapexPresale.isEnded(), "Sale has ended");

        require(
            IERC20(kapexPresale.getHouseToken()).balanceOf(msg.sender) >= kapexPresale.getMinHouseTokenHoldAmount(),
            "msg.sender doesn't hold enough Koda"
        );

        if (bytes(kapexPresale.allocatedBand(msg.sender)).length > 0) {    
            require(!kapexPresale.isBuyPaused(), "Buying is paused");
            
            require(getTotalBought() + msg.value <= kapexPresale.getMaxPurcase(), "Cannot buy more than max purchase amount");
            require(msg.value >= kapexPresale.getMinBNB(), "msg.value is less than minBNB");
            require(msg.value <= kapexPresale.getMaxBNB(), "msg.value is great than maxBNB");
        } 
        else 
        {
            require(!buyPaused, "Buying is paused");

            require(getTotalBought() + msg.value <= maxPurchase, "Cannot buy more than max purchase amount" );
            require(msg.value >= minBNB, "msg.value is less than minBNB");
            require(msg.value <= maxBNB, "msg.value is great than maxBNB");
        }

        bought[msg.sender] = bought[msg.sender] + msg.value;
    }

    

    //////////////////
    // Owner functions

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function withdrawBNB(uint256 _amount, address _receiver)
        external
        onlyOwner
    {
        payable(_receiver).transfer(_amount);
    }

    function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        maxPurchase = _maxPurchase;
    }

    function setMinBNB(uint256 _minBNB) external onlyOwner {
        minBNB = _minBNB;
    }

    function setMaxBNB(uint256 _maxBNB) external onlyOwner {
        maxBNB = _maxBNB;
    }

    function setBuyPause() external onlyOwner {
        if (buyPaused) {
            buyPaused = false;
        } else {
            buyPaused = true;
        }
    }
}