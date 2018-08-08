pragma solidity ^0.4.18;

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    function Utils() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {}
    function symbol() public view returns (string) {}
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
        @dev constructor
    */
    function Owned() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
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
        newOwner = address(0);
    }
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
contract TokenHolder is ITokenHolder, Owned, Utils {
    /**
        @dev constructor
    */
    function TokenHolder() public {
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
    Ether Token interface
*/
contract IEtherToken is ITokenHolder, IERC20Token {
    function deposit() public payable;
    function withdraw(uint256 _amount) public;
    function withdrawTo(address _to, uint256 _amount) public;
}

/*
    Smart Token interface
*/
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

/*
    EIP228 Token Converter interface
*/
contract ITokenConverter {
    function convertibleTokenCount() public view returns (uint16);
    function convertibleToken(uint16 _tokenIndex) public view returns (address);
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256);
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    // deprecated, backward compatibility
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
}

/*
    Bancor Gas Price Limit interface
*/
contract IBancorGasPriceLimit {
    function gasPrice() public view returns (uint256) {}
    function validateGasPrice(uint256) public view;
}

/*
    Bancor Quick Converter interface
*/
contract IBancorQuickConverter {
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256);
    function convertForPrioritized(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for, uint256 _block, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) public payable returns (uint256);
}

/*
    The BancorQuickConverter contract provides allows converting between any token in the 
    bancor network in a single transaction.

    A note on conversion paths -
    Conversion path is a data structure that&#39;s used when converting a token to another token in the bancor network
    when the conversion cannot necessarily be done by single converter and might require multiple &#39;hops&#39;.
    The path defines which converters should be used and what kind of conversion should be done in each step.

    The path format doesn&#39;t include complex structure and instead, it is represented by a single array
    in which each &#39;hop&#39; is represented by a 2-tuple - smart token & to token.
    In addition, the first element is always the source token.
    The smart token is only used as a pointer to a converter (since converter addresses are more likely to change).

    Format:
    [source token, smart token, to token, smart token, to token...]
*/
contract BancorQuickConverter is IBancorQuickConverter, TokenHolder {
    address public signerAddress = 0x0; // verified address that allows conversions with higher gas price
    IBancorGasPriceLimit public gasPriceLimit; // bancor universal gas price limit contract
    mapping (address => bool) public etherTokens;   // list of all supported ether tokens
    mapping (bytes32 => bool) public conversionHashes;

    /**
        @dev constructor
    */
    function BancorQuickConverter() public {
    }

    // validates a conversion path - verifies that the number of elements is odd and that maximum number of &#39;hops&#39; is 10
    modifier validConversionPath(IERC20Token[] _path) {
        require(_path.length > 2 && _path.length <= (1 + 2 * 10) && _path.length % 2 == 1);
        _;
    }

    /*
        @dev allows the owner to update the gas price limit contract address

        @param _gasPriceLimit   address of a bancor gas price limit contract
    */
    function setGasPriceLimit(IBancorGasPriceLimit _gasPriceLimit)
        public
        ownerOnly
        validAddress(_gasPriceLimit)
        notThis(_gasPriceLimit)
    {
        gasPriceLimit = _gasPriceLimit;
    }

    /*
        @dev allows the owner to update the signer address

        @param _signerAddress    new signer address
    */
    function setSignerAddress(address _signerAddress)
        public
        ownerOnly
        validAddress(_signerAddress)
        notThis(_signerAddress)
    {
        signerAddress = _signerAddress;
    }

    /**
        @dev allows the owner to register/unregister ether tokens

        @param _token       ether token contract address
        @param _register    true to register, false to unregister
    */
    function registerEtherToken(IEtherToken _token, bool _register)
        public
        ownerOnly
        validAddress(_token)
        notThis(_token)
    {
        etherTokens[_token] = _register;
    }

    /**
        @dev verifies that the signer address is trusted by recovering 
        the address associated with the public key from elliptic 
        curve signature, returns zero on error.
        notice that the signature is valid only for one conversion
        and expires after the give block.

        @return true if the signer is verified
    */
    function verifyTrustedSender(uint256 _block, address _addr, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) private returns(bool) {
        bytes32 hash = sha256(_block, tx.gasprice, _addr, _nonce);

        // checking that it is the first conversion with the given signature
        // and that the current block number doesn&#39;t exceeded the maximum block
        // number that&#39;s allowed with the current signature
        require(!conversionHashes[hash] && block.number <= _block);

        // recovering the signing address and comparing it to the trusted signer
        // address that was set in the contract
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, hash);
        bool verified = ecrecover(prefixedHash, _v, _r, _s) == signerAddress;

        // if the signer is the trusted signer - mark the hash so that it can&#39;t
        // be used multiple times
        if (verified)
            conversionHashes[hash] = true;
        return verified;
    }

/**
        @dev converts the token to any other token in the bancor network by following
        a predefined conversion path and transfers the result tokens to a target account
        note that the converter should already own the source tokens

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero
        @param _for         account that will receive the conversion result

        @return tokens issued in return
    */
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256) {
        return convertForPrioritized(_path, _amount, _minReturn, _for, 0x0, 0x0, 0x0, 0x0, 0x0);
    }

    /**
        @dev converts the token to any other token in the bancor network
        by following a predefined conversion path and transfers the result
        tokens to a target account.
        this specific version of the function also allows the verified signer
        to bypass the universal gas price limit.
        note that the converter should already own the source tokens

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero
        @param _for         account that will receive the conversion result

        @return tokens issued in return
    */
    function convertForPrioritized(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for, uint256 _block, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s)
        public
        payable
        validConversionPath(_path)
        returns (uint256)
    {
        if (_v == 0x0 && _r == 0x0 && _s == 0x0)
            gasPriceLimit.validateGasPrice(tx.gasprice);
        else
            require(verifyTrustedSender(_block, _for, _nonce, _v, _r, _s));

        // if ETH is provided, ensure that the amount is identical to _amount and verify that the source token is an ether token
        IERC20Token fromToken = _path[0];
        require(msg.value == 0 || (_amount == msg.value && etherTokens[fromToken]));

        IERC20Token toToken;

        // if ETH was sent with the call, the source is an ether token - deposit the ETH in it
        // otherwise, we assume we already have the tokens
        if (msg.value > 0)
            IEtherToken(fromToken).deposit.value(msg.value)();
        
        (_amount, toToken) = convertByPath(_path, _amount, _minReturn, fromToken);

        // finished the conversion, transfer the funds to the target account
        // if the target token is an ether token, withdraw the tokens and send them as ETH
        // otherwise, transfer the tokens as is
        if (etherTokens[toToken])
            IEtherToken(toToken).withdrawTo(_for, _amount);
        else
            assert(toToken.transfer(_for, _amount));

        return _amount;
    }

    function convertByPath(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, IERC20Token _fromToken) private returns (uint256, IERC20Token) {
        ISmartToken smartToken;
        IERC20Token toToken;
        ITokenConverter converter;

        // iterate over the conversion path
        uint256 pathLength = _path.length;

        for (uint256 i = 1; i < pathLength; i += 2) {
            smartToken = ISmartToken(_path[i]);
            toToken = _path[i + 1];
            converter = ITokenConverter(smartToken.owner());

            // if the smart token isn&#39;t the source (from token), the converter doesn&#39;t have control over it and thus we need to approve the request
            if (smartToken != _fromToken)
                ensureAllowance(_fromToken, converter, _amount);

            // make the conversion - if it&#39;s the last one, also provide the minimum return value
            _amount = converter.change(_fromToken, toToken, _amount, i == pathLength - 2 ? _minReturn : 1);
            _fromToken = toToken;
        }
        return (_amount, toToken);
    }

    /**
        @dev claims the caller&#39;s tokens, converts them to any other token in the bancor network
        by following a predefined conversion path and transfers the result tokens to a target account
        note that allowance must be set beforehand

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero
        @param _for         account that will receive the conversion result

        @return tokens issued in return
    */
    function claimAndConvertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public returns (uint256) {
        // we need to transfer the tokens from the caller to the converter before we follow
        // the conversion path, to allow it to execute the conversion on behalf of the caller
        // note: we assume we already have allowance
        IERC20Token fromToken = _path[0];
        assert(fromToken.transferFrom(msg.sender, this, _amount));
        return convertFor(_path, _amount, _minReturn, _for);
    }

    /**
        @dev converts the token to any other token in the bancor network by following
        a predefined conversion path and transfers the result tokens back to the sender
        note that the converter should already own the source tokens

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return tokens issued in return
    */
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256) {
        return convertFor(_path, _amount, _minReturn, msg.sender);
    }

    /**
        @dev claims the caller&#39;s tokens, converts them to any other token in the bancor network
        by following a predefined conversion path and transfers the result tokens back to the sender
        note that allowance must be set beforehand

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return tokens issued in return
    */
    function claimAndConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public returns (uint256) {
        return claimAndConvertFor(_path, _amount, _minReturn, msg.sender);
    }

    /**
        @dev utility, checks whether allowance for the given spender exists and approves one if it doesn&#39;t

        @param _token   token to check the allowance in
        @param _spender approved address
        @param _value   allowance amount
    */
    function ensureAllowance(IERC20Token _token, address _spender, uint256 _value) private {
        // check if allowance for the given amount already exists
        if (_token.allowance(this, _spender) >= _value)
            return;

        // if the allowance is nonzero, must reset it to 0 first
        if (_token.allowance(this, _spender) != 0)
            assert(_token.approve(_spender, 0));

        // approve the new allowance
        assert(_token.approve(_spender, _value));
    }
}