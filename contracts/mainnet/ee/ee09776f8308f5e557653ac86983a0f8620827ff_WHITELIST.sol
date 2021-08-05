pragma solidity 0.6.4;

import "./SafeMath.sol";
import "./IERC20.sol";
//
//█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
//█░░╦─╦╔╗╦─╔╗╔╗╔╦╗╔╗░░█
//█░░║║║╠─║─║─║║║║║╠─░░█
//█░░╚╩╝╚╝╚╝╚╝╚╝╩─╩╚╝░░█
//█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█
//

contract WHITELIST {

    using SafeMath for uint256;

    mapping(address => bool) admins;
    mapping(address => bool) whitelisted; // only whitelisted addresses can claim
    mapping(address => bool) claimed; // 1 claim per address
    
    address private admin = address(0);
    uint256 ethPerClaim = 0.1 ether;
    
    bool private sync;
    
    //protects against potential reentrancy
    modifier synchronized {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    modifier onlyAdmin(){
        require(admins[msg.sender], "not an admin");
        _;
    }
    
    modifier onlyWhitelisted(){
        require(whitelisted[msg.sender], "not whitelisted, no free moneyz 4 u");
        _;
    }
    
    constructor() public {
        admins[msg.sender] = true;
        admin = msg.sender;
    }
    
    receive() external payable{
        
    }

    //allow user to claim eth allocated to whitelisted address
    function ClaimFreeMoneyzzzz()
        public
        synchronized
        onlyWhitelisted
    {
        require(!claimed[msg.sender], "looks like you've already claimed, don't be greedy");
        claimed[msg.sender] = true;
        //send eth
        msg.sender.transfer(ethPerClaim);
    }
    
    //allows admin to add new whitelisted addresses
    function newWhitelist(address _user)
        public
        onlyAdmin
    {
        whitelisted[_user] = true;
    }
    
    //allows admin to revoke any whitelisted addresses
    function revokeWhitelist(address _user)
        public
        onlyAdmin
    {
        whitelisted[_user] = false;
    }
    
    //allocate amount of eth per claim
    function setEthPerClaim(uint256 _amount)
        public
        onlyAdmin
    {
        require(_amount > 0, "value must be greater than 0");
        ethPerClaim = _amount;
    }
    
    //acquire any random tokens dropped to contract
    function tokenManagement(address _tokenAddress)
        public
        onlyAdmin
    {
        require(_tokenAddress != address(this));
        require(IERC20(_tokenAddress).totalSupply() > 0, "may not be contract address");
        uint tokenBal = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, tokenBal);
    }
    
    function donate() 
        public
        payable
    {
        require(msg.value > 0);
        bool success = false;
        //distribute
        (success, ) =  admin.call{value:msg.value}{gas:21000}('');
        require(success, "Transfer failed");
    }
}
