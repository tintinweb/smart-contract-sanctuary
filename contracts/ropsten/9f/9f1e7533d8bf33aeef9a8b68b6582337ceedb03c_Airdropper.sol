pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
    address public owner;
    address public newOwner;

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
     * 
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

}

/**
 *ERC Token Standard #20 Interface
 *https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Airdropper
 * @dev An &quot;airdropper&quot; contract for bulk distribution of an ERC20 token.
 * @dev This contract does not hold any tokens. Instead, it transfers directly
 *   from a given source address to the recipients. Ensure that the source
 *   address has set a sufficient allowance for the address of this contract.
 */
contract Airdropper is Ownable {

    ERC20 public token;

    /**
     * @dev Constructor.
     * @param tokenAddress Address of the token contract.
     */

    constructor(address tokenAddress) public{
        token = ERC20(tokenAddress);
    }
     

    /**
     * @dev Airdrops some tokens to some accounts.
     * @param source The address of the current token holder.
     * @param _destinations List of account addresses.
     * @param _tokenValues List of token amounts. Note that these are in whole
     *   tokens. Fractions of tokens are not supported.
     */
    function airdrop(address source,address[] _destinations, uint256[] _tokenValues) public onlyOwner {
        // This simple validation will catch most mistakes without consuming
        // too much gas.
        require(_destinations.length == _tokenValues.length);

        for (uint256 i = 0; i < _destinations.length; i++) {
            require(token.transferFrom(source, _destinations[i], _tokenValues[i] /*.mul(multiplier)*/ ));
        }
    }

    /**
     * @dev Return all tokens back to owner, in case any were accidentally
     *   transferred to this contract.
     */
    function returnTokens() public onlyOwner {
        token.transfer(owner, token.balanceOf(this));
    }

    /**
     * @dev Destroy this contract and recover any ether to the owner.
     */
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}