/**
 *Submitted for verification at Etherscan.io on 2020-09-01
*/

/*

    /     |  __    / ____|
   /      | |__) | | |
  / /    |  _  /  | |
 / ____   | |    | |____
/_/    _ |_|  _  _____|

* ARC: global/KYFV2.sol
*
* Latest source (may be newer): https://github.com/arcxgame/contracts/blob/master/contracts/global/KYFV2.sol
*
* Contract Dependencies: 
*	- Context
*	- IKYFV2
*	- Ownable
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2020 ARC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

/* ===============================================
* Flattened with Solidifier by Coinage
* 
* https://solidifier.coina.ge
* ===============================================
*/


pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IKYFV2 {

    function checkVerified(
        address _user
    )
        external
        view
        returns (bool);

}


contract KYFV2 is Ownable, IKYFV2 {

    address public verifier;

    uint256 public count;

    uint256 public hardCap;

    mapping (address => bool) public isVerified;

    event Verified (address _user, address _verified);
    event Removed (address _user);
    event VerifierSet (address _verifier);
    event HardCapSet (uint256 _hardCap);

    function checkVerified(
        address _user
    )
        external
        view
        returns (bool)
    {
        return isVerified[_user];
    }

    function verify(
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        returns (bool)
    {
        require(
            count < hardCap,
            "Hard cap reached"
        );

        require(
            isVerified[_user] == false,
            "User has already been verified"
        );

        bytes32 sigHash = keccak256(
            abi.encodePacked(
                _user
            )
        );

        bytes32 recoveryHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", sigHash)
        );

        address recoveredAddress = ecrecover(
            recoveryHash,
            _v,
            _r,
            _s
        );

        require(
            recoveredAddress == verifier,
            "Invalid signature"
        );

        isVerified[_user] = true;

        count++;

        emit Verified(_user, verifier);
    }

    function removeMultiple(
        address[] memory _users
    )
        public
    {
        for (uint256 i = 0; i < _users.length; i++) {
            remove(_users[i]);
        }
    }

    function remove(
        address _user
    )
        public
        onlyOwner
    {
        delete isVerified[_user];
        count--;

        emit Removed(_user);
    }

    function setVerifier(
        address _verifier
    )
        public
        onlyOwner
    {
        verifier = _verifier;
        emit VerifierSet(_verifier);
    }

    function setHardCap(
        uint256 _hardCap
    )
        public
        onlyOwner
    {
        hardCap = _hardCap;
        emit HardCapSet(_hardCap);
    }

}