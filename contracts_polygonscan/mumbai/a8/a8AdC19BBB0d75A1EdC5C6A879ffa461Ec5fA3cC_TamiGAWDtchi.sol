// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./utils/TrustedForwarderRecipient.sol";

contract TamiGAWDtchi is TrustedForwarderRecipient {
    // * CONSTANTS * //
    enum PrayerType {
        WORSHIP,
        MARVEL,
        SACRIFICE,
        COWER
    }
    uint16 private constant _GAWDS_MIN_TOKEN = 1;
    uint16 private constant _GAWDS_MAX_TOKEN = 10_000;

    // * STORAGE * //
    uint16 private _BLOCKS_PER_TICK = 3024;
    uint256 internal _deployedBlock;
    mapping(address => mapping(uint16 => uint256)) public prayers;
    mapping(uint16 => uint256) private _lastWorshipBlock;
    mapping(uint16 => uint256) private _lastMarvelBlock;
    mapping(uint16 => uint256) private _lastSacrificeBlock;
    mapping(uint16 => uint256) private _lastCowerBlock;
    mapping(uint16 => uint8) private _worship;
    mapping(uint16 => uint8) private _marvel;
    mapping(uint16 => uint8) private _sacrifice;
    mapping(uint16 => uint8) private _cower;
    mapping(uint16 => uint256) public resurrectionCounts;

    // * EVENTS * //
    event Prayed(
        address indexed prayer,
        uint16 indexed gawd,
        PrayerType indexed prayerType
    );
    event Resurrected(uint16 indexed gawd, address indexed resurrector);

    // * MODIFIERS * //
    modifier isTrueGawd(uint16 gawd) {
        require(
            gawd >= _GAWDS_MIN_TOKEN && gawd <= _GAWDS_MAX_TOKEN,
            "Not true GAWD"
        );
        _;
    }

    // * CONSTRUCTOR * //
    constructor(address forwarderAddress)
        TrustedForwarderRecipient(forwarderAddress)
    {
        _deployedBlock = block.number;
    }

    // * PUBLIC FUNCTIONS *  //
    function worship(uint16 gawd) public isTrueGawd(gawd) {
        require(getAlive(gawd), "blind with rage");
        require(getSacrifice(gawd) < 80, "sacrifice first");
        require(getMarvel(gawd) < 80, "u must marvel");

        _lastWorshipBlock[gawd] = block.number;

        _worship[gawd] = 0;
        _sacrifice[gawd] += 10;
        _marvel[gawd] += 3;

        addPrayer(msg.sender, 1, PrayerType.WORSHIP);
    }

    function marvel(uint16 gawd) public isTrueGawd(gawd) {
        require(getAlive(gawd), "blind with rage");
        require(getMarvel(gawd) > 0, "your adoration is adequate");
        _lastMarvelBlock[gawd] = block.number;

        _marvel[gawd] = 0;

        addPrayer(msg.sender, 1, PrayerType.MARVEL);
    }

    function sacrifice(uint16 gawd) public isTrueGawd(gawd) {
        require(getAlive(gawd), "blind with rage");
        require(getWorship(gawd) < 80, "lil worship plz");
        require(getCower(gawd) < 80, "cmon cower a bit");
        require(getMarvel(gawd) < 80, "marvel at me some");

        _lastSacrificeBlock[gawd] = block.number;

        _sacrifice[gawd] = 0;
        _worship[gawd] += 10;
        _cower[gawd] += 10;
        _marvel[gawd] += 5;

        addPrayer(msg.sender, 1, PrayerType.SACRIFICE);
    }

    function cower(uint16 gawd) public isTrueGawd(gawd) {
        require(getAlive(gawd), "blind with rage");
        require(getMarvel(gawd) < 80, "show some love first");
        require(getCower(gawd) > 0, "you know your place");

        _lastCowerBlock[gawd] = block.number;

        _cower[gawd] = 0;
        _marvel[gawd] += 5;

        addPrayer(msg.sender, 1, PrayerType.COWER);
    }

    function resurrect(uint16 gawd) public isTrueGawd(gawd) {
        require(getAlive(gawd) == false, "peaceful");
        require(
            block.number > getEarliestBlockForResurrection(gawd),
            "too enraged for resurrection"
        );

        _worship[gawd] = 0;
        _sacrifice[gawd] = 0;
        _cower[gawd] = 0;
        _marvel[gawd] = 0;
        _lastWorshipBlock[gawd] = block.number;
        _lastMarvelBlock[gawd] = block.number;
        _lastSacrificeBlock[gawd] = block.number;
        _lastCowerBlock[gawd] = block.number;

        resurrectionCounts[gawd]++;
        emit Resurrected(gawd, msg.sender);
    }

    // * PUBLIC READ FUNCTIONS * //
    function getStatus(uint16 gawd)
        public
        view
        isTrueGawd(gawd)
        returns (string memory)
    {
        uint256 mostNeeded = 0;

        string[4] memory goodStatus = [
            "gm greetings mortal",
            "glory be unto me",
            "divine",
            "u r blessed"
        ];

        string memory status = goodStatus[block.number % 4];

        uint256 _worshipN = getWorship(gawd);
        uint256 _marvelN = getMarvel(gawd);
        uint256 _sacrificeN = getSacrifice(gawd);
        uint256 _cowerN = getCower(gawd);

        if (getAlive(gawd) == false) {
            return "blind with rage";
        }

        if (_worshipN > 50 && _worshipN > mostNeeded) {
            mostNeeded = _worshipN;
            status = "praise me";
        }

        if (_marvelN > 50 && _marvelN > mostNeeded) {
            mostNeeded = _marvelN;
            status = "witness my greatness";
        }

        if (_sacrificeN > 50 && _sacrificeN > mostNeeded) {
            mostNeeded = _sacrificeN;
            status = "sacrifice plz";
        }

        if (_cowerN > 50 && _cowerN > mostNeeded) {
            mostNeeded = _cowerN;
            status = "cower in fear";
        }

        return status;
    }

    function getAlive(uint16 gawd) public view isTrueGawd(gawd) returns (bool) {
        return
            getWorship(gawd) < 101 &&
            getMarvel(gawd) < 101 &&
            getSacrifice(gawd) < 101 &&
            getCower(gawd) < 101;
    }

    function getWorship(uint16 gawd)
        public
        view
        isTrueGawd(gawd)
        returns (uint256)
    {
        uint256 lastBlock = _lastWorshipBlock[gawd] == 0
            ? _deployedBlock
            : _lastWorshipBlock[gawd];
        return _worship[gawd] + ((block.number - lastBlock) / _BLOCKS_PER_TICK);
    }

    function getMarvel(uint16 gawd)
        public
        view
        isTrueGawd(gawd)
        returns (uint256)
    {
        uint256 lastBlock = _lastMarvelBlock[gawd] == 0
            ? _deployedBlock
            : _lastMarvelBlock[gawd];
        return _marvel[gawd] + ((block.number - lastBlock) / _BLOCKS_PER_TICK);
    }

    function getSacrifice(uint16 gawd)
        public
        view
        isTrueGawd(gawd)
        returns (uint256)
    {
        uint256 lastBlock = _lastSacrificeBlock[gawd] == 0
            ? _deployedBlock
            : _lastSacrificeBlock[gawd];
        return
            _sacrifice[gawd] + ((block.number - lastBlock) / _BLOCKS_PER_TICK);
    }

    function getCower(uint16 gawd)
        public
        view
        isTrueGawd(gawd)
        returns (uint256)
    {
        uint256 lastBlock = _lastCowerBlock[gawd] == 0
            ? _deployedBlock
            : _lastCowerBlock[gawd];
        return _cower[gawd] + ((block.number - lastBlock) / _BLOCKS_PER_TICK);
    }

    function getEarliestBlockForResurrection(uint16 gawd)
        public
        view
        isTrueGawd(gawd)
        returns (uint256)
    {
        require(getAlive(gawd) == false, "peaceful");
        return
            1 +
            (((resurrectionCounts[gawd] + 1)**2) * 100 * _BLOCKS_PER_TICK) +
            _lastWorshipBlock[gawd];
    }

    // * INTERNAL FUNCTIONS * //
    function addPrayer(
        address prayer,
        uint16 gawd,
        PrayerType prayerType
    ) internal {
        prayers[prayer][gawd] += 1;
        emit Prayed(prayer, gawd, prayerType);
    }

    // * TEST FUNCTIONS * //
    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function getDeployedBlock() public view returns (uint256) {
        return _deployedBlock;
    }

    function setBlocksPerTick(uint16 blocksPerTick) public onlyOwner {
        _BLOCKS_PER_TICK = blocksPerTick;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TrustedForwarderRecipient is Ownable {
    address internal _trustedForwarder;

    constructor(address forwarderAddress_) {
        _trustedForwarder = forwarderAddress_;
    }

    // ERC2771Context
    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function setForwarder(address trustedForwarder_) public onlyOwner {
        _trustedForwarder = trustedForwarder_;
    }

    function versionRecipient() external pure returns (string memory) {
        return "1";
    }
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
    "enabled": false,
    "runs": 200
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