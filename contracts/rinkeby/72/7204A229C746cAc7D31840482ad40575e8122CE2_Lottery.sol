//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Lotty.sol";

contract Lottery is Lotty, Ownable {
    struct Entrant {
        bool isEntered;
        uint ethAmount;
        uint entrantAge;
    }
    
    address public admin;

    mapping(address => Entrant) public entrantStruct;
    
//creating one array for current lottery participants
//and one array for participants who have already won
    address[] public entrants;
    address[] public previousEntrantWinners;

    event Winner(address indexed from, address indexed to, uint value);

//Assign admin rights to specific address on creation of contract
    constructor(address _admin) { 
        admin = _admin;
    }
    
//enables admin address to change who the admin is
/*
    function changeAdmin(address newAdmin) public onlyOwner() {
        for(uint i = 0; i < entrants.length; i++) {
            require(
                newAdmin != entrants[i],
                "Lottery entrant cannot be made to admin"
            );
        }
        require(
            newAdmin != admin,
            "This address is already the admin"
        );
        admin = newAdmin;
    }
*/

//Allows any address to add any address into the Lottery except the admin address
    function enterLottery(
        address entrantAddress,
        uint _entrantAge
    ) 
        public payable 
    {
        require(
            entrantAddress != admin,
            "Admin cannot participate in Lottery"
        );
        require(
            entrantStruct[entrantAddress].isEntered != true,
            "This address has already been enterd"
        );
//function invoker has to send along the specified amount of Ether with their function call *subject to change*
        require(
            msg.value == 0.0013 ether, //1300000000000000 wei --> $5.00 USD at time of writing 
            "Wrong amount of ether"
        );
//Creates new struct and with entrant information and pushes it into an array of entrant structs
        entrantStruct[entrantAddress].isEntered = true;
        entrantStruct[entrantAddress].ethAmount += msg.value;
        entrantStruct[entrantAddress].entrantAge = _entrantAge;
        entrants.push(entrantAddress);
    }

//picks winner from entrant array and clears all fields regarding this lottery
    function pickWinner() public onlyOwner() {
        uint index = _random() % entrants.length;
//Deletes entrant struct array for new lottery pook
        for(uint i = 0; i < entrants.length; i++) {
            delete(entrantStruct[entrants[i]]);
        }
        previousEntrantWinners.push(entrants[index]);
//calls private function that creates new Lotty tokens for Lottery winner
        _mint(entrants[index]); //find this function on line 111
        emit Winner(admin, entrants[index], address(this).balance);
//sends either to Lottery winner
        (bool sent, ) = payable(entrants[index]).
            call{value:(address(this).balance)}("");
        require(sent, "Transaction Failed");
//clears the array entrant array
        entrants = new address[](0);
    }
//returns the current amount of eth in lottery pool
    function getLotteryBalance() public view returns(uint) {
        return address(this).balance;
    }
    
//view current lottery participants
    function getEntrants() public view returns(address[] memory) {
        return entrants;
    }

//returns the number of entrants there currently are in the lottery
    function getNumOfEntrants() public view returns(uint) {
        return entrants.length;
    }

//view previous lottey winners
    function getPreviousEntrantWinners() public view returns(address[] memory) {
        return previousEntrantWinners;
    }
    
//creates new tokens and gives them to lottery winner.
//this function is executed in the pickeWinner function
    function _mint(address lotteryWinner) private {
        balances[lotteryWinner] += 10000000000000000000;
        totalSupply += 10000000000000000000;
    }
    
//Helper function for pickWinner(). *Unsecure* Subject to change
    function _random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(
            block.difficulty, 
            block.timestamp,
            entrants
        )));
    }
//function helper disabling any address other than 
//admin to call functions when this is applied
/*
    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "only admin can call this function"
        );
        _;
    }
*/
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Lotty {

    address public owner_;
    string public tokenName = "Lotty";
    string public tokenSymbol = "LTY";
    uint256 public totalSupply; // Tokens can only be minted
    uint256 public decmials = 18;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //check balance of an account
    mapping(address => uint256) public balances;
    // who can spend what on whos behalf
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        owner_ = msg.sender;
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    //transfers token from function caller 
    function transfer(address _to, uint256 _value) public returns(bool success) {
        require(
            balances[msg.sender] >= _value,
            "insufficient funds"
        );
    //state is modified after function call as a re entrancy gaurd
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        public returns(bool success)
    {
        require(
            balances[_from] >= _value,
            "insufficient funds"
        );
        require(
            allowance[_from][msg.sender] >= _value,
            "allowance is too low"
        );
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address _spender, 
        uint256 _value
    ) 
        public returns (bool success) 
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
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