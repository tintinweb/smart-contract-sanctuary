pragma solidity ^0.4.10;

contract GasToken1 {
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
    string constant public symbol = "GST1";

    // We start our storage at this location. The EVM word at this location
    // contains the number of stored words. The stored words follow at
    // locations (STORAGE_LOCATION_ARRAY+1), (STORAGE_LOCATION_ARRAY+2), ...
    uint256 constant STORAGE_LOCATION_ARRAY = 0xDEADBEEF;


    // totalSupply is the number of words we have in storage
    function totalSupply() public constant returns (uint256 supply) {
        uint256 storage_location_array = STORAGE_LOCATION_ARRAY;
        assembly {
            supply := sload(storage_location_array)
        }
    }

    // Mints `value` new sub-tokens (e.g. cents, pennies, ...) by filling up
    // `value` words of EVM storage. The minted tokens are owned by the
    // caller of this function.
    function mint(uint256 value) public {
        uint256 storage_location_array = STORAGE_LOCATION_ARRAY;  // can&#39;t use constants inside assembly

        if (value == 0) {
            return;
        }

        // Read supply
        uint256 supply;
        assembly {
            supply := sload(storage_location_array)
        }

        // Set memory locations in interval [l, r]
        uint256 l = storage_location_array + supply + 1;
        uint256 r = storage_location_array + supply + value;
        assert(r >= l);

        for (uint256 i = l; i <= r; i++) {
            assembly {
                sstore(i, 1)
            }
        }

        // Write updated supply & balance
        assembly {
            sstore(storage_location_array, add(supply, value))
        }
        s_balances[msg.sender] += value;
    }

    function freeStorage(uint256 value) internal {
        uint256 storage_location_array = STORAGE_LOCATION_ARRAY;  // can&#39;t use constants inside assembly

        // Read supply
        uint256 supply;
        assembly {
            supply := sload(storage_location_array)
        }

        // Clear memory locations in interval [l, r]
        uint256 l = storage_location_array + supply - value + 1;
        uint256 r = storage_location_array + supply;
        for (uint256 i = l; i <= r; i++) {
            assembly {
                sstore(i, 0)
            }
        }

        // Write updated supply
        assembly {
            sstore(storage_location_array, sub(supply, value))
        }
    }

    // Frees `value` sub-tokens (e.g. cents, pennies, ...) belonging to the
    // caller of this function by clearing value words of EVM storage, which
    // will trigger a partial gas refund.
    function free(uint256 value) public returns (bool success) {
        uint256 from_balance = s_balances[msg.sender];
        if (value > from_balance) {
            return false;
        }

        freeStorage(value);

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

        freeStorage(value);

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

        freeStorage(value);

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

        freeStorage(value);

        s_balances[from] = from_balance - value;
        from_allowances[spender] = spender_allowance - value;

        return value;
    }
}