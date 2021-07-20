/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity 0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

interface Token {
    function transfer(address _to, uint _amount) public returns (bool success);
    function balanceOf(address _owner) public constant returns (uint balance);
}


contract Airdrop is Ownable {

    address public tokenAddr;

    constructor(address _tokenAddr) public {
        tokenAddr = _tokenAddr;
    }

    function dropTokens(address[] _recipients) public onlyOwner returns (bool) {
        // 10 Tokens per address
        for (uint i = 0; i < _recipients.length; i++) {
            // require(_recipients[i] != address(0));
            require(Token(tokenAddr).transfer(_recipients[i], 500000000000000));
        }

        return true;
    }

    function withdrawTokens(address beneficiary) public onlyOwner {
        require(Token(tokenAddr).transfer(beneficiary, Token(tokenAddr).balanceOf(this)));
    }

}