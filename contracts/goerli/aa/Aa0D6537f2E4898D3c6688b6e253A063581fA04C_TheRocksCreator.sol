// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITheRockCreator {
    function mint(uint256 _characters) external returns(uint256);
}

interface ITheRocksCore {
    function getRock(uint256 _rockId) external view returns (uint256 character, uint256 exp, uint256 bornAt,uint8 level);
    function spawnRock(uint256 _character,address _owner, uint256 _delay) external returns(uint256);
    function rebirthRock(uint256 _rockId,uint256 _character,uint256 delay) external ;
}

contract TheRocksCreator is Ownable, ITheRockCreator {
    event CreateItem(address owner, uint256 _rockId);
    event RebirthItem(uint256 _rockId, uint256 _characters);
    event FeeUpdated(uint256 _newFee);
    event RollingUpdated(uint256 _changeLine, uint256 _changeRate);
    address public creatorFeeReiver;
    IERC20 public feeToken;
    ITheRocksCore theRocksCore;
    uint8 normalRange = 16;

    uint256 changeLine = 1000;
    uint256 changeRate = 20;
    uint256 totalCreated = 0;
    uint256 public fee = 100*10**9; // init fee 100Token
    bool isSoftFee;

    constructor(address core, address token) {
        theRocksCore = ITheRocksCore(core);
        feeToken = IERC20(token);
        creatorFeeReiver = msg.sender;
    }

    function getCurrentFee() internal returns(uint256){
        if(isSoftFee && totalCreated % changeLine == 0) {
            fee += fee * changeRate/100;
            emit FeeUpdated(fee);
        }
        return fee;
    }

    function setFeeToken(address _feeToken) public onlyOwner {
        feeToken = IERC20(_feeToken);
    }

    function setFee(uint256 _fee, bool _isSoftFee) public onlyOwner {
        fee = _fee;
        isSoftFee = _isSoftFee;
        emit FeeUpdated(fee);
    }

    function setRolling(uint256 _changeLine, uint256 _changeRate) public onlyOwner {
        require(changeRate <= 100, "changeRate must lower than 100");
        changeLine = _changeLine;
        _changeRate = _changeRate;
    }

    function _sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) private pure returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint256((_n & mask) >> _offset);
    }

    function _get5Bits(uint256 _input, uint256 _slot) internal pure returns(uint8) {
        return uint8(_sliceNumber(_input, uint256(5), _slot * 5));
    }

    function decode(uint256 _characters) public pure returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](4);
        uint256 i;
        for(i = 0; i < 4; i++) {
            traits[i] = _get5Bits(_characters, i);
        }
        return traits;
    }

    function encode(uint8[] memory _traits) public pure returns (uint256 _characters) {
        _characters = 0;
        for(uint256 i = 0; i < 4; i++) {
            _characters = _characters << 5;
            // bitwise OR trait with _characters
            _characters = _characters | _traits[3 - i];
        }
        return _characters;
    }

    function mint(uint256 _characters) public override returns(uint256){
        uint8[] memory decoded = decode(_characters);
        for(uint8 i = 0; i < 4; i++) {
            require(decoded[i] < normalRange, "Invalid Character!");
        }
        feeToken.transferFrom(msg.sender, creatorFeeReiver, getCurrentFee());
        _characters = encode(decoded);
        totalCreated += 1;
        return _createItem(_characters);
    }

    function _createItem(uint256 characters)
        private
        returns (uint256 rockId)
    {
        rockId = theRocksCore.spawnRock(characters, msg.sender, 0);
        emit CreateItem(msg.sender, rockId);
    }

    function createItem(uint256 characters)
        public
        onlyOwner
        returns (uint256 rockId)
    {
        return _createItem(characters);
    }

    function createMultiItem(uint8 amount, uint256 characters)
        public
        onlyOwner
    {
        require(amount <= 50, "You can only create max 50 Itemes per transaction");
        for (uint8 i; i < amount; i++) {
            _createItem(characters);
        }
    }

    function rebirthRock(uint256 _rockId, uint256 _characters) public onlyOwner {
        theRocksCore.rebirthRock(_rockId, _characters, 0);
        emit RebirthItem(_rockId, _characters);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount < address(this).balance, "WRONG AMOUNT!");
        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
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