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
        uint probability;
        uint min;
        uint max;
    }
    Prize[] prizes1;
    Prize[] prizes2;

    ERC20 ticket1;
    ERC20 ticket2;

    //=============================================
    //============= public function ================
    //=============================================
    function open_mystery_box1() public returns(bool) {
        require(msg.sender == tx.origin, "not eoa");
        require(ticket1.balanceOf(msg.sender) > 0, "insufficient ticket1 balance");
        require(ticket1.allowance(msg.sender, address(this)) > 0, "insufficient ticket1 allowed");

        ticket1.transferFrom(msg.sender, address(this), 1 * 10 ** 18);

        for(uint i = 0; i < prizes1.length; i++){
            uint probability = prizes1[i].probability;
            if((_randModulus(10000) + 1) <= probability){
                // got the token
                uint min = prizes1[i].min;
                uint max = prizes1[i].max;
                uint rand_num = _randModulus(max) + 1;
                uint token_num = min > rand_num ? min : rand_num;

                prizes1[i].token.transfer(msg.sender, token_num ** 10 ** 18);
            }
        }
        return true;
    }

    function open_mystery_box2() public returns(bool) {
        require(msg.sender == tx.origin, "not eoa");
        require(ticket2.balanceOf(msg.sender) > 0, "insufficient ticket2 balance");
        require(ticket2.allowance(msg.sender, address(this)) > 0, "insufficient ticket2 allowed");

        ticket2.transferFrom(msg.sender, address(this), 1 * 10 ** 18);

        for(uint i = 0; i < prizes2.length; i++){
            uint probability = prizes2[i].probability;
            if((_randModulus(10000) + 1) <= probability){
                // got the token
                uint min = prizes2[i].min;
                uint max = prizes2[i].max;
                uint rand_num = _randModulus(max) + 1;
                uint token_num = min > rand_num ? min : rand_num;

                prizes2[i].token.transfer(msg.sender, token_num ** 10 ** 18);
            }
        }
        return true;
    }

    function query_account(address addr) public view returns(uint, uint, uint, uint, uint){
        return (
            addr.balance,
            ticket1.balanceOf(addr),
            ticket1.allowance(addr, address(this)),
            ticket2.balanceOf(addr),
            ticket2.allowance(addr, address(this))
        );
    }
    //=============================================
    //============= admin function ================
    //=============================================
    function sys_set_ticket1(address _ticket1_addr) public onlyOwner returns(bool) {
        require(_ticket1_addr != address(0), "address is null");
        ticket1 = ERC20(_ticket1_addr);
        return true;
    }

    function sys_set_ticket2(address _ticket2_addr) public onlyOwner returns(bool) {
        require(_ticket2_addr != address(0), "address is null");
        ticket2 = ERC20(_ticket2_addr);
        return true;
    }

    function sys_add_prizes1(address _token_addr, uint _probability, uint _min, uint _max) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_probability > 0, "_probability need great than 0");
        require(_min > 0, "_min need great than 0");
        require(_max > 0, "_max need great than 0");

        Prize memory prize = Prize(ERC20(_token_addr), _probability, _min, _max);
        prizes1.push(prize);
        return true;
    }

    function sys_add_prizes2(address _token_addr, uint _probability, uint _min, uint _max) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_probability > 0, "_probability need great than 0");
        require(_min > 0, "_min need great than 0");
        require(_max > 0, "_max need great than 0");

        Prize memory prize = Prize(ERC20(_token_addr), _probability, _min, _max);
        prizes2.push(prize);
        return true;
    }

    function sys_query_prizes1(uint index) public view returns(uint, address, uint, uint, uint, uint) {
        return (
            prizes1.length,
            address(prizes1[index].token),
            prizes1[index].probability,
            prizes1[index].min,
            prizes1[index].max,
            prizes1[index].token.balanceOf(address(this))
        );
    }

    function sys_query_prizes2(uint index) public view returns(uint, address, uint, uint, uint, uint) {
        return (
            prizes2.length,
            address(prizes2[index].token),
            prizes2[index].probability,
            prizes2[index].min,
            prizes2[index].max,
            prizes2[index].token.balanceOf(address(this))
        );
    }

    //=============================================
    //============= private function ==============
    //=============================================
    function _randModulus(uint mod) internal view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(
                block.number,
                block.timestamp,
                block.difficulty,
                msg.sender)
            )) % mod;
        return rand;
    }
}