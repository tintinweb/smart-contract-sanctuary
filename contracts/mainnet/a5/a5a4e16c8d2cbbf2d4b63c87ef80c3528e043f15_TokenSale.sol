pragma solidity ^0.4.21;

// File: contracts/CCLToken.sol

// modified from Moritz Neto with BokkyPooBah / Bok Consulting Pty Ltd Au 2017.
// The MIT Licence.

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


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


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract CCLToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    function CCLToken() public {
        symbol = "CCL";
        name = "CyClean Token";
        decimals = 18;
        _totalSupply = 4000000000000000000000000000; //4,000,000,000
        balances[0xf835bF0285c99102eaedd684b4401272eF36aF65] = _totalSupply;
        Transfer(address(0), 0xf835bF0285c99102eaedd684b4401272eF36aF65, _totalSupply);
    }


    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    function () public payable {
        revert();
    }


    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

// File: contracts/ICOEngineInterface.sol

contract ICOEngineInterface {

    // false if the ico is not started, true if the ico is started and running, true if the ico is completed
    function started() public view returns(bool);

    // false if the ico is not started, false if the ico is started and running, true if the ico is completed
    function ended() public view returns(bool);

    // time stamp of the starting time of the ico, must return 0 if it depends on the block number
    function startTime() public view returns(uint);

    // time stamp of the ending time of the ico, must retrun 0 if it depends on the block number
    function endTime() public view returns(uint);

    // Optional function, can be implemented in place of startTime
    // Returns the starting block number of the ico, must return 0 if it depends on the time stamp
    // function startBlock() public view returns(uint);

    // Optional function, can be implemented in place of endTime
    // Returns theending block number of the ico, must retrun 0 if it depends on the time stamp
    // function endBlock() public view returns(uint);

    // returns the total number of the tokens available for the sale, must not change when the ico is started
    function totalTokens() public view returns(uint);

    // returns the number of the tokens available for the ico. At the moment that the ico starts it must be equal to totalTokens(),
    // then it will decrease. It is used to calculate the percentage of sold tokens as remainingTokens() / totalTokens()
    function remainingTokens() public view returns(uint);

    // return the price as number of tokens released for each ether
    function price() public view returns(uint);
}

// File: contracts/SafeMath.sol

library SafeMathLib {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

// File: contracts/KYCBase.sol

// Abstract base contract
contract KYCBase {
    using SafeMathLib for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);
    event ThisCheck(KYCBase base, address sender);
    constructor ( address[] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }

    // Must be implemented in descending contract to assign tokens to the buyers. Called after the KYC verification is passed
    function releaseTokensTo(address buyer) internal returns(bool);

    // This method can be overridden to enable some sender to buy token for a different address
    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        return buyer == msg.sender;
    }

    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress));
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }

    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        private returns (bool)
    {
        // check the signature
        bytes32 hash = sha256(abi.encodePacked("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount));
        emit ThisCheck(this, msg.sender);
        //bytes32 hash = sha256("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount);
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            revert();
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount);
            alreadyPayed[buyerId] = totalPayed;
            emit KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
    }

    // No payable fallback function, the tokens must be buyed using the functions buyTokens and buyTokensFor
    function () public {
        revert();
    }
}

// File: contracts/TokenSale.sol

contract TokenSale is ICOEngineInterface, KYCBase {
    using SafeMathLib for uint;

    event ReleaseTokensToCalled(address buyer);

    event ReleaseTokensToCalledDetail(address wallet, address buyer, uint amount, uint remainingTokensValue);
    event SenderCheck(address sender);

    CCLToken public token;
    address public wallet;

    // from ICOEngineInterface
    uint private priceValue;
    function price() public view returns(uint) {
        return priceValue;
    }

    // from ICOEngineInterface
    uint private startTimeValue;
    function startTime() public view returns(uint) {
        return startTimeValue;
    }

    // from ICOEngineInterface
    uint private endTimeValue;
    function endTime() public view returns(uint) {
        return endTimeValue;
    }
    // from ICOEngineInterface
    uint private totalTokensValue;
    function totalTokens() public view returns(uint) {
        return totalTokensValue;
    }

    // from ICOEngineInterface
    uint private remainingTokensValue;
    function remainingTokens() public view returns(uint) {
        return remainingTokensValue;
    }


    /**
     *  After you deployed the SampleICO contract, you have to call the ERC20
     *  approve() method from the _wallet account to the deployed contract address to assign
     *  the tokens to be sold by the ICO.
     */
    constructor ( address[] kycSigner, CCLToken _token, address _wallet, uint _startTime, uint _endTime, uint _price, uint _totalTokens)
        public KYCBase(kycSigner)
    {
        token = _token;
        wallet = _wallet;
        //emit WalletCheck(_wallet);
        startTimeValue = _startTime;
        endTimeValue = _endTime;
        priceValue = _price;
        totalTokensValue = _totalTokens;
        remainingTokensValue = _totalTokens;
    }

    // from KYCBase
    function releaseTokensTo(address buyer) internal returns(bool) {
        //emit SenderCheck(msg.sender);
        require(now >= startTimeValue && now < endTimeValue);
        uint amount = msg.value.mul(priceValue);
        remainingTokensValue = remainingTokensValue.sub(amount);
        emit ReleaseTokensToCalledDetail(wallet, buyer, amount, remainingTokensValue);

        wallet.transfer(msg.value);
        //require(this == token.owner());
        token.transferFrom(wallet, buyer, amount);
        emit ReleaseTokensToCalled(buyer);
        return true;
    }

    // from ICOEngineInterface
    function started() public view returns(bool) {
        return now >= startTimeValue;
    }

    // from ICOEngineInterface
    function ended() public view returns(bool) {
        return now >= endTimeValue || remainingTokensValue == 0;
    }

    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        bool value = super.senderAllowedFor(buyer);
        return value;
    }
}