/**
 *Submitted for verification at Etherscan.io on 2020-11-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.6.99 <0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC1363Receiver {
    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data) external returns (bytes4); // solhint-disable-line  max-line-length
}

interface IERC1363Spender {
    function onApprovalReceived(address owner, uint256 value, bytes calldata data) external returns (bytes4);
}

contract Ballot is IERC1363Spender, IERC1363Receiver{   
    using SafeMath for uint256;

    bytes4 internal constant _INTERFACE_ID_ERC1363_RECEIVER = 0x88a7ca5c;
    bytes4 internal constant _INTERFACE_ID_ERC1363_SPENDER = 0x7b04a2d0;

    struct Voter{
        uint256 weight;
        bool voted;
    }
    mapping(address => Voter) private _voters;
    address [] _voters_list;
    
    IERC20 private _token_contract;
    address private _token_contract_address;
    address private _receive_address;
    address private _owner;

    uint256 public _period;

    //need to be update
    uint256 public _end_time;
    uint256 private _pool;
    uint256 private _y_pool; // stat-pool: Yes
    uint256 private _n_pool; // stat-pool: No
    uint256 private _threshold; 
    
    uint256 private _state;

    //Event
    event Transfer(address indexed from, uint256 value);
    event StartVote(address indexed to, uint256 end_time);
    event Vote(address indexed from, uint256 state, bool agree, uint256 weight);

    constructor(address  token_contract){
        _token_contract_address = token_contract;
        _token_contract = IERC20(token_contract);
        _owner = msg.sender;
        _period = 2419200; // 4 weeks

    }
    // ERC1363 Receiver
    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data) public override returns(bytes4){
        // state check
        require(_state == 0, "Token collection not start");
        require(msg.sender == _token_contract_address, "Not called from valid token contract");
        require(value > 0, "Not valid value");

        record(from, value);
        return _INTERFACE_ID_ERC1363_RECEIVER;
    }
    // ERC1363 Spender
    function onApprovalReceived(address owner, uint256 value, bytes calldata data) public override returns(bytes4){
        //state check
        require(_state == 0, "Token collection not start");
        require(msg.sender == _token_contract_address, "Not called from valid token contract");
        require(value > 0, "Not valid value");
        require(_token_contract.transferFrom(owner, address(this), value),"Invalid transferFrom call");

        record(owner, value);
        return _INTERFACE_ID_ERC1363_SPENDER;
    }
    // ERC20
    function transferToken(address owner, uint256 value) public{
        //state check
        require(_state == 0, "Token collection not start");
        require(value > 0, "Not valid value");
        require (_token_contract.transferFrom(owner,address(this),value), "Invalid transferFrom call");

        record(owner, value);
    }
    
    function weightOf(address voter) public view returns(uint256){
        return _voters[voter].weight;
    }

    function record(address voter, uint256 value) private{
        _voters_list.push(voter);
        _voters[voter].weight = _voters[voter].weight.add(value);
        _pool = _pool.add(value);

        emit Transfer(voter, value);
    }

    function stopCollection(address receiveAddress) public{
        //state check
        require(_state == 0, "Not proper state");

        require(msg.sender == _owner, "Not valid owner address");
        require(receiveAddress != address(this), "Please use different address");

        //check receive enough balance, no less than _pool
        require(_token_contract.balanceOf(address(this)) >= _pool, "Not enough balance");

        _state = 1;
        _threshold = _pool.div(2);
        _receive_address = receiveAddress;
        _end_time = block.timestamp.add(_period); //currentTime + 4 weeks

        emit StartVote(receiveAddress, _end_time);
    }

    function submitVote(uint256 state, bool agree) public returns(bool){
        if (block.timestamp > _end_time && _end_time != 0){
            tokenManagement();
            reset();
            return false;
        }

        //state check
        require(_state != 0, "Not voting time");
        require(_state == state, "Not expected stage");

        require(_voters[msg.sender].weight > 0, "Not valid voter");
        require(!_voters[msg.sender].voted, "Already vote");

        _voters[msg.sender].voted = true;
        uint256 weight = _voters[msg.sender].weight;
        
        if (agree){
            _y_pool = _y_pool.add(weight);
        } else {
            _n_pool = _n_pool.add(weight);
        }

        emit Vote(msg.sender, _state, agree, weight);

        tally();
        return true;
    }
    
    function tally() public returns(string memory) {
        require(_state != 0, "Not tally time");
        string memory result;

        if (block.timestamp > _end_time && _end_time != 0){
            tokenManagement();
            reset();
            result = "Time out";
        }

        if (_y_pool >= _threshold){
            if (_state == 3){
                require(_token_contract.balanceOf(address(this)) >= _pool, "Not enough balance");
                _token_contract.transfer(_receive_address, _pool);
                reset();
            } else{
                clearVote();
            }
            result = "Success";
        }else if (_n_pool > _threshold){
            tokenManagement();
            reset();
            result = "Fail";
        }else{
            result = "On going";
        }

        return result;
    }

    // Action if > 50% N votes
    function tokenManagement() private {
        //based on _state, calculate percent
        require(_token_contract.balanceOf(address(this)) >= _pool, "Not enough balance");
    
        if (_state == 1){
            for (uint i = 0; i < _voters_list.length ; i++){
                _token_contract.transfer(_voters_list[i],_voters[_voters_list[i]].weight);
            }
        } else if (_state == 2){
            for (uint i = 0; i < _voters_list.length ; i++){
                uint256 value = _voters[_voters_list[i]].weight.mul(8).div(10);
                _token_contract.transfer(_voters_list[i],value);
                _pool = _pool.sub(value);
            }
            _token_contract.transfer(_receive_address, _pool);
        } else if (_state == 3){
            for (uint i = 0; i < _voters_list.length ; i++){
                uint256 value = _voters[_voters_list[i]].weight.div(10);
                _token_contract.transfer(_voters_list[i],value);
                _pool = _pool.sub(value);
            }
            _token_contract.transfer(_receive_address, _pool);
        }
    }

    function clearVote() private{
        for (uint i = 0; i < _voters_list.length ; i++){
            _voters[_voters_list[i]].voted = false;
        }
        _y_pool = 0;
        _n_pool = 0;
        _state += 1;
        _end_time = block.timestamp.add(_period);
    }

    function reset() private{
        for (uint i = 0; i < _voters_list.length ; i++){
            _voters[_voters_list[i]].weight = 0;
            _voters[_voters_list[i]].voted = false;
        }
        delete _voters_list;

        _end_time = 0;
        _pool = 0;
        _n_pool = 0;
        _y_pool = 0;
        _threshold = 0;
        _state = 0;
    }

}