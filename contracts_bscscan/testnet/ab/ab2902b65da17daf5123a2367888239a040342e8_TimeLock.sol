/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}


abstract contract ReentrancyGuard {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

   
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}

contract TimeLock is Context, Ownable{
    using SafeMath for uint256;
    
    mapping(address => uint256) _balances;
    mapping(address => uint256) checkAmount;
    mapping(address => bool) checkReceiver;
    mapping(address => uint256) checkLock;

    IERC20 public _token;
    uint256 public availableTokens;
    address internal receiver;
    uint256 internal amountToSend;
    uint256 internal relaseTime;
    
    event TokensLocked(address master, address beneficiary, uint256 _amount, uint256 time);
    event SentTokens(address beneficiary, uint256 amount);
    constructor (IERC20 token)  {
        _token = token;
    }
    
    function setAvailableTokens(uint256 amount) external onlyOwner {
        availableTokens = amount;
    }
    
    function setLock(address _receiver, uint256 _amountToSend, uint256 releaseTime) external onlyOwner {
        availableTokens = _token.balanceOf(address(this));
        require(releaseTime > block.timestamp, 'duration should be > 0');
        checkAmount[_receiver] = checkAmount[_receiver].add(_amountToSend);
        checkLock[_receiver] = checkLock[_receiver].add(releaseTime);
        checkReceiver[_receiver] = true;
        emit TokensLocked(_msgSender(), _receiver, _amountToSend, relaseTime);
    }

    function releseToken() public {
        require(block.timestamp >= checkLock[msg.sender]);
        require(checkReceiver[msg.sender] == true);
        require(amountToSend == checkAmount[msg.sender]);
        availableTokens = availableTokens - amountToSend;
        _token.transfer(msg.sender, amountToSend);
        emit SentTokens(msg.sender, amountToSend);

    }
    
    function _checkReceiver(address _address) public view returns(bool){
        return checkReceiver[_address];
    }
    
    function _checkAmount(address _address) public view returns(uint256){
        return checkAmount[_address];
    }
    
    function _checkLock(address _address) public view returns(uint256){
        return checkLock[_address];
    }
    
    function balanceOf(address _address) public view returns(uint256){
        return _balances[_address];
        
    }
    
    function takeTokens(IERC20 tokenAddress)  external onlyOwner {
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(msg.sender, tokenAmt);
    }
}