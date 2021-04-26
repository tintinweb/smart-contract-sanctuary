/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// File: contracts/utils/AddressArray.sol

pragma solidity >=0.4.21 <0.6.0;

library AddressArray{
  function exists(address[] memory self, address addr) public pure returns(bool){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return true;
      }
    }
    return false;
  }

  function index_of(address[] memory self, address addr) public pure returns(uint){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return i;
      }
    }
    require(false, "AddressArray:index_of, not exist");
  }

  function remove(address[] storage self, address addr) public returns(bool){
    uint index = index_of(self, addr);
    self[index] = self[self.length - 1];

    delete self[self.length-1];
    self.length--;
    return true;
  }
}

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/assets/TokenBankInterface.sol

pragma solidity >=0.4.21 <0.6.0;

contract TokenBankInterface{
  function issue(address token_addr, address payable _to, uint _amount) public returns (bool success);
}

// File: contracts/ERC20SalaryV2.sol

pragma solidity >=0.4.21 <0.6.0;





contract ERC20SalaryV2 is Ownable{
  using SafeMath for uint;
  using AddressArray for address[];

  struct employee_info{
    uint salary;
    uint period;
    uint total;
    uint claimed;
    uint last_block_num;
    uint pause_block_num;
    address leader;
    bool paused;
    bool exists;
  }

  TokenBankInterface public erc20bank;
  address public target_token;
  string public token_name;
  address[] public employee_accounts;
  mapping (address => employee_info) public employee_infos;

  event ClaimedSalary(address account, address to, uint amount);

  constructor(string memory _name, address _target_token, address _erc20bank) public{
    token_name = _name;
    target_token = _target_token;
    erc20bank = TokenBankInterface(_erc20bank);
  }

  function change_token_bank(address _addr) public onlyOwner{
    require(_addr != address(0x0), "invalid address");
    erc20bank = TokenBankInterface(_addr);
  }

  function unclaimed_amount() public view returns(uint){
    uint total = 0;
    for(uint i = 0; i < employee_accounts.length; ++i){
      uint p = get_unclaimed_period(employee_accounts[i]);
      uint t = employee_infos[employee_accounts[i]].total.safeSub(employee_infos[employee_accounts[i]].claimed);
      uint s = employee_infos[employee_accounts[i]].salary;
      total = total.safeAdd(p.safeMul(s));
      total = total.safeAdd(t);
    }
    return total;
  }

  function add_employee(address account, uint last_block_num, uint period, uint salary, address leader)
    public onlyOwner
    returns(bool)
    {
      require(account != address(0));
      require(last_block_num >0);
      require(period > 0);
      require(salary > 0);
      require(leader != account, "cannot be self leader");
      if(employee_infos[account].exists) return false;
      _primitive_init_employee(account, last_block_num, 0, false, period, salary, 0, 0, leader);
      return true;
    }

    function add_employee_with_meta(address account, uint last_block_num,
                                    uint pause_block_num, bool paused, uint period,
                                    uint salary, uint total, uint claimed, address leader)
    public onlyOwner
    returns(bool)
      {
      _primitive_init_employee(account, last_block_num, pause_block_num, paused, period, salary, total, claimed, leader);
      return true;
    }

    function _primitive_init_employee(address account, uint last_block_num,
                                     uint pause_block_num, bool paused, uint period,
                                     uint salary, uint total, uint claimed, address leader) internal{
      if(!employee_infos[account].exists) {
        employee_accounts.push(account);
      }

      employee_infos[account].salary = salary;
      employee_infos[account].period = period;
      employee_infos[account].total = total;
      employee_infos[account].claimed = claimed;
      employee_infos[account].last_block_num = last_block_num;
      employee_infos[account].pause_block_num = pause_block_num;
      employee_infos[account].leader = leader;
      employee_infos[account].paused = paused;
      employee_infos[account].exists = true;
    }

    function remove_employee(address account) public onlyOwner{
      _remove_employee(account);
    }

    function _remove_employee(address account) internal returns(bool){
      if(!employee_infos[account].exists) return false;
      employee_accounts.remove(account);
      delete employee_infos[account];
      return true;
    }

    function change_employee_period(address account, uint period) public onlyOwner{
      require(employee_infos[account].exists);
      _update_salary(account);
      employee_infos[account].period = period;
    }

    function change_employee_salary(address account, uint salary) public onlyOwner{
      require(employee_infos[account].exists);
      _update_salary(account);
      employee_infos[account].salary= salary;
    }

    function change_employee_leader(address account, address leader) public onlyOwner{
      require(employee_infos[account].exists);
      require(account != leader, "account cannot be self leader");
      _update_salary(account);
      employee_infos[account].leader = leader;
    }

    function change_employee_status(address account, bool pause) public onlyOwner{
      require(employee_infos[account].exists);
      require(employee_infos[account].paused != pause, "status already done");
      _update_salary(account);
      _change_employee_status(account, pause);
    }

    function _change_employee_status(address account, bool pause) internal {
      employee_infos[account].paused = pause;
      employee_infos[account].pause_block_num = (block.number - employee_infos[account].pause_block_num);
    }

    function change_subordinate_period(address account, uint period) public {
      require(employee_infos[account].exists);
      require(employee_infos[account].leader == msg.sender, "not your subordinate");
      _update_salary(account);
      employee_infos[account].period = period;
    }
    function change_subordinate_salary(address account, uint salary) public {
      require(employee_infos[account].exists);
      require(employee_infos[account].leader == msg.sender, "not your subordinate");

      employee_infos[account].salary = salary;
    }
    function change_subordinate_status(address account, bool pause) public {
      require(employee_infos[account].exists);
      require(employee_infos[account].leader == msg.sender, "not your subordinate");
      _update_salary(account);
      _change_employee_status(account, pause);
    }

    function get_unclaimed_period(address account) public view returns(uint){
      employee_info storage ei = employee_infos[account];
      uint t = block.number.safeSub(ei.pause_block_num);
      t = t.safeSub(ei.last_block_num).safeDiv(ei.period);
      return t;
    }
    function _update_salary(address account) private {
      employee_info storage ei = employee_infos[account];
      if(ei.paused) return ;
      uint p = get_unclaimed_period(account);
      if(p == 0) return ;
      ei.total = ei.total.safeAdd(p.safeMul(ei.salary));
      ei.last_block_num = ei.last_block_num.safeAdd(p.safeMul(ei.period));
    }

    function update_salary(address account) public{
      require(employee_infos[account].exists, "not exist");
      _update_salary(account);
    }

    function claim_salary(address payable to, uint amount) public returns(bool){
      require(employee_infos[msg.sender].exists, "not exist");
      _update_salary(msg.sender);
      employee_info storage ei = employee_infos[msg.sender];
      require(ei.total.safeSub(ei.claimed) >= amount, "no balance");

      ei.claimed  = ei.claimed.safeAdd(amount);
      erc20bank.issue(target_token, to, amount);

      emit ClaimedSalary(msg.sender, to, amount);
      return true;
    }

    function get_employee_count() public view returns(uint){
      return employee_accounts.length;
    }

    function get_employee_info_with_index(uint index) public view returns(uint salary, uint period, uint total, uint claimed, uint last_claim_block_num, uint paused_block_num, bool paused, address leader){
      require(index >= 0 && index < employee_accounts.length);
      address account = employee_accounts[index];
      require(employee_infos[account].exists);
      return get_employee_info_with_account(account);
    }

    function get_employee_info_with_account(address account) public view returns(uint salary, uint period, uint total,
                                                                                 uint claimed, uint last_claim_block_num, uint paused_block_num, bool paused, address leader){
      require(employee_infos[account].exists);
      salary = employee_infos[account].salary;
      period = employee_infos[account].period;
      total = employee_infos[account].total;
      claimed = employee_infos[account].claimed;
      last_claim_block_num = employee_infos[account].last_block_num;
      leader = employee_infos[account].leader;
      paused = employee_infos[account].paused;
      paused_block_num = employee_infos[account].pause_block_num;
    }
}

contract ERC20SalaryV2Factory{
  event NewERC20Salary(address addr);
  function createERC20SalaryV2(string memory name, address target_token, address erc20bank) public returns(address){
    ERC20SalaryV2 salary = new ERC20SalaryV2(name, target_token, erc20bank);
    emit NewERC20Salary(address(salary));
    salary.transferOwnership(msg.sender);
    return address(salary);
  }
}