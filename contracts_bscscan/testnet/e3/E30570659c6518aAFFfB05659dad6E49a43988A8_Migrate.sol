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


interface IERC20 {
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard {
    bool private _notEntered;

    constructor ()  {
        _notEntered = true;
    }
    
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        _notEntered = true;
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


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    
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
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

//Made by FreezyEx
contract Migrate is ReentrancyGuard, Context, Ownable{
    using SafeMath for uint256;
    
    mapping(address => bool) private claimed;
    address public immutable deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    IERC20 public tokenV2;
    IERC20 public tokenV1;
    uint256 public rate;
    bool public migrationStarted;
    
    event MigrateToV2(address addr, uint256 amount);
    
    constructor(IERC20 tokenAddressV1, IERC20 tokenAddressV2, uint256 _rate) {
        tokenV2 = tokenAddressV2;
        tokenV1 = tokenAddressV1;
        rate = _rate;
    }
    
    function startMigration() external onlyOwner{
        migrationStarted = true;
    }
    
    function stopMigration() external onlyOwner{
        migrationStarted = false;
    }
    
    function setTokenV1andV2(IERC20 tokenV1addr, IERC20 tokenV2addr, uint256 _rate) external onlyOwner{
        tokenV1 = tokenV1addr;
        tokenV2 = tokenV2addr;
        rate = _rate;
    }
    
    function withdrawTokens(uint256 amount) external onlyOwner{
        tokenV2.transfer(msg.sender, amount);
    }
    
    
    function migrateToV2(uint256 v1amount) public {
        require(migrationStarted == true, 'Migration not started yet');
        uint256 amount = v1amount * tokenV1.decimals();
        uint256 userV1Balance = tokenV1.balanceOf(msg.sender);
        require(userV1Balance >= amount, 'You must hold V1 tokens to migrate');
        uint256 amtToMigrate = amount.div(rate);
        require(tokenV2.balanceOf(address(this)) >= amtToMigrate, 'No enough V2 liquidity');
        tokenV1.transferFrom(msg.sender, deadWallet, amount);
        tokenV2.transfer(msg.sender, amtToMigrate);
        emit MigrateToV2(msg.sender, amtToMigrate);
    }
    
}

