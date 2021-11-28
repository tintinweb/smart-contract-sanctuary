// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ============================ TEST_1.0.6 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   ============== Verify Random Function by ChainLink ===============

import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/BytesUtil.sol";
import "./Iregister.sol";

contract Register is Iregister, Ownable{

    using BytesUtil for bytes;

    uint256 public pureNameFee;
    address public DAOContract;

    struct User{
        bytes username;
        bytes info;
        bytes DAOInfo;
        bool isVIP;
    }

    mapping(address => User) public addrToUser;
    mapping(bytes => address) public userToAddr;


    constructor(address _DAOAddress, uint256 _pureNameFee){
        newDAOContract(_DAOAddress);
        setPureNameFee(_pureNameFee);
    }

    /**
     * @dev See {Iregister-registered}.
     */
    function registered(address userAddr) public view returns(bool) {
        return addrToUser[userAddr].username.length != 0;
    }

    /**
     * @dev See {Iregister-registered}.
     */
    function registered(bytes memory username) public view returns(bool) {
        return userToAddr[username.lower()] != address(0);
    }

    /**
     * @dev See {Iregister-isPure}.
     */
    function isPure(address userAddr) external view returns(bool){
        return registered(userAddr) 
        && addrToUser[userAddr].username[0] != 0x5f;
    }

    /**
     * @dev See {Iregister-isVIP}.
     */
    function isVIP(address userAddr) external view returns(bool){
        return registered(userAddr)  
        && addrToUser[userAddr].isVIP;
    }

    /**
     * @dev See {Iregister-usernameToAddress}.
     */
    function usernameToAddress(bytes memory username) public view returns(address userAddr) {
        require(registered(username), "no user by this username");
        return userToAddr[username.lower()];
    }

    /**
     * @dev See {Iregister-addressToUsername}.
     */
    function addressToUsername(address userAddr) external view returns(bytes memory username) {
        require(registered(userAddr), "no user by this address");
        return addrToUser[userAddr].username;
    }

    /**
     * @dev See {Iregister-addressToProfile}.
     */
    function addressToProfile(address userAddr) external view returns(
        bytes memory username,
        bytes memory info,
        bool VIPStatus
    ){
        require(registered(userAddr), "no user by this address");
        return(
            addrToUser[userAddr].username,
            addrToUser[userAddr].info,
            addrToUser[userAddr].isVIP
        );
    }

    /**
     * @dev See {Iregister-usernameToProfile}.
     */
    function usernameToProfile(bytes memory username) external view returns(
        address userAddr,
        bytes memory info,
        bool VIPStatus
    ){
        userAddr = usernameToAddress(username);
        return(
            userAddr,
            addrToUser[userAddr].info,
            addrToUser[userAddr].isVIP
        );
    }

    /**
     * @dev See {Iregister-signIn}.
     */
    function signIn(bytes memory username, bytes memory info, bytes memory presenter) external payable {
        address userAddr = _msgSender();
        require(!registered(username), "this username has been used before");
        if(username[0] != 0x5f) {
            require(msg.value >= pureNameFee, "this username is Payable");
        }

        _setUsername(userAddr, username);

        emit TransferUsername(address(0), userAddr, username);

        if(info.length > 0) {setInfo(info);}

        address presenterAddr = userToAddr[presenter.lower()];
        if(presenterAddr != address(0)){
            (bool success, bytes memory data) = DAOContract.call
                (abi.encodeWithSignature("registerSign(address)", presenterAddr
            ));
            if(success){
                addrToUser[userAddr].DAOInfo = data;
            }
        }
    }

    /**
     * @dev See {Iregister-setInfo}.
     */
    function setInfo(bytes memory info) public {
        address userAddr = _msgSender();
        require(registered(userAddr) , "you have to sign in first");
        addrToUser[userAddr].info = info;
        emit SetInfo(userAddr, info);
    }

    /**
     * @dev See {Iregister-transferUsername}.
     */
    function transferUsername(address _to) external {
        address _from = _msgSender();
        bytes memory username = addrToUser[_from].username;

        _deleteUser(_from, username);

        if(_to != address(0)){
            _setUsername(_to, username);
        }

        emit TransferUsername(_from, _to, username);
    }

    /**
     * @dev delete a user by specific `userAddr` and `username`.
     * 
     * Requirements:
     *
     * - user should be registered before.
     */
    function _deleteUser(address userAddr, bytes memory username) private {
        require(registered(userAddr) , "you are not registered");
        delete addrToUser[userAddr];
        delete userToAddr[username.lower()];
    }

    /**
     * @dev set a `username` to a `userAddr`.
     * 
     * Requirements:
     *
     * - Not allowed empty usernames.
     * - user should not be registered before.
     */
    function _setUsername(address userAddr, bytes memory username) private {
        require(username.length > 0, "empty username input");
        require(!registered(userAddr) , "this address has signed a username before");
        addrToUser[userAddr].username = username;
        userToAddr[username.lower()] = userAddr;
    }

    /**
     * @dev Set sign in fee for pure usernames.
     */
    function setPureNameFee(uint256 _fee) public onlyOwner {
        pureNameFee = _fee;
    }

    /**
     * @dev Owner of the contract can upgrade a user to VIP status.
     */
    function upgradeToVIP(address userAddr) external onlyOwner {
        require(registered(userAddr), "no user by this address");
        addrToUser[userAddr].isVIP = true;
    }

    /**
     * @dev Withdraw supply by owner of the contract.
     */
    function withdraw(address receiverAddress) external onlyOwner {
        address payable receiver = payable(receiverAddress);
        receiver.transfer(address(this).balance);
    }

    /**
     * @dev Chenge DAOContract by owner of the contract.
     */
    function newDAOContract(address contractAddr) public onlyOwner {
        DAOContract = contractAddr;
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
pragma solidity ^0.8.7;

// ============================ TEST_1.0.4 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   =============== Verify Random Function by ChanLink ===============

library BytesUtil {

    /**
     * Lower
     * 
     * Converts all the values of a bytes to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the bytes base to convert to lower case
     * @return bytes 
     */
    function lower(bytes memory _base)
        internal
        pure
        returns (bytes memory) {
        for (uint i = 0; i < _base.length; i++) {
            _base[i] = _lower(_base[i]);
        }
        return _base;
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ============================ TEST_1.0.6 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   ============== Verify Random Function by ChainLink ===============

import "@openzeppelin/contracts/access/Ownable.sol";

interface Iregister {

    /**
     * @dev Emitted when username transfers.
     */
    event TransferUsername(address _from, address _to, bytes username);

    /**
     * @dev Emitted when user info sets or changes.
     */
    event SetInfo(address indexed userAddress, bytes info);


    /**
     * @dev returns true if the user has been registered. (by user `address`)
     */
    function registered(address userAddr) external view returns(bool);

    /**
     * @dev returns true if the user has been registered. (by `username`)
     */
    function registered(bytes memory username) external view returns(bool);

    /**
     * @dev returns true if address `userAddr` registered and its `username` is pure type.
     */
    function isPure(address userAddr) external view returns(bool);

    /**
     * @dev returns true if `userAddr` registered and the user is VIP.
     */
    function isVIP(address userAddr) external view returns(bool);

    /**
     * @dev Returns the address `userAddr` of the `username`.
     *
     * Requirements:
     *
     * - `username` must be registered.
     */
    function usernameToAddress(bytes memory username) external view returns(address userAddr);

    /**
     * @dev Returns the `username` of the address `userAddr`.
     *
     * Requirements:
     *
     * - address `userAddr` must be registered before.
     */
    function addressToUsername(address userAddr) external view returns(bytes memory username);


    /**
     * @dev Returns the `username`, `info` and `VIP status` of the `userAddr`.
     *
     * Requirements:
     *
     * - address `userAddr` must be registered before.
     */
    function addressToProfile(address userAddr) external view returns(
        bytes memory username,
        bytes memory info,
        bool VIPStatus
    );

    /**
     * @dev Returns address `userAddr`, `info` and `VIP status of the `username`.
     *
     * Requirements:
     *
     * - `username` must be registered before.
     */
    function usernameToProfile(bytes memory username) external view returns(
        address userAddr,
        bytes memory info,
        bool VIPStatus
    );

    /**
     * @dev Sign in the Register contract by adopting a `username` and optional info if needed.
     *
     * Pure usernames are payable but new user can sign in free by using `_` in the first character of `username`.
     * new user can introduce a bytes username as `presenter`.
     * 
     * Requirements:
     *
     * - Every address can only sign one username.
     * - Not allowed empty usernames.
     * - Usernames are unique so new user has to adopt a username not used before.
     *
     * Emits a {SignIn} event.
     */
    function signIn(bytes memory username, bytes memory info, bytes memory presenter) external payable;

    /**
     * @dev in addition to the username, every user can set a brief personal info.
     *
     * To remove previously info, it can be called by empty bytes input.
     *
     * Requirements:
     *
     * - The user has to register first.
     *
     * Emits a {SetInfo} event.
     */
    function setInfo(bytes memory info) external;

    /**
     * @dev the user can transfer its user to another address.
     * 
     * When `_to` is zero the username will be free.
     *
     * Requirements:
     *
     * - The user should be registered before.
     *
     * Emits a {TransferUsername} event.
     */
    function transferUsername(address _to) external;
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