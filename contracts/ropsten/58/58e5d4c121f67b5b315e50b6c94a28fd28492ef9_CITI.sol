/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;


    // 0.01 ether contributors Address and details are stored ________________ Completed;
    
    // set time limit for registration ____________________________ inProgress;
    

contract Math {

    
    function add(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    } 

    function sub(uint256 x, uint256 y) internal pure returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
    function div(uint256 x, uint256 y)internal pure returns(uint256){
        uint256 z = x / y;
        assert(x != 0 && y != 0);
        return z;
    }
    
}



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20  {
    //@dev Returns the amount of tokens in existence.
     
    //function totalSupply() external view returns (uint256);

    // @dev Returns the amount of tokens owned by `account`.
     
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract CITI is IERC20,Context {
    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private allowances;

    uint256 totalSupply = 1000000000e18;
    string public name = "Decentralized Citien Network";
    string public symbol = "CITI";
    //uint public constant decimals = 18;
   /** string name;
    string private symbol;*/

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        balances[msg.sender] += totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     */
    

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual  returns (uint8) {
        return 18;
    }

     
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            balances[sender] = senderBalance - amount;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

   

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = accountBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
contract sfdgfh is  Math {
    
    
    uint256 public endBlock = 10959999;
    event CreateDCT(address indexed _to, uint256 _value);    
    mapping(address => uint)public contributions;
    address public creator;
    address public vb;
   
    
    /**modifier _onlyCreator(){
        require(msg.sender == creator,"only creator can view details");
        _;
    }*/
    
    struct Applicant {
        address contributorsAddress;
        uint amount;
        uint applicantID;
        string eMailID;
    }
    Applicant[] public Citizen;
    uint nextId = 1;
    
    address[] public Address;
    
    //  15000000
    //  14800000
    modifier _checkAddr(){
        for (uint i = 0; i < Address.length; i++){
        require(msg.sender != Address[i], "you are already registered");
        }
        _;
    }
    
    event success(uint applicantID);
    //error retryWith(string, uint);
    function citizenCount() public view returns(uint noOfCitizens){
        return noOfCitizens = Address.length;
    }
        /** public payable function applicationForCitizenship recieves ether
         * registers the msg.sender, creates and sends tokens to that Address in proportion to contribution
         * with in the preset timeStamp, ths creted tokens is the totalSupply
         * after the timeStamp only application fee is taken and registers the citizen but no new tokens are created.
         */
   
    function applicationForCitizenship(string memory _eMailID)  _checkAddr  public payable   { 
        if(msg.value > 0.01 ether  && block.number < endBlock){
        payable(creator).transfer(msg.value);
        contributions[msg.sender] = contributions[msg.sender] + (msg.value);
        
        Citizen.push(Applicant({contributorsAddress : (msg.sender), amount : div(msg.value,(10**14)), applicantID : nextId, eMailID : _eMailID}));
        nextId++;
        Address.push(msg.sender);
        uint toSender;
        toSender = div(msg.value,(10**14));
        
        emit success(nextId); 
        } 
    }    
    
        // private function for only creator to view the applicantDetails
        // in order to maintain user privacy contributors E-Mail address kept private
    function applicantDetails(address contributorsAddress) internal view   returns (address addr /**,uint amount,uint citizenID, string memory eMailID*/) {
        for (uint i=0 ; i < Citizen.length ; i++) {
            if(Citizen[i].contributorsAddress == contributorsAddress ){
                return (Citizen[i].contributorsAddress/**, Citizen[i].amount, Citizen[i].applicantID, Citizen[i].eMailID*/);
            } 
        }
    }
    
    
}


/**contract InfrastructureDevelopment is StandardToken {  
    
    
    address public elector; // elected representative
    mapping(address => voter) public voters;
    mapping(address => uint) public fund;
    uint endReg;
    
    
    struct proposal{
        uint proposalID;
        string projectName;
        address proposer;
        uint budget;
        uint voteCount;
    }
    struct voter {
        bool voted;
        uint voteIndex;
        uint weight;
    }
    proposal[] public proposals;
    uint nextProposalID = 1;
    
    modifier _onlyElector(){
        require (elector == msg.sender,"not a elector");
        _;
    }
    
    modifier _check(){
        require(block.number < endReg, "voting process completed");
        _;
    }
    
    event winner(uint proposalID,string  projectName,address proposer,uint budget, uint voteCount);
    
    function setEnd(uint _endReg) public {
        endReg = _endReg;
    }
    
    function proposalRegistry(string memory _projectName, address _proposer, uint _budget) public _onlyElector  {
        proposals.push(proposal({proposalID : nextProposalID, projectName : _projectName, proposer : _proposer, budget : _budget, voteCount : 0 }));
        nextProposalID++;
    }
    
    function vote(uint voteIndex) public {
        if(balances[msg.sender] > 0){
            require(!voters[msg.sender].voted,"you are already voted"); 
            voters[msg.sender].weight = 1; 
            voters[msg.sender].voted = true;
            voters[msg.sender].voteIndex = voteIndex;
            proposals[voteIndex].voteCount += voters[msg.sender].weight;
        } 
    }
    
    function winningProject() public view returns (address winningProposalAddress) {
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalAddress = proposals[i].proposer;
            }
        }
        
    }
    
    function fundProject() public  payable {
        payable(winningProject()).transfer(msg.value);
    }
    
    
} */