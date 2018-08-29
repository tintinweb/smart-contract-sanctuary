pragma solidity ^0.4.19;


contract Ownable {
    
    address public owner;

    /**
     * The address whcih deploys this contrcat is automatically assgined ownership.
     * */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * Functions with this modifier can only be executed by the owner of the contract. 
     * */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
    * Transfers ownership to new Ethereum address. This function can only be called by the 
    * owner.
    * @param _newOwner the address to be granted ownership.
    **/
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



contract TokenInterface {
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}



contract Airdrop is Ownable {
    
    TokenInterface token;
    
    event NewTokenAddress(address indexed ERC20_ADDRESS);
    event TokensWithdrawn(address indexed ERC20_ADDRESS, uint256 TOTAL);
    event AirdropInvoked();
    
    /**
     * Allows the owner of the contract to change the token to be airdropped
     * 
     * @param _newTokenAddress The address of the token
     * @return True if function executes, false otherwise
     * */
    function setTokenAddress(address _newTokenAddress) public onlyOwner returns(bool) {
        require(_newTokenAddress != address(token));
        require(_newTokenAddress != address(0));
        token = TokenInterface(_newTokenAddress);
        NewTokenAddress(_newTokenAddress);
        return true;
    }
    

    /**
     * Allows the owner of the contract to airdrop tokens using multiple values 
     * 
     * @param _addrs The array of recipient addresses
     * @param _values The array of values (i.e., tokens) each corresponding address 
     * will receive.
     * @return True if function executes, false otherwise
     * */
    function multiValueAirDrop(address[] _addrs, uint256[] _values) public onlyOwner returns(bool) {
	    require(_addrs.length == _values.length && _addrs.length <= 100);
        for (uint i = 0; i < _addrs.length; i++) {
            if (_addrs[i] != 0x0 && _values[i] > 0) {
                token.transfer(_addrs[i], _values[i]);  
            }
        }
        AirdropInvoked();
        return true;
    }


    /**
     * Allows the owner of the contract to airdrop tokens of a single value
     * 
     * @param _addrs The array of recipient addresses
     * @param _value The amount of tokens each address will receive
     * @return True if function executes, false otherwise
     * */
    function singleValueAirDrop(address[] _addrs, uint256 _value) public onlyOwner returns(bool){
	    require(_addrs.length <= 100 && _value > 0);
        for (uint i = 0; i < _addrs.length; i++) {
            if (_addrs[i] != 0x0) {
                token.transfer(_addrs[i], _value);
            }
        }
        AirdropInvoked();
        return true;
    }
    
    
    /**
     * Allows the owner of the contract to withdraw tokens from the contract
     * 
     * @param _addressOfToken The address of the tokens to be withdrawn 
     * @return True if function executes, false otherwise
     * */
    function withdrawTokens(address _addressOfToken) public onlyOwner returns(bool) {
        TokenInterface tkn = TokenInterface(_addressOfToken);
        if(tkn.balanceOf(address(this)) == 0) {
            revert();
        }
        TokensWithdrawn(_addressOfToken, tkn.balanceOf(address(this)));
        tkn.transfer(owner, tkn.balanceOf(address(this)));
    }
}