pragma solidity ^0.4.26;
contract SHRIMPTokenInterface {
    function balanceOf(address who) external view returns(uint256);
}
contract UNISWAPTokenInterface {
    function balanceOf(address who) external view returns(uint256);
    function totalSupply() external view returns (uint256);
}



contract vote {
    mapping(uint => uint) public event_start_time;
    mapping(uint => uint) public event_end_time;
    address public owner;
    uint public now_id;
    mapping (address => mapping (uint => bool)) public vote_content;
    event Voter(uint indexed id,address voter);
    event Purposal(uint indexed id, string content);
    SHRIMPTokenInterface public shrimp = SHRIMPTokenInterface(0x38c4102D11893351cED7eF187fCF43D33eb1aBE6);
    UNISWAPTokenInterface public uniswap = UNISWAPTokenInterface(0xeBA5D22bBeB146392D032A2F74a735d66A32aeE4);
    SHRIMPTokenInterface public zombieshrimp = SHRIMPTokenInterface(0x1dD61127758c47Ab95a1931E02D3517f8d0dD1A6);

    constructor()public{
        owner = msg.sender;
        now_id = 0;
    }
    function agree_vote(uint id)public{
        // require(event_start_time[id] <= now && event_end_time[id] >= now);
        vote_content[msg.sender][id] = true;
        emit Voter(id,msg.sender);
    }
    function disagree_vote(uint id)public{
        // require(event_start_time[id] <= now && event_end_time[id] >= now);
        vote_content[msg.sender][id] = false;
    }
    function get_vote(uint id, address[] _owners)public view returns(uint tickets){
        uint vote_count = 0;
        address uniswapAddress = 0xeBA5D22bBeB146392D032A2F74a735d66A32aeE4;
        for (uint i=0; i<_owners.length; i++) {
           if(vote_content[_owners[i]][id] == true){
               vote_count+=shrimp.balanceOf(_owners[i]);
               vote_count+=(shrimp.balanceOf(uniswapAddress)*uniswap.balanceOf(_owners[i])/uniswap.totalSupply());
                vote_count+=zombieshrimp.balanceOf(_owners[i]);
           }
        }
        return vote_count;
    }
    function update_event_time(uint id, uint ev_time, uint ev_end_time)public{
        require(msg.sender == owner);
        event_start_time[id] = ev_time;
        event_end_time[id] = ev_end_time;
    }
    function purpose(string content)public{
        emit Purposal(now_id, content);
        now_id ++;
    }
    function get_time()public view returns(uint timestamp){
        return now;
    }
}