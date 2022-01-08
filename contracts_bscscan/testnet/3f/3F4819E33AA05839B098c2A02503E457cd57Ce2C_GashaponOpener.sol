// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


interface ERC721_CONTRACT {
    function safeMint(address to, string memory partCode) external;
}

interface RANDOM_CONTRACT {
    function startRandom() external returns (uint256);
}

interface RANDOM_RATE {
    function getGenPool(
        uint16 _rarity,
        uint16 _number
    ) external view returns (uint16);

    function getNFTPool(uint16 _number)
        external
        view
        returns (uint16);

    function getEquipmentPool(uint16 _number) external view returns (uint16);

    function getBlueprintPool(
        uint16 _rarity,
        uint16 eTypeId,
        uint16 _number
    ) external view returns (uint16);

    function getSpaceWarriorPool(
        uint16 _part,
        uint16 _number
    ) external view returns (uint16);
}

contract GashaponOpener is Ownable {
    using Strings for string;
    uint8 private constant NFT_TYPE = 0; //Kingdom

    uint8 private constant SUITE = 5; //Battle Suit
    uint8 private constant WEAP = 8; //WEAP
    uint8 private constant SPACE_WARRIOR = 6;
    uint8 private constant GEN = 7; //Human GEN

    uint8 private constant COMMON = 0;
    uint8 private constant RARE = 1;
    uint8 private constant EPIC = 2;
    uint8 private constant SPACIAL = 3;

    mapping(uint256 => address) ranNumToSender;
    mapping(uint256 => uint256) requestToNFTId;

    event OpenBox(address _by, string partCode);
    event ChangeRandomRateContract(address _address);
    event ChangeMysteryBoxContract(address _address);
    event ChangeNftCoreContract(address _address);
    event ChangeRandomWorkerContract(address _address);
    event ChangeEcioTokenContract(address _address);

    address public mysteryBoxContract;
    address public nftCoreContract;
    address public randomWorkerContract;
    address public ecioTokenContract;

    uint256 public stdGashaPrice = 12500 * 10**18;
    uint256 public promoGashaPrice = 9500 * 10**18;

    enum randomRateType{
        STD,
        LTD
    }

    mapping(randomRateType => address) public randomRateAddress;
    
    

    constructor() {}

    function changeEcioTokenContract(address _address) public onlyOwner {
        ecioTokenContract = _address;
        emit ChangeEcioTokenContract(_address);
    }

    function changeRandomWorkerContract(address _address) public onlyOwner {
        randomWorkerContract = _address;
        emit ChangeRandomWorkerContract(_address);
    }

    function changeMysteryBoxContract(address _address) public onlyOwner {
        mysteryBoxContract = _address;
        emit ChangeMysteryBoxContract(_address);
    }

    function changeNftCoreContract(address _address) public onlyOwner {
        nftCoreContract = _address;
        emit ChangeNftCoreContract(_address);
    }

    //Change RandomRate type Contract

    function changeRandomRateSTD(address _address) public onlyOwner {
        randomRateAddress[randomRateType.STD] = _address;
        emit ChangeRandomRateContract(_address);
    }

    
    function changeRandomRateLTD(address _address) public onlyOwner {
        randomRateAddress[randomRateType.LTD] = _address;
        emit ChangeRandomRateContract(_address);
    }

    function generateNFT(
        randomRateType _RandomType
    ) internal {
        uint256 _randomNumber = RANDOM_CONTRACT(randomWorkerContract)
          .startRandom();

        string memory _partCode = createNFTCode(_randomNumber, _RandomType);
        mintNFT(msg.sender, _partCode);
        emit OpenBox(msg.sender, _partCode);
    }

    function openGasha(randomRateType _RandomType) public {

        if ( _RandomType == randomRateType.STD ) {
            uint256 _balance = IERC20(ecioTokenContract).balanceOf(msg.sender);
            require(_balance >= stdGashaPrice, "ECIO: Your balance is insufficient.");

            //charge ECIO // Need Approval
            IERC20(ecioTokenContract).transferFrom(msg.sender, address(this), stdGashaPrice);

            // mint NFT and random for user.
            generateNFT(_RandomType);

        } else if ( _RandomType == randomRateType.LTD ) {
            uint256 _balance = IERC20(ecioTokenContract).balanceOf(msg.sender);
            require(_balance >= promoGashaPrice, "ECIO: Your balance is insufficient.");

            //charge ECIO // Need Approval
            IERC20(ecioTokenContract).transferFrom(msg.sender, address(this), promoGashaPrice);

            // mint NFT and random for user.
            generateNFT(_RandomType);
        }
        
    }

    function mintNFT(address to, string memory concatedCode) private {
        ERC721_CONTRACT _nftCore = ERC721_CONTRACT(nftCoreContract);
        _nftCore.safeMint(to, concatedCode);
    }

    function createNFTCode(uint256 _randomNumber, randomRateType _RandomType)
        internal
        view
        returns (string memory)
    {
        string memory partCode;

        //create SW
        partCode = createSW(_randomNumber, _RandomType);

        return partCode;
    }

    function getNumberAndMod(
        uint256 _ranNum,
        uint16 digit,
        uint16 mod
    ) public view virtual returns (uint16) {
        if (digit == 1) {
            return uint16((_ranNum % 10000) % mod);
        } else if (digit == 2) {
            return uint16(((_ranNum % 100000000) / 10000) % mod);
        } else if (digit == 3) {
            return uint16(((_ranNum % 1000000000000) / 100000000) % mod);
        } else if (digit == 4) {
            return uint16(((_ranNum % 10000000000000000) / 1000000000000) % mod);
        } else if (digit == 5) {
            return uint16(((_ranNum % 100000000000000000000) / 10000000000000000) % mod);
        } else if (digit == 6) {
            return uint16(((_ranNum % 1000000000000000000000000) / 100000000000000000000) % mod);
        } else if (digit == 7) {
            return uint16(((_ranNum % 10000000000000000000000000000) / 1000000000000000000000000) % mod);
        } else if (digit == 8) {
            return uint16(((_ranNum % 100000000000000000000000000000000) / 10000000000000000000000000000) % mod);
        }

        return 0;
    }


    function createSW(uint256 _randomNumber, randomRateType _RandomType)
        private
        view
        returns (string memory)
        {
        

        
        // adjust digit to random partcode
        uint16 battleSuiteId = getNumberAndMod(_randomNumber, 5, 1000);
        uint16 humanGenomeId = getNumberAndMod(_randomNumber, 7, 1000);
        uint16 weaponId = getNumberAndMod(_randomNumber, 8, 1000);

        string memory concatedCode = convertCodeToStr(6);

        concatedCode = concateCode(concatedCode, 0); //kingdomCode
        concatedCode = concateCode(concatedCode, 0);
        concatedCode = concateCode(concatedCode, 0);
        concatedCode = concateCode(concatedCode, 0);
        concatedCode = concateCode(
            concatedCode,
            RANDOM_RATE(randomRateAddress[_RandomType]).getSpaceWarriorPool(SUITE, battleSuiteId)
        );
        concatedCode = concateCode(concatedCode, 0);
        concatedCode = concateCode(
            concatedCode,
            RANDOM_RATE(randomRateAddress[_RandomType]).getSpaceWarriorPool(GEN, humanGenomeId)
        );
        concatedCode = concateCode(
            concatedCode,
            RANDOM_RATE(randomRateAddress[_RandomType]).getSpaceWarriorPool(WEAP, weaponId)
        );
        concatedCode = concateCode(concatedCode, 0); //Star
        concatedCode = concateCode(concatedCode, 0); //equipmentCode
        concatedCode = concateCode(concatedCode, 0); //Reserved
        concatedCode = concateCode(concatedCode, 0); //Reserved
        return concatedCode;
    }


    function concateCode(string memory concatedCode, uint256 digit)
        internal
        pure
        returns (string memory)
    {
        concatedCode = string(
            abi.encodePacked(convertCodeToStr(digit), concatedCode)
        );

        return concatedCode;
    }

    function convertCodeToStr(uint256 code)
        private
        pure
        returns (string memory)
    {
        if (code <= 9) {
            return string(abi.encodePacked("0", Strings.toString(code)));
        }

        return Strings.toString(code);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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