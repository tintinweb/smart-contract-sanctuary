pragma solidity 0.8.4;

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
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = msg.sender;
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AccountPairs is Ownable {
    mapping(bytes32 => bytes) records;
    mapping(string => mapping(string => Record[])) recordsByNetworkCurrency;
    mapping(bytes => Record[]) recordsByDepositAddress;
    mapping(address => bool) public isExecutor;

    struct Record {
        string userUuid;
        address internalWalletAddress;
        bytes depositAddress;
        string network;
        string currency;
    }

    modifier onlyExecutor() {
        require(isExecutor[msg.sender], "Sender is not an executor");
        _;
    }

    constructor(address[] memory _executors) public {
        for (uint256 i = 0; i < _executors.length; i++) {
            isExecutor[_executors[i]] = true;
        }
    }

    function addExecutors(address[] memory _executors) external onlyOwner {
        for (uint256 i = 0; i < _executors.length; i++) {
            isExecutor[_executors[i]] = true;
        }
    }

    function removeExecutors(address[] memory _executors) external onlyOwner {
        for (uint256 i = 0; i < _executors.length; i++) {
            isExecutor[_executors[i]] = false;
        }
    }

    function createRecord(
        string memory _userUuid,
        address _internalWalletAddress,
        bytes calldata _depositAddress,
        string memory _network,
        string memory _currency
    ) external onlyExecutor {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _userUuid,
                _internalWalletAddress,
                _network,
                _currency
            )
        );

        require(records[hash].length == 0, "Record already exist");

        records[hash] = _depositAddress;

        recordsByNetworkCurrency[_network][_currency].push(
            Record(
                _userUuid,
                _internalWalletAddress,
                _depositAddress,
                _network,
                _currency
            )
        );
        recordsByDepositAddress[_depositAddress].push(
            Record(
                _userUuid,
                _internalWalletAddress,
                _depositAddress,
                _network,
                _currency
            )
        );
    }

    function getRecord(
        string memory _network,
        string memory _currency,
        string memory _userUuid,
        address _internalWalletAddress
    ) external view returns (bytes memory) {
        return
            records[
                keccak256(
                    abi.encodePacked(
                        _userUuid,
                        _internalWalletAddress,
                        _network,
                        _currency
                    )
                )
            ];
    }

    function getAllRecordsByNetworkAndCurrency(
        string memory _network,
        string memory _currency
    ) external view returns (Record[] memory) {
        return recordsByNetworkCurrency[_network][_currency];
    }

    function getAllRecordsByDepositAddress(bytes calldata _depositAddress)
        external
        view
        returns (Record[] memory)
    {
        return recordsByDepositAddress[_depositAddress];
    }
}