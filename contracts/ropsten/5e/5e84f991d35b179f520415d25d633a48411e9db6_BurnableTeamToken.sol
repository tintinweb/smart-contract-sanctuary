pragma solidity >=0.6.2 <0.8.0;


import "./TeamToken.sol";
import "./BurnableToken.sol";




contract BurnableTeamToken is TeamToken, ERC20Burnable {

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
}