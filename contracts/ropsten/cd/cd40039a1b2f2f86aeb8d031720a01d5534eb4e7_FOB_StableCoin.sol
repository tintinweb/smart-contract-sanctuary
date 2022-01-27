/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: GPL-3.0
/**
 * This contract implemented a simple FOB (free on board) frominternational commercial law.
 * Any ERC20 Token can used to pony between seller and buyer.
 * Seller pay all of good cost and buyer pay agreed amount to guarantee compensation, The procedure
 *      of the contract are executed step by step and at the end, the desired amounts are paid to the 
 *      accounts of the parties on behalf of the contract. 
 * The amount of cargo that will be verified by the seller and buyer can vary up to 0.5 %
 * Both of Seller and Buyer must give Approve permission to Contract for withdraw from their account.
 * 
 * Last Modified Date: 2021-06-25
 * All rights reserved for _bamdadblockchain_ group.
 * [email protected]
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/
pragma solidity ^0.8.6;

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

library StringLib{
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

contract FOB_StableCoin {

    using StringLib for uint;

    uint private constant PERCENTAGE_RATE = 100*(10**6) ;
    string private goods_name;
    string private unit_name;
    string private seller_extra_data;
    uint private unit_price;
    uint private delivery_time;
    uint private penalty_percent;
    uint private kyc_deadline;
    uint private broker_percent;
    string private demand_unit;
    uint private demand;
    string private loading_point;
    address private buyer;
    address private seller;
    address private quality_controller;
    address private vessel_validator;
    address private broker;
    address private arbitrator;
    string private vessel_name;
    address private final_seller_inspector;
    address private final_buyer_inspector;

    bool private shipment_confirmed_by_seller = false;
    bool private shipment_confirmed_by_buyer = false;
    bool private shipment_disagreement_by_buyer = false;

    uint private penalty_value;

    bool private seller_payed_share;
    bool private buyer_payed_share;

    mapping(address => uint) public depositors_balances;
        
    IERC20 private Token;
    address private token_address;
    string private token_symbol;
    uint private token_decimals;
    
    enum State { supplied, payment_done, ship_and_Qcontroller_presented,
    vessel_validator_accept_ship, vessel_validator_reject_ship, quality_controller_accept, quality_controller_reject,
    buyer_confirmed_shipment_done, seller_confirmed_shipment_done, disagreement, waiting_to_pay_penalty, canceled, done }

    State private current_state;
    State private state_befor_disagreement;
    State private state_after_pay_penalty;

//     ///////////////////////////   Modifiers  ///////////////////

    modifier check(bool _condition) {
        require(_condition, "Condition is False.");
        _;
    }

    modifier only_buyer() {
        require(msg.sender == buyer,"Only Buyer can call this.");
        _;
    }
    
    modifier only_seller() {
        require(msg.sender == seller, "Only Seller can call this.");
        _;
    }
    

    modifier only_broker() {
        require(msg.sender == broker, "Only Broker can call this.");
        _;
    }
    
    modifier only_vessel_validator() {
        require(msg.sender == vessel_validator, "Only Vessel Validator can call this.");
        _;
    }
    
    modifier only_arbitrator() {
        require(msg.sender == arbitrator, "Only Arbitrator can call this.");
        _;
    }
    
    modifier only_quality_controller() {
        require(msg.sender == quality_controller, "Only Quality Controller can call this.");
        _;
    }
    
    modifier only_final_seller_inspector() {
        require(msg.sender == final_seller_inspector, "Only Seller can call this.");
        _;
    }
    
    modifier only_final_buyer_inspector() {
        require(msg.sender == final_buyer_inspector, "Only Seller can call this.");
        _;
    }

    modifier inState(State _state) {
        require( current_state == _state, "Invalid state.");
        _;
    }
    modifier inStates(State _state_1 , State _state_2) {
        require( current_state == _state_1 || current_state == _state_2, "Invalid state.");
        _;
    }
    modifier in3States(State _state_1 , State _state_2, State _state_3) {
        require( current_state == _state_1 || current_state == _state_2 || current_state == _state_3, "Invalid state.");
        _;
    }

//      ///////////////////////////  End of  Modifiers  ///////////////////

    constructor(address _token_address, string[5] memory _all_strings, uint[7] memory _all_uints, address _buyer, address _seller, address _vessel_validator,
        address _arbitrator, address _final_seller_inspector
   ){
        require(_token_address != address(0), "constructor: Invalid token address!");
        
        token_address = _token_address;
        Token = IERC20(token_address);
        token_decimals = _all_uints[6];
        token_symbol = _all_strings[4];
                
        goods_name = _all_strings[0];
        unit_name = _all_strings[1];
        loading_point = _all_strings[2];
        seller_extra_data = _all_strings[3];
        
        unit_price = _all_uints[0];
        delivery_time = _all_uints[1];
        penalty_percent = _all_uints[2];
        kyc_deadline = _all_uints[3];
        broker_percent = _all_uints[4];
        demand = _all_uints[5];
        
        // 18000 is equal 5 hours
        require(kyc_deadline > (block.timestamp - 18000), "constructor: kyc_deadline error!");
        require(kyc_deadline < delivery_time, "constructor: kyc_deadline is no less than delivery_time");

        buyer = _buyer;
        seller = _seller;
        arbitrator = _arbitrator;
        vessel_validator = _vessel_validator;
        final_seller_inspector = _final_seller_inspector;
        broker = msg.sender;
        current_state = State.supplied;
        
    }

    function reset_contract (string[4] memory _all_strings, uint[6] memory _all_uints, address _buyer, address _seller, address _vessel_validator,
        address _arbitrator, address _final_seller_inspector) public only_broker{
        
        goods_name = _all_strings[0];
        unit_name = _all_strings[1];
        loading_point = _all_strings[2];
        seller_extra_data = _all_strings[3];
        
        unit_price = _all_uints[0];
        delivery_time = _all_uints[1];
        penalty_percent = _all_uints[2];
        kyc_deadline = _all_uints[3];
        broker_percent = _all_uints[4];
        demand = _all_uints[5];
        
        // 18000 is equal 5 hours
        require(kyc_deadline > (block.timestamp - 18000), "constructor: kyc_deadline error!");
        require(kyc_deadline < delivery_time, "constructor: kyc_deadline is no less than delivery_time");

        depositors_balances[buyer]=0;
        depositors_balances[seller]=0;
        depositors_balances[arbitrator]=0;
        depositors_balances[vessel_validator]=0;
        depositors_balances[final_seller_inspector]=0;
        buyer = _buyer;
        seller = _seller;
        arbitrator = _arbitrator;
        vessel_validator = _vessel_validator;
        final_seller_inspector = _final_seller_inspector;
        current_state = State.supplied;
    }

    function reset_values () public only_broker{
        if (Token.balanceOf(address(this))> 0) {
            Token.transfer(broker,Token.balanceOf(address(this)));
        }
        if (address(this).balance > 0) {
            payable(broker).transfer(address(this).balance);
        }
    }
    
    function Deposit_to_contract() public inState(State.supplied) {

        require( msg.sender == seller || msg.sender == buyer, "Deposit_to_contract: Permission denied! Only Seller and Buyer can call this function.");
        uint total_price = unit_price * demand ;
        uint broker_fee = broker_percent * total_price / PERCENTAGE_RATE;
        uint seller_share = (broker_fee/2) + (total_price * penalty_percent) / PERCENTAGE_RATE;
        uint buyer_share = (broker_fee/2) + total_price;
        
        if(msg.sender == buyer)
        {
            require(Token.balanceOf(buyer) >= buyer_share, "Deposit_to_contract: Buyer Insufficient Funds!");
            require(Token.transferFrom(msg.sender, address(this), buyer_share), "Deposit_to_contract: Failed on transferFrom Buyer!");
            depositors_balances[msg.sender] += buyer_share;
        }
        else
        {
            require(Token.balanceOf(seller) >= seller_share, "Deposit_to_contract: Seller Insufficient Funds!");
            require(Token.transferFrom(msg.sender, address(this), seller_share), "Deposit_to_contract: Failed on transferFrom Seller!");
            depositors_balances[msg.sender] += seller_share;
        }
        
        if(
            (depositors_balances[buyer] >= buyer_share && depositors_balances[seller] >= seller_share) &&
            (Token.balanceOf(address(this)) >= (seller_share + buyer_share))
       ){
            current_state = State.payment_done;
            require(Token.transfer(broker, broker_fee), "Deposit_to_contract: Token broker transfer failed!");
        }
    }

    function contract_termination() public {
        // 18000 is equal 5 hours
        require((block.timestamp-1800)  < kyc_deadline, "contract_termination: kyc_deadline expired!");
        require(current_state != State.disagreement, "contract_termination: current_state != State.disagreement");
        require( msg.sender == seller || msg.sender == buyer , "contract_termination: Permission denied! Only Seller and Buyer can call this function.");
        if(msg.sender == buyer){
            uint new_penalty_value = (demand * unit_price * penalty_percent) / PERCENTAGE_RATE;
            Token.transfer(seller, 2*new_penalty_value);
        }
        Token.transfer(buyer, Token.balanceOf(address(this)));
    }


    function present_ship_and_Qcontroller(address _quality_controller, address _final_buyer_inspector, string memory _vessel_name) public only_buyer inStates(State.payment_done, State.vessel_validator_reject_ship)
    {
        // 18000 is equal 5 hours
        require((block.timestamp-1800) < kyc_deadline, "present_ship_and_Qcontroller: kyc_deadline expired!");
        require((quality_controller == address(0)) || (current_state ==State.vessel_validator_reject_ship), "quality_controller is empty OR current_state == State.vessel_validator_reject_ship");
        quality_controller = _quality_controller;
        final_buyer_inspector = _final_buyer_inspector;
        vessel_name = _vessel_name;
        current_state = State.ship_and_Qcontroller_presented;
    }

    function vessel_validator_accept_reject(bool accepted) public only_vessel_validator inState( State.ship_and_Qcontroller_presented)
    {
        if(accepted == true)
            current_state = State.vessel_validator_accept_ship;
        else
            current_state = State.vessel_validator_reject_ship;
    }

    function quality_controller_accept_reject(bool accepted) public only_quality_controller inStates(State.vessel_validator_accept_ship, State.quality_controller_reject)
    {
        if(accepted == true)
            current_state = State.quality_controller_accept;
        else
            current_state = State.quality_controller_reject;
    }

    function fbi_response(bool is_approved) public inState(State.quality_controller_accept) only_final_buyer_inspector
    {
        if(is_approved){
            shipment_confirmed_by_buyer = true;
            current_state = State.done;
            Token.transfer(seller, Token.balanceOf(address(this)));
        }
        else{
            shipment_disagreement_by_buyer = true;
            if(shipment_confirmed_by_seller) {
                current_state = State.disagreement;
            }
        }
    }

    function fsi_response(bool is_approved) public inState(State.quality_controller_accept) only_final_seller_inspector
    {
        if(is_approved){
            shipment_confirmed_by_seller = true;
            if(shipment_disagreement_by_buyer == true) {
                current_state = State.disagreement;
            }
        }
    }

    function checkout() public inState(State.done)
    {
        bool send = Token.transfer(seller, Token.balanceOf(address(this)));
        require(send, "arbitrator_finalizing: Failed to checkout");
    }

    function get_current_satate() public view returns(State)
    {
        return current_state;
    }
    function get_satate_befor_last_disagrement() public view returns(State)
    {
        return state_befor_disagreement;
    }
    
    function get_state_after_pay_penalty() public view returns(State)
    {
        return state_after_pay_penalty;
    }
    
    function get_seller_address() public view returns(address)
    {
        return seller;
    }

    function get_buyer_address() public view returns(address)
    {
        return buyer;
    }
    
    function get_arbitrator_address() public view returns(address)
    {
        return arbitrator;
    }
    
    function get_vessel_validator_address() public view returns(address)
    {
        return vessel_validator;
    }
    
    function get_quality_controller_address() public view returns(address)
    {
        return quality_controller;
    }
    
    function get_final_seller_inspector_address() public view returns(address)
    {
        return final_seller_inspector;
    }
    
    function get_final_buyer_inspector_address() public view returns(address)
    {
        return final_buyer_inspector;
    }

    // function get_beneficiary_address() public view returns(address)
    // {
    //     return beneficiary;
    // }
    
    function get_penalty_value() public view returns(uint)
    {
        return penalty_value;
    }
    
    function get_penalty_percent() public view returns(uint)
    {
        return penalty_percent;
    }
    
    function get_demand_value() public view returns(uint)
    {
        return demand;
    }
    
    function get_unit_price() public view returns(string memory)
    {
        return unit_price.convertTokenBalance(token_symbol,token_decimals);
    }
    
    function get_loading_point() public view returns(string memory)
    {
        return loading_point;
    }
        
    function get_delivery_time() public view returns(uint)
    {
        return delivery_time;
    }

    function get_vessel_name() public view returns(string memory)
    {
        return vessel_name;
    }

    function get_goods_name() public view returns(string memory)
    {
        return goods_name;
    }
    
    function get_unit_name() public view returns(string memory)
    {
        return unit_name;
    }


    function get_kyc_deadline() public view returns(uint)
    {
        return kyc_deadline;
    }

    function get_current_time() public view returns(uint)
    {
        return block.timestamp;
    }
    
    function get_broker_percent() public view returns(uint)
    {
        return broker_percent;
    }
    
    function get_demand_unit() public view returns(string memory)
    {
        return demand_unit;
    }

    function get_seller_extra_data() public view returns(string memory)
    {
        return seller_extra_data;
    }
    
    function get_seller_share() public view returns(string memory)
    {
        uint _r = uint((unit_price * demand * penalty_percent) / PERCENTAGE_RATE);
        return _r.convertTokenBalance(token_symbol,token_decimals);
    }
    
    function get_payed_by_seller() public view returns(string memory)
    {
        return depositors_balances[seller].convertTokenBalance(token_symbol,token_decimals);
    }

    function get_payed_by_buyer() public view returns(string memory)
    {
        return depositors_balances[buyer].convertTokenBalance(token_symbol,token_decimals);
    }
    
    function get_balance(address depositor_address) public view returns(uint)
    {
        return depositors_balances[depositor_address];
    }
    
    function get_buyer_share() public view returns(string memory)
    {
        return unit_price.convertTokenBalance(token_symbol,token_decimals);
    }

    function token_contract() public view returns (address) {
        return token_address;
    }
   
}