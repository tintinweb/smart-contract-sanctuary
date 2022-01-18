// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";

contract EthereumTerminus is Ownable {

    address public bridge; ///MainnetBridge
    address public elves;
    address public ren;

    mapping (address => address) public contractPairs;
    mapping (uint256 => address) public elfOwner;

    function initialize(address bridge_, address elves_, address ren_) onlyOwner external {

        bridge   = bridge_;
        elves    = elves_;
        ren      = ren_;
       
    }

    function setContractPairs(address key_, address pair_) onlyOwner external {
        ///RXROOT and FXCHILD
        //REN on Poly and REN on Mainnet
        //Elves on Poly and Elves on Mainnet.
        
        contractPairs[key_] = pair_;
        contractPairs[pair_] = key_;

    }

    /// @dev Send Elves and Miren to Polygon

    function travel(uint256[] calldata ids, uint256 renAmount) external {
        address target = contractPairs[address(this)];

        uint256 travelers = ids.length;

        uint256 currIndex = 0;

        bytes[] memory calls = new bytes[]((travelers > 0 ? travelers + 1 : 0) + (renAmount > 0 ? 1 : 0));

        if (travelers > 0) {
            _pullIds(elves, ids);//unstake everyone

            // This will create orcs exactly as they exist in this chain
            for (uint256 i = 0; i < ids.length; i++) {
                calls[i] = dnaSequencing(ids[i]);
            }

            calls[travelers] = abi.encodeWithSelector(this.returnToOwner.selector,contractPairs[elves], msg.sender, ids);
            currIndex += travelers + 1;
        }

        if (renAmount > 0) {
            IERC20Lite(ren).burn(msg.sender, renAmount);
            calls[currIndex] = abi.encodeWithSelector(this.mintToken.selector, contractPairs[address(ren)], msg.sender, renAmount);
            currIndex++;
        }

        ITunnel(bridge).sendMessage(abi.encode(target, calls));
    }

    function callElves(bytes calldata data) external {
        onlyBridge();

        (bool succ, ) = elves.call(data);
        require(succ);
    }

    event D(uint tt);
    event DAD(address al);

    function returnToOwner(address token, address owner, uint256[] calldata ids) external {
        /////return from polygon
        onlyBridge();

        emit DAD(token);

        for (uint256 i = 0; i < ids.length; i++) {  
            emit D(ids[i]);
            if (token == elves)  delete elfOwner[ids[i]];
            IERC721Lite(token).transfer(owner, ids[i]);
        }
    }

    function mintToken(address token, address to, uint256 amount) external { 
        onlyBridge();

        IERC20Lite(token).mint(to, amount);
    }

    function _pullIds(address token, uint256[] calldata ids) internal {
        // The ownership will be checked to the token contract
        IElves(token).pull(msg.sender, ids);
    }

    function pullCallback(address owner, uint256[] calldata ids) external {
        require(msg.sender == elves );
        for (uint256 i = 0; i < ids.length; i++) {
            _stake(msg.sender, ids[i], owner);
        }
    }

    function dnaSequencing(uint256 id) internal view returns (bytes memory data) {
        uint256 sentinel = IElves(elves).getSentinel(id);
        data = abi.encodeWithSelector(this.callElves.selector, abi.encodeWithSelector(IElves.modifyElfDNA.selector,id, sentinel));   
    }


    function _stake(address token, uint256 id, address owner) internal {
        require(elfOwner[id] == address(0), "already staked");
        require(msg.sender == token, "not elf contract");
        require(IERC721Lite(token).ownerOf(id) == address(this), "elf not transferred");

        if (token == elves)   elfOwner[id]  = owner;
    
    }

    function onlyBridge() view internal {
        require(msg.sender == bridge, "not bridge");
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IERC20Lite {
    
    function transfer(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external;
    function mint(address to, uint256 value) external; 

}

interface IElfMetaDataHandler {    
function getTokenURI(uint16 id_, uint256 sentinel) external view returns (string memory);
}

interface ICampaigns {
function gameEngine(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) external 
returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory);
}

interface ITunnel {
    function sendMessage(bytes calldata message_) external;
}

interface ITerminus {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface IElves {
    function getSentinel(uint256 _id) external view returns(uint256 sentinel);
    function modifyElfDNA(uint256 id, uint256 sentinel) external;
    function pull(address owner_, uint256[] calldata ids) external;
}

interface IERC721Lite {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
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