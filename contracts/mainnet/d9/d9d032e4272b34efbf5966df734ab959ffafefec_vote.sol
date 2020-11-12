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
    SHRIMPTokenInterface public zombie = SHRIMPTokenInterface(0xd55BD2C12B30075b325Bc35aEf0B46363B3818f8);
    UNISWAPTokenInterface public uniswap = UNISWAPTokenInterface(0xC83E9d6bC93625863FFe8082c37bA6DA81399C47);
    SHRIMPTokenInterface public shrimpZombie = SHRIMPTokenInterface(0xdcEe2dC9834dfbc7d24C57769ED51daf202a1b87);
    UNISWAPTokenInterface public yfibpt = UNISWAPTokenInterface(0x1066a453127faD74d0aB1C981DffA56D76310517);
    UNISWAPTokenInterface public crvbpt = UNISWAPTokenInterface(0xDA4B031B5ECE42ABB394A9d2130eAA958C2A8B38);

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
        address uniswapAddress = 0xC83E9d6bC93625863FFe8082c37bA6DA81399C47;
        address yfiaddress = 0x1066a453127faD74d0aB1C981DffA56D76310517;
        address crvaddress = 0xDA4B031B5ECE42ABB394A9d2130eAA958C2A8B38;
        for (uint i=0; i<_owners.length; i++) {
           if(vote_content[_owners[i]][id] == true){
               vote_count+=zombie.balanceOf(_owners[i]);
               vote_count+=(zombie.balanceOf(uniswapAddress)*uniswap.balanceOf(_owners[i])/uniswap.totalSupply());
                vote_count+=shrimpZombie.balanceOf(_owners[i]);
                vote_count+=(zombie.balanceOf(yfiaddress)*yfibpt.balanceOf(_owners[i])/yfibpt.totalSupply());
                vote_count+=(zombie.balanceOf(crvaddress)*crvbpt.balanceOf(_owners[i])/crvbpt.totalSupply());
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