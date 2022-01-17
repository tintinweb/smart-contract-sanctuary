// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DNA is Ownable {

    using Counters for Counters.Counter;

    address autobot;
    Counters.Counter public numGenomes;
    Counters.Counter public numSnaps;

    struct Genome {
        uint256 totalSize;
        Counters.Counter snapsAdded;
        address autobot;
    }

    struct SNaP {
        uint256 genomeId;
        string rsid;
        string chromosome;
        string position;
        string genotype;
    }

    /**
    TODO: MORE EVENTS 
    */
    event GenomeAdded(
        uint256 indexed genomeId
    );
    event GenomeAutobotAssigned(
        uint256 indexed genomeId,
        address indexed autobot
    );
    event SNaPAdded(
        uint256 indexed tokenId,
        uint256 indexed genomeId
    );
    event AutobotAssigned(
        address indexed autobot
    );

    mapping(uint256 => Genome) public genomes;
    mapping(uint256 => SNaP) public snaps;

    constructor() {
        autobot = msg.sender;
    }

    function addGenome(
        uint256 _totalSize,
        address _autobot)
        public {
            require(_autobot != address(0), "Invalid autobot address");
            require(msg.sender == owner() || msg.sender == autobot, "Only owner or primary autobot can add genomes");
            
            numGenomes.increment();
            Counters.Counter memory _snapsAdded;
            genomes[numGenomes.current()] = Genome({
                totalSize: _totalSize,
                snapsAdded: _snapsAdded,
                autobot: _autobot
            });
            
            emit GenomeAdded(numGenomes.current());
    }

    function assignGenomeAutobot(
        uint256 _genomeId,
        address _autobot)
        public {
            _validateGenome(_genomeId);
            require(_autobot != address(0), "Valid bot address required");
            require(msg.sender == owner() || msg.sender == genomes[_genomeId].autobot, "Only primary or genome-assigned bot may assign");
            
            genomes[_genomeId].autobot = _autobot;

            emit GenomeAutobotAssigned(_genomeId, _autobot);
    }

    function assignPrimaryAutobot(
        address _autobot)
        public {
            require(_autobot != address(0), "Valid bot address required");
            require(msg.sender == owner(), "Only owner can assign primary autobot");
            
            autobot = _autobot;

            emit AutobotAssigned(_autobot);
    }

    function addSNaPs(
        uint256 _genomeId,
        string[] memory _rsids,
        string[] memory _chromosomes,
        string[] memory _positions,
        string[] memory _genotypes)
        public
        onlyOwner
        {
        _validateGenome(_genomeId);
        require(_rsids.length ==_chromosomes.length && _rsids.length == _positions.length && _rsids.length == _genotypes.length, "Data length mismatch");
        require(genomes[_genomeId].snapsAdded.current() + _rsids.length <= genomes[_genomeId].totalSize, "Too many snaps");

        for (uint256 i = 0; i < _rsids.length; i++) {
            numSnaps.increment();
            genomes[_genomeId].snapsAdded.increment();
            snaps[numSnaps.current()] = SNaP({
                genomeId: _genomeId,
                rsid: _rsids[i], 
                chromosome: _chromosomes[i], 
                position: _positions[i], 
                genotype: _genotypes[i]
            });

            emit SNaPAdded(numSnaps.current(), _genomeId);
        }
    }

    /*
    Conditions for validating a provided genome id.
    */
    function _validateGenome(
        uint256 _genomeId)
        private 
        view {
        if (_genomeId <= 0 || _genomeId < numGenomes.current()) {
            revert("Genome id out of range");
        }
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