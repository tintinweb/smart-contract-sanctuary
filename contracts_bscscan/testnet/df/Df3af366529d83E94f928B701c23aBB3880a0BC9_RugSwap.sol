// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./access/Ownable.sol";
import "./token/BEP20/IBEP20.sol";

interface ZombieOnChainPrice {
    function usdToZmbe(uint amount) external view returns(uint);
}

contract RugSwap is Ownable{
    struct RugInfo {
        bool isListed;
        bool isEnabled;
    }

    uint256 public totalSwaps = 0; // total swaps
    address public burnAddress = 0x000000000000000000000000000000000000dEaD; // Burn address
    address public treasury; // treasury address
    address public zombieAddress;
    address public priceContract;
    uint public totalDisabledTokens;

    address[] public rugList;
    mapping(address => RugInfo) public rugInfo;

    constructor (address _zombieAddress, address _treasury, address _priceContract) {
        priceContract = _priceContract;
        treasury = _treasury;
        zombieAddress = _zombieAddress;
    }

    function addRug (address _rug) public onlyOwner returns(bool) {
        // so an address doesn't get whitelisted twice or more.
        require(!rugInfo[_rug].isListed, "The token is already listed.");
        rugList.push(_rug);
        rugInfo[_rug] = RugInfo({
        isListed: true,
        isEnabled: true
        });
        return true;
    }

    // disables a given address from the rugInfo mapping.
    function disableRug(address _rug) public onlyOwner returns(bool) {
        require(rugInfo[_rug].isListed, "The token is not listed.");
        require(rugInfo[_rug].isEnabled, "The token is not enabled.");
        rugInfo[_rug].isEnabled = false;
        totalDisabledTokens += 1;
        return true;
    }

    // enables a given address from the rugInfo mapping.
    function enableRug(address _rug) public onlyOwner returns(bool) {
        require(rugInfo[_rug].isListed, "The token is not listed.");
        require(!rugInfo[_rug].isEnabled, "The token is already enabled.");
        rugInfo[_rug].isEnabled = true;
        totalDisabledTokens -= 1;
        return true;
    }

    function setPriceContract(address _priceContract) public onlyOwner {
        priceContract = _priceContract;
    }

    function totalEnabledTokens() public view returns(uint) {
        return rugList.length - totalDisabledTokens;
    }

    function resultRugList(address _rug) public view returns(address[] memory) {
        address[] memory newRugList = new address[](totalEnabledTokens() - 1);
        uint _rugsAdded = 0;
        for (uint256 index = 0; index < rugList.length; index++) {
            address _currentRug = rugList[index];
            if(rugInfo[_currentRug].isEnabled && _currentRug != _rug) {
                newRugList[_rugsAdded] = _currentRug;
                _rugsAdded += 1;
            }
        }
        return newRugList;
    }

    function burn(uint256 amount) private {
        IBEP20(zombieAddress).transferFrom(msg.sender, burnAddress, amount);
    }

    function toTreasury(uint256 amount) private {
        IBEP20(zombieAddress).transferFrom(msg.sender, treasury, amount);
    }

    // returns address just for the event to show the rugged token
    function ruggedTokenSwap(address _rug) private returns(bool) {
        // transferring a rugged token from user wallet to this contractAddress, needs approval first.
        IBEP20(_rug).transferFrom(msg.sender, address(this), 10**IBEP20(_rug).decimals());
        // generating a random rugged token except the token which user provided.
        address[] memory newRugList = resultRugList(_rug);
        address randomTokenAddress;
        // handling an edge case, if whiteList has only two addresses then one of them will be omitted in above loop so returning the remaining one.
        if (newRugList.length < 2) {
            randomTokenAddress = newRugList[0];
        } else {
            randomTokenAddress = newRugList[getRandomNum(newRugList.length)];
        }
        // transferring the random rugged token to the user. hopefully he finds it in his wallet ;).
        IBEP20(randomTokenAddress).transfer(msg.sender, 10**IBEP20(randomTokenAddress).decimals());
        return true;
    }

    // function to withdraw tokens in case of v2.
    function withdrawTokens(address ruggedTokenAddress, uint256 _amount) public payable onlyOwner returns(bool result) {
        IBEP20(ruggedTokenAddress).transfer(msg.sender, _amount * 10**IBEP20(ruggedTokenAddress).decimals());
        return true;
    }

    // returns the amount of zombie tokens required for one BUSD
    function getAmount() public view returns(uint) {
        return ZombieOnChainPrice(priceContract).usdToZmbe(10**IBEP20(zombieAddress).decimals());
    }

    function rugSwap(address _rug) public payable returns(string memory) {
        uint256 zombieAmount = getAmount();
        require(totalEnabledTokens() > 1, "Please add more tokens to whitelist.");
        require(rugInfo[_rug].isEnabled, "Only enabled tokens are allowed.");
        // burning half the amount of zombie tokens
        burn(zombieAmount / 2);
        // tranferring the other half to treasury
        toTreasury(zombieAmount / 2);
        ruggedTokenSwap(_rug);
        totalSwaps += 1;
        emit Swapped(msg.sender, zombieAmount, _rug);
        return IBEP20(_rug).symbol();
    }

    uint nonce = 0;
    // generates a pseudo random number just to return a rugged token which doesn't have any value, totally predictable so not suitable for selecting any serious random number.
    function getRandomNum(uint256 length) private returns(uint256) {
        nonce = nonce + 1;
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nonce))) % (length - 1);
    }

    // to check balance of the rugged tokens
    function balanceOf(address _rug) public view returns(uint) {
        return IBEP20(_rug).balanceOf(address(this)) / 10**IBEP20(_rug).decimals();
    }

    event Swapped(address indexed _from, uint _zombieAmount, address _ruggedTokenAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.4;

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
    constructor()  {
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