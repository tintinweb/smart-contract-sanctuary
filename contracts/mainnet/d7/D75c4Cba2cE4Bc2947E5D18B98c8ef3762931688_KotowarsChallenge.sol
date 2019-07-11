/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

pragma solidity ^0.5.0;

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract KotowarsChallenge 
{
    mapping(address => bool) admins;
    
    modifier adminsOnly
    {
        require(admins[msg.sender] == true, "Not an admin");
        _;
    }
  
    address WCKAddress;
  
    uint256 challenge_ttl; 
    uint256 fee;
    uint256 min_buy_in;
   
    enum ChallengeStatus { Created, Accepted, Resolved}
  
    struct Challenge
    {
        address creator;
        address acceptor;
        address winner;
        uint256 buy_in;
        ChallengeStatus status;
        uint256 accepted_at;
    }

    Challenge[] challenges;

    event Created(uint256 challenge_id, address creator,  uint256 buy_in);
    event Accepted(uint256 challenge_id, address acceptor);
    event Resolved(uint256 challenge_id, address winner, uint256 reward);
    event Revoked(uint256 challenge_id, address revoker);

    function create_challenge(uint256 buy_in) public {
        ERC20 WCK = ERC20(WCKAddress);
        require(WCK.transferFrom(msg.sender, address(this), (buy_in + fee) * WCK.decimals()));
        
        Challenge memory challenge = Challenge({
            creator: msg.sender,
            acceptor: address(0),
            winner: address(0),
            buy_in: buy_in,
            status: ChallengeStatus.Created,
            accepted_at: 0
        });
        uint256 challenge_id = challenges.push(challenge) - 1;
        
        emit Created(challenge_id, challenge.creator, challenge.buy_in);
    }
     
    function accept_challenge(uint256 challenge_id) public
    {
        require(challenge_id < challenges.length);
     
        Challenge memory challenge = challenges[challenge_id];
        require(challenge.status == ChallengeStatus.Created);
     
        ERC20 WCK = ERC20(WCKAddress);
        require(WCK.transferFrom(msg.sender, address(this), (challenge.buy_in + fee) * WCK.decimals()));
     
        challenge.acceptor = msg.sender;   
        challenge.status = ChallengeStatus.Accepted;
        challenge.accepted_at = now;
        
        challenges[challenge_id] = challenge;
        
        emit Accepted(challenge_id, challenge.acceptor);
    }
   
    function resolve(uint256 challenge_id, address winner) public adminsOnly
    {
        require(challenge_id < challenges.length);
        
        Challenge memory challenge = challenges[challenge_id];
        require(challenge.status == ChallengeStatus.Accepted);
        
        challenge.winner = winner;
        challenge.status = ChallengeStatus.Resolved;
        
        challenges[challenge_id] = challenge;
        
        uint256 reward = challenge.buy_in * 2;
        ERC20 WCK = ERC20(WCKAddress);
        require(WCK.transferFrom(address(this), challenge.winner, reward * WCK.decimals()));
     
        emit Resolved(challenge_id, challenge.winner, reward);
    }
   
    function unlock_funds(uint256 challenge_id) public
    {
        require(challenge_id < challenges.length);
        
        Challenge memory challenge = challenges[challenge_id];
        require(challenge.status != ChallengeStatus.Resolved);
        require(challenge.accepted_at + challenge_ttl < now);
        
        ERC20 WCK = ERC20(WCKAddress);
        
        if (challenge.status == ChallengeStatus.Created)
        {
            require(WCK.transferFrom(address(this), challenge.creator, challenge.buy_in * WCK.decimals()));
        }
        else if (challenge.status == ChallengeStatus.Accepted)
        {
            require(WCK.transferFrom(address(this), challenge.creator, challenge.buy_in * WCK.decimals()));
            require(WCK.transferFrom(address(this), challenge.acceptor, challenge.buy_in * WCK.decimals()));
        }
        
        challenge.status = ChallengeStatus.Resolved;
        
        emit Revoked(challenge_id, msg.sender);
    }
    
    function set_challenge_ttl(uint256 value) public adminsOnly
    {
        challenge_ttl = value;
    }
    
    function set_min_buy_in(uint256 value) public adminsOnly
    {
        min_buy_in = value;
    }
    
    function set_fee(uint256 value) public adminsOnly
    {
        fee = value;
    }
    
    function set_wck_address(address value) public adminsOnly
    {
        WCKAddress = value;
    }
    
    function add_admin(address admin) public adminsOnly
    {
        admins[admin] = true;
    }
    
    function remove_admin(address admin) public adminsOnly
    {
        admins[admin] = false;
    }
    
    function withdraw() public adminsOnly
    {
        ERC20 WCK = ERC20(WCKAddress);
        WCK.transfer(msg.sender, WCK.balanceOf(address(this)));
    }
    
    constructor() public 
    {
        admins[msg.sender] = true;
        
        WCKAddress = address(0x09fE5f0236F0Ea5D930197DCE254d77B04128075);
        
        challenge_ttl = 60; 
        fee = 0;
        min_buy_in = 0;
    }
}