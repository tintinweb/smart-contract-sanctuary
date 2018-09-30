pragma solidity ^0.4.24;
contract ERC20{
    mapping  (address => uint256) public balanceOf;
    function symbol() constant  public returns (string);
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}
contract collection{
    address public owner;
    address public collectionAddress;
    
    modifier qualification {
        
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _address) public{
        
        owner=msg.sender;
        collectionAddress=_address;
    }
    
    function setCollectionAddress(address _address) public qualification {
        
        collectionAddress=_address;
    }
    
    function setOwner(address _address) public qualification {
        
        owner=_address;
    }
    
    function job(address _token, address[] dsts, uint256 gross) public qualification {

        uint count = dsts.length;
        ERC20 erc20 = ERC20(_token);
        erc20.transferFrom(msg.sender,this,gross);
        for(uint i = 0; i < count; i++){
           if(erc20.balanceOf(dsts[i]) == 0){
               erc20.transfer(dsts[i],erc20.balanceOf(dsts[i]));
           }
        }
    }
    
}