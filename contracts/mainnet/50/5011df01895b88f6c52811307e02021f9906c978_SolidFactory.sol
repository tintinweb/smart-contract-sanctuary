/**
 *Submitted for verification at Etherscan.io on 2021-02-14
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
    event ApprovalEth(address indexed owner, address indexed spender, uint value);
    event ApprovalMulti(address indexed tokenID,address indexed owner, address indexed spender, uint value);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event TransferEth(address indexed from, address indexed to, uint value);
    event TransferMulti(address indexed tokenID,address indexed from, address indexed to, uint value);
    
    event SellRewardEth(uint amount);
    event SellRewardMulti(address indexed tokenID,uint amount);
        
    event SellRewardEthWithTeam(uint amount);
    event SellRewardMultiWithTeam(address indexed tokenID,uint amount);
    
    event ResetRewardEth(address indexed to,uint k_reward_accumulated);
    event ResetRewardMulti(address indexed to,address indexed tokenID,uint k_reward_accumulated);
    
    event BurnOnSellEth(address indexed to,uint transfer_amount);
    event BurnOnSellMulti(address indexed tokenID,address indexed to,uint transfer_amount);
    
    event MintOnBuyEth(address indexed to,uint transfer_amount);
    event MintOnBuyMulti(address indexed tokenID,address indexed to,uint transfer_amount);
    
    event StakeEth(address indexed to,uint stake_amount);
    event StakeMulti(address indexed tokenID,address indexed to,uint stake_amount);
    
    event UnstakeEth(address indexed from,uint unstake_amount);
    event UnstakeMulti(address indexed tokenID,address indexed from,uint unstake_amount);
    
    event ClaimTeamFeeEth(uint transfer_amount);
    event ClaimTeamFeeMulti(address indexed tokenID,uint transfer_amount);
    
    event ClaimRewardEth(address indexed to);
    event ClaimRewardMulti(address indexed tokenID,address indexed to);
    
    event ChangeFeeStatus(bool value, string input,bytes32 next);
    event ChangeTeamAddress(address indexed to,string input,bytes32 next);
    
    event CheckTeamAddressUpdate(address indexed to, string input,bytes32 next);
    event RecoverTeamAddresshash(string input,bytes32 next,bytes32 hash);
    event Set_DOMAIN_SEPARATOR_Multi(address indexed tokenID);
    
    event ClaimTeamSolid();
    event SolidTransfer(address indexed tokenID,address indexed from,address indexed to,uint amount);
    event SolidPermit(address indexed tokenID, address indexed owner, address indexed spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint);
    function totalSupply_eth() external view returns (uint);
    function totalSupply_multi(address tokenID) external view returns (uint);

    function balanceOf(address owner) external view returns (uint);
    function balanceOf_eth(address owner) external view returns (uint);
    function balanceOf_multi(address tokenID,address owner) external view returns (uint);
    
    function allowance(address owner, address spender) external view returns (uint);
    function allowance_eth(address owner, address spender) external view returns (uint);
    function allowance_multi(address tokenID,address owner, address spender) external view returns (uint);
    
    function reward_eth(address owner) external view returns (uint);
    function reward_multi(address tokenID,address owner) external view returns (uint);
    
    function approve(address spender, uint value) external returns (bool);
    function approveEth(address spender, uint value) external returns (bool);
    function approveMulti(address tokenID,address spender, uint value) external returns (bool);
    
    function transfer(address to, uint value) external returns (bool);
    function transferEth(address to, uint value) external returns (bool);
    function transferMulti(address tokenID,address to, uint value) external returns (bool);
    
    function transferFrom(address from, address to, uint value) external returns (bool);
    function transferFromEth(address from, address to, uint value) external returns (bool);
    function transferFromMulti(address tokenID,address from, address to, uint value) external returns (bool);
    
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function permitEth(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function permitMulti(address tokenID,address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    function team_accumuluated_eth() external view returns (uint);
    function team_accumuluated_multi(address tokenID) external view returns (uint);
    
    function k_reward_accumulated_eth() external view returns (uint);
    function k_reward_accumulated_multi(address tokenID) external view returns (uint);
    
    function reward_in_pool_eth() external view returns (uint);
    function reward_in_pool_multi(address tokenID) external view returns (uint);
    
    function last_A_volume_eth() external view returns (uint);
    function last_A_volume_multi(address tokenID) external view returns (uint);
    
    function last_timestamp_eth() external view returns (uint);
    function last_timestamp_multi(address tokenID) external view returns (uint);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function DOMAIN_SEPARATOR_eth() external view returns (bytes32);
    function DOMAIN_SEPARATOR_multi(address tokenID) external view returns (bytes32);
    
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    
    function nonces(address owner) external view returns (uint);
    function nonces_eth(address owner) external view returns (uint);
    function nonces_multi(address tokenID,address owner) external view returns (uint);

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
    
    uint public override team_accumuluated_eth;
    mapping(address => uint) public override team_accumuluated_multi;
    
    uint public override k_reward_accumulated_eth;
    mapping(address => uint) public override k_reward_accumulated_multi;
    
    uint public override reward_in_pool_eth;
    mapping(address => uint) public override reward_in_pool_multi;
    
    uint public override last_A_volume_eth;
    mapping(address => uint) public override last_A_volume_multi;
     
    uint public override last_timestamp_eth;
    mapping(address => uint) public override last_timestamp_multi;
    
    string public override constant name = 'Solid';
    string public override constant symbol = 'Solid';
    uint8 public override constant decimals = 18;
    
    mapping(address => uint) public override reward_eth;
    mapping(address => mapping(address => uint)) public override reward_multi;
    
    mapping(address => uint) public override balanceOf;
    mapping(address => uint) public override balanceOf_eth;
    mapping(address => mapping(address => uint)) public override balanceOf_multi;
    
    mapping(address => mapping (address => uint)) public override allowance;
    mapping(address => mapping (address => uint)) public override allowance_eth;
    mapping(address => mapping (address => mapping(address => uint))) public override allowance_multi;
    
    bytes32 public override DOMAIN_SEPARATOR;
    bytes32 public override DOMAIN_SEPARATOR_eth;
    mapping(address => bytes32) public override DOMAIN_SEPARATOR_multi;
    
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public override constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    
    mapping(address => uint) public override nonces;
    mapping(address => uint) public override nonces_eth;
    mapping(address => mapping(address => uint)) public override nonces_multi;
    
    
    uint public override totalSupply;
    uint public override totalSupply_eth=10000;
    mapping(address => uint) public override totalSupply_multi;
    
    
    mapping(address => uint) public stakedBalanceOf_eth;
    mapping(address => mapping(address => uint)) public stakedBalanceOf_multi;
    
    uint public stakedBalanceTotal_eth=10000;
    mapping(address => uint) public stakedBalanceTotal_multi;
    
    bool public feeOn=false;
    address payable public team_address=0x2B6C7F44DD5A627496A92FDB12080162e368aB1E;
    address payable public team_address2=0x734241200496E2962b1e2553e5b4FeB99347E1d0;
    
    uint public team_address_last_update=block.timestamp;
    uint public team_address2_last_update=block.timestamp;
    
    bytes32 public team_address_hash=0x2d099065a6fdb19f19491af2da6a20c1343fd4a361f0f5e3c3ee9c5830089f07;
    bytes32 public team_address2_hash=0x17811f390c0b53824cf72860f1790e2219f448470e8e4a61ae9da075530172df;
    
    bytes32 public team_address_recover_hash=0xe304aa923d29816f762747dd9af1eb12a6db979a5e4b4894c28ddd3292986a6e;
    bytes32 public team_address2_recover_hash=0xfffeaf54ace025ecdfd417121e996c49fe9d4c8ee5771cc72de5cb92997aa7c7;
    
    bytes32 public COPYRIGHT_HASH=0x01c95541db60cee620e2a69baa71ba0b8c059901aa44da15b6e3818e879e851d;
    bool public lock=false;
    bool public control_lock=true;
    
    uint public totalDocument;
    uint public last_team_totalSupply;
    struct document_hash{
        uint id;
        //document hash
        bytes32 hash;
        // class journals, transactions, letters, and magazine, contract
        uint8 para0;
        // topic class computer science/biology/chemistry
        uint8 para1;
        // sub class blockchain/big data
        uint8 para2;
        // sub-sub class algorithm-based/application-based(optional)
        uint8 para3;
        //reference
        bytes32 para4;
        //keyword relevant
        bytes32 para5;
    }
    mapping(address => document_hash[]) public document;
    mapping(uint => address) public document_id;
    
    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );

        
        DOMAIN_SEPARATOR_eth = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes('ETH')),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );

        stakedBalanceOf_eth[team_address]=5000;
        stakedBalanceOf_eth[team_address2]=5000;
  
    }
    
    function addPaper(bytes32 _paper_hash,uint8 para0, uint8 para1, uint8 para2,uint8 para3,bytes32 para4,bytes32 para5) public {
        uint _totalDocument = totalDocument;
        document[msg.sender].push(document_hash(_totalDocument,_paper_hash,para0,para1,para2,para3,para4,para5));
        document_id[_totalDocument] = msg.sender;
        totalDocument = _totalDocument.add(1);
        
    }
    function solidAddPaper(bytes32 _paper_hash,uint8 para0, uint8 para1, uint8 para2,uint8 para3,bytes32 para4,bytes32 para5) external {
        uint current_gas = gasleft();
        require(msg.sender==tx.origin);
        addPaper(_paper_hash, para0, para1, para2, para3, para4, para5);
        current_gas = (current_gas - gasleft()+32908)*tx.gasprice;
        totalSupply=totalSupply.add(current_gas);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(current_gas);
    }
    
    
    function asciiToUint(byte char) internal pure returns (uint) {
        uint asciiNum = uint(uint8(char));
        if (asciiNum > 47 && asciiNum < 58) {
            return asciiNum - 48;
        } else if (asciiNum > 96 && asciiNum < 103) {
            return asciiNum - 87;
        } else {
            revert();
        }
    }

    function stringToBytes32(string memory str) internal pure returns (bytes32) {
        bytes memory bString = bytes(str);
        uint uintString;
        if (bString.length != 64) { revert(); }
        for (uint i = 0; i < 64; i++) {
            uintString = uintString*16 + uint(asciiToUint(bString[i]));
        }
        return bytes32(uintString);
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++){
            result[i-startIndex] = strBytes[i];
        }
    
        return string(result);
    }
    
    function reverseHashChain(string memory k,bool input) external {
        bytes memory temp = bytes(k);
        require (msg.sender==team_address && keccak256(temp)==COPYRIGHT_HASH);
        uint length = temp.length;
        string memory hashstring = substring(k,length-64,length);
        COPYRIGHT_HASH = stringToBytes32(hashstring);
        lock=input;
         
     }
     
    function unlockUpon() external{
        require (msg.sender==team_address && lock);
        lock=false;
        
    }
    
    function set_DOMAIN_SEPARATOR_Multi(address tokenID) external{

        require(totalSupply_multi[tokenID]==0);
        uint chainId;
        assembly {
        chainId := chainid()
        }
        //string memory solid_token= string(abi.encodePacked('Solid-',IERC20(tokenID).name()));
         DOMAIN_SEPARATOR_multi[tokenID] = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(abi.encodePacked(tokenID)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        totalSupply_multi[tokenID]=10000;
        stakedBalanceOf_multi[tokenID][team_address]=5000;
        stakedBalanceOf_multi[tokenID][team_address2]=5000;
        stakedBalanceTotal_multi[tokenID]=10000;
        emit Set_DOMAIN_SEPARATOR_Multi(tokenID);

        
    }
    
    function recoverTeamAddresshash(string memory input,bytes32 hash,bytes32 next) external{
        if (msg.sender==team_address && keccak256(bytes(input))==team_address_recover_hash){
            team_address_hash = hash;
            team_address_recover_hash = next;
            
        }
        else if(msg.sender==team_address2 && keccak256(bytes(input))==team_address2_recover_hash){
            team_address2_hash = hash;
            team_address2_recover_hash = next;
        }
        emit RecoverTeamAddresshash(input,next,hash);
    }
    function checkTeamAddressUpdate(address payable to, string memory input,bytes32 next) external{
     
        if (msg.sender==team_address && keccak256(bytes(input))==team_address_hash){
            uint time_delta = block.timestamp-team_address2_last_update;
            if (time_delta>63072000){
                team_address2 = to;
                team_address2_last_update = block.timestamp;
                team_address2_hash = next;
                team_address2_recover_hash = next;
            }
            else{
                team_address_last_update = block.timestamp;
            }
            team_address_hash = next;
        }
        else if(msg.sender==team_address2 && keccak256(bytes(input))==team_address2_hash){
            uint time_delta = block.timestamp-team_address_last_update;
            if (time_delta>63072000){
                team_address = to;
                team_address_last_update = block.timestamp;
                team_address_hash = next;
                team_address_recover_hash = next;
            }
            else{
                team_address2_last_update = block.timestamp;
            }
            team_address2_hash = next;
        }
      emit CheckTeamAddressUpdate(to,input,next);
    }
    function changeTeamAddress(address payable to, string memory input,bytes32 next) external{
        if (msg.sender==team_address && keccak256(bytes(input))==team_address_hash){
            team_address = to;
            team_address_hash = next;
        }
        else if (msg.sender==team_address2 && keccak256(bytes(input))==team_address2_hash){
            team_address2 = to;
            team_address2_hash = next;
        }
        emit ChangeTeamAddress(to,input,next);
    }
    
    
    function changeFeeStatus(bool value, string memory input,bytes32 next) external{
        if (msg.sender==team_address && keccak256(bytes(input))==team_address_hash){
            feeOn = value;
            team_address_hash = next;
        }else if (msg.sender==team_address2 && keccak256(bytes(input))==team_address2_hash){
            feeOn = value;
            team_address2_hash = next;
        }
        
        emit ChangeFeeStatus(value,input,next);
    }
    
    function claimTeamSolid() external{
        require((msg.sender==team_address|| msg.sender==team_address2) && !lock);
        uint _totalSupply = totalSupply;
        uint SupplyDelta = _totalSupply.sub(last_team_totalSupply).div(18);
        balanceOf[team_address] = balanceOf[team_address].add(SupplyDelta);
        balanceOf[team_address2] = balanceOf[team_address2].add(SupplyDelta);
        _totalSupply = _totalSupply.add(SupplyDelta.mul(2));
        last_team_totalSupply = _totalSupply;
        totalSupply = _totalSupply;
        emit ClaimTeamSolid();
    }
    function claimTeamFeeEth(uint amount) external{
        require((msg.sender==team_address|| msg.sender==team_address2) && !lock);
        //gas saving
        team_accumuluated_eth=team_accumuluated_eth.sub(amount);
        reward_in_pool_eth=reward_in_pool_eth.sub(amount);
        uint half = amount.div(2);
        team_address.transfer(amount.sub(half));
        team_address2.transfer(half);
        emit ClaimTeamFeeEth(amount);
    }
    
    function claimTeamFeeMulti(address tokenID,uint amount) external{
        require((msg.sender==team_address|| msg.sender==team_address2) && !lock);
        //gas saving
        team_accumuluated_multi[tokenID]=team_accumuluated_multi[tokenID].sub(amount);
        reward_in_pool_multi[tokenID]=reward_in_pool_multi[tokenID].sub(amount);
        uint half = amount.div(2);
        IERC20(tokenID).transfer(team_address,amount.sub(half));
        IERC20(tokenID).transfer(team_address2,half);
        emit ClaimTeamFeeMulti(tokenID,amount);
    }
    
    function solidWrapper(uint8 choice, address tokenID, address payable to,uint amount0,uint amount1) external payable {
        uint current_gas = gasleft();
        require(msg.sender==tx.origin);
        if (choice==0){
            mintOnBuyEth(to, amount0, amount1);
        }
        else if (choice==1){
            mintOnBuyMulti(tokenID,to, amount0, amount1);
        }
        else if (choice==2){
            burnOnSellEth(to, amount0, amount1);
        }
        else if (choice==3){
            burnOnSellMulti(tokenID,to, amount0, amount1);
        }
        else if (choice==4){
            claimRewardEth(to);
        }
        else if (choice==5){
            claimRewardMulti(tokenID,to);
        }
        else if (choice==6){
            stakeEth(to,amount0);
        }
        else if (choice==7){
            stakeMulti(tokenID,to,amount0);
        }
        else if (choice==8){
            unstakeEth(to,amount0);
        }
        else if (choice==9){
            unstakeMulti(tokenID,to,amount0);
        }
        else if (choice==10){
            buyStakeEth(to,amount0,amount1);
        }
        else if (choice==11){
            buyStakeMulti(tokenID,to,amount0,amount1);
        }
        else if (choice==12){
            unstakeSellEth(to,amount0,amount1);
        }
        else if (choice==13){
            unstakeSellMulti(tokenID,to,amount0,amount1);
        }
        else if (choice==14){
            _approve(msg.sender,to,amount0);
        }
        else if (choice==15){
            _approveEth(msg.sender,to,amount0);
        }
        else if (choice==16){
            _approveMulti(tokenID,msg.sender,to,amount0);
        }
        else if (choice==17){
             _transfer(msg.sender, to, amount0);
        }
        else if (choice==18){
            _transferEth(msg.sender, to, amount0);
        }
        else if (choice==19){
            _transferMulti(tokenID,msg.sender, to, amount0);
        }
        else if (choice==20){
            transferFrom(msg.sender, to, amount0);
        }
        else if (choice==21){
            transferFromEth(msg.sender, to, amount0);
        }
        else if (choice==22){
            transferFromMulti(tokenID,msg.sender, to, amount0);
        }
        else if(choice==23){
            IERC20(tokenID).transferFrom(msg.sender,to,amount0);
            emit SolidTransfer(tokenID,msg.sender,to,amount0);
        }
        else if(choice==24){
            ClaimTeamSolid();
        }
        else if(choice==25){
            ClaimTeamFeeEth(amount0);
        }
        else if(choice==26){
            ClaimTeamFeeMulti(tokenID,amount0);
        }
        
        current_gas = (current_gas - gasleft()+32908)*tx.gasprice;
        totalSupply=totalSupply.add(current_gas);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(current_gas);

    }
    function solidPermit(uint8 choice,address tokenID, address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external{
        uint current_gas = gasleft();
        require(msg.sender==tx.origin);
        if (choice==0){
            permit(owner,spender, value, deadline, v,r,s);
        }
        else if (choice==1){
            permitEth(owner,spender, value, deadline, v,r,s);
        }
        else if (choice==2){
            permitMulti(tokenID, owner,spender, value, deadline, v,r,s);
        }
        else if (choice==3){
            IERC20(tokenID).permit(owner,spender,value,deadline,v,r,s);
            emit SolidPermit(tokenID,owner,spender, value, deadline, v,r,s);
        }
        current_gas = (current_gas - gasleft()+32908)*tx.gasprice;
        totalSupply=totalSupply.add(current_gas);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(current_gas);
    
    }
    function mintOnBuyEth(address payable to,uint amount0,uint amount1) public payable returns (uint){
        require(msg.value == amount0, "ETH sent not equal to input amount");
 
        uint temp_x=address(this).balance.sub(reward_in_pool_eth).mul(3);
        //Calculate amount in solid
        uint amount = Math.cubic(temp_x.mul(temp_x).div(4)).mul(10**6).sub(totalSupply_eth);
        
        require(amount1<=amount, 'Slippage on buy Solid-ETH blocked');
     
        //Mint solid to address
        _mintEth(to,amount);

        emit MintOnBuyEth(to,amount0);
        return amount;
    }
    
    function mintOnBuyMulti(address tokenID,address payable to,uint amount0,uint amount1) public returns (uint){
        string memory _name = IERC20(tokenID).name();
        uint _totalSupply_multi = totalSupply_multi[tokenID];
        require(_totalSupply_multi>0,string(abi.encodePacked('Not initialized ',_name)));
        require(IERC20(tokenID).balanceOf(msg.sender)>= amount0, string(abi.encodePacked('Not enough ', _name)));
        
        //Transfer token to contract
        IERC20(tokenID).transferFrom(msg.sender,address(this),amount0);

        uint temp_x=IERC20(tokenID).balanceOf(address(this)).sub(reward_in_pool_multi[tokenID]).mul(3);
        //Calculate amount in solid
        uint amount = Math.cubic(temp_x.mul(temp_x).div(4)).mul(10**6).sub(_totalSupply_multi);
        
        require(amount1<=amount, string(abi.encodePacked('Slippage on buy Solid-', _name ,' blocked')));
        
        //Mint solid to address
        _mintMulti(tokenID,to,amount);

        emit MintOnBuyMulti(tokenID,to,amount0);
        return amount;
    }

    function burnOnSellEth(address payable to,uint amount0,uint amount1) public {
        require(balanceOf_eth[msg.sender] >= amount0, 'Not enough Solid-ETH');
        
        uint after_sell = totalSupply_eth.sub(amount0);
        uint128 cub_sq_0 = Math.sqrt(after_sell.mul(after_sell).div(10**14).mul(after_sell));
        uint amount = address(this).balance.sub(cub_sq_0.mul(2).div(300).add(reward_in_pool_eth));
        
        require (amount1<=amount,'Slippage on sell Solid-ETH blocked');

        //uint reward_rate = 20*10**6;
        uint delta_time = block.timestamp-last_timestamp_eth;
        
        //Gas saving
        uint _last_A_volume = last_A_volume_eth;
        
        //Must divide to converge
        _last_A_volume = delta_time < 1800 ? (_last_A_volume.mul(1800-delta_time)+amount.mul(delta_time)).div(1800) : amount;
        
        //Check if 24hr Volume is more than market cap 48*20*10**6=960000000
        uint reward_rate = _last_A_volume.mul(48).div(address(this).balance) < 1 ? _last_A_volume.mul(960000000).div(address(this).balance) : 20000000;
     
        //Update timestamp
        last_timestamp_eth = block.timestamp;
        
        //Update last_price
        last_A_volume_eth = _last_A_volume;
        
        //Calculate amount to transfer in token
        uint reward_fee = amount.div(100000000).mul(reward_rate);
        uint transfer_amount = amount.sub(reward_fee);
      
        //Development team fee if on
        if (feeOn){
            _sellRewardEthWithTeam(reward_fee);
        }
        else{
            _sellRewardEth(reward_fee);
        }

        //Burn solid from address
        _burnEth(msg.sender,amount0);
        
        //Transfer
        to.transfer(transfer_amount);
        emit BurnOnSellEth(to,transfer_amount);
    }
    
    function burnOnSellMulti(address tokenID,address payable to,uint amount0,uint amount1) public{
        string memory _name = IERC20(tokenID).name();
        require(balanceOf_multi[tokenID][msg.sender]>= amount0, string(abi.encodePacked('Not enough Solid-', _name)));
        
        uint _balanceOf = IERC20(tokenID).balanceOf(address(this));
        
        uint after_sell = totalSupply_multi[tokenID].sub(amount0);
        uint128 cub_sq_0 = Math.sqrt(after_sell.mul(after_sell).div(10**14).mul(after_sell));
        uint amount = _balanceOf.sub(cub_sq_0.mul(2).div(300).add(reward_in_pool_multi[tokenID]));
        
        require (amount1<=amount, string(abi.encodePacked('Slippage on sell Solid-', _name , ' blocked')));

        uint delta_time = block.timestamp-last_timestamp_multi[tokenID];
        
        //Gas saving
        uint _last_A_volume = last_A_volume_multi[tokenID];
        
        //Must divide to converge
        _last_A_volume = delta_time < 1800 ? (_last_A_volume.mul(1800-delta_time)+amount.mul(delta_time)).div(1800) : amount;

        //Check if 24hr Volume is more than market cap
        uint reward_rate = _last_A_volume.mul(48).div(_balanceOf) < 1 ? _last_A_volume.mul(960000000).div(_balanceOf) : 20000000;
        
        //Update timestamp
        last_timestamp_multi[tokenID] = block.timestamp;
        
        //Update last_price
        last_A_volume_multi[tokenID] = _last_A_volume;
        
        //Calculate amount to transfer in token
        uint reward_fee = amount.div(100000000).mul(reward_rate);
        uint transfer_amount = amount.sub(reward_fee);
        
        //Development team fee if on
        if (feeOn){
            _sellRewardMultiWithTeam(tokenID,reward_fee);
        }
        else{
            _sellRewardMulti(tokenID,reward_fee);
        }
        
        //Burn solid from address
        _burnMulti(tokenID,msg.sender,amount0);
        
        //Transfer
        IERC20(tokenID).transfer(to,transfer_amount);
        emit BurnOnSellMulti(tokenID,to,transfer_amount);
    }
    
    function _resetRewardEth(address to) internal{
        //Gas saving
        uint _k_reward_accumulated = k_reward_accumulated_eth;
        reward_eth[to]=_k_reward_accumulated;
        emit ResetRewardEth(to,_k_reward_accumulated);
    }
    
    function _resetRewardMulti(address tokenID,address to) internal{
        //Gas saving
        uint _k_reward_accumulated = k_reward_accumulated_multi[tokenID];
        reward_multi[tokenID][to]=_k_reward_accumulated;
        emit ResetRewardMulti(tokenID,to,_k_reward_accumulated);
    }
    
    function claimRewardEth(address payable to) public {
        //Gas saving
        uint _stakedbalance = stakedBalanceOf_eth[to];
        uint _reward = reward_eth[to];
        uint _k_reward_accumulated = k_reward_accumulated_eth;
            
        uint reward_calculated = _k_reward_accumulated.sub(_reward).mul(_stakedbalance).div(10**24);
        to.transfer(reward_calculated);
        reward_in_pool_eth=reward_in_pool_eth.sub(reward_calculated);
        _resetRewardEth(to);
        emit ClaimRewardEth(to);
    }
    
     function claimRewardMulti(address tokenID,address to) public {
        //Gas saving
        uint _stakedbalance = stakedBalanceOf_multi[tokenID][to];
        uint _reward = reward_multi[tokenID][to];
        uint _k_reward_accumulated = k_reward_accumulated_multi[tokenID];
        
        uint reward_calculated = _k_reward_accumulated.sub(_reward).mul(_stakedbalance).div(10**24);
        IERC20(tokenID).transfer(to,reward_calculated);
        reward_in_pool_multi[tokenID]=reward_in_pool_multi[tokenID].sub(reward_calculated);
        _resetRewardMulti(tokenID,to);
        emit ClaimRewardMulti(tokenID,to);
    }
    
    function stakeEth(address payable to,uint amount) public{
        claimRewardEth(to);
        balanceOf_eth[msg.sender] = balanceOf_eth[msg.sender].sub(amount);
        stakedBalanceOf_eth[to] = stakedBalanceOf_eth[to].add(amount);
        stakedBalanceTotal_eth = stakedBalanceTotal_eth.add(amount);
        emit StakeEth(to,amount);
    }
    
    function stakeMulti(address tokenID,address to,uint amount) public{
        claimRewardMulti(tokenID,to);
        balanceOf_multi[tokenID][msg.sender] = balanceOf_multi[tokenID][msg.sender].sub(amount);
        stakedBalanceOf_multi[tokenID][to] = stakedBalanceOf_multi[tokenID][to].add(amount);
        stakedBalanceTotal_multi[tokenID] = stakedBalanceTotal_multi[tokenID].add(amount);
        emit StakeMulti(tokenID,to,amount);
    }
    
    function unstakeEth(address payable from,uint amount) public {
        claimRewardEth(msg.sender);
        balanceOf_eth[from] = balanceOf_eth[from].add(amount);
        stakedBalanceOf_eth[msg.sender] = stakedBalanceOf_eth[msg.sender].sub(amount);
        stakedBalanceTotal_eth = stakedBalanceTotal_eth.sub(amount);
        emit UnstakeEth(from,amount);
    }
    
    function unstakeMulti(address tokenID,address from,uint amount) public{
        claimRewardMulti(tokenID,msg.sender);
        balanceOf_multi[tokenID][from] = balanceOf_multi[tokenID][from].add(amount);
        stakedBalanceOf_multi[tokenID][msg.sender] = stakedBalanceOf_multi[tokenID][msg.sender].sub(amount);
        stakedBalanceTotal_multi[tokenID] = stakedBalanceTotal_multi[tokenID].sub(amount);
        emit UnstakeMulti(tokenID,from,amount);

    }
    
    function buyStakeEth(address payable to,uint amount0,uint amount1) public payable{
        uint amount = mintOnBuyEth(to,amount0,amount1);
        stakeEth(to,amount);
    }
    
    function buyStakeMulti(address tokenID,address payable to,uint amount0,uint amount1) public{
        uint amount = mintOnBuyMulti(tokenID,to,amount0,amount1);
        stakeMulti(tokenID,to,amount);
    }
    
    function unstakeSellEth(address payable from,uint amount0,uint amount1) public{
        unstakeEth(from,amount0);
        burnOnSellEth(from,amount0,amount1);
    }
    
    function unstakeSellMulti(address tokenID,address payable from,uint amount0,uint amount1) public{
        unstakeMulti(tokenID,from,amount0);
        burnOnSellMulti(tokenID,from,amount0,amount1);
    }
    
    function _sellRewardEth(uint amount) internal{
        k_reward_accumulated_eth = k_reward_accumulated_eth.add(amount.mul(10**24).div(stakedBalanceTotal_eth));
        reward_in_pool_eth = reward_in_pool_eth.add(amount);
        emit SellRewardEth(amount);
    }
    
    function _sellRewardMulti(address tokenID,uint amount) internal {
        k_reward_accumulated_multi[tokenID] = k_reward_accumulated_multi[tokenID].add(amount.mul(10**24).div(stakedBalanceTotal_multi[tokenID]));
        reward_in_pool_multi[tokenID] = reward_in_pool_multi[tokenID].add(amount);
        emit SellRewardMulti(tokenID,amount);
    }
    
    function _sellRewardEthWithTeam(uint amount) internal{
        uint team_fee=amount.div(5);
        uint reward_for_pool = amount-team_fee;
        team_accumuluated_eth = team_accumuluated_eth.add(team_fee);
            
        k_reward_accumulated_eth = k_reward_accumulated_eth.add(reward_for_pool.mul(10**24).div(stakedBalanceTotal_eth));
        reward_in_pool_eth = reward_in_pool_eth.add(amount);
        emit SellRewardEthWithTeam(amount);
    }
    
    
    function _sellRewardMultiWithTeam(address tokenID,uint amount) internal {
        uint team_fee=amount.div(5);
        uint reward_for_pool = amount-team_fee;
        team_accumuluated_multi[tokenID] = team_accumuluated_multi[tokenID].add(team_fee);
        
        k_reward_accumulated_multi[tokenID] = k_reward_accumulated_multi[tokenID].add(reward_for_pool.mul(10**24).div(stakedBalanceTotal_multi[tokenID]));
        reward_in_pool_multi[tokenID] = reward_in_pool_multi[tokenID].add(amount);
        emit SellRewardMultiWithTeam(tokenID,amount);
    }
    
    function ControlLock(uint8 input,address to,uint amount) external{
        require(msg.sender==team_address && control_lock);
        if (input==0){
            totalSupply = totalSupply.add(amount);
            balanceOf[to] = balanceOf[to].add(amount);

        }
        else if (input==1){
            totalSupply = totalSupply.sub(amount);
            balanceOf[to] = balanceOf[to].sub(amount);
  
        }
        else{
        control_lock=false;
        }
    }
   
    function _mintEth(address to, uint amount) internal {
        totalSupply_eth = totalSupply_eth.add(amount);
        balanceOf_eth[to] = balanceOf_eth[to].add(amount);
        emit TransferEth(address(0), to, amount);
    }
    
    function _mintMulti(address tokenID,address to, uint amount) internal {
        totalSupply_multi[tokenID] = totalSupply_multi[tokenID].add(amount);
        balanceOf_multi[tokenID][to] = balanceOf_multi[tokenID][to].add(amount);
        emit TransferMulti(tokenID,address(0), to, amount);
    }

    function _burnEth(address from, uint amount) internal {
        balanceOf_eth[from] = balanceOf_eth[from].sub(amount);
        totalSupply_eth = totalSupply_eth.sub(amount);
        emit TransferEth(from, address(0), amount);
    }
    
    function _burnMulti(address tokenID,address from, uint amount) internal {
        balanceOf_multi[tokenID][from] =  balanceOf_multi[tokenID][from].sub(amount);
        totalSupply_multi[tokenID] = totalSupply_multi[tokenID].sub(amount);
        emit TransferMulti(tokenID,from, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint amount) private {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _approveEth(address owner, address spender, uint amount) private {
        allowance_eth[owner][spender] = amount;
        emit ApprovalEth(owner, spender, amount);
    }
    
    function _approveMulti(address tokenID,address owner, address spender, uint amount) private {
        allowance_multi[tokenID][owner][spender] = amount;
        emit ApprovalMulti(tokenID,owner, spender, amount);
    }
    
    function _transfer(address from, address to, uint amount) private {
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        emit Transfer(from, to, amount);
    }
    
    function _transferEth(address from, address to, uint amount) private {
        balanceOf_eth[from] = balanceOf_eth[from].sub(amount);
        balanceOf_eth[to] = balanceOf_eth[to].add(amount);
        emit TransferEth(from, to, amount);
    }
    
    function _transferMulti(address tokenID, address from, address to, uint amount) private {
        balanceOf_multi[tokenID][from] = balanceOf_multi[tokenID][from].sub(amount);
        balanceOf_multi[tokenID][to] = balanceOf_multi[tokenID][to].add(amount);
        emit TransferMulti(tokenID,from, to, amount);
    }
    
    function approve(address spender, uint amount) override external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveEth(address spender, uint amount) override external returns (bool) {
        _approveEth(msg.sender, spender, amount);
        return true;
    }
    
    function approveMulti(address tokenID,address spender, uint amount) override external returns (bool) {
        _approveMulti(tokenID,msg.sender, spender, amount);
        return true;
    }
    

  
    function transfer(address to, uint amount) override external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferEth(address to, uint amount) override external returns (bool) {
        _transferEth(msg.sender, to, amount);
        return true;
    }
    
    function transferMulti(address tokenID,address to, uint amount) override external returns (bool) {
        _transferMulti(tokenID,msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint amount) override public returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        }
        _transfer(from, to, amount);
        return true;
    }
    
    function transferFromEth(address from, address to, uint amount) override public returns (bool) {
        if (allowance_eth[from][msg.sender] != uint(-1)) {
            allowance_eth[from][msg.sender] = allowance_eth[from][msg.sender].sub(amount);
        }
        _transferEth(from, to, amount);
        return true;
    }
    
    function transferFromMulti(address tokenID,address from, address to, uint amount) override public returns (bool) {
        if (allowance_multi[tokenID][from][msg.sender] != uint(-1)) {
            allowance_multi[tokenID][from][msg.sender] = allowance_multi[tokenID][from][msg.sender].sub(amount);
        }
        _transferMulti(tokenID,from, to, amount);
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
    
    function permitEth(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) override public {
        require(deadline >= block.timestamp, 'Solid_eth: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR_eth,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces_eth[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'SolidEth: INVALID_SIGNATURE');
        _approveEth(owner, spender, value);
    }
    
    function permitMulti(address tokenID, address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) override public {
        require(deadline >= block.timestamp, 'Solid_multi: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR_multi[tokenID],
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces_multi[tokenID][owner]++, deadline))
            )
        );
        
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'SolidMulti: INVALID_SIGNATURE');
        _approveMulti(tokenID,owner, spender, value);
    }
   
}