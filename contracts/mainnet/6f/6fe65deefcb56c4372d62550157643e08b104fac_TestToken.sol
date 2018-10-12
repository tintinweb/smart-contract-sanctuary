pragma solidity 0.4.20;

/*
Basic contract for ERC20 token
*/

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract allowanceRecipient {
    function receiveApproval(address _from, uint256 _value, address _inContract, bytes _extraData) public returns (bool);
}

// see:
// https://github.com/ethereum/EIPs/issues/677
contract tokenRecipient {
    function tokenFallback(address _from, uint256 _value, bytes _extraData) public returns (bool);
}

contract TestToken {

    // see: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/BasicToken.sol
    using SafeMath for uint256;

    /* --- ERC-20 variables */

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#name
    // function name() constant returns (string name)
    string public name = "TestToken";

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#symbol
    // function symbol() constant returns (string symbol)
    string public symbol = "TEST";

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#decimals
    // function decimals() constant returns (uint8 decimals)
    uint8 public decimals = 0;

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#totalsupply
    // function totalSupply() constant returns (uint256 totalSupply)
    uint256 public totalSupply;

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#balanceof
    // function balanceOf(address _owner) constant returns (uint256 balance)
    mapping(address => uint256) public balanceOf;

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#allowance
    // function allowance(address _owner, address _spender) constant returns (uint256 remaining)
    mapping(address => mapping(address => uint256)) public allowance;

    /* --- ERC-20 events */

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#events

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#transfer-1
    event Transfer(address indexed from, address indexed to, uint256 value);

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#approval
    event Approval(address indexed _owner, address indexed spender, uint256 value);

    /* --- Interaction with other contracts events  */
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes _extraData);

    /* ---------- Constructor */
    // do not forget about:
    // https://medium.com/@codetractio/a-look-into-paritys-multisig-wallet-bug-affecting-100-million-in-ether-and-tokens-356f5ba6e90a
    function TestToken() public {
        balanceOf[msg.sender] = 10000;
        totalSupply = balanceOf[msg.sender];
    }


    /* --- ERC-20 Functions */
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#methods

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#transfer
    function transfer(address _to, uint256 _value) public returns (bool){
        return transferFrom(msg.sender, _to, _value);
    }

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#transferfrom
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

        // Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event (ERC-20)
        require(_value >= 0);

        // The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism
        require(msg.sender == _from || _value <= allowance[_from][msg.sender]);

        // check if _from account have required amount
        require(_value <= balanceOf[_from]);

        // Subtract from the sender
        // balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_from] = balanceOf[_from].sub(_value);
        //
        // Add the same to the recipient
        // balanceOf[_to] = balanceOf[_to] + _value;
        balanceOf[_to] = balanceOf[_to].add(_value);

        // If allowance used, change allowances correspondingly
        if (_from != msg.sender) {
            // allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

        // event
        Transfer(_from, _to, _value);

        return true;
    } // end of transferFrom

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#approve
    // there is and attack, see:
    // https://github.com/CORIONplatform/solidity/issues/6,
    // https://drive.google.com/file/d/0ByMtMw2hul0EN3NCaVFHSFdxRzA/view
    // but this function is required by ERC-20
    function approve(address _spender, uint256 _value) public returns (bool){
        require(_value >= 0);
        allowance[msg.sender][_spender] = _value;
        // event
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*  ---------- Interaction with other contracts  */

    /* User can allow another smart contract to spend some shares in his behalf
    *  (this function should be called by user itself)
    *  @param _spender another contract&#39;s address
    *  @param _value number of tokens
    *  @param _extraData Data that can be sent from user to another contract to be processed
    *  bytes - dynamically-sized byte array,
    *  see http://solidity.readthedocs.io/en/v0.4.15/types.html#dynamically-sized-byte-array
    *  see possible attack information in comments to function &#39;approve&#39;
    *  > this may be used to convert pre-ICO tokens to ICO tokens
    */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {

        approve(_spender, _value);

        // &#39;spender&#39; is another contract that implements code as prescribed in &#39;allowanceRecipient&#39; above
        allowanceRecipient spender = allowanceRecipient(_spender);

        // our contract calls &#39;receiveApproval&#39; function of another contract (&#39;allowanceRecipient&#39;) to send information about
        // allowance and data sent by user
        // &#39;this&#39; is this (our) contract address
        if (spender.receiveApproval(msg.sender, _value, this, _extraData)) {
            DataSentToAnotherContract(msg.sender, _spender, _extraData);
            return true;
        }
        return false;
    } // end of approveAndCall

    // for convenience:
    function approveAllAndCall(address _spender, bytes _extraData) public returns (bool success) {
        return approveAndCall(_spender, balanceOf[msg.sender], _extraData);
    }

    /* https://github.com/ethereum/EIPs/issues/677
    * transfer tokens with additional info to another smart contract, and calls its correspondent function
    * @param address _to - another smart contract address
    * @param uint256 _value - number of tokens
    * @param bytes _extraData - data to send to another contract
    * > this may be used to convert pre-ICO tokens to ICO tokens
    */
    function transferAndCall(address _to, uint256 _value, bytes _extraData) public returns (bool success){

        transferFrom(msg.sender, _to, _value);

        tokenRecipient receiver = tokenRecipient(_to);

        if (receiver.tokenFallback(msg.sender, _value, _extraData)) {
            DataSentToAnotherContract(msg.sender, _to, _extraData);
            return true;
        }
        return false;
    } // end of transferAndCall

    // for example for converting ALL tokens of user account to another tokens
    function transferAllAndCall(address _to, bytes _extraData) public returns (bool success){
        return transferAndCall(_to, balanceOf[msg.sender], _extraData);
    }

}