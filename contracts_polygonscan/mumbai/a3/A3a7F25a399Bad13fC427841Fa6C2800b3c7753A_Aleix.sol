/**
 *Submitted for verification at polygonscan.com on 2021-11-23
*/

// SPDX-License-Identifier: MIT
// Un contratracte molt senzill que permet al Owner mintar "entrades", i és l'´únic que les pot enviar. L'usuari l´únic que pot fer és redem
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract Aleix is Ownable, Pausable{
    
    mapping (address => uint) public holders;
    uint public fee = 1;
    
    function mint(uint _amount) public onlyOwner{
        holders[msg.sender] = holders[msg.sender] + _amount;
    }
    
    function redeem(uint _amount) public {
        require (holders[msg.sender] >= _amount, "No tens prou pasta per cremar");
        holders[msg.sender] = holders[msg.sender] - _amount;
        holders[owner()] = holders[owner()] + _amount;
    }
    
    function send(address _to, uint _amount) public onlyOwner{
        require (holders[msg.sender] >= _amount, "No tens prou pasta per enviar");
        holders[_to] = holders[_to] + _amount;
        holders[msg.sender] = holders[msg.sender] - _amount; 
    }
    
    function sendAmbFee(address _to, uint _amount) public {
        require (holders[msg.sender] >= (_amount + fee), "No tens prou pasta per enviar");
        holders[_to] = holders[_to] + _amount;
        holders[msg.sender] = holders[msg.sender] - (_amount + fee);
        holders[owner()] = holders[owner()] + fee;
    }
    
    function setFee(uint _fee) public onlyOwner{
        fee = _fee;
    }
    
    // començo a poder pausar els contractes
    function pausa(bool _state) public onlyOwner{
        if(_state == true) {_pause();}
        else {_unpause();}
    }
    
    // que el contracte comenci pausat i amb 100 tokens per jo
    constructor (){
        mint(100);
        _pause();
    }
}