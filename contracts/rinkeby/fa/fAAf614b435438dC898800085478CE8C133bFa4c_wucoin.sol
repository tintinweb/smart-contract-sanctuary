pragma solidity ^0.8.0;

contract wucoin {
    address admin;
    uint max_balance = 10000000;
    uint public price_of_nft = 10000;
    uint public max_nfts = 10;
    uint nonce = 0;
    mapping (address => uint) balance;
    mapping (uint => address) public placeholder_nft;

    constructor() {
        admin = msg.sender;
        balance[admin] = max_balance;
        placeholder_nft[nonce] = admin;
        nonce++;
    }

    function get_admin_address() view external returns (address) {
        return admin;
    }

    function get_max_balance() view external returns (uint) {
        return max_balance;
    }

    function get_address_amount(address _address) view public returns (uint) {
        return balance[_address];
    }

    modifier onlyOwner(address _maybe_owner) {
        require(_maybe_owner == msg.sender);
        _;
    }

    function transfer(address _from, address _to, uint _amount) public onlyOwner(_from) {
        require(_amount <= get_address_amount(_from));
        balance[_from] -= _amount;
        balance[_to] += _amount;
    }

    function burn(address _from, uint _amount) public onlyOwner(_from) {
        transfer(_from, address(0), _amount);
    }

    // There will only be 1000 "NFTs" ever, thus if it hits 1000 then it'll reject it
    modifier _are_we_at_max_nft() {
        require(nonce < max_nfts);
        _;
    }

    function mint_nft(address _caller, uint number_of_nfts) external _are_we_at_max_nft() onlyOwner(_caller) {
        require(get_address_amount(_caller) >= number_of_nfts * price_of_nft);
        require(nonce + number_of_nfts < max_nfts);
        for (uint i = 0; i < number_of_nfts; i++) {
            burn(_caller, price_of_nft);
            placeholder_nft[nonce] = _caller;
            nonce++;
        }
    }

    modifier _is_admin() {
        require(msg.sender == admin);
        _;
    }

    function admin_change_price_of_nfts(uint _price) external _is_admin() {
        price_of_nft = _price;
    }

    function admin_change_max_nfts(uint _num_nfts) external _is_admin() {
        max_nfts = _num_nfts;
    }
}