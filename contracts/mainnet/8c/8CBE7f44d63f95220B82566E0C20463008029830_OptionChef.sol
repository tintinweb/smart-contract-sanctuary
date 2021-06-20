//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;


import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOptions.sol";
import "./interfaces/IHegexoption.sol";
import "./interfaces/IChefData.sol";

/**
 * @author [email protected]
 * @title Option factory aka Mighty Option Chef
 * @notice Option Chef has the monopoly to mint and destroy NFT Hegexoptions
 */
contract OptionChef is Ownable {

    //storage

    IHegicOptions public hegicOptionETH;
    IHegicOptions public hegicOptionBTC;
    IHegexoption public hegexoption;
    IOptionChefData public chefData;

    //ideally this should've been a mapping/arr of id->Struct {owner, id}
    //there are a few EVM gotchas for this (afaik one can't peek into
    //mapped structs from another contracts, happy to restructure if I'm wrong though)
    // mapping (uint => uint) uIds;
    // mapping (uint => uint) ids;

    //events

    event Wrapped(address account, uint optionId);
    event Unwrapped(address account, uint tokenId);
    event Exercised(uint _tokenId, uint profit);
    event CreatedHegic(uint optionId, uint hegexId);


    //utility functions

    function updateHegicOption(IHegicOptions _hegicOptionETH,
                               IHegicOptions _hegicOptionBTC)
        external
        onlyOwner {
        hegicOptionETH = _hegicOptionETH;
        hegicOptionBTC = _hegicOptionBTC;
    }

    function updateHegexoption(IHegexoption _hegexoption)
        external
        onlyOwner {
        hegexoption = _hegexoption;
    }

    constructor(IHegicOptions _hegicOptionETH,
                IHegicOptions _hegicOptionBTC,
                IOptionChefData  _chefData) public {
        hegicOptionETH = _hegicOptionETH;
        hegicOptionBTC = _hegicOptionBTC;
        chefData = _chefData;
    }

    // direct user to a right contract
    // NOTE: optimize to bool if gas savings are substantial
    function getHegic(uint8 _optionType) public view returns (IHegicOptions) {
        if (_optionType == 0) {
            return hegicOptionETH;
        } else  {
            return hegicOptionBTC;
        }
    }

    //core (un)wrap functionality


    /**
     * @notice Hegexoption wrapper adapter for Hegic
     */
    function wrapHegic(uint _uId, uint8 _optionType) public returns (uint newTokenId) {
        require(chefData.ids(_uId) == 0 , "UOPT:exists");
        IHegicOptions hegicOption = getHegic(_optionType);
        (, address holder, , , , , , ) = hegicOption.options(_uId);
        //auth is a bit unintuitive for wrapping, see NFT.sol:isApprovedOrOwner()
        require(holder == msg.sender || holder == address(this), "UOPT:ownership");
        newTokenId = hegexoption.mintHegexoption(msg.sender);
        chefData.setuid(newTokenId, _uId);
        chefData.setid(_uId, newTokenId);
        chefData.setoptiontype(_uId, _optionType);
        emit Wrapped(msg.sender, _uId);
    }

    /**
     * @notice Hegexoption unwrapper adapter for Hegic
     * @notice check burning logic, do we really want to burn it (vs meta)
     * @notice TODO recheck escrow mechanism on 0x relay to prevent unwrapping when locked
     */
    function unwrapHegic(uint8 _optionType, uint _tokenId) external onlyTokenOwner(_tokenId) {
        // checks if hegicOption will allow to transfer option ownership
        IHegicOptions hegicOption = getHegic(_optionType);
        (IHegicOptions.State state, , , , , , uint expiration ,) = getUnderlyingOptionParams(_optionType, _tokenId);
        if (state == IHegicOptions.State.Active || expiration >= block.timestamp) {
            hegicOption.transfer(chefData.uIds(_tokenId), msg.sender);
        }
        //burns anyway if token is expired
        hegexoption.burnHegexoption(_tokenId);
        uint utokenid = chefData.uIds(_tokenId);
        chefData.setid(utokenid, 0);
        chefData.setuid(_tokenId, 0);
        emit Unwrapped(msg.sender, _tokenId);
    }

    function exerciseHegic(uint8 _optionType, uint _tokenId) external onlyTokenOwner(_tokenId) {
        IHegicOptions hegicOption = getHegic(_optionType);
        hegicOption.exercise(getUnderlyingOptionId(_tokenId));
        uint profit = address(this).balance;
        payable(msg.sender).transfer(profit);
        emit Exercised(_tokenId, profit);
    }

    uint256 public migrationLock = 0;
    address payable public newChef;

    /**
     * @notice  Migrate chef (effective after 72 hours)
     * @param _newChef chef address
     */
    function migrateChefWithTimelock(address payable _newChef) public onlyOwner {
        if (migrationLock != 0 && (block.timestamp > migrationLock + 72 hours)) {
            chefData.transferOwnership(newChef);
            hegexoption.migrateChef(newChef);
            migrationLock = 0;
        } else {
            migrationLock = block.timestamp;
            newChef = _newChef;
        }
    }

    function getUnderlyingOptionId(uint _tokenId) public view returns (uint) {
        return chefData.uIds(_tokenId);
    }

    function getUnderlyingOptionParams(uint8 _optionType, uint _tokenId)
        public
        view
        returns (
        IHegicOptions.State state,
        address payable holder,
        uint256 strike,
        uint256 amount,
        uint256 lockedAmount,
        uint256 premium,
        uint256 expiration,
        IHegicOptions.OptionType optionType)
    {
        (state,
         holder,
         strike,
         amount,
         lockedAmount,
         premium,
         expiration,
         optionType) = getHegic(_optionType).options(chefData.uIds(_tokenId));
    }

    /**
     * @notice check whether Chef has underlying option locked
     */
    function isDelegated(uint _tokenId) public view returns (bool) {
        uint8 optionType = chefData.optionType(chefData.uIds(_tokenId));
        IHegicOptions hegicOption = getHegic(optionType);
        ( , address holder, , , , , , ) = hegicOption.options(chefData.uIds(_tokenId));
        return holder == address(this);
    }

    function createHegic(
        uint8 _hegicOptionType,
        uint _period,
        uint _amount,
        uint _strike,
        IHegicOptions.OptionType _optionType
    )
        payable
        external
        returns (uint)
    {
        IHegicOptions hegicOption = getHegic(_hegicOptionType);
        uint optionId = hegicOption.create{value: msg.value}(_period, _amount, _strike, _optionType);
        // return eth excess
        payable(msg.sender).transfer(address(this).balance);
        uint hegexId = wrapHegic(optionId, _hegicOptionType);
        emit CreatedHegic(optionId, hegexId);
        return hegexId;
    }

    modifier onlyTokenOwner(uint _itemId) {
        require(msg.sender == hegexoption.ownerOf(_itemId), "UOPT:ownership/exchange");
        _;
    }

    receive() external payable {}
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IOptionChefData {
    function uIds(uint k) external view returns (uint);
    function ids(uint k) external view returns (uint);
    function optionType(uint k) external view returns (uint8);

    function setuid(uint k, uint v) external;
    function setid(uint k, uint v) external;
    function setoptiontype(uint k, uint8 v) external;
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IHegexoption {
    //custom functions in use
    function burnHegexoption(uint _id) external;
    function mintHegexoption(address _to) external returns (uint256);
    function migrateChef(address payable _optionChef) external;
    //IERC721 functions in use
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IHegicOptions {
    event Create(
        uint256 indexed id,
        address indexed account,
        uint256 settlementFee,
        uint256 totalFee
    );

    event Exercise(uint256 indexed id, uint256 profit);
    event Expire(uint256 indexed id, uint256 premium);
    enum State {Inactive, Active, Exercised, Expired}
    enum OptionType {Invalid, Put, Call}

    struct Option {
        State state;
        address payable holder;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        OptionType optionType;
    }

    function create(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionType optionType
    )
        external
        payable
        returns (uint256 optionID);

    function transfer(uint256 optionID, address payable newHolder) external;

    function exercise(uint256 optionID) external;

    function options(uint) external view returns (
        State state,
        address payable holder,
        uint256 strike,
        uint256 amount,
        uint256 lockedAmount,
        uint256 premium,
        uint256 expiration,
        OptionType optionType
    );

    function unlock(uint256 optionID) external;
}

interface IHegicETHOptions is IHegicOptions {
        function fees(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionType optionType
    )
        external
        view
        returns (
            uint256 total,
            uint256 settlementFee,
            uint256 strikeFee,
            uint256 periodFee
        );
}

interface IHegicERC20Options is IHegicOptions {
    function fees(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionType optionType
    )
        external
        view
        returns (
            uint256 total,
            uint256 totalETH,
            uint256 settlementFee,
            uint256 strikeFee,
            uint256 periodFee
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
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