/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

pragma solidity ^0.8.9;
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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns(uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract ClaimToken is Ownable, ReentrancyGuard{
    
    uint256 public timeToWait;
    mapping (address => uint256) public tokensToBeClaimed;
    
    address public token;
    uint256 private decimals;
    
    event SwapRecorded(uint256 weiAmt, uint256 tokensAmt, address user);
    
    constructor(address _token, uint256 _timeToWait) {
        timeToWait = _timeToWait;
        token = _token;
        decimals = IERC20(_token).decimals();
    }
    
    function claim() external nonReentrant{
        require(tokensToBeClaimed[msg.sender] > 0, "No tokens to claim");
        require(tokensToBeClaimed[msg.sender] <= IERC20(token).balanceOf(address(this)), "No enough tokens in contract");
        require( block.timestamp > timeToWait, "You must wait : timeToWait");
        uint256 amount = tokensToBeClaimed[msg.sender];
        tokensToBeClaimed[msg.sender] = 0;
        IERC20(token).transfer(msg.sender, amount);
    }
    
    
    function setTimeToWait(uint256 amount) external onlyOwner{
        timeToWait = amount;
    }

    function getClaimAmount(address user) external view returns(uint256){
        return tokensToBeClaimed[user];
    }

    function withdrawBNB() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function rescueBep20 (address tokenAddress) external onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender,  IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    function setClaimAmounts(address[] memory recipients,uint256[] memory amount) public onlyOwner{
        require(recipients.length == amount.length, "Length Not Equal");
        for(uint256 i = 0; i < recipients.length; i++){
            tokensToBeClaimed[recipients[i]] = amount[i];
        }
    }
    
}