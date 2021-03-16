/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity ^0.5.0;

/**
 * @title safemath
 * @dev unsigned math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // gas optimization: this is cheeper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // see: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "safemath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // solidity only automatically asserts when dividing by 0
        require(b > 0, "safemath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // there is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "safemath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "safemath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "safemath#mod: DIVISION_BY_ZERO");
        return a % b;
    }

}

/**
 * copyright 2018 zeroex intl.
 * licensed under the apache license, version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * you may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * see the License for the specific language governing permissions and
 * limitations under the License.
 */
/**
 * utility library of inline functions on addresses
 */
library Address {

    /**
     * returns whether the target address is a contract
     * @dev this function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // XXX currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // see https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // todo check this again before the serenity release, because all addresses will be
        // contracts then.
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

}

/*
 * @dev provides information about the current execution context, including the
 * sender of the transaction and its data. while these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with gsn meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * this contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title 1111-test contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract ElevenElevenTest is Ownable {
    using SafeMath for uint256;
    using Address for address;

    // Public variables
    uint256 public SALE_START_TIMESTAMP = 1611846000;

    uint256 public maxSupply;

    mapping(address => uint256[]) public holders;

    function setStartTime(uint256 blockNumber) public {
      SALE_START_TIMESTAMP = blockNumber;
    }

    constructor() public {
      _supply = 1000000000000000000000;
    }

    uint256 public constant MAX_NFT_SUPPLY = 16384;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    // Mapping from token ID to whether the NFT was minted before reveal
    mapping (uint256 => bool) private _mintedBeforeReveal;

    uint256 private _supply;

    // Token name
    string private _name;

    event Supply(uint256 supply);

    // Token symbol
    string private _symbol;

    // no constructor

    function totalSupply() public view returns (uint256) {
      return _supply;
    }

    function setSupply(uint256 quantity) public onlyOwner returns (uint256) {
      // data _supply = quantity;
      _supply = quantity;
      emit Supply(quantity);
      return _supply;
    }

    /**
     * @dev Gets current NFT Price
     */
    function getNFTPrice() public view returns (uint256, string memory) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

        uint currentSupply = totalSupply();

        if (currentSupply >= 16381) {
            return (100000000000000000000, 'SMOL'); // 16381 - 16383 100 ETH
        } else if (currentSupply >= 16000) {
            return (3000000000000000000, 'ETH'); // 16000 - 16380 3.0 ETH
        } else if (currentSupply >= 15000) {
            return (1700000000000000000, 'SMOL'); // 15000  - 15999 1.7 ETH
        } else if (currentSupply >= 11000) {
            return (900000000000000000, 'ETH'); // 11000 - 14999 0.9 ETH
        } else if (currentSupply >= 7000) {
            return (500000000000000000, 'SMOL'); // 7000 - 10999 0.5 ETH
        } else if (currentSupply >= 3000) {
            return (300000000000000000, 'ETH'); // 3000 - 6999 0.3 ETH
        } else {
            return (100000000000000000, 'SMOL'); // 0 - 2999 0.1 ETH 
        }
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function mint() public {
      require(totalSupply() < MAX_NFT_SUPPLY, "Minting over");

      uint256 id = totalSupply().add(1);

      _supply = _supply + 1;

      uint256 len = holders[msg.sender].length;
      holders[msg.sender][len] = id;
    }
}