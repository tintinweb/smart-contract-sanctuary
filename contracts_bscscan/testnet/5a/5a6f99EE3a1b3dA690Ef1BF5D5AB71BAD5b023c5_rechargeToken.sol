/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: Unlicensed
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
    
    constructor()  {}

    function _msgSender() internal view returns (address) {
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

contract rechargeToken is Ownable{
    using SafeMath for uint256;
    
    IBEP20 public BUSD;
    IBEP20 public SCKS;

    uint256 public tokenPercentage = 1000; //1000 means 10%
    uint256 public SCKSbalance; // SCKS deposti balance
    address public receiverAddress = 0x129e510A1dbffaf64C1f039296d077C6E7A14300;

    event OwnerDeposit(address indexed owner, uint256 indexed amount);
    event BUSDDeposti(address indexed user, uint256 indexed depositAmount);
    event Reward(address indexed user, uint256 indexed rewardAmount);
    event RewardPercentage(address indexed owner, uint256 indexed percentage);
    event FailSafe(address indexed token, address indexed to, uint256 indexed amount);
    event Exchange(address indexed user, uint256 indexed depositAmount, uint256 indexed rewardAmount);
    event SetRewardAddress(address indexed owner, address indexed rewardAddress);
    
    constructor(IBEP20 _BUSD, IBEP20 _SCKS){
        BUSD = _BUSD;
        SCKS = _SCKS;
    }
    
    function setRewardAddress(address _receiverAddress)external onlyOwner {
        require(_receiverAddress != address(0x0),"Exchange :: zero address dected");
        receiverAddress = _receiverAddress;
        emit SetRewardAddress(msg.sender, _receiverAddress);
    }
    
    function exchange(uint256 _amount)external {
        require(_amount > 0,"Exchange :: Deposit number of tokens");
        uint256 decimal = BUSDDecimal();
        uint256 scksdecimal = SCKSDecimal();
        uint256 reward = _amount.mul(tokenPercentage).mul(10 ** scksdecimal).div(10 ** decimal).div(100);
        SCKSbalance = SCKSbalance.sub(reward,"Exchange :: SCKS balance exceed");
        safeTransferFrom(msg.sender, _amount);
        safeTransfer(msg.sender, reward);
        
        emit Exchange(msg.sender , _amount, reward);
    }
    
    function setRewardPercentage(uint256 _percentage)external onlyOwner {
        tokenPercentage = _percentage;
        emit RewardPercentage(msg.sender, _percentage);
    }
    
    function SCKSDecimal()internal view returns(uint256 decimals){
        decimals = SCKS.decimals();
    }
    
    function BUSDDecimal()internal view returns(uint256 decimals){
        decimals = BUSD.decimals();
    }
    
    function safeTransfer(address _account, uint256 _amount) internal{
        SCKS.transfer(_account, _amount);
        emit Reward(_account, _amount);
    }
    
    function safeTransferFrom(address _account, uint256 _amount) internal {
        BUSD.transferFrom(_account, receiverAddress, _amount);
        emit BUSDDeposti(_account, _amount);
    }
    
    function adminDeposit(uint256 _amount)external onlyOwner{
        require(_amount > 0,"Exchange :: Deposit a number of tokens");
        SCKSbalance = SCKSbalance.add(_amount);
        
        SCKS.transferFrom(msg.sender, address(this), _amount);
        emit OwnerDeposit(msg.sender, _amount);
    }
    
    function failSafe(address _token,address _to, uint256 _amount)external onlyOwner {
        
        if(_token == address(0x0)){
            payable(msg.sender).transfer(address(this).balance);
            emit FailSafe(address(this), _to, address(this).balance);
        }
        else {
            if(SCKS == IBEP20(_token)){
            SCKSbalance = SCKSbalance.sub(_amount,"FailSafe :: SCKS balance exceed");
            }
            IBEP20(_token).transfer(_to, _amount);
            emit FailSafe(_token, _to, _amount);
        }
    }
}