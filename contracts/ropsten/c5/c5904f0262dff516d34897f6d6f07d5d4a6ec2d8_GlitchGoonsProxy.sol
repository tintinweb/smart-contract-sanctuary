pragma solidity ^0.4.24;

// File: contracts/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an emitter and administrator addresses, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address emitter;
    address administrator;

    /**
     * @dev Sets the original `emitter` of the contract
     */
    function setEmitter(address _emitter) internal {
        require(_emitter != address(0));
        require(emitter == address(0));
        emitter = _emitter;
    }

    /**
     * @dev Sets the original `administrator` of the contract
     */
    function setAdministrator(address _administrator) internal {
        require(_administrator != address(0));
        require(administrator == address(0));
        administrator = _administrator;
    }

    /**
     * @dev Throws if called by any account other than the emitter.
     */
    modifier onlyEmitter() {
        require(msg.sender == emitter);
        _;
    }

    /**
     * @dev Throws if called by any account other than the administrator.
     */
    modifier onlyAdministrator() {
        require(msg.sender == administrator);
        _;
    }

    /**
   * @dev Allows the current super emitter to transfer control of the contract to a emitter.
   * @param _emitter The address to transfer emitter ownership to.
   * @param _administrator The address to transfer administrator ownership to.
   */
    function transferOwnership(address _emitter, address _administrator) public onlyAdministrator {
        require(_emitter != _administrator);
        require(_emitter != emitter);
        require(_emitter != address(0));
        require(_administrator != address(0));
        emitter = _emitter;
        administrator = _administrator;
    }
}

// File: contracts/GlitchGoonsProxy.sol

contract GlitchGoonsProxy is Ownable {

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor (address _emitter, address _administrator) public {
        setEmitter(_emitter);
        setAdministrator(_administrator);
    }

    function deposit() external payable {
        emitter.transfer(msg.value);
        emit Transfer(msg.sender, emitter, msg.value);
    }

    function transfer(address _to) external payable {
        _to.transfer(msg.value);
        emit Transfer(msg.sender, _to, msg.value);
    }
}