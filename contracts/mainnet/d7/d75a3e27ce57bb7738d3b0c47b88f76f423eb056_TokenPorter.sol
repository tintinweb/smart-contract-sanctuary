/*
    The MIT License (MIT)

    Copyright 2017 - 2018, Alchemy Limited, LLC and Smart Contract Solutions.

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
pragma solidity ^0.4.21;


/**
 * Reference: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 *
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
/* end SafeMath library */


/// @title Math operation when both numbers has decimal places.
/// @notice Use this contract when both numbers has 18 decimal places. 
contract FixedMath {
    
    using SafeMath for uint;
    uint constant internal METDECIMALS = 18;
    uint constant internal METDECMULT = 10 ** METDECIMALS;
    uint constant internal DECIMALS = 18;
    uint constant internal DECMULT = 10 ** DECIMALS;

    /// @notice Multiplication.
    function fMul(uint x, uint y) internal pure returns (uint) {
        return (x.mul(y)).div(DECMULT);
    }

    /// @notice Division.
    function fDiv(uint numerator, uint divisor) internal pure returns (uint) {
        return (numerator.mul(DECMULT)).div(divisor);
    }

    /// @notice Square root.
    /// @dev Reference: https://stackoverflow.com/questions/3766020/binary-search-to-compute-square-root-java
    function fSqrt(uint n) internal pure returns (uint) {
        if (n == 0) {
            return 0;
        }
        uint z = n * n;
        require(z / n == n);

        uint high = fAdd(n, DECMULT);
        uint low = 0;
        while (fSub(high, low) > 1) {
            uint mid = fAdd(low, high) / 2;
            if (fSqr(mid) <= n) {
                low = mid;
            } else {
                high = mid;
            }
        }
        return low;
    }

    /// @notice Square.
    function fSqr(uint n) internal pure returns (uint) {
        return fMul(n, n);
    }

    /// @notice Add.
    function fAdd(uint x, uint y) internal pure returns (uint) {
        return x.add(y);
    }

    /// @notice Sub.
    function fSub(uint x, uint y) internal pure returns (uint) {
        return x.sub(y);
    }
}


/// @title A formula contract for converter
contract Formula is FixedMath {

    /// @notice Trade in reserve(ETH/MET) and mint new smart tokens
    /// @param smartTokenSupply Total supply of smart token
    /// @param reserveTokensSent Amount of token sent by caller
    /// @param reserveTokenBalance Balance of reserve token in the contract
    /// @return Smart token minted
    function returnForMint(uint smartTokenSupply, uint reserveTokensSent, uint reserveTokenBalance) 
        internal pure returns (uint)
    {
        uint s = smartTokenSupply;
        uint e = reserveTokensSent;
        uint r = reserveTokenBalance;
        /// smartToken for mint(T) = S * (sqrt(1 + E/R) - 1)
        /// DECMULT is same as 1 for values with 18 decimal places
        return ((fMul(s, (fSub(fSqrt(fAdd(DECMULT, fDiv(e, r))), DECMULT)))).mul(METDECMULT)).div(DECMULT);
    }

    /// @notice Redeem smart tokens, get back reserve(ETH/MET) token
    /// @param smartTokenSupply Total supply of smart token
    /// @param smartTokensSent Smart token sent
    /// @param reserveTokenBalance Balance of reserve token in the contract
    /// @return Reserve token redeemed
    function returnForRedemption(uint smartTokenSupply, uint smartTokensSent, uint reserveTokenBalance)
        internal pure returns (uint)
    {
        uint s = smartTokenSupply;
        uint t = smartTokensSent;
        uint r = reserveTokenBalance;
        /// reserveToken (E) = R * (1 - (1 - T/S)**2)
        /// DECMULT is same as 1 for values with 18 decimal places
        return ((fMul(r, (fSub(DECMULT, fSqr(fSub(DECMULT, fDiv(t, s))))))).mul(METDECMULT)).div(DECMULT);
    }
}


/// @title Pricer contract to calculate descending price during auction.
contract Pricer {

    using SafeMath for uint;
    uint constant internal METDECIMALS = 18;
    uint constant internal METDECMULT = 10 ** METDECIMALS;
    uint public minimumPrice = 33*10**11;
    uint public minimumPriceInDailyAuction = 1;

    uint public tentimes;
    uint public hundredtimes;
    uint public thousandtimes;

    uint constant public MULTIPLIER = 1984320568*10**5;

    /// @notice Pricer constructor, calculate 10, 100 and 1000 times of 0.99.
    function initPricer() public {
        uint x = METDECMULT;
        uint i;
        
        /// Calculate 10 times of 0.99
        for (i = 0; i < 10; i++) {
            x = x.mul(99).div(100);
        }
        tentimes = x;
        x = METDECMULT;

        /// Calculate 100 times of 0.99 using tentimes calculated above.
        /// tentimes has 18 decimal places and due to this METDECMLT is
        /// used as divisor.
        for (i = 0; i < 10; i++) {
            x = x.mul(tentimes).div(METDECMULT);
        }
        hundredtimes = x;
        x = METDECMULT;

        /// Calculate 1000 times of 0.99 using hundredtimes calculated above.
        /// hundredtimes has 18 decimal places and due to this METDECMULT is
        /// used as divisor.
        for (i = 0; i < 10; i++) {
            x = x.mul(hundredtimes).div(METDECMULT);
        }
        thousandtimes = x;
    }

    /// @notice Price of MET at nth minute out during operational auction
    /// @param initialPrice The starting price ie last purchase price
    /// @param _n The number of minutes passed since last purchase
    /// @return The resulting price
    function priceAt(uint initialPrice, uint _n) public view returns (uint price) {
        uint mult = METDECMULT;
        uint i;
        uint n = _n;

        /// If quotient of n/1000 is greater than 0 then calculate multiplier by
        /// multiplying thousandtimes and mult in a loop which runs quotient times.
        /// Also assign new value to n which is remainder of n/1000.
        if (n / 1000 > 0) {
            for (i = 0; i < n / 1000; i++) {
                mult = mult.mul(thousandtimes).div(METDECMULT);
            }
            n = n % 1000;
        }

        /// If quotient of n/100 is greater than 0 then calculate multiplier by
        /// multiplying hundredtimes and mult in a loop which runs quotient times.
        /// Also assign new value to n which is remainder of n/100.
        if (n / 100 > 0) {
            for (i = 0; i < n / 100; i++) {
                mult = mult.mul(hundredtimes).div(METDECMULT);
            }
            n = n % 100;
        }

        /// If quotient of n/10 is greater than 0 then calculate multiplier by
        /// multiplying tentimes and mult in a loop which runs quotient times.
        /// Also assign new value to n which is remainder of n/10.
        if (n / 10 > 0) {
            for (i = 0; i < n / 10; i++) {
                mult = mult.mul(tentimes).div(METDECMULT);
            }
            n = n % 10;
        }

        /// Calculate multiplier by multiplying 0.99 and mult, repeat it n times.
        for (i = 0; i < n; i++) {
            mult = mult.mul(99).div(100);
        }

        /// price is calculated as initialPrice multiplied by 0.99 and that too _n times.
        /// Here mult is METDECMULT multiplied by 0.99 and that too _n times.
        price = initialPrice.mul(mult).div(METDECMULT);
        
        if (price < minimumPriceInDailyAuction) {
            price = minimumPriceInDailyAuction;
        }
    }

    /// @notice Price of MET at nth minute during initial auction.
    /// @param lastPurchasePrice The price of MET in last transaction
    /// @param numTicks The number of minutes passed since last purchase
    /// @return The resulting price
    function priceAtInitialAuction(uint lastPurchasePrice, uint numTicks) public view returns (uint price) {
        /// Price will decrease linearly every minute by the factor of MULTIPLIER.
        /// If lastPurchasePrice is greater than decrease in price then calculated the price.
        /// Return minimumPrice, if calculated price is less than minimumPrice.
        /// If decrease in price is more than lastPurchasePrice then simply return the minimumPrice.
        if (lastPurchasePrice > MULTIPLIER.mul(numTicks)) {
            price = lastPurchasePrice.sub(MULTIPLIER.mul(numTicks));
        }

        if (price < minimumPrice) {
            price = minimumPrice;
        }
    }
}


/// @dev Reference: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
/// @notice ERC20 standard interface
interface ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function allowance(address _owner, address _spender) public constant returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function approve(address _spender, uint256 _value) public returns (bool);
}


/// @title Ownable
contract Ownable {

    address public owner;
    event OwnershipChanged(address indexed prevOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @notice Allows the current owner to transfer control of the contract to a newOwner.
    /// @param _newOwner 
    /// @return true/false
    function changeOwnership(address _newOwner) public onlyOwner returns (bool) {
        require(_newOwner != address(0));
        require(_newOwner != owner);
        emit OwnershipChanged(owner, _newOwner);
        owner = _newOwner;
        return true;
    }
}


/// @title Owned
contract Owned is Ownable {

    address public newOwner;

    /// @notice Allows the current owner to transfer control of the contract to a newOwner.
    /// @param _newOwner 
    /// @return true/false
    function changeOwnership(address _newOwner) public onlyOwner returns (bool) {
        require(_newOwner != owner);
        newOwner = _newOwner;
        return true;
    }

    /// @notice Allows the new owner to accept ownership of the contract.
    /// @return true/false
    function acceptOwnership() public returns (bool) {
        require(msg.sender == newOwner);

        emit OwnershipChanged(owner, newOwner);
        owner = newOwner;
        return true;
    }
}


/// @title Mintable contract to allow minting and destroy.
contract Mintable is Owned {

    using SafeMath for uint256;

    event Mint(address indexed _to, uint _value);
    event Destroy(address indexed _from, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balanceOf;

    address public autonomousConverter;
    address public minter;
    ITokenPorter public tokenPorter;

    /// @notice init reference of other contract and initial supply
    /// @param _autonomousConverter 
    /// @param _minter 
    /// @param _initialSupply 
    /// @param _decmult Decimal places
    function initMintable(address _autonomousConverter, address _minter, uint _initialSupply, 
        uint _decmult) public onlyOwner {
        require(autonomousConverter == 0x0 && _autonomousConverter != 0x0);
        require(minter == 0x0 && _minter != 0x0);
      
        autonomousConverter = _autonomousConverter;
        minter = _minter;
        _totalSupply = _initialSupply.mul(_decmult);
        _balanceOf[_autonomousConverter] = _totalSupply;
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return _balanceOf[_owner];
    }

    /// @notice set address of token porter
    /// @param _tokenPorter address of token porter
    function setTokenPorter(address _tokenPorter) public onlyOwner returns (bool) {
        require(_tokenPorter != 0x0);

        tokenPorter = ITokenPorter(_tokenPorter);
        return true;
    }

    /// @notice allow minter and tokenPorter to mint token and assign to address
    /// @param _to 
    /// @param _value Amount to be minted  
    function mint(address _to, uint _value) public returns (bool) {
        require(msg.sender == minter || msg.sender == address(tokenPorter));
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        _totalSupply = _totalSupply.add(_value);
        emit Mint(_to, _value);
        emit Transfer(0x0, _to, _value);
        return true;
    }

    /// @notice allow autonomousConverter and tokenPorter to mint token and assign to address
    /// @param _from 
    /// @param _value Amount to be destroyed
    function destroy(address _from, uint _value) public returns (bool) {
        require(msg.sender == autonomousConverter || msg.sender == address(tokenPorter));
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Destroy(_from, _value);
        emit Transfer(_from, 0x0, _value);
        return true;
    }
}


/// @title Token contract
contract Token is ERC20, Mintable {
    mapping(address => mapping(address => uint256)) internal _allowance;

    function initToken(address _autonomousConverter, address _minter,
     uint _initialSupply, uint _decmult) public onlyOwner {
        initMintable(_autonomousConverter, _minter, _initialSupply, _decmult);
    }

    /// @notice Provide allowance information
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return _allowance[_owner][_spender];
    }

    /// @notice Transfer tokens from sender to the provided address.
    /// @param _to Receiver of the tokens
    /// @param _value Amount of token
    /// @return true/false
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_to != minter);
        require(_to != address(this));
        require(_to != autonomousConverter);
        Proceeds proceeds = Auctions(minter).proceeds();
        require((_to != address(proceeds)));

        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Transfer tokens based on allowance.
    /// msg.sender must have allowance for spending the tokens from owner ie _from
    /// @param _from Owner of the tokens
    /// @param _to Receiver of the tokens
    /// @param _value Amount of tokens to transfer
    /// @return true/false
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) { 
        require(_to != address(0));       
        require(_to != minter && _from != minter);
        require(_to != address(this) && _from != address(this));
        Proceeds proceeds = Auctions(minter).proceeds();
        require(_to != address(proceeds) && _from != address(proceeds));
        //AC can accept MET via this function, needed for MetToEth conversion
        require(_from != autonomousConverter);
        require(_allowance[_from][msg.sender] >= _value);
        
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Approve spender to spend the tokens ie approve allowance
    /// @param _spender Spender of the tokens
    /// @param _value Amount of tokens that can be spent by spender
    /// @return true/false
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(this));
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice Transfer the tokens from sender to all the address provided in the array.
    /// @dev Left 160 bits are the recipient address and the right 96 bits are the token amount.
    /// @param bits array of uint
    /// @return true/false
    function multiTransfer(uint[] bits) public returns (bool) {
        for (uint i = 0; i < bits.length; i++) {
            address a = address(bits[i] >> 96);
            uint amount = bits[i] & ((1 << 96) - 1);
            if (!transfer(a, amount)) revert();
        }

        return true;
    }

    /// @notice Increase allowance of spender
    /// @param _spender Spender of the tokens
    /// @param _value Amount of tokens that can be spent by spender
    /// @return true/false
    function approveMore(address _spender, uint256 _value) public returns (bool) {
        uint previous = _allowance[msg.sender][_spender];
        uint newAllowance = previous.add(_value);
        _allowance[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        return true;
    }

    /// @notice Decrease allowance of spender
    /// @param _spender Spender of the tokens
    /// @param _value Amount of tokens that can be spent by spender
    /// @return true/false
    function approveLess(address _spender, uint256 _value) public returns (bool) {
        uint previous = _allowance[msg.sender][_spender];
        uint newAllowance = previous.sub(_value);
        _allowance[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        return true;
    }
}


/// @title  Smart tokens are an intermediate token generated during conversion of MET-ETH
contract SmartToken is Mintable {
    uint constant internal METDECIMALS = 18;
    uint constant internal METDECMULT = 10 ** METDECIMALS;

    function initSmartToken(address _autonomousConverter, address _minter, uint _initialSupply) public  onlyOwner {
        initMintable(_autonomousConverter, _minter, _initialSupply, METDECMULT); 
    }
}


/// @title ERC20 token. Metronome token 
contract METToken is Token {

    string public constant name = "Metronome";
    string public constant symbol = "MET";
    uint8 public constant decimals = 18;

    bool public transferAllowed;

    function initMETToken(address _autonomousConverter, address _minter, 
        uint _initialSupply, uint _decmult) public onlyOwner {
        initToken(_autonomousConverter, _minter, _initialSupply, _decmult);
    }
    
    /// @notice Transferable modifier to allow transfer only after initial auction ended.
    modifier transferable() {
        require(transferAllowed);
        _;
    }

    function enableMETTransfers() public returns (bool) {
        require(!transferAllowed && Auctions(minter).isInitialAuctionEnded());
        transferAllowed = true; 
        return true;
    }

    /// @notice Transfer tokens from caller to another address
    /// @param _to address The address which you want to transfer to
    /// @param _value uint256 the amout of tokens to be transfered
    function transfer(address _to, uint256 _value) public transferable returns (bool) {
        return super.transfer(_to, _value);
        
    }

    /// @notice Transfer tokens from one address to another
    /// @param _from address The address from which you want to transfer
    /// @param _to address The address which you want to transfer to
    /// @param _value uint256 the amout of tokens to be transfered
    function transferFrom(address _from, address _to, uint256 _value) public transferable returns (bool) {        
        return super.transferFrom(_from, _to, _value);
    }

    /// @notice Transfer the token from sender to all the addresses provided in array.
    /// @dev Left 160 bits are the recipient address and the right 96 bits are the token amount.
    /// @param bits array of uint
    /// @return true/false
    function multiTransfer(uint[] bits) public transferable returns (bool) {
        return super.multiTransfer(bits);
    }
    
    mapping (address => bytes32) public roots;

    function setRoot(bytes32 data) public {
        roots[msg.sender] = data;
    }

    function getRoot(address addr) public view returns (bytes32) {
        return roots[addr];
    }

    function rootsMatch(address a, address b) public view returns (bool) {
        return roots[a] == roots[b];
    }

    /// @notice import MET tokens from another chain to this chain.
    /// @param _destinationChain destination chain name
    /// @param _addresses _addresses[0] is destMetronomeAddr and _addresses[1] is recipientAddr
    /// @param _extraData extra information for import
    /// @param _burnHashes _burnHashes[0] is previous burnHash, _burnHashes[1] is current burnHash
    /// @param _supplyOnAllChains MET supply on all supported chains
    /// @param _importData _importData[0] is _blockTimestamp, _importData[1] is _amount, _importData[2] is _fee
    /// _importData[3] is _burnedAtTick, _importData[4] is _genesisTime, _importData[5] is _dailyMintable
    /// _importData[6] is _burnSequence, _importData[7] is _dailyAuctionStartTime
    /// @param _proof proof
    /// @return true/false
    function importMET(bytes8 _originChain, bytes8 _destinationChain, address[] _addresses, bytes _extraData, 
        bytes32[] _burnHashes, uint[] _supplyOnAllChains, uint[] _importData, bytes _proof) public returns (bool)
    {
        require(address(tokenPorter) != 0x0);
        return tokenPorter.importMET(_originChain, _destinationChain, _addresses, _extraData, 
        _burnHashes, _supplyOnAllChains, _importData, _proof);
    }

    /// @notice export MET tokens from this chain to another chain.
    /// @param _destChain destination chain address
    /// @param _destMetronomeAddr address of Metronome contract on the destination chain 
    /// where this MET will be imported.
    /// @param _destRecipAddr address of account on destination chain
    /// @param _amount amount
    /// @param _extraData extra information for future expansion
    /// @return true/false
    function export(bytes8 _destChain, address _destMetronomeAddr, address _destRecipAddr, uint _amount, uint _fee, 
    bytes _extraData) public returns (bool)
    {
        require(address(tokenPorter) != 0x0);
        return tokenPorter.export(msg.sender, _destChain, _destMetronomeAddr,
        _destRecipAddr, _amount, _fee, _extraData);
    }

    struct Sub {
        uint startTime;      
        uint payPerWeek; 
        uint lastWithdrawTime;
    }

    event LogSubscription(address indexed subscriber, address indexed subscribesTo);
    event LogCancelSubscription(address indexed subscriber, address indexed subscribesTo);

    mapping (address => mapping (address => Sub)) public subs;

    /// @notice subscribe for a weekly recurring payment 
    /// @param _startTime Subscription start time.
    /// @param _payPerWeek weekly payment
    /// @param _recipient address of beneficiary
    /// @return true/false
    function subscribe(uint _startTime, uint _payPerWeek, address _recipient) public returns (bool) {
        require(_startTime >= block.timestamp);
        require(_payPerWeek != 0);
        require(_recipient != 0);

        subs[msg.sender][_recipient] = Sub(_startTime, _payPerWeek, _startTime);  
        
        emit LogSubscription(msg.sender, _recipient);
        return true;
    }

    /// @notice cancel a subcription. 
    /// @param _recipient address of beneficiary
    /// @return true/false
    function cancelSubscription(address _recipient) public returns (bool) {
        require(subs[msg.sender][_recipient].startTime != 0);
        require(subs[msg.sender][_recipient].payPerWeek != 0);

        subs[msg.sender][_recipient].startTime = 0;
        subs[msg.sender][_recipient].payPerWeek = 0;
        subs[msg.sender][_recipient].lastWithdrawTime = 0;

        emit LogCancelSubscription(msg.sender, _recipient);
        return true;
    }

    /// @notice get subcription details
    /// @param _owner 
    /// @param _recipient 
    /// @return startTime, payPerWeek, lastWithdrawTime
    function getSubscription(address _owner, address _recipient) public constant
        returns (uint startTime, uint payPerWeek, uint lastWithdrawTime) 
    {
        Sub storage sub = subs[_owner][_recipient];
        return (
            sub.startTime,
            sub.payPerWeek,
            sub.lastWithdrawTime
        );
    }

    /// @notice caller can withdraw the token from subscribers.
    /// @param _owner subcriber
    /// @return true/false
    function subWithdraw(address _owner) public transferable returns (bool) {
        require(subWithdrawFor(_owner, msg.sender));
        return true;
    }

    /// @notice Allow callers to withdraw token in one go from all of its subscribers
    /// @param _owners array of address of subscribers
    /// @return number of successful transfer done
    function multiSubWithdraw(address[] _owners) public returns (uint) {
        uint n = 0;
        for (uint i=0; i < _owners.length; i++) {
            if (subWithdrawFor(_owners[i], msg.sender)) {
                n++;
            } 
        }
        return n;
    }

    /// @notice Trigger MET token transfers for all pairs of subscribers and beneficiaries
    /// @dev address at i index in owners and recipients array is subcriber-beneficiary pair.
    /// @param _owners 
    /// @param _recipients 
    /// @return number of successful transfer done
    function multiSubWithdrawFor(address[] _owners, address[] _recipients) public returns (uint) {
        // owners and recipients need 1-to-1 mapping, must be same length
        require(_owners.length == _recipients.length);

        uint n = 0;
        for (uint i = 0; i < _owners.length; i++) {
            if (subWithdrawFor(_owners[i], _recipients[i])) {
                n++;
            }
        }

        return n;
    }

    function subWithdrawFor(address _from, address _to) internal returns (bool) {
        Sub storage sub = subs[_from][_to];
        
        if (sub.startTime > 0 && sub.startTime < block.timestamp && sub.payPerWeek > 0) {
            uint weekElapsed = (now.sub(sub.lastWithdrawTime)).div(7 days);
            uint amount = weekElapsed.mul(sub.payPerWeek);
            if (weekElapsed > 0 && _balanceOf[_from] >= amount) {
                subs[_from][_to].lastWithdrawTime = block.timestamp;
                _balanceOf[_from] = _balanceOf[_from].sub(amount);
                _balanceOf[_to] = _balanceOf[_to].add(amount);
                emit Transfer(_from, _to, amount);
                return true;
            }
        }       
        return false;
    }
}


/// @title Autonomous Converter contract for MET <=> ETH exchange
contract AutonomousConverter is Formula, Owned {

    SmartToken public smartToken;
    METToken public reserveToken;
    Auctions public auctions;

    enum WhichToken { Eth, Met }
    bool internal initialized = false;

    event LogFundsIn(address indexed from, uint value);
    event ConvertEthToMet(address indexed from, uint eth, uint met);
    event ConvertMetToEth(address indexed from, uint eth, uint met);

    function init(address _reserveToken, address _smartToken, address _auctions) 
        public onlyOwner payable 
    {
        require(!initialized);
        auctions = Auctions(_auctions);
        reserveToken = METToken(_reserveToken);
        smartToken = SmartToken(_smartToken);
        initialized = true;
    }

    function handleFund() public payable {
        require(msg.sender == address(auctions.proceeds()));
        emit LogFundsIn(msg.sender, msg.value);
    }

    function getMetBalance() public view returns (uint) {
        return balanceOf(WhichToken.Met);
    }

    function getEthBalance() public view returns (uint) {
        return balanceOf(WhichToken.Eth);
    }

    /// @notice return the expected MET for ETH
    /// @param _depositAmount ETH.
    /// @return expected MET value for ETH
    function getMetForEthResult(uint _depositAmount) public view returns (uint256) {
        return convertingReturn(WhichToken.Eth, _depositAmount);
    }

    /// @notice return the expected ETH for MET
    /// @param _depositAmount MET.
    /// @return expected ETH value for MET
    function getEthForMetResult(uint _depositAmount) public view returns (uint256) {
        return convertingReturn(WhichToken.Met, _depositAmount);
    }

    /// @notice send ETH and get MET
    /// @param _mintReturn execute conversion only if return is equal or more than _mintReturn
    /// @return returnedMet MET retured after conversion
    function convertEthToMet(uint _mintReturn) public payable returns (uint returnedMet) {
        returnedMet = convert(WhichToken.Eth, _mintReturn, msg.value);
        emit ConvertEthToMet(msg.sender, msg.value, returnedMet);
    }

    /// @notice send MET and get ETH
    /// @dev Caller will be required to approve the AutonomousConverter to initiate the transfer
    /// @param _amount MET amount
    /// @param _mintReturn execute conversion only if return is equal or more than _mintReturn
    /// @return returnedEth ETh returned after conversion
    function convertMetToEth(uint _amount, uint _mintReturn) public returns (uint returnedEth) {
        returnedEth = convert(WhichToken.Met, _mintReturn, _amount);
        emit ConvertMetToEth(msg.sender, returnedEth, _amount);
    }

    function balanceOf(WhichToken which) internal view returns (uint) {
        if (which == WhichToken.Eth) return address(this).balance;
        if (which == WhichToken.Met) return reserveToken.balanceOf(this);
        revert();
    }

    function convertingReturn(WhichToken whichFrom, uint _depositAmount) internal view returns (uint256) {
        
        WhichToken to = WhichToken.Met;
        if (whichFrom == WhichToken.Met) {
            to = WhichToken.Eth;
        }

        uint reserveTokenBalanceFrom = balanceOf(whichFrom).add(_depositAmount);
        uint mintRet = returnForMint(smartToken.totalSupply(), _depositAmount, reserveTokenBalanceFrom);
        
        uint newSmartTokenSupply = smartToken.totalSupply().add(mintRet);
        uint reserveTokenBalanceTo = balanceOf(to);
        return returnForRedemption(
            newSmartTokenSupply,
            mintRet,
            reserveTokenBalanceTo);
    }

    function convert(WhichToken whichFrom, uint _minReturn, uint amnt) internal returns (uint) {
        WhichToken to = WhichToken.Met;
        if (whichFrom == WhichToken.Met) {
            to = WhichToken.Eth;
            require(reserveToken.transferFrom(msg.sender, this, amnt));
        }

        uint mintRet = mint(whichFrom, amnt, 1);
        
        return redeem(to, mintRet, _minReturn);
    }

    function mint(WhichToken which, uint _depositAmount, uint _minReturn) internal returns (uint256 amount) {
        require(_minReturn > 0);

        amount = mintingReturn(which, _depositAmount);
        require(amount >= _minReturn);
        require(smartToken.mint(msg.sender, amount));
    }

    function mintingReturn(WhichToken which, uint _depositAmount) internal view returns (uint256) {
        uint256 smartTokenSupply = smartToken.totalSupply();
        uint256 reserveBalance = balanceOf(which);
        return returnForMint(smartTokenSupply, _depositAmount, reserveBalance);
    }

    function redeem(WhichToken which, uint _amount, uint _minReturn) internal returns (uint redeemable) {
        require(_amount <= smartToken.balanceOf(msg.sender));
        require(_minReturn > 0);

        redeemable = redemptionReturn(which, _amount);
        require(redeemable >= _minReturn);

        uint256 reserveBalance = balanceOf(which);
        require(reserveBalance >= redeemable);

        uint256 tokenSupply = smartToken.totalSupply();
        require(_amount < tokenSupply);

        smartToken.destroy(msg.sender, _amount);
        if (which == WhichToken.Eth) {
            msg.sender.transfer(redeemable);
        } else {
            require(reserveToken.transfer(msg.sender, redeemable));
        }
    }

    function redemptionReturn(WhichToken which, uint smartTokensSent) internal view returns (uint256) {
        uint smartTokenSupply = smartToken.totalSupply();
        uint reserveTokenBalance = balanceOf(which);
        return returnForRedemption(
            smartTokenSupply,
            smartTokensSent,
            reserveTokenBalance);
    }
}


/// @title Proceeds contract
contract Proceeds is Owned {
    using SafeMath for uint256;

    AutonomousConverter public autonomousConverter;
    Auctions public auctions;
    event LogProceedsIn(address indexed from, uint value); 
    event LogClosedAuction(address indexed from, uint value);
    uint latestAuctionClosed;

    function initProceeds(address _autonomousConverter, address _auctions) public onlyOwner {
        require(address(auctions) == 0x0 && _auctions != 0x0);
        require(address(autonomousConverter) == 0x0 && _autonomousConverter != 0x0);

        autonomousConverter = AutonomousConverter(_autonomousConverter);
        auctions = Auctions(_auctions);
    }

    function handleFund() public payable {
        require(msg.sender == address(auctions));
        emit LogProceedsIn(msg.sender, msg.value);
    }

    /// @notice Forward 0.25% of total ETH balance of proceeds to AutonomousConverter contract
    function closeAuction() public {
        uint lastPurchaseTick = auctions.lastPurchaseTick();
        uint currentAuction = auctions.currentAuction();
        uint val = ((address(this).balance).mul(25)).div(10000); 
        if (val > 0 && (currentAuction > auctions.whichAuction(lastPurchaseTick)) 
            && (latestAuctionClosed < currentAuction)) {
            latestAuctionClosed = currentAuction;
            autonomousConverter.handleFund.value(val)();
            emit LogClosedAuction(msg.sender, val);
        }
    }
}


/// @title Auction contract. Send ETH to the contract address and buy MET. 
contract Auctions is Pricer, Owned {

    using SafeMath for uint256;
    METToken public token;
    Proceeds public proceeds;
    address[] public founders;
    mapping(address => TokenLocker) public tokenLockers;
    uint internal constant DAY_IN_SECONDS = 86400;
    uint internal constant DAY_IN_MINUTES = 1440;
    uint public genesisTime;
    uint public lastPurchaseTick;
    uint public lastPurchasePrice;
    uint public constant INITIAL_GLOBAL_DAILY_SUPPLY = 2880 * METDECMULT;
    uint public INITIAL_FOUNDER_SUPPLY = 1999999 * METDECMULT;
    uint public INITIAL_AC_SUPPLY = 1 * METDECMULT;
    uint public totalMigratedOut = 0;
    uint public totalMigratedIn = 0;
    uint public timeScale = 1;
    uint public constant INITIAL_SUPPLY = 10000000 * METDECMULT;
    uint public mintable = INITIAL_SUPPLY;
    uint public initialAuctionDuration = 7 days;
    uint public initialAuctionEndTime;
    uint public dailyAuctionStartTime;
    uint public constant DAILY_PURCHASE_LIMIT = 1000 ether;
    mapping (address => uint) internal purchaseInTheAuction;
    mapping (address => uint) internal lastPurchaseAuction;
    bool public minted;
    bool public initialized;
    uint public globalSupplyAfterPercentageLogic = 52598080 * METDECMULT;
    uint public constant AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS = 14791;
    bytes8 public chain = "ETH";
    event LogAuctionFundsIn(address indexed sender, uint amount, uint tokens, uint purchasePrice, uint refund);

    function Auctions() public {
        mintable = INITIAL_SUPPLY - 2000000 * METDECMULT;
    }

    /// @notice Payable function to buy MET in descending price auction
    function () public payable running {
        require(msg.value > 0);
        
        uint amountForPurchase = msg.value;
        uint excessAmount;

        if (currentAuction() > whichAuction(lastPurchaseTick)) {
            proceeds.closeAuction();
            restartAuction();
        }

        if (isInitialAuctionEnded()) {
            require(now >= dailyAuctionStartTime);
            if (lastPurchaseAuction[msg.sender] < currentAuction()) {
                if (amountForPurchase > DAILY_PURCHASE_LIMIT) {
                    excessAmount = amountForPurchase.sub(DAILY_PURCHASE_LIMIT);
                    amountForPurchase = DAILY_PURCHASE_LIMIT;
                }           
                purchaseInTheAuction[msg.sender] = msg.value;
                lastPurchaseAuction[msg.sender] = currentAuction();
            } else {
                require(purchaseInTheAuction[msg.sender] < DAILY_PURCHASE_LIMIT);
                if (purchaseInTheAuction[msg.sender].add(amountForPurchase) > DAILY_PURCHASE_LIMIT) {
                    excessAmount = (purchaseInTheAuction[msg.sender].add(amountForPurchase)).sub(DAILY_PURCHASE_LIMIT);
                    amountForPurchase = amountForPurchase.sub(excessAmount);
                }
                purchaseInTheAuction[msg.sender] = purchaseInTheAuction[msg.sender].add(msg.value);
            }
        }

        uint _currentTick = currentTick();

        uint weiPerToken;
        uint tokens;
        uint refund;
        (weiPerToken, tokens, refund) = calcPurchase(amountForPurchase, _currentTick);
        require(tokens > 0);

        if (now < initialAuctionEndTime && (token.totalSupply()).add(tokens) >= INITIAL_SUPPLY) {
            initialAuctionEndTime = now;
            dailyAuctionStartTime = ((initialAuctionEndTime / 1 days) + 1) * 1 days;
        }

        lastPurchaseTick = _currentTick;
        lastPurchasePrice = weiPerToken;

        assert(tokens <= mintable);
        mintable = mintable.sub(tokens);

        assert(refund <= amountForPurchase);
        uint ethForProceeds = amountForPurchase.sub(refund);

        proceeds.handleFund.value(ethForProceeds)();

        require(token.mint(msg.sender, tokens));

        refund = refund.add(excessAmount);
        if (refund > 0) {
            if (purchaseInTheAuction[msg.sender] > 0) {
                purchaseInTheAuction[msg.sender] = purchaseInTheAuction[msg.sender].sub(refund);
            }
            msg.sender.transfer(refund);
        }
        emit LogAuctionFundsIn(msg.sender, ethForProceeds, tokens, lastPurchasePrice, refund);
    }

    modifier running() {
        require(isRunning());
        _;
    }

    function isRunning() public constant returns (bool) {
        return (block.timestamp >= genesisTime && genesisTime > 0);
    }

    /// @notice current tick(minute) of the metronome clock
    /// @return tick count
    function currentTick() public view returns(uint) {
        return whichTick(block.timestamp);
    }

    /// @notice current auction
    /// @return auction count 
    function currentAuction() public view returns(uint) {
        return whichAuction(currentTick());
    }

    /// @notice tick count at the timestamp t. 
    /// @param t timestamp
    /// @return tick count
    function whichTick(uint t) public view returns(uint) {
        if (genesisTime > t) { 
            revert(); 
        }
        return (t - genesisTime) * timeScale / 1 minutes;
    }

    /// @notice Auction count at given the timestamp t
    /// @param t timestamp
    /// @return Auction count
    function whichAuction(uint t) public view returns(uint) {
        if (whichTick(dailyAuctionStartTime) > t) {
            return 0;
        } else {
            return ((t - whichTick(dailyAuctionStartTime)) / DAY_IN_MINUTES) + 1;
        }
    }

    /// @notice one single function telling everything about Metronome Auction
    function heartbeat() public view returns (
        bytes8 _chain,
        address auctionAddr,
        address convertAddr,
        address tokenAddr,
        uint minting,
        uint totalMET,
        uint proceedsBal,
        uint currTick,
        uint currAuction,
        uint nextAuctionGMT,
        uint genesisGMT,
        uint currentAuctionPrice,
        uint _dailyMintable,
        uint _lastPurchasePrice) {
        _chain = chain;
        convertAddr = proceeds.autonomousConverter();
        tokenAddr = token;
        auctionAddr = this;
        totalMET = token.totalSupply();
        proceedsBal = address(proceeds).balance;

        currTick = currentTick();
        currAuction = currentAuction();
        if (currAuction == 0) {
            nextAuctionGMT = dailyAuctionStartTime;
        } else {
            nextAuctionGMT = (currAuction * DAY_IN_SECONDS) / timeScale + dailyAuctionStartTime;
        }
        genesisGMT = genesisTime;

        currentAuctionPrice = currentPrice();
        _dailyMintable = dailyMintable();
        minting = currentMintable();
        _lastPurchasePrice = lastPurchasePrice;
    }

    /// @notice Skip Initialization and minting if we&#39;re not the OG Metronome
    /// @param _token MET token contract address
    /// @param _proceeds Address of Proceeds contract
    /// @param _genesisTime The block.timestamp when first auction started on OG chain
    /// @param _minimumPrice Nobody can buy tokens for less than this price
    /// @param _startingPrice Start price of MET when first auction starts
    /// @param _timeScale time scale factor for auction. will be always 1 in live environment
    /// @param _chain chain where this contract is being deployed
    /// @param _initialAuctionEndTime  Initial Auction end time in ETH chain. 
    function skipInitBecauseIAmNotOg(address _token, address _proceeds, uint _genesisTime, 
        uint _minimumPrice, uint _startingPrice, uint _timeScale, bytes8 _chain, 
        uint _initialAuctionEndTime) public onlyOwner returns (bool) {
        require(!minted);
        require(!initialized);
        require(_timeScale != 0);
        require(address(token) == 0x0 && _token != 0x0);
        require(address(proceeds) == 0x0 && _proceeds != 0x0);
        initPricer();

        // minting substitute section
        token = METToken(_token);
        proceeds = Proceeds(_proceeds);

        INITIAL_FOUNDER_SUPPLY = 0;
        INITIAL_AC_SUPPLY = 0;
        mintable = 0;  // 

        // initial auction substitute section
        genesisTime = _genesisTime;
        initialAuctionEndTime = _initialAuctionEndTime;

        // if initialAuctionEndTime is midnight, then daily auction will start immediately
        // after initial auction.
        if (initialAuctionEndTime == (initialAuctionEndTime / 1 days) * 1 days) {
            dailyAuctionStartTime = initialAuctionEndTime;
        } else {
            dailyAuctionStartTime = ((initialAuctionEndTime / 1 days) + 1) * 1 days;
        }

        lastPurchaseTick = 0;

        if (_minimumPrice > 0) {
            minimumPrice = _minimumPrice;
        }

        timeScale = _timeScale;

        if (_startingPrice > 0) {
            lastPurchasePrice = _startingPrice * 1 ether;
        } else {
            lastPurchasePrice = 2 ether;
        }
        chain = _chain;
        minted = true;
        initialized = true;
        return true;
    }

    /// @notice Initialize Auctions parameters
    /// @param _startTime The block.timestamp when first auction starts
    /// @param _minimumPrice Nobody can buy tokens for less than this price
    /// @param _startingPrice Start price of MET when first auction starts
    /// @param _timeScale time scale factor for auction. will be always 1 in live environment
    function initAuctions(uint _startTime, uint _minimumPrice, uint _startingPrice, uint _timeScale) 
        public onlyOwner returns (bool) 
    {
        require(minted);
        require(!initialized);
        require(_timeScale != 0);
        initPricer();
        if (_startTime > 0) { 
            genesisTime = (_startTime / (1 minutes)) * (1 minutes) + 60;
        } else {
            genesisTime = block.timestamp + 60 - (block.timestamp % 60);
        }

        initialAuctionEndTime = genesisTime + initialAuctionDuration;

        // if initialAuctionEndTime is midnight, then daily auction will start immediately
        // after initial auction.
        if (initialAuctionEndTime == (initialAuctionEndTime / 1 days) * 1 days) {
            dailyAuctionStartTime = initialAuctionEndTime;
        } else {
            dailyAuctionStartTime = ((initialAuctionEndTime / 1 days) + 1) * 1 days;
        }

        lastPurchaseTick = 0;

        if (_minimumPrice > 0) {
            minimumPrice = _minimumPrice;
        }

        timeScale = _timeScale;

        if (_startingPrice > 0) {
            lastPurchasePrice = _startingPrice * 1 ether;
        } else {
            lastPurchasePrice = 2 ether;
        }

        for (uint i = 0; i < founders.length; i++) {
            TokenLocker tokenLocker = tokenLockers[founders[i]];
            tokenLocker.lockTokenLocker();
        }
        
        initialized = true;
        return true;
    }

    function createTokenLocker(address _founder, address _token) public onlyOwner {
        require(_token != 0x0);
        require(_founder != 0x0);
        founders.push(_founder);
        TokenLocker tokenLocker = new TokenLocker(address(this), _token);
        tokenLockers[_founder] = tokenLocker;
        tokenLocker.changeOwnership(_founder);
    }

    /// @notice Mint initial supply for founder and move to token locker
    /// @param _founders Left 160 bits are the founder address and the right 96 bits are the token amount.
    /// @param _token MET token contract address
    /// @param _proceeds Address of Proceeds contract
    function mintInitialSupply(uint[] _founders, address _token, 
        address _proceeds, address _autonomousConverter) public onlyOwner returns (bool) 
    {
        require(!minted);
        require(_founders.length != 0);
        require(address(token) == 0x0 && _token != 0x0);
        require(address(proceeds) == 0x0 && _proceeds != 0x0);
        require(_autonomousConverter != 0x0);

        token = METToken(_token);
        proceeds = Proceeds(_proceeds);

        // _founders will be minted into individual token lockers
        uint foundersTotal;
        for (uint i = 0; i < _founders.length; i++) {
            address addr = address(_founders[i] >> 96);
            require(addr != 0x0);
            uint amount = _founders[i] & ((1 << 96) - 1);
            require(amount > 0);
            TokenLocker tokenLocker = tokenLockers[addr];
            require(token.mint(address(tokenLocker), amount));
            tokenLocker.deposit(addr, amount);
            foundersTotal = foundersTotal.add(amount);
        }

        // reconcile minted total for founders
        require(foundersTotal == INITIAL_FOUNDER_SUPPLY);

        // mint a small amount to the AC
        require(token.mint(_autonomousConverter, INITIAL_AC_SUPPLY));

        minted = true;
        return true;
    }

    /// @notice Suspend auction if not started yet
    function stopEverything() public onlyOwner {
        if (genesisTime < block.timestamp) {
            revert(); 
        }
        genesisTime = genesisTime + 1000 years;
        initialAuctionEndTime = genesisTime;
        dailyAuctionStartTime = genesisTime;
    }

    /// @notice Return information about initial auction status.
    function isInitialAuctionEnded() public view returns (bool) {
        return (initialAuctionEndTime != 0 && 
            (now >= initialAuctionEndTime || token.totalSupply() >= INITIAL_SUPPLY));
    }

    /// @notice Global MET supply
    function globalMetSupply() public view returns (uint) {

        uint currAuc = currentAuction();
        if (currAuc > AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS) {
            return globalSupplyAfterPercentageLogic;
        } else {
            return INITIAL_SUPPLY.add(INITIAL_GLOBAL_DAILY_SUPPLY.mul(currAuc));
        }
    }

    /// @notice Global MET daily supply. Daily supply is greater of 1) 2880 2)2% of then outstanding supply per year.
    /// @dev 2% logic will kicks in at 14792th auction. 
    function globalDailySupply() public view returns (uint) {
        uint dailySupply = INITIAL_GLOBAL_DAILY_SUPPLY;
        uint thisAuction = currentAuction();

        if (thisAuction > AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS) {
            uint lastAuctionPurchase = whichAuction(lastPurchaseTick);
            uint recentAuction = AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS + 1;
            if (lastAuctionPurchase > recentAuction) {
                recentAuction = lastAuctionPurchase;
            }

            uint totalAuctions = thisAuction - recentAuction;
            if (totalAuctions > 1) {
                // derived formula to find close to accurate daily supply when some auction missed. 
                uint factor = 36525 + ((totalAuctions - 1) * 2);
                dailySupply = (globalSupplyAfterPercentageLogic.mul(2).mul(factor)).div(36525 ** 2);

            } else {
                dailySupply = globalSupplyAfterPercentageLogic.mul(2).div(36525);
            }

            if (dailySupply < INITIAL_GLOBAL_DAILY_SUPPLY) {
                dailySupply = INITIAL_GLOBAL_DAILY_SUPPLY; 
            }
        }

        return dailySupply;
    }

    /// @notice Current price of MET in current auction
    /// @return weiPerToken 
    function currentPrice() public constant returns (uint weiPerToken) {
        weiPerToken = calcPriceAt(currentTick());
    }

    /// @notice Daily mintable MET in current auction
    function dailyMintable() public constant returns (uint) {
        return nextAuctionSupply(0);
    }

    /// @notice Total tokens on this chain
    function tokensOnThisChain() public view returns (uint) {
        uint totalSupply = token.totalSupply();
        uint currMintable = currentMintable();
        return totalSupply.add(currMintable);
    }

    /// @notice Current mintable MET in auction
    function currentMintable() public view returns (uint) {
        uint currMintable = mintable;
        uint currAuction = currentAuction();
        uint totalAuctions = currAuction.sub(whichAuction(lastPurchaseTick));
        if (totalAuctions > 0) {
            currMintable = mintable.add(nextAuctionSupply(totalAuctions));
        }
        return currMintable;
    }

    /// @notice prepare auction when first import is done on a non ETH chain
    function prepareAuctionForNonOGChain() public {
        require(msg.sender == address(token.tokenPorter()) || msg.sender == address(token));
        require(token.totalSupply() == 0);
        require(chain != "ETH");
        lastPurchaseTick = currentTick();
    }

    /// @notice Find out what the results would be of a prospective purchase
    /// @param _wei Amount of wei the purchaser will pay
    /// @param _timestamp Prospective purchase timestamp
    /// @return weiPerToken expected MET token rate
    /// @return tokens Expected token for a prospective purchase
    /// @return refund Wei refund the purchaser will get if amount is excess and MET supply is less
    function whatWouldPurchaseDo(uint _wei, uint _timestamp) public constant
        returns (uint weiPerToken, uint tokens, uint refund)
    {
        weiPerToken = calcPriceAt(whichTick(_timestamp));
        uint calctokens = METDECMULT.mul(_wei).div(weiPerToken);
        tokens = calctokens;
        if (calctokens > mintable) {
            tokens = mintable;
            uint weiPaying = mintable.mul(weiPerToken).div(METDECMULT);
            refund = _wei.sub(weiPaying);
        }
    }
    
    /// @notice Return the information about the next auction
    /// @return _startTime Start time of next auction
    /// @return _startPrice Start price of MET in next auction
    /// @return _auctionTokens  MET supply in next auction
    function nextAuction() internal constant returns(uint _startTime, uint _startPrice, uint _auctionTokens) {
        if (block.timestamp < genesisTime) {
            _startTime = genesisTime;
            _startPrice = lastPurchasePrice;
            _auctionTokens = mintable;
            return;
        }

        uint recentAuction = whichAuction(lastPurchaseTick);
        uint currAuc = currentAuction();
        uint totalAuctions = currAuc - recentAuction;
        _startTime = dailyAuctionStartTime;
        if (currAuc > 1) {
            _startTime = auctionStartTime(currentTick());
        }

        _auctionTokens = nextAuctionSupply(totalAuctions);

        if (totalAuctions > 1) {
            _startPrice = lastPurchasePrice / 100 + 1;
        } else {
            if (mintable == 0 || totalAuctions == 0) {
                // Sold out scenario or someone querying projected start price of next auction
                _startPrice = (lastPurchasePrice * 2) + 1;   
            } else {
                // Timed out and all tokens not sold.
                if (currAuc == 1) {
                    // If initial auction timed out then price before start of new auction will touch floor price
                    _startPrice = minimumPrice * 2;
                } else {
                    // Descending price till end of auction and then multiply by 2
                    uint tickWhenAuctionEnded = whichTick(_startTime);
                    uint numTick = 0;
                    if (tickWhenAuctionEnded > lastPurchaseTick) {
                        numTick = tickWhenAuctionEnded - lastPurchaseTick;
                    }
                    _startPrice = priceAt(lastPurchasePrice, numTick) * 2;
                }
                
                
            }
        }
    }

    /// @notice Calculate results of a purchase
    /// @param _wei Amount of wei the purchaser will pay
    /// @param _t Prospective purchase tick
    /// @return weiPerToken expected MET token rate
    /// @return tokens Expected token for a prospective purchase
    /// @return refund Wei refund the purchaser will get if amount is excess and MET supply is less
    function calcPurchase(uint _wei, uint _t) internal view returns (uint weiPerToken, uint tokens, uint refund)
    {
        require(_t >= lastPurchaseTick);
        uint numTicks = _t - lastPurchaseTick;
        if (isInitialAuctionEnded()) {
            weiPerToken = priceAt(lastPurchasePrice, numTicks);
        } else {
            weiPerToken = priceAtInitialAuction(lastPurchasePrice, numTicks);
        }

        uint calctokens = METDECMULT.mul(_wei).div(weiPerToken);
        tokens = calctokens;
        if (calctokens > mintable) {
            tokens = mintable;
            uint ethPaying = mintable.mul(weiPerToken).div(METDECMULT);
            refund = _wei.sub(ethPaying);
        }
    }

    /// @notice MET supply for next Auction also considering  carry forward met.
    /// @param totalAuctionMissed auction count when no purchase done.
    function nextAuctionSupply(uint totalAuctionMissed) internal view returns (uint supply) {
        uint thisAuction = currentAuction();
        uint tokensHere = token.totalSupply().add(mintable);
        supply = INITIAL_GLOBAL_DAILY_SUPPLY;
        uint dailySupplyAtLastPurchase;
        if (thisAuction > AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS) {
            supply = globalDailySupply();
            if (totalAuctionMissed > 1) {
                dailySupplyAtLastPurchase = globalSupplyAfterPercentageLogic.mul(2).div(36525);
                supply = dailySupplyAtLastPurchase.add(supply).mul(totalAuctionMissed).div(2);
            } 
            supply = (supply.mul(tokensHere)).div(globalSupplyAfterPercentageLogic);
        } else {
            if (totalAuctionMissed > 1) {
                supply = supply.mul(totalAuctionMissed);
            }
            uint previousGlobalMetSupply = 
            INITIAL_SUPPLY.add(INITIAL_GLOBAL_DAILY_SUPPLY.mul(whichAuction(lastPurchaseTick)));
            supply = (supply.mul(tokensHere)).div(previousGlobalMetSupply);
        
        }
    }

    /// @notice price at a number of minutes out in Initial auction and daily auction
    /// @param _tick Metronome tick
    /// @return weiPerToken
    function calcPriceAt(uint _tick) internal constant returns (uint weiPerToken) {
        uint recentAuction = whichAuction(lastPurchaseTick);
        uint totalAuctions = whichAuction(_tick).sub(recentAuction);
        uint prevPrice;

        uint numTicks = 0;

        // Auction is sold out and metronome clock is in same auction
        if (mintable == 0 && totalAuctions == 0) {
            return lastPurchasePrice;
        }

        // Metronome has missed one auction ie no purchase in last auction
        if (totalAuctions > 1) {
            prevPrice = lastPurchasePrice / 100 + 1;
            numTicks = numTicksSinceAuctionStart(_tick);
        } else if (totalAuctions == 1) {
            // Metronome clock is in new auction, next auction
            // previous auction sold out
            if (mintable == 0) {
                prevPrice = lastPurchasePrice * 2;
            } else {
                // previous auctions timed out
                // first daily auction
                if (whichAuction(_tick) == 1) {
                    prevPrice = minimumPrice * 2;
                } else {
                    prevPrice = priceAt(lastPurchasePrice, numTicksTillAuctionStart(_tick)) * 2;
                }
            }
            numTicks = numTicksSinceAuctionStart(_tick);
        } else {
            //Auction is running
            prevPrice = lastPurchasePrice;
            numTicks = _tick - lastPurchaseTick;
        }

        require(numTicks >= 0);

        if (isInitialAuctionEnded()) {
            weiPerToken = priceAt(prevPrice, numTicks);
        } else {
            weiPerToken = priceAtInitialAuction(prevPrice, numTicks);
        }
    }

    /// @notice Calculate number of ticks elapsed between auction start time and given tick.
    /// @param _tick Given metronome tick
    function numTicksSinceAuctionStart(uint _tick) private view returns (uint ) {
        uint currentAuctionStartTime = auctionStartTime(_tick);
        return _tick - whichTick(currentAuctionStartTime);
    }
    
    /// @notice Calculate number of ticks elapsed between lastPurchaseTick and auctions start time of given tick.
    /// @param _tick Given metronome tick
    function numTicksTillAuctionStart(uint _tick) private view returns (uint) {
        uint currentAuctionStartTime = auctionStartTime(_tick);
        return whichTick(currentAuctionStartTime) - lastPurchaseTick;
    }

    /// @notice First calculate the auction which contains the given tick and then calculate
    /// auction start time of given tick.
    /// @param _tick Metronome tick
    function auctionStartTime(uint _tick) private view returns (uint) {
        return ((whichAuction(_tick)) * 1 days) / timeScale + dailyAuctionStartTime - 1 days;
    }

    /// @notice start the next day&#39;s auction
    function restartAuction() private {
        uint time;
        uint price;
        uint auctionTokens;
        (time, price, auctionTokens) = nextAuction();

        uint thisAuction = currentAuction();
        if (thisAuction > AUCTION_WHEN_PERCENTAGE_LOGIC_STARTS) {
            globalSupplyAfterPercentageLogic = globalSupplyAfterPercentageLogic.add(globalDailySupply());
        }

        mintable = mintable.add(auctionTokens);
        lastPurchasePrice = price;
        lastPurchaseTick = whichTick(time);
    }
}


/// @title This contract serves as a locker for a founder&#39;s tokens
contract TokenLocker is Ownable {
    using SafeMath for uint;
    uint internal constant QUARTER = 91 days + 450 minutes;
  
    Auctions public auctions;
    METToken public token;
    bool public locked = false;
  
    uint public deposited;
    uint public lastWithdrawTime;
    uint public quarterlyWithdrawable;
    
    event Withdrawn(address indexed who, uint amount);
    event Deposited(address indexed who, uint amount);

    modifier onlyAuction() {
        require(msg.sender == address(auctions));
        _;
    }

    modifier preLock() { 
        require(!locked);
        _; 
    }

    modifier postLock() { 
        require(locked); 
        _; 
    }

    /// @notice Constructor to initialize TokenLocker contract.
    /// @param _auctions Address of auctions contract
    /// @param _token Address of METToken contract
    function TokenLocker(address _auctions, address _token) public {
        require(_auctions != 0x0);
        require(_token != 0x0);
        auctions = Auctions(_auctions);
        token = METToken(_token);
    }

    /// @notice If auctions is initialized, call to this function will result in
    /// locking of deposited tokens and further deposit of tokens will not be allowed.
    function lockTokenLocker() public onlyAuction {
        require(auctions.initialAuctionEndTime() != 0);
        require(auctions.initialAuctionEndTime() >= auctions.genesisTime()); 
        locked = true;
    }

    /// @notice It will deposit tokens into the locker for given beneficiary.
    /// @param beneficiary Address of the beneficiary, whose tokens are being locked.
    /// @param amount Amount of tokens being locked
    function deposit (address beneficiary, uint amount ) public onlyAuction preLock {
        uint totalBalance = token.balanceOf(this);
        require(totalBalance.sub(deposited) >= amount);
        deposited = deposited.add(amount);
        emit Deposited(beneficiary, amount);
    }

    /// @notice This function will allow token withdraw from locker.
    /// 25% of total deposited tokens can be withdrawn after initial auction end.
    /// Remaining 75% can be withdrawn in equal amount over 12 quarters.
    function withdraw() public onlyOwner postLock {
        require(deposited > 0);
        uint withdrawable = 0; 
        uint withdrawTime = auctions.initialAuctionEndTime();
        if (lastWithdrawTime == 0 && auctions.isInitialAuctionEnded()) {
            withdrawable = withdrawable.add((deposited.mul(25)).div(100));
            quarterlyWithdrawable = (deposited.sub(withdrawable)).div(12);
            lastWithdrawTime = withdrawTime;
        }

        require(lastWithdrawTime != 0);

        if (now >= lastWithdrawTime.add(QUARTER)) {
            uint daysSinceLastWithdraw = now.sub(lastWithdrawTime);
            uint totalQuarters = daysSinceLastWithdraw.div(QUARTER);

            require(totalQuarters > 0);
        
            withdrawable = withdrawable.add(quarterlyWithdrawable.mul(totalQuarters));

            if (now >= withdrawTime.add(QUARTER.mul(12))) {
                withdrawable = deposited;
            }

            lastWithdrawTime = lastWithdrawTime.add(totalQuarters.mul(QUARTER));
        }

        if (withdrawable > 0) {
            deposited = deposited.sub(withdrawable);
            token.transfer(msg.sender, withdrawable);
            emit Withdrawn(msg.sender, withdrawable);
        }
    }
}


/// @title Interface for TokenPorter contract.
/// Define events and functions for TokenPorter contract
interface ITokenPorter {
    event ExportOnChainClaimedReceiptLog(address indexed destinationMetronomeAddr, 
        address indexed destinationRecipientAddr, uint amount);

    event ExportReceiptLog(bytes8 destinationChain, address destinationMetronomeAddr,
        address indexed destinationRecipientAddr, uint amountToBurn, uint fee, bytes extraData, uint currentTick,
        uint indexed burnSequence, bytes32 indexed currentBurnHash, bytes32 prevBurnHash, uint dailyMintable,
        uint[] supplyOnAllChains, uint genesisTime, uint blockTimestamp, uint dailyAuctionStartTime);

    event ImportReceiptLog(address indexed destinationRecipientAddr, uint amountImported, 
        uint fee, bytes extraData, uint currentTick, uint indexed importSequence, 
        bytes32 indexed currentHash, bytes32 prevHash, uint dailyMintable, uint blockTimestamp, address caller);

    function export(address tokenOwner, bytes8 _destChain, address _destMetronomeAddr, 
        address _destRecipAddr, uint _amount, uint _fee, bytes _extraData) public returns (bool);
    
    function importMET(bytes8 _originChain, bytes8 _destinationChain, address[] _addresses, bytes _extraData, 
        bytes32[] _burnHashes, uint[] _supplyOnAllChains, uint[] _importData, bytes _proof) public returns (bool);

}


/// @title This contract will provide export functionality for tokens.
contract TokenPorter is ITokenPorter, Owned {
    using SafeMath for uint;
    Auctions public auctions;
    METToken public token;
    Validator public validator;
    ChainLedger public chainLedger;

    uint public burnSequence = 1;
    uint public importSequence = 1;
    bytes32[] public exportedBurns;
    uint[] public supplyOnAllChains = new uint[](6);

    /// @notice mapping that tracks valid destination chains for export
    mapping(bytes8 => address) public destinationChains;

    /// @notice Initialize TokenPorter contract.
    /// @param _tokenAddr Address of metToken contract
    /// @param _auctionsAddr Address of auctions contract
    function initTokenPorter(address _tokenAddr, address _auctionsAddr) public onlyOwner {
        require(_tokenAddr != 0x0);
        require(_auctionsAddr != 0x0);
        auctions = Auctions(_auctionsAddr);
        token = METToken(_tokenAddr);
    }

    /// @notice set address of validator contract
    /// @param _validator address of validator contract
    function setValidator(address _validator) public onlyOwner returns (bool) {
        require(_validator != 0x0);
        validator = Validator(_validator);
        return true;
    }

    /// @notice set address of chainLedger contract
    /// @param _chainLedger address of chainLedger contract
    function setChainLedger(address _chainLedger) public onlyOwner returns (bool) {
        require(_chainLedger != 0x0);
        chainLedger = ChainLedger(_chainLedger);
        return true;
    }

    /// @notice only owner can add destination chains
    /// @param _chainName string of destination blockchain name
    /// @param _contractAddress address of destination MET token to import to
    function addDestinationChain(bytes8 _chainName, address _contractAddress) 
        public onlyOwner returns (bool) 
    {
        require(_chainName != 0 && _contractAddress != address(0));
        destinationChains[_chainName] = _contractAddress;
        return true;
    }

    /// @notice only owner can remove destination chains
    /// @param _chainName string of destination blockchain name
    function removeDestinationChain(bytes8 _chainName) public onlyOwner returns (bool) {
        require(_chainName != 0);
        require(destinationChains[_chainName] != address(0));
        destinationChains[_chainName] = address(0);
        return true;   
    }

    /// @notice holds claims from users that have exported on-chain
    /// @param key is address of destination MET token contract
    /// @param subKey is address of users account that burned their original MET token
    mapping (address  => mapping(address => uint)) public claimables;

    /// @notice destination MET token contract calls claimReceivables to record burned 
    /// tokens have been minted in new chain
    /// @param recipients array of addresses of each user that has exported from
    /// original chain.  These can be generated by ExportReceiptLog
    function claimReceivables(address[] recipients) public returns (uint) {
        require(recipients.length > 0);

        uint total;
        for (uint i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint amountBurned = claimables[msg.sender][recipient];
            if (amountBurned > 0) {
                claimables[msg.sender][recipient] = 0;
                emit ExportOnChainClaimedReceiptLog(msg.sender, recipient, amountBurned);
                total = total.add(1);
            }
        }
        return total;
    }

    /// @notice import MET tokens from another chain to this chain.
    /// @param _destinationChain destination chain name
    /// @param _addresses _addresses[0] is destMetronomeAddr and _addresses[1] is recipientAddr
    /// @param _extraData extra information for import
    /// @param _burnHashes _burnHashes[0] is previous burnHash, _burnHashes[1] is current burnHash
    /// @param _supplyOnAllChains MET supply on all supported chains
    /// @param _importData _importData[0] is _blockTimestamp, _importData[1] is _amount, _importData[2] is _fee
    /// _importData[3] is _burnedAtTick, _importData[4] is _genesisTime, _importData[5] is _dailyMintable
    /// _importData[6] is _burnSequence, _importData[7] is _dailyAuctionStartTime
    /// @param _proof proof
    /// @return true/false
    function importMET(bytes8 _originChain, bytes8 _destinationChain, address[] _addresses, bytes _extraData, 
        bytes32[] _burnHashes, uint[] _supplyOnAllChains, uint[] _importData, bytes _proof) public returns (bool)
    {
        
        require(msg.sender == address(token));
        require(_importData.length == 8);
        require(_addresses.length == 2);
        require(_burnHashes.length == 2);
        require(validator.isReceiptClaimable(_originChain, _destinationChain, _addresses, _extraData, _burnHashes, 
        _supplyOnAllChains, _importData, _proof));

        validator.claimHash(_burnHashes[1]);

        require(_destinationChain == auctions.chain());
        uint amountToImport = _importData[1].add(_importData[2]);
        require(amountToImport.add(token.totalSupply()) <= auctions.globalMetSupply());

        require(_addresses[0] == address(token));

        if (_importData[1] == 0) {
            return false;
        }

        if (importSequence == 1 && token.totalSupply() == 0) {
            auctions.prepareAuctionForNonOGChain();
        }
        
        token.mint(_addresses[1], _importData[1]);
        emit ImportReceiptLog(_addresses[1], _importData[1], _importData[2], _extraData,
        auctions.currentTick(), importSequence, _burnHashes[1],
        _burnHashes[0], auctions.dailyMintable(), now, msg.sender);
        importSequence++;
        chainLedger.registerImport(_originChain, _destinationChain, _importData[1]);
        return true;
    }

    /// @notice Export MET tokens from this chain to another chain.
    /// @param tokenOwner Owner of the token, whose tokens are being exported.
    /// @param _destChain Destination chain for exported tokens
    /// @param _destMetronomeAddr Metronome address on destination chain
    /// @param _destRecipAddr Recipient address on the destination chain
    /// @param _amount Amount of token being exported
    /// @param _extraData Extra data for this export
    /// @return boolean true/false based on the outcome of export
    function export(address tokenOwner, bytes8 _destChain, address _destMetronomeAddr,
        address _destRecipAddr, uint _amount, uint _fee, bytes _extraData) public returns (bool) 
    {
        require(msg.sender == address(token));

        require(_destChain != 0x0 && _destMetronomeAddr != 0x0 && _destRecipAddr != 0x0 && _amount != 0);
        require(destinationChains[_destChain] == _destMetronomeAddr);
        
        require(token.balanceOf(tokenOwner) >= _amount.add(_fee));

        token.destroy(tokenOwner, _amount.add(_fee));

        uint dailyMintable = auctions.dailyMintable();
        uint currentTick = auctions.currentTick();
       
       
        if (burnSequence == 1) {
            exportedBurns.push(keccak256(uint8(0)));
        }

        if (_destChain == auctions.chain()) {
            claimables[_destMetronomeAddr][_destRecipAddr] = 
                claimables[_destMetronomeAddr][_destRecipAddr].add(_amount);
        }
        uint blockTime = block.timestamp;
        bytes32 currentBurn = keccak256(
            blockTime, 
            auctions.chain(),
            _destChain, 
            _destMetronomeAddr, 
            _destRecipAddr, 
            _amount,
            currentTick,
            auctions.genesisTime(),
            dailyMintable,
            token.totalSupply(),
            _extraData,
            exportedBurns[burnSequence - 1]);
       
        exportedBurns.push(currentBurn);

        supplyOnAllChains[0] = token.totalSupply();
        
        emit ExportReceiptLog(_destChain, _destMetronomeAddr, _destRecipAddr, _amount, _fee, _extraData, 
            currentTick, burnSequence, currentBurn, exportedBurns[burnSequence - 1], dailyMintable,
            supplyOnAllChains, auctions.genesisTime(), blockTime, auctions.dailyAuctionStartTime());

        burnSequence = burnSequence + 1;
        chainLedger.registerExport(auctions.chain(), _destChain, _amount);
        return true;
    }
}    


contract ChainLedger is Owned {

    using SafeMath for uint;
    mapping (bytes8 => uint) public balance;
    mapping (bytes8 => bool) public validChain;
    bytes8[] public chains;

    address public tokenPorter;
    Auctions public auctions;

    event LogRegisterChain(address indexed caller, bytes8 indexed chain, uint supply, bool outcome);
    event LogRegisterExport(address indexed caller, bytes8 indexed originChain, bytes8 indexed destChain, uint amount);
    event LogRegisterImport(address indexed caller, bytes8 indexed originChain, bytes8 indexed destChain, uint amount);

    function initChainLedger(address _tokenPorter, address _auctionsAddr) public onlyOwner returns (bool) {
        require(_tokenPorter != 0x0);
        require(_auctionsAddr != 0x0);
        
        tokenPorter = _tokenPorter;
        auctions = Auctions(_auctionsAddr);
        
        return true;
    }

    function registerChain(bytes8 chain, uint supply) public onlyOwner returns (bool) {
        require(!validChain[chain]); 
        validChain[chain] = true;
        chains.push(chain);
        balance[chain] = supply;
        emit LogRegisterChain(msg.sender, chain, supply, true);
    }

    function registerExport(bytes8 originChain, bytes8 destChain, uint amount) public {
        require(msg.sender == tokenPorter || msg.sender == owner);
        require(validChain[originChain] && validChain[destChain]);
        require(balance[originChain] >= amount);

        balance[originChain] = balance[originChain].sub(amount);
        balance[destChain] = balance[destChain].add(amount);
        emit LogRegisterExport(msg.sender, originChain, destChain, amount);
    }

    function registerImport(bytes8 originChain, bytes8 destChain, uint amount) public {
        require(msg.sender == tokenPorter || msg.sender == owner);
        require(validChain[originChain] && validChain[destChain]);

        balance[originChain] = balance[originChain].sub(amount);
        balance[destChain] = balance[destChain].add(amount);
        emit LogRegisterImport(msg.sender, originChain, destChain, amount);
    }  
}


contract Validator is Owned {

    mapping (bytes32 => mapping (address => bool)) public hashAttestations;
    mapping (address => bool) public isValidator;
    mapping (address => uint8) public validatorNum;
    address[] public validators;
    address public metToken;
    address public tokenPorter;

    mapping (bytes32 => bool) public hashClaimed;

    uint8 public threshold = 2;

    event LogAttestation(bytes32 indexed hash, address indexed who, bool isValid);

    /// @param _validator1 first validator  
    /// @param _validator2 second validator
    /// @param _validator3 third validator
    function initValidator(address _validator1, address _validator2, address _validator3) public onlyOwner {
        // Clear old validators. Validators can be updated multiple times
        for (uint8 i = 0; i < validators.length; i++) {
            delete isValidator[validators[i]];
            delete validatorNum[validators[i]];
        }
        delete validators;
        validators.push(_validator1);
        validators.push(_validator2);
        validators.push(_validator3);
        // TODO: This will be NA, Bloq and a third party (escrow or company) at launch, 
        // and should be scripted into deploy

        isValidator[_validator1] = true;
        isValidator[_validator2] = true;
        isValidator[_validator3] = true;

        validatorNum[_validator1] = 0;
        validatorNum[_validator2] = 1;
        validatorNum[_validator3] = 2;

    }

    /// @notice set address of token porter
    /// @param _tokenPorter address of token porter
    function setTokenPorter(address _tokenPorter) public onlyOwner returns (bool) {
        require(_tokenPorter != 0x0);
        tokenPorter = _tokenPorter;
        return true;
    }

    function validateHash(bytes32 hash) public {
        require(isValidator[msg.sender]);
        hashAttestations[hash][msg.sender] = true;
        emit LogAttestation(hash, msg.sender, true);
    }

    function invalidateHash(bytes32 hash) public {
        require(isValidator[msg.sender]);
        hashAttestations[hash][msg.sender] = false;
        emit LogAttestation(hash, msg.sender, false);
    }

    function hashClaimable(bytes32 hash) public view returns(bool) {
        if (hashClaimed[hash]) { return false; }

        uint8 count = 0;

        for (uint8 i = 0; i < validators.length; i++) {
            if (hashAttestations[hash][validators[i]]) { count++;} 
        }

        if (count >= threshold) { return true; }
        return false;
    }

    function claimHash(bytes32 hash) public {
        require(msg.sender == tokenPorter);
        require(hashClaimable(hash));
        hashClaimed[hash] = true;
    }

    function isReceiptClaimable(bytes8 _originChain, bytes8 _destinationChain, address[] _addresses, bytes _extraData, 
        bytes32[] _burnHashes, uint[] _supplyOnAllChain, uint[] _importData, bytes _proof) public view returns(bool) {
        // We want to validate that these hash to the provided hash as a safety check, 
        // then we want to know if the hash is Claimable. 

        // Due to stack too deep error and limitation in using number of local 
        // variables we have to use uint array here. 
        // _importData[0] is _blockTimestamp, _importData[1] is _amount, _importData[2] is _fee,
        // _importData[3] is _burnedAtTick, _importData[4] is _genesisTime,
        // _importData[5] is _dailyMintable, _importData[6] is _burnSequence,
        // _addresses[0] is _destMetronomeAddr and _addresses[1] is _recipAddr

        require(_burnHashes[1] == keccak256(_importData[0], _originChain, _destinationChain, _addresses[0], 
            _addresses[1], _importData[1], _importData[3], _importData[4], _importData[5], _supplyOnAllChain[0], 
            _extraData, _burnHashes[0]));

        if (hashClaimable(_burnHashes[1])) {
            return true;
        } 
        
        return false;

    }
}