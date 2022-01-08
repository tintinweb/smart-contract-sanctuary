/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.7;

interface ERC20 {
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface BitDNA {
    function binaryDna(uint tokenId) external view returns (string memory);
}

interface PrizesPool {
    function payPrize(address _token_addr, address _to_addr, uint _amount) external returns(bool);
}

contract Ownable {
    address owner;
    constructor() {
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

contract PrisonDungeon is Ownable {
    struct Prize{
        address addr;
        uint probability;
        uint min;
        uint max;
    }
    Prize[] prizes;

    struct MustToken{
        ERC20 token;
        uint min;
    }
    MustToken[] mustTokens;

    struct CoreAttr{
        ERC20 token;
        uint min_attr_value;
    }
    CoreAttr[] coreAttrs;

    mapping(address => uint[]) user_last_adventure;
    mapping(uint => uint) character_last_use;

    uint public price = 1;
    uint public character_cooling_hours = 6;

    ERC20 ticket;
    ERC721 character;
    BitDNA bitdna;
    PrizesPool prizesPool;

    //=============================================
    //============= public function ===============
    //=============================================
    function adventure(uint character_tokenId) public returns(bool) {
        require(msg.sender == tx.origin, "not eoa");
        require(msg.sender == character.ownerOf(character_tokenId), "only owner character NFT can be used");
        require((block.timestamp - character_last_use[character_tokenId]) > character_cooling_hours * 1 hours, "character need cooling");

        uint ticket_amount = price * 10 ** 18;
        if(ticket_amount > 0){
            ticket.transferFrom(msg.sender, address(this), ticket_amount);
        }

        // must token
        for(uint i = 0; i < mustTokens.length; i++){
            uint token_balance = mustTokens[i].token.balanceOf(msg.sender);
            require(token_balance >= mustTokens[i].min * 10 ** 18, "must token balance require");
        }

        // must core attr
        string memory dna = bitdna.binaryDna(character_tokenId);
        for(uint i = 0; i < coreAttrs.length; i++){
            uint token_balance = coreAttrs[i].token.balanceOf(msg.sender);
            uint dna_value = _sub_dna(dna, i * 16, (i + 1) * 16);
            uint dna_attr_value = dna_value % 10;
            uint core_attr_value = dna_attr_value + (token_balance / (10 ** 18));
            require(core_attr_value >= coreAttrs[i].min_attr_value, "core attr value require");
        }

        // pay prizes
        character_last_use[character_tokenId] = block.timestamp;
        user_last_adventure[msg.sender] = new uint[](prizes.length);
        for(uint i = 0; i < prizes.length; i++){
            uint probability = prizes[i].probability;
            if((_random(10000, i) + 1) <= probability){
                uint min = prizes[i].min;
                uint max = prizes[i].max;
                uint rand_num = _random(max, i) + 1;
                uint token_num = min > rand_num ? min : rand_num;

                user_last_adventure[msg.sender][i] = token_num;
                prizesPool.payPrize(prizes[i].addr, msg.sender, token_num * 10 ** 18);
            }
        }
        return true;
    }

    function query_account(address addr, uint character_tokenId) public view returns(uint, uint, uint, uint){
        return (
            ticket.balanceOf(addr),
            ticket.allowance(addr, address(this)),
            block.timestamp - character_last_use[character_tokenId],
            character_cooling_hours
        );
    }

    function query_core_attrs(address addr, uint character_tokenId) public view returns(uint[] memory, uint[] memory){
        uint[] memory min_core_attrs = new uint[](coreAttrs.length);
        uint[] memory user_core_attrs = new uint[](coreAttrs.length);

        string memory dna = bitdna.binaryDna(character_tokenId);
        for(uint i = 0; i < coreAttrs.length; i++){
            uint token_balance = coreAttrs[i].token.balanceOf(addr);
            uint dna_value = _sub_dna(dna, i * 16, (i + 1) * 16);
            uint dna_attr = dna_value % 10;
            uint user_core_attr = dna_attr + (token_balance / (10 ** 18));

            min_core_attrs[i] = coreAttrs[i].min_attr_value;
            user_core_attrs[i] = user_core_attr;
        }
        return (min_core_attrs, user_core_attrs);
    }

    function query_must_tokens(address addr) public view returns(uint[] memory, uint[] memory){
        uint[] memory min_must_tokens = new uint[](mustTokens.length);
        uint[] memory user_must_tokens = new uint[](mustTokens.length);

        for(uint i = 0; i < mustTokens.length; i++){
            uint token_balance = mustTokens[i].token.balanceOf(addr);

            min_must_tokens[i] = mustTokens[i].min;
            user_must_tokens[i] = token_balance;
        }
        return (min_must_tokens, user_must_tokens);
    }

    function query_last_adventure(address addr) public view returns(uint[] memory){
        return (user_last_adventure[addr]);
    }

    //=============================================
    //============= admin function ================
    //=============================================
    function sys_set_prizesPool(address _prizesPool_addr) public onlyOwner returns(bool) {
        require(_prizesPool_addr != address(0), "address is null");
        prizesPool = PrizesPool(_prizesPool_addr);
        return true;
    }

    function sys_set_bitDNA(address _dna_addr) public onlyOwner returns(bool) {
        require(_dna_addr != address(0), "address is null");
        bitdna = BitDNA(_dna_addr);
        return true;
    }

    function sys_set_ticket(address _ticket_addr) public onlyOwner returns(bool) {
        require(_ticket_addr != address(0), "address is null");
        ticket = ERC20(_ticket_addr);
        return true;
    }

    function sys_set_ticket_price(uint _tecket_price) public onlyOwner returns(bool) {
        price = _tecket_price;
        return true;
    }

    function sys_set_character(address _character_addr) public onlyOwner returns(bool) {
        require(_character_addr != address(0), "address is null");
        character = ERC721(_character_addr);
        return true;
    }

    function sys_set_character_cooling_hours(uint _character_cooling_hours) public onlyOwner returns(bool) {
        character_cooling_hours = _character_cooling_hours;
        return true;
    }

    function sys_add_prize(address _token_addr, uint _probability, uint _min, uint _max) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_probability > 0, "_probability need great than 0");
        require(_min > 0, "_min need great than 0");
        require(_max > 0, "_max need great than 0");

        Prize memory prize = Prize(_token_addr, _probability, _min, _max);
        prizes.push(prize);
        return true;
    }

    function sys_set_prize(uint index, address _token_addr, uint _probability, uint _min, uint _max) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_probability > 0, "_probability need great than 0");
        require(_min > 0, "_min need great than 0");
        require(_max > 0, "_max need great than 0");

        Prize memory prize = Prize(_token_addr, _probability, _min, _max);
        prizes[index] = prize;
        return true;
    }

    function sys_query_prizes(uint index) public view returns(uint, address, uint, uint, uint) {
        return (
            prizes.length,
            prizes[index].addr,
            prizes[index].probability,
            prizes[index].min,
            prizes[index].max
        );
    }

    function sys_add_core_attr(address _token_addr, uint _min) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_min > 0, "_min need great than 0");

        CoreAttr memory coreAttr = CoreAttr(ERC20(_token_addr), _min);
        coreAttrs.push(coreAttr);
        return true;
    }

    function sys_set_core_attr(uint index, address _token_addr, uint _min_attr_value) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");

        CoreAttr memory coreAttr = CoreAttr(ERC20(_token_addr), _min_attr_value);
        coreAttrs[index] = coreAttr;
        return true;
    }

    function sys_query_core_attrs(uint index) public view returns(uint, address, uint) {
        return (
            coreAttrs.length,
            address(coreAttrs[index].token),
            coreAttrs[index].min_attr_value
        );
    }

    function sys_add_must_token(address _token_addr, uint _min) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_min > 0, "_min need great than 0");

        MustToken memory mustToken = MustToken(ERC20(_token_addr), _min);
        mustTokens.push(mustToken);
        return true;
    }

    function sys_set_must_token(uint index, address _token_addr, uint _min) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_min > 0, "_min need great than 0");

        MustToken memory mustToken = MustToken(ERC20(_token_addr), _min);
        mustTokens[index] = mustToken;
        return true;
    }

    function sys_query_must_tokens(uint index) public view returns(uint, address, uint) {
        return (
            mustTokens.length,
            address(mustTokens[index].token),
            mustTokens[index].min
        );
    }

    function sys_transfer_token(address _token_addr, address _receive_addr) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_receive_addr != address(0), "address is null");

        ERC20 token = ERC20(_token_addr);
        token.transfer(_receive_addr, token.balanceOf(address(this)));
        return true;
    }

    //=============================================
    //============= private function ==============
    //=============================================
    function _random(uint mod, uint index) internal view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(
                block.number,
                block.timestamp,
                block.difficulty,
                msg.sender,
                index)
            )) % mod;
        return rand;
    }

    function _sub_dna(string memory str, uint startIndex, uint endIndex) internal pure returns (uint) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }

        uint mint = 0;
        uint length = result.length;
        for (uint i = 0; i < length; i++) {
            if (uint(uint8(result[i])) == 49){
                mint += 2 ** (length - i - 1);
            }
        }

        return mint;
    }
}