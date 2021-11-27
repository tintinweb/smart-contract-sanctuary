// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721{
      function createAndSend(address _admin,uint256 _tokenId,address _to) external payable;
}

 
/// @title Crypto donation platorm
/// @author Luka Jevremovic
/// @notice This is authors fisrt code in soldity, be cearful!!!
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract DonationPlatform is Ownable{
  
   //pakovanje strukure
    struct Campagine{
        uint timeTrget;
        uint  amountTarget;
        address payable  menager;
        //uint amount;
        string  name;
        string descripton;
        bool  closed;
   }
    
    mapping (address=>mapping(string=>uint)) private contributors;
    address public immutable admin;
    mapping (string=>Campagine) public campagines;
    uint256 private nftid;
    IERC721 public immutable nft;
    mapping (string=>uint) private amounts;

    event ContrbutionReceived(address indexed sender, string message);
    event CampagineCreated(address  sender, string indexed name);
    event Whithdraw(address reciver);
    event CampagineClosed(string indexed name);
    constructor(address _nft){
        admin=msg.sender;
        nft=IERC721(_nft);
    }

    function creatCampagine(address _menanger, string memory _name,string  memory _descritpion, uint _timeTarget, uint  _amountTarget) public onlyOwner {
        require(bytes(campagines[_name].name).length==0,"Campagine with that name already exists");// ne znam dal ovo moze bolje da se napise
        Campagine memory newcampagine;
        newcampagine.menager=payable(_menanger);
        newcampagine.name=_name;
        newcampagine.descripton=_descritpion;
        newcampagine.timeTrget=block.timestamp+_timeTarget*86400;//number of days
        newcampagine.amountTarget=_amountTarget;
        campagines[_name]=newcampagine;

        emit CampagineCreated(msg.sender,_name);
    }
    
    function contribute(string memory _name) public payable{
        require(msg.value>0,"thats not nice");
        require(bytes(campagines[_name].name).length!=0,"Campagine with that name doesn't exists");
        /// reverts donation if time target has passsed
        Campagine memory campagine=campagines[_name];
        if (campagine.closed ||block.timestamp>=campagine.timeTrget) 
           revert("this Campagine is closed");

        ///closes the campagine but doesnt revert the donation
        if (campagine.amountTarget<=amounts[_name]+msg.value) {
                campagines[_name].closed=true;
                emit CampagineClosed(campagines[_name].name);
        }

        if (contributors[msg.sender][_name]==0)
             nft.createAndSend(admin, nftid++,msg.sender);
        amounts[_name]+=msg.value;
        contributors[msg.sender][_name]+=msg.value;//treba da se doda provera jedinstevnosti za drugi zadatak

        emit ContrbutionReceived(msg.sender,"Contribution recevied");
    }
    
    function withdraw(string memory _name) public payable {
        require(msg.sender==campagines[_name].menager,"only menager can whithdraw");
        (bool success, ) = campagines[_name].menager.call{value: amounts[_name]}("");
        require(success, "Failed to send Ether");
        amounts[_name]=0;
        emit Whithdraw(msg.sender);
    }

    function getBalance(string memory _name) public view returns (uint) {
        return amounts[_name];
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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