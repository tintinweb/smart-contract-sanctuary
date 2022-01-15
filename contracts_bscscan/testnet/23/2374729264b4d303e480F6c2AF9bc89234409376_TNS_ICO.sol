/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-04
*/

pragma solidity 0.4.25;

contract TNS_ICO {
    using SafeMath for uint256;
    

    IBEP20 public token;

    struct Player {
        address upline;
        uint256 match_bonus;

        uint256 total_ivested_in_token;
        uint256 total_tokens_transferred;
        uint256 total_match_bonus;
        mapping(uint8 => uint256) structure;
    }

   
    address public owner;
 

    uint256 public total_sale;
    uint256 public total_token_distributed;
    uint256 public total_match_bonus;
    uint256 public bnb_per_token =  40; // X -> 1000000 //BNB//0.02cent//according to 1BNB = 500 USD;
    uint256 public min_purchase = 1000; // 100 TNS
    uint256 public xFactor = 1000000;
  


    uint8[] public ref_bonuses; 

    
    mapping(address => Player) public players;
    constructor(IBEP20 tokenAdd) public {
        owner = msg.sender;
        token = tokenAdd;

        ref_bonuses.push(10);
        ref_bonuses.push(40);
        ref_bonuses.push(20);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
    }

   

    
    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;

            uint256 bonus = _amount * ref_bonuses[i] / 1000;
            token.transfer(up,bonus);
            players[up].total_match_bonus += bonus;

            total_match_bonus += bonus;
            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0)) {
            if(players[_upline].total_ivested_in_token == 0) {
                _upline = owner;
            }

            players[_addr].upline = _upline;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                players[_upline].structure[i]++;
                _upline = players[_upline].upline;
                
            }
        }
    }

    function buyToken(address _upline) external payable {

        uint256 min_amt = min_purchase.mul(bnb_per_token).div(xFactor);
        require(msg.value >= min_amt, "Less then the  minimum amount");
        Player storage player = players[msg.sender];
        _setUpline(msg.sender, _upline);
        uint256 token_to_be_transfer = msg.value.div(bnb_per_token).div(xFactor);
        token.transfer(msg.sender,token_to_be_transfer);

 
        player.total_ivested_in_token +=msg.value;

       player.total_tokens_transferred +=  token_to_be_transfer;



        total_sale += msg.value;
        total_token_distributed += token_to_be_transfer;
    

        _refPayout(msg.sender, token_to_be_transfer);


    }
    
   

    function ForLiquidity(uint256 amount) public{
        require(msg.sender==owner,'Permission denied');
        msg.sender.transfer(amount);
    }


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 total_ivested_in_token, uint256 total_tokens_transferred, uint256 _total_match_bonus,uint256[] memory structure) {
        Player storage player = players[_addr];

         uint256[] memory _structure = new uint256[](ref_bonuses.length);

    

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            _structure[i] = player.structure[i];
        }

        return (
            player.total_ivested_in_token,
            player.total_tokens_transferred,
            player.total_match_bonus,
            _structure
        );
    }

  
    

    function contractInfo() view external returns(uint256 _total_sale, uint256 _total_token_distributed, uint256 _total_match_bonus) {
        return (total_sale, total_token_distributed, total_match_bonus);
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}