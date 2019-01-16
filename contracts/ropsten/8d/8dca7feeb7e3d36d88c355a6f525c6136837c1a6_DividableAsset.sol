/**
 * Copyright (C) 2017-2018 Hashfuture Inc. All rights reserved.
 */

pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ownable {
    address public owner;

    function ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

/**
 * The signature mechanism to enhance the credibility of the token.
 * The sign process is asychronous.
 * After the creation of the contract, one who verifies the contract and
 * is willing to guarantee for it can sign the contract address.
 */
contract verifiable {

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * signatures
     * Used to verify that if the contract is protected
     * By hashworld or other publicly verifiable organizations
     */
    mapping(address => Signature) public signatures;

    /**
     * sign Token
     */
    function sign(uint8 v, bytes32 r, bytes32 s) public {
        signatures[msg.sender] = Signature(v, r, s);
    }

    /**
     * To verify whether a specific signer has signed this contract&#39;s address
     * @param signer address to verify
     */
    function verify(address signer) public constant returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this)));
        Signature storage sig = signatures[signer];
        return ecrecover(hash, sig.v, sig.r, sig.s) == signer;
    }
}

contract AssetHashToken is ownable, verifiable{
    using SafeMath for uint;

    //Asset Struct
    struct data {
        // link URL of the original information for storing data; null means undisclosed
        string link;
        // The hash type of the original data, such as SHA-256
        string hashType;
        // Hash value of the agreed content.
        string hashValue;
    }

    data public assetFile;
    data public legalFile;

    //The token id
    uint id;

    //The validity of the contract
    bool public isValid;

    //The splitting status of the asset
    //Set to true if the asset has been splitted to small tokens
    bool public isSplitted;

    // The tradeable status of asset
    // Leave (together with assetPrice) for auto buy and sell functionality (with Ether).
    bool public isTradable;

    /**
     * The price of asset
     * if the contract is valid and tradeable,
     * others can get asset by transfer assetPrice ETH to contract
     */
    uint public assetPrice;

    uint public pledgePrice;

    //Some addtional notes
    string public remark1;
    string public remark2;

    mapping (address => uint) pendingWithdrawals;

    /**
     * The asset update events
     */
    event TokenUpdateEvent (
        uint id,
        bool isValid,
        bool isTradable,
        address owner,
        uint assetPrice,
        string assetFileLink,
        string legalFileLink
    );

    modifier onlyUnsplitted {
        require(isSplitted == false, "This function can be called only under unsplitted status");
        _;
    }

    modifier onlyValid {
        require(isValid == true, "Contract is invaild!");
        _;
    }

    /**
     * constructor
     * @param _id Token id
     * @param _owner initial owner
     * @param _assetPrice The price of asset
     * @param _assetFileUrl The url of asset file
     * @param _assetFileHashType The hash type of asset file
     * @param _assetFileHashValue The hash value of asset file
     * @param _legalFileUrl The url of legal file
     * @param _legalFileHashType The hash type of legal file
     * @param _legalFileHashValue The hash value of legal file
     */
    constructor(
        uint _id,
        address _owner,
        uint _assetPrice,
        uint _pledgePrice,
        string _assetFileUrl,
        string _assetFileHashType,
        string _assetFileHashValue,
        string _legalFileUrl,
        string _legalFileHashType,
        string _legalFileHashValue
        ) public {

        id = _id;
        owner = _owner;

        assetPrice = _assetPrice;
        pledgePrice = _pledgePrice;

        initAssetFile(
            _assetFileUrl, _assetFileHashType, _assetFileHashValue, _legalFileUrl, _legalFileHashType, _legalFileHashValue);

        isValid = true;
        isSplitted = false;
        isTradable = false;
    }

    /**
     * Initialize asset file and legal file
     * @param _assetFileUrl The url of asset file
     * @param _assetFileHashType The hash type of asset file
     * @param _assetFileHashValue The hash value of asset file
     * @param _legalFileUrl The url of legal file
     * @param _legalFileHashType The hash type of legal file
     * @param _legalFileHashValue The hash value of legal file
     */
    function initAssetFile(
        string _assetFileUrl,
        string _assetFileHashType,
        string _assetFileHashValue,
        string _legalFileUrl,
        string _legalFileHashType,
        string _legalFileHashValue
        ) internal {
        assetFile = data(
            _assetFileUrl, _assetFileHashType, _assetFileHashValue);
        legalFile = data(
            _legalFileUrl, _legalFileHashType, _legalFileHashValue);
    }

     /**
     * Get base asset info
     */
    function getAssetBaseInfo() public view onlyValid
        returns (
            uint _id,
            uint _assetPrice,
            bool _isTradable,
            string _remark1,
            string _remark2
        )
    {
        _id = id;
        _assetPrice = assetPrice;
        _isTradable = isTradable;

        _remark1 = remark1;
        _remark2 = remark2;
    }

    /**
     * set the price of asset
     * @param newAssetPrice new price of asset
     * Only can be called by owner
     */
    function setassetPrice(uint newAssetPrice)
        public
        onlyOwner
        onlyValid
        onlyUnsplitted
    {
        assetPrice = newAssetPrice;
        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }

    /**
     * set the tradeable status of asset
     * @param status status of isTradable
     * Only can be called by owner
     */
    function setTradeable(bool status) public onlyOwner onlyValid onlyUnsplitted {
        isTradable = status;
        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }

    /**
     * set the remark1
     * @param content new content of remark1
     * Only can be called by owner
     */
    function setRemark1(string content) public onlyOwner onlyValid onlyUnsplitted {
        remark1 = content;
    }

    /**
     * set the remark2
     * @param content new content of remark2
     * Only can be called by owner
     */
    function setRemark2(string content) public onlyOwner onlyValid onlyUnsplitted {
        remark2 = content;
    }

    /**
     * Modify the link of the asset file
     * @param url new link
     * Only can be called by owner
     */
    function setAssetFileLink(string url) public
        onlyOwner
        onlyValid
        onlyUnsplitted
    {
        assetFile.link = url;
        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }

    /**
     * Modify the link of the legal file
     * @param url new link
     * Only can be called by owner
     */
    function setLegalFileLink(string url)
        public
        onlyOwner
        onlyValid
        onlyUnsplitted
    {
        legalFile.link = url;
        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }

    /**
     * cancel contract
     * Only can be called by owner
     */
    function cancelContract() public onlyOwner onlyValid onlyUnsplitted {
        isValid = false;
        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }

    /**
     *  overwrite the transferOwnership interface in ownable.
     * Only can transfer when the token is not splitted into small keys.
     * After transfer, the token should be set in "no trading" status.
     */
    function transferOwnership(address newowner) public onlyOwner onlyValid onlyUnsplitted {
        owner = newowner;
        isTradable = false;  // set to false for new owner

        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }


    /**
     * Buy asset
     */
    function buy() public payable onlyValid onlyUnsplitted {
        require(isTradable == true, "contract is tradeable");
        require(msg.value >= assetPrice, "assetPrice not match");
        address origin_owner = owner;

        owner = msg.sender;
        isTradable = false;  // set to false for new owner

        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );

        uint priviousBalance = pendingWithdrawals[origin_owner];
        pendingWithdrawals[origin_owner] = priviousBalance.add(assetPrice);
    }

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];

        // Remember to zero the pending refund before sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}

/**
 * Standard ERC 20 interface.
 */
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract DividableAsset is AssetHashToken, ERC20Interface {
    using SafeMath for uint;

    ERC20Interface stableToken;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;

    address public operator;

    uint collectPrice;

    address[] internal allowners;
    mapping (address => uint) public indexOfowner;

    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowed;

    modifier onlySplitted {
        require(isSplitted == true, "Splitted status required");
        _;
    }

    modifier onlyOperator {
        require(operator == msg.sender, "Operation only permited by operator");
        _;
    }

    /**
     * The force collect event
     */
    event ForceCollectEvent (
        uint id,
        uint price,
        address operator
    );

    /**
     * The token split event
     */
    event TokenSplitEvent (
        uint id,
        uint supply,
        uint8 decim,
        uint price,
        address owner
    );

    constructor(
        string _name,
        string _symbol,
        address _tokenAddress,
        uint _id,
        address _owner,
        uint _assetPrice,
        uint _pledgePrice,
        string _assetFileUrl,
        string _assetFileHashType,
        string _assetFileHashValue,
        string _legalFileUrl,
        string _legalFileHashType,
        string _legalFileHashValue
        ) public
        AssetHashToken(
            _id,
            _owner,
            _assetPrice,
            _pledgePrice,
            _assetFileUrl,
            _assetFileHashType,
            _assetFileHashValue,
            _legalFileUrl,
            _legalFileHashType,
            _legalFileHashValue
        )
    {
        name = _name;
        symbol = _symbol;
        operator = msg.sender; // TODO set to HashFuture owned address
        stableToken = ERC20Interface(_tokenAddress);
    }

    // ERC 20 Basic Functionality

    /**
     * Total supply
     */
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    /**
     * Get the token balance for account `tokenOwner`
     */
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    /**
     * Returns the amount of tokens approved by the owner that can be
     * transferred to the spender&#39;s account
     */
    function allowance(address tokenOwner, address spender)
        public view
        returns (uint remaining)
    {
        return allowed[tokenOwner][spender];
    }

    /**
     * Transfer the balance from token owner&#39;s account to `to` account
     * - Owner&#39;s account must have sufficient balance to transfer
     * - 0 value transfers are allowed
     */
    function transfer(address to, uint tokens)
        public
        onlySplitted
        returns (bool success)
    {
        require(tokens > 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);


        // ensure that each address appears only once in allowners list
        // so that distribute divident or force collect only pays one time
        if (indexOfowner[to] == 0) {
            allowners.push(to);
            indexOfowner[to] = allowners.length;
        }
        // could be removed? no
        if (balances[msg.sender] == 0) {
            uint index = indexOfowner[msg.sender].sub(1);
            indexOfowner[msg.sender] = 0;

            if (index != allowners.length.sub(1)) {
                allowners[index] = allowners[allowners.length.sub(1)];
                indexOfowner[allowners[index]] = index.add(1);
            }

            //delete allowners[allowners.length.sub(1)];
            allowners.length = allowners.length.sub(1);
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    /**
     * Token owner can approve for `spender` to transferFrom(...) `tokens`
     * from the token owner&#39;s account
     */
    function approve(address spender, uint tokens)
        public
        onlySplitted
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /**
     * Transfer `tokens` from the `from` account to the `to` account
     */
    function transferFrom(address from, address to, uint tokens)
        public
        onlySplitted
        returns (bool success)
    {
        require(tokens > 0);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);

        // ensure that each address appears only once in allowners list
        // so that distribute divident or force collect only pays one time
        if (indexOfowner[to] == 0) {
            allowners.push(to);
            indexOfowner[to] = allowners.length;
        }

        // could be removed? no
        if (balances[from] == 0) {
            uint index = indexOfowner[from].sub(1);
            indexOfowner[from] = 0;

            if (index != allowners.length.sub(1)) {
                allowners[index] = allowners[allowners.length.sub(1)];
                indexOfowner[allowners[index]] = index.add(1);
            }
            //delete allowners[allowners.length.sub(1)];
            allowners.length = allowners.length.sub(1);
        }

        emit Transfer(from, to, tokens);
        return true;
    }

    /**
     * 
     * Warning: may fail when number of owners exceeds 100 due to gas limit of a block in Ethereum.
     */
    function distributeDivident(uint amount) public {
        // stableToken.approve(address(this), amount)
        // should be called by the caller to the token contract in previous
        uint value = 0;
        uint length = allowners.length;
        require(stableToken.balanceOf(msg.sender) >= amount, "Insufficient balance for sender");
        require(stableToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance for contract");
        for (uint i = 0; i < length; i++) {
            //value = amount * balances[allowners[i]] / _totalSupply;
            value = amount.mul(balances[allowners[i]]);
            value = value.div(_totalSupply);

            // Always use a require when doing token transfer!
            // Do not think it works like the transfer method for ether,
            // which handles failure and will throw for you.
            require(stableToken.transferFrom(msg.sender, allowners[i], value));
        }
    }

    /**
     *  partially distribute divident to given address list
     */
    function partialDistributeDivident(uint amount, address[] _address) public {
        // stableToken.approve(address(this), amount)
        // should be called by the caller to the token contract in previous
        uint value = 0;
        uint length = _address.length;
        require(stableToken.balanceOf(msg.sender) >= amount, "Insufficient balance for sender");
        require(stableToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance for contract");

        uint totalAmount = 0;
        for (uint j = 0; j < length; j++) {
            totalAmount = totalAmount.add(balances[_address[j]]);
        }

        for (uint i = 0; i < length; i++) {
            value = amount.mul(balances[_address[i]]);
            value = value.div(totalAmount);

            // Always use a require when doing token transfer!
            // Do not think it works like the transfer method for ether,
            // which handles failure and will throw for you.
            require(stableToken.transferFrom(msg.sender, _address[i], value));
        }
    }

    /**
     *  Collect all small keys in batches.
     * Anyone can force collect all keys if he provides with sufficient stable tokens.
     * However, due to the gas limitation of Ethereum, he can not collect all keys
     * with only one call. Hence an agent that can be trusted is need.
     * The operator is such an agent who will first receive a request to collect all keys,
     * and then collect them with the stable tokens provided by the claimer.
     * @param _address each address in the array means a target address to be collected from.
     */
    function collectAllForce(address[] _address) public onlyOperator {
        // stableToken.approve(address(this), amount)
        // should be called by the caller to the token contract in previous
        uint value = 0;
        uint length = _address.length;

        uint total_amount = 0;

        for (uint j = 0; j < length; j++) {
            if (indexOfowner[_address[j]] == 0) {
                continue;
            }

            total_amount = total_amount.add(collectPrice.mul(balances[_address[j]]));
        }

        require(stableToken.balanceOf(msg.sender) >= total_amount, "Insufficient balance for sender");
        require(stableToken.allowance(msg.sender, address(this)) >= total_amount, "Insufficient allowance for contract");

        for (uint i = 0; i < length; i++) {
            // Always use a require when doing token transfer!
            // Do not think it works like the transfer method for ether,
            // which handles failure and will throw for you.
            if (indexOfowner[_address[i]] == 0) {
                continue;
            }

            value = collectPrice.mul(balances[_address[i]]);

            require(stableToken.transferFrom(msg.sender, _address[i], value));
            balances[msg.sender] = balances[msg.sender].add(balances[_address[i]]);
            emit Transfer(_address[i], msg.sender, balances[_address[i]]);

            balances[_address[i]] = 0;

            uint index = indexOfowner[_address[i]].sub(1);
            indexOfowner[_address[i]] = 0;

            if (index != allowners.length.sub(1)) {
                allowners[index] = allowners[allowners.length.sub(1)];
                indexOfowner[allowners[index]] = index.add(1);
            }
            allowners.length = allowners.length.sub(1);
        }

        emit ForceCollectEvent(id, collectPrice, operator);
    }

    /**
     *  key inssurance. Split the whole token into small keys.
     * Only the owner can perform this when the token is still valid and unsplitted.
     * @param _supply Totol supply in ERC20 standard
     * @param _decim  Decimal parameter in ERC20 standard
     * @param _price The force acquisition price. If a claimer is willing to pay more than this value, he can
     * buy the keys forcibly. Notice: the claimer can only buy all keys at one time or buy nothing and the
     * buying process is delegated into a trusted agent. i.e. the operator.
     * @param _address The initial distribution plan for the keys. This parameter contains the addresses.
     * @param _amount  The amount corresponding to the initial distribution addresses.
     */
    function split(uint _supply, uint8 _decim, uint _price, address[] _address, uint[] _amount)
        public
        onlyValid
        onlyOperator
        onlyUnsplitted
    {
        require(_address.length == _amount.length);

        isSplitted = true;
        _totalSupply = _supply * 10 ** uint(_decim);
        decimals = _decim;
        collectPrice = _price;

        uint amount = 0;
        uint length = _address.length;

        balances[msg.sender] = _totalSupply;
        if (indexOfowner[msg.sender] == 0) {
            allowners.push(msg.sender);
            indexOfowner[msg.sender] = allowners.length;
        }
        emit Transfer(address(0), msg.sender, _totalSupply);

        for (uint i = 0; i < length; i++) {
            amount = _amount[i]; // * 10 ** uint(_decim);
            balances[_address[i]] = amount;
            balances[msg.sender] = balances[msg.sender].sub(amount);

            // ensure that each address appears only once in allowners list
            // so that distribute divident or force collect only pays one time
            if (indexOfowner[_address[i]] == 0) {
                allowners.push(_address[i]);
                indexOfowner[_address[i]] = allowners.length;
            }
            emit Transfer(msg.sender, _address[i], amount);
        }

        emit TokenSplitEvent(id, _supply, _decim, _price, owner);
    }

    /**
     *  Token conversion. Turn the keys to a whole token.
     * Only the sender with all keys in hand can perform this and he will be the new owner.
     */
    function merge() public onlyValid onlySplitted {
        require(balances[msg.sender] == _totalSupply);
        _totalSupply = 0;
        balances[msg.sender] = 0;
        owner = msg.sender;
        isTradable = false;
        isSplitted = false;
        emit Transfer(msg.sender, address(0), _totalSupply);
        emit TokenSplitEvent(id, 0, 0, 0, msg.sender);
    }
}