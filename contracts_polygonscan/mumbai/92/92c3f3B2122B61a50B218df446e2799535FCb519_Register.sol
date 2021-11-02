// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ============================ TEST_1.0.2 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   =============== Verify Random Function by ChanLink ===============

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRegister.sol";

contract Register is IRegister, Ownable{

    uint256 public pureNameFee;
    address public DAOContract;

    struct User{
        string username;
        string info;
        bool isVIP;
    }

    mapping(address => User) public addrToUser;
    mapping(string => address) public userToAddr;


    constructor(address _DAOAddress, uint256 _pureNameFee){
        newDAOContract(_DAOAddress);
        setPureNameFee(_pureNameFee);
    }

    /**
     * @dev See {IRegister-registered}.
     */
    function registered(address userAddr) public view returns(bool) {
        return bytes(addrToUser[userAddr].username).length != 0;
    }

    /**
     * @dev See {IRegister-registered}.
     */
    function registered(string memory username) public view returns(bool) {
        return userToAddr[username] != address(0);
    }

    /**
     * @dev See {IRegister-isPure}.
     */
    function isPure(address userAddr) external view returns(bool){
        return registered(userAddr) 
        && bytes(addrToUser[userAddr].username)[0] != bytes1("_");
    }

    /**
     * @dev See {IRegister-isVIP}.
     */
    function isVIP(address userAddr) external view returns(bool){
        return registered(userAddr)  
        && addrToUser[userAddr].isVIP;
    }

    /**
     * @dev See {IRegister-usernameToAddress}.
     */
    function usernameToAddress(string memory username) external view returns(address userAddr) {
        require(registered(username), "no user by this username");
        return userToAddr[username];
    }

    /**
     * @dev See {IRegister-addressToUsername}.
     */
    function addressToUsername(address userAddr) external view returns(string memory username) {
        require(registered(userAddr), "no user by this address");
        return addrToUser[userAddr].username;
    }

    /**
     * @dev See {IRegister-addressToProfile}.
     */
    function addressToProfile(address userAddr) external view returns(
        string memory username,
        string memory info,
        bool VIPstatus
    ){
        require(registered(userAddr), "no user by this address");
        return(
            addrToUser[userAddr].username,
            addrToUser[userAddr].info,
            addrToUser[userAddr].isVIP
        );
    }

    /**
     * @dev See {IRegister-usernameToProfile}.
     */
    function usernameToProfile(string memory username) external view returns(
        address userAddr,
        string memory info,
        bool VIPstatus
    ){
        require(registered(username), "no user by this address");
        userAddr = userToAddr[username];
        return(
            userAddr,
            addrToUser[userAddr].info,
            addrToUser[userAddr].isVIP
        );
    }

    /**
     * @dev See {IRegister-signIn}.
     */
    function signIn(string memory username, string memory info, address presenter) external payable {
        address userAddr = _msgSender();
        require(!registered(userAddr) , "this address has signed a username before");
        require(bytes(username).length > 0, "empty username input");
        require(userToAddr[username] == address(0), "this username has been used before");
        require(presenter != address(0) && presenter != userAddr, "wrong presenter address entered");

        if(bytes(username)[0] != bytes1("_")) {
            require(msg.value >= pureNameFee, "this username is Payable");
        }

        addrToUser[userAddr].username = username;
        userToAddr[username] = userAddr;

        emit SignIn(userAddr, username);

        if(bytes(info).length > 0) {setInfo(info);}

        (bool success, bytes memory data) = DAOContract.call
            (abi.encodeWithSignature("registerSign(address)", presenter));
    }

    /**
     * @dev See {IRegister-setInfo}.
     */
    function setInfo(string memory info) public {
        address userAddr = _msgSender();
        require(registered(userAddr) , "you have to sign in first");
        addrToUser[userAddr].info = info;
        emit SetInfo(userAddr, info);
    }


    /**
     * @dev Set sign in fee for pure usernames.
     */
    function setPureNameFee(uint256 _fee) public onlyOwner {
        pureNameFee = _fee;
    }

    /**
     * @dev Owner of the contract can upgrade a user to VIP.
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

// ============================ TEST_1.0.2 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   =============== Verify Random Function by ChanLink ===============

import "@openzeppelin/contracts/access/Ownable.sol";

interface IRegister {

    /**
     * @dev Emitted when a new user signs in.
     */
    event SignIn(address indexed userAddress, string username);

    /**
     * @dev Emitted when user info sets or changes.
     */
    event SetInfo(address indexed userAddress, string info);


    /**
     * @dev Check if the user has been registered. (by user address)
     */
    function registered(address userAddr) external view returns(bool);

    /**
     * @dev Check if the user has been registered. (by username)
     */
    function registered(string memory username) external view returns(bool);

    /**
     * @dev Check if address `userAddr` registered and its `username` is pure.
     */
    function isPure(address userAddr) external view returns(bool);

    /**
     * @dev Check if `userAddr` registered and the user is VIP.
     */
    function isVIP(address userAddr) external view returns(bool);

    /**
     * @dev Returns the address `userAddr` of the `username`.
     *
     * Requirements:
     *
     * - `username` must be registered.
     */
    function usernameToAddress(string memory username) external view returns(address userAddr);

    /**
     * @dev Returns the `username` of the address `userAddr`.
     *
     * Requirements:
     *
     * - address `userAddr` must be registered before.
     */
    function addressToUsername(address userAddr) external view returns(string memory username);


    /**
     * @dev Returns the `username`, `info` and `VIP status` of the `userAddr`.
     *
     * Requirements:
     *
     * - address `userAddr` must be registered before.
     */
    function addressToProfile(address userAddr) external view returns(
        string memory username,
        string memory info,
        bool VIPstatus
    );

    /**
     * @dev Returns address `userAddr`, `info` and `VIP status of the `username`.
     *
     * Requirements:
     *
     * - `username` must be registered before.
     */
    function usernameToProfile(string memory username) external view returns(
        address userAddr,
        string memory info,
        bool VIPstatus
    );

    /**
     * @dev Sign in the Register contract by adopting a `username` and optional info if needed.
     *
     * Pure usernames are payable but new user can sign in free by using `_` in first character of username.
     *
     * Requirements:
     *
     * - Every address can only sign in once and can't change its username.
     * - Not allowed empty usernames.
     * - Usernames are unique so new user has to adopt a username not used before.
     * - new user must introduce a `presenter`.
     *
     * Emits a {SignIn} event.
     */
    function signIn(string memory username, string memory info, address presenter) external payable;

    /**
     * @dev in addition to the username, every user can set additional personal info .
     *
     * To remove previously info, can be called by empty string input.
     *
     * Requirements:
     *
     * - The user has to register first.
     *
     * Emits a {SetInfo} event.
     */
    function setInfo(string memory info) external;
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