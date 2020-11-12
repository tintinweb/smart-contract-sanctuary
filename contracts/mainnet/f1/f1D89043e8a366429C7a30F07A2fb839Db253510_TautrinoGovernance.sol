// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;


// 
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

// 
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

enum RebaseResult { Double, Park, Draw }

interface IPriceManager {
    function averagePrice() external returns (uint32);
    function lastAvgPrice() external view returns (uint32);
    function setTautrino(address _tautrino) external;
}

interface ITautrinoToken {
    function rebase(RebaseResult result) external returns (uint);
    function setGovernance(address _governance) external;
}

contract TautrinoGovernance is Ownable {

    event LogRebase(uint64 epoch, uint32 ethPrice, RebaseResult tauResult, uint tauTotalSupply, RebaseResult trinoResult, uint trinoTotalSupply);

    uint64 public constant REBASE_CYCLE = 1 hours;

    ITautrinoToken public tauToken;
    ITautrinoToken public trinoToken;

    IPriceManager public priceManager;

    RebaseResult private _lastTauRebaseResult;
    RebaseResult private _lastTrinoRebaseResult;

    uint64 private _nextRebaseEpoch;
    uint64 private _lastRebaseEpoch;

    uint64 public rebaseOffset = 3 minutes;

    /**
     * @dev Constructor.
     * @param _tauToken The address of TAU token.
     * @param _trinoToken The address of TRINO token.
     */

    constructor(address _tauToken, address _trinoToken, uint64 _delay) public Ownable() {
        tauToken = ITautrinoToken(_tauToken);
        trinoToken = ITautrinoToken(_trinoToken);
        _nextRebaseEpoch = uint64(block.timestamp - block.timestamp % 3600) + REBASE_CYCLE + _delay;
    }

    /**
     * @dev Update rebase offset.
     * @param _rebaseOffset new rebase offset.
     */

    function setRebaseOffset(uint64 _rebaseOffset) external onlyOwner {
        rebaseOffset = _rebaseOffset;
    }

    /**
     * @dev Rebase TAU and TRINO tokens.
     */

    function rebase() external onlyOwner {
        require(_nextRebaseEpoch <= uint64(block.timestamp) + rebaseOffset, "Not ready to rebase!");

        uint32 _ethPrice = priceManager.averagePrice();
        uint32 _number = _ethPrice;

        uint8 _even = 0;
        uint8 _odd = 0;

        while (_number > 0) {
            if (_number % 2 == 1) {
                _odd += 1;
            } else {
                _even += 1;
            }
            _number /= 10;
        }

        if (_even > _odd) {
            // double balance
            _lastTauRebaseResult = RebaseResult.Double;
            _lastTrinoRebaseResult = RebaseResult.Park;
        } else if (_even < _odd) {
            // park balance
            _lastTauRebaseResult = RebaseResult.Park;
            _lastTrinoRebaseResult = RebaseResult.Double;
        } else {
            _lastTauRebaseResult = RebaseResult.Draw;
            _lastTrinoRebaseResult = RebaseResult.Draw;
        }

        _lastRebaseEpoch = uint64(block.timestamp);
        _nextRebaseEpoch = _nextRebaseEpoch + 1 hours;
        if (_nextRebaseEpoch <= _lastRebaseEpoch) {
            _nextRebaseEpoch = uint64(block.timestamp - block.timestamp % 3600) + REBASE_CYCLE;
        }

        uint _tauTotalSupply = tauToken.rebase(_lastTauRebaseResult);
        uint _trinoTotalSupply = trinoToken.rebase(_lastTrinoRebaseResult);

        emit LogRebase(_lastRebaseEpoch, _ethPrice, _lastTauRebaseResult, _tauTotalSupply, _lastTrinoRebaseResult, _trinoTotalSupply);
    }

    /**
     * @return Price of eth used for last rebasing.
     */

    function lastAvgPrice() public view returns (uint32) {
        return priceManager.lastAvgPrice();
    }

    /**
     * @return Next rebase epoch.
     */

    function nextRebaseEpoch() public view returns (uint64) {
        return _nextRebaseEpoch;
    }

    /**
     * @return Last rebase epoch.
     */

    function lastRebaseEpoch() public view returns (uint64) {
        return _lastRebaseEpoch;
    }

    /**
     * @return Last rebase result.
     */

    function lastRebaseResult() public view returns (RebaseResult, RebaseResult) {
        return (_lastTauRebaseResult, _lastTrinoRebaseResult);
    }

    /**
     * @dev Migrate governance.
     * @param _newGovernance new TautrinoGovernance address.
     */

    function migrateGovernance(address _newGovernance) external onlyOwner {
        require(_newGovernance != address(0), "invalid governance");
        tauToken.setGovernance(_newGovernance);
        trinoToken.setGovernance(_newGovernance);

        if (address(priceManager) != address(0)) {
            priceManager.setTautrino(_newGovernance);
        }
    }

    /**
     * @dev Update price manager.
     * @param _priceManager The address of new price manager.
     */

    function setPriceManager(address _priceManager) external onlyOwner {
        priceManager = IPriceManager(_priceManager);
    }
}