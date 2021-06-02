// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CYAN_Complete.sol";

contract CYAN_ICO {

    address public FLUSH_ADDR; //Where to send flushed ETH and CYAN
    CYAN cyanContract; //CYAN contract object
    uint256 public priceStart; //wei
    uint256 public priceEnd; //wei
    uint256 public icoStartTime; //in days
    uint256 public icoEndTime; //in days
    uint256 public cyanideSold = 0;
    uint256 public ethCollected = 0;

    event Sell(address _buyer, uint256 _amount);
    event SaleStart(uint256 time);
    event SaleEnd(uint256 time);
    event PriceChange(uint256 price);
    event FlushedCYN(uint amount);
    event FlushedETH(uint amount);

    //Called once when contract is deployed
    constructor(address _cyanContractAddress, uint256 _priceStart, uint256 _priceEnd, uint256 _icoStartTime, uint256 _icoEndTime) {

        //Ensure later values are greater than earlier values
        require (_icoStartTime < _icoEndTime);
        require (_priceStart < _priceEnd);

        FLUSH_ADDR = msg.sender; //Assign flush address to contract deployer
        cyanContract = CYAN(payable(_cyanContractAddress)); //Assign CYAN contract by address

        priceStart = _priceStart; //INPUT IN WEI
        priceEnd = _priceEnd; //INPUT IN WEI

        icoStartTime = _icoStartTime; //INPUT IN DAYS
        icoEndTime = _icoEndTime; // INPUT IN DAYS

    }

    function changeSettings(address _cyanContractAddress, uint256 _priceStart, uint256 _priceEnd, uint256 _icoStartTime, uint256 _icoEndTime) public {

        require (msg.sender == FLUSH_ADDR, "Sender not FLUSH_ADDR");
        require (_icoStartTime < _icoEndTime);
        require (_priceStart < _priceEnd);

        cyanContract = CYAN(payable(_cyanContractAddress)); //Assign CYAN contract by address

        priceStart = _priceStart; //INPUT IN WEI
        priceEnd = _priceEnd; //INPUT IN WEI

        icoStartTime = _icoStartTime; //INPUT IN DAYS
        icoEndTime = _icoEndTime; // INPUT IN DAYS

    }

    function getCurrentDay() view public returns (uint256) {
        return ((block.timestamp / (1 days)) - icoStartTime);
    }

    function checkSaleEnabled() view public returns (bool) {
        return ((block.timestamp / (1 days)) >= icoStartTime && (block.timestamp / (1 days)) <= icoEndTime);
    }

    //Returns start price if before ICO and end price if after ICO
    function checkCurrentPrice() view public returns (uint256) {
        if ((block.timestamp / (1 days)) < icoStartTime) {
            return priceStart;
        }
        else if ((block.timestamp / (1 days)) > icoEndTime) {
            return priceEnd;
        }
        else {
            return priceStart + ((((block.timestamp / (1 days)) - icoStartTime) * (priceEnd-priceStart)) / (icoEndTime - icoStartTime));
        }

    }

    function purchaseCYN(uint256 _amount) public payable {

        //Ensure the purchase is correct
        require(checkSaleEnabled(), "Sale not enabled");
        uint256 price = checkCurrentPrice();
        require(msg.value >= (_amount * price), "Not enough ETH sent");
        require(cyanContract.balanceOf(address(this)) >= _amount, "Not enough CYAN left");
        require(cyanContract.transfer(msg.sender, _amount), "CYAN could not be transferred");

        //Update ICO trackers
        cyanideSold += _amount;
        ethCollected += msg.value;

        Sell(msg.sender, _amount);

    }

    //Send all CYAN remaining in the contract to FLUSH_ADDR
    function flushCYN() public {

        require(msg.sender == FLUSH_ADDR, "Sender not FLUSH_ADDR");

        uint256 bal = cyanContract.balanceOf(address(this));
        require(cyanContract.transfer(FLUSH_ADDR, bal));

        FlushedCYN(bal);

    }

    //Send all ETH remaining in the contract to FLUSH_ADDR
    function flushETH() public {

        require(msg.sender == FLUSH_ADDR, "Sender not FLUSH_ADDR");
        require(address(this).balance != 0, "Currently no ETH in CYAN_ICO.");

        uint256 bal = address(this).balance;
        payable(FLUSH_ADDR).transfer(bal);

        FlushedETH(bal);

    }

    //Backup functions
    receive() external payable {}
    fallback() external payable {}

}