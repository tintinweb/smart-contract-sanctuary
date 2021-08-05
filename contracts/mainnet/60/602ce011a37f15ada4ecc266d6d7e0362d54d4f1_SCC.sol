/**
 *Submitted for verification at Etherscan.io on 2020-10-14
*/

/**
 *Submitted for verification at Etherscan.io on 2019-09-04
*/

/**
 *Submitted for verification at Etherscan.io on 2019-08-20
*/

pragma solidity ^0.5.17;

// ----------------------------------------------------------------------------------------------
// An ERC20 standard
//
// author:SCC Team

contract ERC20Interface {
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SCC is ERC20Interface {
    uint256 public constant decimals = 18;

    string public constant symbol = "SCC";
    string public constant name = "Shared Charging Coin & Energy Token";

    uint256 public _totalSupply = 1000000000*(10 ** 18);

    // Owner of this contract
    address public owner;

    // Balances SDAAC for each account
    mapping(address => uint256) private balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) private allowed;

    // List of approved investors
    mapping(address => bool) private approvedInvestorList;

    // deposit
    // mapping(address => uint256) private deposit;

    // totalTokenSold
    // uint256 public totalTokenSold = 0;


    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
      if(msg.data.length < size + 4) {
        revert();
      }
      _;
    }



    /// @dev Constructor
    
    constructor() public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    /// @dev Gets totalSupply
    /// @return Total supply
    function totalSupply()
        public view returns (uint256) {
        return _totalSupply;
    }

    /// @dev Gets account's balance
    /// @param _addr Address of the account
    /// @return Account balance
    function balanceOf(address _addr)
        public view returns (uint256) {
        return balances[_addr];
    }

    /// @dev check address is approved investor
    /// @param _addr address
    function isApprovedInvestor(address _addr)
        public view returns (bool) {
        return approvedInvestorList[_addr];
    }

    /// @dev get ETH deposit
    /// @param _addr address get deposit
    /// @return amount deposit of an buyer
    // function getDeposit(address _addr)
    //     public constant returns(uint256){
    //         return deposit[_addr];
    //     }


    /// @dev Transfers the balance from msg.sender to an account
    /// @param _to Recipient address
    /// @param _amount Transfered amount in unit
    /// @return Transfer status
    function transfer(address _to, uint256 _amount)
        public returns (bool success) {
            
        // if sender's balance has enough unit and amount >= 0,
        //      and the sum is not overflow,
        // then do transfer
        require(_to != address(0));
        require((balances[msg.sender] >= _amount) && (_amount >= 0) && (balances[_to] + _amount > balances[_to]));
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        success = true;
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
    public returns (bool success) {
        require(balances[_from] >= _amount && _amount > 0);
        require(allowed[_from][msg.sender] >= _amount);
        require(balances[_to] + _amount > balances[_to]);
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        success =  true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)
        public

        returns (bool success) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    // get allowance
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function () external payable {
        revert();
    }
}