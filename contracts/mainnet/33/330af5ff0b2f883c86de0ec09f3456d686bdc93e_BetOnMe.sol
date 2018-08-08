pragma solidity ^0.4.18;

/*
 * ERC223 interface
 * see https://github.com/ethereum/EIPs/issues/20
 * see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223 {
    function totalSupply() constant public returns (uint256 outTotalSupply);
    function balanceOf( address _owner) constant public returns (uint256 balance);
    function transfer( address _to, uint256 _value) public returns (bool success);
    function transfer( address _to, uint256 _value, bytes _data) public returns (bool success);
    function transferFrom( address _from, address _to, uint256 _value) public returns (bool success);
    function approve( address _spender, uint256 _value) public returns (bool success);
    function allowance( address _owner, address _spender) constant public returns (uint256 remaining);
    event Transfer( address indexed _from, address indexed _to, uint _value, bytes _data);
    event Approval( address indexed _owner, address indexed _spender, uint256 _value);
}


contract ERC223Receiver { 
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

/**
 * Math operations with safety checks
 */
contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

 
}



/**
 * Standard ERC223
 */
contract StandardToken is ERC223, SafeMath {
        
    uint256 public supplyNum;
    
    uint256 public decimals;

    /* Actual mapBalances of token holders */
    mapping(address => uint) mapBalances;

    /* approve() allowances */
    mapping (address => mapping (address => uint)) mapApproved;

    /* Interface declaration */
    function isToken() public pure returns (bool weAre) {
        return true;
    }


    function totalSupply() constant public returns (uint256 outTotalSupply) {
        return supplyNum;
    }

    
    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        mapBalances[msg.sender] = safeSub(mapBalances[msg.sender], _value);
        mapBalances[_to] = safeAdd(mapBalances[_to], _value);
        
        if (codeLength > 0) {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    
    function transfer(address _to, uint _value) public returns (bool) {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        mapBalances[msg.sender] = safeSub(mapBalances[msg.sender], _value);
        mapBalances[_to] = safeAdd(mapBalances[_to], _value);
        
        if (codeLength > 0) {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
        return true;
    }
    
    

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        mapApproved[_from][msg.sender] = safeSub(mapApproved[_from][msg.sender], _value);
        mapBalances[_from] = safeSub(mapBalances[_from], _value);
        mapBalances[_to] = safeAdd(mapBalances[_to], _value);
        
        bytes memory empty;
        emit Transfer(_from, _to, _value, empty);
                
        return true;
    }

    function balanceOf(address _owner) view public returns (uint balance)    {
        return mapBalances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success)    {

        // To change the approve amount you first have to reduce the addresses`
        //    allowance to zero by calling `approve(_spender, 0)` if it is not
        //    already 0 to mitigate the race condition described here:
        //    https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require (_value != 0); 
        require (mapApproved[msg.sender][_spender] == 0);

        mapApproved[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint remaining)    {
        return mapApproved[_owner][_spender];
    }

}




/**
 * Centrally issued Ethereum token.
 *
 * We mix in burnable and upgradeable traits.
 *
 * Token supply is created in the token contract creation and allocated to owner.
 * The owner can then transfer from its supply to crowdsale participants.
 * The owner, or anybody, can burn any excessive tokens they are holding.
 *
 */
contract BetOnMe is StandardToken {

    string public name = "BetOnMe";
    string public symbol = "BOM";
    
    
    address public coinMaster;
    
    
    /** Name and symbol were updated. */
    event UpdatedInformation(string newName, string newSymbol);

    function BetOnMe() public {
        supplyNum = 1000000000000 * (10 ** 18);
        decimals = 18;
        coinMaster = msg.sender;

        // Allocate initial balance to the owner
        mapBalances[coinMaster] = supplyNum;
    }

    /**
     * Owner can update token information here.
     *
     * It is often useful to conceal the actual token association, until
     * the token operations, like central issuance or reissuance have been completed.
     * In this case the initial token can be supplied with empty name and symbol information.
     *
     * This function allows the token owner to rename the token after the operations
     * have been completed and then point the audience to use the token contract.
     */
    function setTokenInformation(string _name, string _symbol) public {
        require(msg.sender == coinMaster) ;

        require(bytes(name).length > 0 && bytes(symbol).length > 0);

        name = _name;
        symbol = _symbol;
        emit UpdatedInformation(name, symbol);
    }
    
    
    
    /// transfer dead tokens to contract master
    function withdrawTokens() external {
        uint256 fundNow = balanceOf(this);
        transfer(coinMaster, fundNow);//token
        
        uint256 balance = address(this).balance;
        coinMaster.transfer(balance);//eth
    }

}