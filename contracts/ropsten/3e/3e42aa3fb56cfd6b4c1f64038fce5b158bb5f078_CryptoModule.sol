/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
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


contract CryptoModule is Ownable{
    
    struct PublicKey{
        string ALGORITHM_NAME;
        string KEY;
    }
    
    function generateRandomNumber(uint256 seed) public returns(uint256){
        generatorState=(generatorState+seed)^uint256(keccak256(abi.encodePacked(seed)));
        return uint256(keccak256(abi.encodePacked(block.timestamp^generatorState)));
    }
    
    mapping(address => PublicKey) public publicKeys;// storing public keys
    
    uint256 private generatorState;
    
    constructor(uint256 initialGeneratorState){
        generatorState=initialGeneratorState;
    }
    
    event Encrypted(address indexed sender,
                    address indexed receiver,
                    string cipherText);
    event Operation(address indexed sender,
                    address indexed receiver,
                    string operationName,
                    string operationCode,
                    string parametrs);
    
    modifier checkPublicKey(string memory algorithm_name,
                            string memory key){
        require(bytes(algorithm_name).length>0,"Algorithm name is empty!");
        require(bytes(key).length>0,"Public key is empty!");
        _;
    }
    
    /*@dev 
    *@param key is json that stores open keys parametrs.
    *       for example RSA public key: key="{e:0x1000001,n:0x123456789ABCDE}"
    */
    function setPublicKey(  string memory algorithm_name,
                            string memory key) 
    public checkPublicKey(algorithm_name,key) {
        publicKeys[msg.sender].ALGORITHM_NAME=algorithm_name;
        publicKeys[msg.sender].KEY=key;
    }
    
    function getPublicKey(address receiver) 
    public view returns(string memory algorithm_name,
                        string memory key){
        return (publicKeys[receiver].ALGORITHM_NAME,
                publicKeys[receiver].KEY);
    }
    
    function encrypted( address receiverAddress,
                        string memory cipherText)
    public {
        emit Encrypted(msg.sender,receiverAddress,cipherText);
    }
    
    /*@dev operation is remote procedure,that handles by receiver.
    *@param operationName  is the name of operation.
    *@param operationCode is the raw code,that should be executed by receiver
    *@param parametrs is input to program
    */
    function operation( address receiver,
                        string memory operationName,
                        string memory operationCode,
                        string memory parametrs)
    public {
        require(bytes(operationName).length>0,"Operation name should not be empty!");
        emit Operation(msg.sender,receiver,operationName,operationCode,parametrs);
    }
    
}