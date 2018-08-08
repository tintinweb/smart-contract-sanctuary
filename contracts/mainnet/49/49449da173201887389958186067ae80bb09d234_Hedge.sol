pragma solidity ^0.4.11;

contract owned {

        address public owner;

        function owned() {
                owner = msg.sender;
        }

        modifier onlyOwner {
                if (msg.sender == owner)
                _;
        }


}

contract tokenRecipient {
        function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract IERC20Token {

        /// @return total amount of tokens
        function totalSupply() constant returns (uint256 totalSupply);

        /// @param _owner The address from which the balance will be retrieved
        /// @return The balance
        function balanceOf(address _owner) constant returns (uint256 balance);

        /// @notice send `_value` token to `_to` from `msg.sender`
        /// @param _to The address of the recipient
        /// @param _value The amount of token to be transferred
        /// @return Whether the transfer was successful or not
        function transfer(address _to, uint256 _value) returns (bool success);

        /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
        /// @param _from The address of the sender
        /// @param _to The address of the recipient
        /// @param _value The amount of token to be transferred
        /// @return Whether the transfer was successful or not
        function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

        /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
        /// @param _spender The address of the account able to transfer the tokens
        /// @param _value The amount of wei to be approved for transfer
        /// @return Whether the approval was successful or not
        function approve(address _spender, uint256 _value) returns (bool success);

        /// @param _owner The address of the account owning tokens
        /// @param _spender The address of the account able to transfer the tokens
        /// @return Amount of remaining tokens allowed to spent
        function allowance(address _owner, address _spender) constant returns (uint256 remaining);

        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);
        event Burn(address indexed from, uint256 value);
}

contract Hedge is IERC20Token, owned{

        /* Public variables of the token */
        string public standard = "Hedge v1.0";
        string public name = "Hedge";
        string public symbol = "HGD";
        uint8 public decimals = 18;
        uint256 public initialSupply = 50000000 * 10 ** 18;
        uint256 public tokenFrozenUntilBlock;
        uint256 public timeLock = block.timestamp + 180 days; //cofounders time lock

        /* Private variables of the token */
        uint256 supply = initialSupply;
        mapping (address => uint256) balances;
        mapping (address => mapping (address => uint256)) allowances;
        mapping (address => bool) restrictedAddresses;

        event TokenFrozen(uint256 _frozenUntilBlock, string _reason);

        /* Initializes contract and  sets restricted addresses */
        function Hedge() {
                restrictedAddresses[0x0] = true;                        // Users cannot send tokens to 0x0 address
                restrictedAddresses[address(this)] = true;      // Users cannot sent tokens to this contracts address
                balances[msg.sender] = 50000000 * 10 ** 18;
        }

        /* Get total supply of issued coins */
        function totalSupply() constant returns (uint256 totalSupply) {
                return supply;
        }

        /* Get balance of specific address */
        function balanceOf(address _owner) constant returns (uint256 balance) {
                return balances[_owner];
        }

         function transferOwnership(address newOwner) onlyOwner {
                require(transfer(newOwner, balances[msg.sender]));
                owner = newOwner;
        }

        /* Send coins */
        function transfer(address _to, uint256 _value) returns (bool success) {
                require (block.number >= tokenFrozenUntilBlock) ;       // Throw is token is frozen in case of emergency
                require (!restrictedAddresses[_to]) ;                // Prevent transfer to restricted addresses
                require (balances[msg.sender] >= _value);           // Check if the sender has enough
                require (balances[_to] + _value >= balances[_to]) ;  // Check for overflows
                require (!(msg.sender == owner && block.timestamp < timeLock && (balances[msg.sender]-_value) < 10000000 * 10 ** 18));

                balances[msg.sender] -= _value;                     // Subtract from the sender
                balances[_to] += _value;                            // Add the same to the recipient
                Transfer(msg.sender, _to, _value);                  // Notify anyone listening that this transfer took place
                return true;
        }

        /* Allow another contract to spend some tokens in your behalf */
        function approve(address _spender, uint256 _value) returns (bool success) {
                require (block.number > tokenFrozenUntilBlock); // Throw is token is frozen in case of emergency
                allowances[msg.sender][_spender] = _value;          // Set allowance
                Approval(msg.sender, _spender, _value);             // Raise Approval event
                return true;
        }

        /* Approve and then communicate the approved contract in a single tx */
        function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
                tokenRecipient spender = tokenRecipient(_spender);              // Cast spender to tokenRecipient contract
                approve(_spender, _value);                                      // Set approval to contract for _value
                spender.receiveApproval(msg.sender, _value, this, _extraData);  // Raise method on _spender contract
                return true;
        }

        /* A contract attempts to get the coins */
        function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
                require (block.number > tokenFrozenUntilBlock); // Throw is token is frozen in case of emergency
                require (!restrictedAddresses[_to]);                // Prevent transfer to restricted addresses
                require(balances[_from] >= _value);                // Check if the sender has enough
                require (balances[_to] + _value >= balances[_to]);  // Check for overflows
                require (_value <= allowances[_from][msg.sender]);  // Check allowance
                require (!(_from == owner && block.timestamp < timeLock && (balances[_from]-_value) < 10000000 * 10 ** 18));
                balances[_from] -= _value;                          // Subtract from the sender
                balances[_to] += _value;                            // Add the same to the recipient
                allowances[_from][msg.sender] -= _value;            // Deduct allowance for this address
                Transfer(_from, _to, _value);                       // Notify anyone listening that this transfer took place
                return true;
        }

        function burn(uint256 _value) returns (bool success) {
                require(balances[msg.sender] >= _value);                 // Check if the sender has enough
                balances[msg.sender] -= _value;                          // Subtract from the sender
                supply-=_value;
                Burn(msg.sender, _value);
                return true;
        }

        function burnFrom(address _from, uint256 _value) returns (bool success) {
                require(balances[_from] >= _value);                // Check if the targeted balance is enough
                require(_value <= allowances[_from][msg.sender]);    // Check allowance
                balances[_from] -= _value;                         // Subtract from the targeted balance
                allowances[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
                supply -= _value;                              // Update totalSupply
                Burn(_from, _value);
                return true;
        }

        /* Get the amount of remaining tokens to spend */
        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
                return allowances[_owner][_spender];
        }



        /* Stops all token transfers in case of emergency */
        function freezeTransfersUntil(uint256 _frozenUntilBlock, string _reason) onlyOwner {
                tokenFrozenUntilBlock = _frozenUntilBlock;
                TokenFrozen(_frozenUntilBlock, _reason);
        }

        function unfreezeTransfersUntil(string _reason) onlyOwner {
                tokenFrozenUntilBlock = 0;
                TokenFrozen(0, _reason);
        }

        /* Owner can add new restricted address or removes one */
        function editRestrictedAddress(address _newRestrictedAddress) onlyOwner {
                restrictedAddresses[_newRestrictedAddress] = !restrictedAddresses[_newRestrictedAddress];
        }

        function isRestrictedAddress(address _queryAddress) constant returns (bool answer){
                return restrictedAddresses[_queryAddress];
        }
}