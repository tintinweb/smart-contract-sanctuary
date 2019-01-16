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


contract Token {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint value) returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
   

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
  
Token public token;
 
  /**
     * @dev Constructor.
     * @param tokenAddress Address of the token contract.
     * @param decimals Decimals as specified by the token.
     */
    function Airdropper(address tokenAddress, uint decimals) public {
        require(decimals <= 77);  // 10**77 < 2**256-1 < 10**78

        token = Token(tokenAddress);
        
    }
 
function multisend(address _tokenAddr, address[] _to, uint256[] _value)
    returns (bool _success) {
        assert(_to.length == _value.length);
        assert(_to.length <= 150);
        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
                assert((Token(_tokenAddr).transfer(_to[i], _value[i])) == true);
            }
            return true;
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