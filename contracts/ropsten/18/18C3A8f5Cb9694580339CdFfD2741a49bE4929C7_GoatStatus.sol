// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/IGoatStatus.sol";


contract GoatStatus is IGoatStatus, Ownable {

    using Strings for uint256;

    address public override saleAddress;
    address public override rentalAddress;
    address public override goatNFTAddress;
    address public override rentalWrapperAddress;
    
    uint256 public currencyCount;
    address[] private currencyList;
    
    mapping(address => bool) public override isCurrency;

    mapping (bytes32 => uint256) private tokenStatus;
    mapping (bytes32 => uint256) private auctionType;
    mapping (bytes32 => uint256) private statusAmounts;

    /** ====================  Event  ==================== */
    event LogSetAddress(address saleAddress, address rentalAddress, address goatNFTAddress, address rentalWrapperAddress);
    event LogSetCurrency(address token, bool enable);
    event LogSetTokenStatus(address indexed owner, address indexed token, uint256 indexed id, uint256 status, uint256 auctionType, uint256 amount);

    /** ====================  modifier  ==================== */
    modifier onlySaleOrRentalContract() {
        require(msg.sender == saleAddress || msg.sender == rentalAddress, "5001: caller is not goatSale or goatRental");
        _;
    }

    /** ====================  set address  ==================== */
    function setAddress(
        address _saleAddress,
        address _rentalAddress,
        address _goatNFTAddress,
        address _rentalWrapperAddress
    ) 
        external
        override
        onlyOwner 
    {
        saleAddress = _saleAddress;
        rentalAddress = _rentalAddress;
        goatNFTAddress = _goatNFTAddress;
        rentalWrapperAddress = _rentalWrapperAddress;

        emit LogSetAddress(_saleAddress, _rentalAddress, _goatNFTAddress, _rentalWrapperAddress);
    }

    /** ====================  currency function  ==================== */
    function setCurrencyToken(
        address _token, 
        bool _enable
    ) 
        external 
        onlyOwner
        override 
    {
        if (!isCurrency[_token] && _enable) {
            currencyCount++;
            currencyList.push(_token);
        } else if (isCurrency[_token] && !_enable) {
            currencyCount--;
        }

        isCurrency[_token] = _enable;

        emit LogSetCurrency(_token, _enable);
    }

    function getCurrencyList() 
        external 
        override 
        view 
        returns (address[] memory resCurrencyList) 
    {
        resCurrencyList = new address[](currencyCount);
        
        uint256 counter = 0;
        if (currencyCount > 0) {
            for (uint256 i = 0; i < currencyList.length; i++) {
                address currency = currencyList[i];
                if (isCurrency[currency]) {
                    resCurrencyList[counter] = currency;
                    counter++;
                }
            }
        }
    }

    /** ====================  token status function  ==================== */
    function setTokenStatus(
        address _owner,
        address _token,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        uint256 _tokenStatus,
        uint256 _auctionType
    ) 
        external 
        onlySaleOrRentalContract 
        override 
    {
        for(uint256 i = 0; i < _ids.length; i++) {
            bytes32 key = keccak256(abi.encodePacked(_owner, _token, _ids[i].toString()));
            tokenStatus[key] = _tokenStatus;
            auctionType[key] = _auctionType;
            statusAmounts[key] = _amounts[i];

            emit LogSetTokenStatus(_owner, _token, _ids[i], _tokenStatus, _auctionType, _amounts[i]);
        }
    }

    function getTokenStatus(
        address _owner,
        address _token,
        uint256 _id
    )
        external
        view
        override
        returns (
            uint256 _tokenStatus,
            uint256 _auctionType,
            uint256 _amount
        )
    {
        bytes32 key = keccak256(abi.encodePacked(_owner, _token, _id.toString()));
        _tokenStatus = tokenStatus[key];
        _auctionType = auctionType[key];
        _amount = statusAmounts[key];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IGoatStatus {

    function setAddress(
        address _saleAddress,
        address _rentalAddress,
        address _goatNFTAddress,
        address _rentalWrapperAddress
    ) external;
    function saleAddress() external view returns (address);
    function rentalAddress() external view returns (address);
    function goatNFTAddress() external view returns (address);
    function rentalWrapperAddress() external view returns (address);

    function setCurrencyToken(address token, bool enable) external;
    function isCurrency(address token) external view returns (bool);
    function getCurrencyList() external view returns (address[] memory);


    function setTokenStatus(
        address _owner,
        address _token,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        uint256 _tokenStatus,
        uint256 _auctionType
    ) external;

    function getTokenStatus(
        address _owner,
        address _token,
        uint256 _id
    )
    external
    view
    returns (
        uint256 tokenStatus,
        uint256 auctionType,
        uint256 amount
    );
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1000
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