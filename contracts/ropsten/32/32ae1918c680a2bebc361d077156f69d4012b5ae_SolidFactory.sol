/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// SPDX-License-Identifier: Solid-contract

pragma solidity >=0.7.6;

/*		   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  
                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@               
               @@@@,@@@                                    @@@@@@@@             
             @@@@[email protected]@@                                  @@[email protected]@@@            
            @@@@[email protected]@@                               @@@[email protected]@@@          
           @@@@[email protected]@@,                            @@@[email protected]@@@         
          @@@@[email protected]@@                          @@@[email protected]@@%        
         @@@@[email protected]@@                        @@[email protected]@@@        
         @@@@[email protected]@@                     &@@[email protected]@@*       
         @@@[email protected]@@.                  @@@[email protected]@@@       
         @@@[email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]@@@       
         @@@@[email protected]@@@@@@@@@@@@@@@@@@[email protected]@@.       
         @@@@[email protected]@@///////////@@@[email protected]@@@        
          @@@@[email protected]@@/////////@@@[email protected]@@         
           @@@@[email protected]@@//////@@@[email protected]@@@         
            @@@@[email protected]@@////@@,...................&@@@@          
             @@@@%[email protected]@@/&@@[email protected]@@@            
               @@@@([email protected]@@@@[email protected]@@@@             
                 @@@@@.................,@@[email protected]@@@@@               
                   @@@@@@[email protected]@@@@@                  
                      @@@@@@@@.....................%@@@@@@@                     
                          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@                         
                                 *@@@@@@@@@@@@@@                                
                                                                                
                                                                                */
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    event SellReward(uint amount);
       
    event SellRewardWithTeam(uint amount);
  
    event ResetReward(address indexed to,uint k_reward_accumulated);
 
    event BurnOnSell(address indexed to,uint transfer_amount);

    event MintOnBuy(address indexed to,uint transfer_amount);
   

    event ClaimTeamFee(uint transfer_amount);
  
    event ClaimReward(address indexed to);
 


    event Set_DOMAIN_SEPARATOR(address indexed tokenID);
    
    event ClaimTeamSolid();
    event SolidTransfer(address indexed tokenID,address indexed from,address indexed to,uint amount);
    event SolidPermit(address indexed tokenID, address indexed owner, address indexed spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function reward(address owner) external view returns (uint);
  
    function approve(address spender, uint value) external returns (bool);
 
    function transfer(address to, uint value) external returns (bool);
    
    function transferFrom(address from, address to, uint value) external returns (bool);
    
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function team_accumuluated() external view returns (uint);
 
    function k_reward_accumulated() external view returns (uint);

    function reward_in_pool() external view returns (uint);

    function last_A_volume() external view returns (uint);

    function last_timestamp() external view returns (uint);
 
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);
    
    function nonces(address owner) external view returns (uint);

}

library SafeMath{
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow_256');
    }
    
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow_256');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow_256');
    }
   
    function div(uint x, uint y) internal pure returns (uint z) {
        if (y!=0){
           z = x / y;
        }else{
        z = 0;
        }
    }
}

library Math {

    function calculate_leading_zero(uint x) pure internal returns(uint) {
        uint n = 256;
        uint256 y;
        y = x >> 128; if (y != 0) { n = n - 128; x = y; }
        y = x >> 64; if (y != 0) { n = n - 64; x = y; }
        y = x >> 32; if (y != 0) { n = n - 32; x = y; }
        y = x >> 16; if (y != 0) { n = n - 16; x = y; }
        y = x >> 8; if (y != 0) { n = n - 8; x = y; }
        y = x >> 4; if (y != 0) { n = n - 4; x = y; }
        y = x >> 2; if (y != 0) { n = n - 2; x = y; }
        y = x >> 1; if (y != 0) return n - 2;
        return n - x;
    }
    
    // cubic
    function cubic(uint x) pure internal returns(uint) {
        uint256 r0 = 1;
        uint256 r1;

        //IEEE-754 cbrt *may* not be exact. 

        if (x == 0) // cbrt(0) : 
            return (0);

        uint256 b = (256) - calculate_leading_zero(x);
        r0 <<= (b + 2) / 3; // ceil(b / 3)

        do // quadratic convergence: 
        {
            r1 = r0;
            r0 = (2 * r1 + x / (r1 * r1)) / 3;
        }
        while (r0 < r1);

        return uint96 (r1); // floor(cbrt(x)); 
    }
    
    
    
    function sqrt (uint256 x) internal pure returns (uint128) {
        if (x == 0) return 0;
        else{
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
            if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
            if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
            if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
            if (xx >= 0x100) { xx >>= 8; r <<= 4; }
            if (xx >= 0x10) { xx >>= 4; r <<= 2; }
            if (xx >= 0x8) { r <<= 1; }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128 (r < r1 ? r : r1);
        }
  }
 
    
}



contract SolidFactory is IERC20{
    using SafeMath for uint;
    using SafeMath for uint128;
    
    uint public override team_accumuluated;
    
    uint public override k_reward_accumulated;
    
    uint public override reward_in_pool;
    
    uint public override last_A_volume;
     
    uint public override last_timestamp;
    
    string public override constant name = 'SolidDAI';
    string public override constant symbol = 'SolidDAI';
    uint8 public override constant decimals = 18;
    
    mapping(address => uint) public override reward;

    
    mapping(address => uint) public override balanceOf;

    
    mapping(address => mapping (address => uint)) public override allowance;

    
    bytes32 public override DOMAIN_SEPARATOR;

    
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public override constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    
    mapping(address => uint) public override nonces;
    
    uint public override totalSupply;

    
    bool public feeOn=false;

    
    bytes32 public COPYRIGHT_HASH=0x01c95541db60cee620e2a69baa71ba0b8c059901aa44da15b6e3818e879e851d;
    bool public lock=false;
    bool public control_lock=true;
    
    uint public totalDocument;
    uint public last_team_totalSupply;

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        
        
  
    }
    
   
    function set_DOMAIN_SEPARATOR(address tokenID) external{

        require(totalSupply==0);
        uint chainId;
        assembly {
        chainId := chainid()
        }
        //string memory solid_token= string(abi.encodePacked('Solid-',IERC20(tokenID).name()));
         DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(abi.encodePacked(tokenID)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        totalSupply=10000;
        balanceOf[address(this)]=10000;

        emit Set_DOMAIN_SEPARATOR(tokenID);
     
    }

 
    function mintOnBuy(address tokenID,address payable to,uint amount0,uint amount1) public returns (uint){
        string memory _name = IERC20(tokenID).name();
        uint _totalSupply = totalSupply;
        require(_totalSupply>0,string(abi.encodePacked('Not initialized ',_name)));
        require(IERC20(tokenID).balanceOf(msg.sender)>= amount0, string(abi.encodePacked('Not enough ', _name)));
        
        //Transfer token to contract
        IERC20(tokenID).transferFrom(msg.sender,address(this),amount0);

        uint temp_x=IERC20(tokenID).balanceOf(address(this)).sub(reward_in_pool).mul(3);
        //Calculate amount in solid
        uint amount = Math.cubic(temp_x.mul(temp_x).div(4)).mul(10**6).sub(_totalSupply);
        
        require(amount1<=amount, string(abi.encodePacked('Slippage on buy Solid-', _name ,' blocked')));
        
        //Mint solid to address
        _mint(to,amount);

        emit MintOnBuy(to,amount0);
        return amount;
    }

    function burnOnSell(address tokenID,address payable to,uint amount0,uint amount1) public{
        string memory _name = IERC20(tokenID).name();
        require(balanceOf[msg.sender]>= amount0, string(abi.encodePacked('Not enough Solid-', _name)));
        
        uint _balanceOf = IERC20(tokenID).balanceOf(address(this));
        
        uint after_sell = totalSupply.sub(amount0);
        uint128 cub_sq_0 = Math.sqrt(after_sell.mul(after_sell).div(10**14).mul(after_sell));
        uint amount = _balanceOf.sub(cub_sq_0.mul(2).div(300).add(reward_in_pool));
        
        require (amount1<=amount, string(abi.encodePacked('Slippage on sell Solid-', _name , ' blocked')));

        uint delta_time = block.timestamp-last_timestamp;
        
        //Gas saving
        uint _last_A_volume = last_A_volume;
        
        //Must divide to converge
        _last_A_volume = delta_time < 1800 ? (_last_A_volume.mul(1800-delta_time)+amount.mul(delta_time)).div(1800) : amount;

        //Check if 24hr Volume is more than market cap
        uint reward_rate = _last_A_volume.mul(48).div(_balanceOf) < 1 ? _last_A_volume.mul(960000000).div(_balanceOf) : 20000000;
        
        //Update timestamp
        last_timestamp = block.timestamp;
        
        //Update last_price
        last_A_volume = _last_A_volume;
        
        //Calculate amount to transfer in token
        uint reward_fee = amount.div(100000000).mul(reward_rate);
        uint transfer_amount = amount.sub(reward_fee);
        
        //Development team fee if on
        if (feeOn){
            _sellRewardWithTeam(reward_fee);
        }
        else{
            _sellReward(reward_fee);
        }
        
        //Burn solid from address
        _burn(msg.sender,amount0);
        
        //Transfer
        IERC20(tokenID).transfer(to,transfer_amount);
        emit BurnOnSell(to,transfer_amount);
    }
    
    function _resetReward(address to) internal{
        //Gas saving
        uint _k_reward_accumulated = k_reward_accumulated;
        reward[to]=_k_reward_accumulated;
        emit ResetReward(to,_k_reward_accumulated);
    }
    
    function claimReward(address payable to) public {
        //Gas saving
        uint _stakedbalance = balanceOf[to];
        uint _reward = reward[to];
        uint _k_reward_accumulated = k_reward_accumulated;
            
        uint reward_calculated = _k_reward_accumulated.sub(_reward).mul(_stakedbalance).div(10**24);
        to.transfer(reward_calculated);
        reward_in_pool = reward_in_pool.sub(reward_calculated);
        _resetReward(to);
        emit ClaimReward(to);
    }
    
    function _sellReward(uint amount) internal{
        k_reward_accumulated = k_reward_accumulated.add(amount.mul(10**24).div(totalSupply));
        reward_in_pool = reward_in_pool.add(amount);
        emit SellReward(amount);
    }
    
    function _sellRewardWithTeam(uint amount) internal{
        uint team_fee=amount.div(5);
        uint reward_for_pool = amount-team_fee;
        team_accumuluated= team_accumuluated.add(team_fee);
            
        k_reward_accumulated = k_reward_accumulated.add(reward_for_pool.mul(10**24).div(totalSupply));
        reward_in_pool = reward_in_pool.add(amount);
        emit SellRewardWithTeam(amount);
    }

   
    function _mint(address to, uint amount) internal {
        totalSupply = totalSupply.add(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        emit Transfer(address(0), to, amount);
    }
    
   

    function _burn(address from, uint amount) internal {
        balanceOf[from] = balanceOf[from].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
    }
    
   
    function _approve(address owner, address spender, uint amount) private {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  
    
    function _transfer(address from, address to, uint amount) private {
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        emit Transfer(from, to, amount);
    }
    
    
   
    
    function approve(address spender, uint amount) override external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    

  
    function transfer(address to, uint amount) override external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

   
    
    function transferFrom(address from, address to, uint amount) override public returns (bool) {

        allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        
        _transfer(from, to, amount);
        return true;
    }
   
    
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) override public {
        require(deadline >= block.timestamp, 'Solid: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Solid: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
    
    
   
}