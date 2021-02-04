/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint(address account, uint256 amount) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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

contract HDUDPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public hdudStaking;
    modifier onlyHdudStaking(){
        require(hdudStaking == msg.sender);
        _;
    }
    function setHdudStaking(address _addr) public onlyOwner {
        hdudStaking = _addr;
    }
    
    struct DepositInfo {
        uint amount;
        uint rewardDebt;
        uint stakeTime;
        uint amountETH;
    }
    struct PoolInfo {
        address lpToken;
        uint startTime;
        uint endTime;
        uint lastRewardTime;
        uint curReward;
        uint curTotalStaking;
        uint amountLimit;
        uint amountPerSec;
    }

    struct UserInfo {
        address referrer;
        uint dynamicReward;
        uint staticWd;
        uint dynamicWd;
        uint amountETHTotal;
    }
    
    address public usdtTokenAddr = 0xb42D69b7BD3cDd2D60bdfA0ca0763A32B3bb285f;
    address public wethTokenAddr = 0xbF642e1F070f1A7eF8dc9F8d5Ef89e564680aB0f;
    address public usdtWethPairAddr = 0xD3606a2A953bc716a835D15a3F907cC72f732802;

    address public hdudTokenAddr = 0x468aFDb15dF62D2B109a7aecd7f42F63f01Df02C;

    mapping (address => UserInfo) public userInfoes;
    mapping (uint => mapping (address => mapping (uint => DepositInfo))) public depositInfoes;
    mapping (uint => mapping (address => uint)) public depositCounts;
    PoolInfo[] public poolInfoes;

    constructor () public {
        initPool();
    }
    
    function initPool() private{
        poolInfoes.push(PoolInfo({
            lpToken: 0x1F331cCd7cFdCF68C2C2f78391b57a31ab335c90,
            startTime: 1612273254,
            // endTime: uint(1612087501).add(uint(180).mul(86400)),
            endTime: uint(1612273254).add(uint(180).mul(86400)),
            lastRewardTime: 0,
            curReward: 0,
            curTotalStaking: 0,
            amountLimit: 9600 ether,
            amountPerSec: uint(9600 ether).div(180).div(86400)
        }));
        poolInfoes.push(PoolInfo({
            lpToken: 0xD3bAF49D59C6c02D37c9BdA0f4c15058608f39d0,
            startTime: 1612273254,
            // endTime: uint(1612087501).add(uint(180).mul(86400)),
            endTime: uint(1612273254).add(64800),
            lastRewardTime: 0,
            curReward: 0,
            curTotalStaking: 0,
            amountLimit: 7200 ether,
            amountPerSec: uint(7200 ether).div(180).div(86400)
        }));
    }
    
    function setPool(uint _pid,uint _reward, uint _curTotalStaking) public onlyHdudStaking{
        PoolInfo storage pool = poolInfoes[_pid];
        pool.curReward = pool.curReward.add(_reward);
        uint rewardTime = block.timestamp < pool.endTime ? block.timestamp : pool.endTime;
        pool.lastRewardTime = rewardTime;
        pool.curTotalStaking = _curTotalStaking;
    }

    function setUser(address _player, address _referrer, uint _addDynamicReward, uint _addStaticWd, uint _addDynamicWd) public onlyHdudStaking{
        UserInfo storage userInfo = userInfoes[_player];
        if (userInfo.referrer == address(0) && _referrer != address(0)) {
            userInfo.referrer = _referrer;
        }
        userInfo.dynamicReward = userInfo.dynamicReward.add(_addDynamicReward);
        userInfo.staticWd = userInfo.staticWd.add(_addStaticWd);
        userInfo.dynamicWd = userInfo.dynamicWd.add(_addDynamicWd);
    }
    
    function deleteDeposit(uint _pid, address _player, uint subETHTotal) public onlyHdudStaking{
        depositCounts[_pid][_player] = 0;
        userInfoes[_player].amountETHTotal = userInfoes[_player].amountETHTotal.sub(subETHTotal);
    }
    function setDeposit(uint _pid, address _player, uint _amount) public onlyHdudStaking{
        require(_amount > 0, "zero amount");
        PoolInfo storage pool = poolInfoes[_pid];
        uint depoCount = depositCounts[_pid][_player];
        
        uint amountETH;
        if (_pid == 0 || _pid == 2) {
            amountETH = checkLpWethValue(pool.lpToken, _amount);
        }
        if (_pid == 1) {
            amountETH = usdtValue2Eth(checkLpUsdtValue(pool.lpToken, _amount));
        }
        uint newIndex = depoCount + 1;
        depositCounts[_pid][_player] = newIndex;
        depositInfoes[_pid][_player][newIndex] = DepositInfo({
            amount: _amount,
            rewardDebt: pool.curReward,
            stakeTime: block.timestamp,
            amountETH: amountETH
        });
        userInfoes[_player].amountETHTotal = userInfoes[_player].amountETHTotal.add(amountETH);
    }
    
    function updateDeposit(uint _pid, address _player, uint _depoIndex, uint _newDebt) public onlyHdudStaking{
        DepositInfo storage depoInfo = depositInfoes[_pid][_player][_depoIndex];
        depoInfo.rewardDebt =  depoInfo.rewardDebt.add(_newDebt);
    }
    
    function mintHDUD(address _player, uint _amount) public onlyHdudStaking{
        require(_player != address(0) && _amount != 0);
        IERC20(hdudTokenAddr).mint(_player, _amount);
    }
    
    function withdrawLp(uint _pid, address _player, uint _amount) public onlyHdudStaking{
        require(_player != address(0) && _amount != 0);
        PoolInfo storage pool = poolInfoes[_pid];
        IERC20(pool.lpToken).transfer(_player, _amount);
    }
    
    function usdtValue2Eth(uint _usdtValue) public view returns (uint) {
        uint balanceU = IERC20(usdtTokenAddr).balanceOf(usdtWethPairAddr);
        uint balanceE = IERC20(wethTokenAddr).balanceOf(usdtWethPairAddr);
        return _usdtValue.mul(balanceE).div(balanceU);
    }
    function checkLpUsdtValue(address _contract,uint liquidity) public view returns (uint) {
        uint totalSupply0 = checkTotalLp(_contract);
        address token00 = IUniswapPair(_contract).token0();
        address token01 = IUniswapPair(_contract).token1();
        uint amount0 = liquidity.mul(IERC20(token00).balanceOf(_contract)) /
        totalSupply0;
        uint amount1 = liquidity.mul(IERC20(token01).balanceOf(_contract)) /
        totalSupply0;
        uint value = token00 == usdtTokenAddr ? amount0 : amount1;
        return value;
    }
    function checkLpWethValue(address _contract,uint liquidity) public view returns (uint) {
        uint totalSupply0 = checkTotalLp(_contract);
        address token00 = IUniswapPair(_contract).token0();
        address token01 = IUniswapPair(_contract).token1();
        uint amount0 = liquidity.mul(IERC20(token00).balanceOf(_contract)) /
        totalSupply0;
        uint amount1 = liquidity.mul(IERC20(token01).balanceOf(_contract)) /
        totalSupply0;
        uint value = token00 == wethTokenAddr ? amount0 : amount1;
        return value;
    }
    function checkTotalLp(address _contract) public view returns (uint) {
        return IUniswapPair(_contract).totalSupply();
    }
    
}

interface IUniswapPair{
    function getReservers()external view  returns(uint,uint,uint);
    function totalSupply()external view returns(uint);
    function token0()external view returns(address);
    function token1()external view returns(address);
}