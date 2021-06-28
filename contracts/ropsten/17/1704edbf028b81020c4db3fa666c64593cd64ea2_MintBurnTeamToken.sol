pragma solidity >=0.6.2 <0.8.0;


import "./Ownable.sol";
import "./TeamToken.sol";
import "./BurnableToken.sol";

contract MintBurnTeamToken is TeamToken, ERC20Burnable, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supply,
        address _owner,
        address _feeWallet
    )
    public 
    TeamToken(_name, _symbol, _decimals, _supply, _owner, _feeWallet) 
    {

    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}