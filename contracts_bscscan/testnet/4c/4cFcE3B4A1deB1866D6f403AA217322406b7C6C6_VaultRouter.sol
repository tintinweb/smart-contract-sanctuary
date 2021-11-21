// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ReentrancyGuard.sol";
import "./Worker.sol";
import './TransferHelper.sol';
import './IAlpacaVault.sol';
import './IShareToken.sol';
import "./Operatable.sol";

contract VaultRouter is Operatable, ReentrancyGuard
{
    address public WorkerAddress;
    address public ShareTokenAddress;
    address public UsdAddress;
    address[] public RegisteredUsers;
    
    event TokenAddressUpdated(address indexed previousTokenAddress, address indexed newTokenAddress);
    event WorkerAddressUpdated(address indexed previousWorkerAddress, address indexed newWorkerAddress);
    event UsdAddressUpdated(address indexed previousUsdAddress, address indexed newUsdAddress);
    
    modifier onlyRegisteredUsers() 
    {
        bool flag = false;
        for (uint i; i< RegisteredUsers.length;i++){
          if (RegisteredUsers[i]== _msgSender()){
              flag = true;
          }
        }
        require(flag, "VaultRouter: caller is not a registered user");
        _;
    }
    
    function Deposit(uint256 amount) public onlyRegisteredUsers nonReentrant
    {
        TransferHelper.safeTransferFrom(UsdAddress, _msgSender(), WorkerAddress, amount);
        IShareToken(ShareTokenAddress).mint(_msgSender(), amount);
    }
    function WithDraw(uint256 amount) public onlyRegisteredUsers nonReentrant
    {
        require(IShareToken(UsdAddress).balanceOf(WorkerAddress) >= amount, "VaultRouter: WithDraw failed. Insufficient cash.");
        require(IShareToken(ShareTokenAddress).balanceOf(_msgSender()) >= IShareToken(ShareTokenAddress).AmountToShare(amount),
            "VaultRouter: WithDraw failed. Insufficient share.");
        IShareToken(ShareTokenAddress).burn(_msgSender(), amount);
        Operatable(WorkerAddress).emergencyWithdraw(UsdAddress, _msgSender(), amount);
    }
    
    function EmergencyWithdrawToken(address token, address to, uint256 amount) public onlyOwner{
        Operatable(WorkerAddress).emergencyWithdraw(token, to,  amount);
    }
    function UpdateTokenVal(uint256 val) public onlyOperator{
        IShareToken(ShareTokenAddress).updateShareVal(val);
    }
    function SetShareTokenAddress(address newTokenAddress) public onlyOperator {
        require(newTokenAddress != address(0), "Operatorable: new tokenAddress is the zero address");
        _updateTokenAddress(newTokenAddress);
    }
   function SetUsdAddress(address newUsdAddress) public onlyOperator {
        require(newUsdAddress != address(0), "Operatorable: new UsdAddress is the zero address");
        _updateUsdAddress(newUsdAddress);
    }
    function SetWorkerAddress(address newWorkerAddress) public onlyOperator {
        require(newWorkerAddress != address(0), "Operatorable: new workerAddress is the zero address");
        _updateWorkerAddress(newWorkerAddress);
    }
    function SetRegisteredUsersAddress(address[] calldata registeredUsers) public onlyOperator
    {
        RegisteredUsers = registeredUsers;
    }
    function UpdateWorkerOperator(address newOperator) public onlyOwner{
        Operatable(WorkerAddress).updateOperator(newOperator);
    }
    function TransferTokenAndWorkerOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0), "VaultRouter: new owner is address zero." );
        Operatable(ShareTokenAddress).transferOwnership(newOwner);
        Operatable(WorkerAddress).transferOwnership(newOwner);
    }
     /**
     * @dev Update tokenAddress of the contract
     * Internal function without access restriction.
     */
    function _updateTokenAddress(address newTokenAddress) internal{

        address previousTokenAddress = ShareTokenAddress;
        ShareTokenAddress = newTokenAddress;
        emit TokenAddressUpdated(previousTokenAddress, ShareTokenAddress);
    }
    
    /**
     * @dev Update WorkerAddress of the contract
     * Internal function without access restriction.
     */
    function _updateWorkerAddress(address newWorkerAddress) internal{

        address previousWorkerAddress = WorkerAddress;
        WorkerAddress = newWorkerAddress;
        emit TokenAddressUpdated(previousWorkerAddress, WorkerAddress);
    }
    
    /**
     * @dev Update UsdAddress of the contract
     * Internal function without access restriction.
     */
    function _updateUsdAddress(address newUsdAddress) internal{

        address previousUsdAddress = UsdAddress;
        UsdAddress = newUsdAddress;
        emit TokenAddressUpdated(previousUsdAddress, UsdAddress);
    }
    
    
}