/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

library SafeMath {

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

library TokenStr {
    function convertTokenBalance (uint currBalance ,string memory _symbol, uint _decimals) internal pure returns (string memory){
        string memory _result = concat (" " , _symbol);
        _result = concat (getBalanceDecimal(currBalance,_decimals),_result);
        _result = concat (".",_result);
        _result = concat (getBalanceInteger(currBalance,_decimals),_result);

        return _result;
    }

    function getBalanceDecimal(uint currBalance, uint decimalCount) internal pure returns (string memory) {
      if (currBalance == 0) {
         return "0";
      }

      bytes memory bstr = new bytes(2);
      
      uint t;
      t = currBalance % (10**decimalCount);
      t= uint(t / (10**(decimalCount-2)));
      
      bstr[0]=bytes1(uint8(48 + uint(t / 10)));

      bstr[1]=bytes1(uint8(48 + uint(t % 10)));
      return string(bstr);
    }

    function getBalanceInteger(uint currBalance, uint decimalCount) internal pure returns (string memory) {
      if (currBalance == 0) {
         return "0";
      }
      uint j = currBalance;
      uint len=0;
      currBalance = uint(currBalance / (10**decimalCount));

      while (j != 0) {
         len++;
         j /= 10;
      }
      uint delimiter = len/3;
      bytes memory bstr = new bytes(len+delimiter);
      uint k = delimiter + len - 1;

      uint delimiteCounter = 0;
      
      while (currBalance != 0) {
          if (delimiteCounter==3){
              bstr[k--] =bytes1(uint8(32));
              delimiteCounter=0;
          } else {
            bstr[k--] = bytes1(uint8(48 + currBalance % 10));
            delimiteCounter++;
            currBalance /= 10;
          }
      }
      return string(bstr);
    }

    function concat(string memory _base, string memory _value) internal pure returns (string memory) {
        return string(abi.encodePacked(_base, _value));
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//      /////////////////////////// Definitions ///////////////////
contract FOB_StableCoin_v2 {
    //uint private constant PERCENTAGE_RATE = 100*(10**18) ;
    using SafeMath for uint;

    string private delivery_time;
    string private pi_refrence;
    string private pi_hash;
    string private ci_hash;
    string private bl_hash;

    address private buyer;
    address private seller;
    address private inspector;
    address private forwarder;
    address private platform;
    address private merchant;

    uint private seller_penalty;
    uint private platform_fee;
    uint private total_amount;
    uint private inspector_fee;
    uint private forwarder_fee;
    

    mapping(address => uint) public depositors_balances;
    
    
    IERC20 private Token;
    address private token_address;
    string private token_symbol;
    uint private token_decimals;
    
    bool[11] public StatesArray;
        // 0- contract_created
        // 1- buyer_payment_done
        // 2- seller_payment_done
        // 3- inspector_assigned
        // 4- forwarder_assigned
        // 5- forwarder_fee_paid 
        // 6- inspector_fee_paid
        // 7- inspection_done
        // 8- bl_issued
        // 9- done
        // 10- terminated

//      /////////////////////////// End of Definitions ///////////////////


//     ///////////////////////////   Modifiers  ///////////////////

    modifier only_buyer() {
        require(msg.sender == buyer,"Only Buyer can call this.");
        _;
    }
    
    modifier only_platform() {
        require(msg.sender == platform,"Only Platform can call this.");
        _;
    }
    
    modifier only_seller() {
        require(msg.sender == seller, "Only Seller can call this.");
        _;
    }
      
    modifier only_inspector() {
        require(msg.sender == inspector, "Only Inspector can call this.");
        _;
    }

    modifier only_forwarder() {
        require(msg.sender == forwarder, "Only Forwarder can call this.");
        _;
    }

//      ///////////////////////////  End of  Modifiers  ///////////////////

//      ///////////////////////////  Functions (Write) ///////////////////

    constructor(
        address _token_address, 
        string[4] memory _all_strings, 
        uint[4] memory _all_uints, 
        address _buyer, 
        address _seller, 
        address _merchant
    ){
        require(!StatesArray[0],                "Contract Created before");
        require(_token_address  != address(0), "constructor: Invalid token address!");
        require(_seller         != address(0), "constructor: Invalid seller address!");
        require(_buyer          != address(0), "constructor: Invalid buyer address!");
        
        token_address   = _token_address;
        Token           = IERC20(token_address);
        token_symbol    = _all_strings[2];
        token_decimals  = _all_uints[3];
        
        pi_refrence     = _all_strings[0];
        pi_hash         = _all_strings[1];
        delivery_time   = _all_strings[3];

        seller_penalty  = _all_uints[0];
        total_amount    = _all_uints[1];
        platform_fee    = _all_uints[2];
        
        buyer           = _buyer;
        seller          = _seller;
        merchant        = _merchant;
        platform        = msg.sender;
        
        StatesArray[0]   = true;
        
    }
        
    function deposit_to_contract() public{
        require(StatesArray[0], "Wrong state!");
        require(msg.sender == seller || msg.sender == buyer, "Deposit_to_contract: Permission denied! Only Seller and Buyer can call this function.");
        uint seller_share = seller_penalty.add(platform_fee.div(2));
        uint buyer_share = total_amount.add(platform_fee.div(2));
        if(msg.sender == buyer) {
            require(Token.balanceOf(buyer) >= buyer_share, "Deposit_to_contract: Buyer Insufficient Funds!");
            require(Token.allowance(msg.sender, address(this))>=buyer_share, "Deposit_to_contract: Failed on transferFrom Buyer!(Allowance)");
            require(Token.transferFrom(msg.sender, address(this), buyer_share), "Deposit_to_contract: Failed on transferFrom Buyer!");
            require(Token.transfer(platform, platform_fee.div(2)), "Deposit_to_contract: Token platform transfer failed!(buyer)");
            depositors_balances[msg.sender] = total_amount ;
            StatesArray[1]=true;
        }
        else if(msg.sender == seller) {
            require(Token.balanceOf(seller) >= seller_share, "Deposit_to_contract: Seller Insufficient Funds!");
            require(Token.allowance(msg.sender, address(this))>=seller_share, "Deposit_to_contract: Failed on transferFrom Seller!(Alloance)");
            require(Token.transferFrom(msg.sender, address(this), seller_share), "Deposit_to_contract: Failed on transferFrom Seller!");
            require(Token.transfer(platform, platform_fee.div(2)), "Deposit_to_contract: Token platform transfer failed!(seller)");
            depositors_balances[msg.sender] = seller_penalty;
            StatesArray[2]=true;
        }
    }

    function contract_finalization() public only_platform{
        require(StatesArray[7],"Inspection not done yet!");
        require(StatesArray[8],"Bill of Lading not yet issued!");
        if (Token.balanceOf(address(this))>total_amount.add(seller_penalty.add(inspector_fee.add(forwarder_fee)))){
            require(Token.transfer(seller,total_amount.add(seller_penalty)),"Tranfer to Seller account failed!");
            require(Token.transfer(inspector,inspector_fee),"Transfer to Inspector account failed!");
            require(Token.transfer(forwarder,forwarder_fee),"Transfer to Forwarder account failed!");
            if (Token.balanceOf(address(this)) > 0){
                Token.transfer(platform,Token.balanceOf(address(this)));
            }
            if (address(this).balance > 0 ){
                payable(platform).transfer(address(this).balance);
            }
            StatesArray[9]=true;
        } else {
            StatesArray[9]=false;
        }
    }

    function inspector_fee_payment (uint _inspector_fee) public only_seller{
        require(StatesArray[1] && StatesArray[2],"Payment should be done first.");
        require(StatesArray[3],"Inspector should be assinged before.");
        require(Token.balanceOf(seller) >= _inspector_fee, "Deposit_to_contract: Seller Insufficient Funds!");
        require((msg.sender == seller), "Seller could pay inspector fee");
        require(Token.allowance(msg.sender, address(this))>= _inspector_fee, "Deposit_to_contract: Failed on transferFrom Seller!(Alloance)");
        require(Token.transferFrom(msg.sender, address(this), _inspector_fee), "Deposit_to_contract: Failed on transferFrom Seller!");
        depositors_balances [msg.sender] +=_inspector_fee;
        inspector_fee = _inspector_fee;
        StatesArray[6]=true;
    }

    function assigning_inspector (address _inspector) public only_seller{
        require(StatesArray[1] && StatesArray[2],"Payment should be done first.");
        require((inspector == address(0)), "Inspector is not empty");
        require((msg.sender == seller), "Seller could assign inspector");
        inspector = _inspector;
        StatesArray[3]=true;
    }

    function forwarder_fee_payment (uint _forwarder_fee) public only_buyer{
        require(StatesArray[1] && StatesArray[2],"Payment should be done first.");
        require(StatesArray[4],"Forwarder should be assinged before.");
        require(Token.balanceOf(buyer) >= _forwarder_fee, "Deposit_to_contract: Buyer Insufficient Funds!");
        require((msg.sender == buyer), "Buyer could pay forwarder fee");
        require(Token.allowance(msg.sender, address(this))>= _forwarder_fee, "Deposit_to_contract: Failed on transferFrom Buyer!(Alloance)");
        require(Token.transferFrom(msg.sender, address(this), _forwarder_fee), "Deposit_to_contract: Failed on transferFrom Buyer!");
        depositors_balances [msg.sender] +=_forwarder_fee;
        forwarder_fee = _forwarder_fee;
        StatesArray[5]=true;
    }

    function assigning_forwarder (address _forwarder) public only_buyer{
        require(StatesArray[1] && StatesArray[2],"Payment should be done first.");
        require((forwarder == address(0)), "Forwarder is not empty");
        require((msg.sender == buyer), "Seller could assign inspector");
        forwarder = _forwarder;
        StatesArray[4]=true;
    }

    function inspector_submit_ci (string memory _ci_hash) public only_inspector{
        require(StatesArray[6],"Inspection fee not paid.");
        bytes memory tempEmptyStringTest = bytes(ci_hash);
        require(tempEmptyStringTest.length == 0, "CI submitted before.");
        require(msg.sender == inspector, "Only inspector could submit CI");
        ci_hash = _ci_hash;
        StatesArray[7]=true;
    }

    function forwarder_submit_bl (string memory _bl_hash) public only_forwarder{
        require(StatesArray[5],"Forwarding fee not paid.");
        bytes memory tempEmptyStringTest = bytes(bl_hash);
        require(tempEmptyStringTest.length == 0, "BL submitted before.");
        require(msg.sender == forwarder,"Only forwarder could submit BL");
        bl_hash = _bl_hash;
        StatesArray[8]=true;
    }
//      ///////////////////////////  End of Functions (write) ///////////////////

//      ///////////////////////////  Functions (Read) ///////////////////

    function get_seller_address() public view returns(address) {
        return seller;
    }

    function get_buyer_address() public view returns(address) {
        return buyer;
    }
    
    function get_inspector_address() public view returns(address) {
        return inspector;
    }

    function get_forwarder_address() public view returns(address) {
        return forwarder;
    }
 
    function get_paid_by_seller() public view returns(string memory) {
        return TokenStr.convertTokenBalance(depositors_balances[seller],token_symbol,token_decimals);
    }
    
    function get_paid_by_buyer() public view returns(string memory) {
        return TokenStr.convertTokenBalance(depositors_balances[buyer],token_symbol,token_decimals);
    }
    
    function get_bl_hash() public view returns(string memory) {
        return bl_hash;
    }

    function get_ci_hash() public view returns(string memory) {
        return ci_hash;
    }

    function get_pi_hash() public view returns(string memory) {
        return pi_hash;
    }

    function get_delivery_date() public view returns(string memory) {
        return delivery_time;
    }

    function get_pi_refrence() public view returns(string memory) {
        return pi_refrence;
    }

    function get_token_contract_address() public view returns(address) {
        return token_address;
    }

    function get_token_decimals() public view returns(uint) {
        return token_decimals;
    }

    function get_token_symbol() public view returns(string memory) {
        return token_symbol;
    }

    function get_total_amount() public view returns(string memory) {
        return TokenStr.convertTokenBalance(total_amount,token_symbol,token_decimals);
    }

    function get_seller_penalty() public view returns(string memory) {
        return TokenStr.convertTokenBalance(seller_penalty,token_symbol,token_decimals);
    }

    function get_states() public view returns(bool[11] memory){
        return StatesArray;
    }
    
//      ///////////////////////////  End of Functions (Read) ///////////////////


/////////////////String Library/////////////////////////////

/////////////////String Library/////////////////////////////

    //  prevent implicit acceptance of ether 
    receive() external payable {
         revert();
    }
}