/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PaymentManager is Ownable {
    using SafeMath for uint256;
    struct PaymentData {
        bool exists;
        bool isCompleted;
        string referenceId;
        address coinAddress;
        uint256 amountPaid;
    }
    
    uint256 networkGasFee = 0 ether;
    mapping(address => string[]) public allPaymentIdsPerUser;
    mapping(address => mapping(string => PaymentData)) public allPaymentData;
    
    constructor() {
        
    }
    
    
    // --------------------------------------------- //
    //          External Non-View Functions          //
    // --------------------------------------------- //
    
    function setNetworkGasFee(uint256 _amount) external onlyOwner() {
        networkGasFee = _amount;
    }
    
    function initiateNewPayment(string memory _referenceId, address _coinAddress, uint256 _paymentAmount) external payable returns(bool success) {
        require(!getPaymentInformation(_msgSender(), _referenceId).exists, "Payment with given reference Id for given player already exists. Please try with different Id.");
        require(msg.value >= networkGasFee, "Not enough value sent with the transaction.");
        IERC20 paymentCoin = IERC20(_coinAddress);
        require(paymentCoin.allowance(_msgSender(), address(this)) >= _paymentAmount, "Insufficient allowance");
        
        uint256 initialBalance = paymentCoin.balanceOf(address(this));
        paymentCoin.transferFrom(_msgSender(), address(this), _paymentAmount);
        uint256 finalBalance = paymentCoin.balanceOf(address(this));
        
        PaymentData storage paymentData = allPaymentData[_msgSender()][_referenceId];
        paymentData.exists = true;
        paymentData.isCompleted = false;
        paymentData.referenceId = _referenceId;
        paymentData.coinAddress = _coinAddress;
        paymentData.amountPaid = finalBalance.sub(initialBalance);
        
        allPaymentIdsPerUser[_msgSender()].push(_referenceId);
        success = true;
    }
    
    function markPaymentAsComplete(address _playerAddress, string memory _referenceId) external onlyOwner() returns(bool success) {
        PaymentData storage paymentData = allPaymentData[_playerAddress][_referenceId];
        require(paymentData.exists, "Payment with given reference Id for given player already exists. Please try with different Id.");
        require(!paymentData.isCompleted, "The payment has already been completed.");
        
        paymentData.isCompleted = true;
        success = true;
    }
    
    function sendRewardToWinner(address _coinAddress, address _receiveWallet, uint256 _amount) external onlyOwner() {
        IERC20 sendCoin = IERC20(_coinAddress);
        sendCoin.transfer(_receiveWallet, _amount);
    }
    
    
    // --------------------------------------------- //
    //                  View Functions               //
    // --------------------------------------------- //
    
    function getPaymentInformation(address _playerAddress, string memory _referenceId) public view returns(PaymentData memory paymentData) {
        return allPaymentData[_playerAddress][_referenceId];
    }
    
    function getPrepData(address _playerAddress, address _coinAddress) external view returns(uint256, uint256, uint256) {
        IERC20 coin = IERC20(_coinAddress);
        return (coin.balanceOf(_playerAddress), coin.allowance(_playerAddress, address(this)), networkGasFee);
    }
    
    function getAllReferenceIdForPlayer(address _playerAddress) external view returns(string[] memory) {
        return allPaymentIdsPerUser[_playerAddress];
    }
}