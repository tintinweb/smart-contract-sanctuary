/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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

/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
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

contract MigrateToken is ReentrancyGuard, Context, Ownable{

    mapping(address => bool) private claimed;
    address public immutable deadWallet = 0x000000000000000000000000000000000000dEaD;

    IERC20 public tokenV1; //address of the old version
    IERC20 public tokenV2; //address of the new version

    bool public migrationStarted;

    /// @notice Emits event every time someone migrates
    event MigrateToV2(address addr, uint256 amount);

    /// @param tokenAddressV1 The address of old version
    /// @param tokenAddressV2 The address of new version
    constructor(IERC20 tokenAddressV1, IERC20 tokenAddressV2) {
        tokenV2 = tokenAddressV2;
        tokenV1 = tokenAddressV1;
    }

    /// @notice Enables the migration
    function startMigration() external onlyOwner{
        require(migrationStarted == false, "Migration is already enabled");
        migrationStarted = true;
    }

    /// @notice Disable the migration
    function stopMigration() external onlyOwner{
        require(migrationStarted == true, "Migration is already disabled");
        migrationStarted = false;
    }


    /// @notice Withdraws remaining tokens
    function withdrawTokens() external onlyOwner{
        tokenV2.transfer(msg.sender, tokenV1.balanceOf(address(this)) );
        tokenV1.transfer(msg.sender, tokenV1.balanceOf(address(this)) );
    }
        /// @notice Withdraws remaining tokens
    function withdrawV2Tokens() external onlyOwner{
        tokenV2.transfer(msg.sender, tokenV1.balanceOf(address(this)) );
    }
            /// @notice Withdraws remaining tokens
    function withdrawV1Tokens() external onlyOwner{
        tokenV1.transfer(msg.sender, tokenV1.balanceOf(address(this)) );
    }
    

    /// @param v1amount The amount of tokens to migrate
    /// @notice Migrates from old version to new one
    ///   User must call "approve" function on tokenV1 contract
    ///   passing this contract address as "sender".
    ///   Old tokens will be sent to burn
    function migrateToV2(uint256 v1amount) public nonReentrant(){
        require(migrationStarted == true, 'Migration not started yet');
        uint256 amount = v1amount * 10 ** tokenV1.decimals();
        uint256 userV1Balance = tokenV1.balanceOf(msg.sender);
        require(userV1Balance >= amount, 'You must hold V1 tokens to migrate');
        uint256 amtToMigrate = v1amount * 10 ** tokenV2.decimals();
        require(tokenV2.balanceOf(address(this)) >= amtToMigrate, 'No enough V2 liquidity');
        tokenV1.transferFrom(msg.sender, address(this), amount);
        tokenV2.transfer(msg.sender, amtToMigrate);
        emit MigrateToV2(msg.sender, amtToMigrate);
    }

}