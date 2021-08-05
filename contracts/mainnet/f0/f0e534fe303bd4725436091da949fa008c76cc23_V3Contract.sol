pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";
import "IERC20.sol";
import "SafeMath.sol";
import "SafeERC20.sol";

contract V3Contract is Ownable{

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    IERC20 public v3Token = IERC20(0x0);
    
    address public adminAddr;
    
    mapping(address => uint256) map_userTokens;
    address[] array_users;
    
    uint256 public exchange_ratio = 80;
    uint256 public invite_reward_v3_ratio = 10;
    string public ico_flag = "pre-sale";
    bool public lock = true;
    uint256 public v3Token_decimals = 6;
    bool public active_ico = false;
    uint256 public min_amount_of_eth_transfer = 500;
    
    event receive_pay(address sender_, uint256 amount_);
    event fallback_pay(address sender_,uint256 amount_);
    event withdraw_eth(address target_,uint256 amount_);
    event join_presale_invite(string flag_,address sender_,uint256 eth_amount,uint256 v3_amount,address invite_addr_,uint256 v3_reward_amount_);
    event join_presale(string flag_,address sender_,uint256 eth_amount,uint256 v3_amount);
    
    constructor(address v3_token_address) public{
        adminAddr = msg.sender;
        v3Token = IERC20(v3_token_address);
    }
    
    fallback() external payable {
        emit fallback_pay(msg.sender, msg.value);
    }
    
    // bytes public last_pay_inputData;
    // address public invite_address;
    
    receive() external payable {
        // last_pay_inputData = msg.data;
        // // joinPreSale(msg.sender, msg.value);
        // address invite_addr = bytesToAddress(msg.data);
        // invite_address = invite_addr;
        // if(invite_addr == address(invite_addr)){
        //     joinPreSale_invite(msg.sender, msg.value,invite_addr);
        // }else{
        //     joinPreSale(msg.sender, msg.value);
        // }
        emit receive_pay(msg.sender, msg.value);
    }
    
    // function bytesToAddress(bytes memory bys)  private pure returns (address addr) {
    //     assembly {
    //         addr := mload(add(bys,20))
    //     }
    // }
    
    function set_status(bool active_) public isAdmin{
        active_ico = active_;
    }
    
    function change(bool v_) public isAdmin{
        lock = v_;
    }
    
    function set_v3Token_decimals(uint256 v3Token_decimals_) public isAdmin{
        v3Token_decimals = v3Token_decimals_;
    }
      
    function set_exchange_ratio(uint256 ratio_) public isAdmin{
        
        require(ratio_ >= 1,"invaild exchange_ratio");
        exchange_ratio = ratio_;
    }
    
    function set_min_amount_of_eth_transfer(uint256 min_amount_of_eth_transfer_) public isAdmin{
        min_amount_of_eth_transfer = min_amount_of_eth_transfer_;
    }
    
    function set_invite_reward_v3_amount(uint256 invite_reward_v3_ratio_) public isAdmin{
        
        invite_reward_v3_ratio = invite_reward_v3_ratio_;
    }
    
    function set_flag_for_current_ico(string memory flag_) public isAdmin{
       
        ico_flag = flag_;
    }
    
    function fetchUserTokenSize() public view returns(uint256){
        return array_users.length;
    }
    
    function fetchUserTokenDatas(uint256 cursor, uint256 length_) public view returns (address[] memory,uint256[] memory, uint256)
    {
        uint256 length = length_;
        if (length > array_users.length - cursor) {
            length = array_users.length - cursor;
        }

        address[]memory addrs = new address[](length);
        uint256[] memory tokens = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            address addr = array_users[cursor + i];
            addrs[i] = addr;
            tokens[i] = map_userTokens[addr];
        }
        
        
        return (addrs, tokens,cursor + length);
    }
    
    
    function test_addToken_eth(address addr_,uint256 eth_) public isAdmin returns(uint256,uint256){
        uint256 v3_amount;
        uint256 v3_reward;
        uint256 eth_amount;
        (eth_amount,v3_amount,v3_reward) = calcV3WithETH(eth_);
        map_userTokens[addr_] += v3_amount;
        return (v3_amount,v3_reward);
    }
    
    function calcV3WithETH(uint256 eth_) public view returns (uint256,uint256,uint256){
        uint256 v3_amount = eth_ * exchange_ratio * 10 ** v3Token_decimals/(10**18);
        uint256 v3_reward = v3_amount * invite_reward_v3_ratio / 100 ;
        return (eth_,v3_amount,v3_reward);
    }
    
    function joinPreSale_invite(uint256 eth_,address invite_addr_) public{
        
        require(msg.sender!=invite_addr_,"cant not invited by yourself");
        joinPreSale(eth_);
        uint256 v3_amount;
        uint256 v3_reward;
        uint256 eth_amount;
        (eth_amount,v3_amount,v3_reward) = calcV3WithETH(eth_);
        
        if(invite_addr_ == address(invite_addr_)&&v3_reward>0){
            
            // v3Token.safeTransfer(invite_addr_,v3_reward);
            map_userTokens[invite_addr_] +=v3_reward;
            
            if(map_userTokens[invite_addr_] == 0x0){
                array_users.push(invite_addr_);
            }
        }
        emit join_presale_invite(ico_flag,msg.sender,eth_,v3_amount,invite_addr_,v3_reward);
    }
    
    function joinPreSale(uint256 eth_) public {
        
        require(active_ico,"The Pre-sale is pending.");
        
        uint256 v3_amount;
        uint256 v3_reward;
        uint256 eth_amount;
        (eth_amount,v3_amount,v3_reward) = calcV3WithETH(eth_);
        
        if(v3_amount > 0x0){
            // v3Token.safeTransfer(msg.sender,v3_amount);
            if(map_userTokens[msg.sender] == 0x0){
                array_users.push(msg.sender);
            }
            map_userTokens[msg.sender] += v3_amount;
        }
        
        emit join_presale(ico_flag,msg.sender,eth_,v3_amount);
        
    }
    
    function setToken(address tokenAddress_) public onlyOwner {
        v3Token = IERC20(tokenAddress_);
    }
    
    modifier isAdmin() {
        require(msg.sender == adminAddr);
        _;
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0),"invaild admin address");
        adminAddr = _newAdmin;
    }
    
    function withdrawToken(uint256 amount_) public {
        require(!lock,"The pre-sale is not over, you can't withdraw");
        uint256 balance = map_userTokens[msg.sender];
        require(balance >= amount_,"not enough v3 token");
        v3Token.safeTransfer(msg.sender,amount_);
        map_userTokens[msg.sender] = balance - amount_;
    }
    
    function transferToken(address receiver_,uint256 amount_) public isAdmin{
        v3Token.safeTransfer(receiver_,amount_);
    }
    
    function amountOfTokenCanWithdraw(address addr_) public view returns (uint256) {
        return map_userTokens[addr_];
    }
    
    function transferETH(address payable receiver_) public payable isAdmin{
        receiver_.transfer(msg.value);
    }
    
    function balanceOfETH() public view returns (uint256){
       return address(this).balance;
    }
    
    
}