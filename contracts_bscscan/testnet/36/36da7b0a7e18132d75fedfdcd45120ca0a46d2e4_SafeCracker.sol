/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: safe.sol


pragma solidity ^0.8.0;


contract SafeCracker is Ownable{
    
    uint randNonce = 0;
  
    struct VaultModel {
        string vaultName;
        uint256 amount;
        uint256 pinLength;
        bool paused;
        // uint256 endTime;
    }

    VaultModel public Vault;
    
    
    constructor(){
    }

    function randMod(uint m) internal returns(uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % m;
    }

     function createVault(string memory _vaultName, uint256 _pinLength) public onlyOwner returns (bool){
         //conditions
        Vault = VaultModel(_vaultName, 0, _pinLength, false);
        return true;
    }
    
    
    function crackTheVault(string memory pin) payable public returns(bool){
        //  require(block.timestamp < Events[_eventID].startTime, "Event expired !");
        require(Vault.paused == false, "In pause!");
        require(msg.value > 0, "You need to send some Ether");
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "err 1"
        );
        Vault.amount = Vault.amount + msg.value;
        // uint256 txValue = Vault.amount / (10**Vault.pinLength);
        if(Vault.pinLength == stringLength(pin)) {
            bool successCrack = checkPIN(pin);
            if(successCrack){
                // A castigat !!!!!!!
                address payable sender = payable(msg.sender);
                sender.transfer(Vault.amount);
                return true;
            }else{
                // A pierdut !!!!!!
                return false;
            }
        }else{
            return false;
        }
        
    }


    function withdrawAmount(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        address payable sender = payable(msg.sender);
        sender.transfer(amount);
     }
    
    
    function checkPIN(string memory pin) internal returns(bool){
        //conditions
       if(stringLength(pin) == 4){
            uint n1 = randMod(10);
            uint n2 = randMod(10);
            uint n3 = randMod(10);
            uint n4 = randMod(10);
            
            string memory n1s = uint2str(n1);
            string memory n2s = uint2str(n2);
            string memory n3s = uint2str(n3);
            string memory n4s = uint2str(n4);
            
            string memory nToString = string(abi.encodePacked(n1s,n2s,n3s,n4s));
            if (keccak256(bytes(nToString)) == keccak256(bytes(pin))) {
                return true;
            }else{
                return false;
            }
        }
        return false;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function stringLength(string memory s) internal pure returns (uint256) {
      return bytes(s).length;
    }
    
    
    
}