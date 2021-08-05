/**
 *Submitted for verification at Etherscan.io on 2020-05-13
*/

pragma solidity >=0.6.6;

contract NTeria {
    address payable owner;
    struct Person {
        address payable voter;
        uint256 amount;
        string decision;
    }
    bytes32 private_key_hashed;
    uint people_count;
    bool voting_in_progress;
    mapping(uint => Person) people;
    
    event RevealKey(string);
    event VotingClosed(uint);
    
    constructor() public {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    function add_funds() public payable isOwner {}
    
    function withdraw_funds() public isOwner {
        require(address(this).balance>0, 'Balance is zero');
        owner.transfer(address(this).balance);
    }
    
    function open_voting(bytes32 _private_key_hashed) public isOwner {
        private_key_hashed = _private_key_hashed;
        voting_in_progress = true;
    }
    
    function get_vote(string memory _private_key, string memory _decision) internal pure returns(uint _vote) {
        bytes32 _data = keccak256(abi.encodePacked(_private_key,_decision));
        assembly { 
            _vote := and(_data,0xf)
        }
        return _vote;        
    }
    
    function close_voting() public isOwner {
        require(voting_in_progress, "No voting to close");
        uint _balance = get_voting_balance();
        delete voting_in_progress;
        emit VotingClosed(_balance);
    }
    
    function reveal_key_and_pay(string memory  _private_key) public isOwner {
        require(!voting_in_progress, "First, close voting");
        require(keccak256(abi.encodePacked(_private_key)) == private_key_hashed, "Wrong private key");
        emit RevealKey(_private_key);
        
        uint[16] memory _people_votes;
        for (uint i;i<people_count;i++)
            _people_votes[get_vote(_private_key,people[i].decision)]++;
        
        uint _max_votes = 0;
        for (uint j;j<16;j++)
            if (_people_votes[j] > _max_votes)
                _max_votes = _people_votes[j];
        
        uint _money_to_give;
        uint _winners_count = 1;
        for (uint i;i<people_count;i++) {
            uint _vote = get_vote(_private_key,people[i].decision);
            if (_people_votes[_vote] == _max_votes) {
                _money_to_give += people[i].amount;
                delete people[i];
            } else if (people[i].amount > 0) {
                _winners_count ++;
            }
        }
        
        _money_to_give -= _money_to_give%_winners_count;
        uint _qty = _money_to_give/_winners_count;

        for (uint i;i<people_count;i++) {
            if (people[i].amount > 0) {
                people[i].voter.transfer(_qty+people[i].amount);
                delete people[i];
            }
        }
        delete people_count;
        delete private_key_hashed;
    }
    
    function make_vote(string memory _decision) public payable {
        require(voting_in_progress, "Voting is closed");
        require(msg.value > 0, "You should pay something");
        people[people_count] = Person(msg.sender,msg.value,_decision);
        people_count ++;
    }
    
    function cancel_vote() public {
        require(voting_in_progress, "Voting is closed");
        for (uint i;i<people_count;i++) {
            if (people[i].voter == msg.sender) {
                msg.sender.transfer(people[i].amount);
                delete people[i];
            }
            
        }
    }
    
    function get_voting_balance() public view returns(uint _val){
        _val = 0;
        for (uint i;i<people_count;i++) {
            _val += people[i].amount;
        }
    }

    function get_number_votes() public view returns(uint _val){
        _val = 0;
        for (uint i;i<people_count;i++) {
            if (people[i].amount>0) {
                _val ++;
            }
        }
    }
 
    function destroy_contract() public isOwner{
        selfdestruct(owner);
    }
}