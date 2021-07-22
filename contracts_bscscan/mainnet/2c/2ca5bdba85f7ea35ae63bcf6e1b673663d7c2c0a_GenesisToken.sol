/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
interface tokenRecipient{
    function receiveApproval(address  _from,uint256  _value, address  _token, bytes calldata _extraData) external ;
}
contract GenesisToken{
    //public var
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    //store token data set
    mapping(address => uint256) public balanceOf;
    //transition limite
    mapping(address => mapping(address => uint256)) public allowance;
    
    //event for transition
    event Transfer(address indexed from,address indexed to , uint256 value);
    //event for allowance
    event Approval(address indexed owner,address indexed spender,uint256 value);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    //func constructor
    constructor() {
        owner = 0x6b67258A1790B2EE7E632b538fAD780e83f7075F;
        name = "Genesis";
        symbol = "GNS";
        decimals = 18;
        totalSupply = 988000000 * 10 ** uint256(18);
        
        //init totalSupply to map(db)
        balanceOf[owner] = totalSupply;
    }
    
 
    // public functions
    // 1 Transfer tokens 
    function transfer(address _to,uint256 _value) public{
        _transfer(msg.sender,_to,_value);
    }
    
    // 2 Transfer Other's tokens ,who had approve some token to me 
    function transferFrom(address _from,address _to,uint256 _value) public returns (bool success){
        //validate the allowance 
        require(_value<=allowance[_from][msg.sender]);
        //do action :sub allowance and do transfer 
        allowance[_from][msg.sender] -= _value;
        _transfer(_from,_to,_value);
        
        return true;
    }
    //A is msg.sender or i 
    //B is the person who has approve me to use his token or _from 
    //C is the receipient or _to
    
    // 3 set allowance for other address,like B approve A(_spender) to use his token
    function approve(address _spender,uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    // 4 allowance and notify the receipient/spender 
    function approveAndCall(address _spender,uint256 _value,bytes calldata _extraData) public returns (bool success){
        tokenRecipient spender = tokenRecipient(_spender);
        if(approve(_spender,_value)){
            spender.receiveApproval(msg.sender,_value,address(this),_extraData);
            return true;
        }
    }
    
    // onlyOwner function 

    // 12 transfer contract  Ownership to newOwner and transfer all balanceOf oldOwner to newOwner
    function transferOwnership(address newOwner) onlyOwner public{
        _transfer(owner,newOwner,balanceOf[owner]);
        owner = newOwner;
    }

    
    //internal transfer function
    // 1 _transfer
    function _transfer(address _from,address _to, uint256 _value) internal {
        //validate input and ot her internal limites
        require(_to != address(0));//check to address
        require(balanceOf[_from] >= _value);//check from address has enough balance 
        require(balanceOf[_to] + _value >balanceOf[_to]);//after transfer the balance of _to address is ok ,no overflow
        uint256 previousBalances = balanceOf[_from]+balanceOf[_to];//store it for add asset to power the security
        //do transfer:sub from _from address,and add to the _to address
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        //after transfer: emit transfer event,and add asset for security
        emit Transfer(_from,_to,_value);
        assert(balanceOf[_from]+balanceOf[_to] == previousBalances);
    }

}