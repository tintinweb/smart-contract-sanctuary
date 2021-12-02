/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;







interface IATLToken {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function mint(address _to, uint256 _amount) external;

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


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

// The Atlantis Mint controls the creation of new DRIP.
// Please note that it is ownable, and the owner wields
// the power to direct emissions. This contract should
// be owned by on-chain governance, or a community-owned
// multi-sig at minimum.
contract AtlantisMint is Ownable {
    event EmissionsChanged(uint256 indexed newEmissions);
    // The DRIP Token!
    IATLToken public immutable drip; 
    // Decimals for weights.
    uint256 internal immutable WEIGHT_DECIMALS = 10_000;
    // Approximately 20 months.
    uint256 internal immutable EMISSION_INTERVAL = 50_000_000;
    // 3,3b.
    uint256 public immutable maxSupply = 3_300_000_000_000_000_000_000_000_000;
    // All per block emission rates.
    uint256[] public emissions;
    // Last block when emissions halved.
    uint256 public lastEmissionsChange;
    // Addresses with voting weight.
    address[] public weighted;
    // Address weights.
    mapping(address => uint256) public weights;
    // Addresses removed.
    address[] public blacklisted;
    // Last time weighted address engaged mint function.
    mapping(address => uint256) public lastEngaged;
    // Total weights.
    uint256 public totalWeight;

    constructor(
        address _drip,
        uint256 _emissions
    ) public {
        require(_drip != address(0));
        drip = IATLToken(_drip);
        emissions.push(_emissions);
        lastEmissionsChange = block.number;
    }

    // mints new DRIP for weighted address
    function mint() external {
        require(weights[msg.sender] > 0, "...no");
        _checkEmissions();
        uint256 toMint = availableTo(msg.sender);
        require(drip.totalSupply() + toMint <= maxSupply, "shops closed");
        lastEngaged[msg.sender] = block.number;
        drip.mint(msg.sender, toMint);
    }

    // returns emissions per second for weighted address
    function emissionsFor(address _address) public view returns (uint256) {
        uint256 current = emissions[emissions.length - 1];
        if (block.number > lastEmissionsChange + EMISSION_INTERVAL) {
            current /= 2;
        }
        return current * weights[_address] / WEIGHT_DECIMALS;
    }

    // DRIP waiting to be minted by weighted address
    function availableTo(address _address) public view returns (uint256) {
        uint256 blocks = lastEngaged[msg.sender] - block.number;
        return emissionsFor(_address) * blocks;
    }

        // reduces emissions on set intervals
    function _checkEmissions() internal {
        if (block.timestamp > lastEmissionsChange + EMISSION_INTERVAL) {
            emissions.push(emissions[emissions.length - 1] / 2);
            lastEmissionsChange = block.timestamp;
            emit EmissionsChanged(emissions[emissions.length - 1]);
        }
    }

    // is address in array
    function _contains(address _address, address[] memory _array) internal pure returns (bool) {
        for(uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // sets weight for address
    function setWeight(address _address, uint256 _weight) external onlyOwner {
        require(_contains(_address, weighted) && !_contains(_address, blacklisted));
        uint256 current = weights[_address];
        if(_weight > current) {
            require(totalWeight + (_weight - current) <= WEIGHT_DECIMALS);
            totalWeight += (_weight - current);
        } else {
            totalWeight -= (current - _weight);
        }
        weights[_address] = _weight;
    }

    // adds address for weight
    function addWeight(address _address) external onlyOwner {
        require(!_contains(_address, weighted), "Has weight");
        weighted.push(_address);
    }

    // remove in disgrace
    function blacklist(address _address) external onlyOwner {
        require(!_contains(_address, blacklisted));
        blacklisted.push(_address);
        totalWeight -= weights[_address];
        weights[_address] = 0;
    }
}