pragma solidity ^0.4.11;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public constant returns (address owner) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    /**
        @dev constructor
    */
    function Owned() {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still need to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string name) { name; }
    function symbol() public constant returns (string symbol) { symbol; }
    function decimals() public constant returns (uint8 decimals) { decimals; }
    function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

/*
    Token Holder interface
*/
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

/*
    We consider every contract to be a &#39;token holder&#39; since it&#39;s currently not possible
    for a contract to deny receiving tokens.

    The TokenHolder&#39;s contract sole purpose is to provide a safety mechanism that allows
    the owner to send tokens that were sent to the contract by mistake back to their sender.
*/
contract TokenHolder is ITokenHolder, Owned {
    /**
        @dev constructor
    */
    function TokenHolder() {
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    /**
        @dev withdraws tokens held by the contract and sends them to an account
        can only be called by the owner

        @param _token   ERC20 token contract address
        @param _to      account to receive the new amount
        @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}

/*
    EIP228 Token Changer interface
*/
contract ITokenChanger {
    function changeableTokenCount() public constant returns (uint16 count);
    function changeableToken(uint16 _tokenIndex) public constant returns (address tokenAddress);
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public constant returns (uint256 amount);
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256 amount);
}

/*
    Smart Token interface
*/
contract ISmartToken is ITokenHolder, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

/*
    Bancor Changer interface
*/
contract IBancorChanger is ITokenChanger {
    function token() public constant returns (ISmartToken _token) { _token; }
    function getReserveBalance(IERC20Token _reserveToken) public constant returns (uint256 balance);
}

/*
    Ether Token interface
*/
contract IEtherToken is ITokenHolder, IERC20Token {
    function deposit() public payable;
    function withdraw(uint256 _amount) public;
}

/*
    BancorBuyer v0.1

    The bancor buyer contract is a simple bancor changer wrapper that allows buying smart tokens with ETH

    WARNING: the contract will make the purchase using the current price at transaction mining time
*/
contract BancorBuyer is TokenHolder {
    string public version = &#39;0.1&#39;;
    IBancorChanger public tokenChanger; // bancor ETH <-> smart token changer
    IEtherToken public etherToken;      // ether token

    /**
        @dev constructor

        @param _changer     bancor token changer that actually does the purchase
        @param _etherToken  ether token used as a reserve in the token changer
    */
    function BancorBuyer(IBancorChanger _changer, IEtherToken _etherToken)
        validAddress(_changer)
        validAddress(_etherToken)
    {
        tokenChanger = _changer;
        etherToken = _etherToken;

        // ensure that the ether token is used as one of the changer&#39;s reserves
        tokenChanger.getReserveBalance(etherToken);
    }

    /**
        @dev buys the smart token with ETH
        note that the purchase will use the price at the time of the purchase

        @return tokens issued in return
    */
    function buy() public payable returns (uint256 amount) {
        etherToken.deposit.value(msg.value)(); // deposit ETH in the reserve
        assert(etherToken.approve(tokenChanger, 0)); // need to reset the allowance to 0 before setting a new one
        assert(etherToken.approve(tokenChanger, msg.value)); // approve the changer to use the ETH amount for the purchase

        ISmartToken smartToken = tokenChanger.token();
        uint256 returnAmount = tokenChanger.change(etherToken, smartToken, msg.value, 1); // do the actual change using the current price
        assert(smartToken.transfer(msg.sender, returnAmount)); // transfer the tokens to the sender
        return returnAmount;
    }

    // fallback
    function() payable {
        buy();
    }
}