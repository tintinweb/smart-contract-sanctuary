//SourceUnit: TokenMintX.sol

pragma solidity ^0.4.25;


// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

// File: openzeppelin-solidity/contracts/ownership/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

}


contract Token {
    function mint(address _to, uint256 _amount) public returns (bool) {}
    function mintedSupply() public view returns (uint256) {}
    function mintedBy(address player) public view returns (uint256){}
    function remainingMintableSupply() public view returns (uint256) {}
}

contract TokenMint is Whitelist{

    using Address for address;

    event Mint(address indexed source, address indexed to, uint256 amount);

    address public tokenAddress;
    Token private token;

    /**
    * @dev
    * @param _tokenAddress The address of the mintable ERC20 token
    */
    constructor(address _tokenAddress) Ownable() public {

        tokenAddress = _tokenAddress;

        //Only the mint should own its paired token
        token = Token(tokenAddress);
    }

    function estimateMint(uint256 _amount) public returns (uint256){

        uint adjustedAmount = _amount / mintingDifficulty();
        uint remainingSupply = token.remainingMintableSupply();

        //lets be able to mint
        adjustedAmount = adjustedAmount < remainingSupply ? adjustedAmount : remainingSupply;

        return adjustedAmount;
    }

    /**
    * @dev Will relay to internal implementation
    * @param beneficiary Token purchaser
    * @param tokenAmount Number of tokens to be minted
    */
    function mint(address beneficiary, uint256 tokenAmount) onlyWhitelisted public returns (uint256){
        uint adjustedAmount = estimateMint(tokenAmount);

        if (adjustedAmount > 0 && token.mint(beneficiary, adjustedAmount)) {
            emit Mint(msg.sender, beneficiary, adjustedAmount);
            return adjustedAmount;
        }

        return 0;

    }

    /**
    * @dev minting difficulty
    */
    function mintingDifficulty() public view returns (uint256) {
        // Mining difficulty is simple.  Increases every 1M by 100
        // Difficulty starts at 2 given the genesis mine of 2.1M tokens
        uint256 stage = token.mintedSupply() / 1e12;

        //We want to account for the outstanding genesis block distribution; avoid divide by zero errors downstream
        if (stage < 1){
            stage = 1;
        }
        return 50 * (stage * stage);
    }

    /** @dev Returns the supply still available to mint */
    function remainingMintableSupply() public view returns (uint256) {
        return token.remainingMintableSupply();
    }

}

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}