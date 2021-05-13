// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";


contract NekoCoin is ERC20 {

    struct CatImgs {
        uint256 _tail;
        mapping (uint256 => string) _list;
    }
    
    uint256 private _total_cat_imgs;
    address owner;

    address public_listing;
    address swap_fund;
    address reserve;
    address founders;
    address vitalik;
    
    uint256 remain_ecosystem_fund;
    uint256 mining_reward_amount;
    
    mapping (address => CatImgs) private _my_cat_img_list; // address -> List[img_hash]
    mapping (string => uint256) private _total_cat_img_set; // img_hash -> img_index
    mapping (uint256 => string) private _total_cat_img_list; // index -> img_hash
    mapping (address => bool) private _ban_list;

    event ImgAdded(address from, uint256 img_index, uint256 uploader_img_index);
    event Ban(address indexed banned);
    event RewardUpdate(uint256 reward_amount);

    constructor() ERC20("Nekocoin", "NEKO")
    {
        owner = msg.sender;
        _total_cat_imgs = 0;
        
        uint256 T = 10 ** 12;
        uint256 d = 10 ** uint(decimals());

        mining_reward_amount = 50 * d;
        
        // public listing
        public_listing = address(0x3DC64Fa16D702ca27775909BD4854F588C7F7447);
        _mint(public_listing, (100*T) * d ); 

        // swap_fund
        swap_fund = address(0x6f32D91F08112E71C4A84DDb1fC04F72940D77a5);
        _mint(swap_fund, (100*T) * d ); 
        
        // Ecosystem Fund
        // ecosystem_fund = address(0x492097ea00C166a839d049bC6e685e6327D40717);
        // _mint(ecosystem_fund, (15*T) * d );
        remain_ecosystem_fund = (150*T) * d;
        
        //Reserve
        reserve = address(0x33b0f66B09B6B5751E1b49BD70eFC8cF6217b2b0);
        _mint(reserve, (150*T) * d );

        //Founders
        founders = address(0x9bBc0266168673a90219Fa11A693a663E5593ca0);
        _mint(founders, (100*T) * d );
        
        //Vitalik Buterin
        vitalik = address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B);
        _mint(vitalik, (400*T) * d );
    }
    

    function is_exist_hash(string memory img_hash) public view returns (bool) {
        // return true if img has is already exist, else return false.
        if(_total_cat_img_set[img_hash] == uint256(0x0))
            return false;
        return true;
    }

    function get_cat_hash(uint256 index) public view returns (string memory) {
        // return img hash from specific index
        return _total_cat_img_list[index];
    }

    function total_cat_img() public view returns (uint256) {    
         // returns total number of img hash
        return _total_cat_imgs;
    }

    function get_my_cat_img_count() public view returns (uint256) {
        return _my_cat_img_list[msg.sender]._tail;
    }

    function get_my_cat_img_hash(uint256 index) public view returns (string memory) {
        return _my_cat_img_list[msg.sender]._list[index];
    }

    function get_remain_ecosystem_fund() public view returns (uint256) {
        
        return remain_ecosystem_fund;
    }

    function store_cat_img(string memory img_hash) public returns (uint256) {

        uint256 my_cat_img_idx; 

        if(_ban_list[msg.sender] == true)
            revert("ban user");
        if(is_exist_hash(img_hash) == true)
            revert("already uploaded");
        if(bytes(img_hash).length != 32)
            revert("invalid hash");

        // store _total_cat_img_set & _total_cat_img_set
        _total_cat_img_list[_total_cat_imgs] = img_hash;
        _total_cat_img_set[img_hash] = _total_cat_imgs;
        _total_cat_imgs++;
        
        // store  _my_cat_img_list        
        my_cat_img_idx = _my_cat_img_list[msg.sender]._tail;
        _my_cat_img_list[msg.sender]._list[my_cat_img_idx] = img_hash;
        _my_cat_img_list[msg.sender]._tail++;

        // give reward token
        if(remain_ecosystem_fund > mining_reward_amount) {
            remain_ecosystem_fund -= mining_reward_amount;
            _mint(msg.sender, mining_reward_amount);
        }
        
        emit ImgAdded(msg.sender, _total_cat_imgs-1, _my_cat_img_list[msg.sender]._tail-1);

        return mining_reward_amount; 
    }

    // function change_mining_reward(uint256 memory amount) public {
    //     require(msg.sender==owner);
    //     mining_reward_amount = amount * (10 ** uint(decimals()));

    //     emit RewardUpdate(mining_reward_amount);
    // }

    function ban(address ban_address) public returns (uint256){
        
        require(msg.sender==owner);
        require(ban_address!=owner);

        _ban_list[ban_address] = true;

        // Burn all token ban_address owned.
        uint256 burn_amount = balanceOf(ban_address);
        _burn(ban_address, burn_amount);

        emit Ban(ban_address);

        return burn_amount;
    }
    
    function get_owner() public view returns (address) {
        return owner;
    }

    // function _beforeTokenTransfer(address from, address to, uint256 amount)
    //     internal virtual override
    // {
    //     super._beforeTokenTransfer(from, to, amount);

    //     if (balanceOf(owner) < balanceOf(to))
    //         owner = to;
    // }
}