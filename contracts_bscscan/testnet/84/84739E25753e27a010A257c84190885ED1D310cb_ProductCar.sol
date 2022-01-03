pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libs/Initializable.sol";
import "./interfaces/IAppConf.sol";
import "./interfaces/IMint.sol";

contract ProductCar is Ownable,Initializable{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    IAppConf appConf;
    IMint    nftCar;
    event evtMintCar(address indexed,string carType,uint256 tokenId);
    event evtMintParts(address indexed,string partsType,uint256 tokenId);
    event evtMintCard(address indexed,string cardType,uint256 tokenId);
    event evtComposeCar(address indexed,uint256 tokenId);

    function init(IAppConf _appConf,IMint _nftCar) public onlyOwner {
            appConf = _appConf;
            nftCar = _nftCar; 
            initialized = true;
    }
    function mintCar(address to, uint256 tokenId,string calldata _carType) public needInit virtual {
            nftCar.mint(to, tokenId);
            appConf.mintCar(tokenId,_carType);
            evtMintCar(to,_carType,tokenId);
    }

    function mintParts(address to, uint256 tokenId,string calldata _partsType) public virtual {
        //require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
        //bytes32  a = keccak256(abi.encodePacked(_carType));
        nftCar.mint(to, tokenId);

        appConf.mintParts(tokenId,_partsType);

        evtMintParts(to,_partsType,tokenId);
    }

    function mintEquitycard(address to, uint256 tokenId,string calldata _cardType) public virtual {
        //require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
        
        nftCar.mint(to, tokenId);
        appConf.mintEquitycard(tokenId,_cardType);
        evtMintCard(to,_cardType,tokenId);
        
    }

    function compose(uint256[] memory tokenIds) public returns(bool){

        uint256 tokenId = _tokenIdTracker.current();
        _tokenIdTracker.increment();

        //equire(tokenIds.length==composeNumber,"compose number fail");
        address ower = msg.sender;
        for (uint8 index = 0; index < tokenIds.length-1; index++) {
              require(nftCar.exists(ower,tokenIds[index]),"not exists");
              //require(ownerOf(tokenIds[index])!=ower,"ower error");
              //string memory a = nftPartsTypeMap[tokenIds[index]];
              //require(composePartsTypeMap[a]==1,"disallowed");
              nftCar.burn(ower,tokenIds[index]);
        }

        appConf.composed(tokenIds,tokenId);

        nftCar.mint(ower, tokenId);
        evtComposeCar(ower,tokenId);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 可被主合约调用的
abstract contract Initializable {
    // 是否已初始化
    bool public initialized = false;

    modifier needInit() {
        require(initialized, "Contract not init.");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Model.sol";

interface IAppConf {
    function mintCar(uint256 tokenId,string calldata _carType) external returns(bool) ;
    function mintParts(uint256 tokenId,string calldata _partsType) external  ;
    function mintEquitycard(uint256 tokenId,string calldata _cardType) external ;
    function composed(uint256[] memory tokenIds,uint256  tokenId) external returns(bool);
}

pragma solidity ^0.8.0;

interface IMint {
    function mint(address to, uint256 tokenId) external ;
    function exists(address owner,uint256 tokenId)   external returns (bool) ;
    function burn(address owner,uint256 tokenId)  external returns (bool) ;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

library Model {
    uint8 constant CATEGORY_LEVEL = 1;
    uint8 constant CATEGORY_LP = 2;
    uint8 constant CATEGORY_PAIR = 3;

    struct userCrowd{
           uint256 totalBuyAmount;
           uint256 totalTokens;
           uint256 leftTokens;
           uint256 releaseTokens;
           uint256 claimTokens;
    }
    
}