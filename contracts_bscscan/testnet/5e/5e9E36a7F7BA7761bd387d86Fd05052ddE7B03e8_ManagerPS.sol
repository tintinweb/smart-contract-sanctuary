/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

//"SPDX-License-Identifier: KKteam"


pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.0;
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;
contract ManagerPS is Ownable {
    
    address[] listaUtenti;
    mapping(address=>uint) public UserDB;
    
    address public  tokenAddress = 0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3;//0x000000000000000000000000000000000000dEaD; //da mette address token
    uint public unlockTime = 2 minutes; //30 days
    uint public startTime = 0;
    uint public dec = 9;
    uint public nextUnlock;
    
    function inviaPercentuale() public {
        require (block.timestamp >= startTime + unlockTime);
        BEP20 tok = BEP20(tokenAddress);
        for ( uint i=0; i<listaUtenti.length; i++){
            address tempU = listaUtenti[i];
            uint tempTsend = UserDB[tempU]/5;
            uint daInvia = tempTsend*10**dec;
            tok.transfer(tempU, daInvia);
            
        }
        startTime = block.timestamp;
        nextUnlock = startTime + unlockTime;
    }
    
    function set_tokenAddress (address tkn) public onlyOwner{
        tokenAddress = tkn;
    }
    function set_dec (uint dc) public onlyOwner{
        dec = dc;
    }

    function caricaInfo (address[] memory users, uint[] memory amountsTkn) public onlyOwner{
        for ( uint i=0; i<users.length; i++){
            UserDB[users[i]] = amountsTkn[i];
        }
    }
}
abstract contract BEP20 {
function approve(address guy, uint wad) virtual public returns (bool);
function balanceOf(address tokenOwner) virtual external view returns (uint256);
function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool);
}