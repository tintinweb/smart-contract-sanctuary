// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IPizzaMania {
  function maxPizzaSlices() external view returns(uint256);
  function totalSupply() external view returns(uint256);
  function makePizzaSlice(address to, uint256 tokenId) external;
  function canMint(uint256 tokenId) external view returns (bool);
}

contract PizzaKitchen is FactoryERC721, Ownable {
  using Strings for uint256;

  event PaymentReceived(address from, uint256 amount);
  event FeeChanged(uint256 amount);

  string  private _name;
  string  private _symbol;
  string private __baseURI;
  string public contractRev;
  address  public pizzaManiaAddress;
  address[] public acceptedCryptos;
  mapping(address => uint256) public cryptoPrices;

  /*
  * Enforce the existence of only 10,000 pizzaSlices.
  */
  uint256 private _maxPizzaSlices = 10000;

  constructor() {

    pizzaManiaAddress =0x2aCE34Eb2bd1F34a16929D6E7C754c0C32705425;
    //pizzaManiaAddress = 0x2aCE34Eb2bd1F34a16929D6E7C754c0C32705425;
    _name = "PizzaKitchen for PizzaMania!";
    _symbol = "PZZA";
    __baseURI = "https://ipfs.io/ipfs/QmSx3AFV8AAM6p9niYmJc5Y6UCdBTEJc8tBWmdVdpQEHJM/";
    contractRev = "v1";

    acceptedCryptos.push(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619); //WETH
    cryptoPrices[0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619] = 0.01*10**18;
    acceptedCryptos.push(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); //USDC
    cryptoPrices[0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174] = 50*10**6;
    acceptedCryptos.push(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); //WMATIC
    cryptoPrices[0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270] = 20*10**18;
    acceptedCryptos.push(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6); //WBTC
    cryptoPrices[0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6] = 0.00065*10**8;
  }


  /**
   * @dev Returns the name of the token.
   */
  function name() override public view returns (string memory) {
      return _name;
  }

  /**
   * @dev Sets the name of the token.
   */
  function setName(string calldata _newName) external onlyOwner() {
      _name = _newName;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() override public view returns (string memory) {
      return _symbol;
  }

  /**
   * @dev Sets the symbol of the token.
   */
  function setSymbol(string calldata _newSymbol) external onlyOwner() {
      _symbol = _newSymbol;
  }

  /**
   * @dev Returns the Number of options the factory supports
   */
  function numOptions() override public pure returns (uint256) {
    return 1;
  }

  /**
  * @dev Returns whether a new slice can be minted.
  * Returns false if totalSupply of Pizza slices has been reached
  */
  function canMint(uint256 _tokenId) override public view returns (bool) {
    IPizzaMania pzMania = IPizzaMania(pizzaManiaAddress);
    return pzMania.canMint(_tokenId);
  }

  /**
  * @dev Returns a URL specifying metadata about the tokenId
  */
  function tokenURI(uint256 _tokenId) override external view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
  }

  function _baseURI() internal view returns (string memory) {
       return __baseURI;
  }

  /**
  * Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
  */
  function supportsFactoryInterface() override public pure returns (bool) {
        return true;
  }

  function mint(uint256 _tokenId, address _toAddress) override external {
      if(_msgSender() == owner()){
        IPizzaMania pzMania = IPizzaMania(pizzaManiaAddress);
        pzMania.makePizzaSlice(_toAddress, _tokenId);
      }else {
        canMint(_tokenId);
        _userMint(_tokenId,_toAddress);
      }
  }

  // Only for Owner

  function multiMint(uint256[] calldata _tokenId, address _toAddress) external onlyOwner() {
    IPizzaMania pzMania = IPizzaMania(pizzaManiaAddress);
    for(uint i=0; i < _tokenId.length; i++){
      pzMania.makePizzaSlice(_toAddress, _tokenId[i]);
    }
  }

  function _userMint(uint256 _tokenId, address _toAddress) internal {
    bool statechange;
    for(uint i=0; i < acceptedCryptos.length ; i++) {
      if(
        IERC20(acceptedCryptos[i]).allowance(address(this), _msgSender()) >= cryptoPrices[acceptedCryptos[i]]
        ){
          IERC20(acceptedCryptos[i]).transfer(address(this), cryptoPrices[acceptedCryptos[i]]);
          IPizzaMania pzMania = IPizzaMania(pizzaManiaAddress);
          pzMania.makePizzaSlice(_toAddress, _tokenId);
          statechange = true;
      }
    }
    require(statechange, "Approve ERC20 spending!");
  }

  receive() external payable  {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  function collectRoyalties(address _addrs) external onlyOwner() {
    uint256 erc20royalties = IERC20(_addrs).balanceOf(address(this));
    uint256 nativeroyalties = address(this).balance;
    IERC20(_addrs).transfer(address(owner()), erc20royalties);
    payable(address(owner())).transfer(nativeroyalties);
  }

  function changeAcceptedCryptos(address _addrs, uint256 position ) external onlyOwner() {
    acceptedCryptos[position] = _addrs;
  }

  function changeCryptoPrices(address _addrs, uint256 _newPrice ) external onlyOwner() {
    cryptoPrices[_addrs] = _newPrice;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various
 * ways of minting.
 */
interface FactoryERC721 {
    /**
     * Returns the name of this factory.
     */
    function name() external view returns (string memory);

    /**
     * Returns the symbol for this factory.
     */
    function symbol() external view returns (string memory);

    /**
     * Number of options the factory supports.
     */
    function numOptions() external view returns (uint256);

    /**
     * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
     * restrict a total supply per option ID (or overall).
     */
    function canMint(uint256 _optionId) external view returns (bool);

    /**
     * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
     * same structure as the ERC721 metadata.
     */
    function tokenURI(uint256 _optionId) external view returns (string memory);

    /**
     * Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
     */
    function supportsFactoryInterface() external view returns (bool);

    /**
     * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
     * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
     * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
     * @param _optionId the option id
     * @param _toAddress address of the future owner of the asset(s)
     */
    function mint(uint256 _optionId, address _toAddress) external;
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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 10000
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