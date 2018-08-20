pragma solidity 0.4.24;

/**


@title Ownable
@dev The Ownable contract has an owner address, and provides basic authorization control
functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
address public owner;

/**


@dev The Ownable constructor sets the original owner of the contract to the sender
account.
*/
function Ownable() {
owner = msg.sender;
}

/**


@dev Throws if called by any account other than the owner.
*/
modifier onlyOwner() {
if (msg.sender != owner) {
throw;
}
_;
}

/**


@dev Allows the current owner to transfer control of the contract to a newOwner.
@param newOwner The address to transfer ownership to.
*/
function transferOwnership(address newOwner) onlyOwner {
if (newOwner != address(0)) {
owner = newOwner;
}
}

}

contract Token{
function transfer(address to, uint value) public returns (bool);
function decimals() public returns (uint);
}

contract Airdrop is Ownable {

function multisend(address _tokenAddr, address[] _to, uint256[] _value) public onlyOwner
returns (bool _success) {
assert(_to.length == _value.length);
assert(_to.length <= 150);

uint decimals = Token(_tokenAddr).decimals();
// loop through to addresses and send value
for (uint8 i = 0; i < _to.length; i++) {
assert((Token(_tokenAddr).transfer(_to[i], _value[i] * (10 ** decimals))) == true);
}
return true;
}
}