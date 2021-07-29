/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.5.12;


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    function transferFrom(address from, address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}



contract SCOTest{
    using SafeMath for uint;
    
    
    event CtreatedOrder(uint number_contract, address investor);
    event ConfirmOrder(uint number_contract, string status);
    event AnnouncesAmountOrder(uint number_contract, string status);
    event ClosedOrder(uint number_contract, string status);
    
    address public owner;
    
    uint public perion_contract_base = 30 days;
    uint public percentage_of_collateral = 10;
    uint public period_miner_finalization = 5 days;
    uint public count_contracts = 0;
    enum STATE{PENNDING, OPEN, CLOSE, EXEPTION}
    mapping (uint=>STATE) public status_contract;
    mapping (string=>uint) token_balance;
    mapping (string=>address) public token_addres;
    
    
    struct SCO {
        address payable addr_investor;
        address payable addr_miner;
        uint amount_investor;
        uint amount_collateral;
        uint amount_coin_mining;
        string token;
        uint date_contract_start;
        uint date_miner_finalization;
    }
    
    mapping (uint=>SCO) public contracts;
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    
    constructor() public {
        owner = msg.sender;
    }
    
    function setAddressToken(address _addr, string calldata _symbol) onlyOwner external  returns (bool){
       token_addres[_symbol] = _addr;
       token_balance[_symbol] = 0;
       return true;
    }
    
    
    function getBalanceToken(string memory _symbol) public view returns (uint _balance){
        ERC20Basic b = ERC20Basic(token_addres[_symbol]);
        return b.balanceOf(address(this));
    }
    
    function sendTokens(string memory _symbol, uint amount, address _to) internal  returns (bool _is_ok){
        require(getBalanceToken(_symbol) >= amount, "contract dont have tokens");
        ERC20Basic b = ERC20Basic(token_addres[_symbol]);
        b.transfer(_to, amount);
        token_balance[_symbol] -= amount;
        
        return true;
    }
    
    
    function checkBalanceToken(string memory _symbol, uint amount) internal  returns (bool _is_check){
      uint bal = getBalanceToken(_symbol);
      if (bal > 0 && token_balance[_symbol] + amount <= bal){
           token_balance[_symbol] += amount;
           return true;
      }else{
          return false;
      }
    }
    
    function balanceOfOwner() external view returns (uint){
        return owner.balance;
    }
    
    function balanceOf() public view returns(uint){
        return address(this).balance;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    
    function setPercent(uint _p) public onlyOwner {
        percentage_of_collateral = _p;
    }
    
    function setPeriodContract(uint _p) public onlyOwner {
        perion_contract_base = _p;
    }
    
    function setPeriodMinerFinal(uint _p) public onlyOwner {
        period_miner_finalization = _p;
    }
    
    function withStrs(string memory a, string memory b) public pure returns (uint){
        if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))) {
          return 1;
        }
        return 0;
    }
    
    function getCountContracts() external view returns(uint){
        return count_contracts;
    }
    
    
    function getContractById(uint _id_contract) external view returns (address _addr_investor,
                                                                        address _addr_mining, 
                                                                        uint _amount_investor, 
                                                                        uint _amount_collateral,
                                                                        string memory _token)
    {
        
        
        return (contracts[_id_contract].addr_investor, 
                contracts[_id_contract].addr_miner, 
                contracts[_id_contract].amount_investor,
                contracts[_id_contract].amount_collateral, 
                contracts[_id_contract].token);
    }
    
    function getStatusContractById(uint _id_contract) external view returns(string memory){
        if (status_contract[_id_contract] == STATE.OPEN){
            if (contracts[_id_contract].amount_investor > 0){
                return "open investor";
            }else{
                return "open miner";
            }
        }
        if (status_contract[_id_contract] == STATE.PENNDING){
             return "pennding";
        }
        if (status_contract[_id_contract] == STATE.EXEPTION){
            return "exeption";
        }
        if (status_contract[_id_contract] == STATE.CLOSE){
            return "close";
        }
        return "not found";
         
     }
    
    
    function investorCreateOrder(uint _amount_investor, string memory _token) public returns (uint _id_contract) {
        ERC20Basic b = ERC20Basic(token_addres[_token]);
        uint bal_before = getBalanceToken(_token);
        b.transferFrom(msg.sender, address(this), _amount_investor);
        uint bal_after = getBalanceToken(_token);
        assert(bal_before + _amount_investor <= bal_after);
        require(checkBalanceToken(_token, _amount_investor) == true, "you dont give tokens");
        
        SCO memory new_contract;
        count_contracts++;
        
        new_contract.addr_investor =  msg.sender;
        new_contract.amount_investor = _amount_investor;
        new_contract.token =  _token;
        new_contract.amount_collateral = _amount_investor.mul(percentage_of_collateral).div(100);
        
        contracts[count_contracts] = new_contract;
        status_contract[count_contracts] = STATE.OPEN;
        emit CtreatedOrder(count_contracts,  msg.sender);
        return count_contracts;

    }
    
        function minerCreateOrder(uint _amount_miner, string memory _token) public returns (uint _id_contract) {
        ERC20Basic b = ERC20Basic(token_addres[_token]);
        uint bal_before = getBalanceToken(_token);
        b.transferFrom(msg.sender, address(this), _amount_miner);
        uint bal_after = getBalanceToken(_token);
        assert(bal_before + _amount_miner <= bal_after);
        require(checkBalanceToken(_token, _amount_miner) == true, "you dont give tokens");
        
        SCO memory new_contract;
        count_contracts++;
        
        new_contract.addr_miner =  msg.sender;
        new_contract.amount_investor = _amount_miner.div(percentage_of_collateral).mul(100);
        new_contract.token =  _token;
        
        new_contract.amount_collateral = _amount_miner;
        
        contracts[count_contracts] = new_contract;
        status_contract[count_contracts] = STATE.OPEN;
        emit CtreatedOrder(count_contracts,  msg.sender);
        return count_contracts;

    }
    

    function minerConfirmOrder(uint _id_contract) public returns(bool _status){
        require( status_contract[_id_contract] == STATE.OPEN, "contract not open");
        ERC20Basic b = ERC20Basic(token_addres[contracts[_id_contract].token]);
        uint bal_before = getBalanceToken(contracts[_id_contract].token);
        b.transferFrom(msg.sender, address(this), contracts[_id_contract].amount_collateral);
        uint bal_after = getBalanceToken(contracts[_id_contract].token);
        assert(bal_before + contracts[_id_contract].amount_collateral <= bal_after);
        
        require(checkBalanceToken(contracts[_id_contract].token, contracts[_id_contract].amount_collateral) == true, "you dont give tokens");
        
        contracts[_id_contract].date_contract_start = now;
        contracts[_id_contract].addr_miner =  msg.sender;
        status_contract[_id_contract] = STATE.PENNDING;
        emit ConfirmOrder(_id_contract, "PENNDING");
        return true;
        
    }
    
        function investorConfirmOrder(uint _id_contract) public returns(bool _status){
        require( status_contract[_id_contract] == STATE.OPEN, "contract not open");
        ERC20Basic b = ERC20Basic(token_addres[contracts[_id_contract].token]);
        uint bal_before = getBalanceToken(contracts[_id_contract].token);
        
        b.transferFrom(msg.sender, address(this), contracts[_id_contract].amount_investor);
        uint bal_after = getBalanceToken(contracts[_id_contract].token);
        assert(bal_before + contracts[_id_contract].amount_investor <= bal_after);
        
        require(checkBalanceToken(contracts[_id_contract].token, contracts[_id_contract].amount_collateral) == true, "you dont give tokens");
        
        contracts[_id_contract].date_contract_start = now;
        contracts[_id_contract].addr_investor =  msg.sender;
        status_contract[_id_contract] = STATE.PENNDING;
        emit ConfirmOrder(_id_contract, "PENNDING");
        return true;
        
    }
    
    
    function oracleAnnouncesAmount(uint _id_contract, uint _coin_mining) external onlyOwner{
        require( status_contract[_id_contract] == STATE.PENNDING, "contract not pennding");
        
        contracts[_id_contract].amount_coin_mining = _coin_mining;
        contracts[_id_contract].date_miner_finalization = now;
        status_contract[_id_contract] = STATE.EXEPTION;
        emit AnnouncesAmountOrder(_id_contract, "EXEPTION");
    }
    
    function minerPaidObligation(uint _id_contract) public payable{
        require( status_contract[_id_contract] == STATE.EXEPTION, "contract not exeption");
        require(contracts[_id_contract].addr_miner == msg.sender, "you are not miner");
        require(contracts[_id_contract].date_miner_finalization + period_miner_finalization >= now, "you are lose");
        require(contracts[_id_contract].amount_coin_mining <= msg.value, "give me more money");
        require(balanceOf() >= contracts[_id_contract].amount_coin_mining,  "contract dont have eth");
        
        
        sendTokens(contracts[_id_contract].token,
                    contracts[_id_contract].amount_investor.add(contracts[_id_contract].amount_collateral),
                    contracts[_id_contract].addr_miner);
                    
        contracts[_id_contract].addr_investor.transfer(contracts[_id_contract].amount_coin_mining);
        status_contract[_id_contract] = STATE.CLOSE;
        emit ClosedOrder(_id_contract, "CLOSE");

    }
    
    function investorTakesPrepayment(uint _id_contract) external {
        require( status_contract[_id_contract] == STATE.EXEPTION, "contract not exeption");
        require(contracts[_id_contract].addr_investor == msg.sender, "you are not investor");
        require(contracts[_id_contract].date_miner_finalization + period_miner_finalization <= now);
        
        sendTokens(contracts[_id_contract].token,
                    contracts[_id_contract].amount_investor.add(contracts[_id_contract].amount_collateral),
                    contracts[_id_contract].addr_investor);
        
        status_contract[_id_contract] = STATE.CLOSE;
        emit ClosedOrder(_id_contract, "CLOSE");

    }
    
}