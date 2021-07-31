pragma solidity 0.4.21;

import "./Owned.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

//This is the Main Iagon Token Contract derived from the other two contracts Owned and ERC20
contract IagonToken is Owned, ERC20 {
    using SafeMath for uint256;

    uint256 public tokenSupply = 1000000000 * 1e18;

    // This notifies clients about the amount burnt , only admin is able to burn the contract
    event Burn(address from, uint256 value);

    /* This is the main Token Constructor
     */
    function IagonToken() public ERC20(tokenSupply, "Iagon", "IAG") {
        owner = msg.sender;
    }

    // fallback function  , to avoid any ethers being accidentally sent to token contract
    function() public payable {
        revert();
    }

    /* This function is used to mint additional tokens
     * only admin can invoke this function
     * @param _mintedAmount amount of tokens to be minted
     */
    function mintTokens(uint256 _mintedAmount) public onlyOwner {
        balanceOf[owner] = balanceOf[owner].add(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        emit Transfer(0, owner, _mintedAmount);
    }

    /**
     * This function Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public onlyOwner {
        assert(_value <= balanceOf[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure
        address burner = msg.sender;
        balanceOf[burner] = balanceOf[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}