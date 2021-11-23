/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function decimals() external pure returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IEverMigrate {
    function migrateTokens(address sourceToken, address toAddress, uint256 amount) external;
    function returnTokens(address sourceToken, address toAddress, uint256 amount) external;
    function tokenMigrateDetails(address sourceToken) external view returns (address targetToken, uint256 ratio);
    function allSupportedTokens() external view returns (address[] memory);
    function allSupportedTokensLength() external view returns (uint256);
    function supportsToken(address sourceToken) external view returns(bool);
    
    event TokenAdded(address fromToken, address toToken, uint256 ratio);
    event TokensMigrated(address fromToken, address toToken, uint256 amountIn, uint256 amountOut);
    event TokensReturned(address token, address toAddress, uint256 amount);
}

contract EverMigrate is IEverMigrate, Context, Ownable {
    using SafeMath for uint256;

    struct TokenDetails {
        address sourceToken;
        address targetToken;
        address devAddress;
        uint256 ratio;
        bool isPresent;
    }

    struct Transaction {
        uint256 amount;
        uint256 timestamp;
        uint32 txnId;
    }

    mapping (address => TokenDetails) private _tokenList;
    address[] private _allTokens;

    
    uint32 private _txnId = 0;
    mapping (address => mapping (address => Transaction[])) private _userTxns;

    constructor() {

    }

    function addTokenDetails(
        address sourceToken,
        address targetToken,
        address devAddress,
        uint256 ratio) external onlyOwner {
        _tokenList[sourceToken] = TokenDetails(sourceToken, targetToken, devAddress, ratio, true);
        _allTokens.push(sourceToken);

        emit TokenAdded(sourceToken, targetToken, ratio);
    }

    function migrateTokens(address sourceToken, address toAddress, uint256 amount) 
        external {
        require(amount > 0, "Amount should be greater than Zero");
        require(toAddress != address(0), "ERC20: transfer to the zero address is not allowed");
        require(supportsToken(sourceToken), "Unsupported sourceToken");

        TokenDetails memory tokenDetails = _tokenList[sourceToken];
        uint256 amountOut = amount
            .mul(10**IERC20(tokenDetails.targetToken).decimals())
            .div(10**IERC20(tokenDetails.sourceToken).decimals())
            .div(tokenDetails.ratio);

        IERC20(tokenDetails.sourceToken).transferFrom(_msgSender(), tokenDetails.devAddress, amount);
        IERC20(tokenDetails.targetToken).transfer(toAddress, amountOut);

        Transaction[] storage userTxns = _userTxns[sourceToken][_msgSender()];
        userTxns.push(
            Transaction({
                amount: amount,
                timestamp: block.timestamp,
                txnId: _txnId
            })
        );
        _userTxns[sourceToken][_msgSender()] = userTxns;

        _txnId = _txnId + 1;

        emit TokensMigrated(tokenDetails.sourceToken, tokenDetails.targetToken, amount, amountOut);
    }

    function userTransactionsLength(address sourceToken, address userAddress) 
        external view returns (uint256) {
        return _userTxns[sourceToken][userAddress].length;
    }

    function userTransaction(address sourceToken, address userAddress, uint256 position)
        external view returns (uint256, uint256, uint32) {
        Transaction storage txn = _userTxns[sourceToken][userAddress][position];
        
        return (txn.amount, txn.timestamp, txn.txnId);
    }
    
    function returnTokens(address sourceToken, address toAddress, uint256 amount)
        external onlyOwner {
        require(amount > 0, "Amount should be greater than Zero");
        require(toAddress != address(0), "ERC20: transfer to the zero address is not allowed");
        require(supportsToken(sourceToken), "Unsupported sourceToken");

        TokenDetails memory tokenDetails = _tokenList[sourceToken];
        IERC20(tokenDetails.targetToken).transfer(toAddress, amount);

        emit TokensReturned(tokenDetails.targetToken, toAddress, amount);
    }
    
    function tokenMigrateDetails(address sourceToken) 
        external 
        view 
    returns (address targetToken, uint256 ratio) {
        require(supportsToken(sourceToken), "Unsupported sourceToken");
        
        TokenDetails storage details = _tokenList[sourceToken];

        targetToken = details.targetToken;
        ratio = details.ratio;
    }

    function allSupportedTokens() external view returns (address[] memory supportedTokens) {
        return _allTokens;
    }

    function allSupportedTokensLength() external view returns (uint256) {
        return _allTokens.length;
    }

    function supportsToken(address sourceToken) public view returns(bool) {
        if (_tokenList[sourceToken].isPresent) return true;

        return false;
    }
}