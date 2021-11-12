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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

pragma experimental ABIEncoderV2;

import "./IEpochs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//                                                                             hhhhhhh
//                                                                             h:::::h
//                                                                             h:::::h
//                                                                             h:::::h
//     eeeeeeeeeeee    ppppp   ppppppppp      ooooooooooo       cccccccccccccccch::::h hhhhh           ssssssssss
//   ee::::::::::::ee  p::::ppp:::::::::p   oo:::::::::::oo   cc:::::::::::::::ch::::hh:::::hhh      ss::::::::::s
//  e::::::eeeee:::::eep:::::::::::::::::p o:::::::::::::::o c:::::::::::::::::ch::::::::::::::hh  ss:::::::::::::s
// e::::::e     e:::::epp::::::ppppp::::::po:::::ooooo:::::oc:::::::cccccc:::::ch:::::::hhh::::::h s::::::ssss:::::s
// e:::::::eeeee::::::e p:::::p     p:::::po::::o     o::::oc::::::c     ccccccch::::::h   h::::::h s:::::s  ssssss
// e:::::::::::::::::e  p:::::p     p:::::po::::o     o::::oc:::::c             h:::::h     h:::::h   s::::::s
// e::::::eeeeeeeeeee   p:::::p     p:::::po::::o     o::::oc:::::c             h:::::h     h:::::h      s::::::s
// e:::::::e            p:::::p    p::::::po::::o     o::::oc::::::c     ccccccch:::::h     h:::::hssssss   s:::::s
// e::::::::e           p:::::ppppp:::::::po:::::ooooo:::::oc:::::::cccccc:::::ch:::::h     h:::::hs:::::ssss::::::s
//  e::::::::eeeeeeee   p::::::::::::::::p o:::::::::::::::o c:::::::::::::::::ch:::::h     h:::::hs::::::::::::::s
//   ee:::::::::::::e   p::::::::::::::pp   oo:::::::::::oo   cc:::::::::::::::ch:::::h     h:::::h s:::::::::::ss
//     eeeeeeeeeeeeee   p::::::pppppppp       ooooooooooo       cccccccccccccccchhhhhhh     hhhhhhh  sssssssssss
//                      p:::::p
//                      p:::::p
//                     p:::::::p
//                     p:::::::p
//                     p:::::::p
//                     ppppppppp

/// @title Epochs
/// @author jongold.eth
/// @notice parses block numbers in epochs
contract Epochs is IEpochs, Ownable {
    string[12] private epochLabels;

    constructor(string[12] memory _labels) {
        epochLabels = _labels;
    }

    function getEpochLabels() public view override returns (string[12] memory) {
        return epochLabels;
    }

    function setEpochLabels(string[12] memory _labels) public onlyOwner {
        epochLabels = _labels;
    }

    function currentEpochs() public view override returns (uint256[12] memory) {
        return getEpochs(block.number);
    }

    function getEpochs(uint256 blockNumber)
        public
        pure
        override
        returns (uint256[12] memory epochs)
    {
        for (uint256 i = 0; i < 12; i++) {
            uint256 exp = i;
            epochs[i] = 1 + ((blockNumber / 11**exp) % 11);
        }
    }

    // function getEpochsBatch(uint256[] memory blockNumbers)
    //     public
    //     pure
    //     returns (uint256[11][] memory batch)
    // {
    //     for (uint256 i = 0; i < blockNumbers.length; i++) {
    //         batch[i] = getEpochs(blockNumbers[i]);
    //     }
    // }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

pragma experimental ABIEncoderV2;

interface IEpochs {
    function getEpochLabels() external view returns (string[12] memory);

    function currentEpochs() external view returns (uint256[12] memory);

    function getEpochs(uint256 blockNumber)
        external
        pure
        returns (uint256[12] memory);
}