pragma solidity ^0.4.24;

contract ERC20Token {
    function transferFrom(address from, address to, uint value) public returns (bool);
}

contract StandardToken {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
}

contract AirDropT {

    /** ORS token */
    ERC20Token public ORSToken;

    constructor() public {
        ORSToken = ERC20Token(0x0A22dccF5Bd0fAa7E748581693E715afefb2F679);
    }

    function() payable public {}

    /**
     * batch transfer for ORS token.(the same amount)
     *
     * @param _addresses array of address to sent
     * @param _value transfer amount
     */
    function batchTransferORS(address[] _addresses, uint _value) public {
        // transfer circularly
        for (uint i = 0; i < _addresses.length; i++) {
            ORSToken.transferFrom(msg.sender, _addresses[i], _value);
        }
    }

    /**
     * batch transfer for ERC20 token.(the same amount)
     *
     * @param _contractAddress ERC20 token address
     * @param _addresses array of address to sent
     * @param _value transfer amount
     */
    function batchTransferToken(address _contractAddress, address[] _addresses, uint _value) public {
        // data validate & _addresses length limit
        require(_addresses.length > 0);

        StandardToken token = StandardToken(_contractAddress);
        // transfer circularly
        for (uint i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _value);
        }
    }
}