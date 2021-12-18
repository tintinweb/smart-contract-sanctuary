/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.7;

interface ERC20 {
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Ownable {
    address owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "address is null");
        owner = newOwner;
    }
}

contract DnaMysteryBox is Ownable {
    struct Prize{
        ERC20 token;
        address addr;
        uint probability;
        uint min;
        uint max;
    }
    Prize[] prizes;

    mapping(address => uint[]) user_last_box;

    ERC20 ticket;

    //=============================================
    //============= public function ================
    //=============================================
    function open_mystery_box() public returns(bool) {
        require(msg.sender == tx.origin, "not eoa");
        require(ticket.balanceOf(msg.sender) > 0, "insufficient ticket balance");
        require(ticket.allowance(msg.sender, address(this)) > 0, "insufficient ticket allowed");

        ticket.transferFrom(msg.sender, address(this), 1 * 10 ** 18);
        user_last_box[msg.sender] = new uint[](prizes.length);
        for(uint i = 0; i < prizes.length; i++){
            uint probability = prizes[i].probability;
            if((_randModulus(10000, i) + 1) <= probability){
                // got the token
                uint min = prizes[i].min;
                uint max = prizes[i].max;
                uint rand_num = _randModulus(max, i) + 1;
                uint token_num = min > rand_num ? min : rand_num;

                user_last_box[msg.sender][i] = token_num;
                prizes[i].token.transfer(msg.sender, token_num * 10 ** 18);
            }
        }
        return true;
    }

    function query_account(address addr) public view returns(uint, uint, uint){
        return (
            addr.balance,
            ticket.balanceOf(addr),
            ticket.allowance(addr, address(this))
        );
    }

    function query_last_box(address addr) public view returns(uint[] memory){
        return (user_last_box[addr]);
    }

    //=============================================
    //============= admin function ================
    //=============================================
    function sys_set_ticket(address _ticket_addr) public onlyOwner returns(bool) {
        require(_ticket_addr != address(0), "address is null");
        ticket = ERC20(_ticket_addr);
        return true;
    }

    function sys_add_prizes(address _token_addr, uint _probability, uint _min, uint _max) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_probability > 0, "_probability need great than 0");
        require(_min > 0, "_min need great than 0");
        require(_max > 0, "_max need great than 0");

        Prize memory prize = Prize(ERC20(_token_addr), _token_addr, _probability, _min, _max);
        prizes.push(prize);
        return true;
    }

    function sys_query_prizes(uint index) public view returns(uint, address, uint, uint, uint, uint) {
        return (
            prizes.length,
            prizes[index].addr,
            prizes[index].probability,
            prizes[index].min,
            prizes[index].max,
            prizes[index].token.balanceOf(address(this))
        );
    }

    //=============================================
    //============= private function ==============
    //=============================================
    function _randModulus(uint mod, uint index) internal view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(
                block.number,
                block.timestamp,
                block.difficulty,
                msg.sender,
                index)
            )) % mod;
        return rand;
    }
}