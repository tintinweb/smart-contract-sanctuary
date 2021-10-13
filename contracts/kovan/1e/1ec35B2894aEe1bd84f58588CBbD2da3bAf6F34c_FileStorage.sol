/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "./Token.sol";
// import "./FileStorage.sol";

contract Token {

    // My Variables
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    // Keep track balances and allowances approved
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events - fire events on state changes etc
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply)  {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply;
    }

    /// @notice transfer amount of tokens to an address
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    /// @return success as true, for transfer 
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev internal helper transfer function with required safety checks
    /// @param _from, where funds coming the sender
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    // Internal function transfer can only be called by this contract
    //  Emit Transfer Event event 
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Ensure sending is to valid address! 0x0 address cane be used to burn() 
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    /// @notice Approve other to spend on your behalf eg an exchange 
    /// @param _spender allowed to spend and a max amount allowed to spend
    /// @param _value amount value of token to send
    /// @return true, success once address approved
    //  Emit the Approval event  
    // Allow _spender to spend up to _value on your behalf
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice transfer by approved person from original address of an amount within approved limit 
    /// @param _from, address sending to and the amount to send
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    /// @dev internal helper transfer function with required safety checks
    /// @return true, success once transfered from original account    
    // Allow _spender to spend up to _value on your behalf
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

}
contract FileStorage {
    
    address public addressThyme;
    address public admin;
    
    address[] public members;
    mapping(address => uint) public providedDiskSpace;
    mapping(address => bool) public inMemberList;
    mapping(address => bool) public isMember;
   
    
    constructor (address _addressThyme)  {
        
        addressThyme = _addressThyme;
       // addressSupine = _addressSupine;
        admin = msg.sender;
        
    }
    
    function transferDiskSpaceToTokens(uint diskSpace) external { //diskSpace in GB
        
        require(diskSpace > 0, "diskSpace cannot be 0");  
        // require(msg.sender == admin, 'only owner');
         uint amount = diskSpace * 2;
        
        
        Token thyme = Token(addressThyme);
        //thyme.transferFrom(admin, msg.sender, amount);
        thyme.transfer(msg.sender, amount);
        
        //Update diskSpace shared
        providedDiskSpace[msg.sender] = providedDiskSpace[msg.sender] + diskSpace;
        
         //Add user to members array only if they aren't a member already
        if(!inMemberList[msg.sender]) {
            members.push(msg.sender);
        }

        //Update staking status
        isMember[msg.sender] = true;
        inMemberList[msg.sender] = true;
        
    }
    
    function uploadFiles(address recipient, uint fileSize) external { //diskSpace in GB
        
      Token thyme = Token(addressThyme);
        
       // uint charge = fileSize * 0.75;
        //uint rental = fileSize * 75 * 10 ** 16;
        uint rental = fileSize;
        
        require(fileSize > 0, "fileSize cannot be 0");   
        require(thyme.balanceOf(msg.sender) >= rental, 'rental exceeds the token balance');
        require(providedDiskSpace[recipient] >= fileSize , 'no enough disk space in the receiver');
        
        //thyme.transferFrom(msg.sender, recipient, rental);
        thyme.transfer(recipient, rental);
        providedDiskSpace[recipient] = providedDiskSpace[recipient] - fileSize;
    
        
    }
    
    function leaveSystem() external {
        
         Token thyme = Token(addressThyme);
         
         require (thyme.balanceOf(msg.sender) > 0, 'token balance cannot be zero');
        
         
         // Reset the disk space shared
         providedDiskSpace[msg.sender] = 0;
         

        //Update staking status
        isMember[msg.sender] = false;

        
    }
    
    // Issuing Tokens(Earning Interests)
    function issueTokens() public {

        //only the owner must be able to call this function
        //because we must not let anyone else issue tokens
        require(msg.sender == admin, "caller must be the owner");
        Token thyme = Token(addressThyme);


        //loop throug all the people who has membership inside the members array and issue them
        //issue tokens to all members
        for (uint i=0; i<members.length; i++) {
            address recipient = members[i];
            uint reward = providedDiskSpace[recipient];
            if(reward > 0) {
                thyme.transferFrom(msg.sender, recipient, reward);
            }

        }
    }
}