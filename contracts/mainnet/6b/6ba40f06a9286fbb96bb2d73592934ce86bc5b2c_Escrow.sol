/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//Copied from OZ contracts
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//Wrap around Aave oracle
interface IPriceOracleGetter {
  function getAssetPrice(address asset) external view returns (uint256);
}

//Copied from OZ contracts
library SafeERC20 {
   
    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function safeTransfer(IERC20 token,address to,uint256 value) internal {
        require(isContract(address(token)), "Call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(abi.encodeWithSelector(token.transfer.selector, to, value));
        bytes memory returnedData = verifyCallResult(success, returndata, "Call reverted");
        if (returnedData.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "ERC20 operation did not succeed");
        }
    }

    function safeTransferFrom(IERC20 token,address from,address to,uint256 value) internal {
        require(isContract(address(token)), "Call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        bytes memory returnedData = verifyCallResult(success, returndata, "Call to non-contract");
        if (returnedData.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Escrow {
    using SafeERC20 for IERC20;
   
    enum FundingState {
        PAUSED,
        ACTIVE,
        CLOSED,
        REFUND
    }
   
    address public whitelister;
    address public recipient;
    address public owner;
    address public usdc;
    uint256 public lastRecordedETHPrice;
    uint256 public firstWithdrawalLevel;
    uint8 public state;
    bool public isFirstWithdrawalExecuted;
    IPriceOracleGetter public ethUSDCFeed;

    event USDCDeposited(address indexed payee, uint256 indexed amount);
    event USDCWithdrawn(address indexed payee, uint256 indexed amount);
    event Deposited(address indexed payee, uint256 indexed weiAmount);
    event Withdrawn(address indexed payee, uint256 indexed weiAmount);
    event RemovedReservation(address indexed user, uint256 indexed id);
   
    //Map of registered id with their owners
    mapping(uint256 => address) public reservations;
   
    //Map of whitelisted users
    mapping(address => bool) public whitelistedUsers;
   
    //Assets reserved by each users, it returns an unordered list of reserved IDs
    mapping(address => uint256[]) public userReservedAssets;
    mapping(uint256 => uint256) public assetToIndex;

    //Track the USDC and ETH deposited by each users (useful for claimbacks)
    mapping(address => uint256) public ethDeposited;
    mapping(uint256 => uint256) public buyingETHPrice;
    mapping(address => uint256) public usdcDeposited;

    modifier onlyWhitelister {
        require(msg.sender == whitelister, "Caller is not whitelister");
        _;
    }
   
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
   
    modifier onlyRecipient {
        require(msg.sender == recipient, "Caller is not recipient");
        _;
    }
   
    constructor(
        address _priceOracleGetter, //Aave oracle
        address _whitelister, //Who can whitelist users to buy
        address _usdc, //USDC address to be used on the oracle
        address _recipient //Who can withdraw funds from the contract
    ) {
        whitelister = _whitelister;
        usdc = _usdc;
        owner = msg.sender;
        recipient = _recipient;
        firstWithdrawalLevel = 1050000000000000000000000;
        ethUSDCFeed = IPriceOracleGetter(_priceOracleGetter);
        state = uint8(FundingState.ACTIVE);
       _updateETHPrice();
    }
   
    // Owner restricted functions
   
    function setPaused() public onlyOwner {
        _updateETHPrice();
        state = uint8(FundingState.PAUSED);
    }
   
    function setClosed() public onlyOwner {
        _updateETHPrice();
        state = uint8(FundingState.CLOSED);
    }
   
    function setRefund() public onlyOwner {
        _updateETHPrice();
        state = uint8(FundingState.REFUND);
    }

    function setActive() public onlyOwner {
        _updateETHPrice();
        state = uint8(FundingState.ACTIVE);
    }
   
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }
   
    // Whitelister restricted functions
   
    function whitelist(address user, bool value) public onlyWhitelister {
        _updateETHPrice();
        whitelistedUsers[user] = value;
    }
   
    function whitelistInBatch(address[] memory users, bool[] memory values) public onlyWhitelister {
        _updateETHPrice();
        require(users.length == values.length, "Length mismatch");
        for(uint256 i = 0; i < users.length; i++) {
            whitelistedUsers[users[i]] = values[i];
        }
    }

    // Recipient restricted functions
    function firstWithdraw(address payable receiver, uint256 usdcAmount, uint256 ethInWei) public onlyRecipient {
        require(!isFirstWithdrawalExecuted, "Already executed");

        _updateETHPrice();
        uint256 amount = totalValue();
        uint256 totalToWithdraw = usdcAmount + ethInWei;

        require(amount >= firstWithdrawalLevel, "Contract has not recollected enough yet");
        require(totalToWithdraw <= amount, "Wrong amount");
        require(usdcAmount <= IERC20(usdc).balanceOf(address(this)), "Invalid USDC amount");
        require(ethInWei <= address(this).balance, "Invalid ETH amount");

        if(usdcAmount > 0) IERC20(usdc).safeTransfer(receiver, usdcAmount);
        if(ethInWei > 0) _sendValue(receiver, ethInWei);

        isFirstWithdrawalExecuted = true;

        emit Withdrawn(receiver, amount);
    }

    function withdrawETH(address payable receiver) public onlyRecipient {
        _updateETHPrice();
        _validateWithdraw();
       
        emit Withdrawn(receiver, address(this).balance);
        _sendValue(receiver, address(this).balance);
    }
   
    function withdrawUSDC(address receiver) public onlyRecipient {
        _updateETHPrice();
        _validateWithdraw();
       
        emit USDCWithdrawn(receiver, IERC20(usdc).balanceOf(address(this)));
        IERC20(usdc).safeTransfer(receiver, IERC20(usdc).balanceOf(address(this)));
    }
   
    function withdrawAll(address payable receiver) public onlyRecipient {
        _updateETHPrice();
        _validateWithdraw();
       
        emit Withdrawn(receiver, address(this).balance);
        emit USDCWithdrawn(receiver, IERC20(usdc).balanceOf(address(this)));
       
        _sendValue(receiver, address(this).balance);
        IERC20(usdc).safeTransfer(receiver, IERC20(usdc).balanceOf(address(this)));
    }
   
    // Public getters functions to retrieve data
   
    function totalValue() public view returns (uint256 funded) {
        uint256 etherAmount = address(this).balance;
        uint256 unit = 1e18;
        uint256 oneEtherPriceInUSD = unit * unit / lastRecordedETHPrice;
        uint256 amountInUSD = etherAmount * oneEtherPriceInUSD / unit;
       
        funded = amountInUSD + IERC20(usdc).balanceOf(address(this))*1e12;
        return funded;
    }
   
    function getReservationOwner(uint256 id) public view returns (address reservationOwner) {
        reservationOwner = reservations[id];
        return reservationOwner;
    }
   
    function getReservedAsset(address user, uint256 index) public view returns (uint256 id) {
        require(index < userReservedAssets[user].length, "Index out of range");
        id = userReservedAssets[user][index];
        return id;
    }
   
    function getNumberOfReservedAssets(address user) public view returns (uint256 value) {
        value = userReservedAssets[user].length;
        return value;
    }
   
    function getUSDPrice(uint256 id) public pure returns (uint256) {
        if(id < 7000) return uint256(3500);
        else if(id >= 7000 && id < 19000) return uint256(2900);
        else if(id >= 19000 && id < 29000) return uint256(2500);
        else if(id >= 29000 && id < 41000) return uint256(1600);
        else if(id >= 41000 && id < 58000) return uint256(995);
        else revert("ID is out of range");
    }
   
    function checkIDValidity(uint256 id) public pure returns(bool) {
       
        if (id >= 58000) return false;
         
        uint256 base;

        if (id < 1000) {
            base = id / 100;
            if (6 <= base) {
                return false;
            }
        } else if (id < 10000) {
            base = ((id / 10) % 100) / 10;
            if (6 <= base) {
                return false;
            }
        } else {
            base = (id / 100) % 10;
            if (6 <= base) {
                return false;
            }
        }

        return true;
    }

    // User interacting functions

    function buyWithUSDC(uint256 id) public {
        _updateETHPrice();
        _buyWithUSDC(id);
    }

    function buyWithUSDCBatch(uint256[] memory ids) public {
        _updateETHPrice();
        for(uint i = 0; i < ids.length; i++) {
            buyWithUSDC(ids[i]);
        }
    }

    function buyWithEther(uint256 id) public payable {
        _updateETHPrice();
        uint256 amount = msg.value;
        uint256 leftover = _buyWithEther(id, amount);
        if(leftover > 0) _sendValue(payable(msg.sender), leftover);
    }

    function buyWithEtherBatch(uint256[] memory ids) public payable {
        _updateETHPrice();
        uint256 amount = msg.value;
        uint256 leftover;
        for(uint i = 0; i < ids.length; i++) {
            leftover = _buyWithEther(ids[i], amount);
            amount = leftover;
        }
        if(leftover > 0) _sendValue(payable(msg.sender), leftover);
    }
   
    // Create a receive function that reverts to avoid having people sending ETH directly
   
    function claimBackUSDC(uint256 id) public {
        _validateClaimBack(id);
        _updateETHPrice();
       
        uint256 ticketPrice = getUSDPrice(id);
        uint256 usdcUnits = 1e6;
        uint256 priceInERC20Units = ticketPrice * usdcUnits;
       
        require(usdcDeposited[msg.sender] >= priceInERC20Units, "Insufficient funds");

        // Delete reservation and give back to the user his funds for this ID
        usdcDeposited[msg.sender] -= priceInERC20Units;
        _deleteReservation(id);
       
        IERC20(usdc).safeTransfer(msg.sender, priceInERC20Units);
    }
   
    function claimBackETH(uint256 id) public {
        _validateClaimBack(id);
        _updateETHPrice();
       
        uint256 pricePaid = buyingETHPrice[id];
        require(pricePaid > 0, "No valid reservation");
        require(pricePaid <= address(this).balance, "Insufficient funds");

        ethDeposited[msg.sender] -= pricePaid;
        buyingETHPrice[id] = 0;
        _deleteReservation(id);
       
        _sendValue(payable(msg.sender), pricePaid);
    }
   
    // internal functions
   
    function _sendValue(address payable receiver, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = receiver.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
   
    function _deleteReservation(uint256 id) internal {
        reservations[id] = address(0);

        uint256 lastAsset = userReservedAssets[msg.sender][userReservedAssets[msg.sender].length - 1];
        uint256 position = assetToIndex[id];
        userReservedAssets[msg.sender][position] = lastAsset;
        assetToIndex[lastAsset] = position;
        userReservedAssets[msg.sender].pop();         
        assetToIndex[id] = 0;

        emit RemovedReservation(msg.sender, id);
    }
   
    function _validateWithdraw() internal view {
        require(state == uint8(FundingState.CLOSED), "System state is not closed");
    }
   
    function _validateDeposit(uint256 id) internal view {
        require(state == uint8(FundingState.ACTIVE), "System state is not active");
        require(whitelistedUsers[msg.sender], "User is not whitelisted");
        require(reservations[id] == address(0), "ID already taken");
        require(checkIDValidity(id), "Invalid or reserved ID");
    }
   
    function _validateClaimBack(uint256 id) internal view {
        require(state == uint8(FundingState.REFUND), "System state is not in refund");
        require(whitelistedUsers[msg.sender], "User is not whitelisted");
        require(reservations[id] == address(msg.sender), "Msg sender is not the owner");
        require(checkIDValidity(id), "Invalid or reserved ID");
    }
   
    function _updateETHPrice() internal {
        // This will give USDC price in ETH (wei units)
        // Being 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 the USDC address
        // The value returned is the value in wei of 1 USDC ie 1 usd = 227260770000000
        lastRecordedETHPrice = ethUSDCFeed.getAssetPrice(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    function _buyWithEther(uint id, uint amount) internal returns(uint256 leftover) {
        require(amount > 0, "Zero amount not allowed");

        _validateDeposit(id);
       
        uint256 unit = 1e18;
        uint256 oneEtherPriceInUSD = unit * unit / lastRecordedETHPrice;
        uint256 amountInUSD = amount * oneEtherPriceInUSD / unit;

        uint256 ticketPrice = getUSDPrice(id);

        require(
            amountInUSD >= ticketPrice*unit,
            "Insufficient ETH amount"
        );

        if(amountInUSD > ticketPrice*unit) leftover = ((amountInUSD - ticketPrice*unit)*unit) / oneEtherPriceInUSD;

        uint deposited = leftover == 0 ? amount : ticketPrice*unit*unit/oneEtherPriceInUSD;

        reservations[id] = address(msg.sender);
        buyingETHPrice[id] = oneEtherPriceInUSD;
        userReservedAssets[msg.sender].push(id);
        assetToIndex[id] = userReservedAssets[msg.sender].length - 1;
        ethDeposited[msg.sender] += deposited;
        buyingETHPrice[id] = deposited;

        emit Deposited(msg.sender, deposited);
    }

    function _buyWithUSDC(uint id) internal {
        _validateDeposit(id);
       
        uint256 ticketPrice = getUSDPrice(id);
        uint256 usdcUnits = 1e6;
        uint256 priceInERC20Units = ticketPrice * usdcUnits;
       
        require(IERC20(usdc).allowance(msg.sender, address(this)) >= priceInERC20Units, "Contract has not enough allowance");
       
        IERC20(usdc).safeTransferFrom(msg.sender, address(this), priceInERC20Units);
       
        usdcDeposited[msg.sender] += priceInERC20Units;
        reservations[id] = address(msg.sender);
        userReservedAssets[msg.sender].push(id);
        assetToIndex[id] = userReservedAssets[msg.sender].length - 1;

        emit USDCDeposited(msg.sender, priceInERC20Units);
    }
}