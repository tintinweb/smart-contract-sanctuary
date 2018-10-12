pragma solidity ^0.4.25;

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
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    uint8 public decimals;
}

contract TokedoExchange is Ownable, Adminable {
	using SafeMath for uint256;
	
    mapping (address => uint256) public invalidOrder;

    function invalidateOrdersBefore(address _user) onlyAdmin public {
        require( now > invalidOrder[_user], "now > invalidOrder[_user]" );
        invalidOrder[_user] = now;
    }

    mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances
    

    mapping (address => uint256) public lastActiveTransaction; // time of last interaction with this contract
    mapping (bytes32 => uint256) public orderFills; //balanceOf order filled
    
    address public feeAccount;
    uint256 public inactivityReleasePeriod = 2 weeks;
    
    mapping (bytes32 => bool) public traded; //hashes of order already traded
    mapping (bytes32 => bool) public withdrawn; // hashes of funds already withdrawn
    
    uint256 public constant maxFeeWithdrawal = 0.05 ether; // max fee rate applied = 5%
    uint256 public constant maxFeeTrade = 0.10 ether; // max fee rate applied = 10%
    
    address public tokedoToken;
    
    constructor(address _feeAccount, address _tokedoToken) public {
        feeAccount = _feeAccount;
        tokedoToken = _tokedoToken;
    }
    
    /***************************
     * EDITABLE CONFINGURATION *
     ***************************/
    
    function setInactivityReleasePeriod(uint256 _expiry) onlyAdmin public returns (bool success) {
        require(_expiry < 26 weeks, "_expiry < 26 weeks" );
        inactivityReleasePeriod = _expiry;
        return true;
    }
    
    function setFeeAccount(address _newFeeAccount) onlyOwner public returns (bool success) {
        feeAccount = _newFeeAccount;
        success = true;
    }
    
    function setTokedoToken(address _tokedoToken) onlyOwner public returns (bool success) {
        tokedoToken = _tokedoToken;
        success = true;
    }
    
    /*****************
     * DEPOSIT TOKEN *
     *****************/
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    
    function tokenFallback(address _from, uint256 _amount, bytes) public {
        depositTokenFunction(msg.sender, _amount, _from);
    }

	function receiveApproval(address _from, uint256 _amount, bytes) public {
		transferFromAndDepositTokenFunction( msg.sender, _amount, _from );
	}
	
	function depositToken(address _token, uint256 _amount) public {
	    transferFromAndDepositTokenFunction(_token, _amount, msg.sender);
    }

    function transferFromAndDepositTokenFunction (address _token, uint256 _amount, address _sender) private {
        require( Token(_token).transferFrom(_sender, this, _amount), "Token(_token).transferFrom(_sender, this, _amount)" );
        depositTokenFunction(_token, _amount, _sender);
    }

    function depositTokenFunction(address _token, uint256 _amount, address _sender) private {
        tokens[_token][_sender] = tokens[_token][_sender].add(_amount);
        
        lastActiveTransaction[_sender] = now;
        
        emit Deposit(_token, _sender, _amount, tokens[_token][msg.sender]);
    }
    
    /*****************
     * DEPOSIT ETHER *
     *****************/

    function depositEther() payable public {
        
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
        
        lastActiveTransaction[msg.sender] = now;
        
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    /************
     * WITHDRAW *
     ************/
    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    function emergencyWithdraw(address _token, uint256 _amount) public returns (bool success) {
        
        require( now.sub(lastActiveTransaction[msg.sender]) > inactivityReleasePeriod, "now.sub(lastActiveTransaction[msg.sender]) > inactivityReleasePeriod" );
        require( tokens[_token][msg.sender] >= _amount );
        
        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        
        if (_token == address(0)) {
            require(msg.sender.send(_amount), "msg.sender.send(_amount)");
        } else {
            require(Token(_token).transfer(msg.sender, _amount), "Token(_token).transfer(msg.sender, _amount)");
        }
        
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
        success = true;
    }

    function adminWithdraw(address _token, uint256 _amount, address _user, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s, uint256 _feeWithdrawal) public onlyAdmin returns (bool success) {
        
        bytes32 hash = keccak256( abi.encodePacked(this, _token, _amount, _user, _nonce) );
        require( !withdrawn[hash] );
        withdrawn[hash] = true;
        
        require( ecrecover( keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", hash) ), _v, _r, _s) == _user);
        
        if (_feeWithdrawal > maxFeeWithdrawal) _feeWithdrawal = maxFeeWithdrawal;
        
        require(tokens[_token][_user] >= _amount);
        
        tokens[_token][_user] = tokens[_token][_user].sub(_amount);
        
        tokens[_token][feeAccount] = tokens[_token][feeAccount].add(_feeWithdrawal.mul(_amount) / 1 ether);
        
        _amount = (1 ether - _feeWithdrawal).mul(_amount) / 1 ether;
        
        if (_token == address(0)) {
            require( _user.send(_amount), "_user.send(_amount)");
        } else {
            require( Token(_token).transfer(_user, _amount), "Token(_token).transfer(_user, _amount)" );
        }
        
        lastActiveTransaction[_user] = now;
        
        emit Withdraw(_token, _user, _amount, tokens[_token][_user]);
        success = true;
  }

    function balanceOf(address _token, address _user) public view returns (uint256) {
        return tokens[_token][_user];
    }
    
    
    /***************
     * ADMIN TRADE *
     ***************/
    
    function adminTrade(uint256[] _values, address[] _addresses, uint8[] _v, bytes32[] _rs) public onlyAdmin returns (bool success) {
        /* amountSellTaker is in amountBuyMaker terms 
         _values
            [0] amountSellTaker
            [1] tradeNonceTaker
            [2] feeTake
            [3] tokedoPrice
            [4] feePayableTokedoTaker ( yes is 1 - no is 0 )
            [5] feeMake
			[i*5+6] amountBuyMaker
            [i*5+7] amountSellMaker
            [i*5+8] expiresMaker
            [i*5+9] nonceMaker
            [i*5+10] feePayableTokedoMaker ( yes is 1 - no is 0 )
         _addresses
            [0] tokenBuyAddress
            [1] tokenSellAddress
            [2] takerAddress
            [i+3] makerAddress
         _v
            [0] vTaker
            [i+1] vMaker
         _rs
            [0] rTaker
            [1] sTaker
            [i*2+2] rMaker
            [i*2+3] sMaker
         */ 
         
         
        /**********************
         * FEE SECURITY CHECK *
         **********************/
        
        //if ( feeTake > maxFeeTrade) feeTake = maxFeeTrade;    
        if (_values[2] > maxFeeTrade) _values[2] = maxFeeTrade;    // set max fee take
        
        // if (feeMake > maxFeeTrade) feeMake = maxFeeTrade;    
        if (_values[5] > maxFeeTrade) _values[5] = maxFeeTrade;    // set max fee make
    
        /********************************
         * TAKER BEFORE SECURITY CHECK *
         ********************************/
        
        //check if there are sufficient funds for TAKER: 
        require( tokens[_addresses[0]][_addresses[2]] >= _values[0] ,
                "tokens[tokenBuyAddress][takerAddress] >= amountSellTaker");
        
        /**************
         * LOOP LOGIC *
         **************/
        
        bytes32[2] memory orderHash;
        uint256[8] memory amount;
        /*
            orderHash
                [0] globalHash
                [1] makerHash
            amount
                [0] totalBuyMakerAmount
                [1] appliedAmountSellTaker
                [2] remainingAmountSellTaker
                 * [3] amountFeeMake
                 * [4] amountFeeTake
                 * [5] priceTrade
                 * [6] feeTokedoMaker
                 * [7] feeTokedoTaker
                
        */
        
        // remainingAmountSellTaker = amountSellTaker
        amount[2] = _values[0];
        
        for(uint256 i=0; i < (_values.length - 6) / 5; i++ ) {
            
            /************************
             * MAKER SECURITY CHECK *
             *************************/
            
            //required: nonceMaker is greater or egual makerAddress
            require( _values[i*5+9] >= invalidOrder[_addresses[i+3]] ,
                    "nonceMaker >= invalidOrder[makerAddress]"  );
            
            // orderHash: ExchangeAddress, tokenBuyAddress, amountBuyMaker, tokenSellAddress, amountSellMaker, expiresMaker, nonceMaker, makerAddress, feePayableTokedoMaker
            orderHash[1] =  keccak256( abi.encodePacked( abi.encodePacked(this, _addresses[0], _values[i*5+6], _addresses[1], _values[i*5+7], _values[i*5+8], _values[i*5+9], _addresses[i+3]), _values[i*5+10]) );
            
            //globalHash = keccak256( abi.encodePacked( globalHash, makerHash ) );
            orderHash[0] = keccak256( abi.encodePacked( orderHash[0], orderHash[1] ) );
            
            //required: the signer is the same address of makerAddress
            require( _addresses[i+3] == ecrecover( keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash[1]) ), _v[i+1], _rs[i*2+2], _rs[i*2+3]),
                    &#39;makerAddress    == ecrecover( keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", makerHash   ) ), vMaker , rMaker    , sMaker    )&#39;);
            
            
            /*****************
             * GLOBAL AMOUNT *
             *****************/
             
            //appliedAmountSellTaker = amountBuyMaker.sub( orderFilled )
            amount[1] = _values[i*5+6].sub( orderFills[orderHash[1]] ); 

            //if appliedAmountSellTaker <= amountSellTaker
            if ( amount[1] <= _values[0] ) {
                //appliedAmountSellTaker = remainingAmountSellTaker
                amount[1] = amount[2]; 
            }
            
            //remainingAmountSellTaker -= appliedAmountSellTaker
            amount[2] = amount[2].sub( amount[1] ); 
            
            //totalBuyMakerAmount += appliedAmountSellTaker
            amount[0] = amount[0].add( amount[1] );
            
            
            /******************************
             * MAKER SECURITY CHECK FUNDS *
             ******************************/
            
            //check if there are sufficient funds for MAKER: tokens[tokenSellAddress][makerAddress] >= amountSellMaker * appliedAmountSellTaker / amountBuyMaker
            require( tokens[_addresses[1]][_addresses[i+3]] >= ( _values[i*5+7].mul( amount[1] ).div( _values[i*5+6] ) ) ,
                    "tokens[tokenSellAddress][makerAddress] >= ( amountSellMaker.mul( appliedAmountSellTaker ).div( amountBuyMaker ) )");
            
            
            /*******************
             * FEE COMPUTATION *
             *******************/
             
            /* amount
                 * [3] amountFeeMake
                 * [4] amountFeeTake
                 * [5] priceTrade
                 * [6] feeTokedoMaker
                 * [7] feeTokedoTaker
            */
            
            //amountFeeMake = appliedAmountSellTaker.mul( feeMake ).div( 1e18 )
            amount[3] = amount[1].mul( _values[5] ).div( 1e18 );
            //amountFeeTake = feeTake.mul( amountSellMaker ).mul( appliedAmountSellTaker ).div( amountBuyMaker ) / 1e18
            amount[4] = _values[2].mul( _values[i*5+7] ).mul( amount[1] ).div( _values[i*5+6] ) / 1e18  ;
            
            //if ( tokenBuyAddress == address(0 ) {
            if ( _addresses[0] == address(0) ) { // maker sell order
                //amountBuyMaker is ETH
                //amountSellMaker is TKN
                //amountFeeMake is ETH
                //amountFeeTake is TKN
                
                //if ( feePayableTokedoMaker == 1 ) feeTokedoMaker = amountFeeMake.mul( 1e18 ).div(tokedoPrice);
                if ( _values[i*5+10] == 1 ) amount[6] = amount[3].mul( 1e18 ).div(_values[3]);
                
                //if ( feePayableTokedoTaker == 1) 
                if ( _values[4] == 1 ) {
                    // priceTrade =  amountBuyMaker.mul( uint256(Token(tokenSellAddress).decimals()) ).div(amountSellMaker)
                    amount[5] = _values[i*5+6].mul( uint256(Token(_addresses[1]).decimals()) ).div(_values[i*5+7]); // price is ETH / TKN
                    //feeTokedoTaker = amountFeeTake.mul(priceTrade).div( 1e18 ).mul( 1e18 ).div(tokedoPrice);
                    amount[7] = amount[4].mul(amount[5]).div( 1e18 ).mul( 1e18 ).div(_values[3]);
                }
                 
            } else { 
                //maker buy order
                //amountBuyMaker is TKN
                //amountSellMaker is ETH
                //amountFeeMake is TKN
                //amountFeeTake is ETH

                //if ( feePayableTokedoTaker == 1) feeTokedoTaker = amountFeeTake.mul( 1e18 ).div(tokedoPrice);
                if( _values[4] == 1) amount[7] = amount[4].mul( 1e18 ).div(_values[3]);
                
                //if ( feePayableTokedoMaker == 1 )
                if ( _values[i*5+10] == 1 ) {
                    // priceTrade =  amountSellMaker.mul( uint256(Token(tokenBuyAddress).decimals()) ).div(amountBuyMaker)
                    amount[5] = _values[i*5+7].mul( uint256(Token(_addresses[0]).decimals()) ).div(_values[i*5+6]); // price is ETH / TKN
                
                    // feeTokedoMaker = amountFeeMake.mul(priceTrade).div( 1e18 ).mul( 1e18 ).div(tokedoPrice);
                    amount[6] = amount[3].mul(amount[5]).div( 1e18 ).mul( 1e18 ).div(_values[3]);
                }
            }
            
            
            /**********************
             * FEE BALANCE UPDATE *
             **********************/
            
            //feeTokedoTaker > 0 && tokens[tokedoToken][takerAddress] >= feeTokedoTaker
            if ( amount[7] > 0 && tokens[tokedoToken][_addresses[2]] >= amount[7]  ) {
                
                //tokens[tokedoToken][takerAddress]  = tokens[tokedoToken][takerAddress].sub(feeTokedoTaker);
                tokens[tokedoToken][_addresses[2]] = tokens[tokedoToken][_addresses[2]].sub(amount[7]);
                
                //tokens[tokedoToken][feeAccount] = tokens[tokedoToken][feeAccount].add( feeTokedoTaker );
                tokens[tokedoToken][feeAccount] = tokens[_addresses[0]][feeAccount].add( amount[7] );
                
                amount[4] = 0;
            } else {
                //tokens[tokenSellAddress][feeAccount] = tokens[tokenSellAddress][feeAccount].add( amountFeeTake );
                tokens[_addresses[1]][feeAccount] = tokens[_addresses[1]][feeAccount].add( amount[4] );
            }
            
            //feeTokedoMaker > 0 && tokens[tokedoToken][makerAddress] >= feeTokedoMaker
            if ( amount[6] > 0 && tokens[tokedoToken][_addresses[i+3]] >= amount[6] ) {
                
                //tokens[tokedoToken][makerAddress] = tokens[tokedoToken][makerAddress].sub(feeTokedoMaker);
                tokens[tokedoToken][_addresses[i+3]] = tokens[tokedoToken][_addresses[i+3]].sub(amount[6]);
                
                //tokens[tokedoToken][feeAccount] = tokens[tokedoToken][feeAccount].add( feeTokedoMaker );
                tokens[tokedoToken][feeAccount] = tokens[tokedoToken][feeAccount].add( amount[6] );
                
                amount[3] = 0;
            } else {
                //tokens[tokenBuyAddress][feeAccount] = tokens[tokenBuyAddress][feeAccount].add( amountFeeMake );
                tokens[_addresses[0]][feeAccount] = tokens[_addresses[0]][feeAccount].add( amount[3] );
            }
            
        
            /******************
             * BALANCE UPDATE *
             ******************/
            
        //tokens[tokenBuyAddress][takerAddress] = tokens[tokenBuyAddress][takerAddress].sub( appliedAmountSellTaker );
        tokens[_addresses[0]][_addresses[2]] = tokens[_addresses[0]][_addresses[2]].sub( amount[1] );
            
            //tokens[tokenBuyAddress][makerAddress] = tokens[tokenBuyAddress]][makerAddress].add( appliedAmountSellTaker.sub( amountFeeMake ) );
            tokens[_addresses[0]][_addresses[i+3]] = tokens[_addresses[0]][_addresses[i+3]].add( amount[1].sub( amount[3] ) );
            
            
            //tokens[tokenSellAddress][makerAddress] = tokens[tokenSellAddress][makerAddress].sub( amountSellMaker.mul( appliedAmountSellTaker ).div( amountBuyMaker ) );
            tokens[_addresses[1]][_addresses[i+3]] = tokens[_addresses[1]][_addresses[i+3]].sub( _values[i*5+7].mul( amount[1] ).div( _values[i*5+6] ) );
            
        //tokens[tokenSellAddress][takerAddress] = tokens[tokenSellAddress][takerAddress].add( amountSellMaker.mul( appliedAmountSellTaker ).div( amountBuyMaker ).sub( amountFeeTake ) );
        tokens[_addresses[1]][_addresses[2]] = tokens[_addresses[1]][_addresses[2]].add( _values[i*5+7].mul( amount[1] ).div( _values[i*5+6] ).sub( amount[4] ) );
            
            
            /***********************
             * UPDATE MAKER STATUS *
             ***********************/
                        
            //orderFills[orderHash[1]] = orderFills[orderHash[1]].add(appliedAmountSellTaker);
            orderFills[orderHash[1]] = orderFills[orderHash[1]].add(amount[1]);
            
            //lastActiveTransaction[makerAddress] = now;
            lastActiveTransaction[_addresses[i+3]] = now; 
            
        }
        
        
        /*******************************
         * TAKER AFTER SECURITY CHECK *
         *******************************/

        // tradeHash:                                   globalHash, amountSellTaker, takerAddress, tradeNonceTaker, feePayableTokedoTaker
        bytes32 tradeHash = keccak256( abi.encodePacked(orderHash[0], _values[0], _addresses[2], _values[1], _values[4]) ); 
        
        //required: the signer is the same address of takerAddress
        require( _addresses[2] == ecrecover( keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", tradeHash) ), _v[0], _rs[0], _rs[1]) , 
                &#39;takerAddress  == ecrecover( keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", tradeHash) ), vTaker, rTaker, sTaker)&#39; );
        
        //required: the same trade is not done
        require( !traded[tradeHash] , "!traded[tradeHash] ");
        traded[tradeHash] = true;
        
        //required: totalBuyMakerAmount == amountSellTaker
        require( amount[0] == _values[0] , "totalBuyMakerAmount == amountSellTaker" );
        
        
        /***********************
         * UPDATE TAKER STATUS *
         ***********************/
        
        //lastActiveTransaction[takerAddress] = now;
        lastActiveTransaction[_addresses[2]] = now; 
        
        success = true;
    }
}