pragma solidity ^0.6.0;

import "./owner/Operator.sol";

contract DigitalSource is Operator{
    event CreateDigitalArt(uint256 _artId,
                address _creator, 
                address[] _assistants, 
                uint256[] _benefits,
                uint256 _totalEdition, 
                string _uri);

    //artid  => art work detail
    mapping(uint256 => DigitalArt) digitalArts;

    mapping (string=>bool) public metadataExist;

    uint256[] public artIds;

    struct DigitalArt{
        uint256 id;
        uint256 totalEdition;
        uint256 currentEdition;
        address creator;
        address[] assistants;
        uint256[] benefits;
        string uri;
    }

    function getArtIds() view public returns(uint256[] memory){
        return artIds;
    }

    function createDigitalArt(
                address _creator, 
                address[] memory _assistants, 
                uint256[] memory _benefits,
                uint256 _totalEdition, 
                string memory _uri) external onlyOperator() returns (uint256){
        uint256 artId = 10000 + artIds.length;
        require(!metadataExist[_uri],"Metadata exist!");
        metadataExist[_uri] = true;
        DigitalArt storage digitalArt = digitalArts[artId];
        digitalArt.creator = _creator;
        digitalArt.id = artId;
        digitalArt.assistants = _assistants;
        digitalArt.benefits = _benefits;
        digitalArt.uri = _uri;
        digitalArt.totalEdition = _totalEdition;
        digitalArt.currentEdition = 0;
        artIds.push(artId);
        emit CreateDigitalArt(artId, _creator, _assistants, _benefits, _totalEdition, _uri);
        return artId;
    }

    function increaseDigitalArtEdition(
                uint256 _artId, 
                uint256 _count)  external onlyOperator(){
        DigitalArt storage digitalArt = digitalArts[_artId];
        digitalArt.currentEdition = digitalArt.currentEdition + _count;
    }

    function getDigitalCreator(uint256 _artId) view external returns(
                address[] memory creators,
                uint256[] memory benefits) {
        DigitalArt storage digitalArt = digitalArts[_artId];            
        creators[0] = digitalArt.creator;
        for (uint256 index = 0; index < digitalArt.assistants.length; index++) {
            creators[index+1] = digitalArt.assistants[index];
        }
        benefits = digitalArt.benefits;
    }

    function getDigitalArt(uint256 _artId) view external returns(
                uint256 id,
                uint256 totalEdition,
                uint256 currentEdition,
                address creator,
                address[] memory assistants,
                uint256[] memory benefits,
                string memory uri
    ){
        DigitalArt memory digitalArt = digitalArts[_artId];    
        return (digitalArt.id,
                digitalArt.totalEdition,
                digitalArt.currentEdition,
                digitalArt.creator,
                digitalArt.assistants,
                digitalArt.benefits,
                digitalArt.uri);
    }
}

pragma solidity ^0.6.2;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            'operator: caller is not the operator'
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(
            newOperator_ != address(0),
            'operator: zero address given for new operator'
        );
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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