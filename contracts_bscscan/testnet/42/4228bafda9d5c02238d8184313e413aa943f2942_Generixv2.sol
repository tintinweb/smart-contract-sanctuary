/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

pragma solidity ^0.5.2;

contract Generixv2 {
    //////////////////////////////////////////////////////////////////////////
    // Generic ERC20
    //////////////////////////////////////////////////////////////////////////

    // owner -> amount
    mapping(address => uint256) s_balances;
    // owner -> spender -> max amount
    mapping(address => mapping(address => uint256)) s_allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Spec: Get the account balance of another account with address `owner`
    function balanceOf(address owner) public view returns (uint256 balance) {

        return s_balances[owner];
    }

    function internalTransfer(address from, address to, uint256 value) internal returns (bool success) {

        if (value <= s_balances[from]) {

            s_balances[from] -= value;
            s_balances[to] += value;
            emit Transfer(from, to, value);

            return true;
        } else {
            return false;
        }
    }

    // Spec: Send `value` amount of tokens to address `to`
    function transfer(address to, uint256 value) public returns (bool success) {
        address from = msg.sender;
        return internalTransfer(from, to, value);
    }

    // Spec: Send `value` amount of tokens from address `from` to address `to`
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        address spender = msg.sender;

        if (
            value <= s_allowances[from][spender] &&
            internalTransfer(from, to, value)
        ) {
            s_allowances[from][spender] -= value;

            return true;
        } else {
            return false;
        }
    }

    // Spec: Allow `spender` to withdraw from your account, multiple times, up
    // to the `value` amount. If this function is called again it overwrites the
    // current allowance with `value`.
    function approve(address spender, uint256 value) public returns (bool success) {
        address owner = msg.sender;

        if (value != 0 && s_allowances[owner][spender] != 0) {

            return false;
        }

        s_allowances[owner][spender] = value;
        emit Approval(owner, spender, value);

        return true;
    }

    // Spec: Returns the `amount` which `spender` is still allowed to withdraw
    // from `owner`.
    // What if the allowance is higher than the balance of the `owner`?
    // Callers should be careful to use min(allowance, balanceOf) to make sure
    // that the allowance is actually present in the account!
    function allowance(address owner, address spender) public view returns (uint256 remaining) {

        return s_allowances[owner][spender];
    }

    //////////////////////////////////////////////////////////////////////////
    // GasToken specifics
    //////////////////////////////////////////////////////////////////////////

    uint8 constant public decimals = 0;
    string constant public name = "Generixv2";
    string constant public symbol = "Genx";

    // We build a queue of nonces at which child contracts are stored. s_head is
    // the nonce at the head of the queue, s_tail is the nonce behind the tail
    // of the queue. The queue grows at the head and shrinks from the tail.
    // Note that when and only when a contract CREATEs another contract, the
    // creating contract's nonce is incremented.
    // The first child contract is created with nonce == 1, the second child
    // contract is created with nonce == 2, and so on...
    // For example, if there are child contracts at nonces [2,3,4],
    // then s_head == 4 and s_tail == 1. If there are no child contracts,
    // s_head == s_tail.
    uint256 s_head;
    uint256 s_tail;

    // totalSupply gives  the number of tokens currently in existence
    // Each token corresponds to one child contract that can be SELFDESTRUCTed
    // for a gas refund.
    function totalSupply() public view returns (uint256 supply) {

        return s_head - s_tail;
    }

    // Mints `value` new sub-tokens by creating `value`
    // new child contracts. The minted tokens are owned by the caller of this
    // function.
    function mint(uint256 value) public {

        // EVM assembler of runtime portion of child contract:
        //     ;; Pseudocode: if (msg.sender != 0x41b8933c659467b0659aef2335a0c0f7a41bee42) { throw; }
        //     ;;             suicide(msg.sender)
        //     PUSH15 0x4946c0e9f43f4dee607b0ef1fa1c ;; hardcoded address of this contract
        //     CALLER
        //     XOR
        //     PC
        //     JUMPI
        //     CALLER
        //     SELFDESTRUCT
        // Or in binary: 6e4946c0e9f43f4dee607b0ef1fa1c3318585733ff
        // Since the binary is so short (22 bytes), we can get away
        // with a very simple initcode:
        //     PUSH22 0x6e4946c0e9f43f4dee607b0ef1fa1c3318585733ff
        //     PUSH1 0
        //     MSTORE ;; at this point, memory locations mem[10] through
        //            ;; mem[31] contain the runtime portion of the child
        //            ;; contract. all that's left to do is to RETURN this
        //            ;; chunk of memory.
        //     PUSH1 22 ;; length
        //     PUSH1 10 ;; offset
        //     RETURN
        // Or in binary: 756e4946c0e9f43f4dee607b0ef1fa1c3318585733ff6000526016600af3
        // Almost done! All we have to do is put this short (31 bytes) blob into
        // memory and call CREATE with the appropriate offsets.

        assembly {
            mstore(0, 0x756e4946c0e9f43f4dee607b0ef1fa1c3318585733ff6000526016600af300)

            for {let i := div(value, 30)} i {i := sub(i, 1)} {
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
                pop(create(0, 0, 29)) pop(create(0, 0, 29))
            }

            for {let i := and(value, 0x1F)} i {i := sub(i, 1)} {
                pop(create(0, 0, 29))
            }
        }

        s_head += value;
        s_balances[msg.sender] += value;
    }

    // Destroys `value` child contracts and updates s_tail.
    function destroyChildren(uint256 value) internal {
        uint256 tail = s_tail;
        // tail points to slot behind the last contract in the queue
        for (uint256 i = tail + 1; i <= tail + value; i++) {
            _addressFrom(i).call("");
        }

        s_tail = tail + value;
    }

    // Frees `value` sub-tokens (e.g. cents, pennies, ...) belonging to the
    // caller of this function by destroying `value` child contracts, which
    // will trigger a partial gas refund.
    function free(uint256 value) public returns (bool success) {

        uint256 from_balance = s_balances[msg.sender];
        if (value > from_balance) {
            return false;
        }

        destroyChildren(value);

        s_balances[msg.sender] = from_balance - value;

        emit Transfer(msg.sender, address(0), value);

        return true;
    }

    // Frees up to `value` sub-tokens. Returns how many tokens were freed.
    // Otherwise, identical to free.
    function freeUpTo(uint256 value) public returns (uint256 freed) {
        uint256 from_balance = s_balances[msg.sender];
        if (value > from_balance) {
            value = from_balance;
        }

        destroyChildren(value);

        s_balances[msg.sender] = from_balance - value;

        emit Transfer(msg.sender, address(0), value);

        return value;
    }

    function _addressFrom(uint _nonce) internal view returns (address) {

        if (_nonce == 0x00) return address(uint256(keccak256(abi.encodePacked(
                byte(0xd6),
                byte(0x94),
                address(this),
                byte(0x80)
            ))));

        if (_nonce <= 0x7f) return address(uint256(keccak256(abi.encodePacked(
                byte(0xd6),
                byte(0x94),
                address(this),
                uint8(_nonce)
            ))));

        if (_nonce <= 0xff) return address(uint256(keccak256(abi.encodePacked(
                byte(0xd7),
                byte(0x94),
                address(this),
                byte(0x81),
                uint8(_nonce)
            ))));

        if (_nonce <= 0xffff) return address(uint256(keccak256(abi.encodePacked(
                byte(0xd8),
                byte(0x94),
                address(this),
                byte(0x82),
                uint16(_nonce)
            ))));

        if (_nonce <= 0xffffff) return address(uint256(keccak256(abi.encodePacked(
                byte(0xd9),
                byte(0x94),
                address(this),
                byte(0x83),
                uint24(_nonce)
            ))));

        return address(uint256(keccak256(abi.encodePacked(
                byte(0xda),
                byte(0x94),
                address(this),
                byte(0x84),
                uint32(_nonce)
            ))));
    }

    // Frees `value` sub-tokens owned by address `from`. Requires that `msg.sender`
    // has been approved by `from`.
    function freeFrom(address from, uint256 value) public returns (bool success) {
        address spender = msg.sender;
        uint256 from_balance = s_balances[from];
        if (value > from_balance) {
            return false;
        }

        mapping(address => uint256) storage from_allowances = s_allowances[from];
        uint256 spender_allowance = from_allowances[spender];
        if (value > spender_allowance) {
            return false;
        }

        destroyChildren(value);

        s_balances[from] = from_balance - value;
        from_allowances[spender] = spender_allowance - value;

        emit Transfer(from, address(0), value);

        return true;
    }

    // Frees up to `value` sub-tokens owned by address `from`. Returns how many tokens were freed.
    // Otherwise, identical to `freeFrom`.
    function freeFromUpTo(address from, uint256 value) public returns (uint256 freed) {

        address spender = msg.sender;
        uint256 from_balance = s_balances[from];

        if (value > from_balance) {
            value = from_balance;
        }

        mapping(address => uint256) storage from_allowances = s_allowances[from];
        uint256 spender_allowance = from_allowances[spender];

        if (value > spender_allowance) {
            value = spender_allowance;
        }

        destroyChildren(value);

        s_balances[from] = from_balance - value;
        from_allowances[spender] = spender_allowance - value;

        emit Transfer(from, address(0), value);

        return value;
    }
}