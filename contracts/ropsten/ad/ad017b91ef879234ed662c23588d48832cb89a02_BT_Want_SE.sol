pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

contract BT_Want_SE {
    address public owner;
    uint public revealTime;
    uint private nonce;
    uint public winning_count;
    
    mapping (string => uint) attender_index;
    string[] private attender;
    mapping (string => uint) winner_index;
    string[] private winner;
    
    event Result(
        address sender,
        uint time,
        string[] winner
    );

    constructor() public {
        owner = msg.sender;
        nonce = uint(address(this));
        attender.push(""); // Skip invalid index.
        
        revealTime = 1543568400; // Friday, November 30, 2018 17:00:00 GMT+08:00
        winning_count = 2; // For 2 SE.
    }
    
    modifier onlyBefore(uint _time) { require(now < _time); _; }
    modifier onlyAfter(uint _time) { require(now > _time); _; }
    modifier ownerOnly() { require(msg.sender == owner); _; }
    
    // Get random number.
    function random(uint n) internal returns (uint) {
        require (n > 0);
        uint randomnumber = uint(keccak256(abi.encodePacked(now, blockhash(block.number-1), nonce))) % n;
        nonce += block.number + 1;
        return (randomnumber + 1);
    }
    
    function add_attender(string[] _usernames) public ownerOnly onlyBefore(revealTime) {
        for(uint i = 0; i < _usernames.length; i++){
            string memory username = _usernames[i];
            if(attender_index[username] > 0){
                continue;
            } else {
                attender_index[username] = attender.length;
                attender.push(username);
            }
        }
    }
    
    function get_all_attender() public view returns (string[]) {
        string[] memory output = new string[](attender.length);
        for(uint i = 0; i < attender.length; i++){
            output[i] = attender[i];
        }
        return output;
    }
    
    // Get winner id.
    function reveal() external onlyAfter(revealTime) {
        uint max_val = attender.length - 1;
        require(max_val >= winning_count);
        string memory current_winner;
        for (uint i = 1; i <= winning_count; i++) {
            current_winner = attender[random(max_val)];
            if (winner_index[current_winner] > 0){
                i--;
            } else {
                winner_index[current_winner] = i;
                winner.push(attender[random(max_val)]);
            }
        }
        emit Result(msg.sender, now, winner);
        selfdestruct(owner);
    }
}