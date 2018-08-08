pragma solidity ^0.4.17;

library SafeMathMod {// Partial SafeMath Library

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) < a);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) > a);
    }
}

contract ELink {//is inherently ERC20
    using SafeMathMod for uint256;

    /**
    * @constant name The name of the token
    * @constant symbol  The symbol used to display the currency
    * @constant decimals  The number of decimals used to dispay a balance
    * @constant totalSupply The total number of tokens times 10^ of the number of decimals
    * @constant MAX_UINT256 Magic number for unlimited allowance
    * @storage balanceOf Holds the balances of all token holders
    * @storage allowed Holds the allowable balance to be transferable by another address.
    */

    string constant public name = "ELink";

    string constant public symbol = "ELink";

    uint8 constant public decimals = 8;

    uint256 constant public totalSupply = 2500000e8;

    uint256 constant private MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event TransferFrom(address indexed _spender, address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function ELink() public {balanceOf[msg.sender] = totalSupply;}

    /**
    * @notice send `_value` token to `_to` from `msg.sender`
    *
    * @param _to The address of the recipient
    * @param _value The amount of token to be transferred
    * @return Whether the transfer was successful or not
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        /* Ensures that tokens are not sent to address "0x0" */
        require(_to != address(0));
        /* Prevents sending tokens directly to contracts. */
        require(isNotContract(_to));

        /* SafeMathMOd.sub will throw if there is not enough balance and if the transfer value is 0. */
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    *
    * @param _from The address of the sender
    * @param _to The address of the recipient
    * @param _value The amount of token to be transferred
    * @return Whether the transfer was successful or not
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        /* Ensures that tokens are not sent to address "0x0" */
        require(_to != address(0));
        /* Ensures tokens are not sent to this contract */
        require(_to != address(this));
        
        uint256 allowance = allowed[_from][msg.sender];
        /* Ensures sender has enough available allowance OR sender is balance holder allowing single transsaction send to contracts*/
        require(_value <= allowance || _from == msg.sender);

        /* Use SafeMathMod to add and subtract from the _to and _from addresses respectively. Prevents under/overflow and 0 transfers */
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);

        /* Only reduce allowance if not MAX_UINT256 in order to save gas on unlimited allowance */
        /* Balance holder does not need allowance to send from self. */
        if (allowed[_from][msg.sender] != MAX_UINT256 && _from != msg.sender) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Transfer the specified amounts of tokens to the specified addresses.
    * @dev Be aware that there is no check for duplicate recipients.
    *
    * @param _toAddresses Receiver addresses.
    * @param _amounts Amounts of tokens that will be transferred.
    */
    function multiPartyTransfer(address[] _toAddresses, uint256[] _amounts) public {
        /* Ensures _toAddresses array is less than or equal to 255 */
        require(_toAddresses.length <= 255);
        /* Ensures _toAddress and _amounts have the same number of entries. */
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transfer(_toAddresses[i], _amounts[i]);
        }
    }

    /**
    * @dev Transfer the specified amounts of tokens to the specified addresses from authorized balance of sender.
    * @dev Be aware that there is no check for duplicate recipients.
    *
    * @param _from The address of the sender
    * @param _toAddresses The addresses of the recipients (MAX 255)
    * @param _amounts The amounts of tokens to be transferred
    */
    function multiPartyTransferFrom(address _from, address[] _toAddresses, uint256[] _amounts) public {
        /* Ensures _toAddresses array is less than or equal to 255 */
        require(_toAddresses.length <= 255);
        /* Ensures _toAddress and _amounts have the same number of entries. */
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transferFrom(_from, _toAddresses[i], _amounts[i]);
        }
    }

    /**
    * @notice `msg.sender` approves `_spender` to spend `_value` tokens
    *
    * @param _spender The address of the account able to transfer the tokens
    * @param _value The amount of tokens to be approved for transfer
    * @return Whether the approval was successful or not
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        /* Ensures address "0x0" is not assigned allowance. */
        require(_spender != address(0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @param _owner The address of the account owning tokens
    * @param _spender The address of the account able to transfer the tokens
    * @return Amount of remaining tokens allowed to spent
    */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
    }

    function isNotContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
        /* retrieve the size of the code on target address, this needs assembly */
        length := extcodesize(_addr)
        }
        return (length == 0);
    }

    // revert on eth transfers to this contract
    function() public payable {revert();}
}