pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
		newOwner = address(0);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "msg.sender == owner");
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, "address(0) != _newOwner");
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner, "msg.sender == newOwner");
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

contract Adminable is Ownable {
    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        require( admins[msg.sender] && msg.sender != owner , "admins[msg.sender] && msg.sender != owner");
        _;
    }

    function setAdmin(address _admin, bool _authorization) onlyOwner public {
        admins[_admin] = _authorization;
    }
 
}


contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract TokedoExchange is Ownable, Adminable {
	using SafeMath for uint256;
	
    mapping (address => uint256) public invalidOrder;

    function invalidateOrdersBefore(address _user) onlyAdmin public {
        invalidOrder[_user] = now;
    }

    mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances
    

    mapping (address => uint256) public lastActiveTransaction; // time of last interaction with this contract
    mapping (bytes32 => uint256) public orderFills; //balanceOf order filled
    
    address public feeAccount;
    uint256 public inactivityReleasePeriod;
    
    mapping (bytes32 => bool) public traded; //hashes of order already traded
    mapping (bytes32 => bool) public withdrawn; // hashes of funds already withdrawn
    
    uint256 public maxFeeWithdrawal; // fee applied
    uint256 public newMaxFeeWithdrawal;// new proposed fee
    uint256 public timeMaxFeeWithdrawal;// time of proposed fee
    
    uint256 public maxFeeTrade; // fee applied
    uint256 public newMaxFeeTrade;// new proposed fee
    uint256 public timeMaxFeeTrade;// time of proposed fee
  

    constructor(address _feeAccount) public {
        feeAccount = _feeAccount;
        inactivityReleasePeriod = 2 weeks;
        maxFeeWithdrawal = 50 finney;
        maxFeeTrade = 100 finney;
    }
    
    function setInactivityReleasePeriod(uint256 _expiry) onlyAdmin public returns (bool success) {
        require(_expiry < 26 weeks, "_expiry < 26 weeks" );
        
        inactivityReleasePeriod = _expiry;
        
        return true;
    }
    
    function setMaxFeeWithdrawal(uint256 _fee) onlyAdmin public returns (bool success) {
        newMaxFeeWithdrawal = _fee;
        timeMaxFeeWithdrawal = now;
        success = true;
    }
    
    function applySetMaxFeeWithdrawal() onlyAdmin public returns (bool success) {
        require( timeMaxFeeWithdrawal > 0 );
        uint256 waitingTime;
        if ( inactivityReleasePeriod < 1 weeks ) {
            waitingTime = 2 weeks;
        } else {
            waitingTime = 2 * inactivityReleasePeriod;
        }
        require( timeMaxFeeWithdrawal.add( waitingTime ) > now, "timeMaxFeeWithdrawal.add( waitingTime ) > now" );
        
        maxFeeWithdrawal = newMaxFeeWithdrawal;
        
        newMaxFeeWithdrawal = 0;
        timeMaxFeeWithdrawal = 0;
        
        success = true;
    }
    
    function setMaxFeeTrade(uint256 _fee) onlyAdmin public returns (bool success) {
        newMaxFeeTrade = _fee;
        timeMaxFeeTrade = now;
        success = true;
    }
    
    function applySetMaxFeeTrade() onlyAdmin public returns (bool success) {
        require( timeMaxFeeTrade > 0 );
        uint256 waitingTime;
        if ( inactivityReleasePeriod < 1 weeks ) {
            waitingTime = 2 weeks;
        } else {
            waitingTime = 2 * inactivityReleasePeriod;
        }
        require( timeMaxFeeTrade.add( waitingTime ) > now, "timeMaxFeeTrade.add( waitingTime ) > now" );
        
        maxFeeTrade = newMaxFeeTrade;
        
        newMaxFeeTrade = 0;
        timeMaxFeeTrade = 0;
        
        success = true;
    }
    
    function setFeeAccount(address _newFeeAccount) onlyOwner public returns (bool success) {
        feeAccount = _newFeeAccount;
        success = true;
    }


    event Deposit(address token, address user, uint256 amount, uint256 balance);

    function depositToken(address token, uint256 amount) public {
        
        tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
        
        lastActiveTransaction[msg.sender] = now;
        
        require( Token(token).transferFrom(msg.sender, this, amount), "Token(token).transferFrom(msg.sender, this, amount)" );
        
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function depositEther() payable public {
        
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
        
        lastActiveTransaction[msg.sender] = now;
        
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }


    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    function emergencyWithdraw(address token, uint256 amount) public returns (bool success) {
        
        require( now.sub(lastActiveTransaction[msg.sender]) > inactivityReleasePeriod, "now.sub(lastActiveTransaction[msg.sender]) > inactivityReleasePeriod" );
        require( tokens[token][msg.sender] >= amount );
        
        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
        
        if (token == address(0)) {
            require(msg.sender.send(amount), "msg.sender.send(amount)");
        } else {
            require(Token(token).transfer(msg.sender, amount), "Token(token).transfer(msg.sender, amount)");
        }
        
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        success = true;
    }

    function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 feeWithdrawal) public onlyAdmin returns (bool success) {
        
        bytes32 hash = keccak256( abi.encodePacked(this, token, amount, user, nonce) );
        require( !withdrawn[hash] );
        withdrawn[hash] = true;
        
        require( ecrecover( keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", hash) ), v, r, s) == user);
        
        if (feeWithdrawal > maxFeeWithdrawal) feeWithdrawal = maxFeeWithdrawal;
        
        require(tokens[token][user] >= amount);
        
        tokens[token][user] = tokens[token][user].sub(amount);
        
        tokens[token][feeAccount] = tokens[token][feeAccount].add(feeWithdrawal.mul(amount) / 1 ether);
        
        amount = (1 ether - feeWithdrawal).mul(amount) / 1 ether;
        
        if (token == address(0)) {
            require( user.send(amount), "user.send(amount)");
        } else {
            require( Token(token).transfer(user, amount), "Token(token).transfer(user, amount)" );
        }
        
        lastActiveTransaction[user] = now;
        
        emit Withdraw(token, user, amount, tokens[token][user]);
        success = true;
  }

    function balanceOf(address token, address user) public view returns (uint256) {
        return tokens[token][user];
    }

  function adminTrade(uint256[8] _values, address[4] _addresses, uint8[2] v, bytes32[4] rs) public onlyAdmin returns (bool success) {

    /* _values
        [0] amountBuyMaker
        [1] amountSellMaker
        [2] expiresMaker
        [3] nonceMaker
        [4] amountBuyTaker
        [5] tradeNonceTaker
        [6] feeMake
        [7] feeTake
     _addresses
        [0] tokenBuyAddress
        [1] tokenSellAddress
        [2] makerAddress
        [3] takerAddress
     */

    
    //required: nonceMaker is greater or egual User Maker Nonce
    require( _values[3] >= invalidOrder[_addresses[2]] , "_values[3] >= invalidOrder[_addresses[2]]"  );
    
    // orderHash: ExchangeAddress, tokenBuyAddress, amountBuyMaker, tokenSellAddress, amountSellMaker, expiresMaker, nonceMaker, makerAddress
    bytes32 orderHash = keccak256( abi.encodePacked(this, _addresses[0], _values[0], _addresses[1], _values[1], _values[2], _values[3], _addresses[2]) );
    
    //required: the signer is the same address of makerAddress
    require( _addresses[2] == ecrecover( keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash) ), v[0], rs[0], rs[1]),
            &#39;_addresses[2] == ecrecover( keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash) ), v[0], rs[0], rs[1])&#39;);
    
    // tradeHash: OrderHash, amountBuyTaker, takerAddress, tradeNonceTaker
    bytes32 tradeHash = keccak256( abi.encodePacked(orderHash, _values[4], _addresses[3], _values[5]) ); 
    
    //required: the signer is the same address of takerAddress
    require( _addresses[3] == ecrecover( keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", tradeHash) ), v[1], rs[2], rs[3]) , 
            &#39;_addresses[3] == ecrecover( keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", tradeHash) ), v[1], rs[2], rs[3])&#39; );
    
    //required: the same trade is not done
    require( !traded[tradeHash] , "!traded[tradeHash] ");
    traded[tradeHash] = true;
    

    if (_values[6] > maxFeeTrade) _values[6] = maxFeeTrade;    // set max fee make
    if (_values[7] > maxFeeTrade) _values[7] = maxFeeTrade;    // set max fee take
    
    /* amountBuyTaker is in amountBuy terms */
    /* _values
        [0] amountBuyMaker
        [1] amountSellMaker
        [2] expiresMaker
        [3] nonceMaker
        [4] amountBuyTaker
        [5] tradeNonceTaker
        [6] feeMake
        [7] feeTake
     _addresses
        [0] tokenBuyAddress
        [1] tokenSellAddress
        [2] makerAddress
        [3] takerAddress
     */
    
    //required: order + amountBuyTaker <= amountBuyMaker
    require( orderFills[orderHash].add(_values[4]) <= _values[0],
            "orderFills[orderHash].add(_values[4]) <= _values[0]");
    
    //required there are sufficient funds: tokens[tokenBuyAddress][taker] >= amountBuyTaker
    require( tokens[_addresses[0]][_addresses[3]] >= _values[4] ,
            "tokens[_addresses[0]][_addresses[3]] >= _values[4]");
    
    //required there are sufficient funds: tokens[tokenSellAddress][makerAddress] >= amountSellMaker * amountBuyTaker / amountBuyMaker
    require( tokens[_addresses[1]][_addresses[2]] >= ( _values[1].mul(_values[4] ) / _values[0]) ,
            "tokens[_addresses[1]][_addresses[2]] >= ( _values[1].mul(_values[4] ) / _values[0])");
    
    //tokens[tokenBuyAddress][takerAddress] = tokens[tokenBuyAddress][takerAddress].sub( amountBuyTaker );
    tokens[_addresses[0]][_addresses[3]] = tokens[_addresses[0]][_addresses[3]].sub( _values[4] );
    
    //tokens[tokenBuyAddress][makerAddress] = tokens[tokenBuyAddress]][makerAddress].add( amountBuyTaker.mul( (1e18 - feeMake)) / 1e18);
    tokens[_addresses[0]][_addresses[2]] = tokens[_addresses[0]][_addresses[2]].add( _values[4].mul( (1e18 - _values[6]) ) / 1e18 );
    
    //tokens[tokenBuyAddress][feeAccount] = tokens[tokenBuyAddress][feeAccount].add( amountBuyTaker.mul( feeMake ) / 1e18);
    tokens[_addresses[0]][feeAccount] = tokens[_addresses[0]][feeAccount].add( _values[4].mul( _values[6] ) / 1e18 );
    
    
    //tokens[tokenSellAddress][makerAddress] = tokens[tokenSellAddress][makerAddress].sub( amountSellMaker.mul( amountBuyTaker ) / amountBuyMaker);
    tokens[_addresses[1]][_addresses[2]] = tokens[_addresses[1]][_addresses[2]].sub( _values[1].mul( _values[4] ) / _values[0]);
    
    //tokens[tokenSellAddress][takerAddress] = tokens[tokenSellAddress][takerAddress].add( (1e18 - feeTake).mul( amountSellMaker ).mul( amountBuyTaker ) / amountBuyMaker / 1e18);
    tokens[_addresses[1]][_addresses[3]] = tokens[_addresses[1]][_addresses[3]].add( (1e18 - _values[7]).mul( _values[1] ).mul( _values[4] ) / _values[0] / 1e18 );
    
    //tokens[tokenSellAddress][feeAccount] = tokens[tokenSellAddress][feeAccount].add( feeTake.mul( amountSellMaker ).mul( amountBuyTaker ) / amountBuyMaker / 1e18 );
    tokens[_addresses[1]][feeAccount] = tokens[_addresses[1]][feeAccount].add( _values[7].mul( _values[1] ).mul( _values[4] ) / _values[0] / 1e18 );
    
    
    //orderFills[orderHash] = orderFills[orderHash].add(amountBuyTaker);
    orderFills[orderHash] = orderFills[orderHash].add(_values[4]);
    
    lastActiveTransaction[_addresses[2]] = now; //lastActiveTransaction[makerAddress] = now;
    lastActiveTransaction[_addresses[3]] = now; //lastActiveTransaction[takerAddress] = now;
    
    success = true;
    
    }
}