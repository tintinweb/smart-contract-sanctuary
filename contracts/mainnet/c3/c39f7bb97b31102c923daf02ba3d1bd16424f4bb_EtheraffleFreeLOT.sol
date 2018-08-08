pragma solidity ^0.4.11;

contract ERC223 {
    function tokenFallback(address _from, uint _value, bytes _data) public {}
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract EtheraffleFreeLOT is ERC223 {
    using SafeMath for uint;

    string    public name;
    string    public symbol;
    address[] public minters;
    uint      public redeemed;
    uint8     public decimals;
    address[] public destroyers;
    address   public etheraffle;
    uint      public totalSupply;

    mapping (address => uint) public balances;
    mapping (address => bool) public isMinter;
    mapping (address => bool) public isDestroyer;


    event LogMinterAddition(address newMinter, uint atTime);
    event LogMinterRemoval(address minterRemoved, uint atTime);
    event LogDestroyerAddition(address newDestroyer, uint atTime);
    event LogDestroyerRemoval(address destroyerRemoved, uint atTime);
    event LogMinting(address indexed toWhom, uint amountMinted, uint atTime);
    event LogDestruction(address indexed toWhom, uint amountDestroyed, uint atTime);
    event LogEtheraffleChange(address prevController, address newController, uint atTime);
    event LogTransfer(address indexed from, address indexed to, uint value, bytes indexed data);
    /**
     * @dev   Modifier function to prepend to methods rendering them only callable
     *        by the Etheraffle MultiSig wallet.
     */
    modifier onlyEtheraffle() {
        require(msg.sender == etheraffle);
        _;
    }
    /**
     * @dev   Constructor: Sets the meta data & controller for the token.
     *
     * @param _etheraffle   The Etheraffle multisig wallet.
     * @param _amt          Amount to mint on contract creation.
     */
    function EtheraffleFreeLOT(address _etheraffle, uint _amt) {
        name       = "Etheraffle FreeLOT";
        symbol     = "FreeLOT";
        etheraffle = _etheraffle;
        minters.push(_etheraffle);
        destroyers.push(_etheraffle);
        totalSupply              = _amt;
        balances[_etheraffle]    = _amt;
        isMinter[_etheraffle]    = true;
        isDestroyer[_etheraffle] = true;
    }
    /**
     * ERC223 Standard functions:
     *
     * @dev Transfer the specified amount of FreeLOT to the specified address.
     *      Invokes the tokenFallback function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract but does not
     *      implement the tokenFallback function.
     *
     * @param _to     Receiver address.
     * @param _value  Amount of FreeLOT to be transferred.
     * @param _data   Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes _data) external {
        uint codeLength;
        assembly {
            codeLength := extcodesize(_to)
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to]        = balances[_to].add(_value);
        if(codeLength > 0) {
            ERC223 receiver = ERC223(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        LogTransfer(msg.sender, _to, _value, _data);
    }
    /**
     * @dev     Transfer the specified amount of FreeLOT to the specified address.
     *          Standard function transfer similar to ERC20 transfer with no
     *          _data param. Added due to backwards compatibility reasons.
     *
     * @param _to     Receiver address.
     * @param _value  Amount of FreeLOT to be transferred.
     */
    function transfer(address _to, uint _value) external {
        uint codeLength;
        bytes memory empty;
        assembly {
            codeLength := extcodesize(_to)
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to]        = balances[_to].add(_value);
        if(codeLength > 0) {
            ERC223 receiver = ERC223(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        LogTransfer(msg.sender, _to, _value, empty);
    }
    /**
     * @dev     Returns balance of a queried address.
     * @param _owner    The address whose balance will be returned.
     * @return balance  Balance of the of the queried address.
     */
    function balanceOf(address _owner) constant external returns (uint balance) {
        return balances[_owner];
    }
    /**
     * @dev     Allow changing of contract ownership ready for future upgrades/
     *          changes in management structure.
     *
     * @param _new  New owner/controller address.
     */
    function setEtheraffle(address _new) external onlyEtheraffle {
        LogEtheraffleChange(etheraffle, _new, now);
        etheraffle = _new;
    }
    /**
     * @dev     Allow addition of minters to allow future contracts to
     *          use the role.
     *
     * @param _new  New minter address.
     */
    function addMinter(address _new) external onlyEtheraffle {
        minters.push(_new);
        isMinter[_new] = true;
        LogMinterAddition(_new, now);
    }
    /**
     * @dev     Remove a minter should they no longer require or need the
     *          the privilege.
     *
     * @param _minter    The desired address to be removed.
     */
    function removeMinter(address _minter) external onlyEtheraffle {
        require(isMinter[_minter]);
        isMinter[_minter] = false;
        for(uint i = 0; i < minters.length - 1; i++)
            if(minters[i] == _minter) {
                minters[i] = minters[minters.length - 1];
                break;
            }
        minters.length--;
        LogMinterRemoval(_minter, now);
    }
    /**
     * @dev     Allow addition of a destroyer to allow future contracts to
     *          use the role.
     *
     * @param _new  New destroyer address.
     */
    function addDestroyer(address _new) external onlyEtheraffle {
        destroyers.push(_new);
        isDestroyer[_new] = true;
        LogDestroyerAddition(_new, now);
    }
    /**
     * @dev     Remove a destroyer should they no longer require or need the
     *          the privilege.
     *
     * @param _destroyer    The desired address to be removed.
     */
    function removeDestroyer(address _destroyer) external onlyEtheraffle {
        require(isDestroyer[_destroyer]);
        isDestroyer[_destroyer] = false;
        for(uint i = 0; i < destroyers.length - 1; i++)
            if(destroyers[i] == _destroyer) {
                destroyers[i] = destroyers[destroyers.length - 1];
                break;
            }
        destroyers.length--;
        LogDestroyerRemoval(_destroyer, now);
    }
    /**
     * @dev    This function mints tokens by adding tokens to the total supply
     *         and assigning them to the given address.
     *
     * @param _to      The address recipient of the minted tokens.
     * @param _amt     The amount of tokens to mint & assign.
     */
    function mint(address _to, uint _amt) external {
        require(isMinter[msg.sender]);
        totalSupply   = totalSupply.add(_amt);
        balances[_to] = balances[_to].add(_amt);
        LogMinting(_to, _amt, now);
    }
    /**
     * @dev    This function destroys tokens by subtracting them from the total
     *         supply and removing them from the given address. Increments the
     *         redeemed variable to track the number of "used" tokens. Only
     *         callable by the Etheraffle multisig or a designated destroyer.
     *
     * @param _from    The address from whom the token is destroyed.
     * @param _amt     The amount of tokens to destroy.
     */
    function destroy(address _from, uint _amt) external {
        require(isDestroyer[msg.sender]);
        totalSupply     = totalSupply.sub(_amt);
        balances[_from] = balances[_from].sub(_amt);
        redeemed++;
        LogDestruction(_from, _amt, now);
    }
    /**
     * @dev   Housekeeping- called in the event this contract is no
     *        longer needed. Deletes the code from the blockchain.
     *        Only callable by the Etheraffle address.
     */
    function selfDestruct() external onlyEtheraffle {
        selfdestruct(etheraffle);
    }
    /**
     * @dev   Fallback in case of accidental ether transfer
     */
    function () external payable {
        revert();
    }
}