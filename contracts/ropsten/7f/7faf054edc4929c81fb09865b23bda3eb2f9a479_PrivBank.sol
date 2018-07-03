pragma solidity ^0.4.23;

contract PrivBank {
    address owner;
    mapping (bytes32 => uint) balances;

    event Deposit(
      address indexed _from,
      bytes32 indexed _to,
      uint amount
    );
    event Withdraw(
      bytes32 indexed _from,
      address indexed _to,
      uint amount
    );

    constructor() public {
        owner = msg.sender;
    }

    function balanceOf(bytes32 hash) public view returns(uint) {
      return balances[hash];
    }

    // Deposit funds to a hash. The hash must be created through createAddressHash
    // or the funds will not be withdrawable.
    function deposit(bytes32 to) public payable returns(bool) {
        balances[to] += msg.value;
        emit Deposit(msg.sender, to, msg.value);

        return true;
    }

    // Withdraw all funds owned by sender, at seed, to the to address.
    // Must withdraw all funds since seed is exposed and the intent of this contract is to hide
    // holdings.
    function withdraw(bytes32 seed, address to) public returns(bool) {
        bytes32 from = createAddressHash(msg.sender, seed);
        require(balances[from] > 0);

        to.transfer(balances[from]);
        emit Withdraw(from, to, balances[from]);
        delete balances[from];

        return true;
    }

    // Create the hash to be used when depositing funds
    function createAddressHash(address addr, bytes32 seed) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(addr, seed));
    }

    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}