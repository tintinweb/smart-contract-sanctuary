/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity >=0.7.0 <0.9.0;


contract MutilSignWallet { 
    
    mapping(address => address[]) public waitAddOwners;
    
    address public addOwnerAddress;
    
    mapping(address => address[]) public addApprover;
    
    mapping(address => address[]) public waitRemoveOwners;
    
    address public removeOwnerAddress;
    
    mapping(address => address[]) public removeApprover;

    mapping(address => address) public applyTransactions;
    
    mapping(address => uint256) public waitTransactions;
    
    address public applyTransOwner;
    
    mapping(address => address[]) public approveTransOwners;
    
    mapping(address=> bool) public owners;
    
    uint public maxOners;
    
    uint public maxApprover;
    
    uint public currentOwners;
    
    string public walletName;
    
    address public tokenAddress;
    
    string public tokenName;
    
    uint public balanceOfToken;
 
    constructor(string memory _walletName, uint _maxOners, uint _maxApprover,address _tokenAddress, string memory _tokenName) {
        walletName = _walletName;
        maxOners = _maxOners;
        maxApprover = _maxApprover;
        tokenAddress = _tokenAddress;
        tokenName = _tokenName;
        owners[msg.sender] = true;
    }
    
    receive() external payable{}
    
    function applyAddManagers(address[] memory _owners) external {
        require(owners[msg.sender], "Your are not right to add owners");
        require(addOwnerAddress != address(0),"There has a add need opration.");
        
        uint size = _owners.length;
        uint canBeAddCount = maxOners - currentOwners;
        require(size > canBeAddCount, "Add owners more than the max owners.");
        
        for (uint index=0;index < _owners.length; index++) {
            address newOwner = _owners[index];
            if(owners[newOwner] == true) {
                continue;
            }
            waitAddOwners[msg.sender].push(newOwner);
        }
        
    }
    
    function approveAddOwners(address addNonce) external{
        require(owners[msg.sender], "Your are not right to approve add owners");
        addApprover[addNonce].push(msg.sender);
        
        if(addApprover[addNonce].length >= maxApprover) {
            for(uint index=0;index < waitAddOwners[addNonce].length; index++) {
                address newOwner = [addNonce][index];
                owners[newOwner] = true;
            }
            
        }
        
    }
    
    function applyARemoveOwners(address [] memory _removeOwners) external{
        require(owners[msg.sender], "Your are not right to remove owners");
        require(removeOwnerAddress != address(0), "There has a remove need opration. ");
        
        for(uint index=0;index<_removeOwners.length;index++) {
            waitRemoveOwners[removeOwnerAddress].push(_removeOwners[index]);
        }
        
        removeApprover[removeOwnerAddress].push(msg.sender);
        
    }
    
    function approveRemoveOwners() public {
        require(owners[msg.sender], "Your are not right to approve remove owners");
        removeApprover[removeOwnerAddress].push(msg.sender);
        
        if(removeApprover[removeOwnerAddress].length >= maxApprover) {
            address [] memory removeOwners = waitRemoveOwners[removeOwnerAddress];
            
            for(uint index=0;index<removeOwners.length; index++) {
                owners[waitRemoveOwners[removeOwnerAddress][index]] = false;
            }
            
        }
        
    }
    
    function applyTransaction(address _to, uint256 _value) external {
        require(owners[msg.sender], "Your are not right to apply send transaction");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= _value, "This wallet balance is less than there transaction");
        applyTransactions[applyTransOwner] = _to;
        waitTransactions[_to] = _value;
        approveTransOwners[applyTransOwner].push(msg.sender);
    }
    
    function approveTransactions() external {
        require(owners[msg.sender], "Your are not right to apply send transaction");
        approveTransOwners[applyTransOwner].push(msg.sender);
        if(approveTransOwners[applyTransOwner].length >= maxApprover)  {
            address _to = applyTransactions[applyTransOwner];
            uint256 _value = waitTransactions[_to];
            IERC20(tokenAddress).transfer(_to, _value);
        }
    }
}


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