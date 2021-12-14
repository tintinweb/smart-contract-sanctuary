/**
 *Submitted for verification at Etherscan.io on 2021-12-14
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

contract FOB_StableCoin {
    uint private constant PERCENTAGE_RATE = 100*(10**6) ;
    string private goods_name;
    string private unit_name;
    string private seller_extra_data;
    uint private unit_price;
    uint private delivery_time;
    uint private penalty_percent;
    uint private constant ARBITRATOR_PERCENT = 5*(10**6);
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

    address private offender;
    address private beneficiary;
    uint private penalty_value;

    bool private seller_payed_share;
    bool private buyer_payed_share;

    address[] private depositors;

    mapping(address => uint) public depositors_balances;
    
    
    IERC20 private Token;
    address private token_address;
    string private token_symbol;
    string private token_name;
    
    address private complainant;
    string private complaint_title;


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

    constructor(address _token_address, string[4] memory _all_strings, uint[6] memory _all_uints, address _buyer, address _seller, address _vessel_validator,
        address _arbitrator, address _final_seller_inspector
   ){
        require(_token_address != address(0), "constructor: Invalid token address!");
        
        token_address = _token_address;
        Token = IERC20(token_address);
        
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
        
        emit Contarct_Created(seller, buyer, goods_name, unit_price, loading_point, broker_percent);
    }
    
    function Deposit_to_contract() public payable inState(State.supplied) {

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
            emit Buyer_paid_the_amount(buyer, buyer_share);
        }
        else
        {
            require(Token.balanceOf(seller) >= seller_share, "Deposit_to_contract: Seller Insufficient Funds!");
            require(Token.transferFrom(msg.sender, address(this), seller_share), "Deposit_to_contract: Failed on transferFrom Seller!");
            depositors_balances[msg.sender] += seller_share;
            emit Seller_paid_the_amount(seller, seller_share);
        }
        
        if(
            (depositors_balances[buyer] >= buyer_share && depositors_balances[seller] >= seller_share) &&
            (Token.balanceOf(address(this)) >= (seller_share + buyer_share))
       ){
            current_state = State.payment_done;
            require(Token.transfer(broker, broker_fee), "Deposit_to_contract: Token broker transfer failed!");
        }
    }

    function contract_termination() public payable {
        // 18000 is equal 5 hours
        require((block.timestamp-1800)  < kyc_deadline, "contract_termination: kyc_deadline expired!");
        require(current_state != State.disagreement, "contract_termination: current_state != State.disagreement");
        require( msg.sender == seller || msg.sender == buyer , "contract_termination: Permission denied! Only Seller and Buyer can call this function.");
        if(msg.sender == buyer){
            uint new_penalty_value = (demand * unit_price * penalty_percent) / PERCENTAGE_RATE;
            Token.transfer(seller, 2*new_penalty_value);
        }
        Token.transfer(buyer, Token.balanceOf(address(this)));
        emit contarct_terminated();
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
        emit QC_and_ship_presented();
    }

    function vessel_validator_accept_reject(bool accepted) public only_vessel_validator inState( State.ship_and_Qcontroller_presented)
    {
        if(accepted == true)
            current_state = State.vessel_validator_accept_ship;
        else
            current_state = State.vessel_validator_reject_ship;
        emit vessel_validator_is_ok(accepted);
    }

    function quality_controller_accept_reject(bool accepted) public only_quality_controller inStates(State.vessel_validator_accept_ship, State.quality_controller_reject)
    {
        if(accepted == true)
            current_state = State.quality_controller_accept;
        else
            current_state = State.quality_controller_reject;
        emit quality_controller_is_ok(accepted);
    }

    function fbi_response(bool is_approved) public payable inState(State.quality_controller_accept) only_final_buyer_inspector
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

    function fsi_response(bool is_approved) public payable inState(State.quality_controller_accept) only_final_seller_inspector
    {
        if(is_approved){
            shipment_confirmed_by_seller = true;
            if(shipment_disagreement_by_buyer == true) {
                current_state = State.disagreement;
            }
        }
    }

    function arbitrator_finalizing(uint _seller_percent_from_contract_balance) public payable inState(State.disagreement) only_arbitrator {
        uint total_balance = address(this).balance;
        uint arbitrator_share = (total_balance * ARBITRATOR_PERCENT) / PERCENTAGE_RATE;
        total_balance -= arbitrator_share;
        uint seller_share  = (total_balance *_seller_percent_from_contract_balance) / PERCENTAGE_RATE;
        uint buyer_share = total_balance - seller_share;

        Token.transfer(arbitrator, arbitrator_share);
        Token.transfer(seller, seller_share);
        Token.transfer(buyer, buyer_share);
    }

    function checkout() public payable inState(State.done)
    {
        bool send = Token.transfer(seller, Token.balanceOf(address(this)));
        require(send, "arbitrator_finalizing: Failed to checkout");
    }

    function submitting_complaint(string memory _complaint_title) public 
    check(msg.sender == seller || msg.sender == buyer)
    {
        state_befor_disagreement = current_state;
        current_state = State.disagreement;
        complainant = msg.sender;
        complaint_title = _complaint_title;
        emit complaint_submitted(complaint_title);
    }
    
    function arbitrator_command(address _offender, address _beneficiary, uint _penalty_value, State _state_after_pay_penalty) public only_arbitrator inStates(State.disagreement, State.waiting_to_pay_penalty)
    {
        require( (_offender == seller) || (_offender == buyer) || (_offender == address(this)), "arbitrator_command: _offender is not seller or buyer or contract address!");
        require( (_beneficiary == seller) || (_beneficiary == buyer) || (_beneficiary == address(this)), "arbitrator_command: _beneficiary is not seller or buyer or contract address");
        
        state_after_pay_penalty = _state_after_pay_penalty;
        penalty_value = _penalty_value;
        offender = _offender;
        beneficiary = _beneficiary;
        
        current_state = State.waiting_to_pay_penalty;
        if(offender==address(this))
        {
            current_state = state_after_pay_penalty;
            Token.transfer(beneficiary, penalty_value);
        }
    }
    
    function pay_penalty() public payable inState(State.waiting_to_pay_penalty)
    {
        require(Token.transferFrom(msg.sender, address(this), penalty_value), "pay_penalty: Failed on Token.transferFrom");
        // require(msg.sender == offender);
        current_state = state_after_pay_penalty;
        Token.transfer(beneficiary, penalty_value);
    }
    
    function get_current_satate() public view returns(State)
    {
        return current_state ;
    }
    function get_satate_befor_last_disagrement() public view returns(State)
    {
        return state_befor_disagreement ;
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
    
    function get_broker_address() public view returns(address)
    {
        return broker;
    }
     
    function get_offender_address() public view returns(address)
    {
        return offender;
    }
    
    function get_beneficiary_address() public view returns(address)
    {
        return beneficiary;
    }
    
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
    
    function get_unit_price() public view returns(uint)
    {
        return unit_price;
    }
    
    function get_loading_point() public view returns(string memory)
    {
        return loading_point;
    }
        
    function get_delivery_time() public view returns(uint)
    {
        return delivery_time;
    }
    
    function get_complainant_address() public view returns(address)
    {
        return complainant;
    }
    
    function get_complaint_title() public view returns(string memory)
    {
        return complaint_title;
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
    
    function get_seller_share() public view returns(uint)
    {
        return uint((unit_price * demand * penalty_percent) / PERCENTAGE_RATE);
    }
    
    function get_payed_by_seller() public view returns(uint)
    {
        return depositors_balances[seller];
    }
    
    function get_payed_by_buyer() public view returns(uint)
    {
        return depositors_balances[buyer];
    }
    
    function get_buyer_share() public view returns(uint)
    {
        return uint(unit_price * demand);
    }
    
    event Contarct_Created(address seller, address buyer, string goods_name, uint unit_price, string loading_point, uint broker_percent);
    event Buyer_paid_the_amount(address buyer, uint amount);
    event Seller_paid_the_amount(address seller, uint amount);
    event QC_and_ship_presented();
    event contarct_terminated();
    event vessel_validator_is_ok(bool accepted);
    event quality_controller_is_ok(bool accepted);
    event complaint_submitted(string complaint_title);
    
    //  prevent implicit acceptance of ether 
    receive() external payable
    {
         revert();
    }

}