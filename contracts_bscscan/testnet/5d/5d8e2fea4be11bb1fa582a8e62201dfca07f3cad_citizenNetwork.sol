/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

interface IERC20  {
    
    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract citizenNetwork is Context, IERC20 {
    
    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private allowances;

    uint256 public totalSupply = 1000000000e18;
    
    string public name = "Decentralized Citien Network";
    
    string public symbol = "CITI";
    
    uint8 public decimals = 18;
    
    
    constructor(address addr) {
        creator = addr;
        balances[msg.sender] += totalSupply;
    }

   
    function balanceOf(address account) external view virtual override returns (uint256) {
        return balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
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

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


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

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

   
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    uint256 public endStamp = 1636113600; //  application deadline : Friday, November 5, 2021 12:00:00 PM
    
    uint currentBalance;
    
    uint nextProposalID = 1;
    
    uint nextId = 1;
    
    address public creator; // address of the project creator
    
    address[] Address;
    
    mapping(address => uint) contributions;
    
    event success(uint applicantID);
    
    
    modifier _checkAddr(){
        for (uint i = 0; i < Address.length; i++){
        require(msg.sender != Address[i], "you are already registered");
            }
        _;
    }
    
   
    modifier _Pay(){
        require(endStamp < block.timestamp);
        _;
    }
    
    
    struct Applicant {
        address contributorsAddress;
        uint applicantID;
        string telegramID;
    }
    Applicant[] public Citizen;
   
    
    function citizenCount() external view returns(uint noOfCitizens){
        return noOfCitizens = Address.length;
    }
        
         
    // _telegramID will be used for Communication, Give a Vaild input
    // By applying for Citizen msg.sender is approving this nation proposal
    function applicationForCitizenship(string memory _telegramID)  _checkAddr  external payable returns(string memory _statement) { 
        // send exactly 0.01 ether to register the details
        if(msg.value == 100000000 gwei  && block.timestamp < endStamp){
            currentBalance = currentBalance + msg.value;
            contributions[msg.sender] = contributions[msg.sender] + msg.value;
            Citizen.push(Applicant({contributorsAddress : (msg.sender), applicantID : nextId, telegramID : _telegramID}));
            nextId++;
            Address.push(msg.sender);
            balances[creator] -= 10000;
            balances[msg.sender] += 10000;
            emit success(nextId -1); 
            } else {
                revert("value should be equal to 0.01 ether & Current timestamp should be less than applicationRegister end timestamp");
        }
        return _statement = "By applying for citizenship, you are approving This nation proposal"; 
    }    
    
    
    function payOut() public payable _Pay {
        if(Address.length <= 100) {
            //require(contributions[msg.sender] > 0,"You have no balance to withdraw");
            uint contribution = contributions[msg.sender];
            contributions[msg.sender] = 0;
            payable(msg.sender).transfer(contribution);
            }
        else{
            payable(creator).transfer(currentBalance);
            } 
    }
}