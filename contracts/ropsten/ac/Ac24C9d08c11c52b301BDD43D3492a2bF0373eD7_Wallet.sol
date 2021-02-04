/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

pragma solidity ^0.6.2;

contract Account {
    address payable public reciever;
    event Flush(address to, uint256 value);

    constructor(address payable _reciever) public {
        reciever = _reciever;
    }

    function flush() public {
        uint256 balance = address(this).balance;
        if (balance == 0){
            return;
        }
        reciever.transfer(balance);
        emit Flush(reciever, balance);
    }
}

contract Wallet {
    address payable public admin;
    mapping(address => bool) public accounts;

    event Create(address);

    constructor() public {
        admin = msg.sender;
    }

    modifier OnlyAdmin {
        require(msg.sender == admin, "403");
        _;
    }

    function create(address payable _to, bytes32 _salt) public OnlyAdmin {
        Account a = new Account{salt: _salt}(_to);
        emit Create(address(a));
    }
    
    function computeAddress(address payable _to, bytes32 salt) public view returns(address) {
        uint8 prefix = 0xff;
        bytes memory code = abi.encodePacked(
            type(Account).creationCode,
            uint256(_to)
        );
        bytes32 initCodeHash = keccak256(abi.encodePacked(code));
        bytes32 hash = keccak256(abi.encodePacked(prefix, address(this), salt, initCodeHash));
        return address(uint160(uint256(hash)));
    }
}