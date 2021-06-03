pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

// "SPDX-License-Identifier: Apache License 2.0"
// [[0xdE288bC0fCFe25D30Bad8401E70c3183A63F1893, 1619707311, 10000000000000000000]]

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./iIncentives.sol";

contract PrivateSale is Ownable,ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct LockIInfo{
        uint256 lockPeriod;
        uint256 amount;
    }
    struct LockIInfoExt{
        address user;
        uint256 lockPeriod;
        uint256 amount;
    }

    IERC20  public saleToken;
    IIncentives public incentivesContract;
    mapping(address => LockIInfo) internal _whitelist;

    address lockContractAddress;
    address incentivesTokenAddress;

    event Distribute(uint256 amount, uint256 unlockTime, address buyer);

    constructor(address _lockContract,
        address _incentivesContract,
        address _incentivesTokenAddress,
        address _saleToken)
    {
        saleToken = IERC20(_saleToken);
        lockContractAddress = _lockContract;
        incentivesContract = IIncentives(_incentivesContract);
        incentivesTokenAddress = _incentivesTokenAddress;
    }

    function addToWhiteList(LockIInfoExt[] calldata _newBuyers) external onlyOwner {
        for (uint256 i = 0; i < _newBuyers.length; i++) {
            _whitelist[_newBuyers[i].user]=LockIInfo(_newBuyers[i].lockPeriod,_newBuyers[i].amount);
        }     
    }
    
    function addToWhiteList1(        
        address user,
        uint256 lockPeriod,
        uint256 amount) external onlyOwner {
        _whitelist[user]=LockIInfo(lockPeriod, amount);
    }

    function saleInfo(address user)public view returns(LockIInfo memory){
        return _whitelist[user];
    }

    function available() public view returns(uint256){
        return saleToken.balanceOf(address(this));
    }

    function withdrawSaleToken(uint256 amount) external onlyOwner {
        require(amount>0 && amount<=available(),"amount is incorrect!");
        saleToken.safeTransfer(address(msg.sender), amount);
    }

    /**
     * @notice Buy sell token.
     */
    function distribute() external nonReentrant{

        require(_whitelist[msg.sender].amount > 0,"Is not available for this account");

        uint256 balance = saleToken.balanceOf(address(this));
        uint256 distributeTokenAmount = _whitelist[msg.sender].amount;
         _whitelist[msg.sender].amount=0;

        require(balance >= distributeTokenAmount, "Not enough tokens in the contract");

        saleToken.safeTransfer(address(incentivesContract), distributeTokenAmount);
        uint256 unlock_time = _whitelist[msg.sender].lockPeriod;
        incentivesContract.lockIncentives(
                lockContractAddress,incentivesTokenAddress,distributeTokenAmount,unlock_time);

        emit Distribute(distributeTokenAmount, unlock_time, msg.sender);
    }
}