pragma solidity ^0.4.10;

import "./rlp.sol";

contract GasToken2 is Rlp {
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
    function balanceOf(address owner) public constant returns (uint256 balance) {
        return s_balances[owner];
    }

    function internalTransfer(address from, address to, uint256 value) internal returns (bool success) {
        if (value <= s_balances[from]) {
            s_balances[from] -= value;
            s_balances[to] += value;
            Transfer(from, to, value);
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
        if(value <= s_allowances[from][spender] && internalTransfer(from, to, value)) {
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
        Approval(owner, spender, value);
        return true;
    }

    // Spec: Returns the `amount` which `spender` is still allowed to withdraw
    // from `owner`.
    // What if the allowance is higher than the balance of the `owner`?
    // Callers should be careful to use min(allowance, balanceOf) to make sure
    // that the allowance is actually present in the account!
    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return s_allowances[owner][spender];
    }

    //////////////////////////////////////////////////////////////////////////
    // GasToken specifics
    //////////////////////////////////////////////////////////////////////////

    uint8 constant public decimals = 2;
    string constant public name = "Gastoken.io";
    string constant public symbol = "GST2";

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
    function totalSupply() public constant returns (uint256 supply) {
        return s_head - s_tail;
    }

    // Creates a child contract that can only be destroyed by this contract.
    function makeChild() internal returns (address addr) {
        assembly {
            // EVM assembler of runtime portion of child contract:
            //     ;; Pseudocode: if (msg.sender != 0x0000000000b3f879cb30fe243b4dfee438691c04) { throw; }
            //     ;;             suicide(msg.sender)
            //     PUSH15 0xb3f879cb30fe243b4dfee438691c04 ;; hardcoded address of this contract
            //     CALLER
            //     XOR
            //     PC
            //     JUMPI
            //     CALLER
            //     SELFDESTRUCT
            // Or in binary: 6eb3f879cb30fe243b4dfee438691c043318585733ff
            // Since the binary is so short (22 bytes), we can get away
            // with a very simple initcode:
            //     PUSH22 0x6eb3f879cb30fe243b4dfee438691c043318585733ff
            //     PUSH1 0
            //     MSTORE ;; at this point, memory locations mem[10] through
            //            ;; mem[31] contain the runtime portion of the child
            //            ;; contract. all that's left to do is to RETURN this
            //            ;; chunk of memory.
            //     PUSH1 22 ;; length
            //     PUSH1 10 ;; offset
            //     RETURN
            // Or in binary: 756eb3f879cb30fe243b4dfee438691c043318585733ff6000526016600af3
            // Almost done! All we have to do is put this short (31 bytes) blob into
            // memory and call CREATE with the appropriate offsets.
            let solidity_free_mem_ptr := mload(0x40)
            mstore(solidity_free_mem_ptr, 0x00756eb3f879cb30fe243b4dfee438691c043318585733ff6000526016600af3)
            addr := create(0, add(solidity_free_mem_ptr, 1), 31)
        }
    }

    // Mints `value` new sub-tokens (e.g. cents, pennies, ...) by creating `value`
    // new child contracts. The minted tokens are owned by the caller of this
    // function.
    function mint(uint256 value) public {
        for (uint256 i = 0; i < value; i++) {
            require(makeChild() != 0);
        }
        s_head += value;
        s_balances[msg.sender] += value;
    }

    // Destroys `value` child contracts and updates s_tail.
    function destroyChildren(uint256 value) internal {
        uint256 tail = s_tail;
        // tail points to slot behind the last contract in the queue
        for (uint256 i = tail + 1; i <= tail + value; i++) {
            require(mk_contract_address(this, i).call.gas(msg.gas)());
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

        return value;
    }

    // Frees `value` sub-tokens owned by address `from`. Requires that `msg.sender`
    // has been approved by `from`.
    function freeFrom(address from, uint256 value) public returns (bool success) {
        address spender = msg.sender;
        uint256 from_balance = s_balances[from];
        if (value > from_balance) {
            return false;
        }

        mapping(address => uint256) from_allowances = s_allowances[from];
        uint256 spender_allowance = from_allowances[spender];
        if (value > spender_allowance) {
            return false;
        }

        destroyChildren(value);

        s_balances[from] = from_balance - value;
        from_allowances[spender] = spender_allowance - value;

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

        mapping(address => uint256) from_allowances = s_allowances[from];
        uint256 spender_allowance = from_allowances[spender];
        if (value > spender_allowance) {
            value = spender_allowance;
        }

        destroyChildren(value);

        s_balances[from] = from_balance - value;
        from_allowances[spender] = spender_allowance - value;

        return value;
    }
}