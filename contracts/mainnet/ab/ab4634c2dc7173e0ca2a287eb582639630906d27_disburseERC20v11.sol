pragma solidity ^0.4.23;

//safemath is not needed as only authorized trusted users can make calls.
contract disburseERC20v11 {
    //indexed fields can be used for filtering event listeners
    event Disbursement(address indexed _tokenContract,  address[] indexed _contributors, uint256[] _contributions, uint256 _amount);
    event AdminSet(address indexed _tokenContract, address indexed _admin);
    event OwnerSet(address _owner);

    address owner;
    mapping(address => address) tokenAdmins;
    
    constructor() public {
        //set owner to contract creator
        owner = msg.sender;
        emit OwnerSet(owner);
    }  

    function disburseToken(address _tokenContract, address[] _contributors, uint256[] _contributions) public {

        //only allow token admin to disburse
        require(msg.sender == tokenAdmins[_tokenContract]);

        // get this contract&#39;s balance of specified token
        uint256 balance = ERC20Token(_tokenContract).balanceOf(address(this));

        // calculate totalContributions
        uint256 totalContributions;
        for(uint16 i = 0; i < _contributions.length; i++){
            totalContributions = totalContributions + _contributions[i];
        }

        //Send tokens to each contributor
        for(i = 0; i < _contributors.length; i++){
            // calculate members&#39;s disbursement
            uint256 disbursement = (balance * _contributions[i]) / totalContributions;
            
            // ensure that token transfer is successful or  revert all previous actions and stop running
            require(ERC20Token(_tokenContract).transfer(_contributors[i], disbursement));
        }
        // fire event to record disbursement
        emit Disbursement(_tokenContract, _contributors, _contributions, balance);
    }
    
    function setAdmin(address _tokenContract, address _admin) public {
        //don&#39;t allow assignment to address 0x0
        require(_admin != address(0));
        
        //only owner or current admin can set Admin
        require(msg.sender == tokenAdmins[_tokenContract] || msg.sender == owner);
        
        //save admin to token address mapping
        tokenAdmins[_tokenContract] = _admin;
        
        //fire event for client access
        emit AdminSet(_tokenContract, _admin);
    }
    
    function setOwner(address _owner) public {
        //don&#39;t allow assignment to address 0x0
        require(_owner != address(0));
        
        //only owner can set owner
        require(msg.sender == owner);
        
        //save admin to token address mapping
        owner = _owner;
        
        //fire event for client access
        emit OwnerSet(_owner);
    }
}

// interface to allow calls to ERC20 tokens
interface ERC20Token {
    function balanceOf(address _holder) external returns(uint256 tokens);
    function transfer(address _to, uint256 amount) external returns(bool success);
}