/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity ^0.5.0;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
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

    function sub( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) 
    {
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

    function div( uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    // function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)external returns (bool);

    function allowance(address owner, address spender)  external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(  address sender, address recipient, uint256 amount ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,  address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal  pure returns (address payable)
    {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal 
    {
        require( address(this).balance >= amount,  "Address: insufficient balance" );
        (bool success, ) = recipient.call.value(amount)("");
        require( success,  "Address: unable to send value, recipient may have reverted" );
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer( IERC20 token, address to,  uint256 value ) internal 
    {
        callOptionalReturn(  token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(   IERC20 token,address from, address to,  uint256 value) internal
     {
        callOptionalReturn(  token,  abi.encodeWithSelector(token.transferFrom.selector, from, to, value)  );
    }

    function safeApprove(  IERC20 token, address spender,uint256 value ) internal {
        require( (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn( token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn( token, abi.encodeWithSelector(token.approve.selector,   spender, newAllowance));
    }

    function safeDecreaseAllowance( IERC20 token, address spender,uint256 value ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub( value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(  token,  abi.encodeWithSelector( token.approve.selector,  spender,newAllowance) );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
           

            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


contract StakeManager is Ownable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 startTime;
    
    IERC20 public WDCS;
    
    uint256 public rewardInterval = 1 minutes;
    
    uint rewardRate;
    
    mapping(address => mapping(string => uint256)) public userRewardPerTokenPaid;
     //address _staking,
    constructor(address _wdcsAdd, uint256 _startTime) public {
        WDCS = IERC20(_wdcsAdd);
        startTime = _startTime;
    }
    
    modifier checkStart(){
        require(block.timestamp >= startTime,"TETHER_MINT_Pool not started yet.");
        _;
    }

    
    
    function calculateReward(address _address, uint256 _minutes) internal returns(uint256)
    {
        require(_minutes >= 1,'Invalid');
        return  (WDCS.balanceOf(_address).div(10000)).mul(_minutes);
    }
    function withdrawStake() external
    {
        
    }
    function withdrawRewards(address _address) external checkStart returns(uint256)
    {
        uint256 timeReward =  now.sub(startTime,'Invalid time');
        
        require(timeReward >= rewardInterval,'Invalid Time');

        
        if(userRewardPerTokenPaid[_address]['lastRewardCount'] >= 1)
        {
            return 0;
           // uint256 rewards =  calculateReward(_address,timeReward);
            //require(rewards >= 1,'Not enough reward to withdraw');
            //uint256 leftTimeReward = block.timestamp.sub(lastTimeRewarded[_msgSender()]);
        }
        else
        {
            uint256 rewards =  calculateReward(_address,timeReward);
            WDCS.transfer(_address,rewards);
            return rewards;
            //uint256 TimeReward =  now.sub(startTime,'Invalid time');
            
        }
        
    }
    
    
    
     
}