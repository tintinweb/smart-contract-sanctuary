/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

interface IBEP20 {
    
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

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

  
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Context {
    
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
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

    constructor() internal {
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

contract BudaStake is Ownable{
    using SafeMath for uint256;

    IBEP20 public budaCoin;
    uint256 private UpdateBlock;
    uint256 private RewardPerBlock;
    
    struct UserDetails{
        uint256 amount;
        uint256 depositBlockNumber;
    }

    mapping(address => UserDetails)public userDetails;

    event Deposit(address depositor, uint256 amount);
    event Withdraw(address depositor, uint256 amount, uint256 Rewards);
    event AdminDeposit(address owner, uint256 amount);
    event SetRewardPerBlock(address owner, uint256 percentage);
    event Filesafe(address receiver, uint256 amount);
    
    constructor(IBEP20 _budaCoin,uint256 _RewardPerBlock)public{
        budaCoin = _budaCoin;
        RewardPerBlock = _RewardPerBlock;
    }
    
    function rewardPerBlock()public view returns(uint256){
        return RewardPerBlock;
    }
    
    function setRewardPerBlock(uint256 _RewardPerBlock)public onlyOwner{
        RewardPerBlock = _RewardPerBlock;
        emit SetRewardPerBlock(msg.sender, _RewardPerBlock);

    }

    function deposit(uint256 _amount)public{
        require(_msgSender() != address(0) && _amount > 0, "BudaStaking:: Give numbers of tokens");
        safeBudaTransferFrom(msg.sender,address(this),_amount);
        userDetails[msg.sender].amount = userDetails[msg.sender].amount.add(_amount); 
        userDetails[msg.sender].depositBlockNumber = block.number;

        emit Deposit(msg.sender, _amount);
    }
    
    function totalDepositorBalance() public view returns(uint256){
        return budaCoin.balanceOf(address(this)).sub(userDetails[owner()].amount);
    }
    
    function totalRewardsAvailable() public view returns(uint256){
        require(userDetails[owner()].amount != 0 ,"BudaStaking :: Reward Balance Zero");
        return userDetails[owner()].amount;
    }
        
    function calculateRewards(address _account)public view returns(uint256){
        uint256 _amount = userDetails[_account].amount;
        uint256 blocks = block.number - userDetails[_account].depositBlockNumber;
        uint256 rewards = _amount.mul(RewardPerBlock).div(1e9).div(100).mul(blocks).mul(totalRewardsAvailable()).div(totalDepositorBalance());
        return rewards;
    }
    
    function withdraw(uint256 _amount)public returns(bool){
        require(userDetails[msg.sender].amount >= _amount, "BudaStaking:: withdraw amount exceeds the max Token Amount");
        uint256 reward = calculateRewards(msg.sender);
        safeBudaTransfer(msg.sender,_amount.add(reward));
        userDetails[msg.sender].amount = userDetails[msg.sender].amount.sub(_amount);
        userDetails[owner()].amount = userDetails[owner()].amount.sub(reward);
        userDetails[msg.sender].depositBlockNumber = block.number;

        emit Withdraw(msg.sender, _amount, reward);

        return true;
    }
    
    function safeBudaTransferFrom(address _from, address _to, uint256 _amount)internal {
        budaCoin.transferFrom(_from,_to, _amount);
    }
    
    function safeBudaTransfer(address _to, uint256 _amount) internal {
        budaCoin.transfer(_to, _amount);
    }
    
    function adminDeposit(uint256 _amount)public onlyOwner{
        budaCoin.transferFrom(msg.sender,address(this),_amount);
        userDetails[owner()].amount = userDetails[owner()].amount.add(_amount);
        emit AdminDeposit(msg.sender, _amount);
    }
    
    function failSafe(address _to,uint256 _amount)public onlyOwner{
        budaCoin.transfer(_to,_amount);
        emit Filesafe(_to, _amount);
    }
}