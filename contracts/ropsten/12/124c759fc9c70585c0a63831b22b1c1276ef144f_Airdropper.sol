pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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
 * @dev An "airdropper" or "bounty" contract for distributing an ERC20 token
 *   en masse.
 * @dev This contract does not hold any tokens. Instead, it transfers directly
 *   from a given source address to the recipients. Ensure that the source
 *   address has set a sufficient allowance for the address of this contract.
 */
contract Airdropper is Ownable {
    //using SafeMath for uint;

    ERC20 public token;
    //uint public multiplier;
    
    // address[] _destinations = [0xe108b4ee308c6be63c4f1c67ff6e7095c947aa39, 0xe298b4ee308c6be63c4f1c67ff6e7095c947aa39];
    // uint256[] _tokenValues = [2, 5];
    // address source = 0x770d818dF6EDbBD9c6a7dEAdF2cc3B387dC89136;

    /**
     * @dev Constructor.
     * 
     */
    
    constructor() public{
        //require(decimals <= 77);  // 10**77 < 2**256-1 < 10**78

        token = ERC20(0x82eF72295937010222FC2423842BF85E685E234C  );  //Test 5 coin token address
        //multiplier = 10**decimals;
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