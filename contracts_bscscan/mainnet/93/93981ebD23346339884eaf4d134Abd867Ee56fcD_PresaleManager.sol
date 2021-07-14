/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PresaleManager {

    // Address of the token being presold that manages this.
    address _token;
    // Amount of BNB input by a buyer.
    mapping (address => uint256) _presaleBnbInput;
    // Array of buyer addresses.
    address[] _presalerBuyers;
    // Address of buyer to the array index.
    mapping (address => uint256) _presalerBuyersIndexes;
    // Whether the presale is ongoing or not started/finished.
    bool public presaleActive = false;
    // Whether the presale is open to everyone or closed to only whitelist.
    bool public isPresaleOpen = false;
    // People whitelisted to participate even if presale is not open.
    mapping (address => bool) public isInWhitelist;
    // Minimum amount of BNB you can participate with. Default 0.1 BNB.
    uint256 private minPresaleBuy = 1 * (10 ** 17);
    // Maximum amount of BNB you can participate with. Default 1.5 BNB.
    uint256 private maxPresaleBuy = 1.5 ether;
    // Price for every token in BNB.
    uint256 private _presalePricePerToken;
    // Quantity of BNB already sold.
    uint256 private _preSaleAllocatedBnb = 0;
    // Hard cap of the presale in BNB.
    uint256 private _preSaleAmount = 160 ether;
    // Index for iterating buyers over several transactions.
    uint256 private currentIndex = 0;
    // Manager of the presale
    address public owner;

    constructor(address token) {
        _token = token;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyToken {
        require(msg.sender == _token);
        _;
    }

    modifier onlyTokenOrOwner {
        require(msg.sender == owner || msg.sender == _token);
        _;
    }

    function setToken(address token) external onlyOwner {
        _token = token;
    }

    function setPresaleAmountAndPrice(uint256 preSaleAmount, uint256 pricePerToken) internal {
        require(!presaleActive, "Prices cannot be changed while presale is active.");
        _preSaleAmount = preSaleAmount;
        _presalePricePerToken = pricePerToken;
    }

    // If the presale is not active an authorised address can change the amounts.
    function updatePresaleAmountAndPrice(uint256 preSaleAmount, uint256 pricePerToken) external onlyTokenOrOwner {
        setPresaleAmountAndPrice(preSaleAmount, pricePerToken);
    }

    function presalePurchase(address buyer) external payable onlyToken {
        require(presaleActive, "Presale is not open yet.");
        require(isPresaleOpen || isInWhitelist[buyer], "You need to be whitelisted to participate on this presale.");
        require(msg.value >= minPresaleBuy, "Quantity below minimum buy.");
        require(msg.value <= maxPresaleBuy, "You are trying to buy over the current limit.");
        require(_presaleBnbInput[buyer] + msg.value <= maxPresaleBuy, "This buy would get you above the max presale size.");
        require(_preSaleAllocatedBnb + msg.value <= _preSaleAmount, "Your buy would get the presale above hard cap.");

        // New buyer?
        if (_presaleBnbInput[buyer] == 0) {
            addBuyer(buyer);
        }

        // Count BNB allocated on the presale.
        _preSaleAllocatedBnb += msg.value;
        _presaleBnbInput[buyer] += msg.value;
    }

    function setIsPresaleWhitelist(address addy, bool status) external onlyTokenOrOwner {
        isInWhitelist[addy] = status;
    }

    function isPresaleWhitelisted(address addy) public view returns(bool) {
        return isInWhitelist[addy];
    }

    function canBuyPresale(address addy) external view returns(bool) {
        return presaleActive && (isPresaleOpen || isPresaleWhitelisted(addy) && _presaleBnbInput[addy] < maxPresaleBuy);
    }

    function startPresale() external onlyTokenOrOwner {
        presaleActive = true;
    }

    function endPresale() external onlyTokenOrOwner {
        presaleActive = false;
    }

    function setIsPresaleOpen(bool isItOpen) external onlyTokenOrOwner {
        isPresaleOpen = isItOpen;
    }

    function allDelivered() public view returns(bool) {
        return currentIndex >= _presalerBuyers.length;
    }

    function deliver() external onlyToken {
        require(!presaleActive, "Presale is still ongoing!");
        uint256 buyers = _presalerBuyers.length;

        if (buyers == 0) {
            return;
        }

        if (currentIndex >= buyers) {
            return;
        }

        while (currentIndex < buyers) {
            address aBuyer = _presalerBuyers[currentIndex];
            if (_presaleBnbInput[aBuyer] > 0) {
                IBEP20 token = IBEP20(_token);
                token.transfer(aBuyer, getTokensByBnb(_presaleBnbInput[aBuyer]));
            }
            currentIndex++;
        }
    }

    function getTokensByBnb(uint256 bnb) public view returns(uint256) {
        return bnb / _presalePricePerToken;
    }

    function recoverUnallocatedTokens(address receiver) external onlyTokenOrOwner {
        require(!presaleActive, "Presale is still ongoing!");
        require(allDelivered(), "Not all tokens have been delivered.");
        IBEP20 token = IBEP20(_token);
        token.transfer(receiver, token.balanceOf(address(this)));
    }

    function forceRecoverUnallocatedTokens(address receiver) external onlyTokenOrOwner {
        IBEP20 token = IBEP20(_token);
        token.transfer(receiver, token.balanceOf(address(this)));
    }

    function setPresaleQuantities(uint256 min, uint256 max) external onlyTokenOrOwner {
        require(min <= max, "Minimum should be below maximum.");
        minPresaleBuy = min;
        maxPresaleBuy = max;
    }

    function addBuyer(address buyer) internal {
        _presalerBuyersIndexes[buyer] = _presalerBuyers.length;
        _presalerBuyers.push(buyer);
    }

    function removeBuyer(address buyer) internal {
        _presalerBuyers[_presalerBuyersIndexes[buyer]] = _presalerBuyers[_presalerBuyers.length-1];
        _presalerBuyersIndexes[_presalerBuyers[_presalerBuyers.length-1]] = _presalerBuyersIndexes[buyer];
        _presalerBuyers.pop();
    }

    function cancelPresale() external onlyTokenOrOwner {
        isPresaleOpen = false;
        presaleActive = false;

        uint256 buyers = _presalerBuyers.length;

        if (buyers == 0) {
            return;
        }

        currentIndex = 0;

        while (currentIndex < buyers) {
            address aBuyer = _presalerBuyers[currentIndex];
            if (_presaleBnbInput[aBuyer] > 0) {
                payable(aBuyer).transfer(_presaleBnbInput[aBuyer]);
            }
            currentIndex++;
        }

        delete _presalerBuyers;
    }

    function checkPresaleStatus(address addy) external view returns(uint256) {
        return _presaleBnbInput[addy];
    }

    function rescueBnb(address receiver) external onlyTokenOrOwner {
        payable(receiver).transfer(address(this).balance);
    }

    function getPresalers() external view onlyToken returns(address[] memory presalers) {
        return _presalerBuyers;
    }
}