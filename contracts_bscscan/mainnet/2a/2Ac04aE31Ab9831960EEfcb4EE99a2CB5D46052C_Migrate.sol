/**
 *Submitted for verification at BscScan.com on 2022-01-13
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
    function decimals() external view returns (uint8);
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

contract Migrate is ReentrancyGuard, Ownable{

    mapping(address => uint256) private claimableTokensV2;

    IERC20 public tokenV1 = IERC20(0x956cA51Cc658835ca589EBA83fe0aE12E5b7e5e5); //address of the old version
    IERC20 public tokenV2; //address of the new version

    address public v1TokensRecipient = 0xF2EF98Cd1ad1D76f3a47bafb4fe571795e5d2871;

    bool public migrationStarted;
    bool public claimEnabled;

    uint256 public migrationBalance;

    event TokensV1Deposited(address addr, uint256 amount);
    event TokensV2Claimed(address addr, uint256 amount);

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

    function setClaimEnabled(bool state) external onlyOwner{
        claimEnabled = state;
    }

    /// @notice Updates "tokenV1", "tokenV2" and the "rate"
    /// @param tokenV1addr The address of old version
    /// @param tokenV2addr The address of new version
    function setTokenV1andV2(IERC20 tokenV1addr, IERC20 tokenV2addr) external onlyOwner{
        tokenV1 = tokenV1addr;
        tokenV2 = tokenV2addr;
    }

    /// @notice Withdraws remaining tokens
    function withdrawTokens(IERC20 tokenAdd, uint256 amount) external onlyOwner{
        tokenAdd.transfer(msg.sender, amount * 10**(tokenAdd.decimals()));
    }

    /// @notice Migrates from old version to new one
    ///   User must call "approve" function on tokenV1 contract
    ///   passing this contract address as "sender".
    function depositTokensV1() public nonReentrant(){
        require(migrationStarted == true, 'Migration not started yet');
        require(claimableTokensV2[msg.sender] == 0, "You have already deposited V1");
        uint256 userV1Balance = tokenV1.balanceOf(msg.sender);
        require(userV1Balance > 0, 'You must hold V1 tokens to migrate');
        tokenV1.transferFrom(msg.sender, v1TokensRecipient, userV1Balance);
        migrationBalance += userV1Balance;
        claimableTokensV2[msg.sender] = userV1Balance;
        emit TokensV1Deposited(msg.sender, userV1Balance);
    }

    function claimV2Tokens() external nonReentrant{
        require(claimEnabled, "Claim not available yet");
        require(claimableTokensV2[msg.sender] > 0 ,"No tokens to claim");
        uint256 amount = claimableTokensV2[msg.sender];
        claimableTokensV2[msg.sender] = 0;
        tokenV2.transfer(msg.sender, amount);
        emit TokensV2Claimed(msg.sender, amount);
    }

    function getClaimableTokens() external view returns(uint256){
        return claimableTokensV2[msg.sender];
    }

}