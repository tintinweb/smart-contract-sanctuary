/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity >=0.7.0 <0.8.0;

/**
 * 
 */
contract Roulette {

    address public dealer;
    mapping(address => uint) public balances;
    uint player_count = 0;
    uint x_global;
    uint r_global;
    bytes32 c_global;

    constructor(){
        dealer = msg.sender;
    }

    function choose_X_and_R(uint x, uint r) public {

        require(
            msg.sender == dealer, 
            "Only the dealer can set x and R"
        );

        require(
            x == 0 || x == 1,
            "X may only be 0 or 1"
        );
        c_global = keccak256(abi.encodePacked(x,r));
    }

    function view_c() public view returns (bytes32 c){
        c = c_global;
    }

    function bet(uint value) public {
        player_count += 1; 
        require(
            dealer != msg.sender,
            "You aren't in the game"
        );
        require(
            player_count <= 8,
            "Maximum number of players exceeded for this game"
        );


    }

    function reveal(uint x, uint r) public{
        require(
            msg.sender == dealer,
            "Only the dealer can set x and R"
        );
        x_global = x;
        r_global = r;
    }

    function view_X_and_R() public view returns (uint x, uint r, bytes32 c){
        x = x_global;
        r = r_global;

        c = keccak256(abi.encodePacked(x,r));

    }

    function winnings(uint amount) public {
        balances[msg.sender] += amount;
    }

}