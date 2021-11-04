// File: node_modules\@openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
pragma solidity ^0.8.5;

/*
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

// File: @openzeppelin\contracts\access\Ownable.sol

pragma solidity ^0.8.5;


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

// File: contracts\CrashGameWorker.sol


pragma solidity ^0.8.5;

contract CrashGameWorker{

    function utfStringLength(string memory str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == 0x1E)
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function bytessubstring(
        bytes memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (bytes memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return bytes(result);
    }

    function reverse(string[] memory str)
        internal
        pure
        returns (string[] memory)
    {
        string memory s;
        for (uint256 i = 0; i < str.length / 2; i++) {
            s = str[i];
            str[i] = str[str.length - i - 1];
            str[str.length - i - 1] = s;
        }
        return str;
    }

    function hmacsha256(bytes memory key, bytes memory message)
        internal
        pure
        returns (bytes32)
    {
        bytes32 keyl;
        bytes32 keyr;
        uint256 i;
        if (key.length > 64) {
            keyl = sha256(key);
        } else {
            // for (i = 0; i < key.length && i < 32; i++)
            //     keyl |= bytes32(uint(key[i]) * 2 ** (8 * (31 - i)));
            // for (i = 32; i < key.length && i < 64; i++)
            //     keyr |= bytes32(uint(key[i]) * 2 ** (8 * (63 - i)));
            for (i = 0; i < key.length && i < 32; i++)
                keyl |= bytes32(uint8(key[i]) * 2**(8 * (31 - i)));
            for (i = 32; i < key.length && i < 64; i++)
                keyr |= bytes32(uint8(key[i]) * 2**(8 * (63 - i)));
        }
        bytes32 threesix = 0x3636363636363636363636363636363636363636363636363636363636363636;
        bytes32 fivec = 0x5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c;
        return
            sha256(
                abi.encodePacked(
                    fivec ^ keyl,
                    fivec ^ keyr,
                    sha256(
                        abi.encodePacked(
                            threesix ^ keyl,
                            threesix ^ keyr,
                            message
                        )
                    )
                )
            );

        
    }


    //Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) public pure returns (uint8 ch) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
    }

    // Convert an hexadecimal string to raw bytes
    function fromHex(string memory s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length % 2 == 0); // length must be even
        bytes memory r = new bytes(ss.length / 2);
        for (uint256 i = 0; i < ss.length / 2; ++i) {
            r[i] = bytes1(
                fromHexChar(uint8(ss[2 * i])) *
                    16 +
                    fromHexChar(uint8(ss[2 * i + 1]))
            );
        }
        return r;
    }

    function toBytes32(bytes memory input) internal pure returns (bytes32) {
        // require(input.length <= 32, "invalid input size");
        bytes32 b = bytes32(input);
        return b;
    }

    function computeH(bytes32 _hmac) internal pure returns (uint256) {
        bytes32 hmacSha256 = _hmac;

        bytes7 first7Bytes = bytes7(hmacSha256); // get the first 7 bytes (14 hex characters): 0xf83bf40815929b
        bytes7 thirteenHexCharacters = first7Bytes >> 4; // move 4 bytes (1 hex character) to the right: 0x0f83bf40815929

        bytes32 castBytes = bytes32(thirteenHexCharacters); // cast the bytes7 to bytes32 so that we can cast it to integer later
        bytes32 castBytesMoved = castBytes >> 200; // move 200 bytes (50 hex characters) to the right: 0x000000000000000000000000000000000000000000000000000f83bf40815929
        uint256 integerValue = uint256(castBytesMoved); // cast the bytes32 to uint256

        return (integerValue);
    }

    
    function getLengthofDigits(uint256 _number) internal pure returns(uint8){
            uint8 digits = 0;
            //if (number < 0) digits = 1; // enable this line if '-' counts as a digit
            while (_number != 0) {
                _number /= 10;
                digits++;
            }
            return digits;
    }
    
    function getNDecimalNumberinETH(uint256 _number, uint256 dec) internal pure returns(uint256){
            uint8 digits = 0;
            uint256 lastNum = 0;
            //if (number < 0) digits = 1; // enable this line if '-' counts as a digit
            while (_number != 0 && digits < 18-dec) {
                lastNum = _number % 10; 
                _number /= 10;
                if( lastNum >= 5) 
                    _number += 1;
                digits++;
            }
            return _number;
    }

    //(uint256, bytes32, bytes memory, bytes32, uint256)
    function crashPoint(string memory hash, string memory salt)
        public
        pure
        returns (uint256)
    {
        uint256 returnValue;
        //convert strings to bytes
        bytes memory _hash = bytes(hash);
        bytes memory _salt = bytes(salt);
        bytes32 hmacSha256 = hmacsha256(_hash, _salt); //terrible confusing variable name
        uint256 e = 2**52;
        uint256 h = computeH(hmacSha256);
        uint256 tempHash = uint256(hmacSha256); //uint256(toBytes32(_hash));
      
        if (tempHash % 20 == 0) {
            //todo fix cast
            returnValue = 1e18;
        } else {
            //18 place multiplier here
            returnValue = ((((99 * 1e36) * e - h) / (e - h)) / (100 * 1e18));
        }
        return returnValue;
    }
}

//interface for CrashBank
interface ICrashBank {
    function resolveGame(uint32 gameNumber, string memory gameHash,
        address[] memory players, int256[] memory deltas) external ;
}

// File: contracts\CrashGame.sol
pragma solidity ^0.8.5;

contract CrashGame is Ownable, CrashGameWorker {

    //-------Variable declarations -----------//

    string private _salt;
    address crashBankAddress;
    ICrashBank private crashBank;

    //-------EVENT TRIGGER INFO -----------//

    //constructor
    constructor (string memory __salt){
        _salt = __salt;
    }

    event CrashGameEnded(string, uint256 , uint256);

    //onlyowner can set the winner of a game
    /** @notice Ends game and calls encodeAndResolveGame fun
     *  @param _gameNumber Game number
     *  @param _gameHash Game hash
     *  @param players Array of player addresses
     *  @param deltas Array of change to player balance after game (negative if bet was lost)
     */
    function endCrashGame(uint32 _gameNumber, string memory _gameHash, uint256 cp, 
        address[] memory players, int256[] memory deltas)  
        public
        onlyOwner 
        {
        //TODO: check cp of end game and verify it from stored results.
        uint256 expectedCp = crashPoint(_gameHash, _salt);
        //below event is just for testing. Will be removed in final code.
        emit CrashGameEnded(_gameHash, expectedCp, cp);
        // console.log('expectedCp:', expectedCp);
        // console.log('providedCp:', cp);
        // console.log('getNDecimalNumberEth:expectedCp:', getNDecimalNumberinETH(expectedCp, 2));
        // console.log('getNDecimalNumberEth:providedCp:', getNDecimalNumberinETH(cp, 2));
        //require(getNDecimalNumberinETH(expectedCp, 2) == getNDecimalNumberinETH(cp, 2), "Game cp is compromised");
        
        encodeAndResolveGame(_gameNumber, _gameHash, players, deltas);
    }
    
    //------ FUNCTION DECLARATIONS ----//
    /** @notice Encode game data and call CrashBank.resolve()
     *  @param gameNumber Game number
     *  @param gameHash Game hash
     *  @param players Array of player addresses
     *  @param deltas Change to player balance after game (negative if bet was lost)
     */
    function encodeAndResolveGame(uint32 gameNumber, string memory gameHash, 
        address[] memory players, int256[] memory deltas) internal {
        crashBank = ICrashBank(crashBankAddress);
        crashBank.resolveGame(gameNumber, gameHash, players, deltas);
        // require(success);
    }

    function encodeAndResolveGame_old(uint32 gameNumber, string memory gameHash, 
        address[] memory players, int256[] memory deltas) internal {
        bytes memory payload = abi.encodeWithSignature("resolveGame(uint32 gameNumber, string memory gameHash, address[] memory players, int256[] memory deltas)", gameNumber, gameHash, players, deltas);
        (bool success, ) = address(crashBankAddress).call(payload);
        require(success);
    }

    function getCrashPoint(string memory _gameHash) 
        public 
        view 
        returns(uint256, uint256)
        {
            uint256 cp = crashPoint(_gameHash, _salt);
        return (getNDecimalNumberinETH(cp, 2), cp);
    }
    
    function setCrashBankAddress(address _address) external {
        crashBankAddress = _address;
    }
    
}