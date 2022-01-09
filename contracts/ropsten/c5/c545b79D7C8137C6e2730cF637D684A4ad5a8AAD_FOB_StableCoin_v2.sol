/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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
    uint private seller_penalty;
    uint private platform_fee;
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

    uint private penalty_value;
    uint private total_amount;
    uint private inspector_fee;
    uint private forwarder_fee;
    
    address[] private depositors;

    mapping(address => uint) public depositors_balances;
    
    
    IERC20 private Token;
    address private token_address;
    string private token_symbol;
    uint private token_decimals;
    
    enum State {
        contract_created, 
        payment_done, 
        inspector_assigned, 
        forwarder_assigned, 
        forwarder_fee_paid, 
        inspector_fee_paid, 
        inspection_done, 
        bl_issued, 
        done, 
        terminated, 
        arbitration
    }

    State private current_state;

//      /////////////////////////// End of Definitions ///////////////////


//     ///////////////////////////   Modifiers  ///////////////////

    modifier check(bool _condition) {
        require(_condition, "Condition is False.");
        _;
    }

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
  
    modifier inState(State _state) {
        require( true, "Invalid state.");
        _;
    }

    modifier inStates(State _state_1 , State _state_2) {
        require( true, "Invalid state.");
        _;
    }

    modifier in3States(State _state_1 , State _state_2, State _state_3) {
        require( true, "Invalid state.");
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
        current_state   = State.contract_created;
        
        emit Contarct_Created(seller, buyer, pi_refrence, pi_hash, delivery_time, seller_penalty, total_amount, platform_fee);
    }
        
    function deposit_to_contract() public inStates(State.contract_created,State.payment_done) {
        require(msg.sender == seller || msg.sender == buyer, "Deposit_to_contract: Permission denied! Only Seller and Buyer can call this function.");
        uint seller_share = seller_penalty.add(platform_fee.div(2));
        uint buyer_share = total_amount.add(platform_fee.div(2));
        if(msg.sender == buyer) {
            require(Token.balanceOf(buyer) >= buyer_share, "Deposit_to_contract: Buyer Insufficient Funds!");
            require(Token.allowance(msg.sender, address(this))>=buyer_share, "Deposit_to_contract: Failed on transferFrom Buyer!(Allowance)");
            require(Token.transferFrom(msg.sender, address(this), buyer_share), "Deposit_to_contract: Failed on transferFrom Buyer!");
            depositors_balances[msg.sender] += buyer_share;
            require(Token.transfer(platform, platform_fee/2), "Deposit_to_contract: Token broker transfer failed!");
            current_state = State.payment_done;
            emit Buyer_paid_the_amount(buyer, buyer_share);
        }
        else if(msg.sender == seller) {
            require(Token.balanceOf(seller) >= seller_share, "Deposit_to_contract: Seller Insufficient Funds!");
            require(Token.allowance(msg.sender, address(this))>=seller_share, "Deposit_to_contract: Failed on transferFrom Seller!(Alloance)");
            require(Token.transferFrom(msg.sender, address(this), seller_share), "Deposit_to_contract: Failed on transferFrom Seller!");
            depositors_balances[msg.sender] +=seller_share;
            require(Token.transfer(platform, platform_fee/2), "Deposit_to_contract: Token broker transfer failed!");
            current_state = State.payment_done;
            emit Seller_paid_the_amount(seller, seller_share);
        }
    }

    function contract_finalization(bool AllDone) public only_platform inState(State.bl_issued){
        require(AllDone,'Not done yet!');
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
            current_state = State.done;
        } else {
            AllDone = false;           
        }
        emit Contract_Finalization(AllDone);
    }

    function inspector_fee_payment (uint _inspector_fee) public only_seller in3States(State.inspector_assigned,State.forwarder_assigned,State.forwarder_fee_paid) {
        require(Token.balanceOf(seller) >= _inspector_fee, "Deposit_to_contract: Seller Insufficient Funds!");
        require((msg.sender == seller), "Seller could pay inspector fee");
        require(Token.allowance(msg.sender, address(this))>= _inspector_fee, "Deposit_to_contract: Failed on transferFrom Seller!(Alloance)");
        require(Token.transferFrom(msg.sender, address(this), _inspector_fee), "Deposit_to_contract: Failed on transferFrom Seller!");
        depositors_balances[msg.sender] +=_inspector_fee;
        inspector_fee = _inspector_fee;
        current_state = State.inspector_fee_paid;
    }

    function assigning_inspector (address _inspector) public only_seller inStates(State.payment_done,State.forwarder_assigned) {
        require((inspector == address(0)), "Inspector is not empty");
        require((msg.sender == seller), "Seller could assign inspector");
        inspector = _inspector;
        current_state = State.inspector_assigned;
        emit Inspector_Assigned();
    }

    function forwarder_fee_payment (uint _forwarder_fee) public only_buyer in3States(State.inspector_assigned,State.forwarder_assigned,State.inspector_fee_paid) {
        require(Token.balanceOf(buyer) >= _forwarder_fee, "Deposit_to_contract: Buyer Insufficient Funds!");
        require((msg.sender == buyer), "Seller could pay forwarder fee");
        require(Token.allowance(msg.sender, address(this))>= _forwarder_fee, "Deposit_to_contract: Failed on transferFrom Buyer!(Alloance)");
        require(Token.transferFrom(msg.sender, address(this), _forwarder_fee), "Deposit_to_contract: Failed on transferFrom Buyer!");
        depositors_balances[msg.sender] +=_forwarder_fee;
        forwarder_fee = _forwarder_fee;
        current_state = State.forwarder_fee_paid;
    }

    function assigning_forwarder (address _forwarder) public only_buyer inStates(State.inspector_assigned,State.payment_done) {
        require((forwarder == address(0)), "Forwarder is not empty");
        require((msg.sender == buyer), "Seller could assign inspector");
        forwarder = _forwarder;
        current_state = State.forwarder_assigned;
        emit Forwarder_Assigned();
    }

    function inspector_submit_ci (string memory _ci_hash) public only_inspector inStates(State.inspector_assigned,State.inspector_fee_paid) {
        bytes memory tempEmptyStringTest = bytes(ci_hash);
        require(tempEmptyStringTest.length != 0,"CI submitted before.");
        require(msg.sender == inspector,"Only inspector could submit CI");
        require(Token.transfer(inspector, inspector_fee), "Contract_Tx: Inspector transaction failed!");
        ci_hash = _ci_hash;
        current_state = State.inspection_done;
        emit Inspection_Done();
    }

    function forwarder_submit_bl (string memory _bl_hash) public only_forwarder in3States(State.forwarder_assigned,State.forwarder_fee_paid,State.inspection_done) {
        bytes memory tempEmptyStringTest = bytes(bl_hash);
        require(tempEmptyStringTest.length != 0,"BL submitted before.");
        require(msg.sender == forwarder,"Only forwarder could submit BL");
        require(Token.transfer(forwarder, forwarder_fee), "Contract_Tx: Forwarder transaction failed!");
        bl_hash = _bl_hash;
        current_state = State.bl_issued;
        emit BL_Issued();
    }
//      ///////////////////////////  End of Functions (write) ///////////////////

//      ///////////////////////////  Functions (Read) ///////////////////

    function get_current_satate() public view returns(State) {
        return current_state ;
    }

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
    
    function get_seller_penalty() public view returns(uint) {
        return seller_penalty;
    }

    function get_seller_share() public view returns(string memory) {
        return convertTokenBalance(depositors_balances[seller]-inspector_fee,token_symbol,token_decimals);
    }
    
    function get_paid_by_seller() public view returns(string memory) {
        return convertTokenBalance(depositors_balances[seller],token_symbol,token_decimals);
    }
    
    function get_paid_by_buyer() public view returns(string memory) {
        return convertTokenBalance(depositors_balances[buyer],token_symbol,token_decimals);
    }
    
    function get_buyer_share() public view returns(string memory) {
        return convertTokenBalance(depositors_balances[buyer]-forwarder_fee,token_symbol,token_decimals);
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

    function get_total_amount() public view returns(uint) {
        return total_amount;
    }

    function get_platform_fee() public view returns(uint) {
        return platform_fee;
    }
    
//      ///////////////////////////  End of Functions (Read) ///////////////////


/////////////////String Library/////////////////////////////

    function convertTokenBalance (uint currBalance ,string memory _symbol, uint _decimals) public pure returns (string memory){
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
/////////////////String Library/////////////////////////////



//      ///////////////////////////  Events ///////////////////
    event Contarct_Created(address seller, address buyer, string pi_refrence, string pi_hash, string delivery_time, uint seller_penalty, uint total_amount, uint platform_fee);
    event Buyer_paid_the_amount(address buyer, uint amount);
    event Seller_paid_the_amount(address seller, uint amount);
    event Inspector_Assigned();
    event Forwarder_Assigned();
    event Contract_Finalization(bool All_Done);
    event Inspection_Done();
    event BL_Issued();
//      ///////////////////////////  End of Events ///////////////////
    

    //  prevent implicit acceptance of ether 
    receive() external payable {
         revert();
    }

}