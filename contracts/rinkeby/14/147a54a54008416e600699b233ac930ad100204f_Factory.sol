/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

pragma solidity 0.8.4;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Receiver {
    
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function transferFunds(address _token, uint256 _amount, address _receiver) public {
        require(msg.sender == owner);
    
        IERC20(_token).transfer(_receiver, _amount);
    }
}

contract Factory {
    address owner;
    
    mapping (address => Receiver) public userToReceiver;
    
    constructor()
    {
        owner = msg.sender;
    }
    
    function generateReceiver() external returns(address)
    {
        require(address(userToReceiver[msg.sender]) == address(0), "User already has a receiver address generated!");
        
        userToReceiver[msg.sender] = new Receiver();
        
        return(address(userToReceiver[msg.sender]));
    }
    
    //////////////////
    // Owner functions
    
    function transferReceiverFunds(address[] memory _receivers, address[] memory _tokens, uint256[] memory _amounts) external
    {
        require(msg.sender == owner);
        require(_receivers.length == _tokens.length && _amounts.length == _tokens.length);
        
        for(uint256 i=0;i<_tokens.length;i++) 
        {
            Receiver(_receivers[i]).transferFunds(_tokens[i], _amounts[i], address(this));
        }
    }
    
    function transferFunds(address _token, uint256 _amount, address _receiver) public {
        require(msg.sender == owner);
    
        IERC20(_token).transfer(_receiver, _amount);
    }
    
    function transferOwner(address _owner) external
    {
        require(msg.sender == owner);
        
        owner = _owner;
    }
}