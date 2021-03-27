/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

abstract contract MasterMex {
    function setPool(address uniPair, uint256 maxChangeRatio, uint256 minFund) external virtual;
    function transferOwnership(address newOwner) external virtual;
    struct PoolInfo {
        address tokenPair;
        uint256 prevReserved;
        uint256 maxChangeRatio;
        uint256 minFund;
    }
    PoolInfo[] public poolInfo;
    function poolLength() external virtual view returns (uint256);
}

contract DexmexPairCreator is Ownable {
    
    IERC20 _token;
    MasterMex _prediction;
    mapping(address => bool) _pairs;
    
    constructor(IERC20 token, MasterMex prediction) public {
        _token = token;
        _prediction = prediction;
        
        // Add existing pairs
        _pairs[0xBb2b8038a1640196FbE3e38816F3e67Cba72D940] = true;
        _pairs[0xd3d2E2692501A5c9Ca623199D38826e513033a17] = true;
        _pairs[0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc] = true;
        _pairs[0x570fEbDf89C07f256C75686CaCa215289bB11CFc] = true;
        _pairs[0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974] = true;
        _pairs[0x26aAd2da94C59524ac0D93F6D6Cbf9071d7086f2] = true;
        _pairs[0x819f3450dA6f110BA6Ea52195B3beaFa246062dE] = true;
        _pairs[0xDFC14d2Af169B0D36C4EFF567Ada9b2E0CAE044f] = true;
        _pairs[0xC2aDdA861F89bBB333c90c492cB837741916A225] = true;
        _pairs[0xc92b1C381450C5972ee3F4A801e651257aed449A] = true;
    }
    
    function transferMasterOwnership(address newOwner) external onlyOwner {
        _prediction.transferOwnership(newOwner);
    }
    
    function addPair(address uniPair) external {
        require(_token.balanceOf(msg.sender) >= 100000000000000000000000, "PairCreator: You need to hold at least 100k DEXM");
        _addPair(uniPair);
    }
    
    function addPairAuto(address uniPair) external onlyOwner {
        _addPair(uniPair);
    }
    
    function _addPair(address uniPair) private {
        require(!_pairs[uniPair], "PairCreator: Pair already exists");
        _prediction.setPool(uniPair, 300000000000, 2000000000000000000);
        _pairs[uniPair] = true;
    }

}