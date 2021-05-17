/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    ___________________________________________________________________
      _      _                                        ______           
      |  |  /          /                                /              
    --|-/|-/-----__---/----__----__---_--_----__-------/-------__------
      |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
    __/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_
    


------------------------------------------------------------------------------------------------------
 Copyright (c) 2019 Onwards dExpert Inc. ( https://xxxxxxxx.io )
 Contract designed with ❤ by EtherAuthority  ( https://EtherAuthority.io )
------------------------------------------------------------------------------------------------------
*/

//*******************************************************************
//------------------------ SafeMath Library -------------------------
//*******************************************************************
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface BUSDERC20 {

    //function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);

}

contract ERC20Basic is BUSDERC20 {

    string public constant name = "ERC20Basic";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 18;  


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_ = 10 ether;

    using SafeMath for uint256;
    
    address public signer_wallet;
    address public dexpert_wallet;
    

    constructor() public {  
	    balances[msg.sender] = totalSupply_;
	    signer_wallet = msg.sender;
	    dexpert_wallet = msg.sender;
    }  

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}


contract Dexpert is ERC20Basic{
    
    //BUSDERC20 public token;
    
    using SafeMath for uint256;
    
    uint private projectId;
    
    enum projectStatus { STARTED, DESPUTED, ONHOLD, DELIVERED, COMPLETED }
    //projectStatus constant defaultChoice = projectStatus.STARTED;
    
    event ev_create_project(uint project_id, string project_title, uint project_budget, uint initial_payment, uint project_deadline, address client_wallet, address dexpert_wallet, projectStatus project_status);
    event ev_project_delivered(uint project_id, projectStatus project_status);
    event ev_project_completed(uint project_id, projectStatus project_status);
    event ev_project_status_update(uint project_id, projectStatus project_status);
    event ev_project_topup(uint project_id, uint topup_amount);
    
    constructor() {
        projectId = 0;
    }
    
    struct Projects {
        uint project_id;
        string project_title;
        uint project_budget;
        uint initial_payment;
        uint project_deadline;
        address client_wallet;
        address dexpert_wallet;
        projectStatus project_status;
    }
    
    mapping(uint => Projects) public projects;
    //mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
    // contract accepts incoming ether -  this needed in case owner want to fund refPool
    
    function createProject(string memory _project_title, uint _project_budget, uint _initial_payment, uint _project_deadline, address _client_wallet, address _dexpert_wallet) public {
        
        require(msg.sender == ERC20Basic.signer_wallet, "Only signer can call this function.");
        
        require(bytes(_project_title).length > 0, "Please enter project title.");
        require(_project_budget > 0, "Please enter project title.");
        
        projectId = (projectId + 1);
        
        Projects memory newProj = Projects({
            project_id:  projectId,
            project_title: _project_title,
            project_budget: _project_budget,
            initial_payment: _initial_payment,
            project_deadline: _project_deadline,
            client_wallet: _client_wallet,
            dexpert_wallet: _dexpert_wallet,
            project_status: projectStatus.STARTED
        });
        
        projects[projectId] = newProj;
        
        emit ev_create_project(projectId, _project_title, _project_budget, _initial_payment, _project_deadline, _client_wallet, _dexpert_wallet, projectStatus.STARTED);
    }
    
    
    function topUpProject(uint256 _project_id, uint _topup_amount) public payable {
       
        require(_topup_amount > 0);
        Projects storage project_obj = projects[_project_id];
        project_obj.project_budget = project_obj.project_budget.add(_topup_amount);
        
        require(ERC20Basic.dexpert_wallet != project_obj.dexpert_wallet);
        
        //BUSDERC20(ERC20Basic.dexpert_wallet).transferFrom(msg.sender, address(this), _topup_amount);
        
        //busdtoken.transferFrom(msg.sender, address(this), _topup_amount);
        
        require(ERC20Basic(ERC20Basic.dexpert_wallet).transferFrom(msg.sender, address(this), _topup_amount), 'tokens could not be transferred.');
        
        //require(ERC20Essential(token).transferFrom(msg.sender, address(this), _topup_amount), 'Tokens could not be transferred');
        //tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
        //emit Deposit(now, token, msg.sender, amount, tokens[token][msg.sender]);
        
        emit ev_project_topup(_project_id, _topup_amount);
    }
    
    function updateProjectStatus(uint256 _project_id, projectStatus _project_status) public {
       
        Projects storage project_obj = projects[_project_id];
        project_obj.project_status = _project_status;
        
        emit ev_project_status_update(_project_id, _project_status);
    }
    
    function projectMarkDelivered(uint _project_id) public {
        
        require(msg.sender == ERC20Basic.dexpert_wallet, "Only dexpert can call this function.");
        
        Projects storage project_obj = projects[_project_id];
        project_obj.project_status = projectStatus.DELIVERED;
        emit ev_project_delivered(_project_id, projectStatus.DELIVERED);
    }
    
    function projectComplete(uint _project_id) public {
        
        require(msg.sender == ERC20Basic.dexpert_wallet, "Only dexpert can call this function.");
        
        Projects storage project_obj = projects[_project_id];
        project_obj.project_status = projectStatus.COMPLETED;
        emit ev_project_completed(_project_id, projectStatus.COMPLETED);
        
    }

}