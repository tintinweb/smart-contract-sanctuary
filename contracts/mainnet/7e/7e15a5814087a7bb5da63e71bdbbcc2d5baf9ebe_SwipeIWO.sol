// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract SwipeIWO is Ownable {
    struct WhiteList {
        bool isWhite;
        uint256 maxAllowance;
    }

    // Use SafeMath for uint256 and SafeERC20 for IERC20
    using SafeMath for uint256;

    // Address For BaseToken. e.x: SXP
    address private _baseToken;
    // Address For SaleToken. e.x: STRK
    address private _saleToken;
    // Rate STRK To SXP
    uint256 private _saleRate;
    // Is Sale, Only set with owner
    bool private _isSale;
    // Sale Start Time
    uint256 private _startTime;
    // Sale End Time
    uint256 private _endTime;
    // Maximum Base Token Amount
    uint256 private _maxBaseAmount;
    // Minimum Base Token Amount
    uint256 private _minBaseAmount;
    // Limit Base Token Amount
    uint256 private _limitBaseAmount;

    // baseAmount with each address
    mapping(address => uint256) _baseAmounts;
    mapping(address => WhiteList) _whiteList;

    modifier isNoContract() {
        require(
            Address.isContract(_msgSender()) == false,
            "Contract is not allowed on SwipeIWO"
        );
        _;
    }

    modifier isWhite(uint256 newSaleAmount) {
        require(_whiteList[_msgSender()].isWhite, "You're not allowed to purchased");
        require(
            _baseAmounts[_msgSender()].add(newSaleAmount) <= _whiteList[_msgSender()].maxAllowance,
            "You can not purchase more than maxAllowance"
        );
        _;
    }

    /**
     * @dev Check IWO is not Over
     */
    modifier isNotOver() {
        require(_isSale, "SwipeIWO is sale over");
        require(block.timestamp >= _startTime, "SwipeIWO is not started yet");
        require(block.timestamp <= _endTime, "SwipeIWO is already finished");
        require(IERC20(_baseToken).balanceOf(address(this)) <= _limitBaseAmount, "Already sold out.");
        _;
    }

    /**
     * @dev Check IWO is Over
     */
    modifier isOver() {
        require(!_isSale || block.timestamp < _startTime || block.timestamp > _endTime || IERC20(_baseToken).balanceOf(address(this)) > _limitBaseAmount, "SwipeIWO is not finished yet");
        _;
    }

    event PurchaseToken(address indexed account, uint256 baseAmount, uint256 saleAmount);
    
    constructor() {
        // Initialize the base&sale Tokens
        _baseToken = address(0);
        _saleToken = address(0);

        // // Initialize the rate&isSale, should be divide 1e18 when purchase
        // _saleRate = 1e18;
        // _isSale = false;

        // // Initialize the start&end time
        // _startTime = block.timestamp;
        // _endTime = block.timestamp;

        // // Initialize the max&min base amount
        // _minBaseAmount = 1e18;
        // _maxBaseAmount = 1e18;

        // // Initialize the baseLimitAmount
        // _limitBaseAmount = 1e18;

        // Initialize the rate&isSale, should be divide 1e18 when purchase
        _saleRate = 10e18;
        _isSale = true;

        // Initialize the start&end time
        _startTime = uint256(block.timestamp).sub(10000);
        _endTime = uint256(block.timestamp).add(10000);

        // Initialize the max&min base amount
        _minBaseAmount = 1e18;
        _maxBaseAmount = 10e18;

        // Initialize the baseLimitAmount
        _limitBaseAmount = 100e18;
    }

    /**
     * @dev Get White Status
     */
    function getWhiteStatus(address userAddress) public view returns (bool, uint256) {
        return (
            _whiteList[userAddress].isWhite,
            _whiteList[userAddress].maxAllowance
        );
    }

    /**
     * @dev Set White Statuses, only owner call it
     */
    function setWhiteStatus(address[] memory userAddressList, WhiteList[] memory userInfoList) external onlyOwner returns (bool) {
        require(userAddressList.length == userInfoList.length, "The lengths of arrays should be same.");

        for (uint i = 0; i < userAddressList.length; i += 1) {
            _whiteList[userAddressList[i]] = userInfoList[i];
        }

        return true;
    }

    /**
     * @dev Get Base Token
     */
    function getBaseToken() public view returns (address) {
        return _baseToken;
    }

    /**
     * @dev Set Base Token, only owner call it
     */
    function setBaseToken(address baseToken) external onlyOwner {
        require(baseToken != address(0), "BaseToken should be not 0x0");
        _baseToken = baseToken;
    }

    /**
     * @dev Get Sale Token
     */
    function getSaleToken() public view returns (address) {
        return _saleToken;
    }

    /**
     * @dev Set Sale Token, only owner call it
     */
    function setSaleToken(address saleToken) external onlyOwner {
        require(saleToken != address(0), "SaleToken should be not 0x0");
        _saleToken = saleToken;
    }

    /**
     * @dev Get Sale Rate
     */
    function getSaleRate() public view returns (uint256) {
        return _saleRate;
    }

    /**
     * @dev Set Sale Rate, only owner call it
     */
    function setSaleRate(uint256 saleRate) external onlyOwner {
        _saleRate = saleRate;
    }

    /**
     * @dev Get IsSale
     */
    function getIsSale() public view returns (bool) {
        return _isSale;
    }

    /**
     * @dev Set IsSale, only owner call it
     */
    function setIsSale(bool isSale) external onlyOwner {
        _isSale = isSale;
    }

    /**
     * @dev Get IWO Start Time
     */
    function getStartTime() public view returns (uint256) {
        return _startTime;
    }

    /**
     * @dev Set IWO Start Time, only owner call it
     */
    function setStartTime(uint256 startTime) external onlyOwner {
        _startTime = startTime;
    }

    /**
     * @dev Get IWO End Time
     */
    function getEndTime() public view returns (uint256) {
        return _endTime;
    }

    /**
     * @dev Set End Time, only owner call it
     */
    function setEndTime(uint256 endTime) external onlyOwner {
        require(endTime > _startTime, "EndTime should be over than startTime");
        _endTime = endTime;
    }

    /**
     * @dev Get MinBase Amount
     */
    function getMinBaseAmount() public view returns (uint256) {
        return _minBaseAmount;
    }

    /**
     * @dev Set MinBase Amount, only owner call it
     */
    function setMinBaseAmount(uint256 minBaseAmount) external onlyOwner {
        _minBaseAmount = minBaseAmount;
    }

    /**
     * @dev Get MaxBase Amount
     */
    function getMaxBaseAmount() public view returns (uint256) {
        return _maxBaseAmount;
    }

    /**
     * @dev Set MaxBase Amount, only owner call it
     */
    function setMaxBaseAmount(uint256 maxBaseAmount) external onlyOwner {
        require(maxBaseAmount > _minBaseAmount, "MaxBaseAmount should be over than minBaseAmount");
        _maxBaseAmount = maxBaseAmount;
    }

    /**
     * @dev Get LimitBase Amount
     */
    function getLimitBaseAmount() public view returns (uint256) {
        return _limitBaseAmount;
    }

    /**
     * @dev Set LimitBase Amount, only owner call it
     */
    function setLimitBaseAmount(uint256 limitBaseAmount) external onlyOwner {
        _limitBaseAmount = limitBaseAmount;
    }

    /**
     * @dev Check IsIWO On Status
     */
    function isIWOOn() public view returns (bool) {
        if (_isSale &&
            block.timestamp >= _startTime &&
            block.timestamp <= _endTime &&
            IERC20(_baseToken).balanceOf(address(this)) <= _limitBaseAmount) {
                return true;
            }
        return false;
    }

    /**
     * @dev Set Allocation Amount with Sale Token, only owner call it
            Should approve the amount before call this function
     */
    function allocationAmount(uint256 amount) external onlyOwner returns (bool) {
        require(IERC20(_saleToken).balanceOf(address(_msgSender())) >= amount, "Owner should have more than amount with Sale Token");

        IERC20(_saleToken).transferFrom(
            _msgSender(),
            address(this),
            amount
        );

        return true;
    }

    /**
     * @dev Burn baseToken, only owner call it
     */
    function burnBaseToken(uint256 burnAmount) external onlyOwner returns (bool) {
        require(IERC20(_baseToken).balanceOf(address(this)) >= burnAmount, "Burn Amount should be less than balance of contract");

        // IERC20(_baseToken).burn(burnAmount);
        IERC20(_baseToken).transfer(address(0), burnAmount);

        return true;
    }   

    /**
     * @dev Withdraw Base Token, only owner call it
     */
    function withdrawBaseToken(address withdrawAddress, uint256 withdrawAmount) external onlyOwner returns (bool) {
        uint256 baseBalance = IERC20(_baseToken).balanceOf(address(this));
        require(withdrawAmount <= baseBalance, "The withdrawAmount should be less than balance");

        IERC20(_baseToken).transfer(withdrawAddress, withdrawAmount);

        return true;
    }

    /**
     * @dev Withdraw Sale Token, only owner call it
     */
    function withdrawSaleToken(address withdrawAddress, uint256 withdrawAmount) external onlyOwner returns (bool) {
        uint256 saleBalance = IERC20(_saleToken).balanceOf(address(this));
        require(withdrawAmount <= saleBalance, "The withdrawAmount should be less than balance");

        IERC20(_saleToken).transfer(withdrawAddress, withdrawAmount);

        return true;
    }
    
    /**
     * @dev Purchase Sale Token
            Should approve the baseToken before purchase
     */
    function purchaseSaleToken(uint256 baseAmountForSale)
        external
        isNoContract
        isNotOver
        isWhite(baseAmountForSale)
        returns (bool)
    {
        // Check min&max base amount
        uint256 currentBaseTotalAmount = IERC20(_baseToken).balanceOf(address(this));
        // Get Sale Amount
        uint256 saleAmount = baseAmountForSale.mul(_saleRate).div(1e18);

        require(baseAmountForSale >= _minBaseAmount, "Purchase Amount should be more than minBaseAmount");
        require(_baseAmounts[_msgSender()].add(baseAmountForSale) <= _maxBaseAmount, "Purchase Amount should be less than maxBaseAmount");
        require(currentBaseTotalAmount.add(baseAmountForSale) <= _limitBaseAmount, "Total Base Amount shoould be less than baseLimitAmount");
        require(IERC20(_saleToken).balanceOf(address(this)) >= saleAmount, "The contract should have saleAmount with saleToken at least");

        // Update baseAmounts
        _baseAmounts[_msgSender()] = _baseAmounts[_msgSender()].add(baseAmountForSale);

        // TransferFrom baseToken from msgSender to Contract
        IERC20(_baseToken).transferFrom(
            _msgSender(),
            address(this),
            baseAmountForSale
        );

        // Send Sale Token to msgSender
        IERC20(_saleToken).transfer(
            _msgSender(),
            saleAmount
        );

        emit PurchaseToken(_msgSender(), baseAmountForSale, saleAmount);

        return true;
    }
}