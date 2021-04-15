/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/*
    RH Style Guide:
        ContractsAndDataStructures
        member_variables_
        _argument_variables
        local_variable
        struct_member_variable
        functionNames
        SOME_CONSTANT
        
        
        lhs_ = _rhs;
        
        _lhs == rhs_
*/
abstract
contract EIP20Interface {
    function total_supply()
        external view virtual returns (uint256);
    function balanceOf(address _owner)
        external view virtual returns (uint256 balance);
    function allowance(address _owner, address _spender)
        external view virtual returns (uint256 remaining);

    function transfer(address _to, uint256 _value)
        external virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)
        external virtual returns (bool success);
    function approve(address _spender, uint256 _value)
        external virtual returns (bool success);
    
    function symbol() external virtual returns ( string memory );


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Presale
{

    function sink() external payable returns (bool)
    {
        return true;
    }

    // this is to pick up any rounding error amounts left over
    function drain() external returns (bool success)
    {
        require(enabled_, "Not currently enabled");
        bool is_member = false;
        
        for (uint i = 0; i < members_.length; ++i)
        {
            if (members_[i] == msg.sender)
            {
                is_member = true;
                break;
            }
        }        
        
        require(is_member, "members only");
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }


    function disable() external returns (bool)
    {
        require(enabled_, "Not currently enabled");
        bool is_member = false;
        
        for (uint i = 0; i < members_.length; ++i)
        {
            if (members_[i] == msg.sender)
            {
                is_member = true;
                break;
            }
        }
        require(is_member, "members only");
        enabled_ = false;
        return true;
    }
    

    function isEnabled() external view returns (bool)
    {
        return enabled_;
    }

    function enable() external returns (bool)
    {
        require(!enabled_, "Already enabled");
        bool is_member = false;
        
        for (uint i = 0; i < members_.length; ++i)
        {
            if (members_[i] == msg.sender)
            {
                is_member = true;
                break;
            }
        }
        require(is_member, "members only");        
        uint256 share = ((presale_coins_total_ - presale_amount_sold_) + (airdrop_coins_total_ - airdrop_amount_sold_)) / members_.length;
        for (uint i = 0; i < members_.length; ++i)
        {
            require(uniwarp_.allowance(members_[i], address(this)) >= share, "not all members have committed funds");
        }
        enabled_ = true;
        return true;
    }
    
    
    function airdropEligible(address x, bytes32 r, bytes32 s, uint8 v) public pure returns (bool)
    {
       return ecrecover(bytes32(uint256(uint160(x))), v, r, s) == address(0xa1b177DD684d5Ab24c95cc25e19d32602A344edC);
    }

    
    function claimAirdrop(bytes32 r, bytes32 s, uint8 v) external returns (bool)
    {
        require(enabled_, "not enabled");
        require(airdropEligible(msg.sender, r,s,v), "cant claim");
        require(!airdropClaimed_[msg.sender], "already claimed");
        require(airdrop_amount_sold_ + airdrop_per_address_ <= airdrop_coins_total_, "airdrop over");
        
        airdropClaimed_[msg.sender] = true;

        uint256 share_tokens = airdrop_per_address_ / members_.length;    // each member's share to send

        for (uint i = 0; i < members_.length; ++i)
        {
            require(uniwarp_.transferFrom(members_[i], msg.sender, share_tokens), "xfer failed");
            airdrop_amount_sold_ += share_tokens;
        }

        return true;
    }
    
    
    function computePresalePrice(
        uint256 _amount_to_buy) public view returns (uint256)
    {
        return (((gradient_ * presale_amount_sold_) / (10**18) ) + (((gradient_ *  _amount_to_buy)>>1) / (10**18))  + presale_start_price_);
    }    
    
    function buyPresale(uint256 _amount_to_buy) external payable returns (bool)
    {
        require(enabled_, "not enabled");
        require(msg.value > members_.length * 10**9, "less than minimum purchase");
        require(presale_amount_sold_ + _amount_to_buy <= presale_coins_total_ , "not enough presale tokens left to buy that many");
        
        uint256 a = computePresalePrice(_amount_to_buy);
        uint256 needed = (a * _amount_to_buy);
        uint256 b = msg.value*(10**18);
        
        
        require(a < needed);
        require(msg.value < b);
        require (b >= needed, "you didn't pay enough to buy that many");

        
        uint256 share_tokens = _amount_to_buy / members_.length;    // each member's share to send
        uint256 share_bnb = msg.value / members_.length;            // each member's share to receive
        
        for (uint i = 0; i < members_.length; ++i)
        {
            require(uniwarp_.transferFrom(members_[i], msg.sender, share_tokens), "xfer failed");
            payable(members_[i]).transfer(share_bnb);
            presale_amount_sold_ += share_tokens;
        }
        
        return true;
    }
    

    

    uint256 gradient_ = 0;
    

    uint256 airdrop_per_address_ = 0;

    uint256 presale_amount_sold_ = 0;
    uint256 airdrop_amount_sold_ = 0;
    
    uint256 presale_coins_total_ = 0;    // contributed presale coins total (spit across members)
    uint256 airdrop_coins_total_ = 0;    // contributed airdrop coins total (split across members)
    
    uint256 presale_start_price_ = 0;
    
    mapping (address => bool) private airdropClaimed_;
    EIP20Interface private uniwarp_  = EIP20Interface(address(0x0));// = 0x117db2f9449016350c706f8d9f40c67e2cf3f5a4;
    
    address[] private members_;
    bool enabled_ = false;
    
           
    constructor
    (
        address _uniwarp,
        uint256 _presale_coins_each,    // the coins contributed for presale
        uint256 _airdrop_coins_each,    // the coins contributed for airdrop
        uint256 _airdrop_per_address,   // the coins awarded to the airdropees
        uint256 _presale_start_price,   // lowest price to sell for
        uint256 _presale_end_price,     // highest price to sell for
        address[] memory _members
    )
    {
        require(_presale_coins_each > 0, "specify how many coins for presale");
        require(_airdrop_coins_each > 0, "specify how many coins for airdrop");
        require(_members.length > 0, "must have at least one member");
        string memory n = EIP20Interface(_uniwarp).symbol();
        require(keccak256(bytes("UWR")) == keccak256(bytes(n)), "not uniwarp contract");
        uniwarp_ = EIP20Interface(_uniwarp);
        
        presale_start_price_ = _presale_start_price;

        airdrop_coins_total_ = _airdrop_coins_each * _members.length;
        presale_coins_total_ = _presale_coins_each * _members.length;
        
        airdrop_per_address_ = _airdrop_per_address;
        
        gradient_ = ((10**18)*(_presale_end_price - _presale_start_price)) / presale_coins_total_;

        require(gradient_ > 0, "invalid start/end price");
        
        members_ = _members;
    }
}