/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IpreSale{
  function intialize(uint256 preSaleShare, address IGLXtoken) external;
}

contract IglooxPresale is Ownable , Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public tokenPerAVAX;
    uint256 public startTime;
    uint256 public presaleAmount;
    uint256 public currentPresaleAmount;
    uint256 public presaleBalance;
    uint256 public intialTime;
    uint256 public monthlyPercentage = 5;
    address payable public wallet;
    IERC20 public IGLX;
    bool public intilialized;

    event SetWallet(address indexed owner, address newWalletAddress);
    event SetTokenPerAvax(address indexed owner, uint256 newTokenAmount);
    event BuyTokens(address indexed user, uint256 AVAXamount, uint256 tokenAmount);
    event Emergency(address indexed owner, address receiver,address tokenAddress, uint256 tokenAmount);

    constructor(uint256 _tokenPerAVAX, address payable _wallet) {
        tokenPerAVAX = _tokenPerAVAX;
        wallet = _wallet;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function UnPause() external onlyOwner {
        _unpause();
    }

    function updateIGLX(address _newIGLX) external onlyOwner {
        IGLX = IERC20(_newIGLX);
    }

    function updatePercentage(uint256 _newPercentage) external onlyOwner {
        monthlyPercentage = _newPercentage;
    }

    function updateWallet(address newWalletAddress) external whenNotPaused onlyOwner {
        wallet = payable(newWalletAddress);
        emit SetWallet(msg.sender, newWalletAddress);
    }

    function updateTokenPerAvax(uint256 _tokenAmount) external whenNotPaused onlyOwner {
        tokenPerAVAX = _tokenAmount;
        emit SetTokenPerAvax(msg.sender, _tokenAmount);
    }

    function intialize(uint256 _preSaleAmount, address _iglooxToken ) external {
        require(!intilialized,"already intilialized");
        presaleAmount = _preSaleAmount;
        currentPresaleAmount = presaleAmount;
        IGLX = IERC20(_iglooxToken);
        intialTime = block.timestamp;
        intilialized = true;                         
    } 

    function buyToken() external nonReentrant whenNotPaused payable {
        require(intialTime.add(180 days) < block.timestamp,"Presale time not reached");   
        if(startTime.add(30 days) < block.timestamp) {
        
            uint256 count = block.timestamp.sub(startTime).div(30 days);
            if(startTime.add(30 days) <= block.timestamp){
               startTime = startTime.add(30 days).mul(count); 
            }
            if(startTime == 0) { 
                 count = count + 1; 
                 startTime = startTime = intialTime.add(180 days);
            } 
           
            uint256 tokens = presaleAmount.mul(monthlyPercentage).div(100).mul(count);
         
            presaleBalance += tokens;
          
            currentPresaleAmount = currentPresaleAmount.sub(tokens);
          
        }
        uint256 tokenAmount = tokenPerAVAX.mul(msg.value).div(1e18);
      
        require(presaleBalance >= tokenAmount,"Monthly presale finished");
        presaleBalance -= tokenAmount;
       
        IGLX.transfer(msg.sender, tokenAmount);
        require(wallet.send(msg.value),"wallet transaction failed");

        emit BuyTokens(msg.sender, msg.value, tokenAmount);
    }

    function emergencySafe(address _token,address _to, uint256 _tokenAmount) external onlyOwner {
        if(_token == address(0x0)){
            require(payable(_to).send(_tokenAmount),"AVAX transaction failed");
        } else {
            IERC20(_token).transfer(_to, _tokenAmount);
        }

        emit Emergency(msg.sender, _to, _token, _tokenAmount); 
    }
}