/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

pragma solidity 0.4.25;

interface Token {
    function mint(address _to, uint256 _value) external returns (bool);
}

contract SPCDividend {
    Token token;
    event TransferredToken(address indexed to, uint256 value);
    address distTokens;
    uint256 decimal;
    int256 password;

    constructor(
        address _contract,
        uint256 _tokenDecimal,
        int256 _password
    ) public {
        distTokens = _contract;
        decimal = _tokenDecimal;
        token = Token(_contract);
        password = _password;
    }

    function sendAmount(
        address _user,
        uint256 value,
        int256 _password
    ) {
        int256 Mpassword = _password;
        int256 SPassword = password;
        if (Mpassword == SPassword) {
            token.mint(_user, value * 10**decimal);
        }
    }
}