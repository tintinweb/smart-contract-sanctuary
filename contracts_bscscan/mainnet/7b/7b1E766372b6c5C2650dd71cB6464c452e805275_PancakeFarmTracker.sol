// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IPancakeFarm} from "./interface/IPancakeFarm.sol";
import {IERC20} from "./interface/IERC20.sol";

contract PancakeFarmTracker is Ownable {

    address constant poolAddress = 0x73feaa1eE314F8c655E354234017bE2193C9E24E;
    address constant rewardToken = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    uint8 constant decimals = 18;
    uint256 public totalPools = 0;

    mapping(address => uint256) public poolMapping;

    struct TokenBalance {
        address token;
        int256 amount;
        uint8 decimals;
        Token[] rewards;
    }

    struct Token {
        address token;
        uint256 amount;
        uint8 decimals;
    }
    
    constructor() {
        totalPools =  getPoolLength();
        for(uint256 i=0; i< totalPools; i++) {
            address lpToken = getLpToken(i);
            poolMapping[lpToken] = i;
        }
    }

    function syncPools() external {
        totalPools =  getPoolLength();
        for(uint256 i=0; i< totalPools; i++) {
            address lpToken = getLpToken(i);
            poolMapping[lpToken] = i;
        }
    }

    function getPoolLength() public view returns(uint256) {
        // return 5;
        return  IPancakeFarm(poolAddress).poolLength();
    }

    function getLpToken(uint256 pid) public view returns(address) {
         IPancakeFarm.PoolInfo memory poolInfo = IPancakeFarm(poolAddress).poolInfo(pid);
         return poolInfo.lpToken;
    }

    function addPool(uint256 pid) external onlyOwner {
        address lpToken = getLpToken(pid);
        poolMapping[lpToken] = pid;
    }

    function setTotalPool(uint256 pid) external onlyOwner {
      totalPools =  pid;
    }

    function getBalancesAndRewardsByIndex(uint256 startIndex, uint256 endIndex,address account)
        external
        view
        returns (TokenBalance[] memory)
    {
        uint256 diff = endIndex - startIndex;
        TokenBalance[] memory tokens = new TokenBalance[](diff);
        for(uint256 i=0; i< diff; i++) {
        address lpToken = getLpToken(startIndex+i);
       (int256 amount, uint8 decimals) = getBalance(lpToken, account);
       tokens[i]=TokenBalance({
                    token: lpToken,
                    amount: amount,
                    decimals: decimals,
                    rewards: getUnclamedRewards(lpToken,account)
       });
      }
       return tokens;
    }

     function getBalancesAndRewards(address account)
        external
        view
        returns (TokenBalance[] memory)
    {
        TokenBalance[] memory tokens = new TokenBalance[](totalPools);
        for(uint256 i=0; i< totalPools; i++) {
        address lpToken = getLpToken(i);
       (int256 amount, uint8 decimals) = getBalance(lpToken, account);
       tokens[i]=TokenBalance({
                    token: lpToken,
                    amount: amount,
                    decimals: decimals,
                    rewards: getUnclamedRewards(lpToken,account)
       });
      }
       return tokens;
    }

    function getBalances(address account,uint256 idx) public view returns (TokenBalance memory) {
        address lpToken = getLpToken(idx);
       (int256 amount, uint8 decimals) = getBalance(lpToken, account);
       return TokenBalance({
                    token: lpToken,
                    amount: amount,
                    decimals: decimals,
                    rewards: getUnclamedRewards(lpToken,account)
       });
    }

    function getBalance(address token, address account)
        public
        view
        returns (int256, uint8)
    {
        uint256 pid = poolMapping[token];
         uint256 finalAmount = 0;
         uint8 deci = 0;
        try IPancakeFarm(poolAddress).userInfo(pid, account)
         returns (IPancakeFarm.UserInfo memory userInfo) {
             finalAmount = userInfo.amount;
         }catch {
         } 
          try IERC20(token).decimals()
         returns (uint8 decimal) {
             deci = decimal;
         }catch {
         } 
        return (
            int256(finalAmount),
            deci
        );
    }

    function getUnclamedRewards(address token, address account)
        public
        view
        returns (Token[] memory)
    {
        Token[] memory rewards = new Token[](1);
        uint256 pid = poolMapping[token];
         uint256 finalAmount = 0;
         try IPancakeFarm(poolAddress).pendingCake(pid, account)
         returns (uint256 amount) {
             finalAmount = amount;
         }catch {
         }
        rewards[0] = Token({
            token: rewardToken,
            amount: finalAmount,
            decimals: decimals
        });
        return rewards;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IPancakeFarm {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        address lpToken;
        uint256 accSushiPerShare;
        uint256 lastRewardTime;
        uint256 allocPoint;
    }

    function pendingCake(uint256, address) external view returns (uint256);

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 pid)
        external
        view
        returns (IPancakeFarm.PoolInfo memory);

    function userInfo(uint256 pid, address)
        external
        view
        returns (IPancakeFarm.UserInfo memory);

    function lpToken(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IERC20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}