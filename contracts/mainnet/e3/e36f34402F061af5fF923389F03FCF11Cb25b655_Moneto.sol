pragma solidity ^0.4.17;

/// @title Base Token contract - Functions to be implemented by token contracts.
contract BaseToken {
    /*
     * Implements ERC 20 standard.
     * https://github.com/ethereum/EIPs/blob/f90864a3d2b2b45c4decf95efd26b3f0c276051a/EIPS/eip-20-token-standard.md
     * https://github.com/ethereum/EIPs/issues/20
     *
     *  Added support for the ERC 223 "tokenFallback" method in a "transfer" function with a payload.
     *  https://github.com/ethereum/EIPs/issues/223
     */

    /*
     * This is a slight change to the ERC20 base standard.
     * function totalSupply() constant returns (uint256 supply);
     * is replaced with:
     * uint256 public totalSupply;
     * This automatically creates a getter function for the totalSupply.
     * This is moved to the base contract since public getter functions are not
     * currently recognised as an implementation of the matching abstract
     * function by the compiler.
     */
    uint256 public totalSupply;

    /*
     * ERC 20
     */
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    /*
     * ERC 223
     */
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);

    /*
     * Events
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // There is no ERC223 compatible Transfer event, with `_data` included.
}


 /*
 * Contract that is working with ERC223 tokens
 * https://github.com/ethereum/EIPs/issues/223
 */

/// @title ERC223ReceivingContract - Standard contract implementation for compatibility with ERC223 tokens.
contract ERC223ReceivingContract {

    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param _from Transaction initiator, analogue of msg.sender
    /// @param _value Number of tokens to transfer.
    /// @param _data Data containig a function signature and/or parameters
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}


/// @title Standard token contract - Standard token implementation.
contract StandardToken is BaseToken {

    /*
     * Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /*
     * Public functions
     */
    /// @notice Send `_value` tokens to `_to` from `msg.sender`.
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /// @notice Send `_value` tokens to `_to` from `msg.sender` and trigger
    /// tokenFallback if sender is a contract.
    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    /// @param _data Data to be sent to tokenFallback
    /// @return Returns success of function call.
    function transfer(
        address _to,
        uint256 _value,
        bytes _data)
        public
        returns (bool)
    {
        require(transfer(_to, _value));

        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly.
            codeLength := extcodesize(_to)
        }

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    }

    /// @notice Transfer `_value` tokens from `_from` to `_to` if `msg.sender` is allowed.
    /// @dev Allows for an approved third party to transfer tokens from one
    /// address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    /// @notice Allows `_spender` to transfer `_value` tokens from `msg.sender` to any address.
    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    /// @return Returns success of function call.
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0);

        // To change the approve amount you first have to reduce the addresses`
        // allowance to zero by calling `approve(_spender, 0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read functions
     */
    /// @dev Returns number of allowed tokens that a spender can transfer on
    /// behalf of a token owner.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    /// @return Returns remaining allowance for spender.
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /// @dev Returns number of tokens owned by the given address.
    /// @param _owner Address of token owner.
    /// @return Returns balance of owner.
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
}


contract Moneto is StandardToken {
  
  string public name = "Moneto";
  string public symbol = "MTO";
  uint8 public decimals = 18;

  function Moneto(address saleAddress) public {
    require(saleAddress != 0x0);

    totalSupply = 42901786 * 10**18;
    balances[saleAddress] = totalSupply;
    emit Transfer(0x0, saleAddress, totalSupply);

    assert(totalSupply == balances[saleAddress]);
  }

  function burn(uint num) public {
    require(num > 0);
    require(balances[msg.sender] >= num);
    require(totalSupply >= num);

    uint preBalance = balances[msg.sender];

    balances[msg.sender] -= num;
    totalSupply -= num;
    emit Transfer(msg.sender, 0x0, num);

    assert(balances[msg.sender] == preBalance - num);
  }
}


contract MonetoSale {
    Moneto public token;

    address public beneficiary;
    address public alfatokenteam;
    uint public alfatokenFee;
    
    uint public amountRaised;
    uint public tokenSold;
    
    uint public constant PRE_SALE_START = 1523952000; // 17 April 2018, 08:00:00 GMT
    uint public constant PRE_SALE_END = 1526543999; // 17 May 2018, 07:59:59 GMT
    uint public constant SALE_START = 1528617600; // 10 June 2018,08:00:00 GMT
    uint public constant SALE_END = 1531209599; // 10 July 2018, 07:59:59 GMT

    uint public constant PRE_SALE_MAX_CAP = 2531250 * 10**18;
    uint public constant SALE_MAX_CAP = 300312502 * 10**17;

    uint public constant SALE_MIN_CAP = 2500 ether;

    uint public constant PRE_SALE_PRICE = 1250;
    uint public constant SALE_PRICE = 1000;

    uint public constant PRE_SALE_MIN_BUY = 10 * 10**18;
    uint public constant SALE_MIN_BUY = 1 * 10**18;

    uint public constant PRE_SALE_1WEEK_BONUS = 35;
    uint public constant PRE_SALE_2WEEK_BONUS = 15;
    uint public constant PRE_SALE_3WEEK_BONUS = 5;
    uint public constant PRE_SALE_4WEEK_BONUS = 0;

    uint public constant SALE_1WEEK_BONUS = 10;
    uint public constant SALE_2WEEK_BONUS = 7;
    uint public constant SALE_3WEEK_BONUS = 5;
    uint public constant SALE_4WEEK_BONUS = 3;
    
    mapping (address => uint) public icoBuyers;

    Stages public stage;
    
    enum Stages {
        Deployed,
        Ready,
        Ended,
        Canceled
    }
    
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        require(msg.sender == beneficiary);
        _;
    }

    function MonetoSale(address _beneficiary, address _alfatokenteam) public {
        beneficiary = _beneficiary;
        alfatokenteam = _alfatokenteam;
        alfatokenFee = 5 ether;

        stage = Stages.Deployed;
    }

    function setup(address _token) public isOwner atStage(Stages.Deployed) {
        require(_token != 0x0);
        token = Moneto(_token);

        stage = Stages.Ready;
    }

    function () payable public atStage(Stages.Ready) {
        require((now >= PRE_SALE_START && now <= PRE_SALE_END) || (now >= SALE_START && now <= SALE_END));

        uint amount = msg.value;
        amountRaised += amount;

        if (now >= SALE_START && now <= SALE_END) {
            assert(icoBuyers[msg.sender] + msg.value >= msg.value);
            icoBuyers[msg.sender] += amount;
        }
        
        uint tokenAmount = amount * getPrice();
        require(tokenAmount > getMinimumAmount());
        uint allTokens = tokenAmount + getBonus(tokenAmount);
        tokenSold += allTokens;

        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            require(tokenSold <= PRE_SALE_MAX_CAP);
        }
        if (now >= SALE_START && now <= SALE_END) {
            require(tokenSold <= SALE_MAX_CAP);
        }

        token.transfer(msg.sender, allTokens);
    }

    function transferEther(address _to, uint _amount) public isOwner {
        require(_amount <= address(this).balance - alfatokenFee);
        require(now < SALE_START || stage == Stages.Ended);
        
        _to.transfer(_amount);
    }

    function transferFee(address _to, uint _amount) public {
        require(msg.sender == alfatokenteam);
        require(_amount <= alfatokenFee);

        alfatokenFee -= _amount;
        _to.transfer(_amount);
    }

    function endSale(address _to) public isOwner {
        require(amountRaised >= SALE_MIN_CAP);

        token.transfer(_to, tokenSold*3/7);
        token.burn(token.balanceOf(address(this)));

        stage = Stages.Ended;
    }

    function cancelSale() public {
        require(amountRaised < SALE_MIN_CAP);
        require(now > SALE_END);

        stage = Stages.Canceled;
    }

    function takeEtherBack() public atStage(Stages.Canceled) returns (bool) {
        return proxyTakeEtherBack(msg.sender);
    }

    function proxyTakeEtherBack(address receiverAddress) public atStage(Stages.Canceled) returns (bool) {
        require(receiverAddress != 0x0);
        
        if (icoBuyers[receiverAddress] == 0) {
            return false;
        }

        uint amount = icoBuyers[receiverAddress];
        icoBuyers[receiverAddress] = 0;
        receiverAddress.transfer(amount);

        assert(icoBuyers[receiverAddress] == 0);
        return true;
    }

    function getBonus(uint amount) public view returns (uint) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            uint w = now - PRE_SALE_START;
            if (w <= 1 weeks) {
                return amount * PRE_SALE_1WEEK_BONUS/100;
            }
            if (w > 1 weeks && w <= 2 weeks) {
                return amount * PRE_SALE_2WEEK_BONUS/100;
            }
            if (w > 2 weeks && w <= 3 weeks) {
                return amount * PRE_SALE_3WEEK_BONUS/100;
            }
            if (w > 3 weeks && w <= 4 weeks) {
                return amount * PRE_SALE_4WEEK_BONUS/100;
            }
            return 0;
        }
        if (now >= SALE_START && now <= SALE_END) {
            uint w2 = now - SALE_START;
            if (w2 <= 1 weeks) {
                return amount * SALE_1WEEK_BONUS/100;
            }
            if (w2 > 1 weeks && w2 <= 2 weeks) {
                return amount * SALE_2WEEK_BONUS/100;
            }
            if (w2 > 2 weeks && w2 <= 3 weeks) {
                return amount * SALE_3WEEK_BONUS/100;
            }
            if (w2 > 3 weeks && w2 <= 4 weeks) {
                return amount * SALE_4WEEK_BONUS/100;
            }
            return 0;
        }
        return 0;
    }

    function getPrice() public view returns (uint) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            return PRE_SALE_PRICE;
        }
        if (now >= SALE_START && now <= SALE_END) {
            return SALE_PRICE;
        }
        return 0;
    }

    function getMinimumAmount() public view returns (uint) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            return PRE_SALE_MIN_BUY;
        }
        if (now >= SALE_START && now <= SALE_END) {
            return SALE_MIN_BUY;
        }
        return 0;
    }
}