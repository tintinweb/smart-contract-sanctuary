/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.4.24;

contract Ownable {

    address public owner;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Address is not an owner");
        _;
    }

    function transferOwnership (address newOwner) public onlyOwner {
        require(newOwner != address(0), "New Address is not valid address");
        owner = newOwner;
    }
}

interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external view returns (uint256 balance);
}

contract AirDrop is Ownable {

    Token token;

    event TransferredToken(address indexed to, uint256 value);
    event FailedTransfer(address indexed to, uint256 value);

    modifier whenDropIsActive() {
        assert(isActive());
      _;
    }

    constructor () {
        address _tokenAddr = 0xDa68202843e46568d7d33e14f977fe33ffC318B5; 
        token = Token(_tokenAddr);
    }

    function isActive() public view returns (bool) {
        return (tokensAvailable() > 0);
    }

    function sendTokens(address[] dests, uint256[] values) external whenDropIsActive onlyOwner {
        uint i = 0;
        while (i < dests.length) {
            uint256 toSend = values[i] * 10**18;
            sendInternally(dests[i], toSend, values[i]);
            i++;
        } 
    } 

    function sendInternally(address recipient, uint256 tokensToSend, uint256 valueToPresent) internal {
        if (recipient == address(0)) return;

        if (tokensAvailable() >= tokensToSend) {
            token.transfer(recipient, tokensToSend);
            emit TransferredToken(recipient, valueToPresent);
        } else {
            emit FailedTransfer(recipient, valueToPresent); 
        }
    }   

    function tokensAvailable() public view returns (uint256) {
        return token.balanceOf(this);
    }

    function destroy() public onlyOwner {
        uint256 balance = tokensAvailable();
        require (balance > 0, "Balance is zero");
        token.transfer(owner, balance);
        selfdestruct(owner);
    }
}