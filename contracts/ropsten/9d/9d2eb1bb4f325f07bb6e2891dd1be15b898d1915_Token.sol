pragma solidity >=0.4.10;

contract Owned {
    address public owner;
    address newOwner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract Finalizable is Owned {
    bool public finalized;

    function finalize() onlyOwner {
        finalized = true;
    }

    modifier notFinalized() {
        require(!finalized);
        _;
    }
}

// from Zeppelin
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }
}

contract Ledger is Owned, SafeMath, Finalizable {
    Controller public controller;
    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint public totalSupply;
    uint public mintingNonce;
    bool public mintingStopped;

    /**
     * Used for updating the contract with proofs. Note that the logic
     * for guarding against unwanted actions happens in the controller. We only
     * specify onlyController here.
     * @notice: not yet used
     */
    mapping(uint256 => bytes32) public proofs;

    /**
     * If bridge delivers currency back from the other network, it may be that we
     * want to lock it until the user is able to &quot;claim&quot; it. This mapping would store the
     * state of the unclaimed currency.
     * @notice: not yet used
     */
    mapping(address => uint256) public locked;

    /**
     * As a precautionary measure, we may want to include a structure to store necessary
     * data should we find that we require additional information.
     * @notice: not yet used
     */
    mapping(bytes32 => bytes32) public metadata;

    /**
     * Set by the controller to indicate where the transfers should go to on a burn
     */
    address public burnAddress;

    /**
     * Mapping allowing us to identify the bridge nodes, in the current setup
     * manipulation of this mapping is only accessible by the parameter.
     */
    mapping(address => bool) public bridgeNodes;

    // functions below this line are onlyOwner

    function Ledger() {
    }

    function setController(address _controller) onlyOwner notFinalized {
        controller = Controller(_controller);
    }

    /**
     * @dev         To be called once minting is complete, disables minting.  
     */
    function stopMinting() onlyOwner {
        mintingStopped = true;
    }

    /**
     * @dev         Used to mint a batch of currency at once.
     * 
     * @notice      This gives us a maximum of 2^96 tokens per user.
     * @notice      Expected packed structure is [ADDR(20) | VALUE(12)].
     *
     * @param       nonce   The minting nonce, an incorrect nonce is rejected.
     * @param       bits    An array of packed bytes of address, value mappings.  
     *
     */
    function multiMint(uint nonce, uint256[] bits) onlyOwner {
        require(!mintingStopped);
        if (nonce != mintingNonce) return;
        mintingNonce += 1;
        uint256 lomask = (1 << 96) - 1;
        uint created = 0;
        for (uint i=0; i<bits.length; i++) {
            address a = address(bits[i]>>96);
            uint value = bits[i]&lomask;
            balanceOf[a] = balanceOf[a] + value;
            controller.ledgerTransfer(0, a, value);
            created += value;
        }
        totalSupply += created;
    }

    // functions below this line are onlyController

    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

    function transfer(address _from, address _to, uint _value) onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        return true;
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        var allowed = allowance[_from][_spender];
        if (allowed < _value) return false;

        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        allowance[_from][_spender] = safeSub(allowed, _value);
        return true;
    }

    function approve(address _owner, address _spender, uint _value) onlyController returns (bool success) {
        // require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
            return false;
        }

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) onlyController returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = safeAdd(oldValue, _addedValue);
        return true;
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) onlyController returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowance[_owner][_spender] = 0;
        } else {
            allowance[_owner][_spender] = safeSub(oldValue, _subtractedValue);
        }
        return true;
    }

    function setProof(uint256 _key, bytes32 _proof) onlyController {
        proofs[_key] = _proof;
    }

    function setLocked(address _key, uint256 _value) onlyController {
        locked[_key] = _value;
    }

    function setMetadata(bytes32 _key, bytes32 _value) onlyController {
        metadata[_key] = _value;
    }

    /**
     * Burn related functionality
     */

    /**
     * @dev        sets the burn address to the new value
     *
     * @param      _address  The address
     *
     */
    function setBurnAddress(address _address) onlyController {
        burnAddress = _address;
    }

    function setBridgeNode(address _address, bool enabled) onlyController {
        bridgeNodes[_address] = enabled;
    }
}


contract IToken {
    function transfer(address _to, uint _value) returns (bool);
    function balanceOf(address owner) returns(uint);
}

// In case someone accidentally sends token to one of these contracts,
// add a way to get them back out.
contract TokenReceivable is Owned {
    function claimTokens(address _token, address _to) onlyOwner returns (bool) {
        IToken token = IToken(_token);
        return token.transfer(_to, token.balanceOf(this));
    }
}

contract EventDefinitions {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, bytes32 indexed to, uint value);
    event Claimed(address indexed claimer, uint value);
}

contract Pausable is Owned {
    bool public paused;

    function pause() onlyOwner {
        paused = true;
    }

    function unpause() onlyOwner {
        paused = false;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }
}

contract Token is Finalizable, TokenReceivable, SafeMath, EventDefinitions, Pausable {
    // Set these appropriately before you deploy
    string constant public name = &quot;AION&quot;;
    uint8 constant public decimals = 8;
    string constant public symbol = &quot;AION&quot;;
    Controller public controller;
    string public motd;
    event Motd(string message);

    address public burnAddress; //@ATTENTION: set this to a correct value
    bool public burnable = false;

    // functions below this line are onlyOwner

    // set &quot;message of the day&quot;
    function setMotd(string _m) onlyOwner {
        motd = _m;
        Motd(_m);
    }

    function setController(address _c) onlyOwner notFinalized {
        controller = Controller(_c);
    }

    // functions below this line are public

    function balanceOf(address a) constant returns (uint) {
        return controller.balanceOf(a);
    }

    function totalSupply() constant returns (uint) {
        return controller.totalSupply();
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return controller.allowance(_owner, _spender);
    }

    function transfer(address _to, uint _value) notPaused returns (bool success) {
        if (controller.transfer(msg.sender, _to, _value)) {
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint _value) notPaused returns (bool success) {
        if (controller.transferFrom(msg.sender, _from, _to, _value)) {
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint _value) notPaused returns (bool success) {
        // promote safe user behavior
        if (controller.approve(msg.sender, _spender, _value)) {
            Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }

    function increaseApproval (address _spender, uint _addedValue) notPaused returns (bool success) {
        if (controller.increaseApproval(msg.sender, _spender, _addedValue)) {
            uint newval = controller.allowance(msg.sender, _spender);
            Approval(msg.sender, _spender, newval);
            return true;
        }
        return false;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) notPaused returns (bool success) {
        if (controller.decreaseApproval(msg.sender, _spender, _subtractedValue)) {
            uint newval = controller.allowance(msg.sender, _spender);
            Approval(msg.sender, _spender, newval);
            return true;
        }
        return false;
    }

    // modifier onlyPayloadSize(uint numwords) {
    //     assert(msg.data.length >= numwords * 32 + 4);
    //     _;
    // }

    // functions below this line are onlyController

    modifier onlyController() {
        assert(msg.sender == address(controller));
        _;
    }

    // In the future, when the controller supports multiple token
    // heads, allow the controller to reconstitute the transfer and
    // approval history.

    function controllerTransfer(address _from, address _to, uint _value) onlyController {
        Transfer(_from, _to, _value);
    }

    function controllerApprove(address _owner, address _spender, uint _value) onlyController {
        Approval(_owner, _spender, _value);
    }

    /**
     * @dev        Burn event possibly called by the controller on a burn. This is
     *             the public facing event that anyone can track, the bridges listen
     *             to an alternative event emitted by the controller.
     *
     * @param      _from   address that coins are burned from
     * @param      _to     address (on other network) that coins are received by
     * @param      _value  amount of value to be burned
     *
     * @return     { description_of_the_return_value }
     */
    function controllerBurn(address _from, bytes32 _to, uint256 _value) onlyController {
        Burn(_from, _to, _value);
    }

    function controllerClaim(address _claimer, uint256 _value) onlyController {
        Claimed(_claimer, _value);
    }

    /**
     * @dev        Sets the burn address to a new value
     *
     * @param      _address  The address
     *
     */
    function setBurnAddress(address _address) onlyController {
        burnAddress = _address;
    }

    /**
     * @dev         Enables burning through burnable bool
     *
     */
    function enableBurning() onlyController {
        burnable = true;
    }

    /**
     * @dev         Disables burning through burnable bool
     *
     */
    function disableBurning() onlyController {
        burnable = false;
    }

    /**
     * @dev         Indicates that burning is enabled
     */
    modifier burnEnabled() {
        require(burnable == true);
        _;
    }

    /**
     * @dev         burn function, changed from original implementation. Public facing API
     *              indicating who the token holder wants to burn currency to and the amount.
     *
     * @param       _amount  The amount
     *
     */
    function burn(bytes32 _to, uint _amount) notPaused burnEnabled returns (bool success) {
        return controller.burn(msg.sender, _to, _amount);
    }

    /**
     * @dev         claim (quantumReceive) allows the user to &quot;prove&quot; some an ICT to the contract
     *              thereby thereby releasing the tokens into their account
     * 
     */
    function claimByProof(bytes32[] data, bytes32[] proofs, uint256 number) notPaused burnEnabled returns (bool success) {
        return controller.claimByProof(msg.sender, data, proofs, number);
    }

    /**
     * @dev         Simplified version of claim, just requires user to call to claim.
     *              No proof is needed, which version is chosen depends on our bridging model.
     *
     * @return      
     */
    function claim() notPaused burnEnabled returns (bool success) {
        return controller.claim(msg.sender);
    }
}

contract ControllerEventDefinitions {
    /**
     * An internal burn event, emitted by the controller contract
     * which the bridges could be listening to.
     */
    event ControllerBurn(address indexed from, bytes32 indexed to, uint value);
}

/**
 * @title Controller for business logic between the ERC20 API and State
 *
 * Controller is responsible for the business logic that sits in between
 * the Ledger (model) and the Token (view). Presently, adherence to this model
 * is not strict, but we expect future functionality (Burning, Claiming) to adhere
 * to this model more closely.
 * 
 * The controller must be linked to a Token and Ledger to become functional.
 * 
 */
contract Controller is Owned, Finalizable, ControllerEventDefinitions {
    Ledger public ledger;
    Token public token;
    address public burnAddress;

    function Controller() {
    }

    // functions below this line are onlyOwner


    function setToken(address _token) onlyOwner {
        token = Token(_token);
    }

    function setLedger(address _ledger) onlyOwner {
        ledger = Ledger(_ledger);
    }

    /**
     * @dev         Sets the burn address burn values get moved to. Only call
     *              after token and ledger contracts have been hooked up. Ensures
     *              that all three values are set atomically.
     *             
     * @notice      New Functionality
     *
     * @param       _address    desired address
     *
     */
    function setBurnAddress(address _address) onlyOwner {
        burnAddress = _address;
        ledger.setBurnAddress(_address);
        token.setBurnAddress(_address);
    }

    modifier onlyToken() {
        require(msg.sender == address(token));
        _;
    }

    modifier onlyLedger() {
        require(msg.sender == address(ledger));
        _;
    }

    function totalSupply() constant returns (uint) {
        return ledger.totalSupply();
    }

    function balanceOf(address _a) constant returns (uint) {
        return ledger.balanceOf(_a);
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return ledger.allowance(_owner, _spender);
    }

    // functions below this line are onlyLedger

    // let the ledger send transfer events (the most obvious case
    // is when we mint directly to the ledger and need the Transfer()
    // events to appear in the token)
    function ledgerTransfer(address from, address to, uint val) onlyLedger {
        token.controllerTransfer(from, to, val);
    }

    // functions below this line are onlyToken

    function transfer(address _from, address _to, uint _value) onlyToken returns (bool success) {
        return ledger.transfer(_from, _to, _value);
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) onlyToken returns (bool success) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    function approve(address _owner, address _spender, uint _value) onlyToken returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) onlyToken returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) onlyToken returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }

    /**
     * End Original Contract
     * Below is new functionality
     */

    /**
     * @dev        Enables burning on the token contract
     */
    function enableBurning() onlyOwner {
        token.enableBurning();
    }

    /**
     * @dev        Disables burning on the token contract
     */
    function disableBurning() onlyOwner {
        token.disableBurning();
    }

    // public functions

    /**
     * @dev         
     *
     * @param       _from       account the value is burned from
     * @param       _to         the address receiving the value
     * @param       _amount     the value amount
     * 
     * @return      success     operation successful or not.
     */ 
    function burn(address _from, bytes32 _to, uint _amount) onlyToken returns (bool success) {
        if (ledger.transfer(_from, burnAddress, _amount)) {
            ControllerBurn(_from, _to, _amount);
            token.controllerBurn(_from, _to, _amount);
            return true;
        }
        return false;
    }

    /**
     * @dev         Implementation for claim mechanism. Note that this mechanism has not yet
     *              been implemented. This function is only here for future expansion capabilities.
     *              Presently, just returns false to indicate failure.
     *              
     * @notice      Only one of claimByProof() or claim() will potentially be activated in the future.
     *              Depending on the functionality required and route selected. 
     *
     * @param       _claimer    The individual claiming the tokens (also the recipient of said tokens).
     * @param       data        The input data required to release the tokens.
     * @param       success     The proofs associated with the data, to indicate the legitimacy of said data.
     * @param       number      The block number the proofs and data correspond to.
     *
     * @return      success     operation successful or not.
     * 
     */
    function claimByProof(address _claimer, bytes32[] data, bytes32[] proofs, uint256 number)
        onlyToken
        returns (bool success) {
        return false;
    }

    /**
     * @dev         Implementation for an alternative claim mechanism, in which the participant
     *              is not required to confirm through proofs. Note that this mechanism has not
     *              yet been implemented.
     *              
     * @notice      Only one of claimByProof() or claim() will potentially be activated in the future.
     *              Depending on the functionality required and route selected.
     * 
     * @param       _claimer    The individual claiming the tokens (also the recipient of said tokens).
     * 
     * @return      success     operation successful or not.
     */
    function claim(address _claimer) onlyToken returns (bool success) {
        return false;
    }
}

/**
 * Ledger with the ability to mint tokens
 */
contract MintableLedger is Ledger {

    /**
     * For easy testing we will be emitting this event
     */
    event Mint(address to, uint256 value);

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public returns (bool) {
        require(!mintingStopped);
        totalSupply = safeAdd(totalSupply, _amount);
        balanceOf[_to] = safeAdd(balanceOf[_to], _amount);
        Mint(_to, _amount);
        controller.ledgerTransfer(address(0), _to, _amount);
        return true;
    }
}