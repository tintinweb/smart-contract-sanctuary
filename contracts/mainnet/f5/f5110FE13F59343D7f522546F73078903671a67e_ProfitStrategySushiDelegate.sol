pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import './uniswapv2/libraries/TransferHelper.sol';
import "./utils/MasterCaller.sol";
import "./interfaces/IProfitStrategy.sol";

import "./storage/StrategySushiStorage.sol";



interface IMasterChef {

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory _userInfo);
}
/**
 * mine SUSHI via SUSHIswap.MasterChef
 * will transferOnwership to stakeGatling
 */
contract ProfitStrategySushiDelegate is StrategySushiStorage, Ownable, IProfitStrategy {

     /**
     * Stake LP
     */
    function stake(uint256 _amount) external override onlyOwner() {

        if(stakeRewards != address(0)) {
            IMasterChef(stakeRewards).deposit( pid, _amount);
        }
    }

    /**
     * withdraw LP
     */
    function withdraw(uint256 _amount) public override onlyOwner() {

        if(stakeRewards != address(0) && _amount > 0) {

            IMasterChef(stakeRewards).withdraw(pid, _amount);
            TransferHelper.safeTransfer(stakeLpPair, address(stakeGatling),_amount);
        }
    }

    function burn(address _to, uint256 _amount) external override onlyOwner() returns (uint256 amount0, uint256 amount1) {

        if(stakeRewards != address(0) && _amount > 0) {
            IMasterChef(stakeRewards).withdraw(pid, _amount);
            TransferHelper.safeTransfer(stakeLpPair, stakeLpPair, _amount);
            (amount0, amount1) =  IUniswapV2Pair(stakeLpPair).burn(_to);
        }
    }

    function stakeToken() external view override returns (address) {
        return stakeRewards;
    }

    function earnToken() external view override returns (address) {
        return earnTokenAddr;
    }

    function earnPending(address _account) external view override returns (uint256) {
        return IMasterChef(stakeRewards).pendingSushi(pid, _account);
    }
    function earn() external override onlyOwner() {
        IMasterChef(stakeRewards).deposit(pid, 0);
        transferEarn2Gatling();
    }
    function earnTokenBalance(address _account) external view override returns (uint256) {
        return IERC20(earnTokenAddr).balanceOf(_account);
    }

    function balanceOfLP(address _account) external view override  returns (uint256) {
        //
        return IMasterChef(stakeRewards).userInfo(pid, _account).amount;
    }
    
    /**
     * withdraw LP && earnToken
     */
    function exit() external override  onlyOwner() {

        withdraw(IMasterChef(stakeRewards).userInfo(pid, address(this)).amount);
        transferLP2Gatling();
        transferEarn2Gatling();
    }
    function transferLP2Gatling() private {

        uint256 _lpAmount = IERC20(stakeLpPair).balanceOf(address(this));
        if(_lpAmount > 0) {
            TransferHelper.safeTransfer(stakeLpPair, stakeGatling, IERC20(stakeLpPair).balanceOf(address(this)));
        }
    }
    function transferEarn2Gatling() private {

        uint256 _tokenAmount = IERC20(earnTokenAddr).balanceOf(address(this));
        if(_tokenAmount > 0) {
            TransferHelper.safeTransfer(earnTokenAddr, address(stakeGatling), _tokenAmount);
        }
    }
}

pragma solidity 0.6.12;

interface IProfitStrategy {
    /**
     * @notice stake LP
     */
    function stake(uint256 _amount) external;  // owner
    /**
     * @notice withdraw LP
     */
    function withdraw(uint256 _amount) external;  // owner
    /**
     * @notice the stakeReward address
     */
    function stakeToken() external view  returns (address);
    /**
     * @notice the earn Token address
     */
    function earnToken() external view  returns (address);
    /**
     * @notice returns pending earn amount
     */
    function earnPending(address _account) external view returns (uint256);
    /**
     * @notice withdaw earnToken
     */
    function earn() external;
    /**
     * @notice return ERC20(earnToken).balanceOf(_account)
     */
    function earnTokenBalance(address _account) external view returns (uint256);
    /**
     * @notice return LP amount in staking
     */
    function balanceOfLP(address _account) external view  returns (uint256);
    /**
     * @notice withdraw staked LP and earnToken assets
     */
    function exit() external;  // owner

    function burn(address _to, uint256 _amount) external returns (uint256 amount0, uint256 amount1);
}

pragma solidity 0.6.12;

/**
 * mine SUSHI via SUSHIswap.MasterChef
 * will transferOnwership to stakeGatling
 */
contract StrategySushiStorage {

    //Sushi MasterChef
    address public constant stakeRewards = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;
    // UniLP ([usdt-eth].part)
    address public  stakeLpPair;
    //earnToken
    address public constant earnTokenAddr = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public stakeGatling;
    address public admin;
    uint256 public pid;

    event AdminChanged(address previousAdmin, address newAdmin); 

}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract MasterCaller {
    address private _master;

    event MastershipTransferred(address indexed previousMaster, address indexed newMaster);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _master = msg.sender;
        emit MastershipTransferred(address(0), _master);
    }

    /**
     * @dev Returns the address of the current MasterCaller.
     */
    function masterCaller() public view returns (address) {
        return _master;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMasterCaller() {
        require(_master == msg.sender, "Master: caller is not the master");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferMastership(address newMaster) public virtual onlyMasterCaller {
        require(newMaster != address(0), "Master: new owner is the zero address");
        emit MastershipTransferred(_master, newMaster);
        _master = newMaster;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}