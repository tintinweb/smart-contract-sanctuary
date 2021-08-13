/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

pragma solidity ^0.5.0;


/**
                                  ▄▄▄▄       ░
                              ▄▄██▓▓▓███▄ ▀▀▄▓▄▄▄▀▀▀ ▀
              ▀ ▄▄         ▄██▓▓░░░░▓▓▓▓▓██▄ ▀  ▄▄▄██████▄▄▄▄▄
              ▄▀░ ▀▄     ▄█▓▓▓░░░  ░░░░░░░▓▓█▄██▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓░ ░
              █   ▓█   ▄█▓▓▓░░░      ░░░░▓▓██▓▓▓▓░░░░░░░░░░░░▓▓▓██
               ▀▄▓▀   █▓▓▓░░░         ░░░▓█▓▓▓░░░░░       ░░▓▓▓██  ▄
                   ▄▄█▓▓░░░         ░ ░░▓█░░░░░░     ░░░░▓▓▓████▄ ▀▓▀
              ▄▄███▓▓▓░░░            ░░▓▓▓░            ░░░░░▓▓████▄
              ▀▀█▓▓▓░░░          ░  ░░░▓█▓░░               ░░░▓▓███▄
      ▄▓▄      ░▄█▓░░   ░      ░  ░░░▓▓██▓▓░░░         ░░░   ░░░▓▓▓██
       ▀    ▄▄██▓▓▓░  ░░      ░▓░░░▓█████▓░░░░░          ░░░   ░░░░▓██
  ▄▀▀▄   ▄██▓▓▓░░░▓░░  ░       ░▓▓██▓▓▓▓█▓▓░░               ░    ░░░▓██
  █ ▓█  ██▓▓░░░░ ░░▓░         ░▓██▓░░░░▓▓█▓▓░░                    ░░░▓██▄
   ▀▀  ██▓░░░     ░░░      ░░░▓█▓░░ ░  ░ ▓█▓▓░░░                   ░░░▓███▄▄
      ██▓░   ░  ░   ░░      ░▓█░░  ░  ░ ░ ░▀█▓▓▓░░░░            ░░░░░▓▓▓██▀
    ▄██▓▓▓▓░░    ░░  ░░    ░▓█░░ ░       ░ ░ █▀██▓▓░░░░░░░░   ░░░▓▓▓▓▓▓██
    ▀▀▀████▓▓░░      ░    ░▓█▓░ ░       ░ ░   ░ ░███▓▓▓▓▓▓░░░   ░░░▓▓██▀
     ▄ ░██▓▓░       ░    ░▓██▓█▄       ░▄██▀▀▄   ░▓▓█████▓▓▓░░   ░░░▓▓██░  ▄▄
    ▀▓▀ ██▓░             ░▓█▓▓▄█▓     ░█░█▓▓  ▄ ░ ░▓▓███▓▓▓▓▓░░   ░░▓▓▓█▓ █ ▓█
        ░█▓░             ░▓█▓░▀        ▀▀██▄▀     ░░███▓▓░░░░▓░    ░░▓▓██  ▀▀
     ░ ░▓█▓░            ░▓█▓░ ░    █             ░░░▓██▓░░  ░░░     ░░▓▓█  ▄▓▄
  ▄▄   ██▓░░            ░▓█▓ ░   ▄█░          ░ ░ ░▓▓█▓▓░   ░      ░░░▓▓▓█  ▀
 █ ▓█ ██▓░░            ░░▓█░░     ▀▀           ░░░░▓██▓░░            ░░░░▓█
  ▀▀  █▓░░     ░    ░░░▓▓▓██░                   ░░▓█▓▓▓░           ░   ░░░▓█
     ██▓░░     ░      ░░░▓▓██░               ░ ░░▓██▓░░           ░   ░░░░▓▓█
  ▄  █▓░░     ░░░░     ░░░▓▓█▓░  ▀█▓▄         ░▓███▓░░               ░░▓░░▓▓██
    ██▓░      ░░▓░░░ ░░ ░░░░▓█▄            ░▓██████▓░░   ░            ▓█▓▓▓▓██
    █▓░░     ░░▓▓▓▓░░░░░░░░░░▓██▄        ▄▄█▀▓▓███▓░░     ▓░ ░░░░░░   ░▓██▓▓█
   ██▓░  ░  ░▓▓▓██▓▓▓▓▓▓▓▓▓░░░▓▓███▄▄▄▀▀▀  ░░░▓▓██▓░░░ ░   █▓▓▓▓▓▓░░░░ ░▓████
   █▓░░    ░░░▓████████████▓▓▓████▓░         ░▓██▓░░░░░░   ░███████▓▓░░ ░▓██
  ██▓░     ░░▓██▓▓▓░░░░░░░░███████▄    ░    ░░▓█▓▓▓▓▓▓▓░░  ░██▓▓▓▓▓██▓░░░▓██
  ██▓░░ ░░ ░▓██▓░░░░░         ░░░▓▓▀        ░░▀████▀▀▀█▓▓░  ▓█░░░▓▓▓▓█▓░░▓██
   ██▓░░▓▓░▓██▓░░            ▄▄▄                       ▀█▓ ░▓█░ ░░░▓▓██░▓███
    ██▓▓▓█▓▓█▓░░        ▄▄▀▀▀ ░░▓▄  ▄    ▄  ▄▓▀▀▄▄      ▀█▓█▀ ░  ░░▓▓▓█▓▓██  ▀
     ▀██▓▓██▓▓░░                 ░▀▀      ▀▀░     ▀▀░    █▀       ░░▓▓█▓▓██
       ▀████▓░░     ░                                    ▓        ░░▓▓█▓██
     ▄    ▓█▓░░    ░▓                                   ░     ░   ░░▓█▓██  ▄▓▄
          ░█▓▓░   ░▓█▄░                                      ░     ░▓███    ▀
     ▄▀▀▄  ░█▓░░ ░▓▓█░                                      ░▓     ░▓██ ▄▀▀▄
    █ ░ ▓█  █▓░░░▓▓█░                    ░                 ░▓▓    ░░▓██ ▀▄▓▀
     ▀▄▓▀   ▓█▓░▓██░░░░         ░        ░  ░░            ▄▓█░    ░▓▓█▓█    ▄▄
        ▄▓▄ ░█▓██▓░░░            ░     ░░▓░░░   ░░░░      ░█▓░    ░▓█▓░▓█▄▄█▓█
         ▀   ██▓▓░░               ░░▄ ░▓▓█░▓░░░░░         ░█▓░    ░▓█░ ░░▓▓▓▓█
  ▄░▀▀▀▄    ██▓▓░░                 ░▓██▓███▓▓░░░        ░░▓▓█░    ░▓█▓   ░░▓█
 █░░  ░▓█   █▓▓░░  ▄░              ░░▓████▓▓░░░          ░░▓█▓░   ░▓██▓░░░▓█
 █░   ░▓█  ██▓▓░  █░ ▄▄  ▄          ░░▓██▓▓░░░            ░▓█▓░   ░▓███▓▓█▀
  ▀▄▄▓▓▀   █▓▓░░ █░ █▓░█ ░█          ░▓██▓▓░░░            ░▓▓█▓░  ░▓██▓▀▀
          ██▓▓░░ █▓  ░▀  ▓█         ░░▓▓█▓▓░░░            ░░▓▓█░  ░▓█▓░     ▄▓▄
          █▓▓▓░░  ▀▓▄▄▄▄▓▀          ░░▓▓█▓▓░░             ░░░▓▓█░ ░░▓█░      ▀
     ▀    ██▓▓░░░                  ░░▓▓██▓▓░░              ░░▓▓█▓  ░▓█
          ▀█▓▓░░░                 ░░░▓▓██▓▓░░              ░░░▓▓█░ ░▓█░   ▀
       ▄▓▄ █▓▓▓░░░              ░░░░▓▓▓█▓▓▓░░               ░░▓▓█░ ░▓█
        ▀  ▀█▓▓▓░░░░       ░░░░░░▓▓▓▓▓██▓▓░░░       ▄▓▓░     ░░▓▓█░░▓█  ▄▄
     ▄▄▄    ▀█▓▓▓▓░░░░░░░░▓▓███████▓▓██▓▓▓░░       █▓        ░░▓▓█░░▓█ █ ▓█
   ▄▓░  ▀▄   ▀██▓▓▓░░░▓▓█▀▀▀░░░░▓▓█████▓▓░░░      █▓░ ▄▄     ░▓▓▓█░░▓█  ▀▀
  █▓░    ░█    ███▓▓▓███░       ░░░████▓▓░░░      █▓  ▄▓█   ░░░▓██ ░░▓█
  █░    ░▓█     ███▀█████▄▄▄███▄  ░░▓██▓▓░░░       █░  ▀  █ ░░▓▓█░  ░▓█  ▄▀▀▀▄
   ▀▄ ░░▓▀    ▄ ▓█▓░░▓██████▓▓▓██  ░░▓██▓▓░░░       ▀▓▓▄▄▀  ░░▓██░ ░▓▓█ █ ░ ░▓█
     ▀▀▀         ▀█▀▄░░░▓████▓██▓   ░▓██▓▓░░░░             ░░▓██▓░░▓▓██  ▀▄▄▓▀
            ▄░▀▄  ▀▄ ▀▄░░░░▀▀▀▀░  ░░░▓▓██▓▓▓░░░░       ░ ░░▓▓██▓▓▓███▀
           █  ░▓█   ▀▄ ▀▀▄▄     ░░░▓███▀███▓▓▓▓░░░░░░░░░░▓▓██████▀▀▀  ▄▓▄
            ▀░▓▀      ▀▀▄▄  ░░░▓▓██▀▀    ▀███▓▓▓▓▓▓░░░▓▓▓██▀▀          ▀
                  ▄      ▀▀█▀▀▀▀▀█   ▄▄▄    ▀▀██████████▀▀    ▀  ▄▓▄
                           █             ▄▓▄      █        ▀      ▀
   ▄▓▄            ▄▄  ▀▄▄▄▄ ▀▄  ▄▓▓██▄▄■  ▀    ▄▄██▄    ▀     ▄▄███   ░░░  ▀    ▄▄▄▄         
    ▀   ▄▄                                                                     ▄▀░   ▓▄  
       █ ▓█     /$$$$$$$$ /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$$              █ ░   ░▓█ 
        ▀▀     |__  $$__/| $$__  $$| $$_____/ /$$__  $$|__  $$__/          ▄▄  █    ░▓▓█ 
  ▄░▀▀▀▄          | $$   | $$  \ $$| $$      | $$  \ $$   | $$   ░        █ ▓█  ▀▄░░▓█▀
 █░   ░░█         | $$   | $$$$$$$/| $$$$$   | $$$$$$$$   | $$    ▄██      ▀▀    ▀▀▀▀  ▄ 
 █    ░▓█         | $$   | $$__  $$| $$__/   | $$__  $$   | $$   ████▓▄    
  ▀▄▄▓▓▀          | $$   | $$  \ $$| $$      | $$  | $$   | $$   ███▓▓▌   ▄▓▄ 
  ░ ░             | $$   | $$  | $$| $$$$$$$$| $$  | $$   | $$        ▀
  ░ ░ ▀ ▄▓▄       |__/   |__/  |__/|________/|__/  |__/   |__/   ▄   
  ░ ░ ▄▄ ▀  █▀▀▀▀   ▀▀▀█▄▄▄▄█     ▄▀▀▀   ░            ▀▀ █   ▄ ▀      █    ▄▄ 
  ░ ░█ ▓█   █                                                         █   █ ▓█ 
  ░ ░ ▀▀  ▄ █                  bnb your self a treat                  █    ▀▀
  ░ ░ ░    ██▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▀▄
  ░ ░ ░   ■ █▀                                                        █
  ░ ░ ░                                                             



 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    
    
    /**
     * @dev integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // solidity only automatically asserts when dividing by 0
        require(b > 0, "safemath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // there is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "safemath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface TREATcontract {
    function balanceOf(address _owner) external view returns (uint256);
}

interface TreatNFTMinter {
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function create(uint256 _maxSupply, uint256 _initialSupply, string calldata _uri, bytes calldata _data, address _performerAddress) external returns (uint256 nftId);
    function mint(address _to, uint256 _id, uint256 _quantity, bytes calldata _data) external;
    function totalSupply(uint256 _id) external view returns (uint256);
    function maxSupply(uint256 _id) external view returns (uint256);
    function creators(uint256 nftId) external view returns (address payable);
    function referrers(address treatModel) external view returns (address payable);
    function isPerformer(address account) external view returns (bool);
}


contract BNBforTreatsMart is Ownable {
    using SafeMath for uint256;
    TreatNFTMinter public treatNFTMinter;
    TREATcontract public treatDaoToken;
    uint256 public melonNumber;
    address payable public treatTreasuryAddress;
    mapping(uint256 => uint256) public nftCosts;
    mapping(uint256 => address) public treatModels;
    mapping(uint256 => uint256) public performerPercentages;
    mapping(uint256 => uint256) public refPercentages;
    mapping(uint256 => uint256) public refSetPercentages;
    mapping(uint256 => address payable) internal creatorOverrides;
    mapping(address => address payable) internal creatorRefOverrides;
    mapping(uint256 => bool) public isGiveAwayCard;
    address payable public tittyFundAddress;
    uint256 public maxSetId;
    uint256 public nftIdV2Start;
    uint256 public defaultCreatorPercentage;
    uint256 public defaultRefPercentage;
    uint256 public melonCreatorPercentage;
    uint256 public melonRefPercentage;
    bool public paused;
    bool public pausedTreats;
    mapping(uint256 => uint256[]) public nftSetIds;
    mapping(uint256 => uint256) public nftSetCosts;
    mapping(uint256 => address payable) public treatSetModels;
    mapping(uint256 => uint256) public performerSetPercentages;

    event NFTAdded(uint256[] nftIds, uint256 points, address treatModel);
    event NFTsAdded(uint256[] nftIds, uint256[] points, address treatModel);
    event NFTCreatedAndAdded(uint256[] nftIds, uint256[] points, address treatModel);
    event SetAdded(uint256 indexed setId, uint256[] nftIds, uint256 points, address treatModel);
    event Redeemed(address indexed user, uint256 amount);
    event OnCreatorUpdated(address indexed oldAddress, address indexed newAddress);
    event OnCreatorRefUpdated(address indexed oldAddress, address indexed newAddress);

    constructor(TreatNFTMinter _TreatNFTMinterAddress, address payable _TreatTreasuryAddress, address _treatDaoAddress) public {
        treatNFTMinter = _TreatNFTMinterAddress;
        treatTreasuryAddress = _TreatTreasuryAddress;
        melonNumber = 734000000000000000000;
        defaultCreatorPercentage = 925;
        melonCreatorPercentage = 975;
        defaultRefPercentage = 200;
        melonRefPercentage = 400;
        nftIdV2Start = 92;
        treatDaoToken = TREATcontract(_treatDaoAddress);
        paused = false;
        pausedTreats = false;

        maxSetId = 0;
    }

    function createAndAddNFTs(uint256[] memory maxSupplys, uint256[] memory amounts, bool[] memory isGiveAwayFlags, bytes memory _data) public {
        require(treatNFTMinter.isPerformer(msg.sender) == true, "not performer role. cannot create nfts");
        require(pausedTreats == false, "Contract Paused");
        require(maxSupplys.length == amounts.length, "NFT Arrays not equal len");
        uint256[] memory newNftIds;
        for (uint256 i = 0; i < amounts.length; ++i) {
            uint256 newNftId = treatNFTMinter.create(maxSupplys[i],0,"",_data, msg.sender);
            newNftIds[i] = newNftId;
            nftCosts[newNftId] = amounts[i];
            if (isGiveAwayFlags[i] == false) {
                isGiveAwayCard[newNftId] = false;
            } else {
                isGiveAwayCard[newNftId] = true;
            }
            treatModels[newNftId] = msg.sender;
            performerPercentages[newNftId] = defaultCreatorPercentage;
            refPercentages[newNftId] = defaultRefPercentage;
        }
        emit NFTCreatedAndAdded(newNftIds, amounts, msg.sender);
    }

    function addNFT(uint256[] memory nftIds, uint256[] memory amounts) public {
        for (uint256 i = 0; i < nftIds.length; ++i) {
            require(nftIds[i] >= nftIdV2Start, "cant list nft ids from v1 minter");
            require(msg.sender == treatNFTMinter.creators(nftIds[i]), "cannot list nfts you did not create");
        }
        require(nftIds.length == amounts.length, "NFT Arrays not equal len");
        require(pausedTreats == false, "Contract Paused");
        for (uint256 i = 0; i < nftIds.length; ++i) {
            require(treatNFTMinter.maxSupply(nftIds[i]) > 0, "NFT doesn't exist");
            nftCosts[nftIds[i]] = amounts[i];
            isGiveAwayCard[nftIds[i]] = false;
            treatModels[nftIds[i]] = msg.sender;
            performerPercentages[nftIds[i]] = defaultCreatorPercentage;
            refPercentages[nftIds[i]] = defaultRefPercentage;
        }
        emit NFTsAdded(nftIds, amounts, msg.sender);
    }

    function addGiveAwayTreat(uint256[] memory nftIds) public {
        for (uint256 i = 0; i < nftIds.length; ++i) {
            require(nftIds[i] >= nftIdV2Start, "cant list nft ids from v1 minter");
            require(msg.sender == treatNFTMinter.creators(nftIds[i]), "cannot give away nft you did not create");
        }
        require(pausedTreats == false, "Contract Paused");
        for (uint256 i = 0; i < nftIds.length; ++i) {
            require(treatNFTMinter.maxSupply(nftIds[i]) > 0, "NFT doesn't exist");
            isGiveAwayCard[nftIds[i]] = true;
            nftCosts[nftIds[i]] = 0;
            treatModels[nftIds[i]] = treatNFTMinter.creators(nftIds[i]);
        }
        emit NFTAdded(nftIds, 0, msg.sender);
    } 

    function addSet(uint256[] memory nftIds, uint256 _amount) public {
        for (uint256 i = 0; i < nftIds.length; ++i) {
            require(nftIds[i] >= nftIdV2Start, "cant list nft ids from v1 minter");
            require(msg.sender == treatNFTMinter.creators(nftIds[i]), "cannot add nfts to set you did not create");
        }

        for(uint256 i = 0; i < nftIds.length; i++) {
            require(treatNFTMinter.maxSupply(nftIds[i]) > 0, "NFT doesn't exist");
        }

        require(pausedTreats == false, "Contract Paused");

        uint256 nextSetId = maxSetId.add(1);

        nftSetCosts[nextSetId] = _amount;
        nftSetIds[nextSetId] = nftIds;
        treatSetModels[nextSetId] = msg.sender;
        performerSetPercentages[nextSetId] = defaultCreatorPercentage;
        refSetPercentages[nextSetId] = defaultRefPercentage;

        maxSetId = nextSetId;

        emit SetAdded(nextSetId, nftIds, _amount, msg.sender);
    }

    function editSetCost(uint256 _setId, uint256 _newAmount) public {
        require(msg.sender == treatSetModels[_setId], "cannot edit set cost of set that is not yours");
        nftSetCosts[_setId] = _newAmount;
    }

    function getCreatorAddress(uint256 nftId) public view returns (address payable) {
        address payable overrideAddress = creatorOverrides[nftId];
        if(overrideAddress == address(0x00000000000000000000000000000000)) {
            return treatNFTMinter.creators(nftId);
        }

        return overrideAddress;
    }

    function getCreatorRefAddress(address treatModel) public view returns (address payable) {
        address payable overrideAddress = creatorRefOverrides[treatModel];
        if(overrideAddress == address(0x00000000000000000000000000000000)) {
            address payable refAddress = treatNFTMinter.referrers(treatModel);
            if(refAddress == address(0x00000000000000000000000000000000)) {
                refAddress = tittyFundAddress;
            }
            return refAddress;
        }

        return overrideAddress;
    }

    function setCreatorOverrides(uint256[] memory nftIds, address payable[] memory overrideAddresses) public onlyOwner {
        require(nftIds.length == overrideAddresses.length, "invalid arrays length");

        for(uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            address payable overrideAddress = overrideAddresses[i];
            address payable currentCreatorAddress = getCreatorAddress(nftId);

            require(msg.sender == currentCreatorAddress || msg.sender == owner(), "sender not contract owner or current creator");
            require(currentCreatorAddress != overrideAddress, "can't override to same address");

            emit OnCreatorUpdated(currentCreatorAddress, overrideAddress);
            creatorOverrides[nftId] = overrideAddress;
        }
    }
    
    function setCreatorRefOverrides(address payable[] memory treatCreators, address payable[] memory overrideAddresses) public onlyOwner {
        require(treatCreators.length == overrideAddresses.length, "invalid arrays length");

        for(uint256 i = 0; i < treatCreators.length; i++) {
            address payable treatModel = treatCreators[i];
            address payable overrideAddress = overrideAddresses[i];
            address payable currentCreatorRefAddress = getCreatorRefAddress(treatModel);

            require(msg.sender == currentCreatorRefAddress || msg.sender == owner(), "sender not contract owner or current creator");
            require(currentCreatorRefAddress != overrideAddress, "can't override to same address");

            emit OnCreatorRefUpdated(currentCreatorRefAddress, overrideAddress);
            creatorRefOverrides[treatModel] = overrideAddress;
        }
    }


        // Mint 1 nft directly to the user wallet from TreatNFTMinter 
    function redeem(uint256 _nft) payable public {
        require(paused == false, "Contract Paused");
        require(nftCosts[_nft] != 0, "nft not found");
        require(msg.value >= nftCosts[_nft], "not enough treats to buy yoursef a treat");
        require(treatNFTMinter.totalSupply(_nft) < treatNFTMinter.maxSupply(_nft), "max nfts minted");

        address payable creatorAddress = getCreatorAddress(_nft);
        address payable referrerAddress = getCreatorRefAddress(creatorAddress);

        uint256 refPercentage = defaultRefPercentage;
        if(treatDaoToken.balanceOf(referrerAddress) >= melonNumber) {
            refPercentage = melonRefPercentage;
        }

        uint256 creatorPercentage = defaultCreatorPercentage;
        if(treatDaoToken.balanceOf(creatorAddress) >= melonNumber) {
            creatorPercentage = melonCreatorPercentage;
        }
        

        uint256 creatorTake = nftCosts[_nft].mul(creatorPercentage).div(1000);
        uint256 treatTake = nftCosts[_nft].mul(1000-creatorPercentage).div(1000);
        uint256 refTake = treatTake.mul(refPercentage).div(1000);
        uint256 treasuryTake = treatTake.mul(1000-refPercentage).div(1000);

        address(uint160(creatorAddress)).transfer(creatorTake);
        address(uint160(treatTreasuryAddress)).transfer(treasuryTake);
        address(uint160(referrerAddress)).transfer(refTake);

        treatNFTMinter.mint(msg.sender, _nft, 1, "");
        emit Redeemed(msg.sender, nftCosts[_nft]);
    }
    
        // Mint multiple nft directly to the user wallet from TreatNFTMinter 
    function redeemMultiple(uint256 _nft, uint256 _amount) payable public {
        require(paused == false, "Contract Paused");
        require(nftCosts[_nft] != 0, "nft not found");
        uint256 treatSetCost = nftCosts[_nft].mul(_amount);
        require(msg.value >= treatSetCost, "not enough treats to buy yoursef a treat");
        require(treatNFTMinter.totalSupply(_nft).add(_amount) <= treatNFTMinter.maxSupply(_nft), "max nfts minted");

        address payable creatorAddress = getCreatorAddress(_nft);
        address payable referrerAddress = getCreatorRefAddress(creatorAddress);

        uint256 refPercentage = defaultRefPercentage;
        if(treatDaoToken.balanceOf(referrerAddress) >= melonNumber) {
            refPercentage = melonRefPercentage;
        }

        uint256 creatorPercentage = defaultCreatorPercentage;
        if(treatDaoToken.balanceOf(creatorAddress) >= melonNumber) {
            creatorPercentage = melonCreatorPercentage;
        }

        uint256 creatorTake = treatSetCost.mul(creatorPercentage).div(1000);
        uint256 treatTake = treatSetCost.mul(1000-creatorPercentage).div(1000);
        uint256 refTake = treatTake.mul(refPercentage).div(1000);
        uint256 treasuryTake = treatTake.mul(1000-refPercentage).div(1000);

        address(uint160(creatorAddress)).transfer(creatorTake);
        address(uint160(treatTreasuryAddress)).transfer(treasuryTake);
        address(uint160(referrerAddress)).transfer(refTake);

        treatNFTMinter.mint(msg.sender, _nft, _amount, "");
        emit Redeemed(msg.sender, treatSetCost);
    }

    function redeemSet(uint256 _setId) payable public {
        require(paused == false, "Contract Paused");
        uint256[] memory setIds = nftSetIds[_setId];
        require(setIds.length > 0, "set not found");
        require(nftSetCosts[_setId] != 0, "set price not found");
        require(msg.value == nftSetCosts[_setId], "not enough BNB");

        for(uint256 i = 0; i < setIds.length; i++) {
          require(treatNFTMinter.totalSupply(setIds[i]) < treatNFTMinter.maxSupply(setIds[i]), "max nfts minted");
        }

        address payable creatorAddress = treatSetModels[_setId];
        address payable referrerAddress = getCreatorRefAddress(creatorAddress);

        uint256 refPercentage = defaultRefPercentage;
        if(treatDaoToken.balanceOf(referrerAddress) >= melonNumber) {
            refPercentage = melonRefPercentage;
        }

        uint256 creatorPercentage = defaultCreatorPercentage;
        if(treatDaoToken.balanceOf(creatorAddress) >= melonNumber) {
            creatorPercentage = melonCreatorPercentage;
        }

        uint256 treatSetCost = nftSetCosts[_setId];

        uint256 creatorTake = treatSetCost.mul(creatorPercentage).div(1000);
        uint256 treatTake = treatSetCost.mul(1000-creatorPercentage).div(1000);
        uint256 refTake = treatTake.mul(refPercentage).div(1000);
        uint256 treasuryTake = treatTake.mul(1000-refPercentage).div(1000);

        address(uint160(creatorAddress)).transfer(creatorTake);
        address(uint160(treatTreasuryAddress)).transfer(treasuryTake);
        address(uint160(referrerAddress)).transfer(refTake);

        for(uint256 i = 0; i < setIds.length; i++) {
          treatNFTMinter.mint(msg.sender, setIds[i], 1, "");
        }
    }
    
    function redeemFreeTreat(uint256 nftId) payable public {
        require(paused == false, "Contract Paused");
        require(isGiveAwayCard[nftId] == true, "treat not found");
        require(msg.value >= nftCosts[nftId], "wrong price");
        require(treatNFTMinter.totalSupply(nftId) < treatNFTMinter.maxSupply(nftId), "max nfts minted");

        treatNFTMinter.mint(msg.sender, nftId, 1, "");
        emit Redeemed(msg.sender, nftCosts[nftId]);
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4) {
        return 0xf23a6e61;
    }
    
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4) {
        return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
        interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }
    
    function treasury(address payable _treatTreasuryAddress) public onlyOwner {
        require(_treatTreasuryAddress != address(0), "cannot switch treasury to the zero address");
        treatTreasuryAddress = _treatTreasuryAddress;
    }

    function tittyFund(address payable _tittyFundAddress) public onlyOwner {
        tittyFundAddress = _tittyFundAddress;
    }

    function setPercentages(uint256 _defaultCreatorPercentage, uint256 _melonCreatorPercentage, uint256 _defaultRefPercentage, uint256 _melonRefPercentage) public onlyOwner {
        defaultCreatorPercentage = _defaultCreatorPercentage;
        melonCreatorPercentage = _melonCreatorPercentage;
        defaultRefPercentage = _defaultRefPercentage;
        melonRefPercentage = _melonRefPercentage;
    }
    
    function harvestTreats(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPausedTreats(bool _paused) public onlyOwner {
        pausedTreats = _paused;
    }
}