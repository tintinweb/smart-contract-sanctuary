// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Presale is Ownable {
    IERC20 token;
    string public constant info = "ETH2SOCKS Presale contract. This is only for DEFISOCKS holders.";
    uint256 public constant tokensPerEth = 20; //num tokens per ether
    bool private initialized = false;

    mapping(address => uint256) public maxContributions; // the allowed list of contributors and max they can buy
    mapping(address => uint256) public contributions; // the currently used contributions


    modifier whenSaleIsActive() {
        assert(isActive());
        _;
    }
    constructor() {}

    function startSale(address _tokenAddr) public onlyOwner {
        require(initialized == false);
        token = IERC20(_tokenAddr);
        token.approve(address(this), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        initialized = true;
    }

    function addWhitelist() public onlyOwner {
        maxContributions[parseAddr('0xAc86c9072168ef094352B8922e8039372F53907b')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x378B4F843C01B752F5B7FA9d454bf3913CE31c46')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x627CA7601e943Cbffd21AeEb7BB06B9A3137B0ec')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x0BEa184cdf56A9047E19275829d9D89129c0De6D')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x1c23528598E6C1a34EDf13B80aDAf0F8538C2904')] = 3 * 10 ** 18;
    }

    function isActive() public view returns (bool) {
        return (
        initialized == true //Lets the public know if we're live
        );
    }

    fallback() external payable {
        buyTokens();
    } //Fallbacks so if someone sends ether directly to the contract it will function as a purchase

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable whenSaleIsActive {
        require(msg.value >= 0.05 ether, "incorrect amount");
        require(msg.value <= 0.15 ether, "incorrect amount");

        uint256 numRequested = msg.value * tokensPerEth;
        uint256 numAllowed = getAllowedContribution(msg.sender);

        require(numAllowed >= numRequested, "Unable to purchase - overlimit");

        uint256 existingAmount = contributions[msg.sender];
        uint256 newAmount = existingAmount + numRequested;
        contributions[msg.sender] = newAmount;

        payable(owner()).transfer(msg.value);

        token.transferFrom(address(this), msg.sender, numRequested);
    }

    function tokensAvailable() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function endSale() onlyOwner public {
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transferFrom(address(this), payable(owner()), tokenBalance);
        //Tokens returned to owner wallet
        selfdestruct(payable(owner()));
    }

    function getAllowedContribution(address _beneficiary) public view returns (uint256) {
        return maxContributions[_beneficiary] - contributions[_beneficiary];
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}